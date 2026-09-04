-- ============================================================================
-- 0020_explore_api.sql
--
-- Lapisan baca untuk layar Explore. Satu panggilan per baris kartu, bukan satu
-- panggilan per kartu.
--
-- Semua fungsi di sini memakai auth.uid() dan tidak menerima parameter user.
-- Sengaja: kalau user id boleh dikirim dari browser, frontend bisa salah kirim
-- dan kita bergantung pada RLS untuk menutupinya. Dengan auth.uid() pertanyaan
-- itu tidak pernah muncul.
--
-- Jalankan setelah 0019. Aman diulang.
-- ============================================================================

begin;

-- Tipe balikan fungsi tidak bisa diubah lewat CREATE OR REPLACE, dan view
-- career_card ikut berubah bentuk, jadi keduanya dijatuhkan lebih dulu. Aman:
-- tidak ada yang menyimpan data di sini.
drop function if exists public.explore_by_study(integer);
drop function if exists public.explore_by_match(integer);
drop function if exists public.explore_by_activity(integer);
drop function if exists public.explore_top_demand(integer);
drop function if exists public.explore_search(text, integer);
drop view if exists public.career_card;

-- ---------------------------------------------------------------------------
-- 1. Bahan satu kartu profesi
--
-- Semua yang tampil di kartu ada di sini kecuali skor kecocokan, yang
-- bergantung pada DNA pengguna dan karena itu ditambahkan oleh fungsi di
-- bawah.
-- ---------------------------------------------------------------------------
create view public.career_card
with (security_invoker = true) as
select
  c.id                                as career_id,
  c.career_name,
  c.career_description,
  si.name_id                          as sub_industry,
  si.industry_code,
  greatest(coalesce(sc.total, 1) - 1, 0)::int as sub_industry_extra,
  m.demand_score,
  case
    when m.demand_score >= 70 then 'Demand tinggi'
    when m.demand_score >= 50 then 'Demand sedang'
    else 'Demand rendah'
  end                                 as demand_label,
  m.salary_min,
  m.salary_max,
  rmn.months                          as roadmap_months,
  coalesce(act.attrs, array[]::text[]) as activity_attributes
from public.careers c
left join public.career_sub_industries csi
       on csi.career_id = c.id and csi.is_primary
left join public.sub_industries si on si.code = csi.sub_industry_code
left join (select career_id, count(*) as total
           from public.career_sub_industries group by career_id) sc on sc.career_id = c.id
left join public.career_market m     on m.career_id = c.id
-- Lama perjalanan dihitung dari tahap yang benar-benar dilalui pengguna ini:
-- yang sudah lulus S1 tidak perlu diberi tahu bahwa jalurnya 5 tahun karena
-- tahap SEKOLAH dan KULIAH masih ikut dijumlahkan. Tanpa profil, rank dianggap
-- 2 (lulus SMA) — angka yang sama dengan est_months pada roadmap_templates,
-- jadi pengunjung yang belum login melihat angka yang sudah dikurasi di 0007.
left join lateral (
  select coalesce(sum(s.est_months), 0)::smallint as months
  from public.roadmap_templates t2
  join public.roadmap_stages s on s.template_id = t2.id
  where t2.career_id = c.id
    and (s.skip_if_rank_at_least is null
         or s.skip_if_rank_at_least > coalesce(
              (select p.min_education_rank from public.profiles pr
               join public.education_levels el on el.code = pr.education_level_code
               join lateral (select el.order_rank as min_education_rank) p on true
               where pr.user_id = auth.uid() limit 1), 2))
) rmn on true
left join (
  select c2.id as career_id,
         array_agg(a.name_id order by d.rank_in_layer) filter (where d.rank_in_layer <= 3) as attrs
  from public.careers c2
  join public.onet_dna d on d.soc_code = c2.soc_code and d.is_dominant
  join public.dna_attributes a on a.code = d.attribute_code and a.layer_code = 'ACTIVITY'
  group by c2.id
) act on act.career_id = c.id
where c.is_active;

comment on view public.career_card is
  'Satu baris per profesi aktif berisi seluruh isi kartu Explore kecuali skor kecocokan. Angka gaji dan durasi dikirim mentah; pemformatannya urusan tampilan.';

