-- ============================================================================
-- 0022_jenjang_indonesia.sql
--
-- Menurunkan syarat pendidikan 35 profesi yang kelebihan satu sampai dua
-- jenjang, dan merapikan roadmap yang mengikutinya.
--
-- Cacatnya baru terlihat saat layar Explore jadi: kartu Apoteker menampilkan
-- "5-6 tahun" dan roadmapnya menyuruh "Tempuh pendidikan Doktor (S3)".
-- Di Indonesia Apoteker adalah S1 Farmasi + program profesi, bukan doktor.
--
-- Sumber cacatnya distribusi pendidikan O*NET, yang menggambarkan pasar kerja
-- Amerika. Untuk profesi yang di Indonesia diatur jelas — nakes, guru, dosen,
-- pustakawan — angka itu perlu dikoreksi memakai aturan di sini, bukan dipakai
-- apa adanya.
--
-- Yang TIDAK diturunkan, dan alasannya:
--   Dosen (33)                   UU 14/2005 memang mensyaratkan S2.
--   Dokter spesialis (22)        Sp-1 setara jenjang di atas profesi dokter.
--   Perawat spesialis (2)        Ners + program spesialis.
--   Konselor Genetik, Biostatistician   memang lazimnya S2.
--
-- Skala rank kita tidak punya tingkat "profesi" (Apoteker, dokter, Ners),
-- yang secara formal berada di antara S1 dan S2. Profesi seperti itu diberi
-- rank 6 — angka terdekat yang tidak berlebihan. Itu pembulatan yang sadar,
-- bukan kelalaian.
--
-- Jalankan setelah 0021. Aman diulang.
-- ============================================================================

begin;

create temp table _rank_baru (career_name text primary key, rank_baru smallint) on commit drop;

-- Rank 6 — S1 atau D4, termasuk profesi yang syarat masuknya S1 + program profesi.
insert into _rank_baru values
  ('Asisten Dosen', 6),
  ('Dokter Umum', 6),                        -- S1 Kedokteran + profesi dokter
  ('Dokter Gigi', 6),                        -- S1 KG + profesi dokter gigi
  ('Dokter Hewan', 6),                       -- S1 KH + profesi dokter hewan
  ('Apoteker', 6),                           -- S1 Farmasi + profesi apoteker
  ('Audiolog', 6),
  ('Chiropractor', 6),                       -- belum diatur di Indonesia; S1 kesehatan
  ('Penata Anestesi', 6),                    -- D4 Keperawatan Anestesiologi
  ('Sitoteknologis', 6),
  ('Terapis Seni', 6),
  ('Ahli Gizi', 6),                          -- S1 Gizi + profesi dietisien
  ('Health Informatics Specialist', 6),
  ('Guru PAUD Pendidikan Khusus', 6),        -- S1 PLB
  ('Guru Pendidikan Jasmani Adaptif', 6),    -- S1 PJKR
  ('Pengembang Kurikulum', 6),
  ('Pustakawan', 6),                         -- S1 Ilmu Perpustakaan
  ('Arsiparis', 6),
  ('Kurator', 6),
  ('Statistician', 6),
  ('Operations Research Analyst', 6),
  ('Analis Kuantitatif Keuangan', 6),
  ('Geosaintis', 6),
  ('Ahli Ergonomi (Human Factors Engineer)', 6),
  ('Manajer Investasi', 6),
  ('Penyuluh Pertanian', 6),
  ('Desainer Set dan Panggung', 6);

-- Rank 5 — D3, jenjang yang benar-benar dipakai untuk masuk ke profesi ini.
insert into _rank_baru values
  ('Bidan', 5),
  ('Bidan (Perawat Kebidanan)', 5),
  ('Fisioterapis', 5),
  ('Fisioterapis Olahraga', 5),
  ('Terapis Okupasi', 5),
  ('Terapis Wicara', 5),
  ('Akupunkturis', 5),
  ('Optometris', 5),
  ('Ortotis Prostetis', 5);

-- Tiap nama harus benar-benar ada, kalau tidak koreksinya diam-diam terlewat.
do $$
declare sisa text;
begin
  select string_agg(r.career_name, ', ') into sisa
  from _rank_baru r
  where not exists (select 1 from public.careers c where c.career_name = r.career_name and c.is_active);
  if sisa is not null then
    raise exception 'nama profesi tidak ditemukan: %', sisa;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1. Syarat pendidikan profesi
-- ---------------------------------------------------------------------------
update public.careers c
set min_education_rank = r.rank_baru,
    curation_note = coalesce(c.curation_note || ' | ', '') ||
      'jenjang diturunkan dari ' || c.min_education_rank || ' ke ' || r.rank_baru ||
      ' di 0022 (aturan Indonesia, bukan distribusi O*NET)'
from _rank_baru r
where c.career_name = r.career_name and c.min_education_rank <> r.rank_baru;

-- ---------------------------------------------------------------------------
-- 2. Roadmap yang mengikutinya
--
-- Label jenjang dan lama kuliah memakai peta yang sama dengan 0007, supaya
-- profesi yang dikoreksi tidak berbeda bentuk dari 476 lainnya.
-- ---------------------------------------------------------------------------
create temp table _rank_peta (rank smallint primary key, label text, bulan integer) on commit drop;
insert into _rank_peta values
  (3, 'Diploma 1 (D1)', 12),
  (4, 'Diploma 2 (D2)', 24),
  (5, 'Diploma 3 (D3)', 36),
  (6, 'Sarjana (S1) atau Diploma 4 (D4)', 48),
  (7, 'Magister (S2)', 24),
  (8, 'Doktor (S3)', 48);

