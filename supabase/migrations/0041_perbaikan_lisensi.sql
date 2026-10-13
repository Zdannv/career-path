-- ===========================================================================
-- 0041_perbaikan_lisensi.sql
--
-- Menyusun ulang lisensi & sertifikasi per profesi.
--
-- ---------------------------------------------------------------------------
-- Kenapa
-- ---------------------------------------------------------------------------
-- Hasil pengujian: Pembuat Pola Pakaian menampilkan "Sertifikat Ahli K3 Umum".
-- Itu bukan salah satu baris, melainkan akibat aturan di 0028 bahwa tiap
-- profesi harus punya minimal tiga lisensi. Profesi yang tidak punya
-- sertifikasi khas lalu diganjal empat entri generik:
--
--   Sertifikat Kompetensi BNSP      458 profesi
--   Sertifikat Magang Bersertifikat 360 profesi
--   TOEFL / IELTS                   342 profesi
--   Sertifikat Ahli K3 Umum         338 profesi
--
-- Pemetaan sisanya dibuat per rumpun, jadi salah di banyak tempat: dosen
-- mendapat Sertifikat Pendidik guru, caregiver dan terapis pijat mendapat STR,
-- juru ledak mendapat sertifikat las, operator jahit mendapat SIO alat berat,
-- pekerja tambang mendapat SKK Konstruksi, kasir mendapat sertifikasi
-- pemasaran digital.
--
-- ---------------------------------------------------------------------------
-- Aturan baru
-- ---------------------------------------------------------------------------
--   * Lisensi hanya dicantumkan kalau memang berlaku untuk profesi itu.
--     Tidak ada lagi jumlah minimum: profesi yang tidak mensyaratkan apa pun
--     boleh kosong, dan layar detail mengatakannya terus terang.
--   * "Sertifikat Kompetensi BNSP" hanya untuk profesi keterampilan yang punya
--     skema sertifikasi (garmen, logam mesin, otomotif, dan sejenisnya).
--   * Sertifikat Magang Bersertifikat dihapus dari katalog: itu bukti
--     pengalaman, bukan sertifikasi profesi.
--   * Katalog ditambah entri yang sebelumnya tidak ada sehingga profesinya
--     dipasangi yang "paling dekat": Serdos, STRV, KIM juru ledak, SIO
--     forklift / crane / boiler, UKW, dan lain-lain.
--
-- Pemetaan ditulis per profesi (id), bukan per rumpun, supaya satu koreksi
-- tidak lagi menjalar ke puluhan profesi lain.
--
-- ---------------------------------------------------------------------------
-- Jalur Pendidikan ikut diperbaiki
-- ---------------------------------------------------------------------------
-- Langkah uji / lisensi / sertifikasi di tab Jalur Pendidikan (0034) disalin
-- dari pemetaan lama, jadi mewarisi kesalahan yang sama: 91 profesi punya
-- langkah "Sertifikat Ahli K3 Umum". Bagian 4 menyusun ulang blok langkah itu
-- dari pemetaan baru. Jalur yang bloknya memang tidak berubah tidak disentuh.
-- Jalur yang berubah diberi nomor langkah baru, sehingga centang pengguna pada
-- jalur itu (0040) ikut terhapus -- nomornya tidak lagi menunjuk langkah yang
-- sama.
--
-- Jalankan setelah 0040. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Katalog
-- ---------------------------------------------------------------------------
alter table public.licenses add column if not exists step_title_id text;

comment on column public.licenses.step_title_id is
  'Judul langkahnya di Jalur Pendidikan, kalau berbeda dari nama lisensinya ("Registrasi STR", "Pengurusan SIP").';
comment on table public.career_licenses is
  'Lisensi dan sertifikasi yang berlaku untuk sebuah profesi. Profesi boleh tidak punya satu pun.';

insert into public.license_issuers (code, name_id) values
  ('AAMAI', 'AAMAI (Asosiasi Ahli Manajemen Asuransi Indonesia)'),
  ('ANRI', 'ANRI (Arsip Nasional Republik Indonesia)'),
  ('DEWAN_PERS', 'Dewan Pers / lembaga uji kompetensi wartawan'),
  ('ESDM', 'Kementerian ESDM'),
  ('FPSB', 'FPSB Indonesia'),
  ('HPI', 'HPI (Himpunan Penerjemah Indonesia)'),
  ('IAPI', 'IAPI (Institut Akuntan Publik Indonesia)'),
  ('KEMENKEU', 'Kementerian Keuangan RI'),
  ('LSPP', 'LSPP / BSMR (lembaga sertifikasi profesi perbankan)'),
  ('MAPPI', 'MAPPI (Masyarakat Profesi Penilai Indonesia) / Kementerian Keuangan'),
  ('PAI', 'PAI (Persatuan Aktuaris Indonesia)'),
  ('PDHI', 'PDHI (Perhimpunan Dokter Hewan Indonesia)'),
  ('PEMDA', 'Pemerintah daerah (dinas terkait / DPMPTSP)'),
  ('PERPUSNAS', 'Perpustakaan Nasional RI / LSP Pustakawan')
on conflict (code) do update set name_id = excluded.name_id;