-- ---------------------------------------------------------------------------
-- 2. Mesin alasan
--
-- Kartu hanya menampilkan satu alasan, yang paling kuat. Urutannya mengikuti
-- bobot rumus: minat lebih menentukan daripada aktivitas, dan kalimat "belum
-- cocok" hanya muncul kalau memang tidak ada yang cocok.
-- ---------------------------------------------------------------------------
create or replace function public.match_reason(p_detail jsonb, p_industry text)
returns text language sql immutable
set search_path = public
as $$
  select case
    when jsonb_array_length(coalesce(p_detail->'INTEREST'->'cocok','[]'::jsonb)) > 0
      then 'Minatmu selaras dengan dunia ' ||
           lower(p_detail->'INTEREST'->'cocok'->>0) || '.'
    when jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'cocok','[]'::jsonb)) > 0
      then 'Aktivitas pilihanmu, seperti ' ||
           lower(p_detail->'ACTIVITY'->'cocok'->>0) || ', sangat sesuai atribut profesi ini.'
    when jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'belum','[]'::jsonb)) > 0
      then 'Aktivitas ' || (p_detail->'ACTIVITY'->'belum'->>0) ||
           ' masih dapat terus dikembangkan untuk mendukung profesi ini.'
    when p_industry is not null
      then 'Bidang ' || p_industry || ' belum menjadi salah satu minat utama yang kamu pilih.'
    else 'Profil DNA-mu belum banyak beririsan dengan profesi ini.'
  end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Keadaan layar
--
-- Empat tampilan Explore ditentukan dua hal: sudah memilih profesi atau belum,
-- dan sudah mengisi Career DNA atau belum. Frontend menanyakannya sekali.
-- ---------------------------------------------------------------------------
create or replace function public.explore_state()
returns table (
  full_name          text,
  has_career         boolean,
  has_dna            boolean,
  career_id          integer,
  career_name        text,
  percent_done       numeric,
  study_label        text,
  top_activity       text
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  prof as (
    select p.full_name, p.study_program_id, p.smk_concentration_id
    from profiles p, me where p.user_id = me.uid
  ),
  rm as (
    select ur.career_id, c.career_name, coalesce(pr.percent_done, 0) as percent_done
    from user_roadmaps ur
    join careers c on c.id = ur.career_id
    left join user_roadmap_progress pr on pr.user_roadmap_id = ur.id, me
    where ur.user_id = me.uid and ur.status <> 'dibatalkan'
    order by ur.started_at desc
    limit 1
  ),
  dna as (select count(*) as n from user_dna ud, me where ud.user_id = me.uid),
  act as (
    select a.name_id
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code, me
    where ud.user_id = me.uid and a.layer_code = 'ACTIVITY'
    order by a.display_order
    limit 1
  )
  select
    (select full_name from prof),
    (select count(*) from rm) > 0,
    coalesce((select n from dna), 0) > 0,
    (select career_id from rm),
    (select career_name from rm),
    (select percent_done from rm),
    coalesce(
      (select sp.name_id from prof join study_programs sp on sp.id = prof.study_program_id),
      (select sk.name_id from prof join smk_concentrations sk on sk.id = prof.smk_concentration_id)
    ),
    (select name_id from act);
$$;

-- ---------------------------------------------------------------------------
-- 4. Empat baris kartu
-- ---------------------------------------------------------------------------

/** Paling Diminati tahun ini — tidak butuh login. */
create or replace function public.explore_top_demand(p_limit integer default 12)
returns setof public.career_card
language sql stable
set search_path = public
as $$
  select * from public.career_card
  order by demand_score desc nulls last, salary_max desc nulls last, career_name
  limit greatest(p_limit, 1);
$$;

/** Relevan dengan Program Studi — dari program studi atau konsentrasi SMK di profil. */
create or replace function public.explore_by_study(p_limit integer default 12)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          integer,
  salary_max          integer,
  roadmap_months      smallint,
  activity_attributes text[],
  relevance           smallint
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  src as (
    select case when p.study_program_id is not null then 'PRODI' else 'SMK' end as kind,
           coalesce(p.study_program_id, p.smk_concentration_id) as sid
    from profiles p, me where p.user_id = me.uid
  )
  select cc.career_id, cc.career_name, cc.career_description, cc.sub_industry,
         cc.industry_code, cc.sub_industry_extra, cc.demand_score, cc.demand_label,
         cc.salary_min, cc.salary_max, cc.roadmap_months, cc.activity_attributes, e.relevance
  from education_career e
  join src on src.kind = e.source_kind and src.sid = e.source_id
  join public.career_card cc on cc.career_id = e.career_id
  order by e.display_order
  limit greatest(p_limit, 1);
$$;

/** Persentase Match Profesi — butuh Career DNA terisi. */
create or replace function public.explore_by_match(p_limit integer default 12)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          integer,
  salary_max          integer,
  roadmap_months      smallint,
  activity_attributes text[],
  match_score         numeric,
  band_code           text,
  band_label          text,
  reason              text
)
language sql stable
set search_path = public
as $$
  select cc.career_id, cc.career_name, cc.career_description, cc.sub_industry,
         cc.industry_code, cc.sub_industry_extra, cc.demand_score, cc.demand_label,
         cc.salary_min, cc.salary_max, cc.roadmap_months, cc.activity_attributes,
         s.match_score, s.band_code, s.band_label,
         public.match_reason(s.detail, i.name_id)
  from public.career_match_scores(auth.uid()) s
  join public.career_card cc on cc.career_id = s.career_id
  left join public.industries i on i.code = cc.industry_code
  order by s.match_score desc, cc.career_name
  limit greatest(p_limit, 1);
