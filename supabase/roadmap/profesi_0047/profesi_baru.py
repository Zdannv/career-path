"""Profesi baru untuk sub-industri yang isinya terlalu sedikit (permintaan Nico,
28 Oktober 2026). Satu entri = satu profesi; generator buat_0047.py mengubahnya
jadi SQL. Angka gaji, demand, dan ketahanan AI TIDAK ditulis di sini: dihitung
dengan model yang sama dengan 0012/0027."""

# Prodi (study_programs.id) dan SMK (smk_concentrations.id) yang dipakai
P = dict(HUKUM=41, KESOS=46, PEMERINTAHAN=47, ADM_PUBLIK=48, POLITIK=37, KOMUNIKASI=50,
         PEMBANGUNAN_SOSIAL=57, PENGEMBANGAN_MASY=62, PARIWISATA=174, TATA_BOGA=188,
         TEKNIK_LINGKUNGAN=192, INFRA_LINGKUNGAN=233, KESLING=5, SDA_LINGKUNGAN=36,
         EKONOMI_SDA=71, BIOLOGI=19, KIMIA=17, TEKNIK_KIMIA=228, KEHUTANAN=154,
         KONSERVASI_EKOWISATA=161, TEKNIK_TELKOM=211, TEKNIK_ELEKTRO=201,
         KEPOLISIAN=178, MILITER=179, MANAJEMEN_OPS=76)
K = dict(KULINER=38, PEKSOS=45, PERHOTELAN=51, ULW=125, EKOWISATA=126, KIMIA_ANALISIS=34,
         TKJ=75, TJAT=76, TTT=77, ELKOM=64)

# Jalur pendidikan: (jenis, jenjang, judul). Judul yang sama persis dengan
# campus_paths (mis. "Sarjana (S1) Pariwisata") langsung mendapat daftar kampus.
S1 = lambda prodi: ("AKADEMIK", "S1", f"Sarjana (S1) {prodi}")
D3 = lambda prodi: ("VOKASI", "D3", f"Diploma (D3) {prodi}")
SMK = lambda jur: ("VOKASI", "SMK", f"SMK {jur}")

