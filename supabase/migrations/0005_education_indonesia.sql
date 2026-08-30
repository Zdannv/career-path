-- ============================================================================
-- 0005_education_indonesia.sql
--
-- Menyesuaikan data pendidikan dengan desain onboarding tim desain.
--
-- Tiga hal yang sebelumnya tidak ada dan membuat desain itu tidak bisa dibangun:
--
--   1. `education_levels` cuma 6 baris dan MENGGABUNG SMA dengan SMK. Seluruh
--      percabangan onboarding bergantung pada bedanya -- SMK punya Jurusan,
--      SMA tidak. SMP juga belum ada, padahal itu baris pertama di matriks.
--      Sekarang 10 jenjang terpisah.
--
--   2. Daftar jurusan SMK tidak ada. Sekarang lengkap dari sumber resmi:
--      50 Program Keahlian, 128 Konsentrasi Keahlian.
--      Sumber: https://smk.kemendikdasmen.go.id/spektrum-keahlian
--
--   3. Tabel `profiles` belum pernah dibuat. Onboarding tidak punya tempat
--      menyimpan apa pun.
--
-- Aturan percabangan ikut disimpan sebagai DATA (`education_step_rules`),
-- bukan dihardcode di frontend. 20 kombinasi jenjang x status kelulusan --
-- kalau nanti berubah, cukup ubah satu baris tabel.
--
-- Catatan transkripsi daftar program studi: enam entri diperbaiki dari sumber
-- (lihat supabase/dna/../ dan docs/REFACTOR-NOTES.md untuk daftar lengkapnya),
-- dan satu duplikat "Rekayasa Pertanian" di rumpun Ilmu Pertanian dihapus.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Jenjang pendidikan: 6 -> 10
--
--    `order_rank` boleh sama untuk jenjang yang setara secara akademik:
--    SMA dan SMK sama-sama 2, D4 dan S1 sama-sama 6. Yang membedakan mereka
--    adalah `code`, bukan peringkatnya.
--
--    Blok ini hanya berjalan sekali. Kalau kolom `code` sudah ada, berarti
--    migrasi sudah pernah dijalankan dan pemetaan ulang di bawah tidak boleh
--    diulang -- kalau diulang, rank profesi akan bergeser dua kali.
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='education_levels' and column_name='code'
  ) then
    raise notice 'education_levels sudah dimigrasikan, lewati.';
    return;
  end if;

  alter table public.education_levels add column code text;
  alter table public.education_levels add column description_id text;

  -- Petakan min_education_rank 477 profesi dari skala lama (6) ke skala baru (8).
  -- Nilainya berasal dari Job Zone O*NET, jadi pemetaannya deterministik.
  --   lama 1 SMA/MA/SMK -> baru 2 (menengah atas)
  --   lama 2 D1/D2      -> baru 3 (D1)
  --   lama 3 D3         -> baru 5
  --   lama 4 S1/D4      -> baru 6
  --   lama 5 S2         -> baru 7
  --   lama 6 S3         -> baru 8
  update public.careers set min_education_rank =
    case min_education_rank
      when 1 then 2 when 2 then 3 when 3 then 5
      when 4 then 6 when 5 then 7 when 6 then 8
      else min_education_rank end;

  delete from public.education_levels;
end $$;

insert into public.education_levels (code, level_name, description_id, order_rank) values
  ('SMP', 'SMP / MTs', 'Sekolah Menengah Pertama', 1),
  ('SMA', 'SMA / MA', 'Sekolah Menengah Atas', 2),
  ('SMK', 'SMK / MAK', 'Sekolah Menengah Kejuruan', 2),
  ('D1', 'Diploma 1 (D1)', 'Ahli Pratama', 3),
  ('D2', 'Diploma 2 (D2)', 'Ahli Muda', 4),
  ('D3', 'Diploma 3 (D3)', 'Ahli Madya', 5),
  ('D4', 'Diploma 4 (D4)', 'Sarjana Terapan, setara S1', 6),
  ('S1', 'Sarjana (S1)', 'Strata 1', 6),
  ('S2', 'Magister (S2)', 'Strata 2', 7),
  ('S3', 'Doktor (S3)', 'Strata 3', 8)
on conflict do nothing;

alter table public.education_levels alter column code set not null;
create unique index if not exists uq_education_levels_code on public.education_levels(code);

-- ---------------------------------------------------------------------------
-- 2. Spektrum Keahlian SMK
-- ---------------------------------------------------------------------------
create table if not exists public.smk_expertise_programs (
  code          text primary key,
  name_id       text not null unique,
  display_order smallint not null
);
comment on table public.smk_expertise_programs is
  'Program Keahlian SMK. Sumber: smk.kemendikdasmen.go.id/spektrum-keahlian';

create table if not exists public.smk_concentrations (
  id            serial primary key,
  program_code  text not null references public.smk_expertise_programs(code) on delete cascade,
  name_id       text not null,
  display_order smallint not null,
  unique (program_code, name_id)
);
comment on table public.smk_concentrations is
  'Konsentrasi Keahlian SMK -- inilah yang dipilih siswa sebagai "Jurusan" di onboarding.';

