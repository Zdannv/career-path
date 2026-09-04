-- ============================================================================
-- 0016_quest_engine.sql
--
-- Engine template quest: bank template + langkah bersolot, bukan kalimat jadi.
--
-- Sebelum ini setiap milestone roadmap menghasilkan tiga baris yang selalu
-- sama bentuknya — "Pelajari dasar X", "Latih langsung: X", "Simpan bukti
-- kemampuan X" — dengan X diganti nama aktivitas. Nico menyebutnya kaku dan
-- repetitif, dan ia benar: 18.596 baris itu sebenarnya hanya tiga kalimat.
--
-- Di sini kalimatnya pindah ke tabel template. Satu quest = satu template +
-- satu konteks ({profesi, hard_skill, aktivitas, ...}), dan langkah-langkahnya
-- dirender saat dibaca. Yang disimpan tinggal 111 baris langkah; yang tampil
-- ke pengguna tetap puluhan ribu.
--
-- Delapan langkah HS_PEMULA adalah tulisan Nico, dipakai apa adanya.
--
-- Kolom rotate_group yang membuatnya tidak seragam: langkah bernilai NULL
-- selalu muncul, langkah bernilai 1/2/3 hanya muncul pada quest yang
-- rotate_seed-nya cocok. Dua milestone berurutan di satu roadmap karena itu
-- tidak pernah terbaca persis sama.
--
-- Jalankan setelah 0015. Aman diulang.
-- ============================================================================

begin;

create table if not exists public.quest_tiers (
  code           text primary key,
  level          smallint not null unique,
  emoji          text not null,
  label_en       text not null,
  description_id text not null
);

create table if not exists public.quest_templates (
  code           text primary key,
  kind           text not null,
  tier_code      text not null references public.quest_tiers(code),
  title_template text not null,
  summary_template text not null,
  source         text not null default 'navika',
  created_at     timestamptz not null default now(),
  constraint chk_quest_kind check (kind in
    ('HARD_SKILL','AKTIVITAS','EDUKASI','PENGALAMAN','KARIER','LANJUT'))
);
comment on table public.quest_templates is
  'Bank template quest milik Navika. Teks di sini yang membedakan produk ini dari daftar tugas hasil salin situs lain.';

create table if not exists public.quest_template_steps (
  template_code text not null references public.quest_templates(code) on delete cascade,
  step_order    smallint not null,
  step_type     text not null,
  text_template text not null,
  rotate_group  smallint,
  xp            smallint not null,
  est_minutes   smallint not null,
  primary key (template_code, step_order),
  constraint chk_step_type check (step_type in ('RISET','BELAJAR','PRAKTIK','BUKTI','ADMIN')),
  constraint chk_rotate check (rotate_group is null or rotate_group between 1 and 3)
);
comment on column public.quest_template_steps.rotate_group is
  'NULL = langkah inti, selalu muncul. 1-3 = langkah rotasi, hanya muncul kalau cocok dengan rotate_seed quest.';

-- ---------------------------------------------------------------------------
-- Pengisi slot
--
-- [profesi_lanjut] harus diganti sebelum [profesi], kalau tidak "[profesi]_lanjut"
-- ikut tergantikan dan menyisakan kata "_lanjut" menggantung.
-- ---------------------------------------------------------------------------
create or replace function public.quest_render(p_text text, p_ctx jsonb)
returns text language sql immutable
set search_path = public
as $$
  select replace(replace(replace(replace(replace(replace(p_text,
    '[hard_skill]',     coalesce(p_ctx->>'hard_skill','')),
    '[profesi_lanjut]', coalesce(p_ctx->>'profesi_lanjut','')),
    '[profesi]',        coalesce(p_ctx->>'profesi','')),
    '[aktivitas]',      coalesce(p_ctx->>'aktivitas','')),
    '[jenjang]',        coalesce(p_ctx->>'jenjang','')),
    '[lisensi]',        coalesce(p_ctx->>'lisensi',''));
$$;

insert into public.quest_tiers (code, level, emoji, label_en, description_id) values
  ('PEMULA', 1, '🟢', 'Beginner', 'Mengenal konsep dan dasarnya.'),
  ('MENENGAH', 2, '🔵', 'Intermediate', 'Menerapkan pada kasus nyata.'),
  ('MAHIR', 3, '🟣', 'Advanced', 'Menghasilkan karya yang layak ditunjukkan.')