PROFESI = [
    # ── Hukum & Kebijakan ────────────────────────────────────────────────
    dict(nama="Advokat / Pengacara", en="Lawyers", alt="Lawyer;Pengacara;Kuasa Hukum", soc="23-1011.00",
         rank=6, rumpun="SOC_23_10", lisensi=["PKPA_UPA"],
         sub=[("LEG_FIRMA", True)],
         desk="Mewakili dan mendampingi klien, baik orang maupun perusahaan, dalam perkara pidana, perdata, "
              "atau bisnis, di dalam maupun di luar pengadilan. Sehari-hari meriset peraturan dan putusan, "
              "menyusun gugatan atau pembelaan, bernegosiasi, dan beracara di persidangan. Wajib lulus S1 Hukum, "
              "PKPA, ujian profesi advokat, dan disumpah di Pengadilan Tinggi.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")]),
    dict(nama="Notaris", en="Notaries", alt="Notary Public;Pejabat Pembuat Akta", soc="23-1011.00",
         rank=7, rumpun="SOC_23_10", lisensi=["NOTARIS"],
         sub=[("LEG_FIRMA", True)],
         desk="Pejabat umum yang berwenang membuat akta autentik, misalnya akta pendirian perusahaan, "
              "perjanjian, jual beli, dan wasiat, serta mengesahkan tanda tangan dan salinan dokumen. "
              "Memastikan setiap perjanjian sah secara hukum dan menyimpan protokol aktanya. Jalurnya S1 Hukum, "
              "Magister Kenotariatan, magang di kantor notaris, lalu diangkat Menteri Hukum.",
         edu=[("PRODI", P["HUKUM"], 100)],
         jalur=[("AKADEMIK", "S2", "Magister (S2) Kenotariatan")],
         dwa=["4.A.3.b.6.n.9", "4.A.4.b.6.h.1", "4.A.1.a.1.e.1", "4.A.1.a.1.e.2", "4.A.2.a.4.h.1",
              "4.A.4.a.2.i.1", "4.A.4.a.7.b.10", "4.A.3.b.6.n.3"],
         catatan="DNA dan hard skill memakai O*NET Lawyers (23-1011.00); O*NET tidak punya okupasi notaris civil law."),
    dict(nama="Jaksa", en="Prosecutors", alt="Penuntut Umum;Prosecutor", soc="23-1011.00",
         rank=6, rumpun="SOC_23_10", lisensi=["PPPJ"],
         sub=[("LEG_PERADILAN", True), ("GOV_PENEGAKAN", False)],
         desk="Aparatur Kejaksaan yang menuntut perkara pidana atas nama negara: meneliti berkas dari "
              "penyidik, menyusun dakwaan dan tuntutan, membuktikan perkara di persidangan, lalu melaksanakan "
              "putusan hakim. Diangkat lewat seleksi CPNS Kejaksaan dan Pendidikan Pembentukan Jaksa.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")],
         dwa=["4.A.4.a.3.a.2", "4.A.2.a.4.h.1", "4.A.1.a.1.w.7", "4.A.4.a.2.i.1", "4.A.1.a.1.e.2",
              "4.A.3.b.6.n.9", "4.A.1.a.1.e.1", "4.A.4.a.2.i.2"],
         catatan="DNA dan hard skill memakai O*NET Lawyers (23-1011.00), dipilih yang relevan dengan penuntutan."),
    dict(nama="Hakim", en="Judges, Magistrate Judges, and Magistrates", alt="Judge", soc="23-1023.00",
         rank=6, rumpun="SOC_23_10", lisensi=["PPC_HAKIM"],
         sub=[("LEG_PERADILAN", True), ("GOV_PENEGAKAN", False)],
         desk="Memeriksa, mengadili, dan memutus perkara di pengadilan negeri, agama, tata usaha negara, "
              "atau militer. Memimpin persidangan, menilai alat bukti dan keterangan saksi, lalu menyusun "
              "putusan yang adil berdasarkan hukum. Diangkat lewat seleksi calon hakim Mahkamah Agung dan "
              "pendidikan calon hakim terpadu.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")]),
    dict(nama="Legal Officer", en="Corporate Legal Officers", alt="Staf Legal;Corporate Legal;In-house Counsel",
         soc="23-1011.00", rank=6, rumpun="SOC_23_10", lisensi=[],
         sub=[("LEG_COMPLIANCE", True), ("LEG_FIRMA", False)],
         desk="Menangani urusan hukum di dalam perusahaan: menyusun dan menelaah kontrak, mengurus perizinan, "
              "memastikan kegiatan usaha sesuai peraturan, dan mendampingi manajemen saat ada sengketa. "
              "Menjadi penghubung dengan konsultan hukum eksternal bila perkara masuk pengadilan.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")],
         dwa=["4.A.4.b.6.h.1", "4.A.3.b.6.n.9", "4.A.1.a.1.e.2", "4.A.2.a.4.h.1", "4.A.4.a.7.b.10",
              "4.A.3.b.6.n.6", "4.A.1.a.1.e.1", "4.A.4.a.2.j.2"],
         catatan="DNA dan hard skill memakai O*NET Lawyers (23-1011.00), dipilih yang relevan dengan hukum korporasi."),
    dict(nama="Paralegal", en="Paralegals and Legal Assistants", alt="Legal Assistant;Asisten Hukum", soc="23-2011.00",
         rank=6, rumpun="SOC_23_20", lisensi=[],
         sub=[("LEG_FIRMA", True), ("LEG_COMPLIANCE", False)],
         desk="Membantu advokat atau tim legal menyiapkan perkara: meriset peraturan dan putusan, menyusun "
              "draf dokumen hukum, mengelola berkas perkara, serta mewawancarai klien dan saksi. Banyak bekerja "
              "di firma hukum, lembaga bantuan hukum, dan divisi legal perusahaan.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")]),
    dict(nama="Panitera Pengadilan", en="Court Clerks", alt="Panitera Pengganti;Court Clerk", soc="43-4031.00",
         rank=6, rumpun="SOC_23_20", lisensi=[],
         sub=[("LEG_PERADILAN", True), ("GOV_PENEGAKAN", False)],
         desk="Mendampingi hakim di persidangan dan mencatat jalannya sidang dalam berita acara. Mengelola "
              "berkas perkara, jadwal sidang, dan administrasi putusan agar proses peradilan tertib dan "
              "terdokumentasi. Direkrut sebagai ASN di lingkungan Mahkamah Agung.",
         edu=[("PRODI", P["HUKUM"], 100)], jalur=[S1("Ilmu Hukum")]),
    dict(nama="Analis Kebijakan Publik", en="Policy Analysts", alt="Policy Analyst;Analis Kebijakan", soc="19-3094.00",
         rank=6, rumpun="SOC_19_30", lisensi=["ANALIS_KEBIJAKAN"],
         sub=[("LEG_KEBIJAKAN", True), ("GOV_KEMENTERIAN", False)],
         desk="Meneliti masalah publik, mengkaji dampak peraturan, dan menyusun rekomendasi kebijakan untuk "
              "kementerian, lembaga, DPR, pemerintah daerah, atau lembaga riset. Mengolah data, menulis "
              "naskah akademik dan policy brief, serta mempresentasikannya kepada pengambil keputusan.",
         edu=[("PRODI", P["ADM_PUBLIK"], 100), ("PRODI", P["PEMERINTAHAN"], 90), ("PRODI", P["POLITIK"], 90),
              ("PRODI", P["HUKUM"], 60)],
         jalur=[S1("Administrasi Publik")]),

    # ── Keamanan & Pertahanan ────────────────────────────────────────────
    dict(nama="Polisi", en="Police Officers", alt="Anggota Polri;Bintara Polri;Police Officer", soc="33-3051.00",
         rank=2, rumpun="SOC_33_30", lisensi=[],
         sub=[("GOV_PENEGAKAN", True), ("DEF_KEAMANAN", False)],
         desk="Anggota Polri yang menjaga keamanan dan ketertiban masyarakat, menegakkan hukum, serta "
              "melindungi dan melayani warga. Tugasnya meliputi patroli, penanganan laporan dan kecelakaan, "
              "penyelidikan tindak pidana, dan pengamanan kegiatan masyarakat. Masuk lewat pendidikan Bintara "
              "(lulusan SMA/SMK) atau Akademi Kepolisian.",
         edu=[("PRODI", P["KEPOLISIAN"], 100), ("PRODI", P["HUKUM"], 60)],
         jalur=[("VOKASI", "SMA", "SMA/SMK lalu Pendidikan Bintara Polri"),
                ("AKADEMIK", "D4", "Sarjana Terapan Kepolisian (Akpol)")]),
    dict(nama="Prajurit TNI", en="Military Personnel", alt="Tentara;Anggota TNI;Bintara TNI", soc="33-3051.00",
         rank=2, rumpun="SOC_33_30", lisensi=[],
         sub=[("DEF_MILITER", True)],
         desk="Anggota TNI Angkatan Darat, Laut, atau Udara yang bertugas menjaga kedaulatan negara. "
              "Menjalani latihan fisik dan taktik, mengoperasikan peralatan militer, berjaga di wilayah "
              "perbatasan, dan membantu penanganan bencana. Masuk lewat pendidikan Tamtama, Bintara, atau "
              "Akademi Militer.",
         edu=[("PRODI", P["MILITER"], 100)],
         jalur=[("VOKASI", "SMA", "SMA/SMK lalu Pendidikan Bintara TNI"),
                ("AKADEMIK", "D4", "Sarjana Terapan Pertahanan (Akademi Militer)")],
         dwa=["4.A.3.a.1.k.5", "4.A.4.a.5.e.2", "4.A.4.a.5.g.2", "4.A.1.a.2.g.7", "4.A.3.b.6.b.6",
              "4.A.4.a.2.g.6", "4.A.1.a.2.g.5", "4.A.3.a.1.k.12"],
         catatan="O*NET tidak memuat okupasi militer; DNA dan hard skill meminjam Police Officers (33-3051.00)."),
    dict(nama="Petugas Pemadam Kebakaran", en="Firefighters", alt="Firefighter;Damkar", soc="33-2011.00",
         rank=2, rumpun="SOC_33_20", lisensi=["BNSP"],
         sub=[("DEF_KEAMANAN", True), ("GOV_PEMDA", False)],
         desk="Memadamkan kebakaran, menyelamatkan korban, dan menangani keadaan darurat lain seperti "
              "evakuasi, banjir, atau hewan berbahaya. Merawat peralatan pemadam, berlatih rutin, dan "
              "memberi edukasi pencegahan kebakaran kepada warga. Umumnya bertugas di Dinas Pemadam Kebakaran "
              "pemerintah daerah atau tim tanggap darurat industri.",
         edu=[], jalur=[("VOKASI", "SMA", "SMA/SMK lalu Diklat Pemadam Kebakaran")]),
    dict(nama="Satpam / Security Officer", en="Security Guards", alt="Satuan Pengamanan;Security Guard", soc="33-9032.00",
         rank=2, rumpun="SOC_33_90", lisensi=["GADA"],
         sub=[("DEF_KEAMANAN", True)],
         desk="Menjaga keamanan gedung, kawasan, atau acara: mengatur akses keluar-masuk, berpatroli, "
              "memantau CCTV dan alarm, serta menangani kejadian darurat sebelum aparat datang. Wajib memiliki "
              "sertifikat Gada Pratama dari Polri.",
         edu=[], jalur=[("VOKASI", "SMA", "SMA/SMK lalu Pelatihan Gada Pratama")]),
    dict(nama="Supervisor Keamanan", en="First-Line Supervisors of Security Workers",
         alt="Chief Security;Security Supervisor;Komandan Regu", soc="33-1091.00",
         rank=2, rumpun="SOC_33_90", lisensi=["GADA"],
         sub=[("DEF_KEAMANAN", True)],
         desk="Memimpin regu satpam di satu kawasan: menyusun jadwal jaga, memastikan prosedur pengamanan "
              "dijalankan, memeriksa laporan kejadian, dan berkoordinasi dengan manajemen gedung serta polisi. "
              "Biasanya naik dari satpam berpengalaman dengan sertifikat Gada Madya.",
         edu=[], jalur=[("VOKASI", "SMA", "SMA/SMK lalu Pelatihan Gada Pratama dan Madya")]),

    # ── Hospitality & Pariwisata ─────────────────────────────────────────
    dict(nama="Front Office / Resepsionis Hotel", en="Hotel, Motel, and Resort Desk Clerks",
         alt="Front Desk Agent;Receptionist Hotel", soc="43-4081.00", rank=2, rumpun="SOC_43_40",
         lisensi=["PARIWISATA"], sub=[("HOS_HOTEL", True)],
         desk="Menyambut tamu hotel, mengurus check-in dan check-out, mengelola reservasi kamar, serta "
              "menjawab pertanyaan dan keluhan tamu. Menjadi wajah pertama hotel, sehingga butuh komunikasi "
              "yang ramah dan bahasa Inggris yang baik.",
         edu=[("SMK", K["PERHOTELAN"], 100), ("PRODI", P["PARIWISATA"], 90), ("SMK", K["ULW"], 70)],
         jalur=[SMK("Perhotelan"), D3("Perhotelan")]),
    dict(nama="Room Attendant / Housekeeping", en="Maids and Housekeeping Cleaners",
         alt="Housekeeper;Room Boy;Room Maid", soc="37-2012.00", rank=2, rumpun="SOC_37_20",
         lisensi=["PARIWISATA"], sub=[("HOS_HOTEL", True)],
         desk="Menyiapkan dan merapikan kamar tamu sesuai standar hotel: membersihkan, mengganti linen, "
              "mengisi ulang perlengkapan, dan melaporkan kerusakan. Bekerja teliti dan cepat karena kamar "
              "harus siap sebelum tamu berikutnya datang.",
         edu=[("SMK", K["PERHOTELAN"], 100)], jalur=[SMK("Perhotelan")]),
    dict(nama="Concierge", en="Concierges", alt="Guest Relations;Bell Captain", soc="39-6012.00",
         rank=2, rumpun="SOC_39_60", lisensi=["PARIWISATA"], sub=[("HOS_HOTEL", True), ("HOS_TRAVEL", False)],
         desk="Membantu kebutuhan tamu hotel di luar kamar: memesankan restoran, transportasi, tiket, dan tur, "
              "memberi rekomendasi tempat wisata, serta menangani permintaan khusus. Butuh pengetahuan kota "
              "yang luas dan kemampuan melayani dengan ramah.",
         edu=[("SMK", K["PERHOTELAN"], 100), ("PRODI", P["PARIWISATA"], 90)],
         jalur=[SMK("Perhotelan"), D3("Perhotelan")]),
    dict(nama="Manajer Hotel", en="Lodging Managers", alt="Hotel Manager;General Manager Hotel", soc="11-9081.00",
         rank=6, rumpun="SOC_11_90", lisensi=["PARIWISATA"], sub=[("HOS_HOTEL", True)],
         desk="Memimpin operasional hotel atau resort: menetapkan target okupansi dan pendapatan, mengelola "
              "anggaran, mengawasi kepala departemen (front office, housekeeping, F&B), dan menjaga kepuasan "
              "tamu. Biasanya dicapai setelah bertahun-tahun meniti karier di berbagai departemen hotel.",
         edu=[("PRODI", P["PARIWISATA"], 100), ("PRODI", P["MANAJEMEN_OPS"], 70)],
         jalur=[D3("Perhotelan"), S1("Pariwisata")]),
    dict(nama="Chef", en="Chefs and Head Cooks", alt="Head Chef;Kepala Juru Masak;Executive Chef", soc="35-1011.00",
         rank=2, rumpun="SOC_35_10", lisensi=["HIGIENE", "HACCP"],
         sub=[("FNB_RESTORAN", True), ("HOS_HOTEL", False), ("FNB_KATERING", False)],
         desk="Memimpin dapur restoran, hotel, atau katering: merancang menu, menetapkan resep dan standar "
              "rasa, menghitung biaya bahan, serta mengatur dan melatih tim juru masak. Menjaga kebersihan dan "
              "keamanan pangan di setiap tahap pengolahan.",
         edu=[("SMK", K["KULINER"], 100), ("PRODI", P["TATA_BOGA"], 100), ("PRODI", P["PARIWISATA"], 50)],
         jalur=[SMK("Kuliner"), D3("Seni Kuliner")]),
    dict(nama="Pemandu Wisata (Tour Guide)", en="Tour Guides and Escorts", alt="Tour Guide;Pramuwisata",
         soc="39-7011.00", rank=2, rumpun="SOC_39_70", lisensi=["PRAMUWISATA"], sub=[("HOS_TRAVEL", True)],
         desk="Memandu wisatawan di objek wisata, museum, atau kota: menjelaskan sejarah dan budaya, "
              "mengatur jalannya kunjungan, dan memastikan rombongan aman serta nyaman. Pemandu wisatawan "
              "asing butuh bahasa asing yang fasih dan lisensi pramuwisata.",
         edu=[("SMK", K["ULW"], 100), ("PRODI", P["PARIWISATA"], 100), ("SMK", K["EKOWISATA"], 80),
              ("PRODI", P["KONSERVASI_EKOWISATA"], 60)],
         jalur=[SMK("Usaha Layanan Wisata"), ("VOKASI", "D3", "Diploma (D3) Usaha Perjalanan Wisata")]),
    dict(nama="Tour Leader", en="Travel Guides", alt="Tour Leader;Tour Manager", soc="39-7012.00",
         rank=5, rumpun="SOC_39_70", lisensi=["PARIWISATA"], sub=[("HOS_TRAVEL", True)],
         desk="Mendampingi rombongan wisata selama perjalanan, termasuk ke luar negeri: mengatur jadwal, "
              "check-in hotel dan penerbangan, berkoordinasi dengan pemandu lokal, serta menangani masalah di "
              "perjalanan. Biasanya bekerja untuk biro perjalanan atau penyelenggara umrah dan haji.",
         edu=[("PRODI", P["PARIWISATA"], 100), ("SMK", K["ULW"], 90)],
         jalur=[("VOKASI", "D3", "Diploma (D3) Usaha Perjalanan Wisata"), S1("Pariwisata")]),

    # ── NGO & Sosial ─────────────────────────────────────────────────────
    dict(nama="Pekerja Sosial", en="Social Workers", alt="Social Worker;Peksos", soc="21-1021.00",
         rank=6, rumpun="SOC_21_10", lisensi=["PEKSOS"],
         sub=[("NGO_LEMBAGA", True), ("NGO_MASYARAKAT", False), ("NGO_KEMANUSIAAN", False)],
         desk="Mendampingi orang atau keluarga yang menghadapi masalah sosial, misalnya kemiskinan, "
              "kekerasan, disabilitas, anak telantar, atau korban bencana. Menilai kebutuhan klien, "
              "menghubungkannya dengan layanan dan bantuan, lalu memantau perkembangannya. Bekerja di "
              "Kementerian/Dinas Sosial, rumah sakit, panti, dan lembaga sosial.",
         edu=[("PRODI", P["KESOS"], 100), ("PRODI", P["PEMBANGUNAN_SOSIAL"], 90), ("SMK", K["PEKSOS"], 70)],
         jalur=[S1("Ilmu Kesejahteraan Sosial")]),
    dict(nama="Fasilitator Pemberdayaan Masyarakat", en="Community Development Facilitators",
         alt="Pendamping Desa;Community Organizer;Fasilitator Program", soc="21-1093.00",
         rank=6, rumpun="SOC_21_10", lisensi=[],
         sub=[("NGO_MASYARAKAT", True), ("GOV_PEMDA", False)],
         desk="Mendampingi warga desa atau komunitas merencanakan dan menjalankan program bersama, misalnya "
              "usaha ekonomi, air bersih, atau kesehatan. Memfasilitasi musyawarah, melatih kader, dan "
              "melaporkan perkembangan program kepada pemerintah atau lembaga donor.",
         edu=[("PRODI", P["PENGEMBANGAN_MASY"], 100), ("PRODI", P["PEMBANGUNAN_SOSIAL"], 90),
              ("PRODI", P["KESOS"], 80)],
         jalur=[S1("Ilmu Kesejahteraan Sosial")]),
    dict(nama="Manajer Program NGO", en="Social and Community Service Managers",
         alt="Program Manager NGO;Koordinator Program", soc="11-9151.00",
         rank=6, rumpun="SOC_11_90", lisensi=[],
         sub=[("NGO_LEMBAGA", True), ("NGO_KEMANUSIAAN", False), ("NGO_MASYARAKAT", False)],
         desk="Memimpin program sosial atau kemanusiaan di lembaga swadaya masyarakat: menyusun proposal "
              "dan anggaran, mengelola tim lapangan, memantau capaian program, dan melapor kepada donor. "
              "Butuh kemampuan manajemen proyek sekaligus kepekaan terhadap masyarakat yang dilayani.",
         edu=[("PRODI", P["KESOS"], 80), ("PRODI", P["PEMBANGUNAN_SOSIAL"], 80), ("PRODI", P["ADM_PUBLIK"], 70),
              ("PRODI", P["KOMUNIKASI"], 60)],
         jalur=[S1("Ilmu Kesejahteraan Sosial")]),

    # ── Lingkungan & Keberlanjutan ───────────────────────────────────────
    dict(nama="Environmental Engineer", en="Environmental Engineers", alt="Insinyur Lingkungan;Ahli Teknik Lingkungan",
         soc="17-2081.00", rank=6, rumpun="SOC_17_20", lisensi=["IP_PII", "AMDAL"],
         sub=[("SUS_LIMBAH", True), ("SUS_ESG", False)],
         desk="Merancang dan mengawasi sistem pengelolaan limbah cair, padat, dan B3, pengolahan air bersih, "
              "serta pengendalian pencemaran udara. Menyusun kajian lingkungan, memastikan fasilitas memenuhi "
              "baku mutu, dan mencari cara mengurangi dampak lingkungan sebuah proyek atau pabrik.",
         edu=[("PRODI", P["TEKNIK_LINGKUNGAN"], 100), ("PRODI", P["INFRA_LINGKUNGAN"], 90),
              ("PRODI", P["TEKNIK_KIMIA"], 60), ("PRODI", P["KESLING"], 60)],
         jalur=[S1("Teknik Lingkungan")]),
    dict(nama="Analis Laboratorium Lingkungan", en="Environmental Science and Protection Technicians",
         alt="Teknisi Lingkungan;Environmental Technician", soc="19-4042.00", rank=5, rumpun="SOC_19_40",
         lisensi=["BNSP"], sub=[("SUS_LIMBAH", True), ("SUS_ESG", False)],
         desk="Mengambil sampel air, udara, tanah, dan limbah di lapangan lalu mengujinya di laboratorium "
              "untuk memastikan memenuhi baku mutu. Mencatat hasil uji, merawat alat ukur, dan menyiapkan "
              "data untuk laporan pemantauan lingkungan perusahaan atau instansi.",
         edu=[("SMK", K["KIMIA_ANALISIS"], 100), ("PRODI", P["KESLING"], 90), ("PRODI", P["TEKNIK_LINGKUNGAN"], 90),
              ("PRODI", P["KIMIA"], 70)],
         jalur=[SMK("Kimia Analisis"), D3("Analis Kimia")]),
    dict(nama="Konsultan Lingkungan (AMDAL)", en="Environmental Scientists and Specialists",
         alt="Environmental Consultant;Penyusun AMDAL;Environmental Specialist", soc="19-2041.00",
         rank=6, rumpun="SOC_19_20", lisensi=["AMDAL"],
         sub=[("SUS_ESG", True), ("SUS_KONSERVASI", False), ("SUS_LIMBAH", False)],
         desk="Mengkaji dampak lingkungan sebuah proyek atau usaha dan menyusun dokumen AMDAL, UKL-UPL, atau "
              "laporan keberlanjutan (ESG). Meneliti data lapangan, merancang rencana pengelolaan dan "
              "pemantauan, lalu mendampingi klien hingga izin lingkungan terbit.",
         edu=[("PRODI", P["SDA_LINGKUNGAN"], 100), ("PRODI", P["TEKNIK_LINGKUNGAN"], 90),
              ("PRODI", P["BIOLOGI"], 70), ("PRODI", P["EKONOMI_SDA"], 70), ("PRODI", P["KEHUTANAN"], 60)],
         jalur=[S1("Teknik Lingkungan")]),

    # ── Telekomunikasi ───────────────────────────────────────────────────
    dict(nama="Teknisi Fiber Optik", en="Telecommunications Line Installers and Repairers",
         alt="FTTH Technician;Teknisi Jaringan Akses", soc="49-9052.00", rank=2, rumpun="SOC_49_90",
         lisensi=["K3_KETINGGIAN"], sub=[("TEL_ISP", True), ("TEL_FIBER", False)],
         desk="Memasang, menyambung, dan memperbaiki kabel fiber optik dan jaringan internet rumah (FTTH) "
              "maupun backbone. Menarik kabel di tiang, melakukan splicing, mengukur kualitas sinyal, dan "
              "menangani gangguan pelanggan ISP.",
         edu=[("SMK", K["TJAT"], 100), ("SMK", K["TTT"], 90), ("SMK", K["TKJ"], 70), ("PRODI", P["TEKNIK_TELKOM"], 80)],
         jalur=[SMK("Teknik Jaringan Akses Telekomunikasi"), D3("Teknik Telekomunikasi")]),
    dict(nama="Teknisi BTS & Perangkat Telekomunikasi", en="Telecommunications Equipment Installers and Repairers",
         alt="Teknisi BTS;Telecom Technician;Rigger", soc="49-2022.00", rank=5, rumpun="SOC_49_20",
         lisensi=["K3_KETINGGIAN", "BNSP"], sub=[("TEL_SELULER", True), ("TEL_ISP", False)],
         desk="Memasang, menguji, dan merawat perangkat telekomunikasi di menara BTS, ruang server, dan "
              "sentral operator: antena, radio, perangkat transmisi, dan catu daya. Menangani gangguan "
              "jaringan seluler agar layanan tetap tersambung.",
         edu=[("PRODI", P["TEKNIK_TELKOM"], 100), ("SMK", K["TTT"], 100), ("SMK", K["ELKOM"], 90),
              ("PRODI", P["TEKNIK_ELEKTRO"], 70)],
         jalur=[SMK("Teknik Transmisi Telekomunikasi"), D3("Teknik Telekomunikasi")]),
]

