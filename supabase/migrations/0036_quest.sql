-- ===========================================================================
-- 0036_quest.sql
--
-- Layar Quest: daftar "Apa yang perlu Kamu kerjakan minggu ini", isi tiap
-- kelompok quest, ambil -> selesaikan, XP, dan badge pertama.
--
-- ---------------------------------------------------------------------------
-- Bentuknya
-- ---------------------------------------------------------------------------
-- Quest dikelompokkan per "grup". Satu grup = satu hal yang dipelajari:
--
--   jenis grup   tahap Journey   grup per profesi              quest per grup
--   EKSPLORASI   1 Eksplorasi    1 (profesinya sendiri)         2
--   SOFT_SKILL   2 Pondasi       4 soft skill dominan           3 (bebas urutan)
--   HARD_SKILL   3 Keahlian      hard skill profesi (5-8)       3 (berurutan)
--   TOOL         3 Keahlian      tools profesi (2-10)           3 (berurutan)
--   PENGALAMAN   4 Pengalaman    1                              4 (langsung selesai)
--   BERKARIER    5 Berkarier     1                              2 (langsung selesai)
--
-- Grup soft skill, hard skill, dan tools diambil dari sumber yang sama dengan
-- layar Journey (0035), jadi apa yang dijanjikan Journey sama dengan apa yang
-- bisa dikerjakan di Quest.
--
-- Tidak ada satu pun kalimat quest yang disimpan per profesi. Yang disimpan
-- template per level (quest_items) dan, untuk soft skill, tiga pertanyaan per
-- atribut DNA (soft_skill_focus). Nama profesi / skill / tools disisipkan
-- saat dibaca.
--
-- ---------------------------------------------------------------------------
-- Aturan buka-kunci (dari catatan desain di Figma)
-- ---------------------------------------------------------------------------
--   * Soft skill terbuka setelah kedua quest Eksplorasi selesai.
--   * Hard skill dan tools terbuka setelah minimal 1 quest soft skill selesai.
--   * Hard skill dan tools dikerjakan berurutan per level; soft skill bebas.
--   * Asah Pengalaman terbuka setelah minimal 1 quest tools selesai. Praktik
--     magang di dalamnya punya syarat tambahan: posisi studi pengguna harus
--     sudah sampai titik tertentu (S1 semester 5, D3 semester 4, SMK kelas
--     11, ...) -- lihat quest_syarat_magang.
--   * Siap Berkarier terbuka setelah minimal 1 quest Pengalaman selesai.
--     "Kirim Lamaran Kerja" baru bisa diselesaikan kalau jenjang pengguna
--     sudah (atau hampir) memenuhi jenjang minimum profesinya.
--
-- Dua aturan terakhir untuk Berkarier tidak ada di catatan desain; itu
-- keputusan di sini supaya anak SMA yang menuju profesi S1 tidak disuruh
-- mengirim lamaran kerja.
--
-- Aturan buka-kunci per jenis disimpan sebagai data (buka_setelah,
-- buka_minimal) supaya bisa disetel tanpa menulis ulang fungsi.
--
-- ---------------------------------------------------------------------------
-- XP dan kemajuan tahap
-- ---------------------------------------------------------------------------
-- XP quest ditulis ke xp_ledger (source_kind QUEST) oleh selesaikan_quest(),
-- dengan index unik supaya satu quest tidak bisa dibayar dua kali. Nilai XP
-- diambil dari katalog di database, tidak pernah dari client.
--
-- Setiap quest yang selesai menghitung ulang persen tahap Journey-nya dan
-- status item Journey terkait (soft skill, hard skill, tools, kegiatan).
-- Tahap ditandai selesai kalau seluruh quest di dalamnya selesai -- itu yang
-- membuat tahap berikutnya "AKTIF" di layar Roadmap.
--
-- Jalankan setelah 0035. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Jenis grup
-- ---------------------------------------------------------------------------
create table if not exists public.quest_group_kinds (
  code          text primary key,
  kind_order    smallint not null unique,
  stage_code    text not null references public.journey_stages(code),
  -- Label ungu kecil di atas judul kartu: "Soft Skill", "Tools", ...
  label_id      text not null,
  -- Slug di URL /quest/<slug>/<kode>.
  slug          text not null unique,
  icon          text not null,
  tone          text not null,
  -- AMBIL: Ambil Quest -> Selesaikan. LANGSUNG: satu tombol Selesaikan.
  mode          text not null,
  -- true: quest level n baru bisa diambil setelah level n-1 selesai.
  berurutan     boolean not null default false,
  -- Jenis grup yang harus dikerjakan dulu, dan berapa quest-nya.
  -- buka_minimal NULL berarti seluruh quest jenis itu harus selesai.
  buka_setelah  text references public.quest_group_kinds(code),
  buka_minimal  smallint,
  -- Kalimat penjelas kunci, dipakai kalau pengguna membuka grup yang belum
  -- terbuka lewat URL.
  alasan_kunci  text,
  -- Banner "Tips" di atas daftar quest.
  tips_gambar   text not null,
  tips_label    text not null,
  tips_judul    text not null,
  tips_isi      text not null,
  -- true: tampilkan tiga sumber (AI Chat, Youtube, Browsing Artikel).
  tips_sumber   boolean not null default false,
  -- Kotak "Catatan" di bawah daftar. NULL = tidak ada.
  catatan_id    text,
  constraint chk_qgk_mode check (mode in ('AMBIL','LANGSUNG')),
  constraint chk_qgk_tone check (tone in ('hijau','lime','biru','ungu','pink','violet')),
  constraint chk_qgk_gambar check (tips_gambar in ('RESOURCE','WHATS_NEXT'))
);

comment on table public.quest_group_kinds is
  'Enam jenis grup quest. Aturan buka-kunci, bentuk tombol, dan banner tips disimpan sebagai data.';

insert into public.quest_group_kinds
  (code, kind_order, stage_code, label_id, slug, icon, tone, mode, berurutan,
   buka_setelah, buka_minimal, alasan_kunci,
   tips_gambar, tips_label, tips_judul, tips_isi, tips_sumber, catatan_id) values
  ('EKSPLORASI', 1, 'EKSPLORASI', 'Eksplorasi Karier', 'eksplorasi', 'Compass', 'violet', 'AMBIL', false,
   null, null, null,
   'RESOURCE', 'Tips Mengerjakan Quest', 'Cari informasi dari berbagai sumber!',
   'Kamu dapat mencari jawaban melalui', true,
   'Tidak ada jawaban benar atau salah karena quest ini melatihmu untuk memahami profesi pilihanmu sendiri.'),
  ('SOFT_SKILL', 2, 'PONDASI', 'Soft Skill', 'soft-skill', 'UsersRound', 'hijau', 'AMBIL', false,
   'EKSPLORASI', null, 'Selesaikan quest Eksplorasi Karier dulu untuk membuka quest soft skill.',
   'RESOURCE', 'Tips Mengerjakan Quest', 'Cari informasi dari berbagai sumber!',
   'Kamu dapat mencari jawaban melalui', true,
   'Tidak ada jawaban benar atau salah karena misi ini melatihmu untuk memahami profesi pilihanmu sendiri.'),
  ('HARD_SKILL', 3, 'KEAHLIAN', 'Hard Skill', 'hard-skill', 'NotebookPen', 'lime', 'AMBIL', true,
   'SOFT_SKILL', 1, 'Selesaikan minimal satu quest soft skill untuk membuka quest hard skill.',
   'RESOURCE', 'Tips Mengerjakan Quest', 'Cari informasi dari berbagai sumber!',
   'Kamu dapat mencari jawaban melalui', true,
   'Tidak ada jawaban benar atau salah karena quest ini melatihmu untuk memahami profesi pilihanmu sendiri.'),
  ('TOOL', 4, 'KEAHLIAN', 'Tools', 'tools', 'ChartNoAxesColumn', 'biru', 'AMBIL', true,
   'SOFT_SKILL', 1, 'Selesaikan minimal satu quest soft skill untuk membuka quest tools.',
   'RESOURCE', 'Tips Mengerjakan Quest', 'Cari informasi dari berbagai sumber!',
   'Kamu dapat mencari jawaban melalui', true,
   'Tidak ada jawaban benar atau salah karena quest ini melatihmu untuk memahami profesi pilihanmu sendiri.'),
  ('PENGALAMAN', 5, 'PENGALAMAN', 'Asah Pengalaman', 'pengalaman', 'ChevronsRight', 'ungu', 'LANGSUNG', false,
   'TOOL', 1, 'Selesaikan minimal satu quest tools untuk membuka quest Asah Pengalaman.',
   'RESOURCE', 'Tips Mengerjakan Quest', 'Mulai terjun ke dunia kerja',
   'Bekali dirimu dengan terjun langsung', false,
   null),
  ('BERKARIER', 6, 'BERKARIER', 'Siap Berkarier!', 'berkarier', 'Route', 'pink', 'LANGSUNG', false,
   'PENGALAMAN', 1, 'Selesaikan minimal satu quest Asah Pengalaman untuk membuka quest Siap Berkarier.',
   'WHATS_NEXT', 'Tips Navika', 'Peluang karier dimulai dari langkah kecil pertama',
   '', false,
   null)
