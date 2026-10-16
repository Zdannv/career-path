-- ===========================================================================
-- 0042_rumus_matching_overlap_jurusan.sql
--
-- Merombak Career Matching Score (disetujui PM, Oktober 2026).
--
-- ---------------------------------------------------------------------------
-- Masalahnya
-- ---------------------------------------------------------------------------
-- Pada pengujian tim tidak ada satu pun profesi yang skornya di atas 80%.
-- Penyebabnya Jaccard: |U ∩ P| / |U ∪ P|. Pengguna yang cocok 2 dari 3 minat
-- hanya mendapat 2 / (3 + 3 - 2) = 50%, bukan 67%, dan atribut yang hanya
-- selisih satu peringkat dari DNA dominan profesi dihitung nol. Untuk tembus
-- 80, pilihan pengguna harus hampir persis sama dengan DNA profesi di kelima
-- kategori.
--
-- Simulasi pada 464 profesi aktif yang DNA-nya lengkap (80 persona yang
-- dibangkitkan dari skor O*NET tiap profesi lalu diberi derau besar, setara
-- kondisi pengujian tim):
--                                   profesi teratas  rata-rata profesi  Hit@5
--                                        >= 80          >= 80 per user
--     Jaccard (lama)                      9%               0,2           12%
--     overlap                            46%               2,1           12%
--     overlap + kredit, Rule 3 +10       84%              13,0           16%
--     overlap + kredit, Rule 3 +5        56%               3,7           16%   <- dipakai
--   Varian Rule 3 +10 membuat belasan profesi sekaligus berlabel Highly
--   Recommended sehingga labelnya kehilangan arti. Dengan +5, sekitar separuh
--   pengguna mendapat profesi teratas >= 80 dan rata-rata hanya 3-4 profesi
--   yang setinggi itu. Kredit sebagian juga sedikit memperbaiki ketepatan
--   urutan (Hit@5 12% -> 16%).
--
-- ---------------------------------------------------------------------------
-- Rumus baru
-- ---------------------------------------------------------------------------
--   1. Per kategori: kecocokan = jumlah kredit pilihan / jumlah pilihan.
--        kredit 1    atribut ada di N teratas profesi (DNA dominan)
--        kredit 0,5  atribut ada di 2 peringkat sesudahnya ("hampir")
--        kredit 0    selain itu
--      N = dna_layers.selection_count. Kategori tanpa pilihan -> 0.
--   2. Skor dasar = 100 x jumlah (kecocokan x bobot kategori). Bobot tetap.
--   3. Tiga gate rule tetap, dan dihitung dari kecocokan PENUH (bukan kredit):
--        Rule 1  tidak ada minat yang cocok          -> skor dasar maks 49
--        Rule 2  tidak ada aktivitas yang cocok      -> x 0,8
--        Rule 3  >= 1 minat dan >= 2 aktivitas cocok -> + 5
--                (sebelumnya + 10; diturunkan karena kecocokan per kategori
--                kini lebih tinggi, lihat simulasi di atas)
--   4. Bonus jurusan (baru): +10 kalau program studi / konsentrasi SMK
--      pengguna sangat relevan dengan profesi (education_career.relevance
--      >= 80), +5 kalau serumpun (>= 50). Pengguna tanpa jurusan (SMP/SMA)
--      tidak terpengaruh. Sengaja bonus, bukan komponen berbobot: profesi di
--      luar jurusan tidak diturunkan, karena Navika juga untuk orang yang
--      ingin pindah bidang. Data education_career belum diverifikasi tim,
--      jadi bonusnya sengaja kecil.
--   5. Skor akhir dibatasi 100. Label band tidak berubah (80 / 50).
--
-- Rumus lama TIDAK dibuang: diganti nama menjadi
-- career_match_scores_jaccard(uuid) untuk pembanding. Lihat query di bagian
-- paling bawah.
--
-- Fungsi lain (Explore, detail profesi, kategori, pencarian) memanggil
-- career_match_scores() lewat nama dan bentuk keluarannya tidak berubah,
-- jadi semuanya otomatis memakai rumus baru.
--
-- Jalankan setelah 0041. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Simpan rumus lama sebagai pembanding (sekali saja)
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regprocedure('public.career_match_scores_jaccard(uuid)') is null then
    alter function public.career_match_scores(uuid) rename to career_match_scores_jaccard;
    comment on function public.career_match_scores_jaccard(uuid) is
      'Rumus Career Match Score sebelum 0042 (weighted Jaccard + gate rule). Hanya untuk pembanding.';
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Rumus baru
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
  dinilai as (
    select exists (
      select 1 from user_dna_progress dp
      where dp.user_id = p_user_id and dp.completed_at is not null
    ) as ok
  ),
  user_pick as (
    select a.layer_code, ud.attribute_code
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = p_user_id
  ),
  user_n as (
    select layer_code, count(*)::int as n_user
    from user_pick group by layer_code
  ),
  -- Seluruh atribut profesi sampai peringkat N + 2 di tiap kategori.
  prof as (
    select c.id as career_id, c.career_name, a.layer_code, d.attribute_code,
           a.name_id, d.rank_in_layer,
           d.rank_in_layer <= l.selection_count as dominan
    from careers c
    join onet_dna d       on d.soc_code = c.soc_code
    join dna_attributes a on a.code = d.attribute_code
    join dna_layers l     on l.code = a.layer_code
    where c.is_active
      and d.rank_in_layer <= l.selection_count + 2
  ),
  -- Kategori profesi diambil dari bobot, supaya kategori yang tidak dipilih
  -- pengguna tetap muncul dengan kecocokan 0.
  kerangka as (
    select distinct p.career_id, p.career_name, p.layer_code from prof p
  ),
  per_layer as (
    select k.career_id, k.career_name, k.layer_code,
           count(*) filter (where p.dominan)::int                          as n_prof,
           coalesce(max(u.n_user), 0)                                     as n_user,
           count(*) filter (where p.dominan and up.attribute_code is not null)::int     as n_hit,
           count(*) filter (where not p.dominan and up.attribute_code is not null)::int as n_hampir,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where p.dominan and up.attribute_code is not null)   as cocok,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where p.dominan and up.attribute_code is null)       as belum,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where not p.dominan and up.attribute_code is not null) as hampir
    from kerangka k
    join prof p on p.career_id = k.career_id and p.layer_code = k.layer_code
    left join user_pick up on up.attribute_code = p.attribute_code
    left join user_n u on u.layer_code = k.layer_code
    group by k.career_id, k.career_name, k.layer_code
  ),
  sim as (
    select pl.*,
           case when pl.n_user = 0 then 0
                else least(1, (pl.n_hit + 0.5 * pl.n_hampir)::numeric / pl.n_user)
           end as kecocokan
    from per_layer pl
  ),
  agg as (
    select s.career_id, s.career_name,
           sum(s.kecocokan * w.weight) * 100                         as base,
           max(s.n_hit) filter (where s.layer_code = 'INTEREST')     as hit_interest,
           max(s.n_hit) filter (where s.layer_code = 'ACTIVITY')     as hit_activity,
           jsonb_object_agg(s.layer_code, jsonb_build_object(
             'similarity', round(s.kecocokan * 100, 2),
             'n_user',     s.n_user,
             'n_profesi',  s.n_prof,
             'n_cocok',    s.n_hit,
             'n_hampir',   s.n_hampir,
             'cocok',      coalesce(s.cocok, '[]'::jsonb),
             'belum',      coalesce(s.belum, '[]'::jsonb),
             'hampir',     coalesce(s.hampir, '[]'::jsonb)
           ))                                                        as detail
    from sim s
    join dna_layer_weights w on w.layer_code = s.layer_code
    group by s.career_id, s.career_name
  ),
  -- Jurusan pengguna: program studi lebih dulu, lalu konsentrasi SMK.
  jurusan as (
    select case when p.study_program_id is not null then 'PRODI' else 'SMK' end as kind,
           coalesce(p.study_program_id, p.smk_concentration_id)               as sid,
           coalesce(sp.name_id, sk.name_id)                                    as nama
    from profiles p
    left join study_programs sp     on sp.id = p.study_program_id
    left join smk_concentrations sk on sk.id = p.smk_concentration_id
    where p.user_id = p_user_id
      and coalesce(p.study_program_id, p.smk_concentration_id) is not null
  ),
  relevan as (
    select e.career_id, max(e.relevance) as relevansi, max(j.nama) as nama
    from jurusan j
    join education_career e on e.source_kind = j.kind and e.source_id = j.sid
    group by e.career_id
  ),
  gated as (
    select a.*, r.nama as jurusan_nama, r.relevansi,
           case when r.relevansi >= 80 then 10
                when r.relevansi >= 50 then 5
                else 0 end as bonus_jurusan,
           case when coalesce(a.hit_interest, 0) >= 1
                 and coalesce(a.hit_activity, 0) >= 2
                then 5 else 0 end
           +
           (case when coalesce(a.hit_activity, 0) = 0 then 0.8 else 1.0 end)
           *
           (case when coalesce(a.hit_interest, 0) = 0
                 then least(a.base, 49) else a.base end) as setelah_gate
    from agg a
    left join relevan r on r.career_id = a.career_id
  ),
  akhir as (
    select g.*,
           least(g.setelah_gate + g.bonus_jurusan, 100) as final,
           case when g.bonus_jurusan > 0
                then g.detail || jsonb_build_object('JURUSAN', jsonb_build_object(
                       'nama', g.jurusan_nama, 'relevansi', g.relevansi, 'bonus', g.bonus_jurusan))
                else g.detail end as detail_lengkap
    from gated g
  )
  select k.career_id, k.career_name,
         case when d.ok then round(k.final, 2) end,
         case when d.ok then round(k.base, 2) end,
         case when d.ok then b.code end,
         case when d.ok then b.label_id end,
         case when d.ok then k.detail_lengkap end
  from akhir k
  cross join dinilai d
  left join match_score_bands b
         on d.ok and round(k.final, 2) between b.min_score and b.max_score
  order by 3 desc nulls last, k.career_name;