$$;

/**
 * Dari Aktivitas Pilihan — profesi yang atribut aktivitasnya beririsan dengan
 * pilihan user. Spek tim desain: minimal satu atribut harus cocok, jadi
 * irisannya disaring, bukan sekadar diurutkan.
 */
create or replace function public.explore_by_activity(p_limit integer default 12)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          integer,
  salary_max          integer,
  roadmap_months      smallint,
  activity_attributes text[],
  match_score         numeric,
  band_code           text,
  band_label          text,
  n_cocok             integer
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  pilihan as (
    select ud.attribute_code
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code, me
    where ud.user_id = me.uid and a.layer_code = 'ACTIVITY'
  ),
  cocok as (
    select c.id as career_id, count(*)::int as n
    from careers c
    join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join pilihan p on p.attribute_code = d.attribute_code
    where c.is_active
    group by c.id
  )
  select cc.career_id, cc.career_name, cc.career_description, cc.sub_industry,
         cc.industry_code, cc.sub_industry_extra, cc.demand_score, cc.demand_label,
         cc.salary_min, cc.salary_max, cc.roadmap_months, cc.activity_attributes,
         s.match_score, s.band_code, s.band_label, k.n
  from cocok k
  join public.career_card cc on cc.career_id = k.career_id
  left join public.career_match_scores(auth.uid()) s on s.career_id = k.career_id
  order by k.n desc, s.match_score desc nulls last, cc.career_name
  limit greatest(p_limit, 1);
$$;

/**
 * Quest minggu ini — langkah berikutnya di roadmap yang sedang dijalani.
 *
 * Yang ditampilkan quest, bukan langkah, supaya sejalan dengan cara Roadmap
 * menghitung progres. Estimasi menit dijumlahkan dari langkah-langkahnya.
 */