on conflict (code) do update set
  kind_order = excluded.kind_order, stage_code = excluded.stage_code,
  label_id = excluded.label_id, slug = excluded.slug, icon = excluded.icon,
  tone = excluded.tone, mode = excluded.mode, berurutan = excluded.berurutan,
  buka_setelah = excluded.buka_setelah, buka_minimal = excluded.buka_minimal,
  alasan_kunci = excluded.alasan_kunci,
  tips_gambar = excluded.tips_gambar, tips_label = excluded.tips_label,
  tips_judul = excluded.tips_judul, tips_isi = excluded.tips_isi,
  tips_sumber = excluded.tips_sumber, catatan_id = excluded.catatan_id;

-- ---------------------------------------------------------------------------
-- 2. Quest per jenis grup
--
--    Slot yang tersedia di text_template:
--      [profesi]  nama profesi pilihan
--      [item]     nama hard skill (huruf pertama kecil) atau nama tools
--
--    Soft skill tidak punya text_template: kalimatnya berbeda per atribut
--    (lihat soft_skill_focus), karena "Mengapa [x] penting?" tidak terbaca
--    wajar untuk 28 soft skill yang bentuk katanya berbeda-beda.
-- ---------------------------------------------------------------------------
create table if not exists public.quest_items (
  group_kind     text not null references public.quest_group_kinds(code) on delete cascade,
  item_code      text not null,
  item_order     smallint not null,
  label_id       text not null,
  text_template  text,
  min_menit      smallint,
  max_menit      smallint,
  xp             smallint not null,
  -- Syarat tambahan di luar aturan buka-kunci grup.
  syarat         text,
  -- Item Journey tahap Pengalaman yang ikut selesai (KEGIATAN_1..3).
  journey_item   text,
  primary key (group_kind, item_code),
  unique (group_kind, item_order),
  constraint chk_qi_syarat check (syarat is null or syarat in ('MAGANG_WAKTU','JENJANG_KERJA')),
  constraint chk_qi_menit check (
    (min_menit is null and max_menit is null) or (min_menit > 0 and max_menit >= min_menit)),
  constraint chk_qi_xp check (xp > 0)
);

comment on table public.quest_items is
  'Template quest per jenis grup. Kalimat akhirnya dirakit quest_katalog() dengan nama profesi dan item.';

insert into public.quest_items
  (group_kind, item_code, item_order, label_id, text_template, min_menit, max_menit, xp, syarat, journey_item) values
  ('EKSPLORASI', 'YAKIN', 1, 'Yakinkan Dirimu',
   'Kenapa harus memilih profesi sebagai [profesi]?', 10, 15, 50, null, null),
  ('EKSPLORASI', 'DALAM', 2, 'Ketahui Lebih Dalam',
   'Mau tahu rasanya menjalani profesi ini? Cari video dengan kata kunci "A Day in My Life as [profesi]"',
   15, 20, 100, null, null),

  ('SOFT_SKILL', '1', 1, 'Beginner',       null, 10, 15,  50, null, null),
  ('SOFT_SKILL', '2', 2, 'Explorer',       null, 15, 20, 100, null, null),
  ('SOFT_SKILL', '3', 3, 'Problem Solver', null, 15, 20, 150, null, null),

  ('HARD_SKILL', '1', 1, 'Kenali Dasarnya',
   'Apa itu kemampuan [item] dan mengapa kemampuan ini penting dalam pekerjaan?', 10, 15, 50, null, null),
  ('HARD_SKILL', '2', 2, 'Penerapan di Dunia Kerja',
   'Cari contoh bagaimana seorang [profesi] [item] dalam pekerjaan sehari-hari.', 15, 20, 100, null, null),
  ('HARD_SKILL', '3', 3, 'Pahami Dampaknya',
   'Apa yang bisa terjadi jika [item] tidak dilakukan dengan baik, dan bagaimana cara mengatasinya?',
   15, 20, 150, null, null),

  ('TOOL', '1', 1, 'Kenali Dasarnya',
   'Cari penjelasan singkat tentang fungsi utama [item].', 10, 15, 50, null, null),
  ('TOOL', '2', 2, 'Penerapan di Dunia Kerja',
   'Bagaimana seorang [profesi] menggunakan [item] dalam rutinitas pekerjaannya?', 15, 20, 100, null, null),
  ('TOOL', '3', 3, 'Pahami Dampaknya',
   'Bandingkan pekerjaan [profesi] dengan dan tanpa menggunakan [item].', 15, 20, 150, null, null),

  ('PENGALAMAN', 'MAGANG', 1, 'Praktik Kerja Magang',
   'Terjun langsung ke dalam ekosistem industri nyata, dan beradaptasi dengan budaya kerja profesional.',
   null, null, 250, 'MAGANG_WAKTU', 'KEGIATAN_1'),
  ('PENGALAMAN', 'RESUME', 2, 'Resume & Portofolio',
   'Bungkus semua pencapaian, proyek, dan sertifikasi yang telah kamu raih ke dalam CV, resume, dan portofolio yang tersusun rapi.',
   null, null, 100, null, 'KEGIATAN_2'),
  ('PENGALAMAN', 'PARUH_WAKTU', 3, 'Proyek Part-Time & Pro Bono',
   'Asah kemampuan teknis tanpa harus menunggu lulus, lewat proyek paruh waktu (part-time) atau aksi nyata berbasis pro bono.',
   null, null, 150, null, null),
  ('PENGALAMAN', 'ORGANISASI', 4, 'Mengikuti Kegiatan Organisasi',
   'Terjun langsung dalam kegiatan organisasi, atau ikuti kegiatan sosial sebagai relawan.',
   null, null, 150, null, 'KEGIATAN_3'),

  ('BERKARIER', 'SITUS', 1, 'Eksplor Situs Kerja',
   'Jelajahi LinkedIn, Glints, atau Karir.com untuk menemukan peluang karier dan keterampilan yang dibutuhkan perusahaan.',
   null, null, 150, null, null),
  ('BERKARIER', 'LAMARAN', 2, 'Kirim Lamaran Kerja',
   'Pilih lowongan yang sesuai dengan minat dan kemampuanmu, lalu kirimkan CV serta lamaran untuk memulai langkah pertamamu menuju dunia kerja.',
   null, null, 250, 'JENJANG_KERJA', null)
