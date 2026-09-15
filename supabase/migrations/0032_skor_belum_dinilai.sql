-- ===========================================================================
-- 0032_skor_belum_dinilai.sql
--
-- Membedakan "belum dinilai" dari "nilainya nol".
--
-- ---------------------------------------------------------------------------
-- Apa yang salah
-- ---------------------------------------------------------------------------
-- career_match_scores() menghitung Jaccard per lapisan. Kalau pengguna belum
-- mengisi Career DNA, n_user = 0 di semua lapisan, seluruh Jaccard jadi 0,
-- dan skornya keluar 0,00 dengan pita EXPLORE.
--
-- Layar detail lalu menampilkan busur 0% dengan label "Belum Direkomendasikan"
-- dan daftar "Kamu perlu mengembangkan ..." untuk semua atribut profesi. Itu
-- keliru dan menyesatkan: profesinya tidak dinilai jelek, ia BELUM DINILAI
-- sama sekali. Yang lebih parah, profesi yang sama muncul di baris "Relevan
-- dengan Program Studi" — jadi satu layar bilang "cocok dengan jurusanmu" dan
-- layar berikutnya bilang "0%, belum direkomendasikan".
--
-- Terbukti di Postgres lokal sebelum migrasi ini, untuk pengguna tanpa satu
-- pun baris user_dna:
--
--   Frontend Developer   match_score 0.00   band EXPLORE
--   Perawat              match_score 0.00   band EXPLORE
--
-- ---------------------------------------------------------------------------
-- Aturan baru
-- ---------------------------------------------------------------------------
-- Skor hanya punya arti kalau Career DNA sudah SELESAI — bukan sekadar
-- dimulai. DNA yang terisi separuh menghasilkan angka yang terlihat sah
-- padahal dihitung dari data setengah jadi, dan itu justru lebih berbahaya
-- daripada tidak ada angka sama sekali.
--
-- Jadi kalau user_dna_progress.completed_at masih NULL, keempat kolom skor dan
-- kolom detail dikembalikan NULL. Frontend sudah menyiapkan keadaan ini:
-- MatchBlock menampilkan "Selesaikan Career DNA dulu untuk melihat seberapa
-- cocok profesi ini denganmu" ketika skornya null.
--
-- Barisnya TETAP dikembalikan, tidak disaring. Kartu profesi harus tetap
-- tampil lengkap dengan gaji, demand, dan durasinya; yang hilang cuma skornya.
--
-- Pengurutan ikut disesuaikan di dua tempat yang memakai `order by ... desc`
-- tanpa `nulls last`: di PostgreSQL, DESC menaruh NULL di DEPAN, jadi tanpa
-- perbaikan ini profesi yang belum dinilai akan menempati urutan teratas.
--
-- Jalankan setelah 0031. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Skor kecocokan
--
--    Isi perhitungannya tidak berubah sedikit pun dari 0009. Yang ditambahkan
--    hanya CTE `dinilai` dan pembungkus CASE di select terakhir.
-- ---------------------------------------------------------------------------
create or replace function public.career_match_scores(p_user_id uuid)
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
  -- Career DNA yang selesai adalah syarat satu-satunya. Tanpa ini skornya
  -- bukan 0, melainkan tidak ada.
  dinilai as (
    select exists (
      select 1 from user_dna_progress dp
      where dp.user_id = p_user_id and dp.completed_at is not null
    ) as ok
  ),
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
         case when d.ok then round(g.final, 2) end,
         case when d.ok then round(g.base, 2) end,
         case when d.ok then b.code end,
         case when d.ok then b.label_id end,
         -- detail ikut dikosongkan supaya mesin alasan tidak mengarang kalimat
         -- "kamu perlu mengembangkan ..." dari atribut yang belum pernah dipilih.
         case when d.ok then g.detail end
  from gated g
  cross join dinilai d
  left join match_score_bands b
         on d.ok and round(g.final, 2) between b.min_score and b.max_score
  order by 3 desc nulls last, g.career_name;
$$;

comment on function public.career_match_scores(uuid) is
  'Career Match Score per profesi. NULL berarti Career DNA belum selesai diisi — bukan berarti tidak cocok. Lihat 0032.';

-- ---------------------------------------------------------------------------
-- 2. Pengurutan yang menganggap NULL paling besar
--
--    `order by x desc` di PostgreSQL menaruh NULL di depan. Dua fungsi memakai
--    bentuk itu tanpa `nulls last`; sebelum 0032 tidak pernah kelihatan karena
--    skornya tidak pernah NULL.
-- ---------------------------------------------------------------------------
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
         cc.salary_min::integer, cc.salary_max::integer, cc.roadmap_months,
         cc.activity_attributes,
         s.match_score, s.band_code, s.band_label,
         case when s.detail is null then null
              else public.match_reason(s.detail, i.name_id) end
  from public.career_match_scores(auth.uid()) s
  join public.career_card cc on cc.career_id = s.career_id
  left join public.industries i on i.code = cc.industry_code
  order by s.match_score desc nulls last, cc.career_name
  limit greatest(p_limit, 1);