create or replace function public.explore_weekly_quests(p_limit integer default 3)
returns table (
  activity_id  bigint,
  quest_title  text,
  tier_code    text,
  tier_emoji   text,
  quest_kind   text,
  xp           integer,
  est_minutes  integer,
  stage_order  smallint
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  rm as (
    select ur.id, ur.start_rank from user_roadmaps ur, me
    where ur.user_id = me.uid and ur.status <> 'dibatalkan'
    order by ur.started_at desc limit 1
  )
  select s.activity_id, s.activity_name, a.tier_code, qt.emoji, a.kind, s.xp,
         coalesce((select sum(l.est_minutes)::int from roadmap_quest_langkah l
                   where l.activity_id = s.activity_id), 0),
         s.stage_order
  from user_roadmap_stages s
  join rm on rm.id = s.user_roadmap_id
  join roadmap_activities a on a.id = s.activity_id
  left join quest_tiers qt on qt.code = a.tier_code
  where s.activity_status is distinct from 'selesai'
    -- Tahap yang sudah dilewati jenjang pendidikan pengguna tidak boleh muncul
    -- sebagai quest. Tanpa saringan ini, lulusan S1 disuruh "Pilih program
    -- studi" dan "Selesaikan Doktor (S3)" di layar depan.
    and (s.skip_if_rank_at_least is null
         or s.skip_if_rank_at_least > coalesce(rm.start_rank, 0))
  order by s.stage_order, s.milestone_order, s.activity_order
  limit greatest(p_limit, 1);
$$;

/** Pencarian profesi untuk kolom "Cari profesi impian kamu..". */
create or replace function public.explore_search(p_query text, p_limit integer default 20)
returns setof public.career_card
language sql stable
set search_path = public
as $$
  select * from public.career_card
  where p_query is not null and length(btrim(p_query)) >= 2
    and (career_name ilike '%' || btrim(p_query) || '%'
      or career_description ilike '%' || btrim(p_query) || '%'
      or sub_industry ilike '%' || btrim(p_query) || '%')
  order by
    case when career_name ilike btrim(p_query) || '%' then 0 else 1 end,
    demand_score desc nulls last, career_name
  limit greatest(p_limit, 1);
$$;

commit;

-- ============================================================================
-- Verifikasi:
--   select career_name, sub_industry, sub_industry_extra, demand_label,
--          salary_min, salary_max, roadmap_months, activity_attributes
--   from explore_top_demand(5);
--
--   select * from explore_search('apoteker', 5);
-- ============================================================================

-- ============================================================================
-- Perbaikan yang menyusul: urutan atribut yang cocok
--
-- career_match_scores() di 0009 menyusun daftar atribut yang cocok dengan
-- `order by p.name_id` — menurut abjad. Akibatnya mesin alasan mengambil
-- atribut pertama menurut abjad, bukan yang paling dominan di profesi itu, dan
-- kartu Dokter Gigi berbunyi "Minatmu selaras dengan dunia bisnis" padahal
-- Kesehatan juga cocok dan jauh lebih menggambarkan profesinya.
--
-- Yang berubah hanya urutan di dalam kolom detail: sekarang mengikuti
-- rank_in_layer, yaitu seberapa dominan atribut itu pada profesinya. Angka
-- skornya sama sekali tidak berubah — hanya kalimat alasannya jadi tepat.
-- ============================================================================

begin;

drop function if exists public.career_match_scores(uuid);

create function public.career_match_scores(p_user_id uuid)
returns table (
  career_id      integer,
  career_name    text,
  match_score    numeric,
  base_score     numeric,
  band_code      text,
  band_label     text,
  detail         jsonb
)
language sql stable
set search_path = public
as $$
  with
  user_pick as (
    select a.layer_code, ud.attribute_code, a.name_id
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = p_user_id
  ),
  user_n as (
    select layer_code, count(*)::int as n_user
    from user_pick group by layer_code
  ),
  prof as (
    select c.id as career_id, c.career_name, a.layer_code,
           d.attribute_code, a.name_id, d.rank_in_layer
    from careers c
    join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join dna_attributes a on a.code = d.attribute_code
    where c.is_active
  ),
  per_layer as (
    select p.career_id, p.career_name, p.layer_code,
           count(*)::int                                              as n_prof,
           coalesce(max(u.n_user), 0)                                 as n_user,
           count(*) filter (where up.attribute_code is not null)::int as n_hit,
           -- Diurutkan menurut dominansi atribut pada profesinya, bukan abjad:
           -- elemen pertama dipakai mesin alasan sebagai atribut yang paling
           -- menggambarkan profesi ini.
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where up.attribute_code is not null)             as cocok,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where up.attribute_code is null)                 as belum
    from prof p
    left join user_pick up on up.attribute_code = p.attribute_code
    left join user_n u on u.layer_code = p.layer_code
    group by p.career_id, p.career_name, p.layer_code
  ),
  sim as (
    select pl.*,
           case when pl.n_user = 0 then 0
                else pl.n_hit::numeric / nullif(pl.n_user + pl.n_prof - pl.n_hit, 0)
           end as jaccard
    from per_layer pl
  ),
  agg as (
    select s.career_id, s.career_name,
           sum(s.jaccard * w.weight) * 100                                    as base,
           max(s.n_hit)   filter (where s.layer_code = 'INTEREST')            as hit_interest,
           max(s.n_hit)   filter (where s.layer_code = 'ACTIVITY')            as hit_activity,
           max(s.jaccard) filter (where s.layer_code = 'ACTIVITY')            as sim_activity,
           jsonb_object_agg(s.layer_code, jsonb_build_object(
             'similarity', round(s.jaccard * 100, 2),
             'n_user',     s.n_user,
             'n_profesi',  s.n_prof,
             'n_cocok',    s.n_hit,
             'cocok',      coalesce(s.cocok, '[]'::jsonb),
             'belum',      coalesce(s.belum, '[]'::jsonb)
           ))                                                                 as detail
    from sim s
    join dna_layer_weights w on w.layer_code = s.layer_code
    group by s.career_id, s.career_name
  ),
  gated as (
    select a.*,
           least(
             case when coalesce(a.hit_interest, 0) >= 1
                   and coalesce(a.hit_activity, 0) >= 2
                  then 10 else 0 end
             +
             (case when coalesce(a.sim_activity, 0) = 0 then 0.8 else 1.0 end)
             *
             (case when coalesce(a.hit_interest, 0) = 0
                   then least(a.base, 49) else a.base end),
             100
           ) as final
    from agg a
  )
  select g.career_id, g.career_name,
         round(g.final, 2), round(g.base, 2),
         b.code, b.label_id, g.detail
  from gated g
  left join match_score_bands b
         on round(g.final, 2) between b.min_score and b.max_score
  order by 3 desc, g.career_name;
$$;

comment on function public.career_match_scores(uuid) is
  'Career Matching Score sesuai spek tim: weighted Jaccard per kategori DNA + Rule 1-3 + band label. Kolom detail memuat atribut mana yang cocok, diurutkan menurut dominansinya pada profesi — urutan itu yang dipakai match_reason() untuk memilih satu alasan.';

commit;