# Profesi lama yang ditambahkan ke sub-industri tipis (bukan utama).
TAMBAHAN_SUB = [
    ("Network Support Specialist", "TEL_ISP"),
]

SUB_BARU = [("LEG_PERADILAN", "LEGAL", "Peradilan & Kejaksaan", 88)]

RUMPUN_BARU = {
    # kode: (nama, deskripsi, rank_min, rank_max, perlu_lisensi)
    "SOC_23_10": ("Profesi Hukum", "Advokat, notaris, jaksa, hakim, dan legal perusahaan: profesi yang menafsirkan dan menerapkan hukum. Jenjang minimal S1 Hukum, sebagian wajib pendidikan profesi.", 6, 7, True),
    "SOC_23_20": ("Pendukung Hukum & Peradilan", "Membantu advokat dan pengadilan menyiapkan perkara: riset, berkas, dan berita acara. Jenjangnya S1.", 6, 6, False),
    "SOC_19_30": ("Analis Sosial & Kebijakan", "Meneliti masalah sosial dan publik untuk menyusun rekomendasi kebijakan. Jenjangnya S1.", 6, 6, False),
    "SOC_33_30": ("Kepolisian & Militer", "Menjaga keamanan masyarakat dan kedaulatan negara. Masuk lewat pendidikan pembentukan setelah SMA/SMK atau akademi.", 2, 6, False),
    "SOC_33_20": ("Pemadam Kebakaran & Penyelamatan", "Menangani kebakaran dan keadaan darurat serta menyelamatkan korban. Terbuka untuk lulusan SMA/SMK.", 2, 2, True),
    "SOC_33_90": ("Jasa Keamanan", "Menjaga keamanan gedung, kawasan, dan acara. Terbuka untuk lulusan SMA/SMK dengan sertifikat Gada.", 2, 2, True),
    "SOC_37_20": ("Tata Graha & Kebersihan", "Menjaga kamar dan area hotel atau gedung tetap bersih dan siap pakai. Terbuka untuk lulusan SMA/SMK.", 2, 2, False),
    "SOC_39_60": ("Layanan Tamu Hotel", "Melayani kebutuhan tamu di luar urusan kamar: informasi, pemesanan, dan permintaan khusus.", 2, 2, False),
    "SOC_39_70": ("Pemandu & Pemimpin Perjalanan", "Memandu dan mendampingi wisatawan selama kunjungan atau perjalanan. Jenjangnya SMA/SMK sampai D3.", 2, 5, True),
    "SOC_35_10": ("Kepala Dapur", "Memimpin dapur: menu, resep, biaya bahan, dan tim juru masak.", 2, 2, False),
    "SOC_21_10": ("Pekerjaan Sosial & Pemberdayaan", "Mendampingi orang dan komunitas yang menghadapi masalah sosial. Jenjangnya S1.", 6, 6, False),
    "SOC_11_90": ("Manajer Layanan", "Memimpin operasional unit layanan seperti hotel atau lembaga sosial. Jenjangnya S1.", 6, 6, False),
}