on conflict (group_kind, item_code) do update set
  item_order = excluded.item_order, label_id = excluded.label_id,
  text_template = excluded.text_template, min_menit = excluded.min_menit,
  max_menit = excluded.max_menit, xp = excluded.xp, syarat = excluded.syarat,
  journey_item = excluded.journey_item;

-- ---------------------------------------------------------------------------
-- 3. Soft skill: sub-skill fokus, tiga pertanyaan, dan "Tujuan Quest"
--
--    Satu baris per atribut DNA lapis ACTIVITY dan SKILL -- 28 baris, sama
--    dengan jumlah atribut yang bisa muncul di tahap Pondasi.
--
--    Baris ACT_KOMUNIKASI diambil persis dari desain. Sisanya ditulis Navika
--    mengikuti pola yang sama: Beginner = mengapa penting, Explorer =
--    bagaimana profesi memakainya, Problem Solver = bagaimana ia membantu
--    menyelesaikan masalah. Nadanya perlu dicek tim sebelum rilis.
-- ---------------------------------------------------------------------------
create table if not exists public.soft_skill_focus (
  attr_code  text primary key references public.dna_attributes(code) on delete cascade,
  subskill   text not null,
  quest_1    text not null,
  quest_2    text not null,
  quest_3    text not null,
  tujuan     jsonb not null,
  constraint chk_ssf_tujuan check (jsonb_typeof(tujuan) = 'array' and jsonb_array_length(tujuan) between 3 and 5)
);

comment on table public.soft_skill_focus is
  'Sub-skill yang difokuskan, tiga pertanyaan quest (Beginner/Explorer/Problem Solver), dan isi lembar Tujuan Quest per soft skill.';