insert into public.smk_expertise_programs (code, name_id, display_order) values
  ('AGRIBISNIS_PERIKANAN', 'Agribisnis Perikanan', 1),
  ('AGRIBISNIS_TANAMAN', 'Agribisnis Tanaman', 2),
  ('AGRIBISNIS_TERNAK', 'Agribisnis Ternak', 3),
  ('AGRITEKNOLOGI_PENGOLAHAN_HASIL_PERTANIAN', 'Agriteknologi Pengolahan Hasil Pertanian', 4),
  ('AKUNTANSI_DAN_KEUANGAN_LEMBAGA', 'Akuntansi dan Keuangan Lembaga', 5),
  ('ANIMASI', 'Animasi', 6),
  ('BROADCASTING_DAN_PERFILMAN', 'Broadcasting dan Perfilman', 7),
  ('BUSANA', 'Busana', 8),
  ('DESAIN_KOMUNIKASI_VISUAL', 'Desain Komunikasi Visual', 9),
  ('DESAIN_PEMODELAN_DAN_INFORMASI_BANGUNAN', 'Desain Pemodelan dan Informasi Bangunan', 10),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Desain dan Produksi Kriya', 11),
  ('KECANTIKAN_DAN_SPA', 'Kecantikan dan Spa', 12),
  ('KEHUTANAN', 'Kehutanan', 13),
  ('KIMIA_ANALISIS', 'Kimia Analisis', 14),
  ('KONSTRUKSI_DAN_PERAWATAN_BANGUNAN_SIPIL', 'Konstruksi dan Perawatan Bangunan Sipil', 15),
  ('KULINER', 'Kuliner', 16),
  ('LAYANAN_KESEHATAN', 'Layanan Kesehatan', 17),
  ('MANAJEMEN_PERKANTORAN_DAN_LAYANAN_BISNIS', 'Manajemen Perkantoran dan Layanan Bisnis', 18),
  ('NAUTIKA_KAPAL_NIAGA', 'Nautika Kapal Niaga', 19),
  ('NAUTIKA_KAPAL_PENANGKAP_IKAN', 'Nautika Kapal Penangkap Ikan', 20),
  ('PEKERJAAN_SOSIAL', 'Pekerjaan Sosial', 21),
  ('PEMASARAN', 'Pemasaran', 22),
  ('PENGEMBANGAN_PERANGKAT_LUNAK_DAN_GIM', 'Pengembangan Perangkat Lunak dan Gim', 23),
  ('PERHOTELAN', 'Perhotelan', 24),
  ('SENI_PERTUNJUKAN', 'Seni Pertunjukan', 25),
  ('SENI_RUPA', 'Seni Rupa', 26),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Elektronika', 27),
  ('TEKNIK_ENERGI_TERBARUKAN', 'Teknik Energi Terbarukan', 28),
  ('TEKNIK_FURNITUR', 'Teknik Furnitur', 29),
  ('TEKNIK_GEOLOGI_PERTAMBANGAN', 'Teknik Geologi Pertambangan', 30),
  ('TEKNIK_GEOSPASIAL', 'Teknik Geospasial', 31),
  ('TEKNIK_JARINGAN_KOMPUTER_DAN_TELEKOMUNIKASI', 'Teknik Jaringan Komputer dan Telekomunikasi', 32),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Ketenagalistrikan', 33),
  ('TEKNIK_KIMIA_INDUSTRI', 'Teknik Kimia Industri', 34),
  ('TEKNIK_KONSTRUKSI_KAPAL', 'Teknik Konstruksi Kapal', 35),
  ('TEKNIK_KONSTRUKSI_DAN_PERUMAHAN', 'Teknik Konstruksi dan Perumahan', 36),
  ('TEKNIK_LABORATORIUM_MEDIK', 'Teknik Laboratorium Medik', 37),
  ('TEKNIK_LOGISTIK', 'Teknik Logistik', 38),
  ('TEKNIK_MESIN', 'Teknik Mesin', 39),
  ('TEKNIK_OTOMOTIF', 'Teknik Otomotif', 40),
  ('TEKNIK_PENGELASAN_DAN_FABRIKASI_LOGAM', 'Teknik Pengelasan dan Fabrikasi Logam', 41),
  ('TEKNIK_PERAWATAN_GEDUNG', 'Teknik Perawatan Gedung', 42),
  ('TEKNIK_PERMINYAKAN', 'Teknik Perminyakan', 43),
  ('TEKNIK_PESAWAT_UDARA', 'Teknik Pesawat Udara', 44),
  ('TEKNIK_TEKSTIL', 'Teknik Tekstil', 45),
  ('TEKNIKA_KAPAL_NIAGA', 'Teknika Kapal Niaga', 46),
  ('TEKNIKA_KAPAL_PENANGKAP_IKAN', 'Teknika Kapal Penangkap Ikan', 47),
  ('TEKNOLOGI_FARMASI', 'Teknologi Farmasi', 48),
  ('USAHA_LAYANAN_PARIWISATA', 'Usaha Layanan Pariwisata', 49),
  ('USAHA_PERTANIAN_TERPADU', 'Usaha Pertanian Terpadu', 50)
on conflict (code) do update set name_id = excluded.name_id;