create temp table _tpl_ubah as
select t.id as template_id, t.career_id, t.target_rank as rank_lama, r.rank_baru,
       lama.bulan as bulan_lama, baru.bulan as bulan_baru, baru.label as label_baru
from public.roadmap_templates t
join public.careers c on c.id = t.career_id
join _rank_baru r on r.career_name = c.career_name
join _rank_peta lama on lama.rank = t.target_rank
join _rank_peta baru on baru.rank = r.rank_baru
where t.target_rank is distinct from r.rank_baru;

update public.roadmap_templates t
set target_rank = u.rank_baru,
    -- est_months hanya digeser sebesar perubahan lama kuliahnya; fase lain
    -- tidak tersimpan terpisah, jadi menghitung ulang dari nol tidak mungkin
    -- di sini dan juga tidak perlu.
    est_months = greatest(t.est_months - u.bulan_lama + u.bulan_baru, 1),
    curation_note = coalesce(t.curation_note || ' | ', '') ||
      'target_rank dikoreksi di 0022'
from _tpl_ubah u
where t.id = u.template_id;

update public.roadmap_stages s
set name_id     = 'Tempuh pendidikan ' || u.label_baru,
    est_months  = u.bulan_baru,
    skip_if_rank_at_least = u.rank_baru
from _tpl_ubah u
where s.template_id = u.template_id and s.kind = 'KULIAH';

update public.roadmap_milestones m
set name_id = 'Selesaikan ' || u.label_baru
from _tpl_ubah u
join public.roadmap_stages s on s.template_id = u.template_id and s.kind = 'KULIAH'
where m.stage_id = s.id and m.slug = 'SELESAI_STUDI';

-- ---------------------------------------------------------------------------
-- 3. Quest yang teksnya memuat nama jenjang
--
-- Judul quest ED_KULIAH adalah "Selesaikan [jenjang]" dengan slot yang diisi
-- dari nama milestone. Nama milestone baru saja berubah, jadi konteks dan
-- judulnya perlu dirender ulang — kalau tidak, kartu masih berbunyi
-- "Selesaikan Doktor (S3)".
-- ---------------------------------------------------------------------------
update public.roadmap_activities a
set context = jsonb_set(a.context, '{jenjang}', to_jsonb(u.label_baru)),
    name_id = public.quest_render(qt.title_template,
                jsonb_set(a.context, '{jenjang}', to_jsonb(u.label_baru))),
    description_id = public.quest_render(qt.summary_template,
                jsonb_set(a.context, '{jenjang}', to_jsonb(u.label_baru)))
from public.roadmap_milestones m
join public.roadmap_stages s on s.id = m.stage_id
join _tpl_ubah u on u.template_id = s.template_id
join public.quest_templates qt on qt.code = 'ED_KULIAH'
where a.milestone_id = m.id
  and m.slug = 'SELESAI_STUDI'
  and a.quest_template_code = 'ED_KULIAH';

-- ---------------------------------------------------------------------------
-- Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int; sisa text;
begin
  -- Setiap profesi yang masih menuntut S2 atau lebih harus punya alasan yang
  -- bisa disebutkan. Kalau muncul nama baru di luar empat kelompok itu, ia
  -- perlu diputuskan manusia, bukan dibiarkan lolos.
  select string_agg(c.career_name, ', ') into sisa
  from public.careers c
  where c.is_active and c.min_education_rank >= 7
    and c.career_name !~ '^Dosen '
    and c.career_name !~ 'Spesialis'
    and c.career_name not in ('Konselor Genetik', 'Biostatistician');
  if sisa is not null then
    raise exception 'profesi rank >= 7 tanpa alasan yang tercatat: %', sisa;
  end if;

  select count(*) into n from public.roadmap_activities
  where quest_template_code = 'ED_KULIAH' and name_id like '%[%]%';
  if n > 0 then raise exception '% quest pendidikan masih memuat slot kosong', n; end if;

  -- Profesi yang dikoreksi di file ini harus selaras antara syarat profesi dan
  -- target roadmapnya.
  select count(*) into n
  from public.roadmap_templates t
  join public.careers c on c.id = t.career_id
  join _rank_baru r on r.career_name = c.career_name
  where t.target_rank <> c.min_education_rank;
  if n > 0 then raise exception '% profesi yang dikoreksi masih beda antara syarat dan target roadmap', n; end if;

  -- Catatan, bukan kegagalan: 0007 menghitung target_rank roadmap terpisah dari
  -- min_education_rank profesi, jadi keduanya sudah tidak sinkron pada sebagian
  -- profesi jauh sebelum file ini. Itu perkara tersendiri — yang penting di sini
  -- tidak ada yang bertambah.
  select count(*) into n
  from public.roadmap_templates t
  join public.careers c on c.id = t.career_id
  where c.is_active and t.target_rank < c.min_education_rank;
  if n > 0 then
    raise notice '% profesi masih punya target roadmap di bawah syarat pendidikannya (warisan 0007, belum disentuh)', n;
  end if;
end $$;

commit;

-- ============================================================================
-- Verifikasi:
--   select career_name, min_education_rank from careers
--   where career_name in ('Apoteker','Bidan','Ahli Gizi','Pustakawan');
--
--   select s.name_id from roadmap_stages s
--   join roadmap_templates t on t.id = s.template_id
--   join careers c on c.id = t.career_id
--   where c.career_name = 'Apoteker' and s.kind = 'KULIAH';
--   -- harus "Tempuh pendidikan Sarjana (S1) atau Diploma 4 (D4)"
-- ============================================================================