$$;

comment on function public.career_match_scores(uuid) is
  'Career Match Score (0042): overlap dengan kredit sebagian per kategori DNA, gate rule (Rule 3 +5), bonus jurusan, maks 100. NULL berarti Career DNA belum selesai. Rumus lama: career_match_scores_jaccard().';

-- ---------------------------------------------------------------------------
-- 3. Alasan di kartu Explore: jurusan yang sangat relevan disebut lebih dulu
-- ---------------------------------------------------------------------------
create or replace function public.match_reason(p_detail jsonb, p_industry text)
returns text language sql immutable
set search_path = public
as $$
  select case
    when coalesce((p_detail->'JURUSAN'->>'bonus')::int, 0) >= 10
      then 'Sesuai dengan jurusan ' || (p_detail->'JURUSAN'->>'nama') || ' yang Kamu tempuh.'
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
-- 4. Alasan di layar detail: tambah jurusan, dan tegakkan batas spek
--    (maksimal 3 alasan cocok + 2 alasan pengembangan)
-- ---------------------------------------------------------------------------
create or replace function public.match_reasons(p_detail jsonb)
returns jsonb
language sql immutable
set search_path = public
as $$
  with baris as (
    select 0 as urut, 'cocok' as nada,
           'Profesi ini sesuai dengan jurusan <b>' || (p_detail->'JURUSAN'->>'nama') ||
           '</b> yang Kamu tempuh' as teks
    where coalesce((p_detail->'JURUSAN'->>'bonus')::int, 0) > 0
    union all
    select 1, 'cocok',
           'Bidang industri <b>' || (p_detail->'INTEREST'->'cocok'->>0) ||
           '</b> sesuai dengan minat preferensi bidang industri pilihan Kamu'
    where jsonb_array_length(coalesce(p_detail->'INTEREST'->'cocok','[]'::jsonb)) > 0
    union all
    select 2, 'cocok',
           'Rutinitas aktivitas <b>' || (p_detail->'ACTIVITY'->'cocok'->>0) ||
           '</b> profesi ini sesuai dengan preferensi Kamu'
    where jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'cocok','[]'::jsonb)) > 0
    union all
    select 3, 'cocok',
           'Keahlian <b>' || (p_detail->'SKILL'->'cocok'->>0) ||
           '</b> Kamu mendukung kebutuhan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'SKILL'->'cocok','[]'::jsonb)) > 0
    union all
    select 4, 'cocok',
           'Cara kerja <b>' || (p_detail->'WORKSTYLE'->'cocok'->>0) ||
           '</b> Kamu sejalan dengan tuntutan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'WORKSTYLE'->'cocok','[]'::jsonb)) > 0
    union all
    select 5, 'belum',
           'Kamu perlu mengembangkan Keahlian <b>' || (p_detail->'SKILL'->'belum'->>0) ||
           '</b> untuk mendukung kebutuhan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'SKILL'->'belum','[]'::jsonb)) > 0
    union all
    select 6, 'belum',
           'Kamu perlu mengembangkan cara kerja <b>' || (p_detail->'WORKSTYLE'->'belum'->>0) ||
           '</b> yang dibutuhkan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'WORKSTYLE'->'belum','[]'::jsonb)) > 0
    union all
    select 7, 'belum',
           'Rutinitas aktivitas <b>' || (p_detail->'ACTIVITY'->'belum'->>0) ||
           '</b> masih perlu Kamu biasakan di profesi ini'
    where jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'belum','[]'::jsonb)) > 0
      and jsonb_array_length(coalesce(p_detail->'SKILL'->'belum','[]'::jsonb)) = 0
  ),
  terbatas as (
    select *, row_number() over (partition by nada order by urut) as ke
    from baris
  )
  select coalesce(
    jsonb_agg(jsonb_build_object('nada', nada, 'teks', teks) order by urut),
    '[]'::jsonb)
  from terbatas
  where (nada = 'cocok' and ke <= 3) or (nada = 'belum' and ke <= 2);
$$;

commit;

-- ===========================================================================
-- Pembanding (jalankan terpisah setelah migrasi, tidak mengubah data):
-- skor lama vs baru untuk 5 profesi teratas tiap pengguna yang DNA-nya selesai.
--
--   select u.email, b.career_name,
--          l.match_score as skor_lama, l.band_label as label_lama,
--          b.match_score as skor_baru, b.band_label as label_baru,
--          b.detail->'JURUSAN'->>'bonus' as bonus_jurusan
--   from auth.users u
--   join user_dna_progress dp on dp.user_id = u.id and dp.completed_at is not null
--   cross join lateral (select * from public.career_match_scores(u.id) limit 5) b
--   left join lateral (select * from public.career_match_scores_jaccard(u.id)) l
--          on l.career_id = b.career_id
--   order by u.email, b.match_score desc;
-- ===========================================================================