insert into public.smk_concentrations (program_code, name_id, display_order) values
  ('AGRIBISNIS_PERIKANAN', 'Agribisnis Ikan Hias', 1),
  ('AGRIBISNIS_PERIKANAN', 'Agribisnis Perikanan Payau dan Laut', 2),
  ('AGRIBISNIS_PERIKANAN', 'Agribisnis Perikanan Air Tawar', 3),
  ('AGRIBISNIS_PERIKANAN', 'Agribisnis Rumput Laut', 4),
  ('AGRIBISNIS_TANAMAN', 'Agribisnis Tanaman Perkebunan', 1),
  ('AGRIBISNIS_TANAMAN', 'Agribisnis Tanaman Pangan dan Hortikultura', 2),
  ('AGRIBISNIS_TANAMAN', 'Agribisnis Perbenihan Tanaman', 3),
  ('AGRIBISNIS_TANAMAN', 'Agribisnis Lanskap dan Pertamanan', 4),
  ('AGRIBISNIS_TERNAK', 'Agribisnis Ternak Ruminansia', 1),
  ('AGRIBISNIS_TERNAK', 'Agribisnis Ternak Unggas', 2),
  ('AGRIBISNIS_TERNAK', 'Kesehatan Hewan', 3),
  ('AGRITEKNOLOGI_PENGOLAHAN_HASIL_PERTANIAN', 'Agribisnis Pengolahan Hasil Pertanian', 1),
  ('AGRITEKNOLOGI_PENGOLAHAN_HASIL_PERTANIAN', 'Agribisnis Pengolahan Hasil Perikanan', 2),
  ('AGRITEKNOLOGI_PENGOLAHAN_HASIL_PERTANIAN', 'Pengawasan Mutu Hasil Pertanian', 3),
  ('AKUNTANSI_DAN_KEUANGAN_LEMBAGA', 'Layanan Perbankan', 1),
  ('AKUNTANSI_DAN_KEUANGAN_LEMBAGA', 'Layanan Perbankan Syariah', 2),
  ('AKUNTANSI_DAN_KEUANGAN_LEMBAGA', 'Akuntansi', 3),
  ('ANIMASI', 'Animasi', 1),
  ('BROADCASTING_DAN_PERFILMAN', 'Produksi dan Siaran Program Radio', 1),
  ('BROADCASTING_DAN_PERFILMAN', 'Produksi dan Siaran Program Televisi', 2),
  ('BROADCASTING_DAN_PERFILMAN', 'Produksi Film', 3),
  ('BUSANA', 'Desain dan Produksi Busana', 1),
  ('DESAIN_KOMUNIKASI_VISUAL', 'Desain Komunikasi Visual', 1),
  ('DESAIN_KOMUNIKASI_VISUAL', 'Teknik Grafika', 2),
  ('DESAIN_PEMODELAN_DAN_INFORMASI_BANGUNAN', 'Desain Pemodelan dan Informasi Bangunan', 1),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Kriya Kreatif Batik dan Tekstil', 1),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Kriya Kreatif Kulit dan Imitasi', 2),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Kriya Kreatif Keramik', 3),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Kriya Kreatif Logam dan Perhiasan', 4),
  ('DESAIN_DAN_PRODUKSI_KRIYA', 'Kriya Kreatif Kayu dan Rotan', 5),
  ('KECANTIKAN_DAN_SPA', 'Tata Kecantikan Kulit dan Rambut', 1),
  ('KECANTIKAN_DAN_SPA', 'Spa dan Beauty Therapy', 2),
  ('KEHUTANAN', 'Kehutanan', 1),
  ('KIMIA_ANALISIS', 'Kimia Analisis', 1),
  ('KIMIA_ANALISIS', 'Analisis Pengujian Laboratorium', 2),
  ('KONSTRUKSI_DAN_PERAWATAN_BANGUNAN_SIPIL', 'Konstruksi Jalan, Irigasi, dan Jembatan', 1),
  ('KONSTRUKSI_DAN_PERAWATAN_BANGUNAN_SIPIL', 'Konstruksi Jalan dan Jembatan', 2),
  ('KULINER', 'Kuliner', 1),
  ('LAYANAN_KESEHATAN', 'Layanan Penunjang Keperawatan dan Caregiving', 1),
  ('LAYANAN_KESEHATAN', 'Layanan Penunjang Dental Care', 2),
  ('MANAJEMEN_PERKANTORAN_DAN_LAYANAN_BISNIS', 'Manajemen Perkantoran', 1),
  ('MANAJEMEN_PERKANTORAN_DAN_LAYANAN_BISNIS', 'Manajemen Logistik', 2),
  ('NAUTIKA_KAPAL_NIAGA', 'Nautika Kapal Niaga', 1),
  ('NAUTIKA_KAPAL_PENANGKAP_IKAN', 'Nautika Kapal Penangkap Ikan', 1),
  ('PEKERJAAN_SOSIAL', 'Pekerjaan Sosial', 1),
  ('PEMASARAN', 'Bisnis Digital', 1),
  ('PEMASARAN', 'Bisnis Retail', 2),
  ('PENGEMBANGAN_PERANGKAT_LUNAK_DAN_GIM', 'Rekayasa Perangkat Lunak', 1),
  ('PENGEMBANGAN_PERANGKAT_LUNAK_DAN_GIM', 'Pengembangan Gim', 2),
  ('PENGEMBANGAN_PERANGKAT_LUNAK_DAN_GIM', 'Sistem Informasi, Jaringan, dan Aplikasi', 3),
  ('PERHOTELAN', 'Perhotelan', 1),
  ('SENI_PERTUNJUKAN', 'Seni Musik', 1),
  ('SENI_PERTUNJUKAN', 'Seni Tari', 2),
  ('SENI_PERTUNJUKAN', 'Seni Karawitan', 3),
  ('SENI_PERTUNJUKAN', 'Seni Pedalangan', 4),
  ('SENI_PERTUNJUKAN', 'Seni Teater', 5),
  ('SENI_PERTUNJUKAN', 'Tata Artistik Teater', 6),
  ('SENI_RUPA', 'Seni Lukis', 1),
  ('SENI_RUPA', 'Seni Patung', 2),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Audio Video', 1),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Mekatronika', 2),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Elektronika Industri', 3),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Otomasi Industri', 4),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Elektronika Komunikasi', 5),
  ('TEKNIK_ELEKTRONIKA', 'Instrumentasi Medik', 6),
  ('TEKNIK_ELEKTRONIKA', 'Teknik Elektronika Pesawat Udara (Aviation Electronics)', 7),
  ('TEKNIK_ELEKTRONIKA', 'Instrumentasi dan Otomatisasi Proses', 8),
  ('TEKNIK_ENERGI_TERBARUKAN', 'Teknik Energi Surya, Hidro, dan Angin', 1),
  ('TEKNIK_ENERGI_TERBARUKAN', 'Teknik Energi Biomassa', 2),
  ('TEKNIK_FURNITUR', 'Desain Interior dan Teknik Furnitur', 1),
  ('TEKNIK_FURNITUR', 'Desain dan Teknik Furnitur', 2),
  ('TEKNIK_GEOLOGI_PERTAMBANGAN', 'Geologi Pertambangan', 1),
  ('TEKNIK_GEOSPASIAL', 'Teknik Geomatika', 1),
  ('TEKNIK_GEOSPASIAL', 'Informasi Geospasial', 2),
  ('TEKNIK_JARINGAN_KOMPUTER_DAN_TELEKOMUNIKASI', 'Teknik Komputer dan Jaringan', 1),
  ('TEKNIK_JARINGAN_KOMPUTER_DAN_TELEKOMUNIKASI', 'Teknik Jaringan Akses Telekomunikasi', 2),
  ('TEKNIK_JARINGAN_KOMPUTER_DAN_TELEKOMUNIKASI', 'Teknik Transmisi Telekomunikasi', 3),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Instalasi Tenaga Listrik', 1),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Pembangkit Tenaga Listrik', 2),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Jaringan Tenaga Listrik', 3),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Pemanasan, Tata Udara, dan Pendinginan (Heating, Ventilation, and Air Conditioning)', 4),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Kelistrikan Pesawat Udara (Aircraft Electricity)', 5),
  ('TEKNIK_KETENAGALISTRIKAN', 'Teknik Kelistrikan Kapal', 6),
  ('TEKNIK_KIMIA_INDUSTRI', 'Teknik Kimia Industri', 1),
  ('TEKNIK_KIMIA_INDUSTRI', 'Kimia Tekstil', 2),
  ('TEKNIK_KONSTRUKSI_KAPAL', 'Desain Rancang Bangun Kapal', 1),
  ('TEKNIK_KONSTRUKSI_KAPAL', 'Konstruksi Kapal Baja', 2),
  ('TEKNIK_KONSTRUKSI_KAPAL', 'Konstruksi Kapal Non Baja', 3),
  ('TEKNIK_KONSTRUKSI_KAPAL', 'Interior Kapal', 4),
  ('TEKNIK_KONSTRUKSI_DAN_PERUMAHAN', 'Teknik Konstruksi dan Perumahan', 1),
  ('TEKNIK_KONSTRUKSI_DAN_PERUMAHAN', 'Konstruksi Gedung dan Sanitasi', 2),
  ('TEKNIK_LABORATORIUM_MEDIK', 'Layanan Penunjang Laboratorium Medik', 1),
  ('TEKNIK_LOGISTIK', 'Teknik Pengendalian Produksi', 1),
  ('TEKNIK_LOGISTIK', 'Teknik Logistik', 2),
  ('TEKNIK_MESIN', 'Teknik Pemesinan', 1),
  ('TEKNIK_MESIN', 'Teknik Mekanik Industri', 2),
  ('TEKNIK_MESIN', 'Teknik Pengecoran Logam', 3),
  ('TEKNIK_MESIN', 'Desain Gambar Mesin', 4),
  ('TEKNIK_MESIN', 'Teknik Pemesinan Pesawat Udara (Aircraft Machining)', 5),
  ('TEKNIK_MESIN', 'Teknik Konstruksi Rangka Pesawat Udara (Airframe Mechanic)', 6),
  ('TEKNIK_MESIN', 'Teknik Pemesinan Kapal', 7),
  ('TEKNIK_OTOMOTIF', 'Teknik Kendaraan Ringan', 1),
  ('TEKNIK_OTOMOTIF', 'Teknik Sepeda Motor', 2),
  ('TEKNIK_OTOMOTIF', 'Teknik Alat Berat', 3),
  ('TEKNIK_OTOMOTIF', 'Teknik Ototronik', 4),
  ('TEKNIK_OTOMOTIF', 'Teknik Bodi Kendaraan Ringan', 5),
  ('TEKNIK_PENGELASAN_DAN_FABRIKASI_LOGAM', 'Teknik Pengelasan', 1),
  ('TEKNIK_PENGELASAN_DAN_FABRIKASI_LOGAM', 'Teknik Pengelasan Kapal', 2),
  ('TEKNIK_PENGELASAN_DAN_FABRIKASI_LOGAM', 'Teknik Konstruksi Badan Pesawat Udara (Aircraft Sheet Metal Forming)', 3),
  ('TEKNIK_PENGELASAN_DAN_FABRIKASI_LOGAM', 'Teknik Fabrikasi Logam dan Manufaktur', 4),
  ('TEKNIK_PERAWATAN_GEDUNG', 'Teknik Perawatan Gedung', 1),
  ('TEKNIK_PERMINYAKAN', 'Teknik Produksi Minyak dan Gas', 1),
  ('TEKNIK_PERMINYAKAN', 'Teknik Pemboran Minyak dan Gas', 2),
  ('TEKNIK_PERMINYAKAN', 'Teknik Pengolahan Minyak, Gas dan Petrokimia', 3),
  ('TEKNIK_PESAWAT_UDARA', 'Airframe Powerplant', 1),
  ('TEKNIK_PESAWAT_UDARA', 'Electrical Avionic', 2),
  ('TEKNIK_TEKSTIL', 'Teknik Pembuatan Serat Filamen', 1),
  ('TEKNIK_TEKSTIL', 'Teknik Pembuatan Benang Stapel', 2),
  ('TEKNIK_TEKSTIL', 'Teknik Pembuatan Kain', 3),
  ('TEKNIK_TEKSTIL', 'Teknik Penyempurnaan Tekstil', 4),
  ('TEKNIKA_KAPAL_NIAGA', 'Teknika Kapal Niaga', 1),
  ('TEKNIKA_KAPAL_PENANGKAP_IKAN', 'Teknika Kapal Penangkap Ikan', 1),
  ('TEKNOLOGI_FARMASI', 'Layanan Penunjang Kefarmasian Klinis dan Komunitas', 1),
  ('TEKNOLOGI_FARMASI', 'Farmasi Industri', 2),
  ('USAHA_LAYANAN_PARIWISATA', 'Usaha Layanan Wisata', 1),
  ('USAHA_LAYANAN_PARIWISATA', 'Ekowisata', 2),
  ('USAHA_PERTANIAN_TERPADU', 'Usaha Pertanian Terpadu', 1),
  ('USAHA_PERTANIAN_TERPADU', 'Mekanisasi Pertanian', 2)