insert into public.soft_skill_focus (attr_code, subskill, quest_1, quest_2, quest_3, tujuan) values
  ('ACT_ANALISA', 'Menelusuri Akar Masalah',
   'Mengapa penting mencari tahu penyebab sebuah masalah sebelum mencoba memperbaikinya?',
   'Bagaimana berbagai profesi mengumpulkan informasi untuk menyelidiki sebuah masalah?',
   'Bagaimana analisa yang teliti bisa membantu mengambil keputusan yang lebih tepat?',
   '["Mengumpulkan Informasi","Membaca Data","Menarik Kesimpulan","Berpikir Sistematis"]'),
  ('ACT_DESAIN', 'Menuangkan Ide Menjadi Rancangan',
   'Mengapa sebuah ide perlu dituangkan menjadi rancangan sebelum dikerjakan?',
   'Bagaimana berbagai profesi mengubah ide menjadi desain, sketsa, atau purwarupa?',
   'Bagaimana rancangan yang baik bisa membantu menyelesaikan masalah pengguna?',
   '["Menggali Ide","Membuat Sketsa","Menerima Masukan","Menyempurnakan Karya"]'),
  ('ACT_KOMUNIKASI', 'Mendengarkan Orang Lain',
   'Mengapa mendengarkan penting saat berbicara dengan orang lain?',
   'Bagaimana berbagai profesi mendengarkan dan merespons orang lain?',
   'Bagaimana mendengarkan dengan baik bisa membantu menyelesaikan masalah?',
   '["Komunikasi Verbal","Mendengarkan Aktif","Public Speaking","Relationship Building"]'),
  ('ACT_MEMBANGUN', 'Membangun Secara Bertahap',
   'Mengapa membangun sesuatu perlu dilakukan secara bertahap?',
   'Bagaimana berbagai profesi merencanakan, membuat, lalu memperbaiki hasil kerjanya?',
   'Bagaimana kebiasaan menguji dan memperbaiki bisa mencegah kegagalan sebuah proyek?',
   '["Merencanakan Langkah Kerja","Mengerjakan Secara Bertahap","Menguji Hasil","Memperbaiki Kekurangan"]'),
  ('ACT_MEMBANTU', 'Memahami Kebutuhan Orang Lain',
   'Mengapa memahami kebutuhan orang lain penting sebelum membantu mereka?',
   'Bagaimana berbagai profesi melayani orang yang membutuhkan bantuan?',
   'Bagaimana pelayanan yang tulus bisa membantu menyelesaikan masalah seseorang?',
   '["Kepedulian","Sabar Melayani","Komunikasi yang Ramah","Menjaga Kepercayaan"]'),
  ('ACT_MEMIMPIN', 'Mengarahkan Tim',
   'Mengapa sebuah tim membutuhkan seseorang yang mengarahkan?',
   'Bagaimana berbagai profesi membagi tugas dan memantau pekerjaan timnya?',
   'Bagaimana kepemimpinan yang baik bisa membantu tim keluar dari masalah?',
   '["Membagi Tugas","Mengambil Keputusan","Memotivasi Tim","Bertanggung Jawab"]'),
  ('ACT_MENGAJAR', 'Menjelaskan dengan Sederhana',
   'Mengapa kemampuan menjelaskan hal rumit dengan sederhana itu penting?',
   'Bagaimana berbagai profesi membimbing orang lain agar bisa melakukan sesuatu?',
   'Bagaimana bimbingan yang baik bisa membantu seseorang mengatasi kesulitannya?',
   '["Menjelaskan dengan Jelas","Kesabaran","Memberi Contoh","Memberi Umpan Balik"]'),
  ('ACT_MENJUAL', 'Meyakinkan Orang Lain',
   'Mengapa kemampuan meyakinkan orang lain penting dalam banyak pekerjaan?',
   'Bagaimana berbagai profesi menawarkan ide atau produk kepada orang lain?',
   'Bagaimana cara meyakinkan yang jujur bisa membantu mencapai kesepakatan?',
   '["Memahami Kebutuhan Pelanggan","Menyampaikan Manfaat","Persuasi","Membangun Kepercayaan"]'),
  ('ACT_OPERASIONAL', 'Menjaga Pekerjaan Tetap Rapi',
   'Mengapa pekerjaan yang tercatat dan tersusun rapi itu penting?',
   'Bagaimana berbagai profesi mengelola jadwal, dokumen, dan prosedur kerja sehari-hari?',
   'Bagaimana administrasi yang tertib bisa mencegah kesalahan dalam pekerjaan?',
   '["Mengikuti Prosedur","Pencatatan yang Rapi","Mengatur Dokumen","Ketepatan Waktu"]'),
  ('ACT_PROBLEM', 'Mencari Jalan Keluar',
   'Mengapa setiap pekerjaan pasti membutuhkan kemampuan memecahkan masalah?',
   'Bagaimana berbagai profesi mencari jalan keluar ketika pekerjaannya tidak berjalan lancar?',
   'Bagaimana memecah masalah besar menjadi bagian kecil bisa membantu menyelesaikannya?',
   '["Mengenali Masalah","Mencari Pilihan Solusi","Menimbang Risiko","Mencoba dan Mengevaluasi"]'),
  ('ACT_QC', 'Memeriksa Hasil Kerja',
   'Mengapa hasil kerja perlu diperiksa ulang sebelum diserahkan?',
   'Bagaimana berbagai profesi memastikan hasil kerjanya sesuai standar?',
   'Bagaimana pemeriksaan yang teliti bisa mencegah masalah yang lebih besar?',
   '["Ketelitian","Memahami Standar Mutu","Mencatat Temuan","Menindaklanjuti Perbaikan"]'),
  ('ACT_RISET', 'Menguji Dugaan',
   'Mengapa sebuah dugaan perlu diuji sebelum dipercaya?',
   'Bagaimana berbagai profesi melakukan percobaan atau penelitian dalam pekerjaannya?',
   'Bagaimana hasil penelitian bisa membantu menemukan cara kerja yang lebih baik?',
   '["Rasa Ingin Tahu","Menyusun Pertanyaan","Mengumpulkan Bukti","Menarik Kesimpulan"]'),
  ('SKL_ADAPTABILITAS', 'Menyesuaikan Diri dengan Perubahan',
   'Mengapa kemampuan beradaptasi penting ketika situasi kerja berubah?',
   'Bagaimana berbagai profesi menyesuaikan diri dengan teknologi, aturan, atau tim yang baru?',
   'Bagaimana sikap mudah beradaptasi bisa membantu menghadapi situasi yang tidak terduga?',
   '["Terbuka pada Perubahan","Belajar Hal Baru","Tetap Tenang","Fleksibel"]'),
  ('SKL_BELAJAR', 'Mempelajari Hal Baru',
   'Mengapa kemampuan belajar cepat dibutuhkan di dunia kerja sekarang?',
   'Bagaimana berbagai profesi terus belajar agar kemampuannya tidak tertinggal?',
   'Bagaimana cara belajar yang efektif bisa membantu saat menghadapi tugas yang belum pernah dikerjakan?',
   '["Rasa Ingin Tahu","Mencari Sumber Belajar","Mencatat Poin Penting","Mempraktikkan Ilmu Baru"]'),
  ('SKL_CRITICAL', 'Menilai Informasi',
   'Mengapa kita tidak boleh langsung percaya pada setiap informasi yang kita terima?',
   'Bagaimana berbagai profesi memeriksa kebenaran informasi sebelum memakainya?',
   'Bagaimana berpikir kritis bisa membantu menghindari keputusan yang keliru?',
   '["Mempertanyakan Asumsi","Memeriksa Sumber","Membandingkan Sudut Pandang","Menarik Kesimpulan Logis"]'),
  ('SKL_EMPATI', 'Memahami Perasaan Orang Lain',
   'Mengapa memahami perasaan orang lain penting dalam bekerja?',
   'Bagaimana berbagai profesi menunjukkan empati kepada rekan kerja atau orang yang dilayani?',
   'Bagaimana empati bisa membantu meredakan konflik atau kesalahpahaman?',
   '["Mendengarkan Aktif","Peka terhadap Perasaan","Menghargai Perbedaan","Menanggapi dengan Tepat"]'),
  ('SKL_KEPEMIMPINAN', 'Memberi Contoh',
   'Mengapa seorang pemimpin perlu memberi contoh, bukan hanya memberi perintah?',
   'Bagaimana berbagai profesi memimpin tim atau kegiatan dalam pekerjaannya?',
   'Bagaimana kepemimpinan yang baik bisa membantu tim menghadapi masa sulit?',
   '["Memberi Contoh","Mengambil Inisiatif","Memotivasi Orang Lain","Bertanggung Jawab"]'),
  ('SKL_KEPUTUSAN', 'Menimbang Pilihan',
   'Mengapa sebuah keputusan perlu ditimbang dulu sebelum diambil?',
   'Bagaimana berbagai profesi mengambil keputusan penting dalam pekerjaannya?',
   'Bagaimana cara menimbang untung dan rugi bisa membantu memilih jalan keluar terbaik?',
   '["Mengumpulkan Informasi","Menimbang Risiko","Berani Memutuskan","Menerima Konsekuensi"]'),
  ('SKL_KETELITIAN', 'Memperhatikan Detail',
   'Mengapa kesalahan kecil bisa berdampak besar dalam pekerjaan?',
   'Bagaimana berbagai profesi menjaga ketelitian dalam pekerjaannya sehari-hari?',
   'Bagaimana kebiasaan teliti bisa membantu mencegah masalah sebelum terjadi?',
   '["Memperhatikan Detail","Memeriksa Ulang","Mengikuti Prosedur","Konsisten"]'),
  ('SKL_KOLABORASI', 'Bekerja dalam Tim',
   'Mengapa bekerja sama dalam tim penting untuk menyelesaikan pekerjaan besar?',
   'Bagaimana berbagai profesi membagi peran dan bekerja sama dengan rekan kerjanya?',
   'Bagaimana kerja sama yang baik bisa membantu tim menyelesaikan masalah bersama?',
   '["Berbagi Peran","Komunikasi dalam Tim","Menghargai Pendapat","Saling Membantu"]'),
  ('SKL_KOMUNIKASI', 'Menyampaikan Pesan dengan Jelas',
   'Mengapa pesan yang disampaikan dengan jelas penting dalam pekerjaan?',
   'Bagaimana berbagai profesi berkomunikasi dengan rekan kerja, atasan, dan pelanggan?',
   'Bagaimana komunikasi yang jelas bisa membantu mencegah kesalahpahaman?',
   '["Komunikasi Verbal","Komunikasi Tertulis","Mendengarkan Aktif","Menyesuaikan Gaya Bicara"]'),
  ('SKL_KREATIVITAS', 'Menemukan Ide Baru',
   'Mengapa ide-ide baru dibutuhkan dalam setiap pekerjaan?',
   'Bagaimana berbagai profesi memunculkan ide kreatif dalam pekerjaannya?',
   'Bagaimana cara berpikir kreatif bisa membantu menemukan solusi yang tidak biasa?',
   '["Berpikir di Luar Kebiasaan","Mengembangkan Ide","Berani Mencoba","Menggabungkan Gagasan"]'),
  ('SKL_LOGIKA', 'Berpikir Runtut',
   'Mengapa berpikir runtut dan logis penting dalam menyelesaikan pekerjaan?',
   'Bagaimana berbagai profesi memakai logika untuk menganalisa situasi?',
   'Bagaimana berpikir logis bisa membantu menemukan penyebab sebuah masalah?',
   '["Berpikir Runtut","Mengenali Pola","Menarik Kesimpulan","Menguji Alasan"]'),
  ('SKL_NEGOSIASI', 'Mencari Titik Temu',
   'Mengapa kemampuan bernegosiasi dibutuhkan dalam kehidupan sehari-hari dan pekerjaan?',
   'Bagaimana berbagai profesi bernegosiasi dengan klien, rekan, atau atasan?',
   'Bagaimana negosiasi yang baik bisa membantu menyelesaikan perbedaan kepentingan?',
   '["Memahami Kepentingan Pihak Lain","Menyampaikan Tawaran","Mencari Titik Temu","Menjaga Hubungan Baik"]'),
  ('SKL_NUMERIK', 'Bekerja dengan Angka',
   'Mengapa kemampuan berhitung tetap penting walau sudah ada kalkulator dan komputer?',
   'Bagaimana berbagai profesi memakai angka dan perhitungan dalam pekerjaannya?',
   'Bagaimana membaca angka dengan benar bisa membantu mengambil keputusan yang tepat?',
   '["Berhitung dengan Tepat","Membaca Data","Memahami Persentase","Memeriksa Perhitungan"]'),
  ('SKL_PERENCANAAN', 'Menyusun Rencana Kerja',
   'Mengapa pekerjaan perlu direncanakan sebelum dimulai?',
   'Bagaimana berbagai profesi menyusun rencana dan mengatur prioritas pekerjaannya?',
   'Bagaimana rencana yang matang bisa membantu menghadapi hambatan di tengah jalan?',
   '["Menentukan Tujuan","Menyusun Langkah","Mengatur Prioritas","Mengevaluasi Rencana"]'),
  ('SKL_PRESENTASI', 'Berbicara di Depan Orang Banyak',
   'Mengapa kemampuan presentasi penting untuk menyampaikan ide?',
   'Bagaimana berbagai profesi mempresentasikan hasil kerja atau gagasannya?',
   'Bagaimana presentasi yang baik bisa membantu meyakinkan orang lain terhadap solusimu?',
   '["Public Speaking","Menyusun Materi","Percaya Diri","Menjawab Pertanyaan"]'),
  ('SKL_WAKTU', 'Mengatur Waktu',
   'Mengapa mengatur waktu dengan baik penting dalam bekerja maupun belajar?',
   'Bagaimana berbagai profesi membagi waktu di antara banyak tugas?',
   'Bagaimana manajemen waktu yang baik bisa membantu menghadapi tenggat yang mepet?',
   '["Mengatur Prioritas","Membuat Jadwal","Menghindari Menunda","Disiplin"]')
