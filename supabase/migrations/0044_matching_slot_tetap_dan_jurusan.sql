-- ===========================================================================
-- 0044_matching_slot_tetap_dan_jurusan.sql
--
-- Perbaikan Career Match Score dari pengujian PM (20 Oktober 2026): akun lulusan
-- D4 Teknik Informatika mendapat Staff Loket Pos 89%, Petugas Gudang 88%, dan
-- Sales Spare Part sebagai rekomendasi teratas.
--
-- Penyebab (diuji ulang di database lokal):
--   1. Pengguna mengisi Career DNA kurang dari batas maksimal (misalnya 3 dari 5).
--      Rumus 0042 membagi kredit dengan jumlah PILIHAN pengguna, jadi 3 pilihan
--      yang cocok langsung bernilai 100% dan banyak profesi umum ikut tinggi.
--   2. Jurusan hanya memberi bonus (+5/+10) dan tidak pernah menurunkan profesi
--      di luar jurusan, sehingga profesi umum dengan DNA mirip tetap di atas.
--   Catatan: rumus lama (Jaccard) TIDAK lebih baik. Untuk persona yang sama,
--   urutan 10 teratasnya hampir identik (tetap Petugas Gudang, Kurir, dst.),
--   hanya angkanya lebih kecil; untuk persona IT yang mengisi penuh, Jaccard
--   malah menempatkan Insinyur Manufaktur di atas Backend Developer.
--
-- Perubahan:
--   1. Kecocokan per kategori = kredit / max(jumlah pilihan, jumlah slot).
--   2. Pengguna yang punya jurusan: profesi tanpa relevansi dengan jurusannya
--      -10 poin (relevansi >= 80 tetap +10, >= 50 tetap +5). Pengguna tanpa
--      jurusan (SMP/SMA) tidak terpengaruh. Skor dibatasi 0-100.
--
-- Simulasi (D4 Teknik Informatika; 10 teratas yang relevan TI / skor teratas):
--                                  isi sebagian (mirip PM)   isi penuh, profil IT
--     0042 sekarang                0 / 97,5 (Pekarya Kesehatan)   10 / 100
--     Jaccard lama                 0 / 60,5 (Pekarya Kesehatan)    0 / 93,8
--     slot tetap                   0 / 57,8                       10 / 100
--     slot tetap + jurusan -10     3 / 50,7 (QA Engineer)         10 / 100   <- dipakai
--     slot tetap + jurusan -15     5 / 50,7 (QA Engineer)         10 / 100
--
-- Aman dijalankan ulang. Rumus lama tetap ada: career_match_scores_jaccard().
-- ===========================================================================

begin;

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
                -- Dibagi jumlah slot kategori (selection_count), bukan jumlah pilihan
                -- pengguna: memilih 3 dari 5 slot tidak lagi bisa bernilai 100%.
                else least(1, (pl.n_hit + 0.5 * pl.n_hampir)::numeric
                     / greatest(pl.n_user, (select l.selection_count from dna_layers l where l.code = pl.layer_code)))
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
                -- Pengguna yang punya jurusan: profesi di luar jurusannya turun 10 poin.
                -- Tetap bisa direkomendasikan (untuk yang ingin pindah bidang), tetapi
                -- tidak lagi mengalahkan profesi sejurusan hanya karena DNA-nya umum.
                when exists (select 1 from jurusan) then -10
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
           greatest(least(g.setelah_gate + g.bonus_jurusan, 100), 0) as final,
           case when g.bonus_jurusan <> 0
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
  'Career Match Score (0044): overlap per slot kategori DNA dengan kredit sebagian, gate rule, penyesuaian jurusan (+10/+5/-10), 0-100.';

commit;