on conflict (program_code, name_id) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Program studi perguruan tinggi
--
--    Sumber: daftar rumpun & jurusan dari tim (Agustus 2026) -- 244 entri,
--    243 nama unik di 12 rumpun. Menggantikan kurasi 158 nama sebelumnya.
--
--    Rumpun dibuat many-to-many, bukan satu kolom: "Ilmu Keolahragaan" memang
--    terdaftar di Ilmu Kesehatan DAN Ilmu Olahraga. Kalau dipaksa satu kolom,
--    salah satunya harus dibuang atau namanya diduplikasi.
--
--    Ini BUKAN daftar PDDikti (~29.000 prodi per kampus). User tetap boleh
--    mengetik yang tidak ada di sini; isian bebasnya masuk
--    profiles.study_program_custom untuk ditinjau dan dipromosikan admin.
-- ---------------------------------------------------------------------------
create table if not exists public.study_rumpun (
  code          text primary key,
  name_id       text not null unique,
  display_order smallint not null
);

create table if not exists public.study_programs (
  id            serial primary key,
  name_id       text not null unique,
  source        text not null default 'daftar_tim',
  is_verified   boolean not null default false,
  display_order smallint
);
comment on column public.study_programs.is_verified is
  'false = belum dicocokkan ke PDDikti. Prodi hasil ketikan user yang dipromosikan admin juga mulai dari false.';

-- Migrasi dari versi lama yang memakai satu kolom `rumpun`.
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema='public' and table_name='study_programs' and column_name='rumpun') then
    alter table public.study_programs drop column rumpun;
  end if;
  if not exists (select 1 from information_schema.columns
                 where table_schema='public' and table_name='study_programs' and column_name='source') then
    alter table public.study_programs add column source text not null default 'daftar_tim';
  end if;
end $$;

create table if not exists public.study_program_rumpun (
  program_id  integer not null references public.study_programs(id) on delete cascade,
  rumpun_code text    not null references public.study_rumpun(code) on delete cascade,
  primary key (program_id, rumpun_code)
);
create index if not exists idx_spr_rumpun on public.study_program_rumpun(rumpun_code);

insert into public.study_rumpun (code, name_id, display_order) values
  ('ILMU_KESEHATAN', 'Ilmu Kesehatan', 1),
  ('ILMU_MATEMATIKA_DAN_IPA_MIPA', 'Ilmu Matematika dan IPA (MIPA)', 2),
  ('ILMU_SOSIAL_DAN_HUMANIORA', 'Ilmu Sosial dan Humaniora', 3),
  ('ILMU_EKONOMI_DAN_BISNIS', 'Ilmu Ekonomi dan Bisnis', 4),
  ('ILMU_SASTRA_DAN_BUDAYA', 'Ilmu Sastra dan Budaya', 5),
  ('KOMPUTER_DAN_TEKNOLOGI', 'Komputer dan Teknologi', 6),
  ('ILMU_PENDIDIKAN', 'Ilmu Pendidikan', 7),
  ('ILMU_PERTANIAN', 'Ilmu Pertanian', 8),
  ('ILMU_PROFESI_DAN_ILMU_TERAPAN', 'Ilmu Profesi dan Ilmu Terapan', 9),
  ('ILMU_SENI', 'Ilmu Seni', 10),
  ('ILMU_TEKNIK', 'Ilmu Teknik', 11),
  ('ILMU_OLAHRAGA', 'Ilmu Olahraga', 12)
on conflict (code) do update set name_id = excluded.name_id;