on conflict (attr_code) do update set
  subskill = excluded.subskill, quest_1 = excluded.quest_1, quest_2 = excluded.quest_2,
  quest_3 = excluded.quest_3, tujuan = excluded.tujuan;

-- ---------------------------------------------------------------------------
-- 4. Syarat waktu praktik magang
--
--    Catatan desain: "User S1 Farmasi akan mendapat quest Praktik Magang
--    minimal saat di semester 5-6." Diperluas ke jenjang lain dengan patokan
--    yang sama -- kira-kira paruh kedua masa studi. SMK kelas 11 mengikuti
--    jadwal PKL SMK. SMP dan SMA tidak punya angka: magang baru terbuka
--    setelah lulus.
--
--    Pengguna yang tidak sedang studi (sudah lulus) selalu memenuhi syarat.
-- ---------------------------------------------------------------------------
create table if not exists public.quest_syarat_magang (
  level_code   text primary key,
  min_kelas    smallint,
  min_semester smallint,
  constraint chk_qsm_satu check (min_kelas is null or min_semester is null)
);

insert into public.quest_syarat_magang (level_code, min_kelas, min_semester) values
  ('SMP', null, null),
  ('SMA', null, null),
  ('SMK',   11, null),
  ('D1',  null,    2),
  ('D2',  null,    3),
  ('D3',  null,    4),
  ('D4',  null,    5),
  ('S1',  null,    5),
  ('S2',  null,    2),
  ('S3',  null,    3)
on conflict (level_code) do update set
  min_kelas = excluded.min_kelas, min_semester = excluded.min_semester;

-- ---------------------------------------------------------------------------
-- 5. Badge
-- ---------------------------------------------------------------------------
create table if not exists public.achievements (
  code           text primary key,
  name_id        text not null,
  description_id text not null,
  image          text not null
);

insert into public.achievements (code, name_id, description_id, image) values
  ('QUEST_STARTER', 'Quest Starter', 'Menyelesaikan Quest Pertama kali', '/quest/badge-quest-starter.png')
on conflict (code) do update set
  name_id = excluded.name_id, description_id = excluded.description_id, image = excluded.image;

create table if not exists public.user_achievements (
  user_id     uuid not null references auth.users(id) on delete cascade,
  code        text not null references public.achievements(code),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, code)
);

-- ---------------------------------------------------------------------------
-- 6. Status quest pengguna
--
--    Hanya bisa ditulis lewat ambil_quest() / selesaikan_quest(). Tidak ada
--    policy INSERT/UPDATE untuk pengguna: kalau ada, siapa pun bisa menandai
--    quest selesai lewat REST dan melewati semua aturan buka-kunci.
-- ---------------------------------------------------------------------------
create table if not exists public.user_quests (
  id           bigint generated always as identity unique,
  user_id      uuid not null references auth.users(id) on delete cascade,
  career_id    integer not null references public.careers(id) on delete cascade,
  quest_key    text not null,
  status       text not null,
  xp           smallint not null,
  taken_at     timestamptz not null default now(),
  completed_at timestamptz,
  primary key (user_id, career_id, quest_key),
  constraint chk_uq_status check (status in ('DIAMBIL','SELESAI')),
  constraint chk_uq_selesai check ((status = 'SELESAI') = (completed_at is not null))
);

-- Satu quest hanya dibayar XP sekali.
create unique index if not exists uq_xp_quest_once
  on public.xp_ledger (user_id, source_id) where source_kind = 'QUEST';