insert into public.licenses (code, name_id, issuer_code, kind, description_id) values
  ('AAMAI', 'Sertifikasi Ahli Asuransi (AAAIK / AAIK)', 'AAMAI', 'PROFESI', 'Gelar profesi asuransi umum yang lazim diminta untuk posisi underwriting dan klaim.'),
  ('AKTUARIS', 'Gelar Profesi Aktuaris (ASAI / FSAI)', 'PAI', 'PROFESI', 'Diperoleh lewat ujian profesi PAI; FSAI disyaratkan untuk menjadi aktuaris perusahaan.'),
  ('ARSIPARIS', 'Sertifikat Kompetensi Kearsipan', 'ANRI', 'PROFESI', 'Pengakuan kompetensi arsiparis sesuai jenjang jabatan.'),
  ('AUDITOR_ENERGI', 'Sertifikat Kompetensi Auditor Energi', 'BNSP', 'PROFESI', 'Kompetensi melakukan audit energi pada bangunan dan industri.'),
  ('BSMR', 'Sertifikasi Manajemen Risiko Perbankan', 'LSPP', 'PROFESI', 'Disyaratkan regulator bagi pejabat bank yang mengelola risiko dan kredit.'),
  ('CFA', 'CFA (Chartered Financial Analyst)', 'VENDOR', 'TAMBAHAN', 'Sertifikasi internasional analisis investasi.'),
  ('CFE', 'CFE (Certified Fraud Examiner)', 'VENDOR', 'TAMBAHAN', 'Sertifikasi internasional pemeriksaan dan pencegahan kecurangan.'),
  ('CFP', 'Certified Financial Planner (CFP)', 'FPSB', 'PROFESI', 'Sertifikasi perencana keuangan yang diakui secara internasional.'),
  ('CPA', 'CPA Indonesia (Akuntan Publik)', 'IAPI', 'PROFESI', 'Syarat untuk memperoleh izin akuntan publik dan menandatangani laporan audit.'),
  ('ISO_AUDIT', 'Sertifikasi Auditor Sistem Manajemen Mutu (ISO 9001)', 'VENDOR', 'TAMBAHAN', 'Kompetensi mengaudit penerapan sistem manajemen mutu.'),
  ('ISTQB', 'ISTQB Certified Tester', 'VENDOR', 'TAMBAHAN', 'Standar internasional pengujian perangkat lunak.'),
  ('JULEHA', 'Sertifikat Juru Sembelih Halal (Juleha)', 'BNSP', 'PROFESI', 'Kompetensi penyembelihan sesuai syariat dan standar keamanan pangan.'),
  ('KEPABEANAN', 'Sertifikat Ahli Kepabeanan', 'KEMENKEU', 'PROFESI', 'Disyaratkan bagi pengurus jasa kepabeanan (PPJK) untuk mengurus dokumen ekspor-impor.'),
  ('KIM', 'KIM (Kartu Izin Meledakkan) dan Sertifikat Juru Ledak', 'ESDM', 'WAJIB', 'Izin melakukan peledakan di tambang, diberikan kepada pemegang sertifikat juru ledak.'),
  ('MIGAS', 'Sertifikat Kompetensi Tenaga Teknik Migas', 'BNSP', 'PROFESI', 'Kompetensi kerja di kegiatan pemboran, produksi, dan pengolahan minyak dan gas.'),
  ('PENERJEMAH', 'Sertifikasi Penerjemah (HPI)', 'HPI', 'PROFESI', 'Pengakuan kompetensi penerjemah atau juru bahasa lewat tes sertifikasi nasional.'),
  ('PENILAI', 'Sertifikasi Penilai (MAPPI) / Izin Penilai Publik', 'MAPPI', 'PROFESI', 'Jenjang sertifikasi penilai; izin penilai publik diterbitkan Kementerian Keuangan.'),
  ('POP', 'Sertifikat Pengawas Operasional Pertama (POP)', 'ESDM', 'PROFESI', 'Kompetensi pengawas operasional di pertambangan mineral dan batubara.'),
  ('PUSTAKAWAN', 'Sertifikat Kompetensi Pustakawan', 'PERPUSNAS', 'PROFESI', 'Pengakuan kompetensi pustakawan sesuai standar nasional.'),
  ('SCM', 'Sertifikasi Supply Chain (CSCP / CPIM)', 'VENDOR', 'TAMBAHAN', 'Sertifikasi internasional perencanaan, pengadaan, dan rantai pasok.'),
  ('SEC_CERT', 'Sertifikasi Keamanan Siber (CEH / OSCP / CISSP)', 'VENDOR', 'PROFESI', 'Bukti kemampuan menguji dan mengamankan sistem yang lazim diminta posisi keamanan.'),
  ('SERDOS', 'Sertifikat Pendidik Dosen (Serdos)', 'KEMDIKBUD', 'PROFESI', 'Pengakuan dosen profesional, diperoleh lewat sertifikasi dosen setelah memenuhi masa kerja.'),
  ('SIM_C', 'SIM C / SIM A', 'POLRI', 'WAJIB', 'Izin mengemudi sepeda motor atau mobil untuk pekerjaan antar dan lapangan.'),
  ('SIO_BOILER', 'Lisensi K3 Operator Boiler (Pesawat Uap)', 'KEMNAKER', 'WAJIB', 'Izin mengoperasikan ketel uap dan bejana tekan di tempat kerja.'),
  ('SIO_CRANE', 'SIO Crane / Pesawat Angkat', 'KEMNAKER', 'WAJIB', 'Izin mengoperasikan crane, hoist, dan pesawat angkat sejenis.'),
  ('SIO_FORKLIFT', 'SIO Forklift', 'KEMNAKER', 'WAJIB', 'Izin mengoperasikan forklift dan kendaraan angkut industri.'),
  ('SIP_DRH', 'SIP Dokter Hewan', 'PEMDA', 'WAJIB', 'Izin praktik dokter hewan, diterbitkan pemerintah daerah setelah STRV terbit.'),
  ('SIPTTK', 'SIPTTK (Surat Izin Praktik Tenaga Teknis Kefarmasian)', 'DINKES', 'WAJIB', 'Izin praktik tenaga teknis kefarmasian di apotek, rumah sakit, atau industri farmasi.'),
  ('STPT', 'STPT (Surat Terdaftar Penyehat Tradisional)', 'DINKES', 'WAJIB', 'Tanda terdaftar bagi penyehat tradisional, termasuk terapis pijat.'),
  ('STRV', 'STRV (Surat Tanda Registrasi Veteriner)', 'PDHI', 'WAJIB', 'Registrasi dokter hewan setelah lulus pendidikan profesi dan uji kompetensi.'),
  ('UKMPPD', 'Uji Kompetensi Dokter / Dokter Gigi (UKMPPD / UKMP2DG)', 'KEMDIKBUD', 'WAJIB', 'Ujian nasional di akhir pendidikan profesi, syarat sertifikat kompetensi dan STR.'),
  ('UKW', 'Sertifikat Kompetensi Wartawan (UKW)', 'DEWAN_PERS', 'PROFESI', 'Jenjang muda, madya, dan utama; lazim disyaratkan perusahaan pers.'),
  ('UX_CERT', 'Sertifikasi UX Design (Google UX / NN/g)', 'VENDOR', 'TAMBAHAN', 'Pelatihan bersertifikat riset pengguna dan perancangan antarmuka.')