insert into public.study_programs (name_id) values
  ('Kedokteran'),
  ('Kedokteran Gigi'),
  ('Kedokteran Hewan'),
  ('Kesehatan Masyarakat'),
  ('Kesehatan Lingkungan'),
  ('Ilmu Gizi'),
  ('Keselamatan dan Kesehatan Kerja'),
  ('Ilmu Keperawatan'),
  ('Farmasi'),
  ('Nutrisi dan Teknologi Pangan'),
  ('Kebidanan'),
  ('Fisioterapi'),
  ('Ilmu Keolahragaan'),
  ('Teknik Radiodiagnostik dan Radioterapi'),
  ('Manajemen Pelayanan Rumah Sakit'),
  ('Matematika'),
  ('Kimia'),
  ('Fisika'),
  ('Biologi'),
  ('Statistika'),
  ('Astronomi'),
  ('Bioteknologi'),
  ('Geofisika'),
  ('Meteorologi'),
  ('Geografi'),
  ('Biokimia'),
  ('Metrologi'),
  ('Aktuaria'),
  ('Statistika Terapan'),
  ('Mikrobiologi'),
  ('Bioentrepreneurship'),
  ('Ilmu Pangan'),
  ('Matematika Bisnis'),
  ('Fisika Medis'),
  ('Kartografi dan Penginderaan'),
  ('Pengelolaan dan Pemberdayaan SDA dan Lingkungan'),
  ('Ilmu Politik'),
  ('Filsafat'),
  ('Kriminologi'),
  ('Psikologi'),
  ('Ilmu Hukum'),
  ('Sosiologi'),
  ('Jurnalistik'),
  ('Antropologi'),
  ('Hubungan Internasional'),
  ('Ilmu Kesejahteraan Sosial'),
  ('Ilmu Pemerintahan'),
  ('Administrasi Publik'),
  ('Administrasi Bisnis'),
  ('Ilmu Komunikasi'),
  ('Hubungan Masyarakat'),
  ('Marketing Communication'),
  ('Penyiaran'),
  ('Periklanan'),
  ('Peradilan Agama'),
  ('Politik Islam'),
  ('Pembangunan Sosial dan Kesejahteraan'),
  ('Business Law'),
  ('Manajemen Komunikasi'),
  ('Branding'),
  ('Kearsipan'),
  ('Sains Komunikasi dan Pengembangan Masyarakat'),
  ('Ilmu Keluarga dan Konsumen'),
  ('Manajemen Produksi Media'),
  ('Ekonomi Internasional'),
  ('Ekonomi Publik'),
  ('Ekonomi Regional'),
  ('Ekonomi Moneter'),
  ('Ekonomi Pembangunan'),
  ('Ekonomi Industri'),
  ('Ekonomi Sumber Daya Alam dan Lingkungan'),
  ('Ekonomi Sumber Daya Manusia'),
  ('Manajemen Pemasaran'),
  ('Manajemen Keuangan'),
  ('Manajemen Sumber Daya Manusia'),
  ('Manajemen Operasional'),
  ('Akuntansi'),
  ('Akuntansi Keuangan'),
  ('Akuntansi Perpajakan'),
  ('Audit'),
  ('Sistem Informasi'),
  ('Manajemen Akuntansi'),
  ('Ilmu Sejarah'),
  ('Sastra Inggris'),
  ('Arkeologi'),
  ('Sastra Perancis'),
  ('Sastra Korea'),
  ('Sastra Jerman'),
  ('Sastra Belanda'),
  ('Sastra Jepang'),
  ('Sastra Indonesia'),
  ('Sastra Rusia'),
  ('Sastra Jawa'),
  ('Sastra Arab'),
  ('Sastra Cina'),
  ('Sastra Sunda'),
  ('Sastra Bali'),
  ('Sastra Minangkabau'),
  ('Sastra Nusantara'),
  ('Sastra Slavia'),
  ('Sejarah dan Kebudayaan Islam'),
  ('Teknik Informatika'),
  ('Mobile Application & Technology'),
  ('Accounting Information'),
  ('Audio Engineering'),
  ('Ilmu Komputer'),
  ('Sistem Komputer (Teknik Komputer)'),
  ('Sistem Informasi (Manajemen Informatika)'),
  ('Sistem Informasi Bisnis'),
  ('Software Engineering'),
  ('Sistem dan Teknologi Informasi'),
  ('Teknologi Game'),
  ('Ilmu Komputasi'),
  ('Cyber Security'),
  ('Bioinformatika'),
  ('Computerized Accounting'),
  ('Information Systems Audit'),
  ('Human Computer Interaction'),
  ('Pendidikan Guru Sekolah Dasar (PGSD)'),
  ('Manajemen Pendidikan'),
  ('Pendidikan Bahasa Arab'),
  ('Pendidikan Bahasa Inggris'),
  ('Pendidikan Kepelatihan Olahraga'),
  ('Pendidikan Jasmani Kesehatan dan Rekreasi'),
  ('Pendidikan Ilmu Pengetahuan Alam'),
  ('Kurikulum dan Teknologi Pendidikan'),
  ('Pendidikan Luar Sekolah'),
  ('Pendidikan Luar Biasa (PLB)'),
  ('Teologi'),
  ('Pendidikan Kependudukan'),
  ('Manajemen Pendidikan Islam'),
  ('Pendidikan Anak Usia Dini (PAUD)'),
  ('Administrasi Pendidikan'),
  ('Pendidikan Bimbingan Konseling'),
  ('Ilmu Perpustakaan'),
  ('Pendidikan Geografi'),
  ('Tafsir Hadits'),
  ('Pendidikan Pancasila dan Kewarganegaraan'),
  ('Pendidikan Agama Islam'),
  ('Pendidikan Sejarah'),
  ('Pendidikan Matematika'),
  ('Pendidikan Bahasa dan Sastra Indonesia'),
  ('Agronomi dan Hortikultura'),
  ('Mikrobiologi Pertanian'),
  ('Teknologi Pasca Panen'),
  ('Teknologi Industri Benih'),
  ('Ilmu Kelautan'),
  ('Agribisnis (Sosial Ekonomi Pertanian)'),
  ('Agroteknologi'),
  ('Teknologi Pangan'),
  ('Rekayasa Pertanian'),
  ('Peternakan'),
  ('Agroekologi'),
  ('Kehutanan'),
  ('Budidaya Perairan (Akuakultur)'),
  ('Produksi Ternak'),
  ('Teknologi Hasil Ternak'),
  ('Pengelolaan Hutan'),
  ('Teknologi Hasil Hutan'),
  ('Silvikultur'),
  ('Konservasi Sumberdaya Hutan dan Ekowisata'),
  ('Ilmu Hama dan Penyakit Tumbuhan (Proteksi Tanaman)'),
  ('Teknologi Industri Pertanian (Agroindustri)'),
  ('Manajemen Sumberdaya Lahan (Ilmu Tanah)'),
  ('Teknologi Hasil Perikanan'),
  ('Agrobisnis Perikanan (Sosial Ekonomi Perikanan)'),
  ('Sumber Daya Perairan'),
  ('Pemanfaatan Sumberdaya Perikanan'),
  ('Penyuluhan dan Komunikasi Pertanian'),
  ('Budidaya Perikanan'),
  ('Manajemen Hutan'),
  ('Teknik Pertanian'),
  ('Manajemen Bisnis Unggas'),
  ('Pariwisata'),
  ('Penerbang (Pendidikan Pilot)'),
  ('Pendidikan Intelijen'),
  ('Komunikasi Penerbangan'),
  ('Pendidikan Kepolisian'),
  ('Pendidikan Militer'),
  ('Lalu Lintas Udara'),
  ('Manajemen Logistik'),
  ('Desain Interior'),
  ('Desain Produk'),
  ('Animasi'),
  ('DKV New Media'),
  ('DKV Creative Advertising'),
  ('Furniture Design'),
  ('Tata Boga'),
  ('Desain Grafis'),
  ('Teknik Pertambangan'),
  ('Teknik Kelautan'),
  ('Teknik Lingkungan'),
  ('Rekayasa Hayati'),
  ('Manajemen Rekayasa Industri'),
  ('Teknik Perencanaan Wilayah dan Kota (Planologi)'),
  ('Teknik Penerbangan (Aeronautika dan Astronautika)'),
  ('Teknik Metalurgi'),
  ('Teknik Sipil'),
  ('Arsitektur'),
  ('Teknik Geodesi'),
  ('Teknik Elektro'),
  ('Teknik Mesin'),
  ('Teknik Industri'),
  ('Teknik Perkapalan'),
  ('Teknik Otomotif'),
  ('Teknobiomedik'),
  ('Oseanografi'),
  ('Teknik Nuklir'),
  ('Teknik Geologi'),
  ('Teknik Refrigerasi dan Tata Udara'),
  ('Teknik Telekomunikasi'),
  ('Teknik Perancangan Jalan dan Jembatan'),
  ('Teknik Otomasi Manufaktur dan Mekatronika'),
  ('Teknologi Bioproses'),
  ('Teknik Grafika'),
  ('Transportasi Laut'),
  ('Teknik Fisika'),
  ('Teknik Geomatika'),
  ('Teknik Perminyakan'),
  ('Teknik Material'),
  ('Automotive and Robotics Engineering'),
  ('Teknik Tenaga Listrik'),
  ('Teknik Sistem Komputer'),
  ('Arsitektur Lanskap'),
  ('Teknik Konversi Energi'),
  ('Teknik Bioenergi dan Kemurgi'),
  ('Industrial Robotics Design'),
  ('Teknik Kimia'),
  ('Teknik Perpipaan'),
  ('Teknik Bangunan dan Landasan'),
  ('Teknik Listrik Bandara'),
  ('Teknik Alat Berat'),
  ('Rekayasa Infrastruktur Lingkungan'),
  ('Teknik Pesawat Udara'),
  ('Teknik Telekomunikasi dan Navigasi Udara'),
  ('Teknik Pengairan (Sumber Daya Air)'),
  ('Meteorologi Terapan'),
  ('Teknik Ekonomi Konstruksi (Quantity Surveyor)'),
  ('Teknik Sistem Perkapalan'),
  ('Pendidikan Jasmani, Kesehatan, dan Rekreasi'),
  ('Pendidikan Kepelatihan Keolahragaan'),
  ('Olahraga Rekreasi'),
  ('Kepelatihan Kecabangan Olahraga')