do $$
declare t text;
begin
  foreach t in array array['quest_group_kinds','quest_items','soft_skill_focus',
                           'quest_syarat_magang','achievements']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_read_all', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t||'_read_all', t);
  end loop;

  foreach t in array array['user_quests','user_achievements']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_owner_select', t);
    execute format('create policy %I on public.%I for select to authenticated using (user_id = auth.uid())',
                   t||'_owner_select', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 7. Katalog quest satu profesi
--
--    Tidak bergantung pengguna. Urutan grup di dalam jenis mengikuti urutan
--    yang dipakai Journey, jadi grup pertama yang belum selesai di sini sama
--    dengan kartu teratas di Journey.
-- ---------------------------------------------------------------------------

-- Empat soft skill tahap Pondasi. Kueri yang sama dengan blok SOFT_SKILL di
-- journey_stage() (0035); kalau yang satu diubah, ubah juga yang lain.
create or replace function public.soft_skill_profesi(p_career_id integer)
returns table (attr_code text, urutan integer)
language sql stable set search_path = public as $$
  select a.code, (row_number() over (order by d.rank_in_layer, a.code))::integer
  from public.careers c
  join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
  join public.dna_attributes a on a.code = d.attribute_code
  where c.id = p_career_id and a.layer_code in ('ACTIVITY','SKILL')
  order by d.rank_in_layer, a.code
  limit 4;
$$;

-- "Mencatat riwayat medis pasien" -> "mencatat riwayat medis pasien" supaya
-- terbaca wajar di tengah kalimat. Nama hard skill kita berbentuk kegiatan
-- (turunan O*NET DWA), jadi huruf pertamanya selalu kata kerja biasa.
create or replace function public.huruf_kecil_awal(p_text text)
returns text language sql immutable as $$
  select lower(left(p_text, 1)) || substr(p_text, 2);
$$;

create or replace function public.quest_katalog(p_career_id integer)
returns table (
  group_kind text, kind_order smallint, group_code text, group_order integer,
  group_title text, group_subtitle text,
  quest_key text, item_code text, item_order smallint, label text, teks text,
  min_menit smallint, max_menit smallint, xp smallint, syarat text, journey_item text
)
language sql stable set search_path = public as $$
  with prof as (
    select c.id, c.career_name from public.careers c where c.id = p_career_id
  ),
  grup as (
    -- Eksplorasi: satu grup, profesinya sendiri.
    select 'EKSPLORASI'::text as kind, 'PROFESI'::text as kode, 1 as urutan,
           public.isi_profesi(s.hero_id, p.career_name) as judul,
           null::text as sub, null::text as nama_item
    from prof p, public.journey_stages s where s.code = 'EKSPLORASI'
    union all
    select 'SOFT_SKILL', ss.attr_code, ss.urutan, a.name_id, f.subskill, a.name_id
    from public.soft_skill_profesi(p_career_id) ss
    join public.dna_attributes a on a.code = ss.attr_code
    join public.soft_skill_focus f on f.attr_code = ss.attr_code
    union all
    select 'HARD_SKILL', h.skill_code, h.display_order::integer, h.nama, null, h.nama
    from public.career_hard_skill_view h where h.career_id = p_career_id
    union all
    -- Nama kategori tools ("Pengolah Angka (Microsoft Excel, Google Sheets)"),
    -- bukan contoh_produk: contoh produk turunan O*NET berbau pasar Amerika
    -- ("MEDITECH software", "Apache Spark" untuk BI) dan tidak dikenal siswa.
    select 'TOOL', o.tool_code,
           (row_number() over (order by o.fase_order, o.display_order, o.tool_code))::integer,
           o.nama, null, o.nama
    from public.career_tool_view o where o.career_id = p_career_id
    union all
    select 'PENGALAMAN', 'KEGIATAN', 1, s.summary_id, null, null
    from public.journey_stages s where s.code = 'PENGALAMAN'
    union all
    select 'BERKARIER', 'KARIER', 1, 'Persiapkan dirimu untuk masuk ke dunia kerja', null, null
  )
  select
    g.kind, k.kind_order, g.kode, g.urutan, g.judul, g.sub,
    g.kind || ':' || g.kode || ':' || i.item_code,
    i.item_code, i.item_order, i.label_id,
    case g.kind
      when 'SOFT_SKILL' then
        case i.item_code when '1' then f.quest_1 when '2' then f.quest_2 else f.quest_3 end
      else
        replace(replace(i.text_template,
          '[item]', case when g.kind = 'HARD_SKILL'
                         then public.huruf_kecil_awal(coalesce(g.nama_item, ''))
                         else coalesce(g.nama_item, '') end),
          '[profesi]', (select career_name from prof))
    end,
    i.min_menit, i.max_menit, i.xp, i.syarat, i.journey_item
  from grup g
  join public.quest_group_kinds k on k.code = g.kind
  join public.quest_items i on i.group_kind = g.kind
  left join public.soft_skill_focus f on g.kind = 'SOFT_SKILL' and f.attr_code = g.kode
  where exists (select 1 from prof);
$$;

comment on function public.quest_katalog(integer) is
  'Seluruh quest satu profesi, lengkap dengan kalimat yang sudah disisipi nama profesi dan item. Tidak bergantung pengguna.';

-- ---------------------------------------------------------------------------
-- 8. Syarat tambahan untuk pengguna yang sedang masuk
-- ---------------------------------------------------------------------------
create or replace function public.quest_syarat(p_career_id integer)
returns table (syarat text, terpenuhi boolean, alasan text)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with pr as (
    select p.education_level_code as lv, p.graduation_status as st,
           p.grade_level as kelas, p.semester as smt
    from public.profiles p where p.user_id = auth.uid()
  ),
  m as (
    select pr.*, q.min_kelas, q.min_semester, el.level_name
    from pr
    left join public.quest_syarat_magang q on q.level_code = pr.lv
    left join public.education_levels el on el.code = pr.lv
  ),
  ps as (select * from public.posisi_studi()),
  cr as (select min_education_rank from public.careers where id = p_career_id)
  -- Magang
  select 'MAGANG_WAKTU',
    coalesce((
      select case
        when m.st is distinct from 'sedang_studi' then true
        when m.min_kelas is not null then coalesce(m.kelas, 0) >= m.min_kelas
        when m.min_semester is not null then coalesce(m.smt, 0) >= m.min_semester
        else false
      end from m), true),
    (select case
       when m.min_kelas is not null then 'Terbuka mulai kelas ' || m.min_kelas || '.'
       when m.min_semester is not null then 'Terbuka mulai semester ' || m.min_semester || '.'
       else 'Terbuka setelah kamu lulus ' || coalesce(m.level_name, 'sekolah') || '.'
     end from m)
  union all
  -- Lamaran kerja: jenjang yang sudah tuntas, atau yang sedang dijalani kalau
  -- tinggal semester/kelas terakhir, harus memenuhi jenjang minimum profesi.
  select 'JENJANG_KERJA',
    (select greatest(ps.rank_tercapai,
                     case when ps.sisa_bulan <= 6 then coalesce(ps.rank_sedang, 0) else 0 end)
            >= cr.min_education_rank
     from ps, cr),
    (select 'Terbuka saat pendidikanmu hampir memenuhi syarat profesi ini: minimal '
            || public.label_jenjang(cr.min_education_rank) || '.'
     from cr);
$$;

comment on function public.quest_syarat(integer) is
  'Dua syarat quest di luar aturan buka-kunci grup: waktu magang dan jenjang untuk melamar kerja.';

-- ---------------------------------------------------------------------------
-- 9. Status tiap quest untuk pengguna yang sedang masuk
-- ---------------------------------------------------------------------------
create or replace function public.quest_status(p_career_id integer)
returns table (
  group_kind text, kind_order smallint, group_code text, group_order integer,
  group_title text, group_subtitle text,
  quest_key text, item_code text, item_order smallint, label text, teks text,
  min_menit smallint, max_menit smallint, xp smallint, syarat text, journey_item text,
  status text, grup_terbuka boolean, bisa boolean, alasan text
)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with kat as (select * from public.quest_katalog(p_career_id)),
  uq as (
    select u.quest_key, u.status from public.user_quests u
    where u.user_id = auth.uid() and u.career_id = p_career_id
  ),
  st as (
    select k.*, coalesce(uq.status, 'BELUM') as status
    from kat k left join uq on uq.quest_key = k.quest_key
  ),
  -- Jumlah quest selesai dan total per jenis, untuk aturan buka-kunci.
  per_jenis as (
    select s.group_kind as kind,
           count(*) filter (where s.status = 'SELESAI') as selesai,
           count(*) as total
    from st s group by s.group_kind
  ),
  terbuka as (
    select g.code,
           case
             when g.buka_setelah is null then true
             when g.buka_minimal is null then coalesce(pj.selesai = pj.total and pj.total > 0, false)
             else coalesce(pj.selesai, 0) >= g.buka_minimal
           end as buka,
           g.alasan_kunci, g.berurutan
    from public.quest_group_kinds g
    left join per_jenis pj on pj.kind = g.buka_setelah
  ),
  sy as (select * from public.quest_syarat(p_career_id))
  select
    s.group_kind, s.kind_order, s.group_code, s.group_order, s.group_title, s.group_subtitle,
    s.quest_key, s.item_code, s.item_order, s.label, s.teks,
    s.min_menit, s.max_menit, s.xp, s.syarat, s.journey_item,
    s.status,
    t.buka,
    s.status <> 'SELESAI' and t.buka and not kunci.urutan and coalesce(sy.terpenuhi, true),
    case
      when s.status = 'SELESAI' then null
      when not t.buka then t.alasan_kunci
      when kunci.urutan then 'Selesaikan quest sebelumnya dulu.'
      when not coalesce(sy.terpenuhi, true) then sy.alasan
    end
  from st s
  join terbuka t on t.code = s.group_kind
  left join sy on sy.syarat = s.syarat
  cross join lateral (
    select t.berurutan and exists (
      select 1 from st p
      where p.group_kind = s.group_kind and p.group_code = s.group_code
        and p.item_order < s.item_order and p.status <> 'SELESAI'
    ) as urutan
  ) kunci;
$$;

comment on function public.quest_status(integer) is
  'Katalog quest profesi ditambah status pengguna: BELUM/DIAMBIL/SELESAI, apakah grupnya terbuka, apakah bisa ditekan sekarang, dan alasannya kalau tidak.';

-- ---------------------------------------------------------------------------
-- 10. Layar "Quest" -- apa yang dikerjakan minggu ini
--
--     Satu kartu per jenis yang sudah terbuka: grup pertama yang masih punya
--     quest belum selesai. Itu yang membuat daftarnya pendek dan bergeser --
--     di desain terlihat Soft Skill + Hard Skill + Tools, lalu belakangan
--     Tools + Asah Pengalaman + Siap Berkarier.
-- ---------------------------------------------------------------------------
create or replace function public.quest_beranda()
returns table (career_id integer, career_name text, has_career boolean,
               eksplorasi_selesai boolean, semua_selesai boolean, grup jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with pilih as (select public.profesi_pilihan() as cid),
  prof as (select c.id, c.career_name from public.careers c, pilih where c.id = pilih.cid),
  st as (select s.* from pilih, public.quest_status(pilih.cid) s where pilih.cid is not null),
  g as (
    select s.group_kind, s.kind_order, s.group_code, s.group_order,
           s.group_title, s.group_subtitle,
           bool_and(s.grup_terbuka) as buka,
           count(*) as n_quest,
           count(*) filter (where s.status = 'SELESAI') as n_selesai,
           count(*) filter (where s.status = 'DIAMBIL') as n_diambil
    from st s
    group by 1,2,3,4,5,6
  ),
  pertama as (
    select distinct on (g.group_kind) g.*
    from g
    where g.buka and g.n_selesai < g.n_quest
    order by g.group_kind, g.group_order
  )
  select
    (select id from prof),
    (select career_name from prof),
    exists (select 1 from prof),
    coalesce((select bool_and(status = 'SELESAI') from st where group_kind = 'EKSPLORASI'), false),
    exists (select 1 from st) and not exists (select 1 from st where status <> 'SELESAI'),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'jenis',     p.group_kind,
        'slug',      k.slug,
        'kode',      p.group_code,
        'label',     k.label_id,
        'judul',     p.group_title,
        'subjudul',  p.group_subtitle,
        'ikon',      k.icon,
        'tone',      k.tone,
        'n_quest',   p.n_quest,
        'n_selesai', p.n_selesai,
        'n_diambil', p.n_diambil
      ) order by p.kind_order)
      from pertama p join public.quest_group_kinds k on k.code = p.group_kind
    ), '[]'::jsonb);