on conflict (code) do update set
  level = excluded.level, emoji = excluded.emoji,
  label_en = excluded.label_en, description_id = excluded.description_id;

insert into public.quest_templates (code, kind, tier_code, title_template, summary_template) values
  ('HS_PEMULA', 'HARD_SKILL', 'PEMULA', 'Mengenal [hard_skill]', 'Mengenal konsep dan dasar [hard_skill] untuk profesi [profesi].'),
  ('HS_MENENGAH', 'HARD_SKILL', 'MENENGAH', 'Menerapkan [hard_skill]', 'Memakai [hard_skill] pada kasus nyata yang biasa dihadapi [profesi].'),
  ('HS_MAHIR', 'HARD_SKILL', 'MAHIR', 'Menguasai [hard_skill]', 'Menghasilkan karya [hard_skill] yang layak ditunjukkan ke perekrut.'),
  ('AK_PEMULA', 'AKTIVITAS', 'PEMULA', 'Kenali cara [aktivitas]', 'Memahami apa yang sebenarnya dikerjakan saat [aktivitas].'),
  ('AK_MENENGAH', 'AKTIVITAS', 'MENENGAH', 'Latih [aktivitas]', 'Mencoba [aktivitas] berulang kali sampai terbiasa.'),
  ('AK_MAHIR', 'AKTIVITAS', 'MAHIR', 'Buktikan [aktivitas]', 'Melakukan [aktivitas] di situasi nyata dan menyimpan buktinya.'),
  ('ED_KENALI', 'EDUKASI', 'PEMULA', 'Kenali profesi [profesi]', 'Memastikan profesi ini memang yang kamu mau sebelum memilih jurusan.'),
  ('ED_JURUSAN', 'EDUKASI', 'PEMULA', 'Pilih jurusan sekolah', 'Memilih jurusan SMA/SMK yang mengarah ke [profesi].'),
  ('ED_PRODI', 'EDUKASI', 'MENENGAH', 'Pilih program studi', 'Memilih kampus dan program studi yang mengarah ke [profesi].'),
  ('ED_KULIAH', 'EDUKASI', 'MENENGAH', 'Selesaikan [jenjang]', 'Menyelesaikan pendidikan sambil mengumpulkan bekal untuk [profesi].'),
  ('PG_MAGANG', 'PENGALAMAN', 'MENENGAH', 'Dapatkan pengalaman pertama', 'Mendapat satu pengalaman kerja nyata sebagai bekal melamar.'),
  ('KR_REKRUT', 'KARIER', 'MAHIR', 'Lolos rekrutmen [profesi]', 'Menyiapkan diri sampai diterima kerja sebagai [profesi].'),
  ('KR_LISENSI', 'KARIER', 'MENENGAH', 'Urus [lisensi]', 'Melengkapi izin resmi yang wajib dimiliki sebelum bekerja sebagai [profesi].'),
  ('LJ_JALUR', 'LANJUT', 'MAHIR', 'Jajaki jalur ke [profesi_lanjut]', 'Menyiapkan langkah pindah atau naik ke [profesi_lanjut].')
on conflict (code) do update set
  kind = excluded.kind, tier_code = excluded.tier_code,
  title_template = excluded.title_template, summary_template = excluded.summary_template;