on conflict (name_id) do nothing;

insert into public.study_program_rumpun (program_id, rumpun_code)
select p.id, v.rumpun_code
from (values
  ('Kedokteran', 'ILMU_KESEHATAN'),
  ('Kedokteran Gigi', 'ILMU_KESEHATAN'),
  ('Kedokteran Hewan', 'ILMU_KESEHATAN'),
  ('Kesehatan Masyarakat', 'ILMU_KESEHATAN'),
  ('Kesehatan Lingkungan', 'ILMU_KESEHATAN'),
  ('Ilmu Gizi', 'ILMU_KESEHATAN'),
  ('Keselamatan dan Kesehatan Kerja', 'ILMU_KESEHATAN'),
  ('Ilmu Keperawatan', 'ILMU_KESEHATAN'),
  ('Farmasi', 'ILMU_KESEHATAN'),
  ('Nutrisi dan Teknologi Pangan', 'ILMU_KESEHATAN'),
  ('Kebidanan', 'ILMU_KESEHATAN'),
  ('Fisioterapi', 'ILMU_KESEHATAN'),
  ('Ilmu Keolahragaan', 'ILMU_KESEHATAN'),
  ('Teknik Radiodiagnostik dan Radioterapi', 'ILMU_KESEHATAN'),
  ('Manajemen Pelayanan Rumah Sakit', 'ILMU_KESEHATAN'),
  ('Matematika', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Kimia', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Fisika', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Biologi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Statistika', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Astronomi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Bioteknologi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Geofisika', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Meteorologi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Geografi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Biokimia', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Metrologi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Aktuaria', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Statistika Terapan', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Mikrobiologi', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Bioentrepreneurship', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Ilmu Pangan', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Matematika Bisnis', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Fisika Medis', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Kartografi dan Penginderaan', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Pengelolaan dan Pemberdayaan SDA dan Lingkungan', 'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Ilmu Politik', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Filsafat', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Kriminologi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Psikologi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ilmu Hukum', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Sosiologi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Jurnalistik', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Antropologi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Hubungan Internasional', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ilmu Kesejahteraan Sosial', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ilmu Pemerintahan', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Administrasi Publik', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Administrasi Bisnis', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ilmu Komunikasi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Hubungan Masyarakat', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Marketing Communication', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Penyiaran', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Periklanan', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Peradilan Agama', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Politik Islam', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Pembangunan Sosial dan Kesejahteraan', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Business Law', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Manajemen Komunikasi', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Branding', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Kearsipan', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Sains Komunikasi dan Pengembangan Masyarakat', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ilmu Keluarga dan Konsumen', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Manajemen Produksi Media', 'ILMU_SOSIAL_DAN_HUMANIORA'),
  ('Ekonomi Internasional', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Publik', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Regional', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Moneter', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Pembangunan', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Industri', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Sumber Daya Alam dan Lingkungan', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Sumber Daya Manusia', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Manajemen Pemasaran', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Manajemen Keuangan', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Manajemen Sumber Daya Manusia', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Manajemen Operasional', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Akuntansi', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Akuntansi Keuangan', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Akuntansi Perpajakan', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Audit', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Sistem Informasi', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Manajemen Akuntansi', 'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ilmu Sejarah', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Inggris', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Arkeologi', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Perancis', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Korea', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Jerman', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Belanda', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Jepang', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Indonesia', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Rusia', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Jawa', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Arab', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Cina', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Sunda', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Bali', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Minangkabau', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Nusantara', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sastra Slavia', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Sejarah dan Kebudayaan Islam', 'ILMU_SASTRA_DAN_BUDAYA'),
  ('Teknik Informatika', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Mobile Application & Technology', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Accounting Information', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Audio Engineering', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Ilmu Komputer', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sistem Komputer (Teknik Komputer)', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sistem Informasi (Manajemen Informatika)', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sistem Informasi Bisnis', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Software Engineering', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sistem dan Teknologi Informasi', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Teknologi Game', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Ilmu Komputasi', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Cyber Security', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Bioinformatika', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Computerized Accounting', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Information Systems Audit', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Human Computer Interaction', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Pendidikan Guru Sekolah Dasar (PGSD)', 'ILMU_PENDIDIKAN'),
  ('Manajemen Pendidikan', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Bahasa Arab', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Bahasa Inggris', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Kepelatihan Olahraga', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Jasmani Kesehatan dan Rekreasi', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Ilmu Pengetahuan Alam', 'ILMU_PENDIDIKAN'),
  ('Kurikulum dan Teknologi Pendidikan', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Luar Sekolah', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Luar Biasa (PLB)', 'ILMU_PENDIDIKAN'),
  ('Teologi', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Kependudukan', 'ILMU_PENDIDIKAN'),
  ('Manajemen Pendidikan Islam', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Anak Usia Dini (PAUD)', 'ILMU_PENDIDIKAN'),
  ('Administrasi Pendidikan', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Bimbingan Konseling', 'ILMU_PENDIDIKAN'),
  ('Ilmu Perpustakaan', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Geografi', 'ILMU_PENDIDIKAN'),
  ('Tafsir Hadits', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Pancasila dan Kewarganegaraan', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Agama Islam', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Sejarah', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Matematika', 'ILMU_PENDIDIKAN'),
  ('Pendidikan Bahasa dan Sastra Indonesia', 'ILMU_PENDIDIKAN'),
  ('Agronomi dan Hortikultura', 'ILMU_PERTANIAN'),
  ('Mikrobiologi Pertanian', 'ILMU_PERTANIAN'),
  ('Teknologi Pasca Panen', 'ILMU_PERTANIAN'),
  ('Teknologi Industri Benih', 'ILMU_PERTANIAN'),
  ('Ilmu Kelautan', 'ILMU_PERTANIAN'),
  ('Agribisnis (Sosial Ekonomi Pertanian)', 'ILMU_PERTANIAN'),
  ('Agroteknologi', 'ILMU_PERTANIAN'),
  ('Teknologi Pangan', 'ILMU_PERTANIAN'),
  ('Rekayasa Pertanian', 'ILMU_PERTANIAN'),
  ('Peternakan', 'ILMU_PERTANIAN'),
  ('Agroekologi', 'ILMU_PERTANIAN'),
  ('Kehutanan', 'ILMU_PERTANIAN'),
  ('Budidaya Perairan (Akuakultur)', 'ILMU_PERTANIAN'),
  ('Produksi Ternak', 'ILMU_PERTANIAN'),
  ('Teknologi Hasil Ternak', 'ILMU_PERTANIAN'),
  ('Pengelolaan Hutan', 'ILMU_PERTANIAN'),
  ('Teknologi Hasil Hutan', 'ILMU_PERTANIAN'),
  ('Silvikultur', 'ILMU_PERTANIAN'),
  ('Konservasi Sumberdaya Hutan dan Ekowisata', 'ILMU_PERTANIAN'),
  ('Ilmu Hama dan Penyakit Tumbuhan (Proteksi Tanaman)', 'ILMU_PERTANIAN'),
  ('Teknologi Industri Pertanian (Agroindustri)', 'ILMU_PERTANIAN'),
  ('Manajemen Sumberdaya Lahan (Ilmu Tanah)', 'ILMU_PERTANIAN'),
  ('Teknologi Hasil Perikanan', 'ILMU_PERTANIAN'),
  ('Agrobisnis Perikanan (Sosial Ekonomi Perikanan)', 'ILMU_PERTANIAN'),
  ('Sumber Daya Perairan', 'ILMU_PERTANIAN'),
  ('Pemanfaatan Sumberdaya Perikanan', 'ILMU_PERTANIAN'),
  ('Penyuluhan dan Komunikasi Pertanian', 'ILMU_PERTANIAN'),
  ('Budidaya Perikanan', 'ILMU_PERTANIAN'),
  ('Manajemen Hutan', 'ILMU_PERTANIAN'),
  ('Teknik Pertanian', 'ILMU_PERTANIAN'),
  ('Manajemen Bisnis Unggas', 'ILMU_PERTANIAN'),
  ('Pariwisata', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Penerbang (Pendidikan Pilot)', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Pendidikan Intelijen', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Komunikasi Penerbangan', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Pendidikan Kepolisian', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Pendidikan Militer', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Lalu Lintas Udara', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Manajemen Logistik', 'ILMU_PROFESI_DAN_ILMU_TERAPAN'),
  ('Desain Interior', 'ILMU_SENI'),
  ('Desain Produk', 'ILMU_SENI'),
  ('Animasi', 'ILMU_SENI'),
  ('DKV New Media', 'ILMU_SENI'),
  ('DKV Creative Advertising', 'ILMU_SENI'),
  ('Furniture Design', 'ILMU_SENI'),
  ('Tata Boga', 'ILMU_SENI'),
  ('Desain Grafis', 'ILMU_SENI'),
  ('Teknik Pertambangan', 'ILMU_TEKNIK'),
  ('Teknik Kelautan', 'ILMU_TEKNIK'),
  ('Teknik Lingkungan', 'ILMU_TEKNIK'),
  ('Rekayasa Hayati', 'ILMU_TEKNIK'),
  ('Manajemen Rekayasa Industri', 'ILMU_TEKNIK'),
  ('Teknik Perencanaan Wilayah dan Kota (Planologi)', 'ILMU_TEKNIK'),
  ('Teknik Penerbangan (Aeronautika dan Astronautika)', 'ILMU_TEKNIK'),
  ('Teknik Metalurgi', 'ILMU_TEKNIK'),
  ('Teknik Sipil', 'ILMU_TEKNIK'),
  ('Arsitektur', 'ILMU_TEKNIK'),
  ('Teknik Geodesi', 'ILMU_TEKNIK'),
  ('Teknik Elektro', 'ILMU_TEKNIK'),
  ('Teknik Mesin', 'ILMU_TEKNIK'),
  ('Teknik Industri', 'ILMU_TEKNIK'),
  ('Teknik Perkapalan', 'ILMU_TEKNIK'),
  ('Teknik Otomotif', 'ILMU_TEKNIK'),
  ('Teknobiomedik', 'ILMU_TEKNIK'),
  ('Oseanografi', 'ILMU_TEKNIK'),
  ('Teknik Nuklir', 'ILMU_TEKNIK'),
  ('Teknik Geologi', 'ILMU_TEKNIK'),
  ('Teknik Refrigerasi dan Tata Udara', 'ILMU_TEKNIK'),
  ('Teknik Telekomunikasi', 'ILMU_TEKNIK'),
  ('Teknik Perancangan Jalan dan Jembatan', 'ILMU_TEKNIK'),
  ('Teknik Otomasi Manufaktur dan Mekatronika', 'ILMU_TEKNIK'),
  ('Teknologi Bioproses', 'ILMU_TEKNIK'),
  ('Teknik Grafika', 'ILMU_TEKNIK'),
  ('Transportasi Laut', 'ILMU_TEKNIK'),
  ('Teknik Fisika', 'ILMU_TEKNIK'),
  ('Teknik Geomatika', 'ILMU_TEKNIK'),
  ('Teknik Perminyakan', 'ILMU_TEKNIK'),
  ('Teknik Material', 'ILMU_TEKNIK'),
  ('Automotive and Robotics Engineering', 'ILMU_TEKNIK'),
  ('Teknik Tenaga Listrik', 'ILMU_TEKNIK'),
  ('Teknik Sistem Komputer', 'ILMU_TEKNIK'),
  ('Arsitektur Lanskap', 'ILMU_TEKNIK'),
  ('Teknik Konversi Energi', 'ILMU_TEKNIK'),
  ('Teknik Bioenergi dan Kemurgi', 'ILMU_TEKNIK'),
  ('Industrial Robotics Design', 'ILMU_TEKNIK'),
  ('Teknik Kimia', 'ILMU_TEKNIK'),
  ('Teknik Perpipaan', 'ILMU_TEKNIK'),
  ('Teknik Bangunan dan Landasan', 'ILMU_TEKNIK'),
  ('Teknik Listrik Bandara', 'ILMU_TEKNIK'),
  ('Teknik Alat Berat', 'ILMU_TEKNIK'),
  ('Rekayasa Infrastruktur Lingkungan', 'ILMU_TEKNIK'),
  ('Teknik Pesawat Udara', 'ILMU_TEKNIK'),
  ('Teknik Telekomunikasi dan Navigasi Udara', 'ILMU_TEKNIK'),
  ('Teknik Pengairan (Sumber Daya Air)', 'ILMU_TEKNIK'),
  ('Meteorologi Terapan', 'ILMU_TEKNIK'),
  ('Teknik Ekonomi Konstruksi (Quantity Surveyor)', 'ILMU_TEKNIK'),
  ('Teknik Sistem Perkapalan', 'ILMU_TEKNIK'),
  ('Pendidikan Jasmani, Kesehatan, dan Rekreasi', 'ILMU_OLAHRAGA'),
  ('Pendidikan Kepelatihan Keolahragaan', 'ILMU_OLAHRAGA'),
  ('Ilmu Keolahragaan', 'ILMU_OLAHRAGA'),
  ('Olahraga Rekreasi', 'ILMU_OLAHRAGA'),
  ('Kepelatihan Kecabangan Olahraga', 'ILMU_OLAHRAGA')
) as v(name_id, rumpun_code)
join public.study_programs p on p.name_id = v.name_id
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 4. Aturan percabangan onboarding (matriks dari tim desain)
--
--    Frontend membacanya, bukan menghardcode 20 kombinasi. `major_kind`
--    menentukan pemilih mana yang muncul di Step 1.
-- ---------------------------------------------------------------------------
create table if not exists public.education_step_rules (
  level_code        text not null references public.education_levels(code) on delete cascade,
  graduation_status text not null check (graduation_status in ('sedang_studi','sudah_lulus')),
  major_kind        text check (major_kind in ('smk_concentration','study_program')),
  needs_grade       boolean not null,
  needs_semester    boolean not null,
  primary key (level_code, graduation_status)
);

insert into public.education_step_rules (level_code, graduation_status, major_kind, needs_grade, needs_semester) values
  ('SMP', 'sedang_studi', NULL, true, false),
  ('SMP', 'sudah_lulus', NULL, false, false),
  ('SMA', 'sedang_studi', NULL, true, false),
  ('SMA', 'sudah_lulus', NULL, false, false),
  ('SMK', 'sedang_studi', 'smk_concentration', true, false),
  ('SMK', 'sudah_lulus', 'smk_concentration', false, false),
  ('D1', 'sedang_studi', 'study_program', false, true),
  ('D1', 'sudah_lulus', 'study_program', false, false),
  ('D2', 'sedang_studi', 'study_program', false, true),
  ('D2', 'sudah_lulus', 'study_program', false, false),
  ('D3', 'sedang_studi', 'study_program', false, true),
  ('D3', 'sudah_lulus', 'study_program', false, false),
  ('D4', 'sedang_studi', 'study_program', false, true),
  ('D4', 'sudah_lulus', 'study_program', false, false),
  ('S1', 'sedang_studi', 'study_program', false, true),
  ('S1', 'sudah_lulus', 'study_program', false, false),
  ('S2', 'sedang_studi', 'study_program', false, true),
  ('S2', 'sudah_lulus', 'study_program', false, false),
  ('S3', 'sedang_studi', 'study_program', false, true),
  ('S3', 'sudah_lulus', 'study_program', false, false)
on conflict (level_code, graduation_status) do update set
  major_kind = excluded.major_kind,
  needs_grade = excluded.needs_grade,
  needs_semester = excluded.needs_semester;

-- ---------------------------------------------------------------------------
-- 5. Profil user
--
--    CHECK di bawah menegakkan matriks percabangan di level database. Frontend
--    boleh saja punya bug; data yang mustahil (SMA punya jurusan, lulusan
--    punya semester) tetap tidak akan masuk.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  user_id                uuid primary key references auth.users(id) on delete cascade,
  full_name              text,
  date_of_birth          date,
  city                   text,

  education_level_code   text references public.education_levels(code),
  graduation_status      text check (graduation_status in ('sedang_studi','sudah_lulus')),
  grade_level            smallint check (grade_level between 7 and 12),
  semester               smallint check (semester between 1 and 14),
  is_final_semester      boolean not null default false,
  smk_concentration_id   integer references public.smk_concentrations(id),
  study_program_id       integer references public.study_programs(id),
  study_program_custom   text,
  target_graduation_year smallint,

  weekly_hours           text,
  monthly_budget         text,
  onboarding_completed_at timestamptz,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),

  -- Jurusan hanya untuk SMK; program studi hanya untuk D1 ke atas.
  constraint chk_major_matches_level check (
    case
      when education_level_code in ('SMP','SMA')
        then smk_concentration_id is null and study_program_id is null and study_program_custom is null
      when education_level_code = 'SMK'
        then study_program_id is null and study_program_custom is null
      else smk_concentration_id is null
    end
  ),
  -- Kelas hanya untuk siswa sekolah yang masih menempuh studi.
  constraint chk_grade_only_for_school check (
    grade_level is null or
    (education_level_code in ('SMP','SMA','SMK') and graduation_status = 'sedang_studi')
  ),
  -- Semester hanya untuk mahasiswa yang masih menempuh studi.
  constraint chk_semester_only_for_campus check (
    (semester is null and is_final_semester = false) or
    (education_level_code in ('D1','D2','D3','D4','S1','S2','S3')
     and graduation_status = 'sedang_studi')
  ),
  -- Prodi diisi lewat pilihan ATAU ketikan bebas, tidak dua-duanya.
  constraint chk_one_study_program check (
    study_program_id is null or study_program_custom is null
  )
);

create index if not exists idx_profiles_level on public.profiles(education_level_code);

create or replace function public.touch_profiles_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles
  for each row execute function public.touch_profiles_updated_at();

-- Bikinkan baris profil otomatis saat user mendaftar, supaya onboarding
-- tinggal UPDATE dan tidak perlu memikirkan kasus "baris belum ada".
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 6. RLS
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['smk_expertise_programs','smk_concentrations','study_programs',
                           'study_rumpun','study_program_rumpun','education_step_rules']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_read_all', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t||'_read_all', t);
  end loop;
end $$;

select public.apply_owner_rls('profiles');

commit;