on conflict (code) do update set
  name_id = excluded.name_id, issuer_code = excluded.issuer_code,
  kind = excluded.kind, description_id = excluded.description_id;

-- Yang sudah ada, dikoreksi.
update public.licenses set
  name_id = 'SKTTK (Sertifikat Kompetensi Tenaga Teknik Ketenagalistrikan)', issuer_code = 'ESDM'
where code = 'LISTRIK';
update public.licenses set
  description_id = 'Sertifikat kompetensi kerja nasional, diuji lembaga sertifikasi profesi (LSP) sesuai skema bidangnya.'
where code = 'BNSP';
update public.licenses set
  description_id = 'Disyaratkan untuk dosen, penerjemah, dan studi lanjut; banyak diminta perusahaan multinasional.'
where code = 'TOEFL';
update public.licenses set
  description_id = 'Kompetensi keselamatan dan kesehatan kerja yang diakui Kemnaker, untuk petugas dan pengawas K3.'
where code = 'K3_UMUM';

-- Judul langkah di Jalur Pendidikan, mempertahankan kalimat yang dipakai 0034.
update public.licenses l set step_title_id = j.judul
from (values
  ('STR', 'Registrasi STR'),
  ('SIP', 'Pengurusan SIP (Surat Izin Praktik)'),
  ('SIPD', 'Pengurusan SIP Dokter'),
  ('SIPP', 'Pengurusan SIPP (Izin Praktik Perawat)'),
  ('SIPA', 'Pengurusan SIPA (Izin Praktik Apoteker)'),
  ('SIPB', 'Pengurusan SIPB (Izin Praktik Bidan)'),
  ('SIPTTK', 'Pengurusan SIPTTK (Izin Praktik Tenaga Teknis Kefarmasian)'),
  ('STRV', 'Registrasi STRV (Veteriner)'),
  ('SIP_DRH', 'Pengurusan SIP Dokter Hewan'),
  ('STPT', 'Pendaftaran STPT (Penyehat Tradisional)'),
  ('SERDIK', 'Pendidikan Profesi Guru (PPG) dan Sertifikat Pendidik'),
  ('NIDN', 'Pengurusan NIDN'),
  ('STRI', 'Registrasi STRI (Insinyur)'),
  ('SKK', 'Sertifikat Kompetensi Kerja (SKK) Konstruksi'),
  ('SKA_ARS', 'Registrasi STRA (Arsitek)'),
  ('AAJI', 'Lisensi Keagenan Asuransi'),
  ('WPPE', 'Izin Pasar Modal (WPPE/WMI)'),
  ('AMEL', 'Lisensi AMEL'),
  ('COC_LAUT', 'Sertifikat Keahlian Pelaut (COC)'),
  ('SIM_B', 'Pengurusan SIM B Umum'),
  ('SIM_C', 'Pengurusan SIM C / SIM A'),
  ('LISTRIK', 'Sertifikat Kompetensi Ketenagalistrikan'),
  ('KIM', 'Sertifikat Juru Ledak dan KIM')
) as j(kode, judul)
where l.code = j.kode;

-- ---------------------------------------------------------------------------
-- 2. Pemetaan per profesi
--
-- Diganti seluruhnya. Profesi yang tidak muncul di bawah memang tidak punya
-- lisensi atau sertifikasi yang lazim disyaratkan.
-- ---------------------------------------------------------------------------
delete from public.career_licenses;
delete from public.licenses where code = 'MSIB';