$$;

comment on function public.quest_beranda() is
  'Kartu-kartu layar Quest: satu grup berjalan per jenis yang sudah terbuka.';

-- ---------------------------------------------------------------------------
-- 11. Isi satu grup
-- ---------------------------------------------------------------------------
create or replace function public.quest_grup(p_slug text, p_group_code text)
returns table (
  jenis text, kode text, label text, judul text, subjudul text, mode text,
  berurutan boolean, terbuka boolean, alasan_kunci text,
  tips jsonb, tujuan jsonb, catatan text, quest jsonb
)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with k as (select * from public.quest_group_kinds where slug = p_slug),
  pilih as (select public.profesi_pilihan() as cid),
  st as (
    select s.* from pilih, k, public.quest_status(pilih.cid) s
    where pilih.cid is not null and s.group_kind = k.code and s.group_code = p_group_code
  )
  select
    k.code, p_group_code, k.label_id,
    (select group_title from st limit 1),
    (select group_subtitle from st limit 1),
    k.mode, k.berurutan,
    coalesce((select bool_and(grup_terbuka) from st), false),
    k.alasan_kunci,
    jsonb_build_object(
      'gambar', k.tips_gambar, 'label', k.tips_label,
      'judul', k.tips_judul, 'isi', nullif(k.tips_isi, ''), 'sumber', k.tips_sumber),
    case k.code
      when 'EKSPLORASI' then
        '["Kenali profesi impian","Rutinitas kerja profesi","Mantapkan pilihan karier"]'::jsonb
      when 'SOFT_SKILL' then
        (select f.tujuan from public.soft_skill_focus f where f.attr_code = p_group_code)
    end,
    k.catatan_id,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',       s.quest_key,
        'label',     s.label,
        'teks',      s.teks,
        'min_menit', s.min_menit,
        'max_menit', s.max_menit,
        'xp',        s.xp,
        'status',    s.status,
        'bisa',      s.bisa,
        'alasan',    s.alasan
      ) order by s.item_order)
      from st s
    ), '[]'::jsonb)
  from k
  where exists (select 1 from st);
$$;

comment on function public.quest_grup(text, text) is
  'Isi satu grup quest: header, banner tips, lembar Tujuan Quest, catatan, dan daftar quest berstatus. Kosong kalau grup tidak ada untuk profesi pilihan.';

-- ---------------------------------------------------------------------------
-- 12. Sinkron ke Journey
--
--     Dipanggil setiap status quest berubah. Menghitung ulang, bukan
--     menambah: hasilnya selalu sama dengan isi user_quests, jadi tidak ada
--     angka yang bisa bergeser karena dipanggil dua kali.
-- ---------------------------------------------------------------------------
create or replace function public.quest_sinkron_journey(p_user uuid, p_career_id integer)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
begin
  -- quest_status() membaca auth.uid(); fungsi ini hanya dipanggil dari dua
  -- RPC di bawah, yang sudah memastikan p_user = auth.uid().

  -- Persen per tahap.
  insert into public.user_journey_progress (user_id, career_id, stage_code, percent, completed_at, updated_at)
  select p_user, p_career_id, k.stage_code,
         round(100.0 * count(*) filter (where s.status = 'SELESAI') / count(*))::smallint,
         case when bool_and(s.status = 'SELESAI') then now() end,
         now()
  from public.quest_status(p_career_id) s
  join public.quest_group_kinds k on k.code = s.group_kind
  group by k.stage_code
  on conflict (user_id, career_id, stage_code) do update set
    percent = excluded.percent,
    -- Tanggal selesai pertama dipertahankan.
    completed_at = case when excluded.completed_at is null then null
                        else coalesce(public.user_journey_progress.completed_at, excluded.completed_at) end,
    updated_at = now();

  -- Item Journey berbentuk grup: soft skill, hard skill, tools.
  insert into public.user_journey_items (user_id, career_id, item_kind, item_code, status, updated_at)
  select p_user, p_career_id,
         case s.group_kind when 'TOOL' then 'TOOL' else s.group_kind end,
         s.group_code,
         case when bool_and(s.status = 'SELESAI') then 'SELESAI'
              when bool_or(s.status <> 'BELUM') then 'BERLANGSUNG'
              else 'BELUM_MULAI' end,
         now()
  from public.quest_status(p_career_id) s
  where s.group_kind in ('SOFT_SKILL','HARD_SKILL','TOOL')
  group by s.group_kind, s.group_code
  having bool_or(s.status <> 'BELUM')
  on conflict (user_id, career_id, item_kind, item_code) do update set
    status = excluded.status, updated_at = now();

  -- Item Journey tahap Pengalaman: satu quest = satu kegiatan.
  insert into public.user_journey_items (user_id, career_id, item_kind, item_code, status, updated_at)
  select p_user, p_career_id, 'KEGIATAN', s.journey_item, 'SELESAI', now()
  from public.quest_status(p_career_id) s
  where s.journey_item is not null and s.status = 'SELESAI'
  on conflict (user_id, career_id, item_kind, item_code) do update set
    status = excluded.status, updated_at = now();
end $$;

revoke all on function public.quest_sinkron_journey(uuid, integer) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 13. Ambil dan selesaikan
-- ---------------------------------------------------------------------------
create or replace function public.ambil_quest(p_quest_key text)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  v_cid  integer := public.profesi_pilihan();
  q record;
begin
  if v_user is null then
    raise exception 'ambil_quest: tidak ada pengguna terautentikasi';
  end if;
  if v_cid is null then
    raise exception 'ambil_quest: belum ada profesi pilihan';
  end if;

  select s.*, k.mode into q
  from public.quest_status(v_cid) s
  join public.quest_group_kinds k on k.code = s.group_kind
  where s.quest_key = p_quest_key;

  if not found then
    raise exception 'ambil_quest: quest % bukan milik profesi pilihanmu', p_quest_key;
  end if;
  if q.mode <> 'AMBIL' then
    raise exception 'ambil_quest: quest % langsung diselesaikan, tidak perlu diambil', p_quest_key;
  end if;
  if q.status <> 'BELUM' then
    return;  -- sudah diambil atau selesai; tombol ganda tidak perlu jadi error
  end if;
  if not q.bisa then
    raise exception 'ambil_quest: %', coalesce(q.alasan, 'quest belum terbuka');
  end if;

  insert into public.user_quests (user_id, career_id, quest_key, status, xp)
  values (v_user, v_cid, p_quest_key, 'DIAMBIL', q.xp)
  on conflict do nothing;

  perform public.quest_sinkron_journey(v_user, v_cid);
end $$;

comment on function public.ambil_quest(text) is
  'Ambil satu quest dari profesi pilihan. Aturan buka-kunci dan urutan diperiksa di sini, bukan di layar.';

create or replace function public.selesaikan_quest(p_quest_key text)
returns table (xp integer, total_xp integer, level_name text, badge jsonb)
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user  uuid := auth.uid();
  v_cid   integer := public.profesi_pilihan();
  v_id    bigint;
  v_badge jsonb;
  q record;
