-- ============================================================================
-- 0009_matching_engine_spec.sql
--
-- Mengganti mesin Career Matching Score dengan rumus yang ditetapkan tim
-- desain & PO: weighted Jaccard per kategori DNA, lalu tiga gate rule, lalu
-- label band. Spesifikasinya ada di "Career path 1.xlsx", sheet Career
-- Matching Score dan diagram rumusnya.
--
-- Apa yang berubah dari implementasi sebelumnya:
--
--   sebelum  rata-rata skor kontinu O*NET (0-100) pada atribut yang dipilih
--            user, dibobot per layer
--   sesudah  Jaccard atas himpunan: |irisan| / |gabungan| per kategori,
--            dibobot, lalu Rule 1-3
--
-- Keduanya menghasilkan urutan yang mirip; yang dipakai adalah yang disepakati
-- tim, karena angkanya muncul di layar dan harus bisa dijelaskan ke pengguna
-- dengan kalimat sederhana ("kamu cocok 2 dari 3 minat utama profesi ini").
--
-- Cara lama tidak dibuang, hanya berganti nama jadi career_affinity_scores().
-- Ia memakai skor kontinu yang tetap tersimpan di onet_dna, jadi berguna untuk
-- membandingkan kualitas urutan kalau nanti rumusnya ditinjau ulang.
--
-- Jalankan setelah 0008. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Simpan cara lama dengan nama yang jujur
-- ---------------------------------------------------------------------------
drop function if exists public.career_affinity_scores(uuid);

create function public.career_affinity_scores(p_user_id uuid)
returns table (career_id integer, career_name text, affinity numeric, layers jsonb)
language sql stable
set search_path = public
as $$
  with picked as (
    select ud.attribute_code, a.layer_code
    from user_dna ud join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = p_user_id
  ),
  per_layer as (
    select c.id, c.career_name, p.layer_code, avg(d.score) as layer_score
    from careers c
    join onet_dna d on d.soc_code = c.soc_code
    join picked p on p.attribute_code = d.attribute_code
    where c.is_active
    group by c.id, c.career_name, p.layer_code
  )
  select pl.id, pl.career_name,
         round(sum(pl.layer_score * w.weight) / nullif(sum(w.weight), 0), 2),
         jsonb_object_agg(pl.layer_code, round(pl.layer_score, 2))
  from per_layer pl
  join dna_layer_weights w on w.layer_code = pl.layer_code
  group by pl.id, pl.career_name
  order by 3 desc;
$$;

comment on function public.career_affinity_scores(uuid) is
  'Cara penilaian alternatif: rata-rata skor kontinu O*NET pada atribut pilihan user. Bukan angka yang ditampilkan ke pengguna — itu career_match_scores. Disimpan untuk membandingkan kualitas urutan.';

-- ---------------------------------------------------------------------------
-- 2. Career Matching Score sesuai spek
--
-- Satu baris per profesi aktif. Kolom `detail` memuat rincian per kategori —
-- similarity, atribut yang cocok, dan atribut profesi yang belum dimiliki user
-- — karena reason engine butuh tahu ATRIBUT MANA yang cocok, bukan cuma
-- angkanya. Tanpa itu kalimat "Main interest [nama_atribut] selaras dengan
-- profesi ini" tidak bisa diisi.
-- ---------------------------------------------------------------------------
drop function if exists public.career_match_scores(uuid);

create function public.career_match_scores(p_user_id uuid)
returns table (
  career_id      integer,
  career_name    text,
  match_score    numeric,   -- 0-100, setelah gate rules
  base_score     numeric,   -- 0-100, sebelum gate rules
  band_code      text,
  band_label     text,
  detail         jsonb
)
language sql stable
set search_path = public
as $$
  with
  -- Pilihan user, dikelompokkan per kategori.
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
  -- DNA profesi = atribut dominan (peringkat teratas) per kategori.
  prof as (
    select c.id as career_id, c.career_name, a.layer_code,
           d.attribute_code, a.name_id
    from careers c
    join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join dna_attributes a on a.code = d.attribute_code
    where c.is_active
  ),
  -- Jaccard per (profesi, kategori).
  --
  -- |gabungan| = |user| + |profesi| - |irisan|, jadi tidak perlu membentuk
  -- himpunan gabungannya secara eksplisit.
  per_layer as (
    select p.career_id, p.career_name, p.layer_code,
           count(*)::int                                              as n_prof,
           coalesce(max(u.n_user), 0)                                 as n_user,
           count(*) filter (where up.attribute_code is not null)::int as n_hit,
           jsonb_agg(p.name_id order by p.name_id)
             filter (where up.attribute_code is not null)             as cocok,
           jsonb_agg(p.name_id order by p.name_id)
             filter (where up.attribute_code is null)                 as belum
    from prof p
    left join user_pick up
           on up.attribute_code = p.attribute_code
    left join user_n u on u.layer_code = p.layer_code
    group by p.career_id, p.career_name, p.layer_code
  ),
  sim as (
    select pl.*,
           -- Spek: kategori yang tidak dipilih user sama sekali -> similarity 0.
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
  -- Gate rules, berurutan seperti di diagram: Rule 1 lalu Rule 2 lalu Rule 3.
  --
  -- Rule 1 dan Rule 3 tidak mungkin aktif bersamaan: Rule 1 menuntut irisan
  -- Interest = 0, Rule 3 menuntut >= 1.
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
  'Career Matching Score sesuai spek tim: weighted Jaccard per kategori DNA + Rule 1-3 + band label. Kolom detail memuat atribut mana yang cocok, supaya reason engine bisa menyusun kalimat alasannya.';

commit;

-- ============================================================================
-- Verifikasi (ganti UUID dengan pengguna yang punya isi di user_dna):
--
--   select career_name, match_score, base_score, band_label
--   from career_match_scores('...'::uuid) limit 10;
--
--   select jsonb_pretty(detail) from career_match_scores('...'::uuid) limit 1;
--
-- Uji ulang contoh Data Analyst dari diagram: user 3 Interest / 4 Activity /
-- 5 Skills / 3 Environment / 3 Work Style, dengan irisan 1/2/2/3/2 terhadap
-- profesi ber-DNA 2/3/4/3/3, harus menghasilkan base 40,04 dan final 50,04.
-- ============================================================================