insert into public.career_licenses (career_id, license_code, display_order) values
  (1, 'BNSP_TIK', 1),
  (2, 'BNSP_TIK', 1),
  (2, 'CLOUD', 2),
  (3, 'BNSP_TIK', 1),
  (3, 'CLOUD', 2),
  (4, 'BNSP_TIK', 1),
  (5, 'BNSP_TIK', 1),
  (6, 'BNSP_TIK', 1),
  (7, 'DATA_CERT', 1),
  (7, 'BNSP_TIK', 2),
  (8, 'DATA_CERT', 1),
  (8, 'BNSP_TIK', 2),
  (9, 'CLOUD', 1),
  (9, 'DATA_CERT', 2),
  (9, 'BNSP_TIK', 3),
  (10, 'DATA_CERT', 1),
  (10, 'CLOUD', 2),
  (10, 'BNSP_TIK', 3),
  (11, 'DATA_CERT', 1),
  (11, 'CLOUD', 2),
  (11, 'BNSP_TIK', 3),
  (12, 'CLOUD', 1),
  (12, 'BNSP_TIK', 2),
  (13, 'CLOUD', 1),
  (13, 'BNSP_TIK', 2),
  (14, 'CLOUD', 1),
  (14, 'BNSP_TIK', 2),
  (15, 'CLOUD', 1),
  (15, 'BNSP_TIK', 2),
  (16, 'CLOUD', 1),
  (16, 'BNSP_TIK', 2),
  (17, 'CLOUD', 1),
  (17, 'BNSP_TIK', 2),
  (18, 'SEC_CERT', 1),
  (18, 'COMPTIA', 2),
  (18, 'SPBE', 3),
  (18, 'BNSP_TIK', 4),
  (19, 'SEC_CERT', 1),
  (19, 'COMPTIA', 2),
  (19, 'BNSP_TIK', 3),
  (20, 'UX_CERT', 1),
  (21, 'SCRUM', 1),
  (21, 'PMP', 2),
  (22, 'ISTQB', 1),
  (22, 'BNSP_TIK', 2),
  (23, 'PMP', 1),
  (23, 'SCRUM', 2),
  (23, 'BNSP_TIK', 3),
  (24, 'COMPTIA', 1),
  (24, 'BNSP_TIK', 2),
  (25, 'COMPTIA', 1),
  (25, 'CLOUD', 2),
  (25, 'BNSP_TIK', 3),
  (26, 'CCNA', 1),
  (26, 'COMPTIA', 2),
  (26, 'BNSP_TIK', 3),
  (27, 'CLOUD', 1),
  (27, 'BNSP_TIK', 2),
  (28, 'SCRUM', 1),
  (28, 'PMP', 2),
  (29, 'DIGITAL_MKT', 1),
  (29, 'DATA_CERT', 2),
  (30, 'BNSP_TIK', 1),
  (31, 'BNSP_TIK', 1),
  (31, 'SCRUM', 2),
  (32, 'BNSP_TIK', 1),
  (33, 'BNSP_TIK', 1),
  (34, 'BNSP_TIK', 1),
  (34, 'CLOUD', 2),
  (36, 'DIGITAL_MKT', 1),
  (39, 'CA', 1),
  (39, 'BREVET', 2),
  (40, 'CA', 1),
  (40, 'BREVET', 2),
  (41, 'WPPE', 1),
  (41, 'CFA', 2),
  (42, 'K3_UMUM', 1),
  (42, 'PMP', 2),
  (43, 'ISO_AUDIT', 1),
  (48, 'SCM', 1),
  (49, 'SCM', 1),
  (49, 'PMP', 2),
  (58, 'SCM', 1),
  (59, 'SCM', 1),
  (60, 'SCM', 1),
  (61, 'AAMAI', 1),
  (68, 'SCM', 1),
  (69, 'SCM', 1),
  (70, 'SCM', 1),
  (71, 'DIGITAL_MKT', 1),
  (72, 'CA', 1),
  (72, 'CPA', 2),
  (72, 'BREVET', 3),
  (73, 'PENILAI', 1),
  (74, 'PENILAI', 1),
  (76, 'BSMR', 1),
  (77, 'CFA', 1),
  (77, 'WPPE', 2),
  (78, 'CFP', 1),
  (79, 'AAMAI', 1),
  (80, 'BSMR', 1),
  (80, 'CFA', 2),
  (81, 'CA', 1),
  (81, 'BSMR', 2),
  (82, 'CFP', 1),
  (83, 'BSMR', 1),
  (84, 'BREVET', 1),
  (87, 'CFA', 1),
  (88, 'CFE', 1),
  (89, 'BNSP_TIK', 1),
  (90, 'CCNA', 1),
  (90, 'COMPTIA', 2),
  (90, 'BNSP_TIK', 3),
  (91, 'CCNA', 1),
  (91, 'BNSP_TIK', 2),
  (92, 'CLOUD', 1),
  (92, 'BNSP_TIK', 2),
  (93, 'BNSP_TIK', 1),
  (95, 'BNSP_TIK', 1),
  (96, 'BNSP_TIK', 1),
  (98, 'SEC_CERT', 1),
  (98, 'COMPTIA', 2),
  (98, 'SPBE', 3),
  (98, 'CLOUD', 4),
  (99, 'SEC_CERT', 1),
  (99, 'BNSP_TIK', 2),
  (100, 'CLOUD', 1),
  (100, 'BNSP_TIK', 2),
  (101, 'AKTUARIS', 1),
  (102, 'DATA_CERT', 1),
  (103, 'DATA_CERT', 1),
  (104, 'DATA_CERT', 1),
  (105, 'DATA_CERT', 1),
  (106, 'STRI', 1),
  (106, 'K3_UMUM', 2),
  (106, 'IP_PII', 3),
  (107, 'STRI', 1),
  (107, 'K3_UMUM', 2),
  (107, 'IP_PII', 3),
  (108, 'STRI', 1),
  (108, 'IP_PII', 2),
  (109, 'STRI', 1),
  (109, 'K3_UMUM', 2),
  (109, 'IP_PII', 3),
  (110, 'STRI', 1),
  (110, 'IP_PII', 2),
  (111, 'STRI', 1),
  (111, 'IP_PII', 2),
  (112, 'STRI', 1),
  (112, 'IP_PII', 2),
  (113, 'STRI', 1),
  (113, 'IP_PII', 2),
  (114, 'STRI', 1),
  (114, 'IP_PII', 2),
  (116, 'STRI', 1),
  (116, 'IP_PII', 2),
  (117, 'STRI', 1),
  (117, 'POP', 2),
  (117, 'IP_PII', 3),
  (118, 'STRI', 1),
  (118, 'PROTEKSI_RAD', 2),
  (118, 'IP_PII', 3),
  (119, 'STRI', 1),
  (119, 'MIGAS', 2),
  (119, 'IP_PII', 3),
  (121, 'STRI', 1),
  (121, 'IP_PII', 2),
  (122, 'STRI', 1),
  (122, 'IP_PII', 2),
  (125, 'STRI', 1),
  (125, 'IP_PII', 2),
  (127, 'STRI', 1),
  (127, 'LISTRIK', 2),
  (127, 'IP_PII', 3),
  (128, 'STRI', 1),
  (128, 'LISTRIK', 2),
  (128, 'IP_PII', 3),
  (129, 'BNSP', 1),
  (131, 'BNSP', 1),
  (132, 'BNSP', 1),
  (133, 'HACCP', 1),
  (135, 'HACCP', 1),
  (136, 'BNSP', 1),
  (139, 'BNSP', 1),
  (140, 'NIDN', 1),
  (140, 'SERDOS', 2),
  (140, 'TOEFL', 3),
  (141, 'NIDN', 1),
  (141, 'SERDOS', 2),
  (141, 'TOEFL', 3),
  (142, 'NIDN', 1),
  (142, 'SERDOS', 2),
  (142, 'TOEFL', 3),
  (143, 'NIDN', 1),
  (143, 'SERDOS', 2),
  (143, 'TOEFL', 3),
  (144, 'NIDN', 1),
  (144, 'SERDOS', 2),
  (144, 'TOEFL', 3),
  (145, 'NIDN', 1),
  (145, 'SERDOS', 2),
  (145, 'TOEFL', 3),
  (146, 'NIDN', 1),
  (146, 'SERDOS', 2),
  (146, 'TOEFL', 3),
  (147, 'NIDN', 1),
  (147, 'SERDOS', 2),
  (147, 'TOEFL', 3),
  (148, 'NIDN', 1),
  (148, 'SERDOS', 2),
  (148, 'TOEFL', 3),
  (149, 'NIDN', 1),
  (149, 'SERDOS', 2),
  (149, 'TOEFL', 3),
  (150, 'NIDN', 1),
  (150, 'SERDOS', 2),
  (150, 'TOEFL', 3),
  (151, 'NIDN', 1),
  (151, 'SERDOS', 2),
  (151, 'TOEFL', 3),
  (152, 'NIDN', 1),
  (152, 'SERDOS', 2),
  (152, 'TOEFL', 3),
  (153, 'NIDN', 1),
  (153, 'SERDOS', 2),
  (153, 'TOEFL', 3),
  (154, 'NIDN', 1),
  (154, 'SERDOS', 2),
  (154, 'TOEFL', 3),
  (155, 'NIDN', 1),
  (155, 'SERDOS', 2),
  (155, 'TOEFL', 3),
  (156, 'NIDN', 1),
  (156, 'SERDOS', 2),
  (156, 'TOEFL', 3),
  (157, 'NIDN', 1),
  (157, 'SERDOS', 2),
  (157, 'TOEFL', 3),
  (158, 'NIDN', 1),
  (158, 'SERDOS', 2),
  (158, 'TOEFL', 3),
  (160, 'NIDN', 1),
  (160, 'SERDOS', 2),
  (160, 'TOEFL', 3),
  (161, 'NIDN', 1),
  (161, 'SERDOS', 2),
  (161, 'TOEFL', 3),
  (162, 'NIDN', 1),
  (162, 'SERDOS', 2),
  (162, 'TOEFL', 3),
  (163, 'NIDN', 1),
  (163, 'SERDOS', 2),
  (163, 'TOEFL', 3),
  (164, 'NIDN', 1),
  (164, 'SERDOS', 2),
  (164, 'TOEFL', 3),
  (165, 'NIDN', 1),
  (165, 'SERDOS', 2),
  (165, 'TOEFL', 3),
  (166, 'NIDN', 1),
  (166, 'SERDOS', 2),
  (166, 'TOEFL', 3),
  (167, 'NIDN', 1),
  (167, 'SERDOS', 2),
  (167, 'TOEFL', 3),
  (168, 'NIDN', 1),
  (168, 'SERDOS', 2),
  (168, 'TOEFL', 3),
  (169, 'NIDN', 1),
  (169, 'SERDOS', 2),
  (169, 'TOEFL', 3),
  (170, 'NIDN', 1),
  (170, 'SERDOS', 2),
  (170, 'TOEFL', 3),
  (171, 'NIDN', 1),
  (171, 'SERDOS', 2),
  (171, 'TOEFL', 3),
  (172, 'NIDN', 1),
  (172, 'SERDOS', 2),
  (172, 'TOEFL', 3),
  (173, 'NIDN', 1),
  (173, 'SERDOS', 2),
  (173, 'TOEFL', 3),
  (174, 'NIDN', 1),
  (174, 'SERDOS', 2),
  (174, 'TOEFL', 3),
  (175, 'BNSP', 1),
  (177, 'SERDIK', 1),
  (177, 'NUPTK', 2),
  (178, 'SERDIK', 1),
  (178, 'NUPTK', 2),
  (179, 'SERDIK', 1),
  (179, 'NUPTK', 2),
  (180, 'SERDIK', 1),
  (180, 'NUPTK', 2),
  (181, 'SERDIK', 1),
  (181, 'NUPTK', 2),
  (182, 'SERDIK', 1),
  (182, 'NUPTK', 2),
  (183, 'SERDIK', 1),
  (183, 'NUPTK', 2),
  (184, 'SERDIK', 1),
  (184, 'NUPTK', 2),
  (185, 'SERDIK', 1),
  (185, 'NUPTK', 2),
  (186, 'SERDIK', 1),
  (186, 'NUPTK', 2),
  (187, 'SERDIK', 1),
  (187, 'NUPTK', 2),
  (188, 'SERDIK', 1),
  (188, 'NUPTK', 2),
  (190, 'SERDIK', 1),
  (190, 'NUPTK', 2),
  (191, 'NUPTK', 1),
  (196, 'ARSIPARIS', 1),
  (199, 'PUSTAKAWAN', 1),
  (200, 'PUSTAKAWAN', 1),
  (201, 'BNSP', 1),
  (204, 'SERDIK', 1),
  (204, 'NUPTK', 2),
  (205, 'TOEFL', 1),
  (211, 'BNSP', 1),
  (214, 'BNSP', 1),
  (216, 'BNSP', 1),
  (217, 'BNSP', 1),
  (227, 'UKW', 1),
  (228, 'BNSP', 1),
  (229, 'BNSP', 1),
  (232, 'PENERJEMAH', 1),
  (232, 'TOEFL', 2),
  (236, 'BNSP', 1),
  (239, 'BNSP', 1),
  (241, 'BNSP', 1),
  (244, 'UKMPPD', 1),
  (244, 'STR', 2),
  (244, 'SIPD', 3),
  (245, 'UKMPPD', 1),
  (245, 'STR', 2),
  (245, 'SIPD', 3),
  (246, 'UKMPPD', 1),
  (246, 'STR', 2),
  (246, 'SIPD', 3),
  (247, 'UKMPPD', 1),
  (247, 'STR', 2),
  (247, 'SIPD', 3),
  (249, 'UKOM', 1),
  (249, 'STR', 2),
  (249, 'SIP', 3),
  (250, 'UKOM', 1),
  (250, 'STR', 2),
  (250, 'SIP', 3),
  (251, 'UKOM', 1),
  (251, 'STR', 2),
  (251, 'SIPA', 3),
  (255, 'UKOM', 1),
  (255, 'STR', 2),
  (255, 'SIP', 3),
  (257, 'UKOM', 1),
  (257, 'STR', 2),
  (257, 'SIP', 3),
  (258, 'UKOM', 1),
  (258, 'STR', 2),
  (258, 'SIP', 3),
  (258, 'PROTEKSI_RAD', 4),
  (260, 'UKOM', 1),
  (260, 'STR', 2),
  (260, 'SIP', 3),
  (261, 'UKOM', 1),
  (261, 'STR', 2),
  (261, 'SIP', 3),
  (266, 'STRV', 1),
  (266, 'SIP_DRH', 2),
  (267, 'UKOM', 1),
  (267, 'STR', 2),
  (267, 'SIPP', 3),
  (267, 'BTCLS', 4),
  (268, 'UKOM', 1),
  (268, 'STR', 2),
  (268, 'SIPP', 3),
  (268, 'BTCLS', 4),
  (269, 'UKOM', 1),
  (269, 'STR', 2),
  (269, 'SIPP', 3),
  (269, 'BTCLS', 4),
  (270, 'UKOM', 1),
  (270, 'STR', 2),
  (270, 'SIPP', 3),
  (270, 'BTCLS', 4),
  (270, 'ACLS', 5),
  (271, 'UKOM', 1),
  (271, 'STR', 2),
  (271, 'SIPP', 3),
  (271, 'BTCLS', 4),
  (272, 'UKOM', 1),
  (272, 'STR', 2),
  (272, 'SIP', 3),
  (272, 'BTCLS', 4),
  (273, 'UKOM', 1),
  (273, 'STR', 2),
  (273, 'SIPB', 3),
  (275, 'UKOM', 1),
  (275, 'STR', 2),
  (275, 'SIP', 3),
  (276, 'UKMPPD', 1),
  (276, 'STR', 2),
  (276, 'SIPD', 3),
  (276, 'ACLS', 4),
  (277, 'UKMPPD', 1),
  (277, 'STR', 2),
  (277, 'SIPD', 3),
  (277, 'ACLS', 4),
  (278, 'UKMPPD', 1),
  (278, 'STR', 2),
  (278, 'SIPD', 3),
  (279, 'UKMPPD', 1),
  (279, 'STR', 2),
  (279, 'SIPD', 3),
  (279, 'ACLS', 4),
  (280, 'UKMPPD', 1),
  (280, 'STR', 2),
  (280, 'SIPD', 3),
  (280, 'ACLS', 4),
  (281, 'UKMPPD', 1),
  (281, 'STR', 2),
  (281, 'SIPD', 3),
  (282, 'UKMPPD', 1),
  (282, 'STR', 2),
  (282, 'SIPD', 3),
  (283, 'UKMPPD', 1),
  (283, 'STR', 2),
  (283, 'SIPD', 3),
  (284, 'UKMPPD', 1),
  (284, 'STR', 2),
  (284, 'SIPD', 3),
  (285, 'UKMPPD', 1),
  (285, 'STR', 2),
  (285, 'SIPD', 3),
  (286, 'UKMPPD', 1),
  (286, 'STR', 2),
  (286, 'SIPD', 3),
  (287, 'UKMPPD', 1),
  (287, 'STR', 2),
  (287, 'SIPD', 3),
  (287, 'PROTEKSI_RAD', 4),
  (289, 'UKMPPD', 1),
  (289, 'STR', 2),
  (289, 'SIPD', 3),
  (291, 'UKMPPD', 1),
  (291, 'STR', 2),
  (291, 'SIPD', 3),
  (292, 'UKMPPD', 1),
  (292, 'STR', 2),
  (292, 'SIPD', 3),
  (293, 'UKMPPD', 1),
  (293, 'STR', 2),
  (293, 'SIPD', 3),
  (294, 'UKMPPD', 1),
  (294, 'STR', 2),
  (294, 'SIPD', 3),
  (295, 'UKMPPD', 1),
  (295, 'STR', 2),
  (295, 'SIPD', 3),
  (296, 'UKMPPD', 1),
  (296, 'STR', 2),
  (296, 'SIPD', 3),
  (297, 'UKMPPD', 1),
  (297, 'STR', 2),
  (297, 'SIPD', 3),
  (299, 'UKOM', 1),
  (299, 'STR', 2),
  (299, 'SIP', 3),
  (300, 'UKOM', 1),
  (300, 'STR', 2),
  (300, 'SIP', 3),
  (304, 'UKOM', 1),
  (304, 'STR', 2),
  (304, 'SIP', 3),
  (305, 'UKOM', 1),
  (305, 'STR', 2),
  (305, 'SIP', 3),
  (306, 'UKOM', 1),
  (306, 'STR', 2),
  (306, 'SIP', 3),
  (307, 'UKOM', 1),
  (307, 'STR', 2),
  (307, 'SIP', 3),
  (308, 'UKOM', 1),
  (308, 'STR', 2),
  (308, 'SIP', 3),
  (309, 'UKOM', 1),
  (309, 'STR', 2),
  (309, 'SIP', 3),
  (310, 'UKOM', 1),
  (310, 'STR', 2),
  (310, 'SIP', 3),
  (310, 'BLS', 4),
  (311, 'UKOM', 1),
  (311, 'STR', 2),
  (311, 'SIP', 3),
  (312, 'UKOM', 1),
  (312, 'STR', 2),
  (312, 'SIP', 3),
  (312, 'PROTEKSI_RAD', 4),
  (313, 'UKOM', 1),
  (313, 'STR', 2),
  (313, 'SIP', 3),
  (313, 'PROTEKSI_RAD', 4),
  (314, 'UKOM', 1),
  (314, 'STR', 2),
  (314, 'SIP', 3),
  (315, 'UKOM', 1),
  (315, 'STR', 2),
  (315, 'SIP', 3),
  (315, 'PROTEKSI_RAD', 4),
  (316, 'BTCLS', 1),
  (316, 'BLS', 2),
  (317, 'BTCLS', 1),
  (317, 'BLS', 2),
  (318, 'UKOM', 1),
  (318, 'STR', 2),
  (318, 'SIP', 3),
  (319, 'UKOM', 1),
  (319, 'STR', 2),
  (319, 'SIPTTK', 3),
  (321, 'UKOM', 1),
  (321, 'STR', 2),
  (321, 'SIPP', 3),
  (321, 'KAMAR_BEDAH', 4),
  (323, 'UKOM', 1),
  (323, 'STR', 2),
  (323, 'SIP', 3),
  (324, 'UKOM', 1),
  (324, 'STR', 2),
  (324, 'SIPP', 3),
  (324, 'BTCLS', 4),
  (325, 'UKOM', 1),
  (325, 'STR', 2),
  (325, 'SIP', 3),
  (326, 'UKOM', 1),
  (326, 'STR', 2),
  (326, 'SIP', 3),
  (327, 'UKOM', 1),
  (327, 'STR', 2),
  (327, 'SIP', 3),
  (330, 'BLS', 1),
  (331, 'BLS', 1),
  (333, 'UKOM', 1),
  (333, 'STR', 2),
  (333, 'SIP', 3),
  (334, 'UKOM', 1),
  (334, 'STR', 2),
  (334, 'SIP', 3),
  (336, 'UKOM', 1),
  (336, 'STR', 2),
  (336, 'SIPP', 3),
  (336, 'KAMAR_BEDAH', 4),
  (338, 'UKOM', 1),
  (338, 'STR', 2),
  (338, 'SIPB', 3),
  (339, 'BNSP', 1),
  (339, 'BLS', 2),
  (340, 'BNSP', 1),
  (340, 'BLS', 2),
  (341, 'BNSP', 1),
  (341, 'BLS', 2),
  (342, 'BLS', 1),
  (343, 'BLS', 1),
  (346, 'BLS', 1),
  (348, 'STPT', 1),
  (348, 'BNSP', 2),
  (349, 'PPI', 1),
  (351, 'PPI', 1),
  (355, 'PPI', 1),
  (355, 'BLS', 2),
  (358, 'PPI', 1),
  (358, 'BLS', 2),
  (360, 'BNSP', 1),
  (368, 'DIGITAL_MKT', 1),
  (369, 'AAJI', 1),
  (370, 'WPPE', 1),
  (371, 'PARIWISATA', 1),
  (378, 'BNSP', 1),
  (379, 'BNSP', 1),
  (390, 'KEPABEANAN', 1),
  (391, 'KEPABEANAN', 1),
  (392, 'SIM_C', 1),
  (396, 'SIM_C', 1),
  (398, 'SCM', 1),
  (401, 'LISTRIK', 1),
  (401, 'K3_UMUM', 2),
  (402, 'BNSP', 1),
  (403, 'LISTRIK', 1),
  (403, 'BNSP', 2),
  (404, 'AUDITOR_ENERGI', 1),
  (405, 'MIGAS', 1),
  (406, 'MIGAS', 1),
  (407, 'MIGAS', 1),
  (408, 'OPERATOR', 1),
  (409, 'BNSP', 1),
  (410, 'KIM', 1),
  (411, 'OPERATOR', 1),
  (412, 'OPERATOR', 1),
  (413, 'OPERATOR', 1),
  (421, 'AMEL', 1),
  (422, 'BNSP', 1),
  (424, 'BNSP', 1),
  (425, 'BNSP', 1),
  (426, 'BNSP', 1),
  (427, 'BNSP', 1),
  (428, 'BNSP', 1),
  (429, 'BNSP', 1),
  (430, 'BNSP', 1),
  (435, 'BNSP', 1),
  (437, 'LISTRIK', 1),
  (438, 'K3_UMUM', 1),
  (439, 'BNSP', 1),
  (441, 'BNSP', 1),
  (442, 'BNSP', 1),
  (444, 'LAS', 1),
  (444, 'BNSP', 2),
  (449, 'HIGIENE', 1),
  (449, 'BNSP', 2),
  (450, 'JULEHA', 1),
  (450, 'HIGIENE', 2),
  (451, 'JULEHA', 1),
  (451, 'HIGIENE', 2),
  (451, 'HACCP', 3),
  (452, 'JULEHA', 1),
  (452, 'HIGIENE', 2),
  (452, 'HACCP', 3),
  (453, 'HACCP', 1),
  (454, 'HIGIENE', 1),
  (454, 'HACCP', 2),
  (455, 'HACCP', 1),
  (463, 'BNSP', 1),
  (464, 'BNSP', 1),
  (465, 'BNSP', 1),
  (466, 'BNSP', 1),
  (467, 'BNSP', 1),
  (468, 'BNSP', 1),
  (469, 'BNSP', 1),
  (470, 'BNSP', 1),
  (472, 'BNSP', 1),
  (473, 'BNSP', 1),
  (474, 'LAS', 1),
  (474, 'BNSP', 2),
  (475, 'LAS', 1),
  (481, 'BNSP', 1),
  (482, 'BNSP', 1),
  (486, 'BNSP', 1),
  (490, 'BNSP', 1),
  (496, 'BNSP', 1),
  (499, 'BNSP', 1),
  (507, 'LISTRIK', 1),
  (508, 'LISTRIK', 1),
  (509, 'LISTRIK', 1),
  (510, 'LISTRIK', 1),
  (511, 'SIO_BOILER', 1),
  (512, 'BNSP', 1),
  (514, 'MIGAS', 1),
  (515, 'MIGAS', 1),
  (538, 'BNSP', 1),
  (539, 'BNSP', 1),
  (552, 'SIM_C', 1),
  (555, 'SIO_CRANE', 1),
  (556, 'COC_LAUT', 1),
  (557, 'SIO_CRANE', 1),
  (558, 'SIO_FORKLIFT', 1),
  (565, 'MIGAS', 1),
  (567, 'MIGAS', 1);