insert into public.quest_template_steps (template_code, step_order, step_type, text_template, rotate_group, xp, est_minutes) values
  ('HS_PEMULA', 1, 'BELAJAR', 'Pelajari pengenalan dasar hard skill [hard_skill] selama 10-15 menit.', null, 10, 15),
  ('HS_PEMULA', 2, 'RISET', 'Cari tahu mengapa hard skill [hard_skill] penting dalam profesi [profesi].', null, 10, 15),
  ('HS_PEMULA', 3, 'BELAJAR', 'Kenali istilah-istilah dasar yang sering digunakan dalam [hard_skill].', null, 10, 20),
  ('HS_PEMULA', 4, 'BELAJAR', 'Tonton video dari youtuber seputar apa itu [hard_skill].', null, 10, 20),
  ('HS_PEMULA', 5, 'RISET', 'Pelajari fungsi dan manfaat [hard_skill] dalam dunia kerja [profesi].', null, 10, 15),
  ('HS_PEMULA', 6, 'RISET', 'Cari tahu tools yang biasa digunakan untuk mendukung penggunaan [hard_skill].', null, 10, 15),
  ('HS_PEMULA', 7, 'BELAJAR', 'Pelajari contoh sederhana penerapan [hard_skill].', null, 10, 20),
  ('HS_PEMULA', 8, 'BELAJAR', 'Minta AI menjelaskan [hard_skill] dengan bahasa yang mudah dipahami.', null, 10, 10),
  ('HS_PEMULA', 9, 'RISET', 'Cari satu akun atau kanal yang rutin membahas [hard_skill], lalu ikuti.', 1, 5, 10),
  ('HS_PEMULA', 10, 'BUKTI', 'Tulis tiga kalimat: apa itu [hard_skill] menurut pemahamanmu sekarang.', 2, 10, 10),
  ('HS_PEMULA', 11, 'RISET', 'Cari satu lowongan [profesi] yang menyebut [hard_skill], lalu catat levelnya.', 3, 10, 15),
  ('HS_MENENGAH', 1, 'PRAKTIK', 'Kerjakan satu latihan terpandu [hard_skill] dari awal sampai selesai.', null, 20, 60),
  ('HS_MENENGAH', 2, 'PRAKTIK', 'Tiru satu contoh nyata penggunaan [hard_skill] di pekerjaan [profesi], lalu ubah sebagian isinya.', null, 20, 60),
  ('HS_MENENGAH', 3, 'PRAKTIK', 'Buat satu karya kecil memakai [hard_skill] tanpa mengikuti tutorial.', null, 25, 90),
  ('HS_MENENGAH', 4, 'BELAJAR', 'Catat tiga kesalahan yang kamu buat saat memakai [hard_skill] dan cara memperbaikinya.', null, 15, 20),
  ('HS_MENENGAH', 5, 'RISET', 'Bandingkan dua cara berbeda menyelesaikan hal yang sama dengan [hard_skill].', null, 15, 30),
  ('HS_MENENGAH', 6, 'BUKTI', 'Simpan hasil kerjamu sebagai bukti kemampuan [hard_skill].', null, 15, 15),
  ('HS_MENENGAH', 7, 'PRAKTIK', 'Minta satu orang menilai hasil [hard_skill]-mu, lalu tulis masukannya.', 1, 15, 30),
  ('HS_MENENGAH', 8, 'PRAKTIK', 'Ukur berapa lama kamu menyelesaikan satu tugas [hard_skill]; ulangi sampai lebih cepat.', 2, 15, 45),
  ('HS_MENENGAH', 9, 'BELAJAR', 'Cari satu fitur [hard_skill] yang belum pernah kamu pakai, lalu coba.', 3, 15, 30),
  ('HS_MAHIR', 1, 'PRAKTIK', 'Kerjakan satu kasus [hard_skill] yang datang dari kebutuhan nyata, bukan latihan.', null, 35, 120),
  ('HS_MAHIR', 2, 'PRAKTIK', 'Selesaikan satu masalah [hard_skill] yang belum ada tutorialnya.', null, 35, 120),
  ('HS_MAHIR', 3, 'PRAKTIK', 'Gabungkan [hard_skill] dengan satu kemampuan lain yang dipakai [profesi].', null, 30, 90),
  ('HS_MAHIR', 4, 'BUKTI', 'Rapikan hasil [hard_skill]-mu sampai layak ditunjukkan ke perekrut.', null, 30, 60),
  ('HS_MAHIR', 5, 'PRAKTIK', 'Jelaskan keputusanmu memakai [hard_skill] kepada orang yang bukan [profesi].', null, 20, 30),
  ('HS_MAHIR', 6, 'BUKTI', 'Masukkan karya [hard_skill] itu ke portofolio atau CV-mu.', null, 20, 30),
  ('HS_MAHIR', 7, 'PRAKTIK', 'Ajari satu orang dasar [hard_skill]; catat pertanyaan yang tidak bisa kamu jawab.', 1, 25, 60),
  ('HS_MAHIR', 8, 'BELAJAR', 'Tinjau ulang karya [hard_skill] lamamu dan tulis apa yang sekarang kamu lakukan berbeda.', 2, 20, 30),
  ('HS_MAHIR', 9, 'PRAKTIK', 'Ikut satu tantangan, lomba, atau proyek terbuka yang memakai [hard_skill].', 3, 30, 120),
  ('AK_PEMULA', 1, 'RISET', 'Cari tahu apa yang sebenarnya dikerjakan saat [aktivitas].', null, 10, 20),
  ('AK_PEMULA', 2, 'BELAJAR', 'Tulis langkah-langkah [aktivitas] dengan bahasamu sendiri.', null, 15, 25),
  ('AK_PEMULA', 3, 'RISET', 'Cari tahu kesalahan yang paling sering terjadi saat [aktivitas].', null, 10, 15),
  ('AK_PEMULA', 4, 'RISET', 'Tonton atau baca satu contoh nyata seorang [profesi] sedang [aktivitas].', 1, 10, 20),
  ('AK_PEMULA', 5, 'BELAJAR', 'Kenali alat atau dokumen yang biasa dipakai untuk [aktivitas].', 1, 10, 20),
  ('AK_PEMULA', 6, 'BELAJAR', 'Minta AI membuat satu skenario latihan [aktivitas] untuk pemula.', 1, 10, 15),
  ('AK_PEMULA', 7, 'RISET', 'Tanya satu orang yang sudah bekerja: seberapa sering ia [aktivitas]?', 2, 10, 20),
  ('AK_PEMULA', 8, 'RISET', 'Cari satu video atau artikel yang mengupas [aktivitas] langkah demi langkah.', 2, 10, 25),
  ('AK_PEMULA', 9, 'BUKTI', 'Tulis satu paragraf kenapa [aktivitas] penting bagi seorang [profesi].', 2, 10, 15),
  ('AK_PEMULA', 10, 'RISET', 'Bandingkan cara dua orang berbeda [aktivitas].', 3, 10, 25),
  ('AK_PEMULA', 11, 'BELAJAR', 'Buat daftar istilah yang sering muncul saat orang [aktivitas].', 3, 10, 20),
  ('AK_PEMULA', 12, 'BUKTI', 'Gambar alur sederhana dari awal sampai selesai [aktivitas].', 3, 15, 30),
  ('AK_MENENGAH', 1, 'PRAKTIK', 'Coba [aktivitas] satu kali dalam situasi latihan.', null, 20, 60),
  ('AK_MENENGAH', 2, 'PRAKTIK', 'Perbaiki satu hal dari cara kamu [aktivitas], lalu coba lagi.', null, 20, 45),
  ('AK_MENENGAH', 3, 'PRAKTIK', 'Ulangi [aktivitas] dengan kasus yang berbeda.', 1, 20, 60),
  ('AK_MENENGAH', 4, 'BELAJAR', 'Catat berapa lama dan sesulit apa [aktivitas] bagimu sekarang.', 1, 10, 15),
  ('AK_MENENGAH', 5, 'PRAKTIK', 'Minta masukan orang yang lebih berpengalaman soal cara kamu [aktivitas].', 1, 15, 30),
  ('AK_MENENGAH', 6, 'BELAJAR', 'Cari satu cara yang lebih cepat untuk [aktivitas].', 2, 15, 30),
  ('AK_MENENGAH', 7, 'PRAKTIK', 'Kerjakan [aktivitas] dengan batas waktu yang kamu tetapkan sendiri.', 2, 20, 45),
  ('AK_MENENGAH', 8, 'BUKTI', 'Susun daftar periksa pribadi supaya kamu tidak lupa langkah saat [aktivitas].', 2, 15, 30),
  ('AK_MENENGAH', 9, 'PRAKTIK', 'Lakukan [aktivitas] di depan orang lain tanpa membaca catatan.', 3, 20, 30),
  ('AK_MENENGAH', 10, 'PRAKTIK', 'Kerjakan [aktivitas] bersama satu orang lain, lalu bandingkan hasilnya.', 3, 20, 60),
  ('AK_MENENGAH', 11, 'PRAKTIK', 'Coba [aktivitas] pada kondisi yang tidak ideal: waktu sempit atau data kurang.', 3, 20, 45),
  ('AK_MAHIR', 1, 'PRAKTIK', 'Lakukan [aktivitas] pada situasi nyata di magang, organisasi, atau pekerjaan.', null, 30, 120),
  ('AK_MAHIR', 2, 'BUKTI', 'Simpan hasilnya (foto, dokumen, atau tangkapan layar) sebagai bukti kemampuan.', null, 20, 20),
  ('AK_MAHIR', 3, 'BUKTI', 'Tulis satu paragraf: masalah apa yang kamu selesaikan lewat [aktivitas].', 1, 15, 20),
  ('AK_MAHIR', 4, 'BUKTI', 'Masukkan bukti itu ke portofolio atau CV-mu.', 1, 15, 20),
  ('AK_MAHIR', 5, 'BUKTI', 'Minta atasan atau pembimbing menuliskan satu kalimat penilaian atas cara kamu [aktivitas].', 1, 20, 30),
  ('AK_MAHIR', 6, 'PRAKTIK', 'Kerjakan [aktivitas] pada kasus yang lebih besar atau lebih rumit.', 2, 25, 120),
  ('AK_MAHIR', 7, 'PRAKTIK', 'Tunjukkan cara kamu [aktivitas] kepada rekan yang lebih baru.', 2, 20, 45),
  ('AK_MAHIR', 8, 'BUKTI', 'Susun panduan singkat cara [aktivitas] untuk dipakai tim.', 2, 25, 60),
  ('AK_MAHIR', 9, 'BELAJAR', 'Bandingkan cara kamu [aktivitas] dengan standar yang berlaku di industri.', 3, 20, 30),
  ('AK_MAHIR', 10, 'BUKTI', 'Ukur hasil [aktivitas]-mu dengan angka, lalu tulis targetnya.', 3, 20, 30),
  ('AK_MAHIR', 11, 'BELAJAR', 'Cari satu bagian dari [aktivitas] yang bisa kamu sederhanakan atau otomatiskan.', 3, 20, 45),
  ('ED_KENALI', 1, 'RISET', 'Cari tahu keseharian seorang [profesi].', null, 10, 20),
  ('ED_KENALI', 2, 'RISET', 'Ngobrol dengan satu orang yang bekerja sebagai [profesi].', null, 15, 45),
  ('ED_KENALI', 3, 'RISET', 'Cari tahu berapa kisaran gaji [profesi] di kota terdekat.', null, 10, 15),
  ('ED_KENALI', 4, 'RISET', 'Cari tahu bagian paling berat dari pekerjaan [profesi].', null, 10, 15),
  ('ED_KENALI', 5, 'BUKTI', 'Tulis alasanmu tertarik pada profesi ini.', null, 10, 20),
  ('ED_KENALI', 6, 'RISET', 'Tonton satu video ''a day in the life'' seorang [profesi].', 1, 5, 20),
  ('ED_KENALI', 7, 'RISET', 'Cari tahu profesi lain yang mirip [profesi], lalu bandingkan.', 2, 10, 25),
  ('ED_KENALI', 8, 'RISET', 'Cari tahu apakah [profesi] butuh sertifikat atau izin khusus.', 3, 10, 15),
  ('ED_JURUSAN', 1, 'RISET', 'Bandingkan jurusan SMA/SMK yang mengarah ke profesi [profesi].', null, 15, 30),
  ('ED_JURUSAN', 2, 'RISET', 'Cari tahu mata pelajaran apa yang paling dipakai di [profesi].', null, 10, 20),
  ('ED_JURUSAN', 3, 'RISET', 'Tanya guru BK soal jurusan yang cocok untuk [profesi].', null, 10, 30),
  ('ED_JURUSAN', 4, 'ADMIN', 'Tetapkan pilihan jurusanmu.', null, 15, 15),
  ('ED_JURUSAN', 5, 'BELAJAR', 'Perkuat satu mata pelajaran yang paling menentukan di jurusan itu.', 1, 15, 60),
  ('ED_JURUSAN', 6, 'RISET', 'Cari tahu sekolah mana di sekitarmu yang membuka jurusan itu.', 2, 10, 25),
  ('ED_JURUSAN', 7, 'BUKTI', 'Tulis rencana cadangan kalau jurusan pilihanmu tidak tersedia.', 3, 10, 20),
  ('ED_PRODI', 1, 'RISET', 'Susun daftar program studi yang mengarah ke profesi [profesi].', null, 15, 40),
  ('ED_PRODI', 2, 'RISET', 'Bandingkan kampus, biaya, dan jalur masuknya.', null, 20, 60),
  ('ED_PRODI', 3, 'RISET', 'Cari tahu beasiswa yang bisa kamu ambil untuk program studi itu.', null, 15, 40),
  ('ED_PRODI', 4, 'ADMIN', 'Daftar ke program studi pilihanmu.', null, 25, 60),
  ('ED_PRODI', 5, 'BELAJAR', 'Latih soal seleksi masuk jalur yang kamu incar.', 1, 20, 90),
  ('ED_PRODI', 6, 'RISET', 'Cari tahu akreditasi program studi yang kamu tuju.', 2, 10, 20),
  ('ED_PRODI', 7, 'RISET', 'Tanya satu mahasiswa aktif di program studi itu soal kesehariannya.', 3, 15, 30),
  ('ED_KULIAH', 1, 'BELAJAR', 'Jaga capaian akademik tiap semester.', null, 20, 60),
  ('ED_KULIAH', 2, 'PRAKTIK', 'Ikut satu organisasi atau kepanitiaan yang melatih kemampuan [profesi].', null, 20, 120),
  ('ED_KULIAH', 3, 'PRAKTIK', 'Ambil tugas akhir yang berhubungan dengan profesi [profesi].', null, 30, 120),
  ('ED_KULIAH', 4, 'ADMIN', 'Selesaikan kelulusan dan urus ijazah.', null, 25, 60),
  ('ED_KULIAH', 5, 'RISET', 'Cari dosen pembimbing yang bidangnya dekat dengan [profesi].', 1, 15, 30),
  ('ED_KULIAH', 6, 'PRAKTIK', 'Ambil satu mata kuliah pilihan yang paling dekat dengan [profesi].', 2, 15, 30),
  ('ED_KULIAH', 7, 'BUKTI', 'Kumpulkan tugas kuliah terbaikmu jadi satu berkas portofolio.', 3, 20, 45),
  ('PG_MAGANG', 1, 'RISET', 'Data tempat magang atau proyek yang menerima pemula.', null, 15, 45),
  ('PG_MAGANG', 2, 'BUKTI', 'Siapkan CV singkat dan satu contoh karya untuk dilampirkan.', null, 20, 60),
  ('PG_MAGANG', 3, 'ADMIN', 'Kirim lamaran magang ke minimal lima tempat.', null, 20, 60),
  ('PG_MAGANG', 4, 'PRAKTIK', 'Jalani satu magang atau proyek nyata.', null, 40, 120),
  ('PG_MAGANG', 5, 'BUKTI', 'Rangkum hasilnya jadi satu portofolio.', null, 25, 60),
  ('PG_MAGANG', 6, 'PRAKTIK', 'Minta surat keterangan atau testimoni dari pembimbing magangmu.', 1, 15, 20),
  ('PG_MAGANG', 7, 'RISET', 'Catat tiga hal yang ternyata berbeda dari bayanganmu soal [profesi].', 2, 10, 20),
  ('PG_MAGANG', 8, 'PRAKTIK', 'Jaga hubungan dengan satu orang dari tempat magang itu.', 3, 10, 20),
  ('KR_REKRUT', 1, 'BUKTI', 'Susun CV yang menonjolkan pengalamanmu sebagai calon [profesi].', null, 25, 90),
  ('KR_REKRUT', 2, 'BUKTI', 'Rapikan profil LinkedIn atau portofolio daringmu.', null, 20, 60),
  ('KR_REKRUT', 3, 'BELAJAR', 'Latih wawancara kerja untuk posisi [profesi].', null, 25, 90),
  ('KR_REKRUT', 4, 'RISET', 'Cari tahu tahapan seleksi yang biasa dipakai untuk posisi ini.', null, 15, 30),
  ('KR_REKRUT', 5, 'ADMIN', 'Lamar ke minimal lima lowongan.', null, 25, 60),
  ('KR_REKRUT', 6, 'BELAJAR', 'Siapkan jawaban untuk pertanyaan soal gaji yang kamu harapkan.', 1, 15, 30),
  ('KR_REKRUT', 7, 'PRAKTIK', 'Minta satu orang mewawancaraimu sebagai latihan.', 2, 20, 45),
  ('KR_REKRUT', 8, 'BELAJAR', 'Pelajari tes teknis yang biasa muncul untuk posisi [profesi].', 3, 20, 60),
  ('KR_LISENSI', 1, 'RISET', 'Cari tahu syarat dan alur pengurusan [lisensi].', null, 15, 30),
  ('KR_LISENSI', 2, 'RISET', 'Cari tahu berapa biaya dan berapa lama proses [lisensi].', null, 10, 20),
  ('KR_LISENSI', 3, 'ADMIN', 'Kumpulkan berkas yang diminta untuk [lisensi].', null, 20, 90),
  ('KR_LISENSI', 4, 'ADMIN', 'Lengkapi berkas dan ajukan [lisensi].', null, 25, 60),
  ('KR_LISENSI', 5, 'BUKTI', 'Simpan salinan digital [lisensi] beserta masa berlakunya.', null, 15, 15),
  ('KR_LISENSI', 6, 'BELAJAR', 'Pelajari materi ujian atau uji kompetensi untuk [lisensi].', 1, 25, 120),
  ('KR_LISENSI', 7, 'RISET', 'Tanya satu orang [profesi] yang sudah punya [lisensi] soal kendalanya.', 2, 10, 30),
  ('KR_LISENSI', 8, 'RISET', 'Catat kapan [lisensi] harus diperpanjang dan apa syaratnya.', 3, 10, 20),
  ('LJ_JALUR', 1, 'RISET', 'Cari tahu apa yang membedakan [profesi_lanjut] dari peranmu sekarang.', null, 15, 30),
  ('LJ_JALUR', 2, 'RISET', 'Daftar kemampuan yang masih kurang untuk pindah ke [profesi_lanjut].', null, 15, 30),
  ('LJ_JALUR', 3, 'BELAJAR', 'Ambil satu kemampuan dari daftar itu dan mulai pelajari.', null, 25, 120),
  ('LJ_JALUR', 4, 'PRAKTIK', 'Cari kesempatan mengerjakan tugas [profesi_lanjut] di tempat kerjamu sekarang.', null, 25, 120),
  ('LJ_JALUR', 5, 'RISET', 'Ngobrol dengan satu orang yang sudah menjadi [profesi_lanjut].', 1, 15, 45),
  ('LJ_JALUR', 6, 'RISET', 'Bandingkan gaji dan jam kerja [profesi_lanjut] dengan peranmu sekarang.', 2, 10, 20),
  ('LJ_JALUR', 7, 'BUKTI', 'Perbarui CV-mu supaya mengarah ke [profesi_lanjut].', 3, 15, 45)
on conflict (template_code, step_order) do update set
  step_type = excluded.step_type, text_template = excluded.text_template,
  rotate_group = excluded.rotate_group, xp = excluded.xp, est_minutes = excluded.est_minutes;

-- Tiap template wajib punya langkah inti; template tanpa langkah inti akan
-- menghasilkan quest kosong bagi dua dari tiga rotate_seed.
do $$
declare sisa text;
begin
  select string_agg(t.code, ', ') into sisa
  from public.quest_templates t
  where not exists (select 1 from public.quest_template_steps s
                    where s.template_code = t.code and s.rotate_group is null);
  if sisa is not null then
    raise exception 'template tanpa langkah inti: %', sisa;
  end if;
end $$;

alter table public.quest_tiers          enable row level security;
alter table public.quest_templates      enable row level security;
alter table public.quest_template_steps enable row level security;
do $$
declare t text;
begin
  foreach t in array array['quest_tiers','quest_templates','quest_template_steps'] loop
    execute format('drop policy if exists %I_read_all on public.%I', t, t);
    execute format('create policy %I_read_all on public.%I for select to anon, authenticated using (true)', t, t);
  end loop;
end $$;

commit;