$$;

create or replace function public.family_detail(p_family_code text)
returns table (
  family_code    text,
  family_name    text,
  description_id text,
  n_profesi      integer,
  match_score    numeric,
  band_code      text,
  band_label     text,
  salary_min     bigint,
  salary_max     bigint,
  n_sub_industri integer,
  growth_pct     numeric,
  demand_label   text,
  atribut        jsonb,
  pendidikan     jsonb
)
language sql stable
set search_path = public
as $$
  with anggota as (
    select c.id, c.min_education_rank, c.career_name
    from public.careers c
    where c.is_active and c.family_code = p_family_code
  ),
  pasar as (
    select min(m.salary_min) as smin, max(m.salary_max) as smax,
           max(m.growth_pct) as growth, max(m.demand_score) as demand
    from public.career_market m join anggota a on a.id = m.career_id
  ),
  subind as (
    select count(distinct csi.sub_industry_code)::int as n
    from public.career_sub_industries csi join anggota a on a.id = csi.career_id
  ),
  skor as (
    select s.match_score, s.band_code, s.band_label
    from public.career_match_scores(auth.uid()) s
    join anggota a on a.id = s.career_id
    order by s.match_score desc nulls last
    limit 1
  ),
  atr as (
    select l.code as layer_code, l.name_id as layer_name, l.display_order,
           jsonb_agg(x.name_id order by x.n desc, x.name_id) as isi
    from (
      select a2.layer_code, a2.name_id, count(*) as n,
             row_number() over (partition by a2.layer_code
                                order by count(*) desc, a2.name_id) as rn
      from anggota an
      join public.careers c on c.id = an.id
      join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
      join public.dna_attributes a2 on a2.code = d.attribute_code
      group by a2.layer_code, a2.name_id
    ) x
    join public.dna_layers l on l.code = x.layer_code
    where x.rn <= 6
    group by l.code, l.name_id, l.display_order
  ),
  pend as (
    select a.min_education_rank as rank,
           public.label_jenjang(a.min_education_rank) as jenjang,
           count(*)::int as n,
           string_agg(a.career_name, ', ' order by a.career_name) as contoh
    from anggota a
    group by a.min_education_rank
  )
  select
    f.code, f.name_id, f.description_id,
    (select count(*)::int from anggota),
    (select match_score from skor), (select band_code from skor),
    (select band_label from skor),
    p.smin, p.smax, (select n from subind), p.growth,
    case when p.demand >= 70 then 'Demand tinggi'
         when p.demand >= 50 then 'Demand sedang'
         else 'Demand rendah' end,
    (select coalesce(jsonb_agg(jsonb_build_object(
       'layer', layer_code, 'judul', 'Atribut ' || layer_name, 'isi', isi)
       order by display_order), '[]'::jsonb) from atr),
    (select coalesce(jsonb_agg(jsonb_build_object(
       'jenjang', jenjang,
       'catatan', case
         when n = (select count(*) from anggota)
           then 'Standar minimum untuk seluruh profesi di kategori ini.'
         when n = 1
           then contoh || ' memerlukan minimal ' || jenjang || '.'
         else n || ' profesi di kategori ini memerlukan minimal ' || jenjang ||
              ', antara lain ' || split_part(contoh, ', ', 1) || '.'
       end) order by rank), '[]'::jsonb) from pend)
  from public.career_families f, pasar p
  where f.code = p_family_code;
$$;

-- ---------------------------------------------------------------------------
-- 3. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_skor numeric; v_band text; v_n int;
begin
  -- Pengguna tanpa Career DNA yang selesai harus mendapat NULL, bukan 0.
  select match_score, band_code into v_skor, v_band
  from public.career_match_scores('00000000-0000-0000-0000-000000000000'::uuid)
  limit 1;
  if v_skor is not null or v_band is not null then
    raise exception '0032: pengguna tanpa DNA masih mendapat skor % pita %', v_skor, v_band;
  end if;

  -- Barisnya tetap ada; yang hilang hanya skornya.
  select count(*) into v_n
  from public.career_match_scores('00000000-0000-0000-0000-000000000000'::uuid);
  if v_n < 400 then
    raise exception '0032: hanya % baris dikembalikan, profesi ikut hilang', v_n;
  end if;

  raise notice '0032: skor kini NULL kalau Career DNA belum selesai (% profesi tetap terkirim)', v_n;
end $$;

commit;