-- ---------------------------------------------------------------------------
-- 3. Tampilan: tidak berubah bentuk, hanya dibuat ulang supaya pasti segar
-- ---------------------------------------------------------------------------
create or replace view public.career_license_view
with (security_invoker = true) as
select cl.career_id,
       l.code    as license_code,
       l.name_id as nama,
       i.name_id as penerbit,
       l.kind    as sifat,
       l.description_id as deskripsi,
       cl.display_order
from public.career_licenses cl
join public.licenses l        on l.code = cl.license_code
join public.license_issuers i on i.code = l.issuer_code;

-- ---------------------------------------------------------------------------
-- 4. Jalur Pendidikan: blok uji / lisensi / sertifikasi disusun ulang
--
-- Isi blok: semua lisensi WAJIB (uji kompetensi lebih dulu, lalu registrasi
-- dan izin sesuai urutan di pemetaan), ditutup satu sertifikasi PROFESI
-- pertama kalau ada. Sertifikasi TAMBAHAN tidak masuk jalur.
--
-- Bloknya diletakkan di tempat blok lama berada. Jalur yang sebelumnya tidak
-- punya blok mendapatkannya tepat sebelum langkah kerja atau tujuan.
-- ---------------------------------------------------------------------------
do $$
declare
  p record;
  v_lama text[];
  v_baru text[];
  v_pos  int;
  v_ubah int := 0;
  v_centang int := 0;
  v_n int;