# Kemampuan domain per rumpun SOC dua digit yang belum punya (lihat 0015).
DOMAIN_BARU = {"HUKUM": "Hukum", "KEAMANAN": "Keamanan & Keselamatan", "SOSIAL": "Layanan Sosial"}
HARD_SKILL_DOMAIN = {
    "21": [("ASESMEN_SOSIAL", "Asesmen Kebutuhan & Kondisi Klien", "SOSIAL"),
           ("PENDAMPINGAN_KASUS", "Manajemen Kasus & Pendampingan", "SOSIAL"),
           ("FASILITASI_KELOMPOK", "Fasilitasi Diskusi & Kelompok Warga", "SOSIAL"),
           ("RUJUKAN_LAYANAN", "Rujukan & Jejaring Layanan", "SOSIAL"),
           ("PELAPORAN_PROGRAM", "Pencatatan & Pelaporan Program", "SOSIAL")],
    "23": [("RISET_HUKUM", "Riset Peraturan & Yurisprudensi", "HUKUM"),
           ("DRAFTING_HUKUM", "Penyusunan Dokumen Hukum (Legal Drafting)", "HUKUM"),
           ("ANALISIS_PERKARA", "Analisis Kasus & Argumentasi Hukum", "HUKUM"),
           ("HUKUM_ACARA", "Hukum Acara & Praktik Persidangan", "HUKUM"),
           ("ETIKA_PROFESI_HUKUM", "Kode Etik & Kerahasiaan Profesi", "HUKUM")],
    "33": [("PATROLI_PENGAMANAN", "Patroli & Pengamanan Area", "KEAMANAN"),
           ("TANGGAP_DARURAT", "Tanggap Darurat & Pertolongan Pertama", "KEAMANAN"),
           ("LAPORAN_KEJADIAN", "Penyusunan Laporan Kejadian", "KEAMANAN"),
           ("KOMUNIKASI_RADIO", "Komunikasi Radio & Koordinasi Lapangan", "KEAMANAN"),
           ("PENGENDALIAN_SITUASI", "Bela Diri & Pengendalian Situasi", "KEAMANAN")],
    "35": [("HIGIENE_PANGAN", "Higiene & Keamanan Pangan (HACCP)", "LAYANAN"),
           ("TEKNIK_MASAK", "Teknik Memasak & Pengolahan Bahan", "LAYANAN"),
           ("MENU_COSTING", "Perencanaan Menu & Food Costing", "LAYANAN"),
           ("MANAJEMEN_DAPUR", "Manajemen Dapur & Brigade", "LAYANAN")],
    "37": [("STANDAR_HOUSEKEEPING", "Standar Kebersihan Kamar & Area Publik", "LAYANAN"),
           ("BAHAN_PEMBERSIH", "Penggunaan Bahan & Alat Pembersih", "LAYANAN"),
           ("LAYANAN_TAMU", None, None), ("HIGIENE_ALAT", None, None)],
}