begin
  if v_user is null then
    raise exception 'selesaikan_quest: tidak ada pengguna terautentikasi';
  end if;
  if v_cid is null then
    raise exception 'selesaikan_quest: belum ada profesi pilihan';
  end if;

  select s.*, k.mode into q
  from public.quest_status(v_cid) s
  join public.quest_group_kinds k on k.code = s.group_kind
  where s.quest_key = p_quest_key;

  if not found then
    raise exception 'selesaikan_quest: quest % bukan milik profesi pilihanmu', p_quest_key;
  end if;
  if q.status = 'SELESAI' then
    raise exception 'selesaikan_quest: quest % sudah selesai', p_quest_key;
  end if;

  if q.mode = 'AMBIL' then
    -- Quest yang diambil sudah lolos buka-kunci saat diambil. Syaratnya tidak
    -- diperiksa ulang: pengguna yang mengambil quest lalu profilnya berubah
    -- tidak boleh terjebak dengan quest setengah jalan.
    if q.status <> 'DIAMBIL' then
      raise exception 'selesaikan_quest: ambil quest % dulu', p_quest_key;
    end if;
    update public.user_quests
       set status = 'SELESAI', completed_at = now()
     where user_id = v_user and career_id = v_cid and quest_key = p_quest_key
    returning id into v_id;
  else
    if not q.bisa then
      raise exception 'selesaikan_quest: %', coalesce(q.alasan, 'quest belum terbuka');
    end if;
    insert into public.user_quests (user_id, career_id, quest_key, status, xp, completed_at)
    values (v_user, v_cid, p_quest_key, 'SELESAI', q.xp, now())
    returning id into v_id;
  end if;

  insert into public.xp_ledger (user_id, source_kind, source_id, xp, reason)
  values (v_user, 'QUEST', v_id, q.xp, 'Menyelesaikan quest: ' || q.label)
  on conflict do nothing;

  -- Badge pertama. Dihitung lintas profesi: "pertama kali" berarti pertama
  -- kali di Navika, bukan pertama kali di profesi ini.
  with baru as (
    insert into public.user_achievements (user_id, code)
    values (v_user, 'QUEST_STARTER')
    on conflict do nothing
    returning code
  )
  select jsonb_build_object('kode', a.code, 'nama', a.name_id,
                            'deskripsi', a.description_id, 'gambar', a.image)
    into v_badge
  from baru join public.achievements a on a.code = baru.code;

  perform public.quest_sinkron_journey(v_user, v_cid);

  return query
    select q.xp::integer, x.total_xp, x.level_name, v_badge
    from public.xp_pengguna() x;
end $$;

comment on function public.selesaikan_quest(text) is
  'Selesaikan satu quest: tulis XP sekali, beri badge Quest Starter kalau ini yang pertama, dan perbarui kemajuan Journey.';

-- ---------------------------------------------------------------------------
-- 14. "Quest minggu ini" di Explore
--
--     Sebelumnya explore_weekly_quests() membaca aktivitas roadmap lama
--     (0006/0017), sementara tombol panahnya membuka layar Quest ini -- dua
--     daftar yang tidak sama. Sekarang Explore membaca dari sumber yang sama:
--     quest yang bisa dikerjakan saat ini, satu per grup berjalan.
-- ---------------------------------------------------------------------------
create or replace function public.quest_minggu_ini(p_limit integer default 3)
returns table (quest_key text, jenis text, slug text, kode text, label text,
               teks text, min_menit smallint, max_menit smallint, xp smallint,
               status text, total bigint)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with pilih as (select public.profesi_pilihan() as cid),
  st as (select s.* from pilih, public.quest_status(pilih.cid) s where pilih.cid is not null),
  bisa as (
    -- Quest yang sedang diambil didahulukan, lalu yang bisa diambil.
    select distinct on (s.group_kind) s.*
    from st s
    where s.status = 'DIAMBIL' or s.bisa
    order by s.group_kind, (s.status = 'DIAMBIL') desc, s.group_order, s.item_order
  )
  select b.quest_key, b.group_kind, k.slug, b.group_code, b.label, b.teks,
         b.min_menit, b.max_menit, b.xp, b.status,
         (select count(*) from st where st.status = 'DIAMBIL' or st.bisa)
  from bisa b join public.quest_group_kinds k on k.code = b.group_kind
  order by k.kind_order
  limit greatest(p_limit, 1);
$$;

comment on function public.quest_minggu_ini(integer) is
  'Quest yang bisa dikerjakan sekarang, satu per jenis, untuk kartu "Quest minggu ini" di Explore. total = semua quest yang bisa dikerjakan saat ini.';

-- ---------------------------------------------------------------------------
-- 15. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int; v_cid int;
begin
  select count(*) into n from public.quest_group_kinds;
  if n <> 6 then raise exception '0036: quest_group_kinds harus 6 baris, dapat %', n; end if;

  -- Tiap jenis punya quest, dan jenis AMBIL wajib punya durasi (ditampilkan
  -- di baris quest); jenis LANGSUNG tidak.
  select count(*) into n from public.quest_group_kinds k
   where not exists (select 1 from public.quest_items i where i.group_kind = k.code);
  if n > 0 then raise exception '0036: % jenis grup tanpa quest', n; end if;

  select count(*) into n from public.quest_items i
  join public.quest_group_kinds k on k.code = i.group_kind
  where (k.mode = 'AMBIL') <> (i.min_menit is not null);
  if n > 0 then raise exception '0036: % quest dengan durasi tidak sesuai mode grupnya', n; end if;

  -- Soft skill: setiap atribut yang bisa muncul di tahap Pondasi punya isi.
  select count(*) into n from public.dna_attributes a
   where a.layer_code in ('ACTIVITY','SKILL')
     and not exists (select 1 from public.soft_skill_focus f where f.attr_code = a.code);
  if n > 0 then raise exception '0036: % soft skill tanpa quest', n; end if;

  -- Aturan buka-kunci tidak boleh melingkar dan harus bisa dimulai.
  select count(*) into n from public.quest_group_kinds where buka_setelah is null;
  if n = 0 then raise exception '0036: tidak ada jenis grup yang terbuka sejak awal'; end if;
  select count(*) into n from public.quest_group_kinds k
    join public.quest_group_kinds p on p.code = k.buka_setelah
   where p.kind_order >= k.kind_order;
  if n > 0 then raise exception '0036: % aturan buka-kunci menunjuk jenis yang datang belakangan', n; end if;

  -- Setiap jenjang yang ada punya patokan magang.
  select count(*) into n from public.education_levels el
   where el.code is not null
     and not exists (select 1 from public.quest_syarat_magang q where q.level_code = el.code);
  if n > 0 then raise exception '0036: % jenjang tanpa patokan magang', n; end if;

  -- Setiap profesi aktif punya quest di keenam jenis, dan tidak ada kalimat
  -- yang masih menyisakan slot.
  select count(*) into n from public.careers c
   where c.is_active
     and (select count(distinct group_kind) from public.quest_katalog(c.id)) <> 6;
  if n > 0 then raise exception '0036: % profesi aktif tidak lengkap enam jenis quest', n; end if;

  select id into v_cid from public.careers where is_active order by id limit 1;
  select count(*) into n from public.quest_katalog(v_cid) where teks like '%[%]%' or teks is null;
  if n > 0 then raise exception '0036: % kalimat quest masih bersolot atau kosong', n; end if;

  raise notice '0036: 6 jenis grup, % template quest, % soft skill; profesi % punya % quest',
    (select count(*) from public.quest_items),
    (select count(*) from public.soft_skill_focus),
    v_cid, (select count(*) from public.quest_katalog(v_cid));
end $$;

commit;