begin
  create temp table _blok (urut int, title_id text, note_id text, step_kind text) on commit drop;
  create temp table _sisa (step_order int, title_id text, note_id text, step_rank smallint, step_kind text)
    on commit drop;

  for p in select id, career_id from public.career_education_paths order by id loop
    truncate _blok;
    insert into _blok
    select row_number() over (order by x.kelas, x.display_order),
           x.judul, x.deskripsi, x.jenis
    from (
      select coalesce(l.step_title_id, l.name_id) as judul, l.description_id as deskripsi,
             case when l.code in ('UKOM', 'UKMPPD') then 'UJI' else 'LISENSI' end as jenis,
             case when l.code in ('UKOM', 'UKMPPD') then 0 else 1 end as kelas,
             cl.display_order
      from public.career_licenses cl join public.licenses l on l.code = cl.license_code
      where cl.career_id = p.career_id and l.kind = 'WAJIB'
      union all
      (select coalesce(l.step_title_id, l.name_id), l.description_id, 'SERTIFIKASI', 2, cl.display_order
       from public.career_licenses cl join public.licenses l on l.code = cl.license_code
       where cl.career_id = p.career_id and l.kind = 'PROFESI'
       order by cl.display_order limit 1)
    ) x;

    select coalesce(array_agg(s.step_kind || ':' || s.title_id order by s.step_order), '{}')
      into v_lama
    from public.career_education_path_steps s
    where s.path_id = p.id and s.step_kind in ('UJI', 'LISENSI', 'SERTIFIKASI');

    select coalesce(array_agg(b.step_kind || ':' || b.title_id order by b.urut), '{}')
      into v_baru from _blok b;

    continue when v_lama = v_baru;

    select min(s.step_order) into v_pos
    from public.career_education_path_steps s
    where s.path_id = p.id and s.step_kind in ('UJI', 'LISENSI', 'SERTIFIKASI');
    if v_pos is null then
      select min(s.step_order) into v_pos
      from public.career_education_path_steps s
      where s.path_id = p.id and s.step_kind in ('KERJA', 'SPESIALISASI', 'TUJUAN');
    end if;

    truncate _sisa;
    insert into _sisa
    select s.step_order, s.title_id, s.note_id, s.step_rank, s.step_kind
    from public.career_education_path_steps s
    where s.path_id = p.id and s.step_kind not in ('UJI', 'LISENSI', 'SERTIFIKASI');

    select count(*) into v_n from public.user_education_path_steps u where u.path_id = p.id;
    v_centang := v_centang + v_n;

    delete from public.career_education_path_steps where path_id = p.id;

    insert into public.career_education_path_steps
      (path_id, step_order, title_id, note_id, step_rank, step_kind)
    select p.id, row_number() over (order by g.bagian, g.urut),
           g.title_id, g.note_id, g.step_rank, g.step_kind
    from (
      select 1 as bagian, s.step_order as urut, s.title_id, s.note_id, s.step_rank, s.step_kind
        from _sisa s where s.step_order < v_pos
      union all
      select 2, b.urut, b.title_id, b.note_id, null::smallint, b.step_kind from _blok b
      union all
      select 3, s.step_order, s.title_id, s.note_id, s.step_rank, s.step_kind
        from _sisa s where s.step_order >= v_pos
    ) g;

    v_ubah := v_ubah + 1;
  end loop;

  raise notice '0041: % jalur pendidikan disusun ulang, % centang pengguna ikut terhapus', v_ubah, v_centang;