ISSUER_BARU = {
    "ORG_ADVOKAT": "Organisasi Advokat (PERADI dan organisasi advokat lain yang diakui)",
    "KEMENKUM": "Kementerian Hukum Republik Indonesia",
    "KEJAKSAAN": "Kejaksaan Agung Republik Indonesia",
    "MA": "Mahkamah Agung Republik Indonesia",
    "KEMENSOS": "Kementerian Sosial (Lembaga Sertifikasi Pekerjaan Sosial)",
    "KLH": "Kementerian Lingkungan Hidup / LSK Penyusun AMDAL",
    "LAN": "Lembaga Administrasi Negara (LAN)",
}
LISENSI_BARU = [
    # kode, nama, penerbit, sifat, deskripsi, judul langkah (WAJIB)
    ("PKPA_UPA", "PKPA, Ujian Profesi Advokat, dan Sumpah Advokat", "ORG_ADVOKAT", "WAJIB",
     "Pendidikan Khusus Profesi Advokat, lulus ujian profesi, magang 2 tahun di kantor advokat, lalu disumpah di Pengadilan Tinggi (UU 18/2003).",
     "PKPA, Ujian Profesi, dan Sumpah Advokat"),
    ("NOTARIS", "Magister Kenotariatan dan SK Pengangkatan Notaris", "KEMENKUM", "WAJIB",
     "Lulus Magister Kenotariatan, magang di kantor notaris, ujian kode etik, lalu diangkat Menteri Hukum (UU 2/2014).",
     "Magister Kenotariatan dan Pengangkatan Notaris"),
    ("PPPJ", "Pendidikan dan Pelatihan Pembentukan Jaksa (PPPJ)", "KEJAKSAAN", "WAJIB",
     "Pendidikan wajib bagi CPNS Kejaksaan berlatar S1 Hukum sebelum diangkat sebagai jaksa.",
     "Pendidikan Pembentukan Jaksa (PPPJ)"),
    ("PPC_HAKIM", "Pendidikan dan Pelatihan Calon Hakim (PPC) Terpadu", "MA", "WAJIB",
     "Pendidikan calon hakim selama sekitar dua tahun setelah lulus seleksi calon hakim Mahkamah Agung.",
     "Pendidikan Calon Hakim Terpadu"),
    ("GADA", "Sertifikat Satpam Gada Pratama / Madya / Utama", "POLRI", "WAJIB",
     "Pelatihan dasar dan lanjutan satuan pengamanan yang diselenggarakan bersama Polri (Perpol 4/2020).",
     "Pelatihan dan Sertifikat Gada Pratama"),
    ("PRAMUWISATA", "Lisensi / Sertifikat Kompetensi Pramuwisata", "PEMDA", "PROFESI",
     "Lisensi pemandu wisata dari dinas pariwisata daerah, didukung sertifikat kompetensi BNSP bidang kepemanduan.",
     None),
    ("PEKSOS", "Sertifikat Kompetensi Pekerja Sosial", "KEMENSOS", "PROFESI",
     "Sertifikasi pekerja sosial profesional dan tenaga kesejahteraan sosial sesuai UU 14/2019 tentang Pekerja Sosial.",
     None),
    ("AMDAL", "Sertifikat Kompetensi Penyusun AMDAL (Ketua/Anggota Tim)", "KLH", "PROFESI",
     "Syarat menjadi penyusun dokumen AMDAL; diterbitkan lembaga sertifikasi kompetensi yang ditunjuk kementerian lingkungan.",
     None),
    ("K3_KETINGGIAN", "Sertifikat K3 Bekerja di Ketinggian", "KEMNAKER", "WAJIB",
     "Wajib bagi pekerja yang memanjat tiang atau menara, sesuai Permenaker 9/2016.",
     "Sertifikat K3 Bekerja di Ketinggian"),
    ("ANALIS_KEBIJAKAN", "Sertifikat Kompetensi Analis Kebijakan", "LAN", "TAMBAHAN",
     "Uji kompetensi jabatan fungsional Analis Kebijakan bagi ASN; menambah bobot bagi analis di luar pemerintahan.",
     None),
]