end $$;

-- ---------------------------------------------------------------------------
-- Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_n int;
begin
  -- Pengganjal generik tidak boleh kembali diam-diam.
  select count(*) into v_n from public.career_licenses where license_code = 'K3_UMUM';
  if v_n > 10 then
    raise exception '0041: Sertifikat Ahli K3 Umum terpasang di % profesi; seharusnya hanya peran K3 dan pengawas produksi', v_n;
  end if;
  if exists (select 1 from public.licenses where code = 'MSIB') then
    raise exception '0041: Sertifikat Magang Bersertifikat masih ada di katalog';
  end if;

  -- Kasus dari laporan pengujian.
  if exists (select 1 from public.career_licenses cl join public.careers c on c.id = cl.career_id
             where c.career_name like 'Pembuat Pola Pakaian%' and cl.license_code <> 'BNSP') then
    raise exception '0041: Pembuat Pola Pakaian masih punya lisensi selain sertifikat kompetensi';
  end if;

  -- Langkah lisensi di jalur pendidikan harus berasal dari pemetaan profesinya.
  select count(*) into v_n
  from public.career_education_path_steps s
  join public.career_education_paths p on p.id = s.path_id
  where s.step_kind in ('UJI', 'LISENSI', 'SERTIFIKASI')
    and not exists (
      select 1 from public.career_licenses cl join public.licenses l on l.code = cl.license_code
      where cl.career_id = p.career_id and coalesce(l.step_title_id, l.name_id) = s.title_id);
  if v_n > 0 then
    raise exception '0041: % langkah jalur pendidikan menunjuk lisensi yang bukan milik profesinya', v_n;
  end if;

  -- Nomor langkah tetap rapat dan tiap jalur tetap berakhir di tujuannya.
  select count(*) into v_n from (
    select path_id from public.career_education_path_steps
    group by path_id having max(step_order) <> count(*) or min(step_order) <> 1) x;
  if v_n > 0 then
    raise exception '0041: % jalur pendidikan punya nomor langkah yang bolong', v_n;
  end if;
  select count(*) into v_n from public.career_education_paths p
  where (select s.step_kind from public.career_education_path_steps s
         where s.path_id = p.id order by s.step_order desc limit 1) is distinct from 'TUJUAN';
  if v_n > 0 then
    raise exception '0041: % jalur pendidikan tidak berakhir di langkah tujuan', v_n;
  end if;

  perform public.career_competency((select id from public.careers where is_active order by id limit 1));

  raise notice '0041: % lisensi di katalog, % tautan, % profesi aktif tanpa lisensi',
    (select count(*) from public.licenses),
    (select count(*) from public.career_licenses),
    (select count(*) from public.careers c where c.is_active
       and not exists (select 1 from public.career_licenses cl where cl.career_id = c.id));
end $$;

commit;
