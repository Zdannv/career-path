-- ============================================================================
-- 0007_roadmap_data.sql
--
-- Mengisi roadmap untuk seluruh profesi aktif.
--
-- Sumber:
--   * Intermediate Work Activities O*NET 30.3  -> nama capaian (milestone)
--   * Task Ratings (Importance)                -> urutan capaian
--   * Education (Required Level of Education)  -> jenjang target
--   * Training and Experience (RW, OJ)         -> lama fase pengalaman
--   * Software Skills (In Demand)              -> alat kerja yang dipelajari
--   * Related Occupations (Primary-Short)      -> fase pengembangan karier
--   O*NET 30.3, CC BY 4.0.
--
-- Teks Indonesianya dirakit di sini, bukan disimpan baris per baris: yang
-- tersimpan hanya kosakata capaian dan masukan per profesi, sisanya dibentuk
-- oleh fungsi _rm_generate() di bawah. Itu sebabnya file ini ratusan kilobyte,
-- bukan belasan megabyte, dan kenapa memperbaiki satu pola kalimat cukup
-- disunting di satu tempat lalu dijalankan ulang.
--
-- Jalankan setelah 0006. Aman diulang: seluruh isi roadmap dihapus dan
-- dibangun ulang setiap kali. Progres pengguna tidak ikut terhapus selama
-- id aktivitas tidak berubah — lihat catatan di bagian 5.
-- ============================================================================

begin;

set local statement_timeout = '10min';

-- ---------------------------------------------------------------------------
-- 1. Kosakata capaian (311 IWA yang dipakai profesi kita)
-- ---------------------------------------------------------------------------
insert into public.roadmap_skill_areas (code, gwa_code, name_id, name_en) values
  ('4.A.1.a.1.a','4.A.1.a.1','Menelaah detail produksi karya seni','Study details of artistic productions.'),
  ('4.A.1.a.1.b','4.A.1.a.1','Membaca dokumen kerja untuk memahami proses','Read documents or materials to inform work processes.'),
  ('4.A.1.a.1.c','4.A.1.a.1','Menyelidiki perkara hukum atau kriminal','Investigate criminal or legal matters.'),
  ('4.A.1.a.1.d','4.A.1.a.1','Mengumpulkan informasi dari sumber fisik maupun digital','Gather information from physical or electronic sources.'),
  ('4.A.1.a.1.e','4.A.1.a.1','Menelusuri dokumen hukum atau catatan publik','Consult legal materials or public records.'),
  ('4.A.1.a.1.f','4.A.1.a.1','Mengumpulkan data kegiatan operasional atau pengembangan','Gather data about operational or development activities.'),
  ('4.A.1.a.1.g','4.A.1.a.1','Mencari informasi tentang barang atau jasa','Obtain information about goods or services.'),
  ('4.A.1.a.1.h','4.A.1.a.1','Meneliti isu ilmu kebumian','Research issues related to earth sciences.'),
  ('4.A.1.a.1.i','4.A.1.a.1','Meneliti perilaku, proses, atau kinerja organisasi','Research organizational behavior, processes, or performance.'),
  ('4.A.1.a.1.j','4.A.1.a.1','Menelaah dampak lingkungan dari kegiatan industri atau pembangunan','Investigate the environmental impact of industrial or development activities.'),
  ('4.A.1.a.1.k','4.A.1.a.1','Mengumpulkan bahan untuk berita','Gather information for news stories.'),
  ('4.A.1.a.1.l','4.A.1.a.1','Menghimpun informasi pasien atau klien','Collect information about patients or clients.'),
  ('4.A.1.a.1.n','4.A.1.a.1','Menggali kebutuhan dan pendapat konsumen','Collect data about consumer needs or opinions.'),
  ('4.A.1.a.1.p','4.A.1.a.1','Meneliti fenomena biologi atau ekologi','Research biological or ecological phenomena.'),
  ('4.A.1.a.1.q','4.A.1.a.1','Mengurus dokumen atau izin resmi','Obtain formal documentation or authorization.'),
  ('4.A.1.a.1.r','4.A.1.a.1','Meneliti isu sejarah atau sosial','Research historical or social issues.'),
  ('4.A.1.a.1.s','4.A.1.a.1','Meneliti isu kesehatan','Research healthcare issues.'),
  ('4.A.1.a.1.t','4.A.1.a.1','Meneliti rancangan atau penerapan teknologi','Research technology designs or applications.'),
  ('4.A.1.a.1.u','4.A.1.a.1','Menyelidiki insiden atau kecelakaan','Investigate incidents or accidents.'),
  ('4.A.1.a.1.v','4.A.1.a.1','Menyelidiki masalah organisasi atau operasional','Investigate organizational or operational problems.'),
  ('4.A.1.a.1.w','4.A.1.a.1','Mewawancarai orang untuk menggali informasi','Interview people to obtain information.'),
  ('4.A.1.a.2.a','4.A.1.a.2','Memantau jalannya peralatan','Monitor equipment operation.'),
  ('4.A.1.a.2.b','4.A.1.a.2','Memantau operasional agar kinerjanya tetap memadai','Monitor operations to ensure adequate performance.'),
  ('4.A.1.a.2.c','4.A.1.a.2','Memantau data atau aktivitas keuangan','Monitor financial data or activities.'),
  ('4.A.1.a.2.e','4.A.1.a.2','Memantau kondisi kesehatan manusia atau hewan','Monitor health conditions of humans or animals.'),
  ('4.A.1.a.2.f','4.A.1.a.2','Memantau perilaku atau kinerja individu','Monitor individual behavior or performance.'),
  ('4.A.1.a.2.g','4.A.1.a.2','Memantau keselamatan dan keamanan area kerja','Monitor safety or security of work areas, facilities, or properties.'),
  ('4.A.1.a.2.h','4.A.1.a.2','Memantau tren dan perkembangan di luar organisasi','Monitor external affairs, trends, or events.'),
  ('4.A.1.a.2.i','4.A.1.a.2','Memantau kondisi lingkungan','Monitor environmental conditions.'),
  ('4.A.1.a.2.j','4.A.1.a.2','Memantau jalannya sistem komputer atau teknologi informasi','Monitor operation of computer or information technologies.'),
  ('4.A.1.a.2.k','4.A.1.a.2','Memantau kepatuhan operasional terhadap regulasi atau standar','Monitor operations to ensure compliance with regulations or standards.'),
  ('4.A.1.b.1.a','4.A.1.b.1','Menandai material atau objek untuk identifikasi','Mark materials or objects for identification.'),
  ('4.A.1.b.1.b','4.A.1.b.1','Mengenali peluang bisnis atau organisasi','Identify business or organizational opportunities.'),
  ('4.A.1.b.2.a','4.A.1.b.2','Melakukan tes diagnostik untuk menilai kesehatan pasien','Administer diagnostic tests to assess patient health.'),
  ('4.A.1.b.2.b','4.A.1.b.2','Menilai teknologi atau proses ramah lingkungan','Evaluate green technologies or processes.'),
  ('4.A.1.b.2.c','4.A.1.b.2','Menguji karakteristik material atau produk','Test characteristics of materials or products.'),
  ('4.A.1.b.2.d','4.A.1.b.2','Memeriksa kendaraan','Inspect vehicles.'),
  ('4.A.1.b.2.e','4.A.1.b.2','Memeriksa fasilitas atau peralatan','Inspect facilities or equipment.'),
  ('4.A.1.b.2.f','4.A.1.b.2','Memeriksa hasil kerja atau produk jadi','Inspect completed work or finished products.'),
  ('4.A.1.b.2.g','4.A.1.b.2','Memeriksa sistem atau peralatan produksi dan industri','Inspect commercial, industrial, or production systems or equipment.'),
  ('4.A.1.b.2.h','4.A.1.b.2','Menguji kinerja sistem komputer atau sistem informasi','Test performance of computer or information systems.'),
  ('4.A.1.b.2.i','4.A.1.b.2','Memeriksa manusia atau hewan untuk menilai kondisi fisiknya','Examine people or animals to assess health conditions or physical characteristics.'),
  ('4.A.1.b.2.j','4.A.1.b.2','Memeriksa karakteristik atau kondisi material dan produk','Inspect characteristics or conditions of materials or products.'),
  ('4.A.1.b.2.k','4.A.1.b.2','Menguji lokasi atau material terhadap bahaya lingkungan','Test sites or materials for environmental hazards.'),
  ('4.A.1.b.2.l','4.A.1.b.2','Menguji kinerja peralatan atau sistem','Test performance of equipment or systems.'),
  ('4.A.1.b.3.a','4.A.1.b.3','Mengukur karakteristik fisik material, produk, atau peralatan','Measure physical characteristics of materials, products, or equipment.'),
  ('4.A.1.b.3.b','4.A.1.b.3','Memperkirakan biaya pengembangan atau operasional proyek','Estimate project development or operational costs.'),
  ('4.A.1.b.3.c','4.A.1.b.3','Menghitung data keuangan','Calculate financial data.'),
  ('4.A.1.b.3.d','4.A.1.b.3','Menilai karakteristik lahan atau properti','Assess characteristics of land or property.'),
  ('4.A.1.b.3.e','4.A.1.b.3','Melakukan pengukuran fisik pada pasien atau klien','Take physical measurements of patients or clients.'),
  ('4.A.2.a.1.a','4.A.2.a.1','Menilai kebutuhan hidup, kerja, atau sosial individu dan komunitas','Assess living, work, or social needs or status of individuals or communities.'),
  ('4.A.2.a.1.b','4.A.2.a.1','Mengevaluasi program, praktik, atau proses','Evaluate programs, practices, or processes.'),
  ('4.A.2.a.1.c','4.A.2.a.1','Menilai kemampuan, kebutuhan, dan capaian peserta didik','Assess student capabilities, needs, or performance.'),
  ('4.A.2.a.1.d','4.A.2.a.1','Mengevaluasi kemampuan atau kinerja personel','Evaluate personnel capabilities or performance.'),
  ('4.A.2.a.1.e','4.A.2.a.1','Mengevaluasi masukan dan keluaran produksi','Evaluate production inputs or outputs.'),
  ('4.A.2.a.1.f','4.A.2.a.1','Mengevaluasi kondisi pasien dan pilihan penanganannya','Evaluate patient or client condition or treatment options.'),
  ('4.A.2.a.1.g','4.A.2.a.1','Menilai kegunaan dan kinerja produk atau teknologi','Evaluate the characteristics, usefulness, or performance of products or technologies.'),
  ('4.A.2.a.1.h','4.A.2.a.1','Menelaah karya ilmiah','Evaluate scholarly work.'),
  ('4.A.2.a.1.i','4.A.2.a.1','Menilai kondisi aset keuangan, properti, atau sumber daya lain','Evaluate condition of financial assets, property, or other resources.'),
  ('4.A.2.a.1.j','4.A.2.a.1','Menilai kelayakan proyek','Evaluate project feasibility.'),
  ('4.A.2.a.2.a','4.A.2.a.2','Menilai kualitas dan keakuratan data','Evaluate the quality or accuracy of data.'),
  ('4.A.2.a.2.b','4.A.2.a.2','Menyortir material atau produk','Sort materials or products.'),
  ('4.A.2.a.2.c','4.A.2.a.2','Menghimpun catatan, dokumentasi, dan data','Compile records, documentation, or other data.'),
  ('4.A.2.a.2.d','4.A.2.a.2','Merekonsiliasi data keuangan','Reconcile financial data.'),
  ('4.A.2.a.2.e','4.A.2.a.2','Memverifikasi data pribadi','Verify personal information.'),
  ('4.A.2.a.3.a','4.A.2.a.3','Memeriksa keakuratan dan kepatuhan material atau dokumen','Examine materials or documentation for accuracy or compliance.'),
  ('4.A.2.a.3.b','4.A.2.a.3','Menilai kepatuhan terhadap standar dan regulasi lingkungan','Assess compliance with environmental standards or regulations.'),
  ('4.A.2.a.3.c','4.A.2.a.3','Memeriksa aktivitas, operasi, atau sistem keuangan','Examine financial activities, operations, or systems.'),
  ('4.A.2.a.3.d','4.A.2.a.3','Menjalankan prosedur keselamatan layanan kesehatan','Follow standard healthcare safety procedures to protect patient and staff members.'),
  ('4.A.2.a.4.a','4.A.2.a.4','Menganalisis data lingkungan atau geospasial','Analyze environmental or geospatial data.'),
  ('4.A.2.a.4.b','4.A.2.a.4','Menganalisis kondisi pasar atau industri','Analyze market or industry conditions.'),
  ('4.A.2.a.4.c','4.A.2.a.4','Menganalisis risiko bisnis atau keuangan','Analyze business or financial risks.'),
  ('4.A.2.a.4.d','4.A.2.a.4','Menganalisis data ilmiah dengan prinsip matematika','Analyze scientific or applied data using mathematical principles.'),
  ('4.A.2.a.4.e','4.A.2.a.4','Mengevaluasi rancangan, spesifikasi, dan data teknis','Evaluate designs, specifications, or other technical data.'),
  ('4.A.2.a.4.f','4.A.2.a.4','Menganalisis data kesehatan atau medis','Analyze health or medical data.'),
  ('4.A.2.a.4.g','4.A.2.a.4','Menganalisis data untuk memperbaiki operasional','Analyze data to improve operations.'),
  ('4.A.2.a.4.i','4.A.2.a.4','Menilai karakteristik dan dampak regulasi atau kebijakan','Assess characteristics or impacts of regulations or policies.'),
  ('4.A.2.a.4.j','4.A.2.a.4','Menganalisis zat biologi, zat kimia, dan datanya','Analyze biological or chemical substances or related data.'),
  ('4.A.2.a.4.k','4.A.2.a.4','Menganalisis data bisnis atau keuangan','Analyze business or financial data.'),
  ('4.A.2.a.4.l','4.A.2.a.4','Menganalisis kinerja sistem atau peralatan','Analyze performance of systems or equipment.'),
  ('4.A.2.b.1.a','4.A.2.b.1','Menentukan nilai atau harga barang dan jasa','Determine values or prices of goods or services.'),
  ('4.A.2.b.1.b','4.A.2.b.1','Mendiagnosis masalah sistem atau peralatan','Diagnose system or equipment problems.'),
  ('4.A.2.b.1.c','4.A.2.b.1','Memberi otorisasi kegiatan atau transaksi bisnis','Authorize business activities or transactions.'),
  ('4.A.2.b.1.d','4.A.2.b.1','Menentukan metode atau prosedur kerja','Determine operational methods or procedures.'),
  ('4.A.2.b.1.f','4.A.2.b.1','Mendiagnosis kondisi atau gangguan kesehatan','Diagnose health conditions or disorders.'),
  ('4.A.2.b.1.g','4.A.2.b.1','Menyunting naskah atau dokumen','Edit written materials or documents.'),
  ('4.A.2.b.1.h','4.A.2.b.1','Menentukan kebutuhan sumber daya proyek atau operasional','Determine resource needs of projects or operations.'),
  ('4.A.2.b.1.i','4.A.2.b.1','Menerapkan prosedur atau proses kerja','Implement procedures or processes.'),
  ('4.A.2.b.1.j','4.A.2.b.1','Memilih material atau peralatan untuk proyek dan operasional','Select materials or equipment for operations or projects.'),
  ('4.A.2.b.1.k','4.A.2.b.1','Mengolah rekaman audio atau video','Alter audio or video recordings.'),
  ('4.A.2.b.2.a','4.A.2.b.2','Menyusun rencana perawatan pasien atau klien','Develop patient or client care or treatment plans.'),
  ('4.A.2.b.2.b','4.A.2.b.2','Merancang sistem atau aplikasi komputer','Design computer or information systems or applications.'),
  ('4.A.2.b.2.c','4.A.2.b.2','Menyusun rencana bisnis atau pemasaran','Develop business or marketing plans.'),
  ('4.A.2.b.2.d','4.A.2.b.2','Menyusun resep atau menu','Develop recipes or menus.'),
  ('4.A.2.b.2.e','4.A.2.b.2','Menyusun standar, kebijakan, dan prosedur keselamatan','Develop safety standards, policies, or procedures.'),
  ('4.A.2.b.2.f','4.A.2.b.2','Merancang basis data','Design databases.'),
  ('4.A.2.b.2.g','4.A.2.b.2','Menyusun rencana pengelolaan sumber daya alam','Develop plans for managing or preserving natural resources.'),
  ('4.A.2.b.2.h','4.A.2.b.2','Menyusun rencana keuangan atau bisnis','Develop financial or business plans.'),
  ('4.A.2.b.2.i','4.A.2.b.2','Mengembangkan metode atau program asesmen kesehatan','Develop health assessment methods or programs.'),
  ('4.A.2.b.2.j','4.A.2.b.2','Membuat materi pemasaran atau promosi','Develop marketing or promotional materials.'),
  ('4.A.2.b.2.k','4.A.2.b.2','Merancang material atau perangkat','Design materials or devices.'),
  ('4.A.2.b.2.l','4.A.2.b.2','Menyusun program, rencana, dan prosedur pembelajaran','Develop educational programs, plans, or procedures.'),
  ('4.A.2.b.2.m','4.A.2.b.2','Mengembangkan cara mengatasi masalah lingkungan','Develop systems or practices to mitigate or resolve environmental problems.'),
  ('4.A.2.b.2.n','4.A.2.b.2','Mengembangkan program kesehatan masyarakat','Develop public or community health programs.'),
  ('4.A.2.b.2.o','4.A.2.b.2','Membuat desain atau tampilan visual','Create visual designs or displays.'),
  ('4.A.2.b.2.p','4.A.2.b.2','Menyusun rencana darurat atau kontingensi','Develop contingency or emergency response plans.'),
  ('4.A.2.b.2.q','4.A.2.b.2','Mengembangkan kebijakan organisasi yang berkelanjutan','Develop sustainable organizational or business policies or practices.'),
  ('4.A.2.b.2.r','4.A.2.b.2','Membuat konten berita, hiburan, atau karya seni','Develop news, entertainment, or artistic content.'),
  ('4.A.2.b.2.s','4.A.2.b.2','Menyusun rencana dan metodologi penelitian','Develop research plans or methodologies.'),
  ('4.A.2.b.2.t','4.A.2.b.2','Menciptakan karya desain atau pertunjukan seni','Create artistic designs or performances.'),
  ('4.A.2.b.2.u','4.A.2.b.2','Mengembangkan teori atau model ilmiah dan matematis','Develop scientific or mathematical theories or models.'),
  ('4.A.2.b.2.v','4.A.2.b.2','Merumuskan tujuan dan sasaran organisasi atau program','Develop organizational or program goals or objectives.'),
  ('4.A.2.b.3.a','4.A.2.b.3','Memperbarui pengetahuan di bidang keahliannya','Maintain current knowledge in area of expertise.'),
  ('4.A.2.b.4.a','4.A.2.b.4','Menyusun kebijakan, sistem, dan proses organisasi','Develop organizational policies, systems, or processes.'),
  ('4.A.2.b.5.a','4.A.2.b.5','Menyusun jadwal layanan atau fasilitas','Prepare schedules for services or facilities.'),
  ('4.A.2.b.5.b','4.A.2.b.5','Menjadwalkan kegiatan operasional','Schedule operational activities.'),
  ('4.A.2.b.5.c','4.A.2.b.5','Mengatur jadwal janji temu','Schedule appointments.'),
  ('4.A.2.b.6.a','4.A.2.b.6','Merencanakan acara atau program','Plan events or programs.'),
  ('4.A.2.b.6.b','4.A.2.b.6','Merencanakan aktivitas kerja','Plan work activities.'),
  ('4.A.3.a.1.a','4.A.3.a.1','Membuat campuran atau larutan','Prepare mixtures or solutions.'),
  ('4.A.3.a.1.b','4.A.3.a.1','Melindungi orang dan properti dari ancaman seperti kebakaran atau banjir','Protect people or property from threats such as fires or flooding.'),
  ('4.A.3.a.1.c','4.A.3.a.1','Membersihkan alat, peralatan, fasilitas, dan area kerja','Clean tools, equipment, facilities, or work areas.'),
  ('4.A.3.a.1.d','4.A.3.a.1','Memasang struktur atau penutup pelindung di area kerja','Set up protective structures or coverings near work areas.'),
  ('4.A.3.a.1.e','4.A.3.a.1','Membuang limbah atau puing','Dispose of waste or debris.'),
  ('4.A.3.a.1.f','4.A.3.a.1','Memuat produk, material, atau peralatan untuk diangkut','Load products, materials, or equipment for transportation or further processing.'),
  ('4.A.3.a.1.g','4.A.3.a.1','Melakukan pekerjaan konstruksi atau penggalian umum','Perform general construction or extraction activities.'),
  ('4.A.3.a.1.h','4.A.3.a.1','Membersihkan benda kerja atau produk jadi','Clean workpieces, finished products, or other objects.'),
  ('4.A.3.a.1.i','4.A.3.a.1','Membersihkan peralatan atau fasilitas medis','Clean medical equipment or facilities.'),
  ('4.A.3.a.1.j','4.A.3.a.1','Memindahkan material, peralatan, atau perbekalan','Move materials, equipment, or supplies.'),
  ('4.A.3.a.1.k','4.A.3.a.1','Menjaga keselamatan dan keamanan','Maintain safety or security.'),
  ('4.A.3.a.1.l','4.A.3.a.1','Mengawal atau mendampingi orang','Escort others.'),
  ('4.A.3.a.1.m','4.A.3.a.1','Mengantar pasien atau klien','Transport patients or clients.'),
  ('4.A.3.a.1.n','4.A.3.a.1','Memanjat peralatan atau struktur bangunan','Climb equipment or structures.'),
  ('4.A.3.a.1.p','4.A.3.a.1','Melakukan aktivitas atletik untuk kebugaran, kompetisi, atau seni','Perform athletic activities for fitness, competition, or artistic purposes.'),
  ('4.A.3.a.1.q','4.A.3.a.1','Melakukan kegiatan pertanian','Perform agricultural activities.'),
  ('4.A.3.a.2.a','4.A.3.a.2','Membangun struktur bangunan','Build structures.'),
  ('4.A.3.a.2.aa','4.A.3.a.2','Membuat perangkat atau komponen','Fabricate devices or components.'),
  ('4.A.3.a.2.ab','4.A.3.a.2','Membuat objek atau ornamen dekoratif','Create decorative objects or parts of objects.'),
  ('4.A.3.a.2.ac','4.A.3.a.2','Mengolah karkas hewan','Process animal carcasses.'),
  ('4.A.3.a.2.ad','4.A.3.a.2','Mengebor lubang pada tanah atau material','Drill holes in earth or materials.'),
  ('4.A.3.a.2.ae','4.A.3.a.2','Menata atau merapikan rambut','Groom or style hair.'),
  ('4.A.3.a.2.af','4.A.3.a.2','Menyiapkan ruang kelas, fasilitas, dan materi belajar','Set up classrooms, facilities, educational materials, or equipment.'),
  ('4.A.3.a.2.ag','4.A.3.a.2','Mengaplikasikan lapisan atau cairan pelindung','Apply protective solutions or coatings.'),
  ('4.A.3.a.2.ah','4.A.3.a.2','Menyambungkan komponen atau saluran ke peralatan','Connect components or supply lines to equipment or tools.'),
  ('4.A.3.a.2.ai','4.A.3.a.2','Menyambung bagian dengan teknik solder, las, atau brazing','Join parts using soldering, welding, or brazing techniques.'),
  ('4.A.3.a.2.aj','4.A.3.a.2','Merakit produk atau alat bantu kerja','Assemble products or work aids.'),
  ('4.A.3.a.2.ak','4.A.3.a.2','Menata stok perbekalan atau produk','Stock supplies or products.'),
  ('4.A.3.a.2.al','4.A.3.a.2','Mengambil sampel lingkungan atau biologis','Collect environmental or biological samples.'),
  ('4.A.3.a.2.am','4.A.3.a.2','Mengisi celah atau menambal ketidaksempurnaan','Apply materials to fill gaps or imperfections.'),
  ('4.A.3.a.2.an','4.A.3.a.2','Mengeluarkan benda kerja dari mesin produksi','Remove workpieces from production equipment.'),
  ('4.A.3.a.2.ao','4.A.3.a.2','Memosisikan material atau komponen untuk dirakit','Position materials or components for assembly.'),
  ('4.A.3.a.2.ap','4.A.3.a.2','Mengemas barang','Package objects.'),
  ('4.A.3.a.2.aq','4.A.3.a.2','Memasang instalasi perpipaan atau sanitasi','Install plumbing or piping equipment or systems.'),
  ('4.A.3.a.2.as','4.A.3.a.2','Mengerjakan finishing dekoratif','Apply decorative finishes.'),
  ('4.A.3.a.2.at','4.A.3.a.2','Menyiapkan dan memasang peralatan','Set up equipment.'),
  ('4.A.3.a.2.au','4.A.3.a.2','Menyiapkan spesimen atau material untuk diuji','Prepare specimens or materials for testing.'),
  ('4.A.3.a.2.b','4.A.3.a.2','Mengambil sampel produk atau material','Collect samples of products or materials.'),
  ('4.A.3.a.2.c','4.A.3.a.2','Menyiapkan makanan atau minuman','Prepare foods or beverages.'),
  ('4.A.3.a.2.d','4.A.3.a.2','Merakit peralatan atau komponen','Assemble equipment or components.'),
  ('4.A.3.a.2.e','4.A.3.a.2','Menjahit pakaian atau bahan','Sew garments or materials.'),
  ('4.A.3.a.2.f','4.A.3.a.2','Menempatkan benda kerja atau material pada mesin','Position workpieces or materials on equipment.'),
  ('4.A.3.a.2.g','4.A.3.a.2','Membentuk material menjadi produk','Shape materials to create products.'),
  ('4.A.3.a.2.h','4.A.3.a.2','Menata display atau dekorasi','Arrange displays or decorations.'),
  ('4.A.3.a.2.i','4.A.3.a.2','Menyetel peralatan agar kinerjanya optimal','Adjust equipment to ensure adequate performance.'),
  ('4.A.3.a.2.k','4.A.3.a.2','Menyiapkan peralatan medis dan area kerjanya','Prepare medical equipment or work areas for use.'),
  ('4.A.3.a.2.l','4.A.3.a.2','Memotong material','Cut materials.'),
  ('4.A.3.a.2.m','4.A.3.a.2','Menyiapkan material industri untuk diproses','Prepare industrial materials for processing or use.'),
  ('4.A.3.a.2.o','4.A.3.a.2','Menghaluskan permukaan benda atau peralatan','Smooth surfaces of objects or equipment.'),
  ('4.A.3.a.2.p','4.A.3.a.2','Memasang peralatan energi atau pemanas','Install energy or heating equipment.'),
  ('4.A.3.a.2.q','4.A.3.a.2','Membuat alat kesehatan','Fabricate medical devices.'),
  ('4.A.3.a.2.s','4.A.3.a.2','Membongkar peralatan','Disassemble equipment.'),
  ('4.A.3.a.2.t','4.A.3.a.2','Memasang peralatan komersial atau produksi','Install commercial or production equipment.'),
  ('4.A.3.a.2.u','4.A.3.a.2','Mengaplikasikan produk perawatan kulit atau rambut','Apply hygienic or cosmetic agents to skin or hair.'),
  ('4.A.3.a.2.v','4.A.3.a.2','Menempatkan alat atau peralatan kerja','Position tools or equipment.'),
  ('4.A.3.a.2.x','4.A.3.a.2','Menyetel peralatan medis agar kinerjanya optimal','Adjust medical equipment to ensure adequate performance.'),
  ('4.A.3.a.2.y','4.A.3.a.2','Mengukir atau menggravir benda','Engrave objects.'),
  ('4.A.3.a.3.a','4.A.3.a.3','Mengoperasikan peralatan kantor','Operate office equipment.'),
  ('4.A.3.a.3.b','4.A.3.a.3','Mengoperasikan sistem atau peralatan pompa','Operate pumping systems or equipment.'),
  ('4.A.3.a.3.c','4.A.3.a.3','Mengoperasikan alat berat konstruksi atau penggalian','Operate construction or excavation equipment.'),
  ('4.A.3.a.3.d','4.A.3.a.3','Mengoperasikan peralatan medis','Operate medical equipment.'),
  ('4.A.3.a.3.e','4.A.3.a.3','Mengoperasikan peralatan audio visual','Operate audiovisual or related equipment.'),
  ('4.A.3.a.3.f','4.A.3.a.3','Mengoperasikan mesin pengolahan atau produksi industri','Operate industrial processing or production equipment.'),
  ('4.A.3.a.3.g','4.A.3.a.3','Mengoperasikan peralatan produksi atau distribusi energi','Operate energy production or distribution equipment.'),
  ('4.A.3.a.3.h','4.A.3.a.3','Mengoperasikan alat angkat dan alat pemindah','Operate lifting or moving equipment.'),
  ('4.A.3.a.3.i','4.A.3.a.3','Mengoperasikan peralatan laboratorium atau lapangan','Operate laboratory or field equipment.'),
  ('4.A.3.a.3.j','4.A.3.a.3','Mengoperasikan peralatan atau sistem komunikasi','Operate communications equipment or systems.'),
  ('4.A.3.a.3.l','4.A.3.a.3','Mengoperasikan mesin potong atau gerinda','Operate cutting or grinding equipment.'),
  ('4.A.3.a.4.a','4.A.3.a.4','Mengoperasikan kendaraan atau alat transportasi','Operate transportation equipment or vehicles.'),
  ('4.A.3.b.1.a','4.A.3.b.1','Memprogram sistem komputer atau mesin produksi','Program computer systems or production equipment.'),
  ('4.A.3.b.1.b','4.A.3.b.1','Menerapkan pengamanan sistem komputer dan informasi','Implement security measures for computer or information systems.'),
  ('4.A.3.b.1.c','4.A.3.b.1','Menyiapkan sistem komputer, jaringan, dan sistem informasi','Set up computer systems, networks, or other information systems.'),
  ('4.A.3.b.1.d','4.A.3.b.1','Menyelesaikan masalah komputer','Resolve computer problems.'),
  ('4.A.3.b.1.e','4.A.3.b.1','Mengoperasikan sistem komputer atau peralatan terkomputerisasi','Operate computer systems or computerized equipment.'),
  ('4.A.3.b.1.f','4.A.3.b.1','Mengolah data digital atau daring','Process digital or online data.'),
  ('4.A.3.b.2.a','4.A.3.b.2','Menyusun spesifikasi teknis produk atau operasional','Develop technical specifications for products or operations.'),
  ('4.A.3.b.2.b','4.A.3.b.2','Merancang struktur atau fasilitas bangunan','Design structures or facilities.'),
  ('4.A.3.b.2.c','4.A.3.b.2','Merancang sistem atau peralatan industri','Design industrial systems or equipment.'),
  ('4.A.3.b.2.d','4.A.3.b.2','Membuat model sistem, proses, atau produk','Develop models of systems, processes, or products.'),
  ('4.A.3.b.2.e','4.A.3.b.2','Merancang sistem atau peralatan kelistrikan dan elektronik','Design electrical or electronic systems or equipment.'),
  ('4.A.3.b.2.f','4.A.3.b.2','Menyusun prosedur dan standar operasional atau teknis','Develop operational or technical procedures or standards.'),
  ('4.A.3.b.4.a','4.A.3.b.4','Merawat fasilitas atau peralatan','Maintain facilities or equipment.'),
  ('4.A.3.b.4.b','4.A.3.b.4','Memperbaiki benda kerja atau produk','Repair workpieces or products.'),
  ('4.A.3.b.4.c','4.A.3.b.4','Memperbaiki alat atau peralatan','Repair tools or equipment.'),
  ('4.A.3.b.4.d','4.A.3.b.4','Memperbaiki komponen kendaraan','Repair vehicle components.'),
  ('4.A.3.b.4.e','4.A.3.b.4','Menjaga kendaraan tetap layak jalan','Maintain vehicles in working condition.'),
  ('4.A.3.b.4.f','4.A.3.b.4','Merawat peralatan atau instrumen medis','Maintain medical equipment or instruments.'),
  ('4.A.3.b.5.a','4.A.3.b.5','Merawat alat dan peralatan kerja','Maintain tools or equipment.'),
  ('4.A.3.b.5.b','4.A.3.b.5','Memperbaiki peralatan listrik atau elektronik','Repair electrical or electronic equipment.'),
  ('4.A.3.b.5.c','4.A.3.b.5','Merawat peralatan elektronik, komputer, dan perangkat teknis lain','Maintain electronic, computer, or other technical equipment.'),
  ('4.A.3.b.6.a','4.A.3.b.6','Menyusun dokumen, laporan, atau anggaran keuangan','Prepare financial documents, reports, or budgets.'),
  ('4.A.3.b.6.b','4.A.3.b.6','Mencatat informasi perkara hukum','Record information about legal matters.'),
  ('4.A.3.b.6.c','4.A.3.b.6','Mempresentasikan hasil riset atau informasi teknis','Present research or technical information.'),
  ('4.A.3.b.6.e','4.A.3.b.6','Merekam gambar dengan peralatan foto atau audio visual','Record images with photographic or audiovisual equipment.'),
  ('4.A.3.b.6.f','4.A.3.b.6','Menyusun dokumen kesehatan atau medis','Prepare health or medical documents.'),
  ('4.A.3.b.6.g','4.A.3.b.6','Menyusun proposal atau pengajuan hibah','Prepare proposals or grant applications.'),
  ('4.A.3.b.6.h','4.A.3.b.6','Memelihara catatan operasional','Maintain operational records.'),
  ('4.A.3.b.6.i','4.A.3.b.6','Mendokumentasikan rancangan, prosedur, dan kegiatan teknis','Document technical designs, procedures, or activities.'),
  ('4.A.3.b.6.j','4.A.3.b.6','Memelihara catatan penjualan atau keuangan','Maintain sales or financial records.'),
  ('4.A.3.b.6.k','4.A.3.b.6','Memelihara rekam medis atau catatan kesehatan','Maintain health or medical records.'),
  ('4.A.3.b.6.l','4.A.3.b.6','Menyusun materi informasi atau bahan ajar','Prepare informational or instructional materials.'),
  ('4.A.3.b.6.m','4.A.3.b.6','Menyiapkan dokumen kontrak, permohonan, atau perizinan','Prepare documentation for contracts, applications, or permits.'),
  ('4.A.3.b.6.n','4.A.3.b.6','Menyusun dokumen hukum atau regulasi','Prepare legal or regulatory documents.'),
  ('4.A.3.b.6.o','4.A.3.b.6','Menyusun laporan kegiatan operasional atau prosedural','Prepare reports of operational or procedural activities.'),
  ('4.A.3.b.6.p','4.A.3.b.6','Menulis naskah untuk keperluan seni atau komersial','Write material for artistic or commercial purposes.'),
  ('4.A.4.a.1.a','4.A.4.a.1','Menjelaskan detail teknis produk atau layanan','Explain technical details of products or services.'),
  ('4.A.4.a.1.b','4.A.4.a.1','Menjelaskan regulasi, kebijakan, atau prosedur','Explain regulations, policies, or procedures.'),
  ('4.A.4.a.1.c','4.A.4.a.1','Menjadi penerjemah bahasa, budaya, atau keagamaan','Interpret language, cultural, or religious information for others.'),
  ('4.A.4.a.1.d','4.A.4.a.1','Menjelaskan informasi keuangan','Explain financial information.'),
  ('4.A.4.a.1.e','4.A.4.a.1','Menjelaskan informasi medis kepada pasien dan keluarganya','Explain medical information to patients or family members.'),
  ('4.A.4.a.2.a','4.A.4.a.2','Mengomunikasikan informasi lingkungan dan keberlanjutan','Communicate environmental or sustainability information.'),
  ('4.A.4.a.2.b','4.A.4.a.2','Membantu ilmuwan atau tenaga ahli dalam proyek dan riset','Assist scientists, scholars, or technical specialists with projects or research.'),
  ('4.A.4.a.2.c','4.A.4.a.2','Berkoordinasi soal rencana dan kegiatan operasional','Communicate with others about operational plans or activities.'),
  ('4.A.4.a.2.d','4.A.4.a.2','Berdiskusi dengan tenaga kesehatan lain tentang perawatan pasien','Confer with healthcare or other professionals about patient care.'),
  ('4.A.4.a.2.e','4.A.4.a.2','Mengomunikasikan strategi bisnis','Communicate with others about business strategies.'),
  ('4.A.4.a.2.f','4.A.4.a.2','Berkolaborasi mengembangkan program pendidikan','Collaborate in the development of educational programs.'),
  ('4.A.4.a.2.g','4.A.4.a.2','Melaporkan keadaan darurat atau masalah kepada pihak terkait','Notify others of emergencies or problems.'),
  ('4.A.4.a.2.h','4.A.4.a.2','Mengomunikasikan spesifikasi dan detail proyek','Communicate with others about specifications or project details.'),
  ('4.A.4.a.2.j','4.A.4.a.2','Menggali kebutuhan dan spesifikasi pesanan klien','Confer with clients to determine needs or order specifications.'),
  ('4.A.4.a.3.a','4.A.4.a.3','Menyampaikan keterangan dalam proses hukum','Present information in legal proceedings.'),
  ('4.A.4.a.3.b','4.A.4.a.3','Memberikan informasi atau bantuan kepada publik','Provide information or assistance to the public.'),
  ('4.A.4.a.3.c','4.A.4.a.3','Memberikan informasi kepada tamu, klien, atau pelanggan','Provide information to guests, clients, or customers.'),
  ('4.A.4.a.4.a','4.A.4.a.4','Membangun relasi dan jejaring profesional','Develop professional relationships or networks.'),
  ('4.A.4.a.5.a','4.A.4.a.5','Membantu orang lain mengakses layanan atau sumber daya tambahan','Assist others to access additional services or resources.'),
  ('4.A.4.a.5.b','4.A.4.a.5','Memberikan terapi','Administer therapeutic treatments.'),
  ('4.A.4.a.5.c','4.A.4.a.5','Memberikan perawatan atau tindakan medis dasar','Administer basic health care or medical treatments.'),
  ('4.A.4.a.5.d','4.A.4.a.5','Merawat tanaman atau hewan','Care for plants or animals.'),
  ('4.A.4.a.5.e','4.A.4.a.5','Menangani situasi krisis atau darurat','Intervene in crisis situations or emergencies.'),
  ('4.A.4.a.5.f','4.A.4.a.5','Memasangkan alat bantu pada pasien atau klien','Fit assistive devices to patients or clients.'),
  ('4.A.4.a.5.g','4.A.4.a.5','Memberikan pertolongan medis darurat','Administer emergency medical treatment.'),
  ('4.A.4.a.5.h','4.A.4.a.5','Membantu orang mengurus berkas','Assist individuals with paperwork.'),
  ('4.A.4.a.5.i','4.A.4.a.5','Mendampingi individu berkebutuhan khusus','Assist individuals with special needs.'),
  ('4.A.4.a.5.j','4.A.4.a.5','Memberikan bantuan umum kepada pelanggan atau pengguna jalan','Provide general assistance to others, such as customers, patrons, or motorists.'),
  ('4.A.4.a.5.k','4.A.4.a.5','Mengasistensi tenaga kesehatan saat tindakan medis','Assist healthcare practitioners during medical procedures.'),
  ('4.A.4.a.5.l','4.A.4.a.5','Menangani cedera, penyakit, atau gangguan kesehatan','Treat injuries, illnesses, or diseases.'),
  ('4.A.4.a.6.a','4.A.4.a.6','Mengadvokasi kebutuhan individu atau komunitas','Advocate for individual or community needs.'),
  ('4.A.4.a.6.b','4.A.4.a.6','Menjual produk atau layanan','Sell products or services.'),
  ('4.A.4.a.6.c','4.A.4.a.6','Mempromosikan produk, layanan, atau program','Promote products, services, or programs.'),
  ('4.A.4.a.7.a','4.A.4.a.7','Menengahi perselisihan','Mediate disputes.'),
  ('4.A.4.a.7.b','4.A.4.a.7','Menegosiasikan kontrak atau kesepakatan','Negotiate contracts or agreements.'),
  ('4.A.4.a.7.c','4.A.4.a.7','Menyelesaikan masalah personel atau operasional','Resolve personnel or operational problems.'),
  ('4.A.4.a.8.a','4.A.4.a.8','Menampilkan pertunjukan seni atau hiburan','Present arts or entertainment performances.'),
  ('4.A.4.a.8.c','4.A.4.a.8','Menanggapi keluhan atau pertanyaan pelanggan','Respond to customer problems or inquiries.'),
  ('4.A.4.b.1.a','4.A.4.b.1','Berkoordinasi dengan pihak lain untuk menyelesaikan masalah','Coordinate with others to resolve problems.'),
  ('4.A.4.b.1.b','4.A.4.b.1','Memberi aba-aba untuk mengoordinasikan pekerjaan','Signal others to coordinate work activities.'),
  ('4.A.4.b.1.c','4.A.4.b.1','Mengoordinasikan kegiatan dengan klien, instansi, atau organisasi','Coordinate activities with clients, agencies, or organizations.'),
  ('4.A.4.b.1.d','4.A.4.b.1','Mengoordinasikan kegiatan seni atau hiburan','Coordinate artistic or entertainment activities.'),
  ('4.A.4.b.1.e','4.A.4.b.1','Mengoordinasikan kegiatan kelompok atau kemasyarakatan','Coordinate group, community, or public activities.'),
  ('4.A.4.b.1.f','4.A.4.b.1','Membagi tugas kepada orang lain','Assign work to others.'),
  ('4.A.4.b.1.g','4.A.4.b.1','Mengoordinasikan kegiatan kepatuhan regulasi','Coordinate regulatory compliance activities.'),
  ('4.A.4.b.2.a','4.A.4.b.2','Memberi dukungan dan semangat kepada orang lain','Provide support or encouragement to others.'),
  ('4.A.4.b.3.a','4.A.4.b.3','Mengajarkan keterampilan hidup','Teach life skills.'),
  ('4.A.4.b.3.b','4.A.4.b.3','Mengajar mata pelajaran akademik atau kejuruan','Teach academic or vocational subjects.'),
  ('4.A.4.b.3.c','4.A.4.b.3','Mengajarkan prosedur dan standar keselamatan','Teach safety procedures or standards to others.'),
  ('4.A.4.b.3.d','4.A.4.b.3','Melatih orang lain tentang prosedur kerja','Train others on operational or work procedures.'),
  ('4.A.4.b.3.e','4.A.4.b.3','Melatih orang lain menggunakan peralatan atau produk','Train others to use equipment or products.'),
  ('4.A.4.b.3.f','4.A.4.b.3','Memberi edukasi kesehatan kepada orang lain','Train others on health or medical topics.'),
  ('4.A.4.b.4.a','4.A.4.b.4','Menyupervisi pekerjaan personel','Supervise personnel activities.'),
  ('4.A.4.b.4.b','4.A.4.b.4','Terlibat dalam komite organisasi','Serve on organizational committees.'),
  ('4.A.4.b.4.e','4.A.4.b.4','Memimpin kegiatan ilmiah atau teknis','Direct scientific or technical activities.'),
  ('4.A.4.b.4.f','4.A.4.b.4','Mengelola kegiatan sumber daya manusia','Manage human resources activities.'),
  ('4.A.4.b.4.g','4.A.4.b.4','Mengelola sistem atau kegiatan pengendalian','Manage control systems or activities.'),
  ('4.A.4.b.4.h','4.A.4.b.4','Mengelola anggaran atau keuangan','Manage budgets or finances.'),
  ('4.A.4.b.4.i','4.A.4.b.4','Memimpin kegiatan konstruksi atau penggalian','Direct construction or extraction activities.'),
  ('4.A.4.b.4.j','4.A.4.b.4','Mengarahkan operasional dan prosedur organisasi','Direct organizational operations, activities, or procedures.'),
  ('4.A.4.b.4.k','4.A.4.b.4','Memimpin kegiatan keamanan atau keselamatan','Direct security or safety activities or operations.'),
  ('4.A.4.b.4.l','4.A.4.b.4','Memimpin kegiatan hukum','Direct legal activities.'),
  ('4.A.4.b.5.a','4.A.4.b.5','Membimbing orang lain sebagai coach','Coach others.'),
  ('4.A.4.b.6.a','4.A.4.b.6','Memberi nasihat medis kepada pasien atau klien','Advise patients or clients on medical issues.'),
  ('4.A.4.b.6.b','4.A.4.b.6','Memberi saran tentang produk atau layanan','Advise others on products or services.'),
  ('4.A.4.b.6.c','4.A.4.b.6','Memberi saran tentang keberlanjutan dan praktik ramah lingkungan','Advise others on environmental sustainability or green practices.'),
  ('4.A.4.b.6.d','4.A.4.b.6','Memberi saran tentang perancangan dan penggunaan teknologi','Advise others on the design or use of technologies.'),
  ('4.A.4.b.6.e','4.A.4.b.6','Memberi saran tentang urusan bisnis atau operasional','Advise others on business or operational matters.'),
  ('4.A.4.b.6.f','4.A.4.b.6','Memberi saran tentang kesehatan dan kebugaran','Advise others on healthcare or wellness issues.'),
  ('4.A.4.b.6.g','4.A.4.b.6','Memberi saran tentang pendidikan atau pilihan karier','Advise others on educational or vocational matters.'),
  ('4.A.4.b.6.h','4.A.4.b.6','Memberi saran tentang urusan hukum atau regulasi','Advise others on legal or regulatory matters.'),
  ('4.A.4.b.6.i','4.A.4.b.6','Memberi saran tentang kesehatan dan keselamatan kerja','Advise others on workplace health or safety issues.'),
  ('4.A.4.b.6.j','4.A.4.b.6','Memberi konseling tentang masalah pribadi','Counsel others about personal matters.'),
  ('4.A.4.b.6.k','4.A.4.b.6','Memberi saran tentang urusan keuangan','Advise others on financial matters.'),
  ('4.A.4.c.1.a','4.A.4.c.1','Menjalankan pekerjaan administrasi atau ketatausahaan','Perform administrative or clerical activities.'),
  ('4.A.4.c.1.c','4.A.4.c.1','Melaksanakan transaksi keuangan','Execute financial transactions.'),
  ('4.A.4.c.1.d','4.A.4.c.1','Menerbitkan dokumen resmi','Issue documentation.'),
  ('4.A.4.c.1.e','4.A.4.c.1','Memproses pengiriman atau surat','Process shipments or mail.'),
  ('4.A.4.c.2.a','4.A.4.c.2','Menjalankan proses rekrutmen dan seleksi','Perform recruiting or hiring activities.'),
  ('4.A.4.c.2.b','4.A.4.c.2','Menjalankan kegiatan kepegawaian','Perform human resources activities.'),
  ('4.A.4.c.3.a','4.A.4.c.3','Mengisi ulang persediaan material, peralatan, atau produk','Replenish inventories of materials, equipment, or products.'),
  ('4.A.4.c.3.b','4.A.4.c.3','Meminta pemeriksaan atau tindakan medis','Order medical tests or procedures.'),
  ('4.A.4.c.3.c','4.A.4.c.3','Mendistribusikan material, perbekalan, atau sumber daya','Distribute materials, supplies, or resources.'),
  ('4.A.4.c.3.d','4.A.4.c.3','Menerima pembayaran atau ongkos','Collect fares or payments.'),
  ('4.A.4.c.3.e','4.A.4.c.3','Melakukan pengadaan barang atau jasa','Purchase goods or services.'),
  ('4.A.4.c.3.f','4.A.4.c.3','Meresepkan obat atau alat kesehatan','Prescribe medical treatments or devices.'),
  ('4.A.4.c.3.g','4.A.4.c.3','Memantau sumber daya atau persediaan','Monitor resources or inventories.')
on conflict (code) do update
  set gwa_code = excluded.gwa_code,
      name_id  = excluded.name_id,
      name_en  = excluded.name_en;

-- ---------------------------------------------------------------------------
-- 2. Masukan per profesi
--
--   iwa_codes  : capaian terurut dari yang paling penting (maksimal 9)
--   tools      : perangkat lunak bertanda "In Demand" di O*NET, maksimal 5
--   next_socs  : profesi lanjutan, hanya yang ada di knowledge base kita
--   note       : terisi kalau jenjang targetnya dikoreksi manual
-- ---------------------------------------------------------------------------
create temporary table _rm_in (
  soc_code    text primary key,
  target_rank smallint,
  job_zone    smallint,
  exp_months  integer,
  ojt_months  integer,
  iwa_codes   text[],
  iwa_w       numeric[],
  tools       text[],
  next_socs   text[],
  note        text
) on commit drop;

insert into _rm_in values
  ('11-2011.00',6,4,60,2,array['4.A.2.b.2.c','4.A.4.a.4.a','4.A.2.b.2.j','4.A.4.a.2.c','4.A.2.a.4.g','4.A.2.b.3.a','4.A.2.a.4.b','4.A.2.a.3.a','4.A.2.a.1.d']::text[],array[10.49,7.16,7.13,6.9,6.59,6.25,6.0,4.07,3.89]::numeric[],array['Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['41-3011.00','13-1161.00','13-1161.01']::text[],null),
  ('11-2022.00',6,4,60,2,array['4.A.4.a.8.c','4.A.1.a.1.n','4.A.4.b.6.b','4.A.2.a.4.k','4.A.2.a.1.d','4.A.2.b.1.c','4.A.4.a.2.c','4.A.4.a.4.a','4.A.4.b.6.e']::text[],array[4.35,4.29,4.24,4.21,4.19,3.7,3.53,3.5,3.25]::numeric[],array['Salesforce software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-1161.00','11-2011.00','13-1022.00']::text[],null),
  ('11-2032.00',6,4,24,9,array['4.A.4.a.2.c','4.A.4.a.3.b','4.A.2.b.2.j','4.A.4.a.4.a','4.A.2.b.2.c','4.A.2.b.1.g','4.A.2.a.1.d','4.A.2.a.1.b','4.A.1.a.2.h']::text[],array[9.0,6.0,6.0,6.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['Salesforce software','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['27-3031.00','11-2011.00','13-1161.00']::text[],null),
  ('11-3021.00',6,4,84,4,array['4.A.2.b.2.b','4.A.2.b.2.v','4.A.2.a.1.j','4.A.2.a.4.g','4.A.4.a.7.c','4.A.4.a.2.c','4.A.2.a.1.d','4.A.4.b.6.b','4.A.2.b.3.a']::text[],array[8.13,7.81,7.27,4.11,4.1,4.1,4.04,3.99,3.88]::numeric[],array['Enterprise application integration EAI software','Microsoft Azure software','Amazon Web Services AWS software']::text[],array['15-1211.00','15-1252.00','15-1299.08']::text[],null),
  ('11-3031.00',6,4,60,4,array['4.A.2.a.4.k','4.A.3.b.6.n','4.A.4.a.4.a','4.A.4.a.1.b','4.A.1.a.2.c','4.A.2.a.4.g','4.A.2.b.1.c','4.A.3.b.6.a','4.A.4.b.6.e']::text[],array[18.2,8.08,8.06,4.24,4.2,4.14,4.09,4.04,3.82]::numeric[],array['SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-2011.00','13-2051.00','13-2052.00']::text[],null),
  ('11-3031.01',6,4,84,4,array['4.A.4.b.6.e','4.A.3.b.6.a','4.A.2.a.4.k','4.A.2.b.1.h','4.A.2.a.2.c','4.A.4.a.4.a','4.A.1.a.2.c','4.A.1.a.2.k','4.A.2.b.1.c']::text[],array[15.42,8.59,8.22,4.52,4.45,4.44,4.4,4.4,4.33]::numeric[],array['Intuit QuickBooks','SAP software','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['13-2011.00','13-2061.00','11-3031.00']::text[],null),
  ('11-3031.03',7,5,108,9,array['4.A.1.a.2.c','4.A.2.b.1.i','4.A.2.b.1.c','4.A.2.a.4.g','4.A.4.b.6.e','4.A.1.a.2.b','4.A.4.a.1.b','4.A.2.b.3.a','4.A.1.a.2.k']::text[],array[9.12,8.69,4.48,4.38,4.23,4.22,4.22,4.05,3.79]::numeric[],array['Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['13-2051.00','13-2054.00','13-2052.00']::text[],null),
  ('11-3051.00',6,4,36,9,array['4.A.2.a.4.g','4.A.4.a.2.c','4.A.2.b.1.i','4.A.3.b.6.o','4.A.2.a.1.e','4.A.1.a.2.b','4.A.2.a.1.d','4.A.4.b.3.d','4.A.3.b.6.h']::text[],array[7.79,7.42,6.8,6.72,4.01,3.85,3.85,3.85,3.72]::numeric[],array['SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['11-3051.01','11-3071.04']::text[],'Lowongan manajer produksi di Indonesia praktis selalu mensyaratkan S1 Teknik/Industri.'),
  ('11-3051.01',6,4,60,4,array['4.A.2.a.4.g','4.A.2.a.1.e','4.A.1.a.2.b','4.A.3.b.6.h','4.A.1.b.2.e','4.A.4.a.1.b','4.A.4.a.2.c','4.A.2.a.3.a','4.A.4.b.3.d']::text[],array[8.27,8.24,8.18,8.13,7.97,7.84,7.5,4.24,4.11]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['19-4099.01','17-2112.02','17-2112.00']::text[],null),
  ('11-3061.00',6,4,36,9,array['4.A.3.b.6.a','4.A.1.a.1.w','4.A.2.b.1.i','4.A.2.a.4.g','4.A.2.a.2.a','4.A.2.a.3.c','4.A.2.b.1.c','4.A.3.b.6.m','4.A.4.b.3.d']::text[],array[11.57,8.64,8.61,8.16,4.18,4.18,4.18,4.12,4.11]::numeric[],array['Purchasing software','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software']::text[],array['13-1023.00','13-1022.00','13-1081.02']::text[],null),
  ('11-3071.04',6,4,84,4,array['4.A.2.b.1.i','4.A.2.b.1.h','4.A.2.b.2.q','4.A.2.a.4.g','4.A.4.a.2.c','4.A.3.b.2.f','4.A.3.b.6.h','4.A.1.b.1.b','4.A.1.a.1.j']::text[],array[25.22,11.86,10.18,8.06,7.67,7.54,6.74,6.41,5.21]::numeric[],array['Warehouse management system WMS','Inventory management systems','SAP software','Microsoft PowerPoint','Microsoft Outlook']::text[],array['13-1081.02','13-1081.00','13-1081.01']::text[],null),
  ('11-9199.01',6,4,60,4,array['4.A.2.b.1.i','4.A.3.b.6.n','4.A.2.a.3.a','4.A.1.a.2.h','4.A.4.b.6.h','4.A.4.a.1.b','4.A.2.b.3.a','4.A.1.a.2.b','4.A.2.b.2.v']::text[],array[11.31,8.94,8.56,6.6,4.3,4.13,4.09,3.83,3.77]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-1041.07','11-9199.02','15-2051.02']::text[],null),
  ('11-9199.02',6,4,36,4,array['4.A.3.b.6.n','4.A.1.a.2.k','4.A.4.a.1.b','4.A.4.a.2.c','4.A.2.b.3.a','4.A.2.a.3.b','4.A.4.b.6.h','4.A.2.b.1.i','4.A.4.b.3.d']::text[],array[12.53,12.49,12.48,12.01,12.0,10.95,8.2,8.0,4.1]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-1041.07','11-9199.01','13-1041.00']::text[],null),
  ('11-9199.08',6,4,36,4,array['4.A.2.a.3.c','4.A.1.a.1.c','4.A.1.a.2.k','4.A.4.b.6.e','4.A.4.b.3.d','4.A.1.a.1.w','4.A.2.b.2.p','4.A.2.a.4.c','4.A.4.b.6.h']::text[],array[11.92,8.76,7.61,6.58,4.24,4.2,4.05,4.05,3.94]::numeric[],array['Reporting software','Enterprise application integration EAI software','Google Workspace software','Microsoft PowerPoint','Microsoft Outlook']::text[],array['13-2054.00','11-9199.02']::text[],null),
  ('13-1011.00',6,4,18,2,array['4.A.4.a.6.c','4.A.2.b.3.a','4.A.4.a.7.b','4.A.4.a.8.c','4.A.4.a.4.a','4.A.2.b.1.i','4.A.3.b.6.a','4.A.1.b.2.e','4.A.4.b.6.k']::text[],array[12.48,4.28,3.99,3.95,3.86,3.5,3.42,2.97,2.54]::numeric[],array[]::text[],array['27-2012.04','41-3011.00','27-3031.00']::text[],null),
  ('13-1021.00',6,4,36,4,array['4.A.4.c.1.c','4.A.2.a.4.g','4.A.4.a.7.b','4.A.3.b.6.h','4.A.2.b.1.a','4.A.4.b.6.e','4.A.2.a.1.i','4.A.4.c.3.e','4.A.4.b.4.j']::text[],array[7.65,6.75,4.18,4.06,3.58,3.23,2.8,4.4,4.07]::numeric[],array['Purchasing software','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word']::text[],array['13-1022.00','13-1023.00','11-3061.00']::text[],null),
  ('13-1022.00',5,3,36,4,array['4.A.2.a.4.b','4.A.4.a.2.e','4.A.2.b.1.a','4.A.4.a.7.b','4.A.4.a.2.c','4.A.4.b.6.e','4.A.4.c.1.c','4.A.2.b.1.c','4.A.1.a.1.g']::text[],array[13.51,11.42,7.55,4.3,4.13,4.1,3.93,3.93,3.73]::numeric[],array['Purchasing software','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software']::text[],array['13-1023.00','13-1021.00','11-3061.00']::text[],null),
  ('13-1023.00',6,4,36,9,array['4.A.1.a.1.g','4.A.4.c.1.c','4.A.2.a.4.b','4.A.4.a.2.e','4.A.2.a.4.i','4.A.3.b.2.a','4.A.2.a.4.k','4.A.4.b.3.d','4.A.1.a.2.b']::text[],array[7.61,7.4,7.36,7.19,4.85,4.25,4.2,4.16,4.05]::numeric[],array['Microsoft SharePoint','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word']::text[],array['11-3061.00','13-1022.00','13-1021.00']::text[],null),
  ('13-1032.00',2,3,36,1,array['4.A.1.b.2.d','4.A.2.b.1.a','4.A.2.a.3.c','4.A.3.b.6.m','4.A.4.b.1.a']::text[],array[14.13,13.48,4.72,4.67,3.42]::numeric[],array['Disassembler software','Microsoft Office software']::text[],array['49-3021.00','49-3023.00','13-2022.00']::text[],null),
  ('13-1041.00',6,4,24,9,array['4.A.2.b.3.a','4.A.2.a.3.a','4.A.4.a.3.c','4.A.4.b.6.h','4.A.1.b.2.e','4.A.2.a.3.c','4.A.3.b.6.c','4.A.2.b.1.i','4.A.2.a.2.a']::text[],array[9.0,8.9,8.47,7.37,4.38,4.38,4.3,3.0,3.0]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['11-9199.02','13-1041.07']::text[],null),
  ('13-1041.07',6,4,36,4,array['4.A.2.a.4.i','4.A.2.a.3.a','4.A.2.b.3.a','4.A.3.b.6.n','4.A.4.b.6.h','4.A.1.a.1.q','4.A.4.a.1.b','4.A.2.a.2.c','4.A.2.a.3.c']::text[],array[20.47,12.91,9.88,8.95,8.3,4.55,4.44,4.26,3.8]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['11-9199.01','11-9199.02','13-1041.00']::text[],null),
  ('13-1081.00',6,4,36,2,array['4.A.1.a.1.n','4.A.3.b.6.g','4.A.4.a.4.a','4.A.2.a.4.g','4.A.4.a.3.c','4.A.4.a.2.e','4.A.4.a.2.c','4.A.2.b.3.a','4.A.3.b.2.f']::text[],array[8.66,8.17,4.46,4.12,4.04,3.96,3.92,3.71,3.65]::numeric[],array['SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-1081.02','11-3071.04','13-1081.01']::text[],null),
  ('13-1081.01',6,4,18,4,array['4.A.2.a.4.g','4.A.1.b.1.b','4.A.2.a.4.k','4.A.4.b.6.e','4.A.3.b.6.a','4.A.2.b.2.q','4.A.2.b.2.c','4.A.3.b.2.f','4.A.3.b.2.b']::text[],array[45.87,11.9,7.42,7.21,6.21,6.21,4.22,3.95,3.8]::numeric[],array['SAP software','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['13-1081.02','17-2112.00','13-1081.00']::text[],null),
  ('13-1081.02',6,4,60,4,array['4.A.2.a.4.g','4.A.3.b.6.h','4.A.3.b.2.f','4.A.1.a.1.g','4.A.1.a.2.b','4.A.4.b.6.e','4.A.3.b.6.o','4.A.4.a.2.e','4.A.1.b.1.b']::text[],array[27.08,15.25,10.94,7.96,7.9,4.14,4.05,3.86,3.69]::numeric[],array['Microsoft Power BI','Inventory management systems','Tableau','Structured query language SQL','SAP software']::text[],array['11-3071.04','13-1081.00','13-1081.01']::text[],null),
  ('13-1161.00',6,4,36,4,array['4.A.2.a.4.b','4.A.1.a.1.f','4.A.3.b.6.c','4.A.1.a.1.i','4.A.2.a.1.b','4.A.1.a.2.c','4.A.4.a.2.e','4.A.2.b.2.c','4.A.2.b.4.a']::text[],array[20.36,7.91,4.59,4.33,4.1,3.74,3.65,3.09,4.27]::numeric[],array['TikTok','Canva','Google Analytics','Adobe Creative Cloud software','Salesforce software']::text[],array['11-2011.00','13-1161.01','15-2051.01']::text[],null),
  ('13-1161.01',5,4,18,2,array['4.A.2.b.1.i','4.A.2.b.2.b','4.A.4.a.2.e','4.A.2.a.4.b','4.A.3.b.2.a','4.A.2.a.1.g','4.A.4.a.3.c','4.A.3.b.2.f','4.A.4.b.6.d']::text[],array[27.78,26.74,23.28,21.01,7.17,6.91,6.11,5.1,3.48]::numeric[],array['Adobe Analytics','Ahrefs Site Explorer','Google Tag Manager','Moz search engine optimization SEO software','Screaming Frog SEO Spider']::text[],array['15-1255.00','13-1161.00','11-2011.00']::text[],null),
  ('13-2011.00',6,4,24,9,array['4.A.2.a.3.c','4.A.3.b.6.a','4.A.2.a.2.a','4.A.2.a.4.k','4.A.1.a.1.c','4.A.4.b.6.k','4.A.4.b.6.e','4.A.4.a.2.c','4.A.4.a.2.e']::text[],array[40.14,20.09,15.61,15.5,9.0,8.85,8.66,8.58,4.3]::numeric[],array['Intuit QuickBooks','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software']::text[],array['13-2061.00','11-3031.01','11-3031.00']::text[],null),
  ('13-2022.00',6,4,36,36,array['4.A.3.b.6.c','4.A.2.a.1.i','4.A.3.b.1.f','4.A.2.b.1.d','4.A.3.b.6.l','4.A.1.a.1.d','4.A.1.b.2.f','4.A.3.b.6.h','4.A.2.b.2.f']::text[],array[9.53,8.77,8.68,4.91,4.91,4.73,4.52,4.36,4.36]::numeric[],array[]::text[],array['13-2023.00','41-9021.00','41-9022.00']::text[],null),
  ('13-2023.00',6,4,18,18,array['4.A.2.a.1.i','4.A.1.a.1.d','4.A.2.a.4.b','4.A.2.a.2.a','4.A.2.b.2.o','4.A.2.a.3.c','4.A.4.a.1.d','4.A.3.b.6.a','4.A.2.b.3.a']::text[],array[35.74,9.23,8.63,8.39,7.96,7.88,5.26,4.7,4.57]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['13-2022.00','41-9021.00','41-9022.00']::text[],null),
  ('13-2031.00',6,4,18,9,array['4.A.2.a.4.k','4.A.4.b.6.k','4.A.3.b.6.a','4.A.1.a.1.d','4.A.2.a.2.a','4.A.4.a.2.e','4.A.4.a.3.a','4.A.1.b.1.b','4.A.2.b.4.a']::text[],array[19.83,8.42,8.09,4.12,4.08,4.06,3.81,3.36,4.0]::numeric[],array['Microsoft Power BI','SAP software','Microsoft Access','Microsoft PowerPoint','Microsoft Outlook']::text[],array['13-2011.00','11-3031.01','11-3031.00']::text[],null),
  ('13-2041.00',6,4,18,2,array['4.A.2.a.4.k','4.A.2.a.4.c','4.A.3.b.6.m','4.A.2.a.4.g','4.A.3.b.6.a','4.A.2.a.4.b','4.A.2.a.1.i','4.A.4.b.6.k','4.A.2.a.3.c']::text[],array[9.43,4.9,4.76,4.55,4.55,4.25,3.69,3.69,3.31]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['43-4041.00','13-2072.00','43-4131.00']::text[],null),
  ('13-2051.00',6,4,24,9,array['4.A.2.a.4.k','4.A.2.a.4.b','4.A.2.b.1.a','4.A.2.a.1.i','4.A.4.b.6.k','4.A.2.a.4.c','4.A.1.b.1.b','4.A.2.b.2.h','4.A.2.b.3.a']::text[],array[18.0,9.0,9.0,6.0,6.0,6.0,3.0,3.0,3.0]::numeric[],array['Microsoft Power BI','Tableau','Structured query language SQL','SAP software','Microsoft PowerPoint']::text[],array['13-2052.00','41-3031.00','11-3031.03']::text[],null),
  ('13-2052.00',6,4,36,9,array['4.A.4.a.1.d','4.A.4.b.6.k','4.A.2.a.1.i','4.A.2.b.1.i','4.A.1.a.1.w','4.A.4.a.8.c','4.A.3.b.6.a','4.A.1.b.1.b','4.A.4.c.1.c']::text[],array[16.98,15.02,9.08,8.63,4.65,4.54,4.04,3.96,3.85]::numeric[],array['Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['13-2051.00','13-2071.00','41-3031.00']::text[],null),
  ('13-2053.00',6,4,18,9,array['4.A.2.b.1.c','4.A.2.a.1.i','4.A.2.a.4.f','4.A.4.a.1.b','4.A.2.a.4.c','4.A.2.a.2.a']::text[],array[12.32,4.53,4.53,4.3,4.19,4.04]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['13-2054.00','13-2041.00','13-2072.00']::text[],null),
  ('13-2054.00',6,4,24,9,array['4.A.2.a.4.c','4.A.2.a.4.k','4.A.3.b.2.f','4.A.4.a.3.c','4.A.4.b.6.e','4.A.2.a.4.b','4.A.1.a.1.f','4.A.1.a.2.c','4.A.2.b.2.h']::text[],array[24.0,15.0,9.0,6.0,6.0,3.0,3.0,3.0,3.0]::numeric[],array['Microsoft Power BI','Tableau','R','Python','Structured query language SQL']::text[],array['13-2099.01','13-2051.00','11-3031.03']::text[],null),
  ('13-2061.00',6,4,18,36,array['4.A.2.a.3.c','4.A.1.a.2.b','4.A.4.b.3.d','4.A.4.b.6.h','4.A.3.b.6.o','4.A.2.b.1.i','4.A.1.a.2.c','4.A.2.a.4.i','4.A.2.a.3.a']::text[],array[10.91,8.0,7.42,4.65,4.45,4.24,4.13,3.74,3.5]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['13-2011.00','11-9199.02','13-2099.04']::text[],null),
  ('13-2071.00',5,4,18,9,array['4.A.2.b.2.h','4.A.4.a.1.d','4.A.4.b.6.k','4.A.1.b.3.c','4.A.2.a.1.i','4.A.4.a.1.b','4.A.4.c.1.c','4.A.1.a.1.w','4.A.3.b.6.m']::text[],array[17.44,16.18,13.28,9.36,8.76,4.79,4.6,4.54,4.48]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['13-2052.00','13-2072.00','43-4041.00']::text[],null),
  ('13-2072.00',6,4,36,9,array['4.A.2.a.1.i','4.A.2.b.1.c','4.A.4.a.1.d','4.A.2.a.2.a','4.A.3.b.6.h','4.A.2.a.3.c','4.A.2.b.2.h','4.A.4.a.8.c','4.A.1.b.3.c']::text[],array[7.57,7.4,7.33,7.14,7.13,7.13,6.97,6.96,6.57]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['43-4131.00','13-2071.00','13-2041.00']::text[],null),
  ('13-2081.00',5,3,18,4,array['4.A.2.a.3.c','4.A.4.a.3.c','4.A.4.a.8.c','4.A.2.b.2.h','4.A.2.a.2.a','4.A.2.a.1.i','4.A.4.a.1.b','4.A.3.b.6.b','4.A.2.b.3.a']::text[],array[19.99,13.43,8.38,4.55,4.54,4.54,4.41,4.35,4.19]::numeric[],array['Tax compliance property tax management software','Alteryx software','Tax software','SAP software','Microsoft PowerPoint']::text[],array['13-2011.00','43-4041.00']::text[],null),
  ('13-2099.01',7,5,36,9,array['4.A.2.a.4.k','4.A.3.b.2.f','4.A.4.b.6.e','4.A.4.a.2.e','4.A.3.b.6.a','4.A.2.a.1.g','4.A.1.a.2.c','4.A.3.b.2.a','4.A.2.a.1.b']::text[],array[19.7,18.2,7.43,6.79,3.65,3.3,2.88,2.83,2.33]::numeric[],array['Microsoft Visual Basic for Applications VBA','Tableau','R','C++','The MathWorks MATLAB']::text[],array['15-2051.00','13-2054.00','13-2051.00']::text[],null),
  ('13-2099.04',6,4,36,9,array['4.A.1.a.1.c','4.A.3.b.6.n','4.A.2.a.4.k','4.A.4.b.6.e','4.A.2.b.3.a','4.A.3.a.1.k','4.A.1.a.1.d','4.A.1.a.1.w','4.A.3.b.6.b']::text[],array[25.49,9.44,8.27,8.21,7.6,7.5,4.83,4.73,4.62]::numeric[],array['Structured query language SQL','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software']::text[],array['13-2061.00','11-9199.02']::text[],null),
  ('15-1211.00',5,4,36,9,array['4.A.2.b.2.b','4.A.4.b.6.d','4.A.4.a.2.h','4.A.3.b.1.d','4.A.1.b.2.h','4.A.1.a.2.j','4.A.3.b.1.c','4.A.3.b.1.a','4.A.2.a.4.e']::text[],array[17.86,7.16,6.65,4.24,4.0,4.0,3.78,3.71,3.6]::numeric[],array['ServiceNow','Microsoft Power BI','Atlassian JIRA','Python','Structured query language SQL']::text[],array['15-1252.00','15-1299.08','15-1242.00']::text[],null),
  ('15-1211.01',7,5,36,4,array['4.A.2.b.2.b','4.A.2.a.1.g','4.A.2.a.4.f','4.A.3.b.2.f','4.A.4.b.6.d','4.A.4.a.2.h','4.A.3.b.1.b','4.A.3.b.6.h','4.A.1.b.2.h']::text[],array[25.58,12.19,8.57,8.24,6.18,4.81,4.43,4.24,4.14]::numeric[],array['Microsoft Power BI','Tableau','R','SAS','Python']::text[],array['29-9021.00','15-2051.02']::text[],null),
  ('15-1212.00',6,4,60,4,array['4.A.3.b.1.b','4.A.3.b.2.f','4.A.2.b.3.a','4.A.1.b.2.h','4.A.3.b.6.h','4.A.3.b.1.d','4.A.1.a.2.j','4.A.4.b.3.e','4.A.4.b.1.a']::text[],array[12.32,4.4,4.23,4.12,3.94,3.94,3.89,3.81,3.94]::numeric[],array['eMASS','MITRE ATT&CK software','Tenable Nessus','Firewall software','Microsoft PowerShell']::text[],array['15-1299.05','15-1299.04','15-1299.06']::text[],null),
  ('15-1221.00',7,5,36,4,array['4.A.2.b.2.b','4.A.2.a.4.g','4.A.1.a.2.j','4.A.3.b.5.c','4.A.2.a.4.d','4.A.2.a.1.j','4.A.4.a.2.b','4.A.4.a.2.h','4.A.2.b.2.v']::text[],array[7.52,4.24,3.69,3.69,3.61,3.46,3.37,3.35,3.2]::numeric[],array['Hugging Face','LangChain','Vector database software','Amazon Web Services AWS SageMaker','Scikit-learn']::text[],array['15-2051.00','15-1252.00','15-1251.00']::text[],null),
  ('15-1231.00',6,4,60,9,array['4.A.3.b.1.c','4.A.3.b.1.d','4.A.1.b.2.h','4.A.3.b.6.i','4.A.3.b.1.b','4.A.2.a.4.l','4.A.4.b.6.d','4.A.1.a.2.j','4.A.2.a.4.g']::text[],array[26.88,15.76,14.87,14.19,8.81,4.26,3.96,3.94,3.94]::numeric[],array['Microsoft Active Directory','ServiceNow','Firewall software','Microsoft Windows Server','Apple macOS']::text[],array['15-1241.00','15-1244.00','15-1232.00']::text[],null),
  ('15-1232.00',5,3,36,2,array['4.A.3.b.1.c','4.A.4.b.6.d','4.A.1.a.1.b','4.A.1.b.2.h','4.A.4.b.3.e','4.A.1.a.2.j','4.A.3.b.1.d','4.A.3.b.5.c','4.A.4.a.2.h']::text[],array[11.48,10.57,7.15,6.78,6.6,3.99,3.94,3.77,3.71]::numeric[],array['Microsoft Active Directory','Apple iOS','ServiceNow','Firewall software','Microsoft Azure software']::text[],array['15-1231.00','15-1244.00','15-1299.08']::text[],'Di Indonesia pintu masuknya SMK TKJ atau D3 Informatika, bukan S1.'),
  ('15-1241.00',6,4,60,9,array['4.A.3.b.5.c','4.A.3.b.1.c','4.A.3.b.2.f','4.A.4.a.2.h','4.A.4.b.6.d','4.A.2.b.2.b','4.A.3.b.2.a','4.A.1.a.1.t','4.A.1.a.2.j']::text[],array[14.72,11.46,10.9,10.05,8.13,7.63,7.2,7.19,7.18]::numeric[],array['Border Gateway Protocol BGP','IBM Terraform','Firewall software','Ansible software','Microsoft PowerShell']::text[],array['15-1231.00','15-1244.00','15-1299.08']::text[],null),
  ('15-1241.01',5,3,36,9,array['4.A.3.b.1.b','4.A.3.b.1.c','4.A.3.b.6.h','4.A.3.b.6.i','4.A.4.a.2.h','4.A.2.b.3.a','4.A.2.a.1.g','4.A.2.a.4.e','4.A.2.b.2.p']::text[],array[15.9,11.32,7.75,7.01,4.3,4.19,4.15,4.14,4.11]::numeric[],array['Autodesk Navisworks','NavisWorks Jetstream','Firewall software','Autodesk Revit','Microsoft Visio']::text[],array['15-1241.00','15-1231.00','15-1299.08']::text[],null),
  ('15-1242.00',6,4,60,4,array['4.A.2.b.2.f','4.A.2.a.1.g','4.A.3.b.1.b','4.A.3.b.1.f','4.A.4.b.6.d','4.A.1.a.1.b','4.A.3.b.2.f','4.A.3.b.1.c','4.A.1.b.2.h']::text[],array[13.71,10.49,7.73,7.13,6.51,5.81,3.93,3.86,3.76]::numeric[],array['Microsoft Azure Data Factory','PySpark','Relational database management system software','Informatica software','Apache Airflow']::text[],array['15-1243.00','15-1211.00','15-1244.00']::text[],null),
  ('15-1243.00',6,4,60,4,array['4.A.2.b.2.f','4.A.3.b.2.f','4.A.2.a.1.g','4.A.3.b.6.i','4.A.4.a.2.h','4.A.3.b.2.d','4.A.2.b.2.b','4.A.4.b.6.d','4.A.3.b.2.a']::text[],array[31.27,15.75,11.03,8.47,8.43,8.05,7.7,6.88,4.0]::numeric[],array['Snowflake','Apache Spark','Microsoft Power BI','Apache Kafka','Microsoft Azure software']::text[],array['15-1242.00','15-1243.01','15-1252.00']::text[],null),
  ('15-1243.01',6,4,60,4,array['4.A.3.b.2.f','4.A.2.b.2.b','4.A.3.b.2.d','4.A.2.b.2.o','4.A.3.b.1.a','4.A.3.b.6.h','4.A.2.a.2.a','4.A.2.b.2.f','4.A.3.b.1.d']::text[],array[15.55,15.2,8.14,8.0,7.74,7.1,4.43,4.09,3.91]::numeric[],array['Operational Data Store ODS software','Microsoft Power BI','Tableau','Python','Structured query language SQL']::text[],array['15-1243.00','15-1242.00','15-1252.00']::text[],null),
  ('15-1244.00',6,4,60,9,array['4.A.3.b.1.b','4.A.4.b.6.d','4.A.3.b.1.d','4.A.3.b.5.c','4.A.1.a.2.j','4.A.1.b.2.h','4.A.2.b.1.h','4.A.2.a.4.e','4.A.3.b.2.f']::text[],array[15.99,13.72,12.24,7.68,7.64,7.12,6.74,6.74,3.74]::numeric[],array['Microsoft Active Directory','ServiceNow','Firewall software','Red Hat Enterprise Linux','Microsoft Windows Server']::text[],array['15-1231.00','15-1242.00','15-1241.00']::text[],null),
  ('15-1251.00',6,4,36,4,array['4.A.2.b.2.b','4.A.1.b.2.h','4.A.4.b.3.e','4.A.3.b.1.a','4.A.3.b.1.d','4.A.3.b.2.d','4.A.2.b.2.o','4.A.3.b.6.i','4.A.3.b.6.l']::text[],array[19.42,14.88,9.45,8.57,4.38,3.58,3.58,3.56,3.27]::numeric[],array['Cascading style sheets CSS','Microsoft Visual Studio','Git','Microsoft Azure software','C#']::text[],array['15-1252.00','15-1255.00','15-1299.08']::text[],null),
  ('15-1252.00',6,4,84,4,array['4.A.2.b.2.b','4.A.2.a.4.e','4.A.4.a.2.h','4.A.1.a.2.j','4.A.3.b.2.f','4.A.2.a.1.g','4.A.3.b.1.f','4.A.2.a.4.d','4.A.3.b.2.a']::text[],array[10.86,10.76,7.43,4.12,3.9,3.59,3.59,3.56,3.53]::numeric[],array['TypeScript','IBM Terraform','RESTful API','Jenkins CI','Spring Boot']::text[],array['15-1299.08','15-1211.00','15-1253.00']::text[],null),
  ('15-1253.00',6,4,18,4,array['4.A.1.b.2.h','4.A.3.b.2.f','4.A.4.b.6.d','4.A.3.b.6.h','4.A.1.a.2.j','4.A.3.b.1.c','4.A.2.a.1.g','4.A.3.b.1.d','4.A.2.a.4.g']::text[],array[26.0,20.56,17.56,8.82,8.09,7.71,6.25,4.7,4.7]::numeric[],array['Appium','Microsoft Playwright','Postman','REST Assured','TestNG']::text[],array['15-1252.00','17-2112.02','15-1299.08']::text[],null),
  ('15-1254.00',5,3,18,2,array['4.A.2.b.2.b','4.A.3.b.1.f','4.A.4.b.6.d','4.A.3.b.6.i','4.A.3.b.2.a','4.A.3.b.1.c','4.A.1.b.2.h','4.A.3.b.1.b','4.A.3.b.1.a']::text[],array[13.17,12.09,10.07,9.64,9.47,9.35,8.13,7.35,4.58]::numeric[],array['JavaScript framework software','GraphQL','Vue.js','Web application software','TypeScript']::text[],array['15-1255.00','15-1299.01','15-1252.00']::text[],null),
  ('15-1255.00',6,4,24,9,array['4.A.2.b.2.o','4.A.2.b.2.b','4.A.3.b.2.a','4.A.3.b.1.f','4.A.3.b.6.i','4.A.1.a.1.t','4.A.3.b.1.d','4.A.3.b.2.d','4.A.1.b.2.h']::text[],array[15.0,12.0,12.0,12.0,9.0,6.0,6.0,6.0,6.0]::numeric[],array['Adobe XD','TypeScript','Figma','React','Google Angular']::text[],array['15-1254.00','15-1299.01','15-1252.00']::text[],null),
  ('15-1255.01',6,4,18,2,array['4.A.4.a.2.h','4.A.2.b.2.b','4.A.2.b.2.o','4.A.3.b.6.i','4.A.1.b.2.h','4.A.2.b.3.a','4.A.2.a.4.b','4.A.3.b.2.f','4.A.4.b.4.e']::text[],array[30.9,25.0,11.28,8.57,8.34,3.65,3.6,3.28,4.2]::numeric[],array['Unreal Technology Unreal Engine','Unity Technologies Unity','Autodesk Maya','C#','C++']::text[],array['15-1255.00','27-1014.00','27-1024.00']::text[],null),
  ('15-1299.01',6,4,36,2,array['4.A.4.b.6.d','4.A.3.b.6.h','4.A.3.b.1.b','4.A.3.b.1.d','4.A.3.b.2.f','4.A.3.b.2.a','4.A.1.b.2.h','4.A.2.b.2.p','4.A.2.b.2.b']::text[],array[18.65,16.01,13.04,12.71,11.5,11.14,11.02,8.57,8.43]::numeric[],array['Microsoft Internet Information Services (IIS) Manager','Web application framework software','Content management systems CMS','Web application software','Web server software']::text[],array['15-1255.00','15-1254.00','15-1242.00']::text[],null),
  ('15-1299.02',5,3,9,9,array['4.A.2.b.2.o','4.A.3.b.1.f','4.A.4.b.6.d','4.A.2.b.2.b','4.A.2.b.2.f','4.A.2.a.4.d','4.A.3.b.1.a','4.A.3.b.6.c','4.A.2.a.2.a']::text[],array[22.65,16.1,14.73,14.54,11.93,11.61,7.81,4.61,4.06]::numeric[],array['ESRI ArcGIS ArcPy','ESRI ArcGIS Survey 123','QGIS','RockWare ArcMap','Microsoft Azure software']::text[],array['15-2051.00']::text[],null),
  ('15-1299.03',6,4,36,4,array['4.A.3.b.2.f','4.A.1.a.1.d','4.A.3.b.1.f','4.A.4.b.6.d','4.A.3.b.2.a','4.A.3.b.6.h','4.A.2.a.1.g','4.A.2.a.4.e','4.A.3.b.1.b']::text[],array[23.68,11.49,8.54,7.19,4.17,4.17,4.16,4.16,4.14]::numeric[],array['Microsoft SharePoint','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software']::text[],array['15-1211.00','15-1242.00','29-9021.00']::text[],null),
  ('15-1299.04',6,4,24,9,array['4.A.3.b.6.c','4.A.3.b.2.f','4.A.2.a.4.l','4.A.2.b.3.a','4.A.1.a.1.c','4.A.2.a.1.g','4.A.1.b.2.l','4.A.1.b.2.h','4.A.1.a.1.d']::text[],array[12.0,12.0,9.0,6.0,6.0,3.0,3.0,3.0,3.0]::numeric[],array['Nmap','Qualys Cloud Platform','Kali Linux','Portswigger BurP Suite','MITRE ATT&CK software']::text[],array['15-1299.05','15-1212.00','15-1253.00']::text[],null),
  ('15-1299.05',6,4,60,4,array['4.A.2.a.1.g','4.A.3.b.1.c','4.A.2.b.2.b','4.A.4.b.6.d','4.A.2.a.4.l','4.A.1.b.2.h','4.A.4.b.3.d','4.A.1.a.1.c','4.A.3.b.2.a']::text[],array[8.35,7.82,7.82,7.32,4.56,4.28,4.28,4.22,3.94]::numeric[],array['Single sign-on SSO','IBM Terraform','Microsoft Active Directory','Kubernetes','Firewall software']::text[],array['15-1299.04','15-1212.00','15-1244.00']::text[],null),
  ('15-1299.06',6,4,24,9,array['4.A.1.a.1.c','4.A.3.b.6.c','4.A.4.b.6.d','4.A.2.a.2.c','4.A.1.a.2.j','4.A.2.a.4.g','4.A.2.a.4.l','4.A.2.b.3.a','4.A.2.b.6.b']::text[],array[12.0,9.0,9.0,3.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['MITRE ATT&CK software','Firewall software','Microsoft PowerShell','Splunk Enterprise','Amazon Web Services AWS software']::text[],array['15-1212.00','15-1299.05','15-1299.04']::text[],null),
  ('15-1299.07',6,4,24,9,array['4.A.2.b.2.b','4.A.2.a.1.g','4.A.1.b.2.h','4.A.4.a.2.h','4.A.3.b.1.a','4.A.3.b.1.b','4.A.3.b.2.f','4.A.2.a.4.l','4.A.2.b.2.f']::text[],array[9.0,6.0,6.0,6.0,6.0,6.0,6.0,3.0,3.0]::numeric[],array['Solidity','Rust programming language','TypeScript','RESTful API','Kubernetes']::text[],array['15-1252.00','15-1299.08','15-1243.00']::text[],null),
  ('15-1299.08',5,3,36,4,array['4.A.1.b.2.h','4.A.4.b.6.d','4.A.2.b.2.b','4.A.3.b.1.c','4.A.4.a.2.h','4.A.2.a.1.g','4.A.3.b.2.f','4.A.1.a.2.j','4.A.3.b.5.c']::text[],array[15.32,15.01,12.99,11.8,11.42,11.37,4.18,4.09,3.95]::numeric[],array['IBM Terraform','Jenkins CI','Microsoft Active Directory','Kubernetes','Amazon Web Services AWS CloudFormation']::text[],array['15-1252.00','15-1211.00','15-1241.00']::text[],null),
  ('15-1299.09',6,4,36,4,array['4.A.2.b.6.b','4.A.3.b.2.f','4.A.1.a.2.c','4.A.2.a.1.g','4.A.1.a.2.k','4.A.1.a.1.n','4.A.2.b.1.h','4.A.2.a.4.l','4.A.2.a.4.d']::text[],array[12.15,7.95,4.29,4.25,4.25,4.2,4.05,4.05,4.0]::numeric[],array['ServiceNow','Atlassian Confluence','Microsoft Azure software','Amazon Web Services AWS software','Atlassian JIRA']::text[],array['11-3021.00','15-1252.00','15-1211.00']::text[],null),
  ('15-2011.00',6,4,0,9,array['4.A.4.a.3.a','4.A.4.a.2.e','4.A.2.a.4.f','4.A.2.b.2.v','4.A.2.a.4.d','4.A.4.b.6.h','4.A.4.b.6.b','4.A.4.a.7.b','4.A.4.a.3.c']::text[],array[5.73,4.46,4.44,4.26,4.17,3.8,3.8,3.27,2.42]::numeric[],array['Microsoft Power BI','Microsoft Visual Basic for Applications VBA','Tableau','R','SAS']::text[],array['13-2052.00','13-2054.00','13-2051.00']::text[],null),
  ('15-2031.00',7,5,18,2,array['4.A.2.a.4.d','4.A.2.b.2.u','4.A.2.b.1.d','4.A.2.b.2.b','4.A.3.b.6.c','4.A.2.a.2.a','4.A.3.b.6.h','4.A.1.a.1.t','4.A.3.b.1.d']::text[],array[11.95,8.9,8.6,7.51,4.62,4.55,4.5,4.38,4.38]::numeric[],array['Microsoft Power BI','Tableau','Salesforce software','Python','Structured query language SQL']::text[],array['15-2051.00','15-1252.00','15-1243.00']::text[],null),
  ('15-2041.00',7,5,18,4,array['4.A.2.b.1.d','4.A.3.b.6.c','4.A.2.a.4.d','4.A.2.b.2.s','4.A.2.a.2.a','4.A.3.b.1.f','4.A.2.a.1.j','4.A.2.b.2.o','4.A.2.a.4.e']::text[],array[16.77,16.51,13.25,12.45,8.58,8.53,4.67,4.52,4.5]::numeric[],array['SAS JMP','Statistical software','StataCorp Stata','Tableau','IBM SPSS Statistics']::text[],array['15-2051.00','15-2041.01','15-2051.02']::text[],null),
  ('15-2041.01',7,5,18,4,array['4.A.2.a.4.d','4.A.3.b.6.c','4.A.2.b.2.s','4.A.2.b.1.d','4.A.2.a.4.f','4.A.2.b.3.a','4.A.2.b.2.o','4.A.3.b.1.a','4.A.4.b.6.b']::text[],array[19.96,16.84,11.68,8.53,7.81,4.3,4.3,4.29,4.25]::numeric[],array['Statistical software','StataCorp Stata','IBM SPSS Statistics','R','SAS']::text[],array['15-2051.00','15-2041.00','15-2051.02']::text[],null),
  ('15-2051.00',6,4,24,9,array['4.A.2.a.4.d','4.A.2.a.4.g','4.A.3.b.6.c','4.A.2.b.1.d','4.A.2.a.4.k','4.A.2.b.1.j','4.A.2.b.2.o','4.A.2.b.3.a','4.A.2.b.2.u']::text[],array[9.0,6.0,6.0,3.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['NumPy','Scikit-learn','pandas','PyTorch','TensorFlow']::text[],array['15-2041.00','13-2099.01','15-2031.00']::text[],null),
  ('15-2051.01',6,4,36,4,array['4.A.2.a.4.b','4.A.3.b.2.f','4.A.3.b.6.c','4.A.3.b.1.f','4.A.4.b.6.d','4.A.3.b.6.h','4.A.2.b.2.f','4.A.4.a.2.c','4.A.1.a.1.n']::text[],array[21.4,7.92,4.64,4.36,3.95,3.73,3.7,3.65,3.64]::numeric[],array['Snowflake','Microsoft Power BI','Microsoft Azure software','Amazon Web Services AWS software','Tableau']::text[],array['15-2051.00','15-1211.00','13-1161.00']::text[],null),
  ('15-2051.02',6,4,36,2,array['4.A.2.a.2.a','4.A.3.b.2.f','4.A.4.a.2.h','4.A.3.b.1.f','4.A.2.b.2.f','4.A.2.a.4.g','4.A.1.a.2.k','4.A.3.b.6.c','4.A.2.a.4.f']::text[],array[12.59,11.86,10.29,8.37,4.5,4.32,4.05,3.95,3.71]::numeric[],array['Epic Systems','Structured query language SQL','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['15-1211.01','15-2051.00']::text[],null),
  ('17-2061.00',6,4,36,9,array['4.A.2.a.4.e','4.A.4.b.6.b','4.A.4.b.6.e','4.A.2.b.3.a','4.A.3.b.2.e','4.A.4.a.2.h','4.A.3.b.2.d','4.A.1.b.2.l','4.A.3.b.6.i']::text[],array[13.69,7.15,6.38,4.31,4.18,4.14,4.07,4.07,4.0]::numeric[],array['PCI Express PCIe','Tool command language Tcl','SystemVerilog','Very high speed integrated circuit VHSIC hardware description language VHDL simulation software','Simulation program with integrated circuit emphasis SPICE']::text[],array['15-1252.00','17-3024.01']::text[],null),
  ('17-2111.00',6,4,24,9,array['4.A.1.a.1.t','4.A.1.a.1.v','4.A.3.b.6.i','4.A.4.b.6.i','4.A.2.b.2.e','4.A.4.a.2.h','4.A.1.b.2.g','4.A.4.b.3.c','4.A.2.b.3.a']::text[],array[16.32,16.2,8.09,8.02,6.91,6.87,6.0,4.29,4.29]::numeric[],array['Microsoft SharePoint','Autodesk AutoCAD','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word']::text[],array[]::text[],null),
  ('17-2111.02',6,4,18,9,array['4.A.2.b.3.a','4.A.2.a.3.a','4.A.4.b.6.i','4.A.2.b.2.e','4.A.3.b.6.c','4.A.1.b.2.e','4.A.1.a.2.k','4.A.2.a.4.i','4.A.2.b.1.b']::text[],array[13.26,8.38,8.24,4.24,4.19,4.19,4.19,3.73,3.55]::numeric[],array['Mechanical electrical plumbing MEP design software','Autodesk Revit','Autodesk AutoCAD','Microsoft Office software','Microsoft Excel']::text[],array['17-2111.00']::text[],null),
  ('17-2112.00',6,4,36,9,array['4.A.2.a.4.e','4.A.4.a.2.h','4.A.3.b.6.i','4.A.1.a.1.b','4.A.2.b.5.b','4.A.1.b.3.b','4.A.2.b.1.d','4.A.4.a.2.j','4.A.4.b.6.e']::text[],array[10.85,7.49,7.09,6.75,6.3,3.97,3.92,3.78,3.67]::numeric[],array['Structured query language SQL','Autodesk AutoCAD','SAP software','Microsoft PowerPoint','Microsoft Office software']::text[],array['17-3026.00','17-2112.03','11-3051.00']::text[],null),
  ('17-2112.01',6,5,18,9,array['4.A.1.a.1.t','4.A.4.b.6.i','4.A.3.b.6.i','4.A.2.b.2.s','4.A.2.b.1.h','4.A.3.b.2.d','4.A.4.a.2.h','4.A.1.b.2.e','4.A.2.a.1.g']::text[],array[28.7,8.69,7.95,7.64,7.2,6.6,4.5,4.47,4.26]::numeric[],array['Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['17-2111.00','17-2112.00','17-2112.02']::text[],null),
  ('17-2112.02',6,4,36,4,array['4.A.3.b.6.i','4.A.2.b.2.s','4.A.1.b.2.g','4.A.1.a.1.b','4.A.2.a.4.l','4.A.2.b.6.b','4.A.3.b.5.c','4.A.3.b.6.h','4.A.1.b.2.f']::text[],array[8.4,7.72,7.57,4.63,4.55,4.37,4.2,4.1,4.0]::numeric[],array['Microsoft Power Platform software','IBM Terraform','Kubernetes','Microsoft Power BI','Docker']::text[],array['17-2112.00','11-3051.01','15-1253.00']::text[],null),
  ('17-2112.03',6,4,18,4,array['4.A.2.b.1.b','4.A.3.b.2.c','4.A.2.a.4.e','4.A.2.b.1.h','4.A.2.a.4.g','4.A.4.a.7.c','4.A.3.b.2.f','4.A.2.b.1.i','4.A.2.b.1.d']::text[],array[11.89,10.9,7.29,7.16,4.27,4.27,4.19,4.19,4.16]::numeric[],array['Dassault Systemes SolidWorks','Autodesk AutoCAD','SAP software','Microsoft PowerPoint','Microsoft Office software']::text[],array['17-2112.00','17-2141.00','11-3051.00']::text[],null),
  ('17-2121.00',6,4,36,9,array['4.A.2.a.1.g','4.A.3.b.6.c','4.A.1.a.2.k','4.A.2.b.2.o','4.A.1.b.2.l','4.A.1.a.1.b','4.A.2.b.5.b','4.A.2.b.2.s','4.A.3.b.2.b']::text[],array[11.08,7.61,7.5,7.4,6.98,6.93,6.81,6.39,4.0]::numeric[],array['McNeel Rhinoceros 3D','Autodesk AutoCAD','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['17-3027.00','17-2141.00']::text[],null),
  ('17-2131.00',6,4,18,9,array['4.A.2.a.3.b','4.A.2.b.6.b','4.A.4.b.3.b','4.A.2.a.4.l','4.A.1.a.2.b','4.A.1.b.2.c','4.A.2.a.4.e','4.A.3.a.2.m','4.A.2.b.1.d']::text[],array[7.75,7.66,6.86,4.3,4.16,4.11,4.1,4.06,4.05]::numeric[],array['Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['17-2112.03','17-2112.00','17-2141.00']::text[],null),
  ('17-2141.00',6,4,36,9,array['4.A.3.b.2.c','4.A.4.b.6.e','4.A.1.b.3.b','4.A.1.b.2.l','4.A.1.a.1.b','4.A.2.a.1.g','4.A.2.b.1.i','4.A.4.a.2.h','4.A.1.a.1.v']::text[],array[12.32,10.86,7.04,6.79,4.3,4.18,4.15,3.97,3.76]::numeric[],array['Autodesk Revit','PTC Creo Parametric','Dassault Systemes SolidWorks','Python','Autodesk AutoCAD']::text[],array['17-3027.00','17-2199.05','17-2112.00']::text[],null),
  ('17-2141.02',6,4,18,4,array['4.A.3.b.2.a','4.A.1.a.1.t','4.A.2.b.2.m','4.A.3.b.2.e','4.A.1.b.2.l','4.A.4.b.6.d','4.A.2.a.4.l','4.A.3.a.2.i','4.A.2.a.1.g']::text[],array[14.48,10.75,10.53,7.58,4.25,4.24,4.19,4.17,3.84]::numeric[],array['Siemens Teamcenter','PTC Creo Parametric','Dassault Systemes SolidWorks','Dassault Systemes CATIA','The MathWorks MATLAB']::text[],array['17-2141.00','17-2112.03','17-2112.00']::text[],null),
  ('17-2151.00',6,4,60,18,array['4.A.2.b.1.d','4.A.2.b.1.j','4.A.1.a.2.b','4.A.3.b.2.c','4.A.2.b.3.a','4.A.3.b.6.c','4.A.1.b.2.e','4.A.1.a.1.v','4.A.4.b.6.i']::text[],array[11.55,7.57,7.45,6.63,5.8,4.38,4.08,4.07,4.07]::numeric[],array['Autodesk AutoCAD Civil 3D','Bentley MicroStation','Autodesk AutoCAD','Microsoft PowerPoint','Microsoft Office software']::text[],array['17-2171.00','19-4043.00','17-2112.00']::text[],null),
  ('17-2161.00',6,4,36,9,array['4.A.3.b.6.i','4.A.1.a.1.t','4.A.3.b.2.c','4.A.1.a.2.k','4.A.4.a.7.c','4.A.1.a.1.v','4.A.3.b.6.c','4.A.2.a.4.l','4.A.2.b.6.b']::text[],array[8.1,6.73,4.5,4.48,4.44,4.35,4.05,4.05,3.95]::numeric[],array['ANSYS simulation software','Python','Microsoft Office software','Microsoft Excel']::text[],array[]::text[],null),
  ('17-2171.00',6,4,60,9,array['4.A.2.b.1.d','4.A.1.b.2.l','4.A.1.a.2.b','4.A.3.b.2.f','4.A.3.b.6.h','4.A.4.a.7.c','4.A.2.a.4.a','4.A.2.b.6.b','4.A.2.a.4.e']::text[],array[4.16,4.12,4.09,4.09,4.04,3.99,3.99,3.95,3.83]::numeric[],array['Autodesk AutoCAD','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['17-2151.00','17-2112.00']::text[],null),
  ('17-2199.03',6,4,36,4,array['4.A.4.b.6.c','4.A.1.a.2.b','4.A.2.a.4.g','4.A.3.b.2.d','4.A.1.a.1.t','4.A.1.b.2.g','4.A.2.a.3.b','4.A.3.b.6.c','4.A.4.b.3.d']::text[],array[10.95,8.48,8.38,7.76,7.3,4.0,3.8,3.71,3.57]::numeric[],array['C++','The MathWorks MATLAB','Python','Autodesk AutoCAD','Microsoft PowerPoint']::text[],array['47-4011.01','17-2199.11','17-2199.10']::text[],null),
  ('17-2199.05',6,4,36,2,array['4.A.3.b.2.e','4.A.3.b.2.c','4.A.2.b.1.j','4.A.4.b.6.e','4.A.2.b.2.o','4.A.1.b.2.l','4.A.2.b.1.i','4.A.3.b.6.h','4.A.2.b.1.h']::text[],array[17.69,10.78,7.45,7.11,4.22,3.81,3.81,3.76,3.75]::numeric[],array['Embedded systems development software','ANSYS simulation software','MathWorks Simulink','C#','Dassault Systemes SolidWorks']::text[],array['17-3024.01','17-2199.08','17-3027.00']::text[],null),
  ('17-2199.08',6,4,36,4,array['4.A.3.b.1.a','4.A.3.b.2.e','4.A.3.b.2.c','4.A.1.a.1.t','4.A.2.a.4.e','4.A.2.a.4.l','4.A.1.b.2.l','4.A.3.b.6.h','4.A.4.b.6.b']::text[],array[17.25,11.36,10.42,7.35,4.11,4.04,3.89,3.85,3.81]::numeric[],array['Git','C#','Dassault Systemes SolidWorks','C','Oracle Java']::text[],array['17-2199.05','17-2141.00','17-2061.00']::text[],null),
  ('17-2199.10',6,4,60,4,array['4.A.2.b.2.o','4.A.1.b.2.b','4.A.3.b.2.c','4.A.4.b.6.d','4.A.4.b.6.e','4.A.1.a.1.t','4.A.3.b.2.a','4.A.1.a.2.k','4.A.2.a.1.g']::text[],array[7.42,6.81,6.36,3.8,3.72,3.63,3.43,3.2,3.0]::numeric[],array['ANSYS simulation software','PTC Creo Parametric','Git','Dassault Systemes SolidWorks','C++']::text[],array['17-2199.11','17-2199.03','17-2141.00']::text[],null),
  ('17-2199.11',6,4,36,4,array['4.A.2.a.4.e','4.A.2.b.2.m','4.A.1.a.1.f','4.A.2.b.6.b','4.A.4.b.6.d','4.A.2.b.2.o','4.A.3.b.2.d','4.A.2.a.3.b','4.A.4.b.6.e']::text[],array[6.48,6.15,4.46,4.44,4.33,4.21,4.14,3.88,3.88]::numeric[],array['Aurora HelioScope','ETAP','PVsyst','SKM Systems Analysis Power Tools','Python']::text[],array['41-4011.07','47-1011.03','47-2152.04']::text[],null),
  ('17-3024.01',5,3,36,9,array['4.A.3.b.1.a','4.A.3.a.2.d','4.A.3.b.5.a','4.A.3.b.6.i','4.A.3.b.5.b','4.A.2.b.1.b','4.A.3.b.6.h','4.A.2.a.1.g','4.A.3.a.2.i']::text[],array[22.97,15.74,12.49,7.06,4.24,4.2,4.15,3.83,3.83]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['17-3027.00']::text[],null),
  ('17-3026.00',5,3,36,9,array['4.A.3.b.2.f','4.A.3.b.2.c','4.A.1.a.2.k','4.A.1.a.2.b','4.A.2.a.4.e','4.A.3.a.2.i','4.A.2.b.1.j','4.A.2.b.2.o','4.A.1.b.2.c']::text[],array[9.0,9.0,6.74,6.4,6.0,6.0,6.0,6.0,3.66]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['17-2112.00','17-2112.03','17-3027.00']::text[],null),
  ('17-3027.00',5,3,36,9,array['4.A.2.b.2.o','4.A.3.b.2.c','4.A.1.b.2.c','4.A.3.b.6.i','4.A.2.a.4.e','4.A.1.b.2.l','4.A.1.a.1.b','4.A.3.a.2.d','4.A.2.a.4.l']::text[],array[13.9,13.15,10.79,10.37,9.91,9.67,7.14,7.02,6.91]::numeric[],array['Dassault Systemes SolidWorks','Microsoft Office software','Microsoft Excel']::text[],array['17-3024.01','17-3026.00']::text[],null),
  ('17-3027.01',5,3,36,9,array['4.A.1.b.2.l','4.A.4.b.6.e','4.A.3.b.6.i','4.A.3.a.3.f','4.A.1.a.1.b','4.A.1.b.2.f','4.A.1.a.2.b','4.A.2.a.4.l','4.A.3.a.2.t']::text[],array[11.47,6.92,4.26,4.22,4.19,4.15,4.11,4.11,4.0]::numeric[],array[]::text[],array['17-3027.00','17-3024.01']::text[],null),
  ('19-1012.00',6,4,9,4,array['4.A.1.a.1.t','4.A.1.b.2.e','4.A.2.a.1.e','4.A.3.b.2.f','4.A.2.b.3.a','4.A.1.b.2.c','4.A.3.b.2.a','4.A.2.a.1.g','4.A.4.a.2.j']::text[],array[15.12,4.38,4.18,4.14,4.0,3.91,3.81,3.73,3.35]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['19-4013.00']::text[],null),
  ('19-2042.00',7,5,9,4,array['4.A.2.a.4.a','4.A.1.a.1.h','4.A.2.a.4.g','4.A.2.b.1.d','4.A.1.a.2.i','4.A.2.b.2.o','4.A.2.a.3.a','4.A.1.b.2.e','4.A.2.b.2.s']::text[],array[30.13,14.58,12.94,8.83,7.98,7.85,7.35,7.07,4.43]::numeric[],array['Git','Geographic information system GIS systems','ESRI ArcGIS software','Python','Autodesk AutoCAD']::text[],array[]::text[],null),
  ('19-4013.00',5,3,9,2,array['4.A.2.a.4.j','4.A.3.b.6.h','4.A.1.b.2.c','4.A.3.a.2.au','4.A.2.a.1.e','4.A.1.b.3.a','4.A.3.a.1.h','4.A.3.b.5.c','4.A.1.a.1.p']::text[],array[12.25,8.7,8.67,8.22,4.68,4.38,4.23,4.23,4.19]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['19-1012.00','19-4099.01']::text[],null),
  ('19-4043.00',6,4,24,9,array['4.A.2.a.4.a','4.A.3.b.6.h','4.A.2.b.2.o','4.A.1.a.1.d','4.A.2.a.2.c','4.A.3.a.2.al','4.A.3.a.2.b','4.A.3.a.3.i','4.A.1.a.1.h']::text[],array[24.39,11.73,7.63,7.28,6.28,6.0,4.48,4.0,3.87]::numeric[],array['Microsoft Outlook','Microsoft Excel']::text[],array[]::text[],null),
  ('19-4099.01',5,3,9,2,array['4.A.1.b.2.c','4.A.3.b.5.c','4.A.2.a.1.e','4.A.3.b.6.n','4.A.3.b.2.f','4.A.2.a.4.g','4.A.3.a.2.i','4.A.1.b.2.e','4.A.3.b.6.h']::text[],array[8.46,8.43,8.06,7.34,7.17,4.35,4.29,4.2,4.18]::numeric[],array['Sparta Systems TrackWise','SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Word']::text[],array['11-3051.01','17-2112.02','17-2112.00']::text[],'Peran analis laboratorium QC di Indonesia lazimnya D3/S1 Kimia atau Analis Kesehatan.'),
  ('25-1011.00',8,5,18,1,array['4.A.4.b.6.g','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.p','4.A.4.a.2.f']::text[],array[25.17,17.64,17.38,13.97,13.22,4.43,4.43,4.37,3.93]::numeric[],array['Learning management system LMS']::text[],array['25-1063.00','25-2032.00','25-1112.00']::text[],null),
  ('25-1021.00',7,5,36,4,array['4.A.4.b.6.g','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.3.b','4.A.3.b.5.c','4.A.3.b.6.l','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.p']::text[],array[18.2,18.13,16.13,8.43,7.4,4.59,4.15,4.15,4.12]::numeric[],array['Learning management system LMS','Oracle Java','C++','Python']::text[],array['11-3021.00','25-1011.00','25-1022.00']::text[],null),
  ('25-1022.00',7,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.h','4.A.3.b.6.l','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.p']::text[],array[18.18,14.97,10.95,8.66,4.39,4.37,4.26,4.26,3.87]::numeric[],array['Learning management system LMS']::text[],array['25-1054.00','25-1051.00','25-1063.00']::text[],null),
  ('25-1031.00',7,5,36,18,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.l','4.A.3.b.6.h','4.A.3.b.6.p']::text[],array[16.95,16.29,14.36,8.74,4.48,4.48,4.44,4.36,4.01]::numeric[],array['Autodesk Revit','Learning management system LMS','Autodesk AutoCAD']::text[],array['25-1121.00','25-2023.00','25-1194.00']::text[],null),
  ('25-1032.00',8,5,0,9,array['4.A.2.b.3.a','4.A.2.a.1.c','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.b.1.g','4.A.3.b.6.p','4.A.3.b.6.l','4.A.3.b.6.g','4.A.2.a.1.b']::text[],array[16.88,16.16,12.69,8.28,5.84,4.49,4.38,4.27,3.83]::numeric[],array['Learning management system LMS']::text[],array['25-1194.00','25-1054.00','25-1021.00']::text[],null),
  ('25-1041.00',8,5,36,9,array['4.A.2.b.3.a','4.A.2.a.1.c','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.p','4.A.3.b.6.l','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.h']::text[],array[16.93,15.84,14.92,8.1,4.11,4.06,3.95,3.95,3.91]::numeric[],array[]::text[],array['25-1053.00','25-1043.00','25-1042.00']::text[],null),
  ('25-1042.00',8,5,36,0,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.3.b.6.p']::text[],array[17.16,15.93,13.15,12.92,7.74,4.39,4.36,4.18,3.81]::numeric[],array['Learning management system LMS']::text[],array['25-1051.00','25-1052.00','25-1053.00']::text[],null),
  ('25-1043.00',8,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.g']::text[],array[17.07,16.66,14.46,8.79,7.7,4.4,4.14,4.14,4.12]::numeric[],array[]::text[],array['25-1053.00','25-1041.00','25-1051.00']::text[],null),
  ('25-1051.00',7,5,18,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.h','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.l','4.A.3.b.6.p']::text[],array[16.89,15.25,12.52,8.41,4.43,4.16,4.16,4.15,3.77]::numeric[],array['Learning management system LMS']::text[],array['25-1042.00','25-1053.00','25-1054.00']::text[],null),
  ('25-1052.00',8,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.a.1.c','4.A.1.a.2.f','4.A.2.b.2.e','4.A.4.b.3.e','4.A.3.b.6.h']::text[],array[21.27,15.59,13.25,8.77,6.72,4.7,4.7,4.7,4.44]::numeric[],array['Learning management system LMS']::text[],array['25-1042.00','25-1054.00','25-1051.00']::text[],null),
  ('25-1053.00',8,5,36,2,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.p','4.A.3.b.6.h']::text[],array[19.87,16.05,13.44,7.74,4.24,4.06,4.06,4.04,3.96]::numeric[],array[]::text[],array['25-1043.00','25-1051.00','25-1041.00']::text[],null),
  ('25-1054.00',8,5,18,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.g']::text[],array[17.76,15.77,12.91,8.5,4.47,4.12,4.12,4.12,3.69]::numeric[],array['Learning management system LMS']::text[],array['25-1022.00','25-1051.00','25-1052.00']::text[],null),
  ('25-1061.00',8,5,18,2,array['4.A.2.b.3.a','4.A.2.a.1.c','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.p','4.A.1.a.1.r','4.A.2.a.1.b','4.A.2.b.2.l']::text[],array[21.46,19.31,14.45,9.19,4.43,4.41,4.35,4.09,4.09]::numeric[],array['Learning management system LMS']::text[],array['25-1067.00','25-1062.00','25-1125.00']::text[],null),
  ('25-1062.00',8,5,36,2,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.b.2.l','4.A.3.b.6.l','4.A.2.a.1.b','4.A.3.b.6.p','4.A.3.b.6.h']::text[],array[17.74,16.63,13.53,9.33,7.29,4.46,4.12,4.08,4.0]::numeric[],array['Learning management system LMS']::text[],array['25-1125.00','25-1061.00','25-1067.00']::text[],null),
  ('25-1063.00',8,5,36,0,array['4.A.2.b.3.a','4.A.2.a.1.c','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.p','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.h']::text[],array[16.61,16.17,12.83,8.46,4.45,4.41,4.15,4.15,3.97]::numeric[],array['Learning management system LMS']::text[],array['25-1011.00','25-1067.00','25-1065.00']::text[],null),
  ('25-1064.00',8,5,60,0,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.a.2.c','4.A.3.b.6.l','4.A.3.b.6.p','4.A.3.b.6.h','4.A.2.a.1.b']::text[],array[17.36,16.43,12.3,8.67,6.23,4.55,4.35,4.16,3.99]::numeric[],array['Geographic information system GIS systems']::text[],array['25-1051.00','25-1061.00','25-1067.00']::text[],null),
  ('25-1065.00',8,5,18,0,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.p','4.A.3.b.6.l','4.A.3.b.6.h']::text[],array[17.71,17.36,13.35,9.15,4.42,4.42,4.4,4.34,4.23]::numeric[],array['Learning management system LMS']::text[],array['25-1067.00','25-1112.00','25-1125.00']::text[],null),
  ('25-1066.00',8,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.p','4.A.4.b.6.j']::text[],array[20.38,16.06,12.35,8.77,7.95,3.98,3.98,3.9,3.82]::numeric[],array['Learning management system LMS']::text[],array['25-1067.00','25-1081.00','25-1113.00']::text[],null),
  ('25-1067.00',8,5,36,9,array['4.A.4.b.6.g','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.p','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.h']::text[],array[19.12,17.71,16.16,8.84,4.34,4.14,4.12,4.12,4.1]::numeric[],array['Learning management system LMS','Microsoft Office software']::text[],array['25-1061.00','25-1066.00','25-1065.00']::text[],null),
  ('25-1071.00',7,5,36,9,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.a.1.b','4.A.2.b.2.l','4.A.4.c.1.a']::text[],array[16.73,15.92,10.79,8.29,4.36,4.15,4.01,4.01,3.88]::numeric[],array['Learning management system LMS']::text[],array['25-1072.00','25-1193.00','25-1042.00']::text[],null),
  ('25-1072.00',7,5,36,2,array['4.A.2.a.1.c','4.A.4.b.6.g','4.A.2.b.3.a','4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.h','4.A.3.b.6.p']::text[],array[22.82,19.19,16.88,13.49,4.41,4.37,4.37,4.32,3.84]::numeric[],array['Learning management system LMS','Microsoft Office software']::text[],array['25-1071.00','29-1141.04','29-1141.00']::text[],null),
  ('25-1081.00',8,5,60,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.p','4.A.2.b.2.l','4.A.2.a.1.b','4.A.4.c.1.a']::text[],array[16.86,16.83,15.44,12.23,8.41,4.32,3.97,3.97,3.79]::numeric[],array['Learning management system LMS']::text[],array['25-9031.00','25-3011.00','25-9044.00']::text[],null),
  ('25-1082.00',8,5,60,1,array['4.A.2.b.3.a','4.A.2.a.1.c','4.A.4.b.3.b','4.A.4.b.6.g','4.A.2.b.2.l','4.A.3.b.6.l','4.A.3.b.6.p','4.A.2.a.1.b','4.A.3.b.6.h']::text[],array[18.07,17.37,13.17,13.07,10.28,8.72,4.69,4.5,4.2]::numeric[],array[]::text[],array['25-1081.00','25-9044.00','25-9031.00']::text[],null),
  ('25-1111.00',7,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.h','4.A.3.b.6.l','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.p']::text[],array[20.99,16.21,14.09,8.94,4.25,4.23,4.12,4.12,3.85]::numeric[],array['Learning management system LMS','Microsoft Office software']::text[],array['25-1112.00','25-1067.00','25-1065.00']::text[],null),
  ('25-1112.00',7,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.2.b.2.l','4.A.3.b.6.l','4.A.3.b.6.h','4.A.3.b.6.p','4.A.2.a.1.b']::text[],array[17.84,16.09,13.79,9.02,7.89,4.62,4.29,4.04,4.01]::numeric[],array['Learning management system LMS']::text[],array['25-1111.00','25-1065.00','25-1067.00']::text[],null),
  ('25-1113.00',8,5,60,2,array['4.A.4.b.6.g','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.p','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.h']::text[],array[17.56,17.53,16.64,8.91,4.48,4.32,4.19,4.19,3.92]::numeric[],array['Learning management system LMS']::text[],array['25-1067.00','25-1081.00','25-1066.00']::text[],null),
  ('25-1121.00',7,5,36,2,array['4.A.4.b.3.b','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.3.b.4.a','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.b.2.l','4.A.2.a.1.b']::text[],array[18.02,16.96,16.04,13.51,7.56,4.32,4.29,4.21,4.21]::numeric[],array['Learning management system LMS']::text[],array['25-3021.00','25-1123.00','25-9044.00']::text[],null),
  ('25-1122.00',7,5,36,9,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.a.1.b','4.A.2.b.2.l','4.A.2.b.1.j']::text[],array[18.8,14.61,13.79,9.36,4.62,4.4,4.37,4.37,4.12]::numeric[],array['Learning management system LMS','Microsoft Windows','Microsoft PowerPoint']::text[],array['25-1081.00','25-1067.00','25-1065.00']::text[],null),
  ('25-1123.00',8,5,60,1,array['4.A.4.b.3.b','4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.3.b.6.p','4.A.2.b.1.g','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.a.1.b']::text[],array[29.64,20.52,19.05,12.86,6.79,5.34,4.68,4.55,4.36]::numeric[],array['Learning management system LMS']::text[],array['25-1062.00','25-1124.00','25-1126.00']::text[],null),
  ('25-1124.00',8,5,36,2,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.3.b.6.p','4.A.2.b.1.j','4.A.2.a.1.b']::text[],array[21.42,16.88,10.96,9.12,8.32,4.65,4.39,4.02,4.02]::numeric[],array['Learning management system LMS']::text[],array['25-1123.00','25-1062.00','25-2031.00']::text[],null),
  ('25-1125.00',8,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.3.b','4.A.4.b.6.g','4.A.3.b.6.l','4.A.2.b.6.a','4.A.3.b.6.p','4.A.3.b.6.h','4.A.2.a.1.b']::text[],array[17.67,17.42,12.87,12.62,8.28,5.36,4.55,4.26,4.09]::numeric[],array['Learning management system LMS','Microsoft PowerPoint','Microsoft Excel']::text[],array['25-1062.00','25-1061.00','25-1067.00']::text[],null),
  ('25-1126.00',8,5,36,0,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.p','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.a.1.b','4.A.2.b.2.l']::text[],array[18.26,16.61,10.88,9.22,8.23,4.49,4.22,3.95,3.95]::numeric[],array['Learning management system LMS']::text[],array['25-1067.00','25-1062.00','25-1125.00']::text[],null),
  ('25-1192.00',7,5,36,4,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.b.2.l','4.A.2.a.1.b','4.A.3.b.6.h','4.A.1.a.2.f']::text[],array[17.95,16.84,15.33,8.99,4.54,4.42,4.42,4.35,4.11]::numeric[],array[]::text[],array['25-1193.00','25-1081.00','25-2023.00']::text[],null),
  ('25-1193.00',8,5,36,1,array['4.A.2.a.1.c','4.A.2.b.3.a','4.A.4.b.6.g','4.A.4.b.3.b','4.A.3.b.6.l','4.A.3.b.6.h','4.A.2.a.1.b','4.A.2.b.2.l','4.A.3.b.6.p']::text[],array[17.12,16.42,13.48,9.16,4.61,4.56,4.44,4.44,3.95]::numeric[],array['Learning management system LMS']::text[],array['25-1071.00','25-1192.00','25-1081.00']::text[],null),
  ('25-1194.00',5,3,60,4,array['4.A.4.b.3.b','4.A.2.a.1.c','4.A.1.a.2.f','4.A.2.b.2.l','4.A.3.b.6.h','4.A.3.b.6.o','4.A.2.b.1.j','4.A.4.b.6.g','4.A.2.b.3.a']::text[],array[17.01,13.0,8.98,8.23,4.27,4.27,4.13,3.93,3.9]::numeric[],array['Microsoft Office software']::text[],array['25-2032.00','25-2023.00','25-1032.00']::text[],null),
  ('25-2011.00',6,3,9,1,array['4.A.3.a.2.af','4.A.1.a.2.f','4.A.2.b.2.l','4.A.4.a.5.i','4.A.4.b.6.g','4.A.4.b.3.a','4.A.4.b.3.b','4.A.4.a.2.c','4.A.2.a.1.c']::text[],array[21.53,21.34,20.94,17.49,8.89,8.88,8.67,8.22,8.11]::numeric[],array[]::text[],array['25-2012.00','25-2055.00','25-2021.00']::text[],'UU 14/2005 pasal 9: guru wajib berkualifikasi minimal S1/D4, termasuk jenjang PAUD.'),
  ('25-2012.00',6,4,9,9,array['4.A.2.b.2.l','4.A.1.a.2.f','4.A.2.a.1.c','4.A.4.b.6.g','4.A.3.a.2.af','4.A.4.a.2.c','4.A.3.b.6.l','4.A.4.b.3.b','4.A.4.a.5.i']::text[],array[29.29,21.05,20.38,17.48,16.66,12.95,12.89,9.04,8.39]::numeric[],array[]::text[],array['25-2021.00','25-2011.00','25-2055.00']::text[],null),
  ('25-2021.00',6,4,9,9,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.1.a.2.f','4.A.4.b.6.g','4.A.3.b.6.l','4.A.3.a.2.af','4.A.4.b.3.b','4.A.4.a.2.c','4.A.4.a.2.f']::text[],array[29.53,25.6,20.85,13.76,13.26,12.33,9.47,8.88,8.09]::numeric[],array[]::text[],array['25-2031.00','25-2022.00','25-3011.00']::text[],null),
  ('25-2022.00',6,4,9,1,array['4.A.2.a.1.c','4.A.2.b.2.l','4.A.1.a.2.f','4.A.3.b.6.l','4.A.4.b.6.g','4.A.4.b.3.b','4.A.4.a.2.c','4.A.3.a.2.af','4.A.4.a.2.f']::text[],array[25.07,22.26,20.18,11.69,11.69,8.66,7.81,7.81,7.33]::numeric[],array[]::text[],array['25-2031.00','25-2021.00','25-3011.00']::text[],null),
  ('25-2023.00',6,4,4,4,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.1.a.2.f','4.A.3.b.6.l','4.A.4.b.6.g','4.A.4.a.2.c','4.A.4.a.2.f','4.A.4.b.3.b','4.A.3.a.2.af']::text[],array[24.21,21.11,20.13,12.47,12.34,8.06,7.63,4.53,4.52]::numeric[],array[]::text[],array['25-2032.00','25-1194.00','25-2031.00']::text[],null),
  ('25-2031.00',6,4,0,2,array['4.A.2.a.1.c','4.A.2.b.2.l','4.A.1.a.2.f','4.A.3.b.6.l','4.A.4.b.6.g','4.A.4.a.2.c','4.A.4.a.2.f','4.A.2.b.2.e','4.A.4.b.3.b']::text[],array[23.05,22.16,17.81,11.53,11.15,7.32,7.13,4.32,4.32]::numeric[],array[]::text[],array['25-2022.00','25-2021.00','25-3041.00']::text[],null),
  ('25-2032.00',6,4,36,4,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.1.a.2.f','4.A.4.b.6.g','4.A.4.b.3.b','4.A.4.a.2.c','4.A.2.b.3.a','4.A.4.a.2.f','4.A.2.b.2.e']::text[],array[23.66,20.51,19.96,11.89,8.88,7.68,7.4,7.03,4.47]::numeric[],array[]::text[],array['25-1194.00','25-2023.00','25-9031.00']::text[],null),
  ('25-2051.00',6,5,9,9,array['4.A.2.b.2.l','4.A.3.b.6.l','4.A.4.b.3.a','4.A.1.a.2.f','4.A.4.a.5.i','4.A.3.a.2.af','4.A.2.a.1.c','4.A.4.b.6.g','4.A.4.a.2.f']::text[],array[38.87,15.88,13.93,13.38,12.35,12.34,8.89,8.65,8.46]::numeric[],array[]::text[],array['25-2055.00','25-2056.00','25-2057.00']::text[],null),
  ('25-2055.00',6,4,24,9,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.3.b.6.l','4.A.1.a.2.f','4.A.4.a.2.f','4.A.3.a.2.af','4.A.4.b.6.g','4.A.2.b.3.a','4.A.3.b.6.h']::text[],array[18.0,15.0,15.0,12.0,9.0,6.0,6.0,3.0,3.0]::numeric[],array[]::text[],array['25-2056.00','25-2057.00','25-2051.00']::text[],null),
  ('25-2056.00',6,4,18,2,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.4.b.3.a','4.A.1.a.2.f','4.A.4.a.2.f','4.A.3.b.6.l','4.A.4.b.6.g','4.A.3.a.2.af','4.A.3.b.6.h']::text[],array[34.69,24.35,13.4,13.21,12.85,9.0,8.96,8.74,4.69]::numeric[],array[]::text[],array['25-2055.00','25-2058.00','25-2057.00']::text[],null),
  ('25-2057.00',6,4,9,9,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.4.b.6.g','4.A.1.a.2.f','4.A.4.b.3.a','4.A.4.a.2.f','4.A.3.b.6.l','4.A.4.b.3.b','4.A.3.a.2.af']::text[],array[49.73,19.65,16.49,15.48,12.9,12.54,12.17,11.16,8.05]::numeric[],array[]::text[],array['25-2055.00','25-2056.00','25-2058.00']::text[],null),
  ('25-2058.00',6,4,9,2,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.4.b.6.g','4.A.3.b.6.l','4.A.1.a.2.f','4.A.4.a.2.f','4.A.4.b.3.a','4.A.4.b.3.b','4.A.4.a.2.c']::text[],array[36.94,19.58,15.97,15.42,15.07,12.54,12.42,10.62,8.46]::numeric[],array['Microsoft Outlook','Microsoft Excel']::text[],array['25-2055.00','25-2056.00','25-2057.00']::text[],null),
  ('25-2059.01',6,5,9,2,array['4.A.2.a.1.c','4.A.4.b.3.f','4.A.3.b.6.l','4.A.4.b.6.g','4.A.2.b.2.e','4.A.4.a.5.i','4.A.4.a.2.f','4.A.3.b.6.h','4.A.2.b.2.l']::text[],array[12.84,9.61,8.9,8.25,4.67,4.65,4.25,4.16,4.1]::numeric[],array[]::text[],array['25-2055.00','25-2058.00','25-2056.00']::text[],null),
  ('25-3011.00',6,4,18,2,array['4.A.2.a.1.c','4.A.2.b.2.l','4.A.3.b.6.l','4.A.4.b.6.g','4.A.4.a.2.f','4.A.4.b.3.b','4.A.1.a.2.f','4.A.3.a.2.af','4.A.3.b.6.h']::text[],array[27.65,22.48,11.54,10.06,9.69,8.26,8.05,4.19,4.1]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['25-2021.00','25-2031.00','25-3041.00']::text[],null),
  ('25-3021.00',6,3,18,4,array['4.A.2.b.2.l','4.A.2.a.1.c','4.A.3.b.6.l','4.A.1.a.2.f','4.A.4.b.3.b','4.A.3.b.6.h','4.A.4.b.3.a','4.A.4.b.3.e','4.A.4.a.2.f']::text[],array[22.05,20.76,11.84,11.76,4.49,4.25,3.9,3.85,3.84]::numeric[],array[]::text[],array['25-2031.00','25-2021.00','25-3041.00']::text[],null),
  ('25-3031.00',6,4,9,0,array['4.A.4.b.3.b','4.A.1.a.2.f','4.A.4.b.3.a','4.A.3.b.6.h','4.A.4.a.5.i','4.A.4.a.5.j','4.A.3.a.3.e','4.A.3.b.1.e','4.A.4.b.6.g']::text[],array[17.77,13.41,8.62,4.53,4.46,4.31,4.13,4.13,4.01]::numeric[],array[]::text[],array['25-3011.00','25-2058.00','25-2012.00']::text[],'UU 14/2005 pasal 9: kualifikasi guru minimal S1/D4, tidak dibedakan untuk guru pengganti.'),
  ('25-3041.00',5,3,4,1,array['4.A.4.b.3.b','4.A.2.a.1.c','4.A.3.b.6.l','4.A.4.b.6.g','4.A.4.a.2.h','4.A.2.b.3.a','4.A.4.a.2.f','4.A.1.a.2.f','4.A.2.b.5.b']::text[],array[20.57,14.67,10.98,6.7,4.73,4.18,4.15,4.14,3.95]::numeric[],array[]::text[],array['25-2031.00','25-3011.00','25-2021.00']::text[],null),
  ('25-4011.00',7,5,18,4,array['4.A.3.b.6.l','4.A.3.b.2.f','4.A.1.b.2.j','4.A.4.a.5.j','4.A.1.a.1.d','4.A.2.b.2.f','4.A.3.a.2.h','4.A.2.b.6.a','4.A.2.b.3.a']::text[],array[9.54,9.41,8.11,4.77,4.71,4.6,4.32,3.87,3.57]::numeric[],array['Archivists'' Toolkit','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['25-4022.00','25-4012.00','15-1299.03']::text[],null),
  ('25-4012.00',7,5,60,9,array['4.A.1.b.2.e','4.A.2.b.6.a','4.A.3.a.2.a','4.A.2.b.2.f','4.A.2.b.3.a','4.A.4.a.3.b','4.A.1.b.2.j','4.A.4.a.7.b','4.A.2.a.1.h']::text[],array[11.43,6.58,4.35,4.15,4.03,3.94,3.84,3.84,3.76]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['25-4011.00','25-4013.00','25-4022.00']::text[],null),
  ('25-4013.00',6,4,60,9,array['4.A.3.a.2.h','4.A.2.b.3.a','4.A.3.a.2.a','4.A.1.b.2.j','4.A.3.b.6.h','4.A.2.b.1.a','4.A.4.c.1.a','4.A.3.b.6.e','4.A.3.b.1.f']::text[],array[20.41,11.28,11.26,8.39,8.05,6.2,4.27,4.15,4.01]::numeric[],array[]::text[],array['25-4012.00','27-1027.00','25-4011.00']::text[],null),
  ('25-4022.00',7,5,18,1,array['4.A.4.a.5.j','4.A.4.b.3.e','4.A.4.c.1.a','4.A.1.a.1.d','4.A.3.b.6.h','4.A.2.b.1.b','4.A.2.b.1.j','4.A.4.a.2.c','4.A.2.b.6.a']::text[],array[11.84,11.41,8.26,7.93,7.69,7.58,4.19,3.99,3.86]::numeric[],array['Springshare LibGuides','Microsoft Office software','Microsoft Excel']::text[],array['25-4031.00','25-4011.00','25-1082.00']::text[],null),
  ('25-4031.00',5,3,9,2,array['4.A.4.c.1.a','4.A.3.a.1.j','4.A.3.b.6.h','4.A.3.b.6.l','4.A.4.a.3.b','4.A.4.a.5.j','4.A.4.a.2.b','4.A.4.a.7.a','4.A.3.b.5.c']::text[],array[31.22,11.37,11.34,6.84,4.27,4.18,3.9,3.79,3.73]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['15-1299.03']::text[],null),
  ('25-9021.00',7,5,18,2,array['4.A.4.a.6.c','4.A.4.b.6.g','4.A.4.b.3.a','4.A.4.a.2.c','4.A.1.a.1.d','4.A.1.a.1.n','4.A.2.a.1.j','4.A.4.a.6.a','4.A.3.b.6.h']::text[],array[7.76,4.28,4.27,4.24,4.08,4.04,4.04,4.0,3.88]::numeric[],array[]::text[],array['25-1041.00','25-1194.00']::text[],null),
  ('25-9031.00',7,5,36,2,array['4.A.3.b.6.l','4.A.4.b.6.g','4.A.2.a.1.b','4.A.2.b.3.a','4.A.2.a.1.c','4.A.2.a.1.d','4.A.4.b.3.d','4.A.1.a.2.f','4.A.3.b.6.g']::text[],array[25.26,20.78,15.67,6.67,6.0,4.51,4.1,4.08,3.88]::numeric[],array['Articulate Storyline','TechSmith Camtasia','Learning management system LMS','Microsoft PowerPoint','Microsoft Outlook']::text[],array['25-1081.00','25-2023.00','25-2021.00']::text[],null),
  ('25-9042.00',5,3,4,1,array['4.A.1.a.2.f','4.A.3.b.6.h','4.A.3.b.6.l','4.A.4.b.3.b','4.A.4.b.3.a','4.A.3.a.1.c','4.A.3.a.2.af','4.A.4.b.3.e','4.A.4.a.2.f']::text[],array[21.26,12.29,11.57,8.67,8.5,8.18,7.44,4.24,4.21]::numeric[],array[]::text[],array['25-9043.00','25-3041.00','25-2058.00']::text[],null),
  ('25-9043.00',5,3,2,1,array['4.A.1.a.2.f','4.A.3.b.6.h','4.A.3.b.6.l','4.A.3.a.2.af','4.A.4.a.5.i','4.A.4.b.3.a','4.A.4.b.3.b','4.A.2.b.2.l','4.A.3.a.1.c']::text[],array[20.13,11.43,9.9,9.77,8.7,8.29,7.99,7.67,6.52]::numeric[],array['Microsoft Office software']::text[],array['25-2055.00','25-2058.00','25-2056.00']::text[],null),
  ('25-9044.00',6,5,2,2,array['4.A.4.b.3.b','4.A.3.b.6.l','4.A.2.a.1.c','4.A.4.a.2.b','4.A.4.b.6.g','4.A.4.a.2.c','4.A.2.a.1.b','4.A.4.b.3.e','4.A.1.a.2.f']::text[],array[17.41,15.92,12.35,9.85,8.16,6.79,3.78,3.75,3.75]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['25-3041.00','25-2031.00','25-1081.00']::text[],null),
  ('27-1011.00',6,4,60,2,array['4.A.2.b.2.o','4.A.1.a.1.a','4.A.4.a.2.h','4.A.4.a.1.a','4.A.4.a.2.j','4.A.2.b.1.d','4.A.3.b.6.l','4.A.4.b.3.d','4.A.2.b.2.t']::text[],array[16.27,8.26,4.61,4.53,4.31,4.24,4.15,3.97,3.91]::numeric[],array['Figma','Adobe After Effects','Adobe Creative Cloud software','Adobe InDesign','Adobe Illustrator']::text[],array['27-1024.00','27-1014.00','27-2012.00']::text[],null),
  ('27-1012.00',2,3,18,4,array['4.A.3.a.2.ab','4.A.3.a.2.ap','4.A.4.a.6.c','4.A.3.a.2.aj','4.A.2.b.2.o','4.A.2.b.1.j','4.A.2.b.2.t','4.A.3.a.2.as','4.A.2.a.4.e']::text[],array[9.06,7.72,7.24,7.19,7.03,4.91,4.64,4.39,4.06]::numeric[],array[]::text[],array['27-1013.00','51-6092.00']::text[],null),
  ('27-1013.00',5,3,18,2,array['4.A.2.b.2.o','4.A.3.a.2.ab','4.A.3.a.2.h','4.A.3.a.2.as','4.A.4.a.8.a','4.A.3.a.2.ag','4.A.2.b.2.t','4.A.3.a.2.aj','4.A.4.a.2.h']::text[],array[18.07,15.53,7.85,7.66,6.79,4.47,4.26,4.16,3.86]::numeric[],array['Autodesk Maya','Adobe Illustrator','Adobe Photoshop']::text[],array['27-1014.00','27-1024.00','27-1012.00']::text[],null),
  ('27-1014.00',6,4,18,1,array['4.A.2.b.2.o','4.A.2.b.2.t','4.A.3.b.5.a','4.A.3.b.5.c','4.A.3.a.3.f','4.A.3.a.2.d','4.A.3.a.2.at','4.A.3.b.1.f','4.A.4.b.4.j']::text[],array[32.55,8.23,4.0,4.0,3.54,3.54,3.54,3.36,4.28]::numeric[],array['SideFX Houdini','Unreal Technology Unreal Engine','Unity Technologies Unity','Maxon Cinema 4D','Figma']::text[],array['27-1024.00','27-4032.00','27-1011.00']::text[],null),
  ('27-1021.00',6,4,36,4,array['4.A.2.a.1.g','4.A.2.b.2.t','4.A.4.a.2.h','4.A.2.b.2.o','4.A.3.b.2.f','4.A.1.a.1.n','4.A.2.a.1.e','4.A.4.a.1.a','4.A.2.b.2.e']::text[],array[8.16,7.95,7.93,7.59,7.19,6.72,4.08,3.96,3.75]::numeric[],array['Figma','Dassault Systemes SolidWorks','Adobe Creative Cloud software','Adobe Illustrator','Adobe Photoshop']::text[],array['51-4061.00','51-6092.00','51-4062.00']::text[],null),
  ('27-1022.00',6,3,60,4,array['4.A.2.b.2.t','4.A.4.a.2.h','4.A.2.b.1.a','4.A.4.a.6.c','4.A.3.a.2.aj','4.A.1.a.2.h','4.A.1.b.2.c','4.A.3.b.6.l','4.A.2.b.2.o']::text[],array[15.33,11.21,8.5,7.93,7.46,7.15,6.74,4.81,4.81]::numeric[],array['Adobe Creative Cloud software','Adobe InDesign','Adobe Illustrator','Adobe Photoshop','Microsoft PowerPoint']::text[],array['51-6092.00','27-1021.00','27-1012.00']::text[],null),
  ('27-1023.00',2,2,18,4,array['4.A.2.b.2.t','4.A.3.a.2.ak','4.A.3.a.2.h','4.A.3.a.1.c','4.A.4.a.2.j','4.A.2.b.1.j','4.A.4.a.5.d','4.A.3.a.1.q','4.A.3.a.2.ab']::text[],array[8.34,8.28,8.07,7.7,4.58,4.5,4.4,4.4,4.32]::numeric[],array[]::text[],array['27-1012.00','27-1022.00','41-2031.00']::text[],null),
  ('27-1024.00',6,4,36,4,array['4.A.2.b.2.o','4.A.1.a.1.a','4.A.4.a.2.h','4.A.1.a.1.n','4.A.3.a.3.f','4.A.4.c.1.a','4.A.4.a.2.j','4.A.2.b.3.a','4.A.3.b.6.h']::text[],array[42.11,8.75,8.65,8.5,4.45,4.45,4.28,4.25,4.1]::numeric[],array['Figma','Canva','Adobe Premiere Pro','Cascading style sheets CSS','Adobe After Effects']::text[],array['27-1014.00','27-1011.00','15-1255.00']::text[],null),
  ('27-1025.00',6,4,18,18,array['4.A.2.b.3.a','4.A.3.b.2.b','4.A.4.a.2.j','4.A.2.b.2.o','4.A.1.a.1.j','4.A.1.a.1.b','4.A.1.b.2.e','4.A.2.b.1.j','4.A.1.b.3.b']::text[],array[13.11,12.99,9.08,9.06,7.36,4.44,4.42,3.96,3.88]::numeric[],array['Chaos Enscape','Trimble SketchUp Pro','Autodesk Revit','Adobe Creative Cloud software','Adobe InDesign']::text[],array['27-1021.00','27-1012.00','27-1022.00']::text[],null),
  ('27-1026.00',5,3,9,1,array['4.A.3.a.2.h','4.A.4.b.3.d','4.A.2.b.2.o','4.A.4.a.2.h','4.A.4.a.2.e','4.A.2.b.2.c','4.A.2.b.2.t','4.A.3.b.6.h','4.A.2.b.1.j']::text[],array[32.23,7.66,7.56,7.38,7.34,4.36,3.93,3.83,3.8]::numeric[],array['Microsoft Excel']::text[],array['41-2031.00','41-3011.00','27-1022.00']::text[],null),
  ('27-1027.00',7,5,36,2,array['4.A.2.b.2.o','4.A.4.a.2.h','4.A.2.b.2.t','4.A.1.b.2.f','4.A.2.b.1.j','4.A.1.a.1.a','4.A.2.b.1.d','4.A.4.a.1.a','4.A.4.a.2.j']::text[],array[13.61,12.48,11.7,8.15,7.66,4.76,4.76,4.62,4.52]::numeric[],array['Autodesk Revit','Adobe Creative Cloud software','Adobe Illustrator','Adobe Photoshop','Autodesk AutoCAD']::text[],array['27-1024.00','27-1013.00','27-1011.00']::text[],null),
  ('27-2012.00',6,4,36,2,array['4.A.2.b.1.d','4.A.4.a.2.h','4.A.2.b.1.g','4.A.2.b.2.r','4.A.4.a.7.b','4.A.2.b.3.a','4.A.1.a.1.a','4.A.3.b.6.g','4.A.4.a.8.a']::text[],array[12.04,7.92,7.72,6.79,6.6,4.27,4.2,3.98,3.94]::numeric[],array['Adobe Premiere Pro','Adobe After Effects','Adobe Creative Cloud software','Adobe Photoshop','Microsoft PowerPoint']::text[],array['27-2012.05','27-2012.03','27-4032.00']::text[],null),
  ('27-2012.03',6,4,36,2,array['4.A.2.b.2.r','4.A.3.a.3.j','4.A.3.b.5.c','4.A.3.b.6.h','4.A.4.a.3.b','4.A.2.b.1.k','4.A.2.b.2.c','4.A.2.b.1.j','4.A.1.a.1.w']::text[],array[10.98,7.71,4.42,4.18,4.15,4.02,3.81,3.59,3.52]::numeric[],array['TikTok','Google Analytics','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['27-2012.05','27-2012.00','15-1299.09']::text[],null),
  ('27-2012.04',6,4,36,9,array['4.A.4.b.3.b','4.A.4.a.8.a','4.A.4.a.7.b','4.A.3.b.6.h','4.A.1.a.1.a','4.A.4.a.2.h','4.A.1.a.2.h','4.A.4.c.2.a','4.A.4.b.4.j']::text[],array[6.38,4.38,4.07,3.97,3.65,3.65,3.43,16.25,15.34]::numeric[],array['Salesforce software','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['13-1011.00','27-2012.00','27-2041.00']::text[],null),
  ('27-2012.05',6,4,18,2,array['4.A.4.a.2.h','4.A.3.a.3.e','4.A.2.b.1.d','4.A.4.a.8.a','4.A.3.a.2.at','4.A.2.b.2.o','4.A.1.a.2.a','4.A.3.a.3.j','4.A.1.b.2.g']::text[],array[6.74,4.69,4.54,4.52,4.52,4.19,4.18,4.13,4.0]::numeric[],array['Microsoft Office software']::text[],array['27-2012.03','27-2012.00','27-4032.00']::text[],null),
  ('27-2041.00',7,4,60,2,array['4.A.2.b.2.t','4.A.1.a.1.a','4.A.4.a.8.a','4.A.2.b.2.r','4.A.2.b.2.o','4.A.4.a.7.b','4.A.4.a.2.h','4.A.2.b.3.a','4.A.3.a.3.e']::text[],array[53.81,8.08,7.23,4.52,3.86,3.86,3.85,3.0,3.0]::numeric[],array[]::text[],array['25-1121.00','27-2012.00','27-2012.04']::text[],null),
  ('27-3011.00',5,4,18,2,array['4.A.4.a.3.b','4.A.1.a.1.k','4.A.2.b.2.r','4.A.4.a.6.c','4.A.3.a.3.e','4.A.2.b.1.g','4.A.4.a.8.a','4.A.3.b.6.h','4.A.3.b.6.p']::text[],array[29.08,11.98,8.35,6.94,4.53,4.36,4.35,4.33,4.05]::numeric[],array['Adobe Audition','Microsoft Office software']::text[],array['27-3023.00','27-2012.00','27-2012.03']::text[],null),
  ('27-3023.00',6,4,24,9,array['4.A.2.b.2.r','4.A.1.a.1.k','4.A.4.a.3.b','4.A.3.b.6.l','4.A.2.b.1.g','4.A.3.a.3.e','4.A.4.a.4.a','4.A.3.a.3.j','4.A.1.a.1.w']::text[],array[26.76,24.86,21.18,11.24,8.4,7.38,4.38,3.94,3.59]::numeric[],array[]::text[],array['27-3011.00','27-3041.00','27-3043.05']::text[],null),
  ('27-3031.00',6,4,18,2,array['4.A.2.b.2.c','4.A.3.b.6.p','4.A.4.a.4.a','4.A.4.a.3.b','4.A.4.a.2.e','4.A.3.b.6.l','4.A.2.b.1.g','4.A.1.a.1.n','4.A.2.b.2.p']::text[],array[14.74,8.79,8.46,7.91,7.7,7.66,3.9,3.76,3.64]::numeric[],array['Canva','WordPress','Adobe Creative Cloud software','Adobe InDesign','Adobe Photoshop']::text[],array['11-2032.00','11-2011.00','13-1161.00']::text[],null),
  ('27-3041.00',6,4,36,4,array['4.A.2.b.1.g','4.A.2.b.2.r','4.A.2.b.2.o','4.A.4.a.2.h','4.A.2.a.2.a','4.A.3.b.6.l','4.A.4.a.2.c','4.A.1.a.1.q','4.A.4.a.7.b']::text[],array[23.58,8.35,7.89,7.66,4.48,4.13,4.13,3.15,3.12]::numeric[],array['Content management systems CMS','Hypertext markup language HTML','Adobe Photoshop','Microsoft PowerPoint','Microsoft Outlook']::text[],array['27-4032.00','27-3023.00','27-3043.05']::text[],null),
  ('27-3042.00',5,4,36,9,array['4.A.2.b.1.g','4.A.1.a.1.b','4.A.2.b.2.o','4.A.2.a.2.c','4.A.3.b.6.h','4.A.2.b.2.r','4.A.1.a.1.t','4.A.3.b.6.l','4.A.2.b.6.b']::text[],array[12.4,7.57,7.54,4.72,4.23,4.01,3.95,3.94,3.81]::numeric[],array['Atlassian Confluence','Atlassian JIRA','Extensible markup language XML','Microsoft Visio','Microsoft SharePoint']::text[],array['15-1299.03','27-3041.00']::text[],null),
  ('27-3043.00',5,4,36,1,array['4.A.3.b.6.p','4.A.2.b.1.g','4.A.2.b.2.c','4.A.4.a.1.a','4.A.4.a.2.j','4.A.1.a.2.h','4.A.1.a.1.n','4.A.1.a.1.q','4.A.2.b.3.a']::text[],array[26.61,6.0,4.46,4.24,4.23,3.71,3.57,3.0,3.0]::numeric[],array['TikTok','Canva','Adobe Premiere Pro','Adobe Creative Cloud software','Adobe Photoshop']::text[],array['27-3043.05','27-3031.00','41-3011.00']::text[],null),
  ('27-3043.05',5,4,18,1,array['4.A.3.b.6.p','4.A.2.b.1.g','4.A.2.b.2.r','4.A.2.b.3.a','4.A.4.a.2.h','4.A.1.a.1.q','4.A.4.a.6.c','4.A.4.b.3.d','4.A.4.a.8.a']::text[],array[29.86,8.93,4.55,4.35,4.23,3.47,3.0,2.84,2.72]::numeric[],array[]::text[],array['27-3043.00','27-3041.00','27-3023.00']::text[],null),
  ('27-3091.00',6,4,18,2,array['4.A.4.a.1.c','4.A.2.a.2.c','4.A.2.a.2.a','4.A.1.a.2.g','4.A.3.a.1.k','4.A.2.b.3.a','4.A.4.a.3.b','4.A.2.b.1.g','4.A.4.b.3.d']::text[],array[29.39,8.69,8.65,4.86,4.86,4.41,3.96,3.93,3.8]::numeric[],array['Productivity software','Microsoft PowerPoint','Microsoft Office software','Microsoft Excel']::text[],array['29-1127.00','25-1124.00','25-3011.00']::text[],null),
  ('27-4011.00',5,3,18,4,array['4.A.3.b.5.c','4.A.3.a.3.e','4.A.2.b.1.k','4.A.3.b.6.h','4.A.3.a.2.at','4.A.4.a.3.b','4.A.4.a.2.g','4.A.3.b.1.f','4.A.3.a.3.j']::text[],array[10.61,10.55,10.36,9.6,6.68,5.98,4.08,3.71,3.69]::numeric[],array['Microsoft Teams','Zoom','Microsoft Office software']::text[],array['27-4012.00','27-4014.00','27-4031.00']::text[],null),
  ('27-4012.00',5,3,36,9,array['4.A.3.a.3.j','4.A.1.a.2.a','4.A.3.b.6.h','4.A.3.a.3.e','4.A.3.b.5.c','4.A.4.a.2.g','4.A.1.a.1.b','4.A.2.b.5.b','4.A.2.b.1.k']::text[],array[35.64,13.07,12.23,11.69,8.54,4.52,4.09,4.09,4.01]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['27-4011.00','17-3024.01','51-8012.00']::text[],null),
  ('27-4014.00',2,3,18,4,array['4.A.3.a.3.e','4.A.2.b.1.k','4.A.4.a.2.h','4.A.4.a.2.g','4.A.2.b.1.j','4.A.3.b.6.h','4.A.3.a.2.s','4.A.3.b.1.f']::text[],array[22.32,15.9,4.83,4.5,4.48,4.2,3.9,3.62]::numeric[],array[]::text[],array['27-4011.00','27-4012.00','27-4015.00']::text[],null),
  ('27-4015.00',5,3,9,9,array['4.A.3.a.2.at','4.A.3.a.1.f','4.A.1.b.2.g','4.A.1.a.1.f','4.A.1.b.2.l','4.A.3.a.2.ah','4.A.3.a.2.i','4.A.3.a.2.s','4.A.3.a.2.t']::text[],array[12.0,6.0,3.0,3.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['Microsoft Office software']::text[],array['51-2022.00']::text[],null),
  ('27-4021.00',5,3,18,4,array['4.A.3.a.2.at','4.A.3.a.3.e','4.A.2.b.1.d','4.A.2.b.1.j','4.A.3.b.1.f','4.A.4.c.1.e','4.A.2.b.2.o','4.A.3.a.2.as','4.A.3.b.6.h']::text[],array[31.45,9.49,9.34,7.85,7.67,7.66,4.68,4.57,4.5]::numeric[],array['Adobe Photoshop Lightroom','Adobe Photoshop']::text[],array['27-1013.00','27-1024.00','27-1014.00']::text[],null),
  ('27-4031.00',5,3,9,1,array['4.A.3.a.3.e','4.A.3.a.2.at','4.A.2.b.1.d','4.A.3.a.3.j','4.A.2.b.1.k','4.A.4.a.2.h','4.A.1.b.2.f','4.A.2.b.1.j','4.A.1.a.1.b']::text[],array[13.26,12.76,8.7,7.75,4.72,4.45,4.33,4.31,4.27]::numeric[],array['TikTok','Video editing software','Adobe Premiere Pro','Adobe After Effects','Apple Final Cut Pro']::text[],array['27-4012.00','27-4011.00','27-2012.05']::text[],null),
  ('27-4032.00',6,4,36,2,array['4.A.2.b.1.k','4.A.2.b.2.r','4.A.4.a.2.h','4.A.3.a.3.j','4.A.1.b.1.a','4.A.2.a.2.a','4.A.2.b.2.o','4.A.4.a.2.c','4.A.3.a.3.e']::text[],array[35.16,8.94,7.77,4.53,4.31,4.16,4.11,4.02,4.02]::numeric[],array['DaVinci Resolve','TikTok','Video editing software','Adobe Premiere Pro','Adobe After Effects']::text[],array['27-3041.00','27-2012.00','27-1014.00']::text[],null),
  ('29-1011.00',8,5,18,2,array['4.A.1.b.2.i','4.A.1.a.1.l','4.A.3.b.6.k','4.A.4.b.6.a','4.A.4.a.5.b','4.A.2.b.1.f','4.A.2.a.4.f','4.A.4.a.2.d','4.A.4.a.5.a']::text[],array[9.83,9.81,9.73,9.3,4.91,4.91,4.73,4.34,4.34]::numeric[],array[]::text[],array['29-1243.00','29-1242.00','29-1217.00']::text[],null),
  ('29-1021.00',8,5,18,1,array['4.A.4.a.5.l','4.A.3.a.3.d','4.A.2.a.3.d','4.A.1.b.2.i','4.A.4.a.5.c','4.A.2.b.2.a','4.A.2.b.1.f','4.A.2.b.2.k','4.A.4.b.6.a']::text[],array[33.4,18.47,4.91,4.77,4.71,4.58,4.57,4.5,4.5]::numeric[],array[]::text[],array['29-1022.00','29-1024.00','29-1023.00']::text[],null),
  ('29-1022.00',8,5,60,2,array['4.A.4.a.5.l','4.A.4.a.5.c','4.A.4.a.2.d','4.A.2.a.4.f','4.A.4.a.5.g']::text[],array[38.09,4.76,4.66,4.63,4.16]::numeric[],array[]::text[],array['29-1243.00','29-1242.00','29-1024.00']::text[],null),
  ('29-1023.00',8,5,18,4,array['4.A.3.a.2.x','4.A.4.a.1.e','4.A.1.b.2.i','4.A.2.b.1.f','4.A.2.a.4.f','4.A.4.b.6.a','4.A.3.b.6.k','4.A.4.b.3.f','4.A.4.a.2.d']::text[],array[9.8,9.57,4.93,4.93,4.9,4.77,4.77,4.76,4.62]::numeric[],array[]::text[],array['29-1021.00','29-1024.00','29-1243.00']::text[],null),
  ('29-1024.00',8,5,18,9,array['4.A.4.a.5.l','4.A.1.b.2.i','4.A.3.a.2.x','4.A.4.a.2.d','4.A.2.b.2.k']::text[],array[24.67,14.28,13.77,4.63,4.62]::numeric[],array[]::text[],array['29-1022.00','29-1021.00','29-1023.00']::text[],null),
  ('29-1031.00',6,5,18,2,array['4.A.1.a.2.e','4.A.4.b.3.f','4.A.4.b.6.a','4.A.2.a.4.f','4.A.2.b.2.d','4.A.1.a.2.k','4.A.4.b.6.f','4.A.3.b.6.g','4.A.1.b.2.c']::text[],array[13.3,10.07,8.98,8.9,7.5,6.81,6.62,5.12,4.96]::numeric[],array[]::text[],array['29-2051.00','29-1215.00','29-1221.00']::text[],null),
  ('29-1041.00',8,5,0,1,array['4.A.4.a.5.l','4.A.1.b.2.a','4.A.2.a.4.f','4.A.2.b.2.a','4.A.4.a.5.f','4.A.4.b.3.f','4.A.1.a.2.e','4.A.4.a.5.a','4.A.4.a.2.d']::text[],array[8.67,5.0,4.95,4.95,4.81,4.71,4.57,4.52,4.52]::numeric[],array['Microsoft Edge','Apple Safari','Mozilla Firefox','Web browser software']::text[],array['29-1241.00','29-1243.00','29-1216.00']::text[],null),
  ('29-1051.00',8,5,9,2,array['4.A.2.a.4.d','4.A.3.b.6.k','4.A.3.a.1.a','4.A.2.a.2.e','4.A.2.a.4.j','4.A.4.a.1.e','4.A.4.b.6.a','4.A.2.a.4.f','4.A.4.a.2.d']::text[],array[9.14,8.32,7.98,4.9,4.71,4.68,4.68,4.43,4.25]::numeric[],array[]::text[],array['29-1214.00','29-1215.00','29-1216.00']::text[],null),
  ('29-1122.00',7,5,9,2,array['4.A.2.b.2.a','4.A.2.b.2.n','4.A.4.b.3.f','4.A.4.a.5.i','4.A.2.a.1.f','4.A.2.a.4.f','4.A.3.b.6.k','4.A.3.b.6.f','4.A.1.a.2.e']::text[],array[8.97,8.5,8.36,7.7,4.77,4.77,4.71,4.45,4.45]::numeric[],array[]::text[],array['29-1123.00','31-2021.00','29-1229.04']::text[],null),
  ('29-1123.00',7,5,4,1,array['4.A.3.b.6.k','4.A.4.a.5.a','4.A.1.b.2.i','4.A.2.a.4.f','4.A.2.b.2.a','4.A.4.c.1.a','4.A.4.a.1.e','4.A.4.a.5.b','4.A.4.b.3.f']::text[],array[18.7,12.55,9.4,9.38,9.36,9.0,8.78,8.57,8.42]::numeric[],array[]::text[],array['31-2021.00','29-1229.04','29-1122.00']::text[],null),
  ('29-1124.00',5,3,18,9,array['4.A.4.a.5.c','4.A.3.a.3.d','4.A.4.a.2.d','4.A.4.a.5.k','4.A.3.a.1.a','4.A.4.a.5.l','4.A.2.a.3.d','4.A.2.a.2.e','4.A.3.b.1.f']::text[],array[13.8,13.75,9.12,9.04,7.71,4.89,4.85,4.82,4.78]::numeric[],array[]::text[],array['29-2031.00','29-2034.00','29-1126.00']::text[],null),
  ('29-1126.00',5,3,9,2,array['4.A.4.b.3.f','4.A.4.a.5.g','4.A.4.a.2.d','4.A.1.b.2.a','4.A.3.b.4.f','4.A.4.a.5.k','4.A.1.a.2.e','4.A.3.a.2.k','4.A.3.a.3.d']::text[],array[16.72,14.68,14.23,12.44,9.18,8.81,8.79,4.77,4.77]::numeric[],array[]::text[],array['29-2031.00','29-2043.00','29-1141.01']::text[],null),
  ('29-1127.00',7,5,18,2,array['4.A.4.b.3.f','4.A.2.b.2.a','4.A.4.a.2.d','4.A.3.b.6.f','4.A.4.b.3.b','4.A.3.b.6.c','4.A.2.b.2.l','4.A.4.a.5.i','4.A.2.a.4.f']::text[],array[17.68,13.61,13.48,9.49,8.14,7.43,7.37,7.37,4.88]::numeric[],array[]::text[],array['29-1122.00','29-1181.00']::text[],null),
  ('29-1128.00',6,4,9,2,array['4.A.4.b.3.f','4.A.1.b.2.a','4.A.3.a.3.d','4.A.3.b.4.f','4.A.2.b.2.a','4.A.4.a.5.g','4.A.4.b.3.e','4.A.4.b.6.a','4.A.2.a.4.f']::text[],array[20.15,11.46,7.99,7.15,4.86,4.86,4.77,4.73,4.68]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['29-1229.04','29-1123.00','31-2021.00']::text[],null),
  ('29-1129.01',7,5,18,2,array['4.A.2.b.2.a','4.A.2.a.4.f','4.A.2.a.1.f','4.A.4.a.2.d','4.A.1.a.1.l','4.A.4.b.3.b','4.A.1.a.2.e','4.A.3.b.6.k','4.A.4.a.5.b']::text[],array[21.56,16.32,8.63,8.56,7.62,7.5,4.73,4.73,4.62]::numeric[],array[]::text[],array['29-1129.02']::text[],null),
  ('29-1129.02',6,4,9,1,array['4.A.2.b.2.a','4.A.4.a.2.d','4.A.3.b.6.k','4.A.4.a.5.b','4.A.1.a.1.l','4.A.2.a.1.f','4.A.2.b.3.a','4.A.2.a.4.f','4.A.3.a.1.p']::text[],array[34.76,12.13,9.21,9.19,8.7,8.22,7.91,7.47,4.88]::numeric[],array[]::text[],array['29-1129.01','29-1122.00','29-1127.00']::text[],null),
  ('29-1131.00',8,5,18,9,array['4.A.4.a.5.l','4.A.2.b.3.a','4.A.1.b.2.i','4.A.2.a.4.f','4.A.1.a.1.s','4.A.4.a.5.c','4.A.3.a.2.al','4.A.3.a.3.d','4.A.4.a.3.b']::text[],array[13.74,13.09,8.83,7.77,7.62,4.7,4.56,4.53,4.46]::numeric[],array[]::text[],array['29-2056.00','31-9096.00','29-1229.01']::text[],null),
  ('29-1141.00',6,4,18,4,array['4.A.1.a.2.e','4.A.3.b.6.k','4.A.4.a.5.c','4.A.4.a.2.d','4.A.2.b.2.n','4.A.4.b.6.f','4.A.4.a.5.k','4.A.4.a.5.l','4.A.2.a.4.f']::text[],array[22.42,14.04,13.43,12.58,8.43,8.23,8.12,4.56,4.41]::numeric[],array[]::text[],array['29-1141.01','29-1141.03','29-1141.04']::text[],null),
  ('29-1141.01',6,4,9,2,array['4.A.1.a.2.e','4.A.2.a.4.f','4.A.4.a.5.c','4.A.4.a.1.e','4.A.2.b.1.f','4.A.4.a.2.d','4.A.2.a.1.f','4.A.4.a.5.g','4.A.3.a.2.x']::text[],array[13.55,13.5,9.05,8.96,8.75,8.72,7.74,4.8,4.69]::numeric[],array[]::text[],array['29-1141.00','29-1141.03','29-1141.04']::text[],null),
  ('29-1141.02',7,5,18,4,array['4.A.2.a.4.f','4.A.4.a.2.d','4.A.4.a.5.c','4.A.2.b.1.f','4.A.2.a.1.f','4.A.3.b.6.k','4.A.4.a.1.e','4.A.1.a.2.e','4.A.2.b.2.a']::text[],array[13.46,12.58,10.56,9.64,4.91,4.87,4.87,4.86,4.7]::numeric[],array['Microsoft Teams','Google Meet']::text[],array['29-1141.04','29-1223.00','29-1215.00']::text[],null),
  ('29-1141.03',6,4,9,4,array['4.A.1.a.2.e','4.A.4.a.5.c','4.A.3.a.3.d','4.A.2.a.4.f','4.A.3.b.6.k','4.A.2.b.2.a','4.A.4.a.2.d','4.A.4.b.3.f','4.A.4.a.5.g']::text[],array[26.52,20.81,12.74,9.7,8.65,8.51,7.98,6.64,4.85]::numeric[],array[]::text[],array['29-1141.01','29-1141.00','29-1141.04']::text[],null),
  ('29-1141.04',7,5,36,4,array['4.A.3.b.2.f','4.A.4.b.3.f','4.A.2.b.2.a','4.A.2.a.1.b','4.A.4.b.6.f','4.A.4.a.5.l','4.A.4.a.2.d','4.A.2.b.3.a','4.A.2.a.3.d']::text[],array[17.12,12.67,10.73,8.66,8.15,4.71,4.7,4.67,4.62]::numeric[],array[]::text[],array['29-1141.02','29-1141.01','29-1141.00']::text[],null),
  ('29-1151.00',8,5,36,1,array['4.A.4.a.5.c','4.A.4.a.5.g','4.A.1.a.2.e','4.A.3.a.1.a','4.A.2.a.4.f','4.A.4.c.1.a','4.A.3.a.3.d','4.A.3.b.4.f','4.A.2.b.1.j']::text[],array[46.15,14.8,9.45,9.29,9.11,8.81,8.77,8.62,4.7]::numeric[],array['Patient management software','Epic Systems']::text[],array['29-1211.00','29-1141.00','29-1141.03']::text[],null),
  ('29-1161.00',7,5,18,2,array['4.A.4.a.5.c','4.A.4.b.3.f','4.A.1.b.2.i','4.A.3.b.6.k','4.A.4.a.2.d','4.A.2.b.2.a','4.A.4.a.1.e','4.A.2.a.4.f','4.A.4.a.5.g']::text[],array[18.05,15.78,14.75,9.73,9.15,4.91,4.88,4.85,4.82]::numeric[],array[]::text[],array['29-9099.01','29-1141.00','29-1141.01']::text[],null),
  ('29-1181.00',8,5,9,2,array['4.A.4.b.3.f','4.A.1.b.2.i','4.A.4.a.2.d','4.A.3.b.6.k','4.A.2.a.4.f','4.A.3.a.2.x','4.A.1.b.2.a','4.A.3.a.3.d','4.A.1.a.2.e']::text[],array[16.98,9.01,8.24,4.95,4.86,4.82,4.77,4.77,4.62]::numeric[],array['Microsoft Excel']::text[],array['29-2092.00','29-1041.00','29-1243.00']::text[],null),
  ('29-1211.00',8,5,36,1,array['4.A.4.a.2.d','4.A.4.a.5.k','4.A.1.a.2.e','4.A.3.b.6.k','4.A.4.a.5.g','4.A.4.a.5.c','4.A.1.b.2.i','4.A.4.b.3.f','4.A.4.a.5.a']::text[],array[13.25,9.56,9.49,4.84,4.84,4.81,4.8,4.18,4.11]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1242.00','29-1212.00']::text[],null),
  ('29-1212.00',7,5,48,4,array['4.A.1.b.2.a','4.A.3.a.3.d','4.A.2.a.4.f','4.A.4.a.5.l','4.A.4.a.1.e','4.A.4.b.6.a','4.A.1.a.2.e','4.A.1.a.1.s','4.A.1.a.1.l']::text[],array[12.0,9.0,9.0,6.0,6.0,6.0,3.0,3.0,3.0]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1216.00','29-1211.00']::text[],null),
  ('29-1213.00',8,5,36,2,array['4.A.4.a.5.l','4.A.2.b.1.f','4.A.1.b.2.i','4.A.4.b.6.a','4.A.3.b.6.k','4.A.2.b.3.a','4.A.4.b.6.f','4.A.4.a.5.a','4.A.4.b.3.f']::text[],array[26.44,9.59,4.9,4.76,4.63,4.32,4.3,4.13,4.06]::numeric[],array[]::text[],array['29-1243.00','29-1242.00','29-1241.00']::text[],null),
  ('29-1214.00',8,5,36,1,array['4.A.2.a.1.f','4.A.2.a.4.f','4.A.4.a.5.g','4.A.4.a.2.d','4.A.1.a.2.e','4.A.2.b.1.f','4.A.1.b.2.a','4.A.4.a.5.l','4.A.4.b.6.a']::text[],array[14.38,14.36,10.0,9.33,9.23,5.0,5.0,5.0,4.83]::numeric[],array['Epic Systems']::text[],array['29-2043.00','29-1243.00','29-1215.00']::text[],null),
  ('29-1215.00',8,5,36,2,array['4.A.4.a.5.c','4.A.1.a.1.l','4.A.2.a.4.f','4.A.3.b.6.k','4.A.1.a.2.e','4.A.4.a.1.e','4.A.4.b.6.f','4.A.4.b.6.a','4.A.4.a.5.a']::text[],array[5.0,4.99,4.99,4.99,4.97,4.96,4.76,4.76,4.64]::numeric[],array['Epic Systems']::text[],array['29-1214.00','29-1221.00','29-1216.00']::text[],null),
  ('29-1216.00',8,5,36,2,array['4.A.4.a.5.l','4.A.4.b.6.f','4.A.2.b.1.f','4.A.4.a.5.c','4.A.2.a.4.f','4.A.4.a.1.e','4.A.4.b.6.a','4.A.4.a.5.a','4.A.1.a.2.e']::text[],array[21.5,12.57,8.78,8.52,4.53,4.43,4.36,4.28,4.27]::numeric[],array[]::text[],array['29-1243.00','29-1212.00','29-1218.00']::text[],null),
  ('29-1217.00',8,5,60,18,array['4.A.2.a.4.f','4.A.2.b.1.f','4.A.1.b.2.a','4.A.4.a.2.d','4.A.4.a.5.l','4.A.1.a.1.l','4.A.1.b.2.i','4.A.4.a.5.c','4.A.1.a.2.e']::text[],array[18.75,9.4,9.16,8.9,8.86,4.86,4.84,4.72,4.72]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1212.00','29-1242.00']::text[],null),
  ('29-1218.00',8,5,60,2,array['4.A.4.a.5.l','4.A.4.a.5.c','4.A.4.b.6.f','4.A.2.a.4.f','4.A.1.a.1.l','4.A.3.b.6.k','4.A.4.a.1.e','4.A.1.a.2.e','4.A.4.a.2.d']::text[],array[9.71,9.61,8.72,4.86,4.82,4.82,4.81,4.67,4.66]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1216.00','29-1212.00']::text[],null),
  ('29-1221.00',8,5,36,1,array['4.A.4.a.5.l','4.A.1.b.2.i','4.A.4.b.6.f','4.A.2.b.2.n','4.A.4.a.5.c','4.A.4.b.6.a','4.A.4.a.1.e','4.A.1.a.1.l','4.A.3.b.6.k']::text[],array[13.14,9.8,8.34,7.64,4.95,4.84,4.81,4.77,4.77]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1216.00','29-1215.00']::text[],null),
  ('29-1222.00',8,5,60,2,array['4.A.2.a.4.f','4.A.4.a.2.d','4.A.2.b.1.f','4.A.2.a.4.j','4.A.3.a.3.i','4.A.3.b.6.f','4.A.1.a.1.p','4.A.2.b.3.a','4.A.1.b.2.a']::text[],array[11.69,9.01,8.9,8.78,4.92,4.84,4.67,4.4,3.98]::numeric[],array[]::text[],array['29-1243.00','29-1212.00','29-1224.00']::text[],null),
  ('29-1223.00',8,5,60,1,array['4.A.2.a.4.f','4.A.3.b.6.f','4.A.4.a.5.b','4.A.3.b.6.k','4.A.1.a.1.l','4.A.2.b.2.a','4.A.4.a.2.d','4.A.1.b.2.i','4.A.4.b.6.a']::text[],array[8.17,6.24,4.84,4.52,4.52,4.47,4.45,4.44,4.31]::numeric[],array[]::text[],array['29-1221.00','29-1217.00','29-1141.02']::text[],null),
  ('29-1224.00',8,5,60,18,array['4.A.4.a.2.d','4.A.2.a.4.f','4.A.1.a.1.l','4.A.4.a.1.e','4.A.2.b.2.e','4.A.2.b.1.d','4.A.1.a.2.k','4.A.4.b.3.f','4.A.3.b.6.f']::text[],array[14.08,12.76,9.68,9.36,8.74,7.46,7.46,7.42,4.98]::numeric[],array['Epic Systems']::text[],array['29-1212.00','29-1243.00','29-1242.00']::text[],null),
  ('29-1229.01',8,5,60,4,array['4.A.4.a.5.l','4.A.1.b.2.a','4.A.2.b.1.f','4.A.4.a.1.e','4.A.2.a.4.f','4.A.3.b.6.k','4.A.2.b.2.a','4.A.1.b.2.i','4.A.2.a.1.f']::text[],array[9.5,8.4,4.81,4.79,4.77,4.76,4.72,4.59,4.51]::numeric[],array[]::text[],array['29-1212.00','29-1216.00','29-1243.00']::text[],null),
  ('29-1229.03',8,5,36,36,array['4.A.4.a.5.l','4.A.3.a.3.d','4.A.2.b.1.f','4.A.2.a.4.f','4.A.1.a.1.l','4.A.3.b.6.k','4.A.4.a.5.c','4.A.4.b.6.f','4.A.4.a.5.a']::text[],array[27.69,9.48,4.89,4.77,4.76,4.76,4.76,4.69,4.31]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1212.00','29-1242.00']::text[],null),
  ('29-1229.04',8,5,36,2,array['4.A.1.a.2.e','4.A.4.a.5.l','4.A.4.a.2.d','4.A.1.b.2.i','4.A.3.b.6.k','4.A.2.a.1.f','4.A.2.b.2.a','4.A.1.b.2.a','4.A.4.b.3.f']::text[],array[9.09,8.73,8.66,8.46,4.73,4.6,4.48,4.34,4.15]::numeric[],array[]::text[],array['29-1242.00','29-1243.00','29-1212.00']::text[],null),
  ('29-1229.05',8,5,36,2,array['4.A.2.b.2.n','4.A.4.a.3.b','4.A.3.b.6.k','4.A.1.a.1.l','4.A.1.a.1.p','4.A.2.b.2.i','4.A.2.a.4.d','4.A.1.a.1.s','4.A.2.a.4.f']::text[],array[11.72,7.62,4.25,4.25,4.21,4.21,4.21,4.21,4.17]::numeric[],array[]::text[],array['29-1214.00','29-1216.00','29-1215.00']::text[],null),
  ('29-1229.06',8,5,84,1,array['4.A.4.b.6.f','4.A.4.a.5.l','4.A.1.b.2.i','4.A.3.b.6.k','4.A.2.a.4.f','4.A.2.a.1.f','4.A.4.b.6.a','4.A.2.b.1.f','4.A.4.a.2.d']::text[],array[31.07,16.01,12.52,8.73,7.78,7.69,6.82,4.63,4.14]::numeric[],array['Epic Systems']::text[],array['29-1229.04','29-1242.00','29-1243.00']::text[],null),
  ('29-1241.00',8,5,60,4,array['4.A.4.a.5.l','4.A.2.b.2.a','4.A.1.b.2.a','4.A.2.b.1.f','4.A.1.a.2.e','4.A.4.a.5.c','4.A.3.b.6.k','4.A.4.b.6.a','4.A.2.a.4.f']::text[],array[13.92,9.43,4.81,4.76,4.76,4.72,4.6,4.6,4.58]::numeric[],array[]::text[],array['29-1243.00','29-1242.00','29-1212.00']::text[],null),
  ('29-1242.00',7,5,48,4,array['4.A.4.a.5.l','4.A.2.b.1.f','4.A.2.a.4.f','4.A.1.a.1.s','4.A.2.b.5.c','4.A.3.a.1.i','4.A.2.a.3.d','4.A.1.b.2.i','4.A.4.a.5.a']::text[],array[9.0,6.0,6.0,3.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['Epic Systems']::text[],array['29-1243.00','29-1241.00','29-1211.00']::text[],null),
  ('29-1243.00',7,5,48,4,array['4.A.1.b.2.i','4.A.4.a.1.e','4.A.2.a.4.f','4.A.4.a.5.l','4.A.1.a.2.e','4.A.1.a.1.s','4.A.2.b.5.c','4.A.3.a.1.i','4.A.2.b.1.f']::text[],array[6.0,6.0,6.0,6.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array[]::text[],array['29-1242.00','29-1241.00','29-1229.03']::text[],null),
  ('29-1291.00',7,5,18,2,array['4.A.4.a.5.l','4.A.2.a.3.d','4.A.2.a.1.f','4.A.2.b.2.a','4.A.1.a.1.l','4.A.3.b.6.k','4.A.4.b.3.f','4.A.1.b.2.i','4.A.2.a.4.f']::text[],array[21.94,9.9,9.0,4.89,4.72,4.62,4.46,4.38,4.38]::numeric[],array[]::text[],array['29-1011.00','31-9011.00','29-1212.00']::text[],null),
  ('29-1292.00',5,3,4,0,array['4.A.1.b.2.i','4.A.4.a.5.l','4.A.3.b.6.k','4.A.3.a.3.d','4.A.2.b.3.a','4.A.2.b.5.c','4.A.4.b.6.a','4.A.3.a.1.i','4.A.3.b.4.f']::text[],array[13.9,13.09,9.44,9.3,8.96,8.8,4.66,4.47,4.47]::numeric[],array['Henry Schein Dentrix']::text[],array['31-9091.00','29-9093.00','29-2056.00']::text[],null),
  ('29-2011.00',6,4,9,4,array['4.A.2.a.4.j','4.A.3.a.2.au','4.A.3.a.2.al','4.A.3.b.4.f','4.A.3.b.1.f','4.A.3.a.1.i','4.A.3.a.2.k','4.A.3.a.3.i','4.A.2.b.2.e']::text[],array[23.67,18.09,13.27,9.47,4.77,4.74,4.74,4.73,4.72]::numeric[],array[]::text[],array['29-2012.00','29-2011.04','29-2011.01']::text[],null),
  ('29-2011.01',6,4,9,9,array['4.A.3.a.2.au','4.A.2.b.1.d','4.A.2.a.4.j','4.A.4.a.2.d','4.A.3.b.6.f','4.A.3.b.1.f','4.A.3.a.3.i','4.A.3.a.2.al','4.A.4.a.1.e']::text[],array[28.88,22.76,19.38,18.47,9.72,9.57,4.94,4.9,4.82]::numeric[],array[]::text[],array['29-2011.00','29-2012.00','29-2011.04']::text[],null),
  ('29-2011.02',6,5,2,2,array['4.A.2.a.4.j','4.A.4.a.2.d','4.A.3.a.2.au','4.A.3.b.4.f','4.A.2.a.2.e','4.A.1.b.2.a','4.A.2.a.3.d','4.A.1.a.2.k','4.A.4.a.5.k']::text[],array[12.26,9.68,9.13,8.28,5.0,4.82,4.77,4.77,4.68]::numeric[],array[]::text[],array['29-2011.00','29-2011.01','29-2011.04']::text[],'Tenaga laboratorium sitologi; jalur formalnya S1/D4 Teknologi Laboratorium Medik.'),
  ('29-2011.04',6,4,9,4,array['4.A.3.a.2.au','4.A.2.a.4.j','4.A.3.a.3.i','4.A.3.a.2.al','4.A.3.b.6.h','4.A.1.b.2.a','4.A.3.a.1.a','4.A.3.b.4.f','4.A.4.b.3.f']::text[],array[17.72,8.17,7.93,4.76,4.48,4.47,4.4,4.33,3.67]::numeric[],array[]::text[],array['29-2012.01','29-2012.00','29-2011.00']::text[],null),
  ('29-2012.00',6,3,9,4,array['4.A.2.a.4.j','4.A.3.a.2.au','4.A.3.a.2.al','4.A.1.b.2.c','4.A.1.b.2.a','4.A.3.a.3.i','4.A.3.b.1.f','4.A.3.b.4.f','4.A.3.a.2.k']::text[],array[14.12,14.0,9.07,8.78,4.89,4.8,4.8,4.69,4.69]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['29-2011.00','29-2011.04','29-2012.01']::text[],null),
  ('29-2012.01',5,3,4,4,array['4.A.3.a.2.au','4.A.3.a.2.al','4.A.3.a.3.i','4.A.3.a.2.h','4.A.3.b.4.f']::text[],array[19.1,5.0,4.14,4.08,4.08]::numeric[],array[]::text[],array['29-2011.04','29-2012.00','29-2011.00']::text[],null),
  ('29-2031.00',5,3,18,2,array['4.A.4.a.5.k','4.A.3.a.3.d','4.A.2.a.4.f','4.A.1.a.2.a','4.A.1.a.2.e','4.A.4.a.2.d','4.A.3.b.4.f','4.A.4.c.1.a','4.A.1.b.2.a']::text[],array[18.55,18.21,9.34,9.3,9.27,8.77,8.24,8.16,4.83]::numeric[],array[]::text[],array['29-2032.00','29-2099.01','29-2034.00']::text[],null),
  ('29-2032.00',5,3,18,4,array['4.A.3.a.3.d','4.A.4.a.5.k','4.A.3.b.6.k','4.A.3.a.2.i','4.A.4.a.2.d','4.A.4.a.5.g','4.A.1.a.2.a','4.A.1.a.2.e','4.A.4.a.1.e']::text[],array[26.67,18.7,13.31,9.7,9.23,7.84,4.87,4.85,4.74]::numeric[],array[]::text[],array['29-2031.00','29-2034.00','29-2099.01']::text[],null),
  ('29-2033.00',5,3,18,4,array['4.A.3.a.3.d','4.A.3.b.6.k','4.A.2.a.3.d','4.A.4.a.5.c','4.A.2.a.4.f','4.A.4.c.1.a','4.A.4.a.1.e','4.A.3.a.1.a','4.A.1.b.2.g']::text[],array[19.27,9.53,9.46,4.91,4.77,4.76,4.74,4.74,4.73]::numeric[],array[]::text[],array['29-2031.00','29-2034.00','29-1124.00']::text[],null),
  ('29-2034.00',5,3,9,2,array['4.A.3.a.3.d','4.A.3.b.6.k','4.A.3.a.2.i','4.A.1.a.2.e','4.A.2.a.2.a','4.A.4.a.5.k','4.A.3.a.2.k','4.A.4.a.2.d','4.A.4.b.3.f']::text[],array[32.99,13.49,9.89,9.83,9.62,9.52,9.33,7.92,7.26]::numeric[],array['R']::text[],array['29-2031.00','29-2032.00','29-2035.00']::text[],null),
  ('29-2035.00',5,3,18,2,array['4.A.3.a.3.d','4.A.4.a.5.k','4.A.1.a.1.b','4.A.1.a.1.l','4.A.3.b.4.f','4.A.2.a.3.d','4.A.4.a.5.j','4.A.2.b.1.j','4.A.2.a.2.a']::text[],array[26.6,13.62,10.0,9.73,8.53,5.0,4.83,4.83,4.6]::numeric[],array[]::text[],array['29-2034.00','29-2031.00','29-2032.00']::text[],null),
  ('29-2036.00',6,4,18,9,array['4.A.3.a.3.d','4.A.2.a.4.f','4.A.2.b.2.a','4.A.3.a.2.i','4.A.3.a.2.q','4.A.4.b.3.f','4.A.3.b.6.k','4.A.1.a.1.s','4.A.4.b.6.b']::text[],array[32.17,27.6,17.51,16.44,11.44,11.37,8.62,7.89,7.82]::numeric[],array['Eclipse IDE','Epic Systems']::text[],array['29-1124.00','29-2033.00','29-1224.00']::text[],null),
  ('29-2042.00',5,3,9,9,array['4.A.4.a.2.d','4.A.4.a.5.g','4.A.1.a.2.e','4.A.2.a.4.f','4.A.3.a.1.i','4.A.2.b.3.a','4.A.3.b.4.f','4.A.3.a.4.a','4.A.3.b.6.k']::text[],array[9.0,6.0,3.0,3.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array[]::text[],array['29-2043.00','29-9093.00','29-1141.00']::text[],null),
  ('29-2043.00',5,3,9,9,array['4.A.4.a.5.g','4.A.4.a.5.c','4.A.4.a.2.d','4.A.4.b.3.f','4.A.2.a.4.f','4.A.1.a.2.e','4.A.3.b.6.k','4.A.3.a.3.d','4.A.2.b.3.a']::text[],array[18.0,12.0,9.0,6.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array[]::text[],array['29-2042.00','29-1141.00','29-1141.01']::text[],null),
  ('29-2051.00',5,3,18,2,array['4.A.4.a.2.d','4.A.1.a.2.e','4.A.2.b.2.v','4.A.2.a.4.f','4.A.1.a.1.l','4.A.2.a.1.f','4.A.4.b.6.a','4.A.1.b.3.b','4.A.2.b.1.h']::text[],array[12.84,9.32,8.74,4.55,4.55,4.55,4.41,4.4,4.4]::numeric[],array[]::text[],array['29-1031.00','31-1121.00']::text[],null),
  ('29-2052.00',5,3,2,2,array['4.A.3.b.1.f','4.A.4.c.1.c','4.A.3.a.1.a','4.A.4.c.1.a','4.A.3.a.1.i','4.A.4.a.6.b','4.A.2.a.2.e','4.A.3.b.6.k','4.A.4.a.3.b']::text[],array[18.61,18.39,17.69,13.86,8.72,7.19,4.86,4.71,4.53]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['29-1051.00','31-9095.00','29-2056.00']::text[],'UU 17/2023 & PP 51/2009: tenaga teknis kefarmasian minimal D3 Farmasi.'),
  ('29-2055.00',5,3,9,4,array['4.A.4.a.5.k','4.A.3.a.1.i','4.A.1.a.2.e','4.A.2.a.3.d','4.A.3.a.2.au','4.A.1.a.2.b','4.A.3.a.2.i','4.A.3.a.3.d','4.A.4.a.5.c']::text[],array[33.66,14.08,8.93,4.81,4.73,4.71,4.67,4.67,4.66]::numeric[],array[]::text[],array['29-9093.00','29-2031.00','31-9099.02']::text[],null),
  ('29-2056.00',5,3,9,2,array['4.A.4.a.5.c','4.A.4.a.5.k','4.A.1.a.2.e','4.A.3.a.1.i','4.A.3.a.1.a','4.A.3.b.6.k','4.A.3.a.3.d','4.A.1.b.2.a','4.A.4.a.5.g']::text[],array[22.88,22.25,14.12,13.57,9.14,9.02,8.84,4.7,4.62]::numeric[],array[]::text[],array['31-9096.00','29-9093.00','29-2031.00']::text[],'Permentan 3/2019: paramedik veteriner minimal D3 Kesehatan Hewan.'),
  ('29-2057.00',5,3,18,4,array['4.A.1.b.2.a','4.A.3.b.6.k','4.A.1.b.2.i','4.A.3.a.1.i','4.A.3.a.3.d','4.A.4.b.3.e','4.A.1.a.1.l','4.A.4.a.5.c','4.A.4.a.5.k']::text[],array[31.75,9.81,9.55,9.14,8.97,8.18,4.95,4.77,4.71]::numeric[],array['Microsoft Excel']::text[],array['29-2099.05','29-2031.00','29-9093.00']::text[],'Permenkes 19/2013: minimal D3 Refraksi Optisi, wajib STR.'),
  ('29-2061.00',5,3,9,2,array['4.A.3.b.6.k','4.A.4.a.5.c','4.A.4.a.5.i','4.A.4.a.3.c','4.A.4.a.2.d','4.A.3.a.2.k','4.A.3.a.1.i','4.A.1.a.2.e','4.A.1.b.2.i']::text[],array[22.08,13.4,12.13,8.86,8.59,8.19,8.0,4.66,4.55]::numeric[],array[]::text[],array['29-1141.00','29-2043.00','29-1141.01']::text[],null),
  ('29-2072.00',5,3,9,9,array['4.A.4.c.1.a','4.A.2.b.5.c','4.A.3.b.6.k','4.A.3.b.1.f','4.A.2.b.3.a','4.A.1.a.1.l','4.A.1.a.2.k','4.A.3.b.6.f','4.A.3.a.1.k']::text[],array[24.0,6.0,6.0,6.0,3.0,3.0,3.0,3.0,3.0]::numeric[],array['Epic Systems','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['29-9021.00']::text[],null),
  ('29-2081.00',5,3,9,9,array['4.A.3.a.2.q','4.A.4.b.6.b','4.A.4.a.5.f','4.A.2.b.6.b','4.A.4.c.1.a','4.A.4.b.3.e','4.A.4.a.6.b','4.A.1.b.2.i','4.A.2.a.1.f']::text[],array[17.55,9.58,9.5,9.24,8.96,8.93,8.04,4.96,4.81]::numeric[],array[]::text[],array['29-1041.00','29-2057.00','29-2099.05']::text[],'Permenkes 19/2013: refraksionis optisien minimal D3 Refraksi Optisi, wajib STR.'),
  ('29-2091.00',7,5,18,9,array['4.A.3.a.2.q','4.A.1.b.2.i','4.A.3.a.2.x','4.A.4.b.3.f','4.A.4.b.3.e','4.A.3.b.6.k','4.A.1.a.1.l','4.A.2.b.2.k','4.A.4.a.2.d']::text[],array[17.91,9.42,9.29,7.8,4.76,4.76,4.71,4.53,4.0]::numeric[],array[]::text[],array['29-1242.00','29-1229.04','29-1181.00']::text[],null),
  ('29-2092.00',6,3,18,4,array['4.A.1.b.2.a','4.A.4.b.3.e','4.A.4.b.6.a','4.A.4.b.6.j','4.A.3.a.3.d','4.A.3.b.4.f','4.A.3.a.2.x','4.A.3.a.2.q','4.A.4.a.5.k']::text[],array[14.15,8.53,4.78,4.78,4.65,4.65,4.65,4.45,4.35]::numeric[],array[]::text[],array['29-2057.00','29-2091.00','29-2099.01']::text[],null),
  ('29-2099.01',5,3,18,9,array['4.A.1.a.1.l','4.A.1.b.2.a','4.A.3.a.2.i','4.A.3.a.3.d','4.A.4.a.5.k','4.A.3.b.4.f','4.A.1.a.2.e','4.A.4.a.1.e','4.A.3.a.2.k']::text[],array[14.78,14.13,9.38,9.38,9.36,9.16,4.94,4.83,4.81]::numeric[],array['R']::text[],array['29-2031.00','29-2034.00','29-2032.00']::text[],null),
  ('29-2099.05',5,3,36,2,array['4.A.1.b.2.a','4.A.3.a.3.d','4.A.1.b.2.i','4.A.3.b.6.k','4.A.3.a.1.i','4.A.4.a.5.k','4.A.1.a.1.l','4.A.4.a.5.c','4.A.2.a.4.f']::text[],array[50.32,25.72,17.17,9.5,8.9,7.42,4.9,4.65,4.6]::numeric[],array[]::text[],array['29-2057.00','29-2031.00','29-2034.00']::text[],'Tenaga kesehatan berizin; jalur formalnya D3 Refraksi Optisi/Teknologi Oftalmik.'),
  ('29-2099.08',5,3,36,2,array['4.A.4.a.5.a','4.A.2.b.3.a','4.A.1.a.1.w','4.A.4.a.1.b','4.A.4.b.3.d','4.A.2.a.4.k','4.A.4.a.2.c','4.A.3.b.6.c','4.A.3.b.6.l']::text[],array[8.3,7.96,4.45,4.06,3.89,3.75,3.48,3.37,3.21]::numeric[],array['Epic Systems','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['29-9021.00','29-2072.00','15-1211.01']::text[],null),
  ('29-9021.00',5,3,9,9,array['4.A.1.a.1.l','4.A.1.b.2.h','4.A.4.c.1.a','4.A.3.b.1.f','4.A.4.a.6.c','4.A.1.a.2.h','4.A.3.a.1.k','4.A.3.b.2.f','4.A.2.b.2.f']::text[],array[6.0,6.0,6.0,6.0,6.0,3.0,3.0,3.0,3.0]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['29-2072.00','15-2051.02','15-1211.01']::text[],null),
  ('29-9091.00',7,5,18,1,array['4.A.3.a.1.l','4.A.4.b.6.f','4.A.2.b.2.a','4.A.4.b.3.f','4.A.2.a.4.f','4.A.2.a.1.f','4.A.4.a.2.d','4.A.3.a.1.c','4.A.4.a.5.b']::text[],array[14.92,14.3,11.6,9.81,9.38,9.32,8.9,8.76,4.69]::numeric[],array['Microsoft Office software']::text[],array['29-1229.06','29-1128.00','31-2021.00']::text[],null),
  ('29-9092.00',7,5,0,1,array['4.A.4.a.1.e','4.A.2.a.4.f','4.A.1.a.1.l','4.A.4.b.3.f','4.A.1.a.1.s','4.A.3.b.6.g','4.A.4.a.2.d','4.A.3.b.6.f','4.A.4.b.6.a']::text[],array[23.05,9.4,9.04,7.14,6.53,6.12,4.91,4.61,4.59]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['29-1223.00','29-1215.00','29-1141.02']::text[],null),
  ('29-9093.00',5,3,18,9,array['4.A.4.a.5.k','4.A.4.a.5.c','4.A.4.a.5.l','4.A.1.a.2.e','4.A.3.a.3.d','4.A.4.a.2.d','4.A.3.a.2.i','4.A.2.a.2.e','4.A.2.a.3.d']::text[],array[35.61,23.44,18.14,13.41,9.27,8.71,7.88,4.97,4.71]::numeric[],array[]::text[],array['29-2055.00','29-2043.00','29-2042.00']::text[],null),
  ('29-9099.01',5,5,18,4,array['4.A.4.a.5.c','4.A.2.a.4.f','4.A.1.b.2.i','4.A.4.a.5.a','4.A.2.a.1.f','4.A.4.a.1.e','4.A.4.b.6.a','4.A.2.b.1.f','4.A.1.a.2.e']::text[],array[21.52,16.54,13.91,13.01,12.97,12.39,12.2,9.26,9.11]::numeric[],array['Epic Systems']::text[],array['29-1161.00','29-1218.00','29-1141.00']::text[],'UU 4/2019 tentang Kebidanan: bidan vokasi minimal D3 Kebidanan.'),
  ('31-1121.00',2,2,9,1,array['4.A.4.a.5.i','4.A.4.a.5.c','4.A.4.b.3.f','4.A.3.a.1.l','4.A.3.b.6.k','4.A.2.a.1.f','4.A.4.b.3.a','4.A.4.a.5.b']::text[],array[20.82,7.87,7.55,7.47,4.46,3.92,3.9,3.31]::numeric[],array[]::text[],array['31-1131.00','31-1122.00','29-2043.00']::text[],null),
  ('31-1122.00',2,2,2,2,array['4.A.4.a.5.c','4.A.4.b.3.f','4.A.3.a.2.c','4.A.3.b.6.h','4.A.3.b.6.f','4.A.1.a.2.e','4.A.2.b.2.v','4.A.4.b.6.j','4.A.3.a.1.c']::text[],array[9.11,8.98,8.22,4.65,4.65,4.46,4.45,4.39,4.19]::numeric[],array[]::text[],array['31-1121.00','31-1131.00']::text[],null),
  ('31-1131.00',2,3,2,1,array['4.A.4.a.5.i','4.A.4.a.5.k','4.A.3.b.6.k','4.A.4.a.3.c','4.A.4.a.5.c','4.A.3.a.1.c','4.A.3.a.2.ak','4.A.1.a.2.e','4.A.2.a.4.f']::text[],array[26.69,22.48,17.55,12.77,12.29,8.38,8.11,4.52,4.45]::numeric[],array[]::text[],array['31-1121.00','29-2043.00','29-2061.00']::text[],null),
  ('31-1132.00',2,2,0,1,array['4.A.4.a.5.k','4.A.3.a.1.j','4.A.3.a.1.e','4.A.3.a.1.i','4.A.3.a.1.c','4.A.4.a.2.c','4.A.3.a.2.ak','4.A.4.a.3.c','4.A.4.a.5.i']::text[],array[20.83,16.28,12.68,9.43,8.63,8.12,7.59,7.56,6.56]::numeric[],array[]::text[],array['31-1131.00','31-1121.00','29-9093.00']::text[],null),
  ('31-1133.00',2,2,9,2,array['4.A.4.a.5.i','4.A.3.b.6.k','4.A.2.a.1.f','4.A.4.a.5.l','4.A.1.a.2.e','4.A.4.a.5.k','4.A.4.a.2.d','4.A.4.b.6.a','4.A.2.a.3.d']::text[],array[16.79,16.75,8.52,4.56,4.47,4.44,4.35,4.29,4.29]::numeric[],array[]::text[],array['31-1121.00']::text[],'Pekarya adalah tenaga penunjang non-nakes; jenjangnya SMA/SMK.'),
  ('31-2021.00',5,3,4,4,array['4.A.4.b.3.f','4.A.3.b.6.f','4.A.4.a.2.d','4.A.4.a.5.k','4.A.4.a.5.b','4.A.3.a.2.k','4.A.4.a.5.c','4.A.3.b.6.k','4.A.1.a.2.e']::text[],array[30.07,9.74,9.36,8.98,8.01,7.82,6.76,4.89,4.85]::numeric[],array[]::text[],array['29-1126.00']::text[],null),
  ('31-9011.00',2,3,1,1,array['4.A.4.a.5.b','4.A.4.a.5.a','4.A.1.a.1.w','4.A.3.a.1.c','4.A.3.a.2.ak','4.A.2.b.2.a','4.A.3.b.6.k','4.A.2.a.1.f','4.A.4.b.3.f']::text[],array[26.34,7.28,4.81,4.5,4.5,4.38,4.24,4.23,4.16]::numeric[],array[]::text[],array['31-2021.00']::text[],null),
  ('31-9091.00',2,3,9,9,array['4.A.3.a.2.q','4.A.3.b.6.k','4.A.4.a.5.k','4.A.3.a.1.i','4.A.4.a.5.c','4.A.3.a.2.k','4.A.3.a.3.d','4.A.4.a.1.e','4.A.4.b.3.f']::text[],array[16.03,13.25,9.47,8.58,8.26,4.81,4.59,4.58,4.35]::numeric[],array['Henry Schein Dentrix']::text[],array['29-1292.00','29-2057.00','29-9093.00']::text[],null),
  ('31-9093.00',2,2,18,9,array['4.A.3.a.1.i','4.A.1.a.2.a','4.A.3.a.3.d','4.A.3.a.1.j','4.A.4.a.5.k','4.A.3.b.4.f','4.A.3.b.6.k','4.A.3.a.2.k','4.A.3.a.2.ak']::text[],array[18.74,13.83,9.36,8.54,6.64,4.85,4.75,4.75,4.53]::numeric[],array[]::text[],array['29-2055.00','29-2012.00','31-9099.02']::text[],null),
  ('31-9095.00',2,2,0,2,array['4.A.4.c.1.a','4.A.4.a.3.c','4.A.4.a.5.j','4.A.4.a.8.c','4.A.3.a.2.ap','4.A.1.b.1.a','4.A.4.c.1.c','4.A.3.a.2.ak','4.A.3.b.6.k']::text[],array[12.93,9.06,4.67,4.39,4.25,4.25,4.16,4.0,3.89]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['29-2052.00','41-2011.00','53-7065.00']::text[],null),
  ('31-9096.00',2,2,4,2,array['4.A.4.a.5.i','4.A.4.a.5.k','4.A.4.a.5.c','4.A.1.a.2.e','4.A.4.c.1.a','4.A.3.a.2.k','4.A.3.a.1.c','4.A.2.a.1.f','4.A.1.b.2.a']::text[],array[18.55,17.64,17.37,9.43,8.47,8.42,4.61,4.54,4.52]::numeric[],array[]::text[],array['29-2056.00','29-2043.00','29-9093.00']::text[],null),
  ('31-9097.00',5,3,9,2,array['4.A.3.a.2.al','4.A.3.a.2.au','4.A.3.a.1.e','4.A.4.a.2.d','4.A.1.b.2.a','4.A.3.a.2.k','4.A.3.a.1.i','4.A.4.a.5.c','4.A.3.b.6.k']::text[],array[22.4,18.92,9.71,9.06,9.06,4.86,4.86,4.5,4.44]::numeric[],array['Microsoft Office software']::text[],array['29-2012.00','29-2011.00','29-2031.00']::text[],'Praktik flebotomi masuk ranah ATLM (D3 Teknologi Laboratorium Medik), wajib STR.'),
  ('31-9099.02',2,2,1,2,array['4.A.3.b.4.f','4.A.4.a.5.k','4.A.2.b.3.a','4.A.3.a.1.i','4.A.3.a.2.al','4.A.1.a.2.a','4.A.3.a.3.d','4.A.3.a.2.k','4.A.4.b.3.f']::text[],array[9.83,8.9,8.36,4.96,4.92,4.88,4.67,4.64,4.17]::numeric[],array[]::text[],array['29-2055.00','29-2031.00','29-9093.00']::text[],null),
  ('39-5091.00',2,3,18,1,array['4.A.3.a.2.u','4.A.1.a.1.a','4.A.3.a.1.c','4.A.4.a.2.h','4.A.2.b.2.t','4.A.3.b.6.o','4.A.2.a.1.f','4.A.4.b.3.f','4.A.4.b.3.e']::text[],array[31.47,17.87,10.0,7.93,7.61,4.47,4.45,3.33,3.33]::numeric[],array[]::text[],array[]::text[],null),
  ('41-1011.00',2,2,36,4,array['4.A.2.b.2.l','4.A.4.b.3.d','4.A.1.b.2.j','4.A.3.a.2.h','4.A.2.b.2.c','4.A.4.a.5.j','4.A.4.a.8.c','4.A.1.a.2.c','4.A.3.b.6.j']::text[],array[12.64,8.51,8.42,8.37,7.86,4.7,4.7,4.37,4.19]::numeric[],array['Microsoft Office software']::text[],array['41-1012.00']::text[],null),
  ('41-1012.00',6,4,60,4,array['4.A.1.a.2.c','4.A.4.a.2.c','4.A.1.b.2.j','4.A.4.a.6.c','4.A.1.a.1.n','4.A.2.b.2.l','4.A.3.b.6.a','4.A.4.a.1.a','4.A.4.a.8.c']::text[],array[8.24,8.12,7.81,4.06,4.06,4.06,4.02,3.88,3.88]::numeric[],array['Salesforce software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-1011.00']::text[],null),
  ('41-2011.00',2,2,2,1,array['4.A.4.c.1.c','4.A.3.b.6.j','4.A.2.a.2.d','4.A.2.b.1.a','4.A.4.a.3.c','4.A.4.a.8.c','4.A.4.a.5.j','4.A.4.a.1.a','4.A.1.a.2.c']::text[],array[26.61,17.43,13.66,13.49,12.59,8.89,8.89,8.89,8.66]::numeric[],array[]::text[],array['41-2021.00','43-3071.00','43-4051.00']::text[],null),
  ('41-2021.00',2,2,2,2,array['4.A.4.c.1.c','4.A.4.b.6.b','4.A.1.b.2.j','4.A.3.b.6.j','4.A.4.a.5.j','4.A.2.b.1.a','4.A.4.a.1.a','4.A.4.a.1.d','4.A.1.a.1.n']::text[],array[21.68,16.25,8.37,8.18,7.67,4.66,4.4,4.4,4.37]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-2031.00','41-2011.00','41-9091.00']::text[],null),
  ('41-2022.00',2,2,18,2,array['4.A.4.c.1.c','4.A.1.a.1.n','4.A.4.a.1.a','4.A.4.b.6.b','4.A.3.b.6.m','4.A.1.b.2.j','4.A.2.a.4.g','4.A.2.b.1.a','4.A.3.a.2.ak']::text[],array[22.7,8.83,8.41,7.88,4.48,4.28,4.25,4.25,4.22]::numeric[],array['Inventory control system software','Inventory management systems','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['41-2021.00','43-5071.00','41-2031.00']::text[],null),
  ('41-2031.00',2,2,9,2,array['4.A.2.b.1.a','4.A.4.a.5.j','4.A.4.b.6.b','4.A.3.a.2.h','4.A.4.c.1.c','4.A.3.b.6.m','4.A.1.a.1.n','4.A.3.b.6.j','4.A.4.a.8.c']::text[],array[15.72,12.24,9.01,8.83,8.79,8.08,4.84,4.58,4.53]::numeric[],array[]::text[],array['41-2021.00','41-9091.00','53-7065.00']::text[],null),
  ('41-3011.00',6,4,18,4,array['4.A.2.b.2.j','4.A.4.a.6.c','4.A.3.b.6.m','4.A.4.a.1.a','4.A.1.b.1.b','4.A.4.a.4.a','4.A.2.b.3.a','4.A.2.b.2.c','4.A.2.b.1.a']::text[],array[24.29,13.25,13.01,12.91,12.88,8.29,8.15,8.04,4.51]::numeric[],array['Canva','Adobe Creative Cloud software','Adobe InDesign','Salesforce software','Adobe Photoshop']::text[],array['11-2011.00','13-1161.00','13-1161.01']::text[],null),
  ('41-3021.00',5,4,1,4,array['4.A.4.a.6.b','4.A.4.a.1.d','4.A.1.a.1.n','4.A.4.c.1.c','4.A.2.b.3.a','4.A.3.b.6.j','4.A.1.b.1.b','4.A.4.a.4.a','4.A.3.b.6.m']::text[],array[16.93,15.76,8.14,8.04,7.14,4.19,4.14,4.14,4.05]::numeric[],array['Microsoft Outlook','Microsoft Office software']::text[],array['43-4051.00','13-2052.00','41-3031.00']::text[],null),
  ('41-3031.00',6,4,36,4,array['4.A.4.a.1.d','4.A.4.a.7.b','4.A.4.a.6.b','4.A.2.b.1.a','4.A.1.a.2.h','4.A.1.a.1.n','4.A.1.b.1.b','4.A.3.b.6.a','4.A.3.b.6.j']::text[],array[16.11,15.45,15.14,10.6,8.89,8.57,8.53,8.28,4.6]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['13-2051.00','13-2052.00','11-3031.03']::text[],null),
  ('41-3041.00',5,3,18,4,array['4.A.4.c.1.c','4.A.1.a.1.n','4.A.4.a.6.b','4.A.2.b.1.a','4.A.3.b.6.h','4.A.3.b.6.m','4.A.1.a.1.d','4.A.4.a.6.c']::text[],array[4.6,4.57,4.57,4.57,4.49,4.42,4.3,4.04]::numeric[],array['Amadeus CRS','Sabre Central Command','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-2021.00','43-4051.00']::text[],null),
  ('41-4011.00',5,4,36,2,array['4.A.4.a.6.c','4.A.4.b.6.b','4.A.4.a.1.a','4.A.2.b.1.a','4.A.4.a.6.b','4.A.4.a.2.h','4.A.2.a.2.a','4.A.2.b.3.a','4.A.4.a.7.b']::text[],array[18.55,14.09,10.72,8.1,7.71,7.39,7.2,6.62,4.3]::numeric[],array['Salesforce software','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-4012.00','41-9031.00','13-1022.00']::text[],null),
  ('41-4011.07',5,3,9,4,array['4.A.4.a.1.a','4.A.4.a.6.b','4.A.3.b.6.g','4.A.3.b.6.m','4.A.2.b.2.j','4.A.4.a.1.d','4.A.1.a.1.n','4.A.2.a.1.g','4.A.1.b.1.b']::text[],array[8.99,8.78,4.77,4.77,4.77,4.58,4.54,4.52,4.42]::numeric[],array['Salesforce software']::text[],array['17-2199.11','47-1011.03','47-4011.01']::text[],null),
  ('41-4012.00',5,4,36,9,array['4.A.4.a.6.c','4.A.4.a.7.b','4.A.4.b.6.b','4.A.2.b.1.a','4.A.4.a.1.a','4.A.3.a.2.ak','4.A.3.a.2.h','4.A.4.a.8.c','4.A.3.b.6.m']::text[],array[12.02,8.6,8.52,8.28,8.21,4.38,4.38,4.37,4.16]::numeric[],array['Salesforce software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-4011.00','13-1022.00','13-1021.00']::text[],null),
  ('41-9011.00',2,2,0,1,array['4.A.4.a.6.c','4.A.4.b.6.b','4.A.3.b.6.j','4.A.2.b.3.a','4.A.3.a.2.h','4.A.4.a.6.b','4.A.3.a.1.c','4.A.4.a.1.a','4.A.1.b.1.b']::text[],array[27.85,11.77,8.87,8.31,8.25,4.52,4.47,4.46,4.2]::numeric[],array[]::text[],array['41-9091.00','41-2031.00','41-4012.00']::text[],null),
  ('41-9012.00',2,2,1,0,array['4.A.4.a.6.c','4.A.3.b.6.a','4.A.1.a.1.f','4.A.1.b.1.b','4.A.4.a.2.c','4.A.3.a.2.h','4.A.3.a.4.a','4.A.3.a.1.p']::text[],array[16.57,4.59,4.12,3.95,3.95,3.66,3.66,3.26]::numeric[],array[]::text[],array['27-1013.00','39-5091.00','27-4021.00']::text[],null),
  ('41-9021.00',6,4,18,9,array['4.A.4.a.6.b','4.A.2.a.2.a','4.A.2.b.3.a','4.A.1.a.1.d','4.A.2.a.1.i','4.A.3.b.6.m','4.A.4.a.7.b','4.A.1.a.2.h','4.A.4.a.5.a']::text[],array[8.43,7.92,7.74,7.7,7.42,4.49,4.39,3.67,3.66]::numeric[],array['Microsoft Outlook','Microsoft Office software']::text[],array['41-9022.00','13-2023.00','41-3031.00']::text[],null),
  ('41-9022.00',2,3,0,4,array['4.A.4.b.6.k','4.A.2.a.1.i','4.A.4.a.6.c','4.A.1.a.1.d','4.A.4.a.7.b','4.A.2.b.5.c','4.A.1.b.1.b','4.A.3.b.6.m','4.A.2.b.2.j']::text[],array[20.29,13.23,12.75,11.56,9.66,7.1,6.71,4.86,4.6]::numeric[],array['Yardi software','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['41-9021.00','13-2023.00','41-3031.00']::text[],null),
  ('41-9031.00',6,4,60,9,array['4.A.4.a.6.c','4.A.4.a.6.b','4.A.1.b.1.b','4.A.4.a.2.h','4.A.4.b.6.b','4.A.2.b.3.a','4.A.4.a.2.e','4.A.3.b.6.g','4.A.3.b.6.m']::text[],array[15.56,8.48,7.87,7.68,7.61,7.21,7.01,4.58,4.15]::numeric[],array['Microsoft Azure software','Amazon Web Services AWS software','Salesforce software','Python','Microsoft PowerPoint']::text[],array['41-4011.00','13-1081.01','17-2112.00']::text[],null),
  ('41-9041.00',2,2,0,2,array['4.A.3.b.6.h','4.A.4.a.6.c','4.A.4.a.1.a','4.A.4.a.8.c','4.A.2.b.2.j','4.A.4.a.3.c','4.A.1.b.1.b','4.A.2.b.5.c','4.A.1.a.2.h']::text[],array[13.81,13.47,4.66,4.66,4.45,4.43,4.11,3.67,3.33]::numeric[],array[]::text[],array['43-4051.00','41-3011.00','41-2021.00']::text[],null),
  ('41-9091.00',1,2,0,1,array['4.A.4.a.6.c','4.A.4.c.1.c','4.A.4.a.6.b','4.A.4.a.1.a','4.A.1.b.1.b','4.A.4.a.8.c','4.A.3.a.2.h','4.A.3.a.2.ak','4.A.4.b.4.j']::text[],array[12.88,8.64,7.72,4.7,4.41,4.17,3.73,2.7,12.49]::numeric[],array[]::text[],array['41-2031.00','41-2021.00','41-9011.00']::text[],null),
  ('43-3071.00',2,2,1,1,array['4.A.2.a.2.a','4.A.4.c.1.c','4.A.2.a.2.d','4.A.4.c.1.a','4.A.4.a.8.c','4.A.1.b.3.c','4.A.3.b.1.f','4.A.4.a.3.c','4.A.4.a.6.b']::text[],array[36.88,17.28,13.43,12.11,9.17,8.77,4.69,4.56,4.03]::numeric[],array['Microsoft Office software']::text[],array['41-2011.00','43-4041.00']::text[],null),
  ('43-4041.00',2,2,2,2,array['4.A.1.a.1.n','4.A.2.a.4.k','4.A.4.a.3.c','4.A.3.b.6.j','4.A.2.a.2.c','4.A.4.c.1.a','4.A.1.a.1.w','4.A.4.c.1.e','4.A.1.a.1.d']::text[],array[10.99,9.01,6.33,4.54,4.4,4.4,4.02,3.82,3.39]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['13-2041.00','43-4131.00','13-2072.00']::text[],null),
  ('43-4051.00',2,2,18,2,array['4.A.4.a.8.c','4.A.4.c.1.c','4.A.4.a.1.a','4.A.3.b.6.j','4.A.4.a.3.c','4.A.2.b.1.a','4.A.3.b.6.m','4.A.4.a.5.a','4.A.2.a.3.c']::text[],array[12.21,7.83,4.67,4.53,4.22,4.18,4.1,4.07,4.05]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['41-9041.00','43-4041.00']::text[],null),
  ('43-4131.00',2,3,36,4,array['4.A.4.a.3.c','4.A.2.a.2.a','4.A.3.b.6.j','4.A.3.b.6.m','4.A.4.c.1.a','4.A.2.a.2.c','4.A.1.a.1.n','4.A.2.b.1.a','4.A.1.a.1.w']::text[],array[13.0,8.98,8.94,8.84,8.76,4.6,4.42,4.41,4.38]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['13-2072.00','43-4041.00','13-2041.00']::text[],null),
  ('43-4151.00',2,2,18,2,array['4.A.2.b.1.a','4.A.4.a.2.c','4.A.2.a.2.a','4.A.1.a.1.n','4.A.3.b.6.m','4.A.4.a.1.a','4.A.1.b.2.f','4.A.4.a.8.c','4.A.1.b.2.j']::text[],array[8.1,7.8,4.49,4.44,4.3,4.29,4.26,4.24,4.22]::numeric[],array['Order management software','Microsoft Office software','Microsoft Excel']::text[],array['43-5071.00','43-5051.00','43-4051.00']::text[],null),
  ('43-5011.00',2,2,0,4,array['4.A.3.a.1.f','4.A.3.b.6.h','4.A.1.a.2.b','4.A.3.a.2.ap','4.A.4.a.7.b','4.A.2.a.4.g','4.A.4.b.6.e','4.A.4.c.1.c','4.A.2.b.1.a']::text[],array[11.15,6.82,6.66,6.04,3.86,3.72,3.47,3.45,3.41]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['43-5011.01','43-5071.00','43-5051.00']::text[],'Peran operasional bandara/pelabuhan; pintu masuknya SMA/SMK.'),
  ('43-5011.01',2,2,18,4,array['4.A.2.a.4.g','4.A.3.b.6.m','4.A.4.b.6.e','4.A.4.a.1.b','4.A.4.c.1.c','4.A.2.a.3.a','4.A.4.a.7.b','4.A.3.b.6.n','4.A.4.a.5.a']::text[],array[30.39,13.45,12.9,8.65,8.55,8.14,4.63,4.47,4.45]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['43-5011.00','43-5071.00','43-5051.00']::text[],'Peran operasional; SMA/SMK dengan sertifikat kepabeanan sudah cukup untuk masuk.'),
  ('43-5021.00',2,2,9,1,array['4.A.3.a.1.j','4.A.3.a.1.f','4.A.4.a.2.c','4.A.1.a.1.q','4.A.3.b.6.h','4.A.3.a.4.a','4.A.2.a.2.b','4.A.2.a.4.g','4.A.4.c.1.e']::text[],array[9.01,8.79,8.73,4.58,4.54,4.41,4.36,4.23,4.05]::numeric[],array[]::text[],array['43-5052.00','43-5051.00','43-5071.00']::text[],null),
  ('43-5032.00',2,2,18,2,array['4.A.4.a.2.c','4.A.2.b.5.b','4.A.4.a.8.c','4.A.3.a.3.j','4.A.3.b.6.m','4.A.3.b.6.h','4.A.1.a.2.b','4.A.2.b.1.j','4.A.4.b.1.f']::text[],array[8.34,4.79,4.65,4.53,4.46,4.39,4.37,4.14,4.66]::numeric[],array['Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['43-5061.00']::text[],null),
  ('43-5041.00',2,2,2,2,array['4.A.3.b.1.f','4.A.4.a.3.c','4.A.4.a.2.g','4.A.3.a.4.a','4.A.3.b.6.h','4.A.1.a.2.a','4.A.2.a.2.a','4.A.3.a.2.i','4.A.4.a.5.a']::text[],array[8.76,7.98,7.85,4.25,4.21,4.21,4.21,3.97,3.94]::numeric[],array['Microsoft Office software']::text[],array['51-8012.00']::text[],null),
  ('43-5051.00',2,2,9,2,array['4.A.4.a.6.b','4.A.4.c.1.e','4.A.4.a.5.h','4.A.4.c.1.c','4.A.1.b.3.a','4.A.2.b.1.a','4.A.3.b.6.j','4.A.2.a.3.a','4.A.3.b.6.m']::text[],array[8.85,8.79,8.34,8.2,4.63,4.63,4.62,4.48,4.44]::numeric[],array[]::text[],array['43-5052.00','43-5071.00','43-5053.00']::text[],null),
  ('43-5052.00',2,2,0,1,array['4.A.4.c.1.e','4.A.3.a.1.j','4.A.4.a.3.c','4.A.3.b.1.f','4.A.1.a.1.q','4.A.2.a.2.b','4.A.4.c.1.c','4.A.4.c.1.a','4.A.3.b.6.h']::text[],array[26.4,9.16,7.77,4.77,4.7,4.63,4.54,4.46,4.34]::numeric[],array[]::text[],array['43-5051.00','43-5021.00','43-5071.00']::text[],null),
  ('43-5053.00',2,2,0,1,array['4.A.4.c.1.e','4.A.3.a.2.ap','4.A.3.a.1.f','4.A.2.a.3.a','4.A.3.b.5.a','4.A.3.b.1.e','4.A.3.a.4.a','4.A.1.b.1.a','4.A.2.a.2.b']::text[],array[12.71,8.49,8.46,4.45,4.44,4.35,4.28,4.27,4.1]::numeric[],array[]::text[],array['43-5071.00','43-5051.00','53-7065.00']::text[],null),
  ('43-5061.00',2,2,18,9,array['4.A.4.a.2.c','4.A.3.b.6.h','4.A.2.a.2.c','4.A.2.b.5.b','4.A.1.a.1.b','4.A.1.b.2.f','4.A.2.a.3.a','4.A.2.b.1.a','4.A.3.b.6.l']::text[],array[16.48,13.25,7.45,4.29,4.16,3.85,3.85,3.67,3.35]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['43-5071.00','51-1011.00','43-5111.00']::text[],null),
  ('43-5071.00',2,2,9,2,array['4.A.2.a.4.g','4.A.1.b.2.j','4.A.3.a.2.ak','4.A.3.b.6.m','4.A.3.a.2.ap','4.A.3.b.6.h','4.A.4.a.8.c','4.A.3.a.1.j','4.A.2.b.1.a']::text[],array[7.46,4.22,4.05,4.05,4.0,3.96,3.95,3.88,3.73]::numeric[],array['Microsoft Edge','Warehouse management system WMS','Apple Safari','Mozilla Firefox','Inventory management systems']::text[],array['43-5051.00','53-7065.00','43-5011.00']::text[],null),
  ('43-5111.00',2,2,2,2,array['4.A.1.b.2.f','4.A.1.b.2.j','4.A.3.b.6.h','4.A.1.b.3.a','4.A.1.b.1.a','4.A.4.a.2.c','4.A.3.a.2.ak','4.A.4.b.3.d','4.A.4.a.1.a']::text[],array[12.57,4.45,4.43,4.41,4.35,4.35,4.26,4.05,3.97]::numeric[],array['Inventory management systems']::text[],array['51-9061.00','43-5071.00','53-7064.00']::text[],null),
  ('47-1011.03',5,3,9,4,array['4.A.2.b.1.h','4.A.1.b.2.b','4.A.2.b.6.b','4.A.1.b.3.b','4.A.4.a.2.c','4.A.1.b.1.b','4.A.2.b.2.o','4.A.1.b.3.d','4.A.2.a.4.e']::text[],array[11.78,7.74,4.4,4.02,4.01,3.8,3.8,3.77,3.51]::numeric[],array[]::text[],array['47-2231.00','41-4011.07','47-2152.04']::text[],'Peran penyelia teknis bersertifikat; jalur masuknya D3 Teknik Elektro ke atas.'),
  ('47-2152.04',2,3,9,4,array['4.A.3.a.2.p','4.A.3.a.2.aq','4.A.1.b.2.g','4.A.3.a.2.ag','4.A.3.a.1.g','4.A.1.b.2.l','4.A.4.a.1.b','4.A.2.b.1.d','4.A.3.b.5.a']::text[],array[25.45,16.79,13.08,8.37,8.26,4.46,4.3,4.15,4.14]::numeric[],array['Microsoft Office software']::text[],array['47-2231.00','17-2199.11','47-1011.03']::text[],null),
  ('47-2231.00',2,2,18,9,array['4.A.3.a.2.p','4.A.2.b.1.d','4.A.1.b.2.b','4.A.2.b.1.j','4.A.1.b.2.g','4.A.3.a.2.t','4.A.3.a.2.ag','4.A.1.b.1.a','4.A.2.b.2.o']::text[],array[25.84,24.96,16.8,13.01,8.8,4.44,4.44,4.37,4.36]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['47-2152.04','47-1011.03','49-9081.00']::text[],null),
  ('47-4011.01',5,3,18,9,array['4.A.2.a.4.g','4.A.1.b.1.b','4.A.1.b.2.e','4.A.3.b.6.a','4.A.2.a.4.c','4.A.2.a.1.g','4.A.2.a.1.i','4.A.4.b.6.e','4.A.1.a.1.j']::text[],array[31.38,8.87,8.19,4.41,4.4,4.21,4.2,4.1,4.07]::numeric[],array['R','Python','Structured query language SQL','Microsoft PowerPoint','Microsoft Outlook']::text[],array['17-2199.03','17-2199.11','47-1011.03']::text[],'Sertifikasi auditor energi (SKKNI) mensyaratkan latar teknik minimal D3.'),
  ('47-5011.00',1,2,9,1,array['4.A.1.b.2.g','4.A.3.b.5.a','4.A.3.a.1.a','4.A.4.b.3.d','4.A.3.a.2.t','4.A.3.a.3.h','4.A.3.a.1.c','4.A.3.a.2.a','4.A.1.a.2.b']::text[],array[9.08,8.93,8.48,8.31,7.95,7.93,4.54,4.38,4.36]::numeric[],array[]::text[],array['47-5012.00','47-5071.00','47-5081.00']::text[],null),
  ('47-5012.00',2,2,36,9,array['4.A.3.b.5.a','4.A.3.a.3.h','4.A.3.a.3.c','4.A.4.b.3.d','4.A.1.b.3.d','4.A.3.a.2.t','4.A.3.b.6.h','4.A.3.a.3.b','4.A.1.b.2.g']::text[],array[12.43,8.68,8.54,4.5,4.43,4.38,4.36,4.29,4.29]::numeric[],array[]::text[],array['47-5023.00','47-5081.00','47-5013.00']::text[],null),
  ('47-5013.00',2,2,9,2,array['4.A.1.b.2.g','4.A.3.a.3.h','4.A.1.a.2.b','4.A.3.a.3.c','4.A.3.b.5.a','4.A.3.b.6.o','4.A.3.a.2.aq','4.A.4.a.2.c','4.A.3.a.3.b']::text[],array[11.22,8.49,7.79,7.44,4.57,4.39,4.35,4.19,4.18]::numeric[],array[]::text[],array['47-5012.00','47-5071.00','53-7073.00']::text[],null),
  ('47-5022.00',2,2,9,4,array['4.A.3.a.3.c','4.A.1.b.2.g','4.A.2.b.3.a','4.A.4.a.2.c','4.A.3.a.1.j','4.A.1.b.3.a','4.A.2.a.2.a','4.A.3.a.2.a','4.A.3.b.5.a']::text[],array[16.2,4.56,4.43,4.04,3.99,3.98,3.98,3.9,3.9]::numeric[],array[]::text[],array['53-7041.00','47-5041.00','49-3042.00']::text[],null),
  ('47-5023.00',2,2,9,4,array['4.A.3.a.3.c','4.A.2.b.1.j','4.A.3.a.4.a','4.A.3.a.2.v','4.A.3.b.6.h','4.A.3.b.2.c','4.A.3.a.1.c','4.A.3.a.2.al','4.A.3.a.2.aa']::text[],array[20.42,8.32,8.24,8.13,8.04,7.88,7.4,6.9,4.38]::numeric[],array[]::text[],array['47-5012.00','47-5081.00','51-4032.00']::text[],null),
  ('47-5032.00',2,2,18,9,array['4.A.3.a.2.m','4.A.3.a.2.v','4.A.3.a.3.c','4.A.3.a.2.d','4.A.3.b.5.a','4.A.3.b.6.h','4.A.1.a.2.k','4.A.2.b.1.j','4.A.3.a.1.g']::text[],array[31.12,12.7,8.83,8.18,7.55,7.5,4.88,4.88,4.57]::numeric[],array[]::text[],array['47-5023.00','47-5081.00','47-5012.00']::text[],null),
  ('47-5041.00',2,2,18,9,array['4.A.3.a.3.c','4.A.3.a.2.v','4.A.1.b.2.k','4.A.1.b.2.f','4.A.2.b.1.d','4.A.3.a.2.a','4.A.1.a.2.b','4.A.3.a.1.c','4.A.3.a.3.h']::text[],array[13.58,9.25,4.74,4.7,4.43,4.39,4.28,4.24,4.21]::numeric[],array[]::text[],array['47-5022.00','47-5081.00','47-5023.00']::text[],null),
  ('47-5043.00',2,2,4,2,array['4.A.3.a.2.a','4.A.3.a.3.c','4.A.3.a.2.v','4.A.3.a.2.at','4.A.3.a.2.ad','4.A.1.b.2.g','4.A.1.b.2.k','4.A.1.b.2.f']::text[],array[23.6,9.76,9.59,9.49,4.93,4.89,4.88,4.8]::numeric[],array[]::text[],array['47-5041.00','47-5023.00','51-2011.00']::text[],null),
  ('47-5044.00',2,2,4,2,array['4.A.3.a.3.f','4.A.3.a.2.v','4.A.3.a.1.e','4.A.3.a.3.c','4.A.3.a.4.a','4.A.3.a.1.c','4.A.3.b.4.e','4.A.3.b.6.h','4.A.1.b.3.a']::text[],array[12.64,11.67,8.68,8.64,8.34,8.22,7.47,7.45,7.08]::numeric[],array[]::text[],array['53-7051.00','47-5022.00','47-5041.00']::text[],null),
  ('47-5051.00',2,2,2,1,array['4.A.3.a.3.c','4.A.3.a.2.l','4.A.1.b.2.j','4.A.3.a.2.ad','4.A.3.a.2.ao','4.A.4.b.4.i']::text[],array[14.97,7.2,3.8,3.74,3.4,3.74]::numeric[],array[]::text[],array['47-5012.00','51-4071.00','51-7041.00']::text[],null),
  ('47-5071.00',1,2,18,9,array['4.A.3.a.1.g','4.A.3.a.2.aq','4.A.3.b.5.a','4.A.3.a.1.c','4.A.3.a.3.h','4.A.1.b.2.g','4.A.3.a.2.t','4.A.3.a.1.a','4.A.3.a.2.d']::text[],array[13.11,7.35,7.16,6.45,3.57,3.51,3.46,3.43,3.35]::numeric[],array[]::text[],array['47-5012.00','47-5013.00','53-7041.00']::text[],null),
  ('47-5081.00',2,2,0,2,array['4.A.3.a.1.g','4.A.3.b.5.a','4.A.3.a.1.f','4.A.3.a.1.c','4.A.1.a.2.b','4.A.3.a.4.a','4.A.3.a.3.c','4.A.2.b.1.j','4.A.3.a.2.al']::text[],array[7.68,7.56,7.54,7.34,4.28,4.07,3.93,3.89,3.84]::numeric[],array[]::text[],array['51-9198.00','47-5012.00','47-5023.00']::text[],null),
  ('49-2011.00',2,3,18,4,array['4.A.3.a.2.i','4.A.1.b.2.l','4.A.3.b.4.c','4.A.3.b.6.h','4.A.3.b.1.c','4.A.3.a.2.d','4.A.3.b.5.a','4.A.3.a.2.ah','4.A.4.a.2.j']::text[],array[15.81,11.96,8.46,8.15,8.14,8.07,7.25,7.08,4.38]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array[]::text[],null),
  ('49-2097.00',2,3,18,9,array['4.A.3.a.2.t','4.A.3.b.5.b','4.A.3.a.2.i','4.A.1.a.1.b','4.A.1.b.3.b','4.A.1.b.2.l','4.A.4.a.2.j','4.A.4.b.3.e','4.A.3.a.4.a']::text[],array[8.4,7.98,7.86,7.82,4.12,4.02,4.02,3.97,3.96]::numeric[],array[]::text[],array[]::text[],null),
  ('49-3011.00',2,3,36,9,array['4.A.1.b.2.d','4.A.1.a.1.b','4.A.3.b.4.c','4.A.3.a.1.c','4.A.3.a.2.d','4.A.3.a.2.s','4.A.3.b.4.e','4.A.3.a.2.ao','4.A.1.b.2.f']::text[],array[28.69,16.51,16.11,14.54,11.74,10.97,7.82,6.98,4.48]::numeric[],array['Microsoft Office software']::text[],array['51-2011.00','51-2031.00']::text[],null),
  ('49-3021.00',2,2,1,1,array['4.A.3.a.2.o','4.A.3.a.2.l','4.A.3.a.2.d','4.A.3.a.2.s','4.A.3.a.1.d','4.A.1.a.1.b','4.A.3.a.1.a','4.A.1.b.2.f','4.A.3.a.2.ai']::text[],array[25.7,15.16,12.66,12.15,8.49,7.84,7.64,4.48,4.45]::numeric[],array[]::text[],array['49-3023.00','49-3043.00','51-2011.00']::text[],null),
  ('49-3022.00',2,2,18,9,array['4.A.3.b.4.d','4.A.3.a.2.ag','4.A.3.a.2.d','4.A.3.a.2.l','4.A.2.b.1.h','4.A.1.b.2.d','4.A.3.a.1.h','4.A.3.a.2.s','4.A.3.a.2.m']::text[],array[43.58,9.73,7.97,7.11,4.66,4.46,4.35,4.3,3.89]::numeric[],array[]::text[],array['49-3021.00','49-3023.00','51-9195.00']::text[],null),
  ('49-3023.00',2,3,36,9,array['4.A.3.b.4.c','4.A.3.b.4.d','4.A.3.a.2.i','4.A.3.a.2.s','4.A.3.b.4.e','4.A.3.a.2.d','4.A.1.b.2.d','4.A.3.a.2.ao','4.A.1.b.2.l']::text[],array[29.33,23.08,19.16,12.02,11.75,10.55,8.76,8.41,8.27]::numeric[],array[]::text[],array['49-3043.00','49-3031.00','49-3052.00']::text[],null),
  ('49-3031.00',2,3,18,18,array['4.A.3.b.4.d','4.A.1.b.2.d','4.A.3.a.2.i','4.A.1.b.2.l','4.A.3.b.4.e','4.A.3.a.2.d','4.A.2.b.1.j','4.A.3.a.3.h','4.A.3.b.5.a']::text[],array[34.71,16.34,15.98,12.1,11.53,7.44,4.54,4.23,4.16]::numeric[],array[]::text[],array['49-3042.00','49-3043.00','49-3023.00']::text[],null),
  ('49-3041.00',2,3,18,9,array['4.A.3.a.2.d','4.A.1.b.2.l','4.A.3.b.4.c','4.A.3.a.2.i','4.A.3.b.4.a','4.A.1.a.1.b','4.A.1.b.2.g','4.A.3.b.4.d','4.A.3.b.4.e']::text[],array[8.96,8.96,8.84,8.66,6.67,4.54,4.54,4.54,4.54]::numeric[],array[]::text[],array['49-3042.00','49-3053.00','51-2031.00']::text[],null),
  ('49-3042.00',2,3,18,9,array['4.A.3.b.4.c','4.A.3.b.5.a','4.A.3.a.2.d','4.A.3.a.2.ai','4.A.3.a.2.i','4.A.3.a.1.c','4.A.1.b.2.f','4.A.3.a.4.a','4.A.1.b.2.g']::text[],array[21.27,11.79,8.12,8.0,7.88,7.68,4.42,4.36,4.36]::numeric[],array[]::text[],array['49-3031.00','49-3043.00']::text[],null),
  ('49-3043.00',2,2,4,4,array['4.A.3.b.4.d','4.A.1.b.2.d','4.A.3.b.4.c','4.A.3.a.2.s','4.A.3.b.6.h','4.A.1.b.2.f','4.A.3.a.2.i','4.A.3.b.5.b','4.A.3.a.2.aa']::text[],array[15.63,11.79,8.26,7.92,4.24,3.94,3.93,3.92,3.63]::numeric[],array['Disassembler software']::text[],array['49-3031.00','49-3023.00','49-3042.00']::text[],null),
  ('49-3051.00',2,3,18,4,array['4.A.3.b.4.d','4.A.1.a.2.a','4.A.1.b.2.d','4.A.3.a.2.i','4.A.3.b.4.c','4.A.3.b.6.i','4.A.3.a.2.v','4.A.3.b.4.e','4.A.3.a.2.ao']::text[],array[11.86,8.19,7.8,7.68,7.37,4.12,4.08,4.05,3.88]::numeric[],array[]::text[],array['49-3031.00','49-3052.00','49-3053.00']::text[],null),
  ('49-3052.00',2,3,36,2,array['4.A.3.a.2.d','4.A.3.b.4.d','4.A.3.b.4.c','4.A.3.a.2.i','4.A.3.a.2.s','4.A.1.b.2.l','4.A.3.a.2.o','4.A.1.b.2.d','4.A.1.a.2.a']::text[],array[21.81,18.12,18.07,9.14,9.08,8.87,7.34,4.74,4.51]::numeric[],array[]::text[],array['49-3091.00','49-3051.00','49-3023.00']::text[],null),
  ('49-3053.00',2,2,18,4,array['4.A.3.b.4.c','4.A.1.b.2.d','4.A.3.b.5.a','4.A.3.a.2.s','4.A.3.a.2.d','4.A.3.b.6.h','4.A.1.b.2.l','4.A.3.b.4.d','4.A.3.a.2.i']::text[],array[13.16,9.05,8.83,8.66,8.47,4.62,4.56,4.48,4.46]::numeric[],array[]::text[],array['49-3031.00','49-3052.00','49-3042.00']::text[],null),
  ('49-3091.00',1,2,18,4,array['4.A.3.a.2.d','4.A.3.a.2.i','4.A.4.a.1.a','4.A.3.a.2.ao','4.A.4.a.6.b','4.A.3.b.4.a','4.A.3.a.2.s','4.A.3.a.2.o','4.A.3.b.4.d']::text[],array[26.6,9.33,4.75,4.68,4.61,4.48,4.14,3.3,2.78]::numeric[],array[]::text[],array['49-3052.00','49-3093.00','49-3053.00']::text[],null),
  ('49-3093.00',2,2,9,2,array['4.A.3.b.4.d','4.A.3.a.2.d','4.A.1.b.2.d','4.A.3.b.4.e','4.A.3.a.2.s','4.A.3.a.2.o','4.A.3.a.1.c','4.A.3.a.3.h','4.A.1.b.2.l']::text[],array[20.91,17.43,12.61,8.76,8.49,8.07,7.26,4.62,4.5]::numeric[],array['Microsoft Outlook']::text[],array['49-3023.00','49-3052.00','49-3043.00']::text[],null),
  ('49-9044.00',2,2,18,36,array['4.A.3.a.2.d','4.A.3.a.2.ao','4.A.3.a.2.v','4.A.3.a.2.aa','4.A.3.a.2.i','4.A.3.b.5.a','4.A.3.b.4.c','4.A.3.a.2.ai','4.A.3.a.2.s']::text[],array[21.68,13.47,12.86,11.4,9.49,9.18,8.86,8.5,8.19]::numeric[],array[]::text[],array['51-2011.00','51-2031.00']::text[],null),
  ('49-9061.00',2,3,36,18,array['4.A.3.a.2.i','4.A.1.a.1.b','4.A.3.a.2.s','4.A.1.b.2.l','4.A.3.b.5.a','4.A.3.a.1.c','4.A.3.a.2.t','4.A.1.b.2.g','4.A.1.b.3.a']::text[],array[8.55,7.98,4.4,4.37,4.34,4.34,4.31,4.05,3.97]::numeric[],array[]::text[],array['27-4015.00']::text[],null),
  ('49-9081.00',2,3,9,9,array['4.A.1.b.2.l','4.A.3.b.4.c','4.A.2.b.1.b','4.A.3.b.5.a','4.A.3.a.1.n','4.A.4.b.3.e','4.A.4.b.3.d','4.A.1.b.2.g','4.A.3.a.2.a']::text[],array[21.12,12.78,4.74,4.6,4.48,3.83,3.83,3.47,3.11]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['51-8013.04','51-8013.00','47-2231.00']::text[],null),
  ('51-1011.00',2,3,18,4,array['4.A.2.b.6.b','4.A.3.b.6.h','4.A.4.b.3.e','4.A.3.a.1.k','4.A.1.b.2.g','4.A.1.a.1.b','4.A.4.a.2.c','4.A.1.a.2.a','4.A.2.a.1.d']::text[],array[11.21,8.05,8.05,4.48,4.23,4.22,4.15,4.02,4.0]::numeric[],array['SAP software','Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array[]::text[],null),
  ('51-2011.00',2,2,18,4,array['4.A.3.a.2.aj','4.A.3.a.2.a','4.A.3.a.2.ao','4.A.3.a.2.l','4.A.3.a.3.f','4.A.3.a.2.d','4.A.3.a.1.h','4.A.3.a.2.ai','4.A.1.a.1.b']::text[],array[17.0,16.65,12.71,12.19,8.36,8.21,8.17,7.54,4.4]::numeric[],array[]::text[],array['51-2031.00','51-2041.00','51-2023.00']::text[],null),
  ('51-2021.00',2,2,0,4,array['4.A.3.a.2.l','4.A.3.b.6.h','4.A.3.a.3.f','4.A.3.a.2.d','4.A.1.a.1.b','4.A.1.b.2.l','4.A.3.a.1.f','4.A.2.b.1.j','4.A.3.a.2.aj']::text[],array[8.83,8.62,8.46,4.4,4.4,4.38,4.25,4.25,4.07]::numeric[],array[]::text[],array['51-2022.00','51-4034.00','51-6091.00']::text[],null),
  ('51-2022.00',2,2,0,2,array['4.A.3.a.2.d','4.A.1.a.1.b','4.A.3.a.2.ai','4.A.1.b.2.l','4.A.3.b.6.h','4.A.3.b.4.b','4.A.3.a.2.ao','4.A.1.b.1.a','4.A.4.b.3.e']::text[],array[12.31,8.98,8.88,8.08,7.98,4.2,4.17,4.05,4.03]::numeric[],array[]::text[],array['51-2023.00','51-2011.00','51-2031.00']::text[],null),
  ('51-2023.00',2,2,18,4,array['4.A.3.a.2.ao','4.A.3.a.2.d','4.A.1.b.2.f','4.A.3.a.2.ah','4.A.1.b.3.a','4.A.1.a.1.b','4.A.1.b.1.a','4.A.3.a.2.g','4.A.3.a.2.s']::text[],array[8.58,7.1,4.37,4.14,4.12,4.01,3.92,3.72,3.63]::numeric[],array[]::text[],array['51-2022.00','51-2031.00','51-2011.00']::text[],null),
  ('51-2031.00',2,2,9,4,array['4.A.3.a.2.ao','4.A.3.a.2.d','4.A.2.b.6.b','4.A.1.a.1.b','4.A.1.b.2.f','4.A.3.a.2.at','4.A.1.b.3.a','4.A.3.a.2.o','4.A.3.a.2.ad']::text[],array[8.51,8.21,4.65,4.65,4.46,4.4,4.39,4.15,4.09]::numeric[],array[]::text[],array['51-2011.00','51-2023.00','51-2022.00']::text[],null),
  ('51-2041.00',2,2,4,2,array['4.A.3.a.2.ao','4.A.3.a.3.l','4.A.1.a.1.b','4.A.3.a.2.ai','4.A.3.a.3.h','4.A.3.a.2.f','4.A.3.a.2.g','4.A.3.a.2.o','4.A.3.a.2.m']::text[],array[20.36,15.72,8.82,8.63,8.22,8.05,7.42,7.08,7.0]::numeric[],array['Microsoft Outlook']::text[],array['51-2011.00','51-4192.00','51-4122.00']::text[],null),
  ('51-2051.00',2,2,0,2,array['4.A.3.a.1.f','4.A.3.a.2.an','4.A.1.b.2.g','4.A.3.a.1.g','4.A.3.a.2.l','4.A.3.a.2.o','4.A.3.a.1.h','4.A.3.a.1.a','4.A.1.b.3.a']::text[],array[12.94,8.51,8.16,8.04,7.5,4.55,4.43,4.43,4.38]::numeric[],array[]::text[],array['51-9195.00','51-4071.00','51-2041.00']::text[],null),
  ('51-2092.00',2,2,4,4,array['4.A.3.a.2.d','4.A.2.a.1.e','4.A.1.a.1.b','4.A.3.b.5.a','4.A.3.b.6.h','4.A.2.b.6.b','4.A.4.b.3.e','4.A.3.a.2.ap','4.A.3.a.1.c']::text[],array[8.39,4.62,4.43,4.17,4.08,4.04,3.94,3.93,3.74]::numeric[],array[]::text[],array['51-2022.00','51-2031.00','51-2023.00']::text[],null),
  ('51-3011.00',2,2,4,1,array['4.A.2.a.1.e','4.A.3.a.2.i','4.A.3.a.3.f','4.A.3.a.2.ag','4.A.3.a.1.f','4.A.1.b.3.a','4.A.1.b.2.f','4.A.1.a.2.a','4.A.3.a.1.c']::text[],array[9.2,9.14,9.08,8.39,4.58,4.49,4.47,4.41,4.41]::numeric[],array[]::text[],array['51-3092.00','51-3093.00','51-3091.00']::text[],null),
  ('51-3021.00',2,2,18,4,array['4.A.3.a.2.c','4.A.1.b.1.a','4.A.1.b.3.a','4.A.1.b.2.f','4.A.2.b.1.h','4.A.3.b.6.h','4.A.3.a.1.f','4.A.4.a.2.j','4.A.4.c.3.e']::text[],array[30.68,4.6,4.6,4.46,4.28,4.22,3.99,3.93,4.28]::numeric[],array[]::text[],array['51-3022.00','51-3023.00','51-3011.00']::text[],null),
  ('51-3022.00',1,2,2,2,array['4.A.3.a.2.c','4.A.3.a.2.ac','4.A.1.b.1.a','4.A.1.b.3.a','4.A.1.b.2.f','4.A.2.a.2.b','4.A.4.c.3.c']::text[],array[38.52,12.18,4.48,4.48,4.33,4.25,4.03]::numeric[],array['Web browser software']::text[],array['51-3023.00','51-3021.00','53-7064.00']::text[],null),
  ('51-3023.00',2,2,9,9,array['4.A.3.a.2.ac','4.A.3.a.2.c','4.A.3.a.1.h']::text[],array[52.38,30.5,8.69]::numeric[],array[]::text[],array['51-3022.00','51-3021.00']::text[],null),
  ('51-3091.00',2,2,0,4,array['4.A.3.a.2.f','4.A.1.b.2.f','4.A.1.a.2.a','4.A.1.b.3.a','4.A.3.a.2.i','4.A.3.a.2.b','4.A.2.a.1.e','4.A.3.a.3.b','4.A.4.a.2.g']::text[],array[12.02,8.93,8.72,8.66,8.65,4.58,4.58,4.57,4.36]::numeric[],array[]::text[],array['51-3092.00','51-3093.00','51-9012.00']::text[],null),
  ('51-3092.00',2,2,2,2,array['4.A.3.a.3.f','4.A.2.b.1.d','4.A.1.b.2.f','4.A.3.a.1.c','4.A.1.a.2.a','4.A.2.a.1.e','4.A.3.b.6.h','4.A.1.b.2.g','4.A.1.b.3.a']::text[],array[40.48,13.17,13.1,9.46,8.97,8.61,4.77,4.61,4.55]::numeric[],array[]::text[],array['51-3093.00','51-3091.00','51-9023.00']::text[],null),
  ('51-3093.00',2,2,2,2,array['4.A.3.a.2.i','4.A.3.a.3.f','4.A.3.a.1.c','4.A.1.a.1.b','4.A.1.a.2.a','4.A.1.b.3.a','4.A.3.b.6.h','4.A.3.a.3.b','4.A.3.a.2.an']::text[],array[17.41,13.13,9.3,9.22,8.83,4.52,4.45,4.41,4.37]::numeric[],array[]::text[],array['51-3092.00','51-3091.00','51-9012.00']::text[],null),
  ('51-4021.00',2,2,0,2,array['4.A.1.b.3.a','4.A.1.b.2.f','4.A.3.a.2.f','4.A.3.a.3.f','4.A.2.b.1.j','4.A.3.b.4.c','4.A.2.b.1.d','4.A.3.a.2.i','4.A.3.a.2.ap']::text[],array[8.52,8.51,8.22,7.99,7.7,7.41,4.33,4.29,4.28]::numeric[],array[]::text[],array['51-6091.00','51-4072.00','51-4031.00']::text[],null),
  ('51-4022.00',2,2,4,4,array['4.A.3.a.3.f','4.A.3.a.2.f','4.A.3.a.2.s','4.A.3.a.3.l','4.A.3.b.4.c','4.A.3.b.5.a','4.A.1.a.1.b','4.A.1.b.3.a','4.A.1.b.2.l']::text[],array[13.06,12.59,8.25,7.94,7.8,7.43,4.54,4.43,4.29]::numeric[],array[]::text[],array['51-4031.00','51-7042.00','51-4111.00']::text[],null),
  ('51-4023.00',2,2,2,2,array['4.A.3.a.3.f','4.A.1.a.1.b','4.A.1.a.2.a','4.A.3.a.2.f','4.A.3.a.2.at','4.A.3.a.3.l','4.A.1.b.2.f','4.A.1.b.3.a','4.A.2.b.1.h']::text[],array[13.3,13.02,12.71,8.3,8.24,7.7,4.39,4.39,4.11]::numeric[],array[]::text[],array['51-9032.00','51-4031.00','51-4033.00']::text[],null),
  ('51-4031.00',2,2,36,2,array['4.A.3.a.3.l','4.A.3.a.2.f','4.A.3.b.5.a','4.A.3.a.1.c','4.A.3.a.2.i','4.A.3.a.2.ai','4.A.1.a.1.b','4.A.3.a.2.at','4.A.3.a.2.ao']::text[],array[20.21,16.25,16.13,11.53,11.2,10.11,8.94,8.21,7.83]::numeric[],array[]::text[],array['51-9032.00','51-7042.00','51-4035.00']::text[],null),
  ('51-4032.00',2,2,18,9,array['4.A.3.a.2.ao','4.A.1.a.1.b','4.A.3.a.2.i','4.A.3.a.2.f','4.A.3.a.2.ad','4.A.1.b.3.a','4.A.3.b.4.c','4.A.1.a.2.a','4.A.3.a.3.h']::text[],array[15.65,14.1,8.59,8.54,8.48,4.84,4.46,4.33,4.25]::numeric[],array[]::text[],array['51-4035.00','51-4034.00','51-7042.00']::text[],null),
  ('51-4033.00',2,2,4,2,array['4.A.3.a.3.l','4.A.1.b.3.a','4.A.3.a.2.f','4.A.1.a.1.b','4.A.3.b.4.c','4.A.3.a.2.at','4.A.3.a.2.ao','4.A.1.a.2.a','4.A.2.b.1.j']::text[],array[21.33,13.39,11.73,8.72,7.58,6.15,4.44,4.41,4.33]::numeric[],array[]::text[],array['51-4194.00','51-7042.00','51-4035.00']::text[],null),
  ('51-4034.00',2,2,9,9,array['4.A.3.a.2.f','4.A.1.a.1.b','4.A.1.b.3.a','4.A.3.a.3.l','4.A.3.b.1.a','4.A.3.a.2.i','4.A.3.a.3.f','4.A.3.b.5.a','4.A.3.b.4.c']::text[],array[19.07,8.6,8.38,8.27,7.86,7.79,4.34,4.22,4.22]::numeric[],array[]::text[],array['51-4035.00','51-4033.00','51-4081.00']::text[],null),
  ('51-4035.00',2,2,36,4,array['4.A.3.a.2.f','4.A.3.a.2.i','4.A.1.a.1.b','4.A.3.a.2.an','4.A.3.a.2.ao','4.A.1.a.2.a','4.A.2.b.1.j','4.A.3.a.3.l','4.A.3.b.5.a']::text[],array[16.77,12.12,8.4,4.45,4.37,4.33,4.32,4.2,4.2]::numeric[],array[]::text[],array['51-4034.00','51-4033.00','51-7042.00']::text[],null),
  ('51-4041.00',2,3,18,4,array['4.A.1.b.3.a','4.A.3.a.3.l','4.A.3.a.3.f','4.A.3.a.2.f','4.A.1.a.2.a','4.A.4.a.2.c','4.A.1.b.2.l','4.A.3.a.2.d','4.A.4.b.6.e']::text[],array[18.22,13.48,8.89,8.45,8.38,8.35,8.29,7.98,7.85]::numeric[],array['G-code','Mastercam computer-aided design and manufacturing software']::text[],array['51-9161.00','51-4035.00','51-4111.00']::text[],null),
  ('51-4051.00',2,2,4,4,array['4.A.3.a.2.i','4.A.3.a.2.m','4.A.1.a.2.a','4.A.3.a.1.f','4.A.2.b.1.h','4.A.3.a.2.b','4.A.3.a.1.h','4.A.1.b.3.a','4.A.3.b.6.h']::text[],array[22.84,12.86,8.75,8.64,4.6,4.6,4.55,4.54,4.51]::numeric[],array[]::text[],array['51-4191.00','51-9051.00','51-9012.00']::text[],null),
  ('51-4052.00',2,2,0,4,array['4.A.3.a.2.i','4.A.3.a.1.f','4.A.3.a.2.an','4.A.1.a.2.a','4.A.3.a.1.c','4.A.3.a.2.d','4.A.1.b.2.g','4.A.3.a.2.b','4.A.3.a.2.f']::text[],array[18.4,13.31,8.89,4.66,4.63,4.62,4.59,4.57,4.45]::numeric[],array[]::text[],array['51-9195.00','51-4023.00','51-4022.00']::text[],null),
  ('51-4061.00',2,3,18,9,array['4.A.3.a.2.aj','4.A.1.a.1.b','4.A.3.a.3.l','4.A.3.b.1.a','4.A.3.a.2.ao','4.A.3.a.3.f','4.A.3.a.2.l','4.A.3.a.2.g','4.A.1.b.2.f']::text[],array[10.86,8.98,8.26,8.08,7.4,4.31,4.18,4.18,4.18]::numeric[],array[]::text[],array['51-4111.00','51-4192.00','51-4041.00']::text[],null),
  ('51-4062.00',2,3,4,4,array['4.A.1.b.3.a','4.A.3.a.3.l','4.A.2.b.2.k','4.A.3.a.2.aj','4.A.3.a.2.ag','4.A.3.b.1.a','4.A.3.b.4.b','4.A.3.a.2.ai','4.A.1.a.1.b']::text[],array[8.17,7.91,7.74,7.53,6.0,4.56,3.85,3.84,3.79]::numeric[],array[]::text[],array['51-6092.00','51-4111.00','51-4192.00']::text[],null),
  ('51-4071.00',2,2,0,2,array['4.A.3.a.2.aj','4.A.3.a.1.f','4.A.3.a.2.an','4.A.3.a.1.c','4.A.3.a.2.o','4.A.3.a.2.v','4.A.3.a.3.h','4.A.3.a.3.f','4.A.3.a.2.l']::text[],array[18.19,13.69,8.8,4.68,4.68,4.64,4.44,4.32,4.26]::numeric[],array[]::text[],array['51-9195.00','51-4072.00','51-2051.00']::text[],null),
  ('51-4072.00',2,2,9,4,array['4.A.3.a.2.f','4.A.3.a.1.f','4.A.3.b.5.a','4.A.3.a.2.an','4.A.1.a.2.a','4.A.1.a.1.b','4.A.3.a.3.f','4.A.2.b.1.j','4.A.3.a.1.c']::text[],array[14.89,13.82,11.36,11.06,8.39,8.18,7.96,7.37,7.37]::numeric[],array[]::text[],array['51-4021.00','51-9195.00','51-6091.00']::text[],null),
  ('51-4081.00',2,2,9,4,array['4.A.3.a.2.i','4.A.1.b.3.a','4.A.3.a.2.f','4.A.3.a.3.l','4.A.3.b.5.a','4.A.1.a.1.b','4.A.2.b.1.j','4.A.3.b.4.c','4.A.3.b.1.a']::text[],array[19.71,12.57,12.5,12.35,11.38,8.66,8.32,7.98,7.34]::numeric[],array[]::text[],array['51-4034.00','51-4035.00','51-4033.00']::text[],null),
  ('51-4111.00',2,3,36,9,array['4.A.1.b.3.a','4.A.3.a.3.l','4.A.3.a.2.o','4.A.1.b.2.f','4.A.3.a.2.f','4.A.3.b.2.c','4.A.3.a.3.f','4.A.1.a.1.b','4.A.3.a.2.ai']::text[],array[12.7,12.3,11.88,8.04,7.59,7.46,4.37,4.19,4.12]::numeric[],array[]::text[],array['51-4194.00','51-4061.00','51-4035.00']::text[],null),
  ('51-4121.00',2,2,18,4,array['4.A.3.a.2.ai','4.A.3.a.2.m','4.A.3.a.3.l','4.A.3.a.2.g','4.A.1.b.3.a','4.A.2.b.1.j','4.A.1.a.2.a','4.A.3.a.2.l','4.A.3.a.1.k']::text[],array[31.67,15.4,11.13,10.85,8.41,8.16,8.05,7.64,4.61]::numeric[],array[]::text[],array['51-4122.00','51-2041.00','51-2011.00']::text[],null),
  ('51-4122.00',2,2,9,2,array['4.A.3.a.2.ai','4.A.3.a.2.ao','4.A.3.b.5.a','4.A.1.a.1.b','4.A.3.a.3.l','4.A.3.a.2.aj','4.A.3.a.2.i','4.A.3.b.6.h','4.A.2.b.1.j']::text[],array[22.23,11.82,11.71,8.4,7.9,7.87,7.86,7.83,7.8]::numeric[],array[]::text[],array['51-4121.00','51-4035.00','51-2041.00']::text[],null),
  ('51-4191.00',2,2,4,4,array['4.A.3.a.2.i','4.A.3.a.2.f','4.A.1.a.1.b','4.A.2.b.1.d','4.A.3.a.3.f','4.A.1.b.2.f','4.A.3.a.1.f','4.A.3.b.4.c','4.A.3.b.6.h']::text[],array[13.03,12.28,9.66,9.37,9.04,8.99,8.99,7.7,4.69]::numeric[],array['Microsoft Word']::text[],array['51-4051.00','51-9051.00','51-4072.00']::text[],null),
  ('51-4192.00',2,2,18,9,array['4.A.3.a.2.ao','4.A.2.b.2.k','4.A.3.a.2.aj','4.A.2.b.6.b','4.A.3.a.2.ab','4.A.1.b.3.a','4.A.3.a.2.a','4.A.3.a.3.h','4.A.1.b.2.f']::text[],array[21.57,8.08,8.06,4.4,4.19,4.18,4.09,4.06,4.05]::numeric[],array[]::text[],array['51-2041.00','51-2011.00','51-4062.00']::text[],null),
  ('51-4193.00',2,2,0,4,array['4.A.3.a.2.m','4.A.1.b.3.a','4.A.3.a.3.f','4.A.3.a.1.h','4.A.3.b.5.a','4.A.3.a.2.i','4.A.3.a.2.f','4.A.3.a.1.c','4.A.3.a.1.f']::text[],array[19.86,16.46,12.83,11.41,10.52,8.07,7.82,7.13,7.12]::numeric[],array[]::text[],array['51-4191.00','51-4122.00','51-4072.00']::text[],null),
  ('51-4194.00',2,2,4,4,array['4.A.3.a.3.l','4.A.1.a.1.b','4.A.3.a.2.i','4.A.1.b.3.a','4.A.3.a.2.f','4.A.3.b.5.a','4.A.3.a.2.ag','4.A.1.a.2.a','4.A.1.b.2.f']::text[],array[8.89,8.82,8.74,8.5,8.44,8.32,8.19,4.54,4.5]::numeric[],array[]::text[],array['51-4033.00','51-4035.00','51-7042.00']::text[],null),
  ('51-5111.00',2,3,36,4,array['4.A.3.a.3.f','4.A.3.b.1.a','4.A.1.b.2.f','4.A.3.b.5.a','4.A.1.a.2.a','4.A.2.b.1.j','4.A.1.b.3.a','4.A.1.b.2.j','4.A.3.a.1.c']::text[],array[21.94,13.6,12.41,8.47,4.41,4.38,4.27,4.16,4.01]::numeric[],array['Adobe Creative Cloud software','Adobe InDesign','Adobe Illustrator','Adobe Photoshop','Microsoft Office software']::text[],array['51-5112.00','51-5113.00']::text[],null),
  ('51-5112.00',2,2,36,2,array['4.A.1.a.1.b','4.A.1.b.2.f','4.A.3.a.2.f','4.A.3.a.1.f','4.A.3.b.1.a','4.A.3.a.1.c','4.A.3.a.2.i','4.A.3.b.1.f','4.A.3.a.3.f']::text[],array[9.28,9.23,9.03,8.86,8.63,8.6,8.56,8.51,4.67]::numeric[],array[]::text[],array['51-9196.00','51-5111.00','51-9191.00']::text[],null),
  ('51-5113.00',2,2,18,4,array['4.A.3.a.3.f','4.A.3.a.2.e','4.A.3.a.2.l','4.A.3.a.2.f','4.A.3.a.1.f','4.A.1.b.2.f','4.A.1.a.1.b','4.A.1.a.2.a','4.A.3.a.1.c']::text[],array[28.89,13.14,13.01,8.9,8.23,4.59,4.55,4.42,4.4]::numeric[],array[]::text[],array['51-9196.00','51-9032.00','51-9191.00']::text[],null),
  ('51-6011.00',1,2,1,1,array['4.A.3.a.1.h','4.A.1.b.2.j','4.A.2.a.2.b','4.A.3.a.1.a','4.A.3.a.2.f','4.A.1.b.2.f','4.A.3.a.2.an','4.A.3.a.1.c','4.A.3.b.5.a']::text[],array[37.26,11.79,8.33,7.86,7.01,4.21,4.21,4.15,4.15]::numeric[],array[]::text[],array['53-7061.00','51-6021.00','51-9192.00']::text[],null),
  ('51-6021.00',1,2,18,4,array['4.A.3.a.3.f','4.A.3.a.2.f','4.A.3.a.2.m','4.A.3.a.1.h','4.A.1.b.3.a','4.A.2.b.1.j','4.A.3.a.2.at','4.A.1.b.1.a','4.A.3.a.2.ap']::text[],array[47.28,17.15,12.57,8.45,8.28,7.89,7.75,4.58,4.58]::numeric[],array[]::text[],array['51-6031.00','51-6011.00','51-6042.00']::text[],null),
  ('51-6031.00',1,2,9,4,array['4.A.3.a.2.f','4.A.3.a.2.e','4.A.3.a.2.ao','4.A.3.a.2.l','4.A.1.b.2.j','4.A.3.a.2.ab','4.A.1.a.2.a','4.A.3.a.1.f','4.A.3.a.2.s']::text[],array[24.71,23.25,11.31,8.52,8.25,7.98,4.39,4.32,4.17]::numeric[],array[]::text[],array['51-6042.00','51-6051.00','51-6021.00']::text[],null),
  ('51-6041.00',2,2,0,2,array['4.A.3.a.2.e','4.A.3.a.2.aj','4.A.3.a.2.l','4.A.3.a.2.ab','4.A.3.a.2.f','4.A.3.a.2.ao','4.A.3.a.1.h','4.A.3.a.2.o','4.A.2.a.1.e']::text[],array[34.07,18.13,13.52,12.25,8.78,7.85,4.47,4.47,4.41]::numeric[],array[]::text[],array['51-6042.00','51-6051.00','51-6031.00']::text[],null),
  ('51-6042.00',2,2,0,2,array['4.A.3.a.2.e','4.A.3.a.2.f','4.A.3.a.2.aj','4.A.1.b.2.f','4.A.1.a.2.k','4.A.3.a.2.ao','4.A.3.a.2.an','4.A.3.a.1.f','4.A.1.a.1.b']::text[],array[25.09,16.94,8.0,4.68,4.68,4.67,4.46,4.35,4.34]::numeric[],array[]::text[],array['51-6031.00','51-9032.00','51-6041.00']::text[],null),
  ('51-6051.00',1,2,0,1,array['4.A.3.a.2.l','4.A.3.a.2.e','4.A.1.b.3.a','4.A.1.b.3.e','4.A.2.b.1.j','4.A.3.a.2.ao','4.A.3.a.2.o','4.A.2.b.2.k','4.A.3.a.2.f']::text[],array[14.06,13.3,9.75,4.94,4.83,4.81,4.7,4.4,4.34]::numeric[],array[]::text[],array['51-6031.00','51-6052.00','51-6041.00']::text[],null),
  ('51-6052.00',2,2,9,2,array['4.A.3.a.2.e','4.A.1.b.3.e','4.A.3.a.2.l','4.A.3.a.2.f','4.A.1.b.3.a','4.A.3.b.6.h','4.A.3.a.3.f','4.A.2.b.1.a','4.A.3.a.2.v']::text[],array[49.66,8.5,8.22,7.84,4.35,4.25,4.09,4.04,4.0]::numeric[],array[]::text[],array['51-6051.00','51-6092.00','51-6031.00']::text[],null),
  ('51-6061.00',2,2,1,2,array['4.A.1.a.2.a','4.A.3.a.1.h','4.A.3.a.2.e','4.A.4.a.2.c','4.A.3.a.2.f','4.A.1.b.3.a','4.A.4.a.2.g','4.A.3.a.2.ag','4.A.3.a.2.an']::text[],array[9.08,9.03,9.0,8.44,7.96,4.64,4.53,4.52,4.46]::numeric[],array[]::text[],array['51-9192.00','51-9191.00','53-7063.00']::text[],null),
  ('51-6062.00',2,2,2,2,array['4.A.3.a.3.l','4.A.1.b.2.f','4.A.3.a.2.f','4.A.3.a.2.i','4.A.4.a.2.c','4.A.3.b.4.c','4.A.1.a.2.k','4.A.3.a.2.v','4.A.3.a.2.l']::text[],array[20.82,8.84,8.38,8.3,8.14,7.64,4.42,4.29,4.29]::numeric[],array[]::text[],array['51-9032.00','51-9196.00','51-7042.00']::text[],null),
  ('51-6063.00',2,2,4,2,array['4.A.3.a.3.l','4.A.1.b.2.f','4.A.3.a.2.f','4.A.1.b.2.g','4.A.3.b.4.c','4.A.4.a.2.c','4.A.3.a.2.l','4.A.4.a.2.g','4.A.3.b.1.a']::text[],array[20.54,9.12,8.89,8.67,8.24,8.19,4.5,4.45,4.38]::numeric[],array[]::text[],array['51-6064.00','51-6031.00','51-6062.00']::text[],null),
  ('51-6064.00',1,2,0,2,array['4.A.3.a.3.l','4.A.3.a.2.f','4.A.1.a.2.a','4.A.3.b.4.c','4.A.3.a.2.l','4.A.4.a.2.g','4.A.3.a.1.f','4.A.1.b.2.g','4.A.3.b.6.h']::text[],array[24.92,12.34,8.69,7.86,4.58,4.49,4.29,4.27,4.25]::numeric[],array[]::text[],array['51-6063.00','51-9196.00','51-6091.00']::text[],null),
  ('51-6091.00',2,2,9,4,array['4.A.3.a.1.c','4.A.3.a.3.f','4.A.3.a.2.i','4.A.1.a.2.a','4.A.3.b.6.h','4.A.4.a.2.g','4.A.3.a.1.f','4.A.1.b.1.a','4.A.3.a.3.b']::text[],array[15.4,12.45,12.22,8.06,7.78,4.25,4.03,3.94,3.91]::numeric[],array[]::text[],array['51-4021.00','51-9041.00','51-9196.00']::text[],null),
  ('51-6092.00',2,3,36,9,array['4.A.2.b.2.k','4.A.3.a.2.ao','4.A.3.a.2.aj','4.A.3.b.1.a','4.A.3.a.2.f','4.A.1.b.3.a','4.A.1.b.1.a','4.A.3.a.2.v','4.A.4.a.2.j']::text[],array[21.67,20.7,8.3,4.58,4.48,4.45,4.44,4.35,4.19]::numeric[],array['Adobe Illustrator','Adobe Photoshop','Autodesk AutoCAD','Microsoft Office software','Microsoft Excel']::text[],array['51-4062.00','51-6051.00','51-6052.00']::text[],null),
  ('51-6093.00',2,2,18,2,array['4.A.3.b.4.b','4.A.3.a.2.e','4.A.3.a.2.ao','4.A.3.a.2.f','4.A.1.b.3.a','4.A.3.a.2.l','4.A.3.a.2.aj','4.A.1.a.1.b','4.A.1.b.2.j']::text[],array[23.27,16.62,8.78,8.74,4.49,4.49,4.45,4.35,4.2]::numeric[],array[]::text[],array['51-7021.00','51-7011.00','51-6051.00']::text[],null),
  ('51-7011.00',2,2,36,4,array['4.A.3.a.2.aj','4.A.3.a.2.l','4.A.1.b.3.a','4.A.1.a.1.b','4.A.3.a.2.ag','4.A.3.a.3.l','4.A.2.b.1.a','4.A.2.b.1.h','4.A.3.a.2.ab']::text[],array[13.17,12.5,8.97,8.8,7.54,4.4,4.28,4.28,4.19]::numeric[],array[]::text[],array['51-7021.00','51-7042.00']::text[],null),
  ('51-7021.00',2,2,18,4,array['4.A.3.a.2.ag','4.A.3.a.2.g','4.A.3.b.4.b','4.A.3.a.2.s','4.A.3.a.1.h','4.A.4.a.2.j','4.A.3.a.2.am','4.A.3.a.3.l','4.A.4.b.6.e']::text[],array[19.47,12.28,12.17,8.05,8.04,4.34,4.26,4.24,4.11]::numeric[],array[]::text[],array['51-6093.00','51-7011.00','51-9195.00']::text[],null),
  ('51-7041.00',2,2,2,2,array['4.A.3.a.2.f','4.A.3.b.5.a','4.A.1.a.1.b','4.A.3.a.2.i','4.A.1.b.2.j','4.A.1.b.3.a','4.A.3.a.2.l','4.A.3.a.3.l','4.A.2.b.1.j']::text[],array[17.13,16.49,12.12,8.99,8.78,8.7,8.35,8.32,8.06]::numeric[],array[]::text[],array['51-7042.00','51-9032.00','51-4033.00']::text[],null),
  ('51-7042.00',2,2,4,2,array['4.A.3.a.2.f','4.A.3.a.3.l','4.A.3.a.2.i','4.A.2.b.1.j','4.A.3.a.1.f','4.A.3.a.1.c','4.A.3.b.5.a','4.A.1.b.3.a','4.A.1.b.2.l']::text[],array[20.85,16.46,12.8,8.42,8.28,8.08,7.6,4.38,4.36]::numeric[],array[]::text[],array['51-7041.00','51-9032.00','51-4033.00']::text[],null),
  ('51-8012.00',2,3,36,9,array['4.A.3.a.3.g','4.A.2.b.6.b','4.A.3.b.6.h','4.A.4.a.2.c','4.A.1.a.2.a','4.A.2.b.1.h','4.A.1.b.2.g','4.A.1.a.2.h','4.A.3.a.2.i']::text[],array[22.88,8.98,8.43,4.75,4.54,4.3,4.2,4.14,4.14]::numeric[],array[]::text[],array['51-8013.00','51-8021.00','51-8013.04']::text[],null),
  ('51-8013.00',2,2,36,36,array['4.A.3.a.3.g','4.A.3.a.3.b','4.A.3.b.5.a','4.A.1.a.2.a','4.A.3.a.2.i','4.A.4.a.2.c','4.A.3.b.6.h','4.A.3.b.4.c','4.A.1.a.2.b']::text[],array[43.12,13.37,13.14,12.31,8.98,8.69,7.14,6.52,6.0]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['51-8013.04','51-8013.03','51-8092.00']::text[],null),
  ('51-8013.03',2,2,36,18,array['4.A.3.a.3.g','4.A.1.b.2.c','4.A.3.b.6.h','4.A.1.b.3.a','4.A.1.b.2.g','4.A.4.a.2.g','4.A.3.a.3.b','4.A.3.a.1.f','4.A.2.b.1.h']::text[],array[22.76,9.24,8.86,8.25,4.43,4.43,4.37,4.32,4.32]::numeric[],array[]::text[],array['51-8099.01','51-8013.00','51-8021.00']::text[],null),
  ('51-8013.04',5,3,36,18,array['4.A.3.a.3.g','4.A.3.b.5.a','4.A.1.b.2.g','4.A.3.a.2.d','4.A.3.a.2.ai','4.A.3.b.6.h','4.A.1.a.2.a','4.A.2.b.1.b','4.A.3.a.1.c']::text[],array[17.26,12.4,8.34,8.22,8.08,7.99,4.43,4.38,4.34]::numeric[],array[]::text[],array['51-8013.00','49-9081.00','51-8013.03']::text[],null),
  ('51-8021.00',2,3,36,9,array['4.A.3.a.2.i','4.A.1.a.2.a','4.A.3.a.3.g','4.A.3.b.6.h','4.A.3.a.2.m','4.A.3.b.4.c','4.A.3.b.5.a','4.A.3.a.3.b','4.A.2.b.1.b']::text[],array[16.71,16.49,12.69,8.15,7.7,7.68,7.61,4.41,4.32]::numeric[],array[]::text[],array['51-8013.00','51-8013.03','53-7071.00']::text[],null),
  ('51-8031.00',2,2,9,9,array['4.A.3.b.5.a','4.A.3.a.3.f','4.A.3.a.1.c','4.A.1.b.2.c','4.A.3.a.2.b','4.A.3.b.6.h','4.A.1.b.2.g','4.A.3.b.4.c','4.A.4.b.4.j']::text[],array[11.52,9.45,7.92,4.88,4.88,4.75,4.33,3.78,4.09]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['51-8091.00','51-8013.03','51-8013.00']::text[],null),
  ('51-8091.00',2,2,18,9,array['4.A.3.a.3.f','4.A.1.a.2.a','4.A.3.b.4.c','4.A.1.b.2.c','4.A.1.b.2.g','4.A.3.a.2.b','4.A.3.b.6.h','4.A.3.a.2.i','4.A.3.a.3.b']::text[],array[14.07,13.69,12.44,9.09,4.63,4.6,4.52,4.5,4.43]::numeric[],array['Microsoft Office software','Microsoft Excel']::text[],array['51-9011.00','51-9012.00','51-8031.00']::text[],null),
  ('51-8092.00',2,2,18,9,array['4.A.3.a.3.g','4.A.1.a.2.a','4.A.1.b.2.c','4.A.3.b.5.a','4.A.1.b.2.g','4.A.3.b.6.h','4.A.2.b.1.b','4.A.4.b.6.e','4.A.3.a.2.i']::text[],array[25.46,8.95,7.79,7.3,4.66,4.42,4.41,4.41,4.35]::numeric[],array['Google Android','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['51-8013.00','51-8093.00','53-7071.00']::text[],null),
  ('51-8093.00',2,2,18,4,array['4.A.1.a.2.a','4.A.3.a.3.b','4.A.3.b.5.a','4.A.1.b.2.c','4.A.3.a.1.c','4.A.3.b.4.c','4.A.4.a.2.g','4.A.3.a.3.g','4.A.3.a.2.i']::text[],array[16.58,8.17,7.93,7.46,7.37,4.29,4.29,4.23,4.23]::numeric[],array[]::text[],array['51-8092.00','53-7071.00','53-7073.00']::text[],null),
  ('51-8099.01',2,2,9,2,array['4.A.1.a.2.b','4.A.3.a.3.g','4.A.3.b.6.h','4.A.2.a.1.e','4.A.3.a.2.m','4.A.1.b.3.a','4.A.3.b.5.a','4.A.3.a.3.b','4.A.3.a.2.b']::text[],array[18.04,13.67,13.52,8.77,8.73,8.49,7.87,4.72,4.7]::numeric[],array[]::text[],array['51-8013.03','51-8091.00','51-8093.00']::text[],null),
  ('51-9011.00',2,2,36,9,array['4.A.3.a.1.c','4.A.3.a.2.i','4.A.3.a.3.f','4.A.1.a.2.a','4.A.1.a.1.b','4.A.3.b.5.a','4.A.3.a.1.k','4.A.3.b.6.h','4.A.3.a.2.b']::text[],array[11.97,9.18,9.16,9.13,8.9,7.6,4.76,4.74,4.61]::numeric[],array['SAP software','Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['51-8091.00','51-9012.00','51-8031.00']::text[],null),
  ('51-9012.00',2,2,4,2,array['4.A.3.a.2.i','4.A.3.a.3.b','4.A.3.a.3.f','4.A.1.b.2.c','4.A.3.b.5.a','4.A.3.a.1.c','4.A.3.a.1.f','4.A.2.a.3.b','4.A.3.a.1.k']::text[],array[16.63,8.36,8.36,8.2,7.64,7.62,4.51,4.4,4.4]::numeric[],array['Microsoft Office software']::text[],array['51-9192.00','51-9023.00','51-9051.00']::text[],null),
  ('51-9021.00',2,2,9,2,array['4.A.1.b.3.a','4.A.3.a.1.c','4.A.3.a.3.l','4.A.1.b.2.c','4.A.3.b.5.a','4.A.1.a.2.a','4.A.3.a.3.b','4.A.4.a.2.g','4.A.1.b.1.a']::text[],array[12.09,7.86,7.66,7.56,7.56,4.35,4.09,4.04,3.86]::numeric[],array[]::text[],array['51-4033.00','53-7063.00','51-9032.00']::text[],null),
  ('51-9023.00',2,2,0,2,array['4.A.1.b.3.a','4.A.3.a.3.f','4.A.3.a.1.c','4.A.3.a.1.f','4.A.1.b.2.c','4.A.3.a.3.b','4.A.3.a.1.a','4.A.3.b.5.a','4.A.1.a.1.b']::text[],array[13.83,13.36,12.61,8.76,8.74,8.69,8.68,7.99,4.58]::numeric[],array[]::text[],array['51-9012.00','51-3092.00','51-9192.00']::text[],null),
  ('51-9032.00',2,2,0,2,array['4.A.3.a.3.l','4.A.3.a.2.f','4.A.3.a.2.i','4.A.1.b.3.a','4.A.3.a.1.f','4.A.3.a.2.an','4.A.3.b.5.a','4.A.1.a.1.b','4.A.1.b.2.l']::text[],array[24.99,16.23,12.14,8.84,8.41,8.35,7.62,4.42,4.31]::numeric[],array[]::text[],array['51-7042.00','51-4033.00','51-6062.00']::text[],null),
  ('51-9041.00',2,2,9,4,array['4.A.3.a.3.f','4.A.1.b.3.a','4.A.3.a.2.i','4.A.1.a.1.b','4.A.3.a.2.an','4.A.3.a.2.f','4.A.3.b.6.h','4.A.3.a.1.f','4.A.3.a.2.s']::text[],array[21.78,17.05,13.43,13.08,12.29,11.61,8.29,8.08,7.78]::numeric[],array[]::text[],array['51-6091.00','53-7063.00','51-9032.00']::text[],null),
  ('51-9051.00',2,2,4,2,array['4.A.3.b.5.a','4.A.1.a.1.b','4.A.3.a.2.i','4.A.3.a.1.f','4.A.1.a.2.a','4.A.3.b.6.h','4.A.1.b.2.c','4.A.3.a.2.an','4.A.2.b.1.h']::text[],array[10.77,8.32,8.17,7.75,4.51,4.21,4.15,4.06,4.05]::numeric[],array[]::text[],array['51-9012.00','51-9041.00','51-4051.00']::text[],null),
  ('51-9061.00',2,2,2,4,array['4.A.1.b.2.c','4.A.1.b.3.a','4.A.1.a.2.a','4.A.2.a.1.e','4.A.3.b.6.h','4.A.1.a.1.b','4.A.4.b.6.e','4.A.3.b.4.c','4.A.3.a.1.c']::text[],array[16.9,16.01,12.63,12.24,8.64,8.62,8.36,8.05,8.05]::numeric[],array['Microsoft PowerPoint','Microsoft Outlook','Microsoft Word','Microsoft Office software','Microsoft Excel']::text[],array['51-2022.00','51-2011.00','51-2023.00']::text[],null),
  ('51-9111.00',2,2,2,2,array['4.A.3.a.2.ap','4.A.1.b.3.a','4.A.1.a.2.a','4.A.3.b.5.a','4.A.3.a.2.an','4.A.2.a.2.b','4.A.1.b.1.a','4.A.4.a.2.g','4.A.3.a.1.c']::text[],array[25.46,8.94,8.85,8.81,8.81,8.53,4.53,4.45,4.36]::numeric[],array[]::text[],array['53-7064.00','53-7063.00','51-9191.00']::text[],null),
  ('51-9161.00',2,2,18,9,array['4.A.3.b.1.a','4.A.1.a.2.a','4.A.3.b.4.c','4.A.3.a.2.i','4.A.3.a.2.f','4.A.3.a.2.s','4.A.3.a.1.f','4.A.1.b.3.a','4.A.3.a.2.at']::text[],array[43.56,13.4,13.25,12.73,9.26,8.84,7.4,4.76,4.63]::numeric[],array['G-code']::text[],array['51-4035.00','51-4041.00','51-4034.00']::text[],null),
  ('51-9162.00',2,2,36,9,array['4.A.3.b.1.a','4.A.2.b.1.d','4.A.2.b.1.j','4.A.1.a.1.b','4.A.1.b.2.l','4.A.1.b.3.a','4.A.2.b.6.b','4.A.2.a.2.a','4.A.2.b.2.o']::text[],array[24.33,8.89,4.56,4.46,4.39,4.33,3.82,3.81,3.78]::numeric[],array['Autodesk Fusion 360','G-code','Mastercam computer-aided design and manufacturing software','Dassault Systemes SolidWorks','Autodesk AutoCAD']::text[],array['51-9161.00','51-4041.00','17-3024.01']::text[],null),
  ('51-9191.00',2,2,2,4,array['4.A.3.a.2.i','4.A.3.a.1.f','4.A.1.a.2.a','4.A.1.a.1.b','4.A.3.b.5.a','4.A.1.b.3.a','4.A.3.a.2.ao','4.A.4.a.2.g','4.A.1.b.2.l']::text[],array[13.55,12.86,8.73,8.68,8.27,7.39,4.59,4.54,4.41]::numeric[],array[]::text[],array['51-9196.00','51-9032.00','53-7063.00']::text[],null),
  ('51-9192.00',2,2,0,2,array['4.A.3.a.1.c','4.A.3.a.2.ag','4.A.1.a.2.a','4.A.3.a.2.i','4.A.3.a.3.b','4.A.3.a.2.b','4.A.1.b.2.c','4.A.3.b.5.a','4.A.3.a.3.f']::text[],array[8.01,4.25,4.13,4.09,4.09,4.07,4.07,4.05,3.95]::numeric[],array[]::text[],array['51-9012.00','51-9023.00','51-9051.00']::text[],null),
  ('51-9193.00',1,2,9,2,array['4.A.3.a.2.i','4.A.1.a.2.a','4.A.1.b.3.a','4.A.3.a.1.f','4.A.3.a.1.c','4.A.3.b.6.h','4.A.3.a.3.b','4.A.3.b.5.a','4.A.4.a.2.g']::text[],array[24.26,8.51,8.24,8.09,7.45,4.35,4.17,4.0,4.0]::numeric[],array[]::text[],array['51-9192.00','51-9012.00','51-9051.00']::text[],null),
  ('51-9195.00',2,2,2,2,array['4.A.3.a.2.l','4.A.3.a.2.an','4.A.1.b.3.a','4.A.3.a.2.aj','4.A.3.a.1.f','4.A.3.a.2.i','4.A.1.a.1.b','4.A.3.a.2.y','4.A.3.b.5.a']::text[],array[14.71,11.82,11.08,10.9,10.84,7.82,4.09,4.02,4.0]::numeric[],array[]::text[],array['51-4071.00','51-4072.00','51-9041.00']::text[],null),
  ('51-9195.04',2,2,36,18,array['4.A.1.b.3.a','4.A.3.a.2.g','4.A.3.b.4.c','4.A.3.a.1.f','4.A.3.a.2.an','4.A.3.a.2.m','4.A.2.b.1.j','4.A.3.a.2.i','4.A.3.b.6.h']::text[],array[9.02,8.59,7.56,4.73,4.6,4.53,4.23,4.21,4.2]::numeric[],array[]::text[],array['51-9195.00','51-9041.00','51-4072.00']::text[],null),
  ('51-9196.00',2,2,4,2,array['4.A.3.a.1.f','4.A.3.a.2.i','4.A.3.a.2.f','4.A.1.a.2.a','4.A.1.b.2.f','4.A.3.a.2.l','4.A.3.a.2.at','4.A.3.a.2.s','4.A.1.b.1.a']::text[],array[16.25,12.89,12.78,8.68,4.66,4.35,4.2,4.0,3.94]::numeric[],array[]::text[],array['51-9191.00','51-9032.00','51-6062.00']::text[],null),
  ('51-9198.00',2,2,2,2,array['4.A.3.a.1.c','4.A.3.a.2.an','4.A.3.a.3.h','4.A.3.a.1.f','4.A.1.b.2.f','4.A.3.a.3.f','4.A.3.b.6.h','4.A.3.a.2.ap','4.A.3.b.4.c']::text[],array[17.0,11.68,10.84,8.29,8.22,8.05,7.49,7.37,7.2]::numeric[],array[]::text[],array['47-5081.00','53-7063.00']::text[],null),
  ('53-3031.00',2,2,1,2,array['4.A.3.b.6.j','4.A.4.a.6.b','4.A.3.a.4.a','4.A.4.a.3.c','4.A.3.b.6.h','4.A.4.a.7.c','4.A.3.a.1.c','4.A.3.b.4.e','4.A.3.a.1.f']::text[],array[11.69,7.05,4.32,4.06,4.04,3.99,3.97,3.97,3.51]::numeric[],array[]::text[],array['43-5071.00','41-9091.00','41-2021.00']::text[],null),
  ('53-6031.00',2,2,0,4,array['4.A.3.b.4.e','4.A.3.a.1.c','4.A.3.b.6.j','4.A.1.b.3.a','4.A.3.a.3.b','4.A.4.a.6.b','4.A.3.a.2.d','4.A.1.b.2.d','4.A.4.a.3.c']::text[],array[19.87,12.45,7.94,4.24,3.96,3.94,3.94,3.78,2.35]::numeric[],array['Microsoft Edge','Apple Safari','Mozilla Firefox','Web browser software']::text[],array['49-3023.00','53-7072.00','53-7061.00']::text[],null),
  ('53-7011.00',1,2,0,4,array['4.A.3.a.3.f','4.A.3.b.4.e','4.A.1.b.3.a','4.A.3.a.1.f','4.A.3.a.1.c','4.A.4.a.2.c','4.A.3.a.1.j','4.A.3.a.2.d','4.A.3.a.2.ah']::text[],array[12.87,8.63,8.6,8.52,8.38,8.38,8.3,8.03,8.03]::numeric[],array[]::text[],array['53-7063.00','53-7051.00','53-7041.00']::text[],null),
  ('53-7021.00',2,3,9,4,array['4.A.1.b.2.g','4.A.3.b.4.e','4.A.1.b.3.a','4.A.3.a.1.f','4.A.2.a.2.a','4.A.3.a.3.h','4.A.3.a.2.d','4.A.3.a.1.c','4.A.1.b.2.f']::text[],array[9.02,8.8,8.01,7.57,4.68,4.55,4.5,4.28,3.93]::numeric[],array[]::text[],array['53-7041.00','53-7051.00','49-3042.00']::text[],null),
  ('53-7031.00',2,2,18,2,array['4.A.3.a.3.c','4.A.3.a.3.b','4.A.3.a.3.h','4.A.1.b.3.d','4.A.4.b.4.j']::text[],array[13.54,8.13,4.31,3.99,3.83]::numeric[],array[]::text[],array['53-7041.00','47-5022.00','47-5012.00']::text[],null),
  ('53-7041.00',2,2,18,9,array['4.A.3.a.3.h','4.A.3.b.4.e','4.A.1.a.2.a','4.A.3.a.1.j','4.A.3.a.2.v','4.A.3.a.1.n','4.A.2.b.1.j','4.A.3.a.1.f','4.A.4.a.2.c']::text[],array[21.89,8.32,4.43,4.13,4.13,4.12,4.1,3.93,3.93]::numeric[],array[]::text[],array['53-7051.00','53-7021.00','47-5022.00']::text[],null),
  ('53-7051.00',2,2,9,2,array['4.A.3.a.1.f','4.A.3.a.4.a','4.A.3.a.3.h','4.A.3.a.2.v','4.A.3.a.1.j','4.A.1.b.2.e','4.A.1.b.1.a','4.A.1.b.3.a','4.A.3.a.1.c']::text[],array[9.0,8.11,4.61,4.49,4.34,4.34,4.26,4.26,4.11]::numeric[],array['Warehouse management system WMS']::text[],array['53-7041.00','53-7021.00','47-5044.00']::text[],null),
  ('53-7061.00',2,2,4,2,array['4.A.3.a.1.c','4.A.3.a.3.b','4.A.3.a.2.d','4.A.3.a.2.ag','4.A.3.a.4.a','4.A.1.b.2.d','4.A.3.a.1.a','4.A.4.a.2.g','4.A.3.a.1.g']::text[],array[30.56,7.27,6.57,3.97,3.93,3.88,3.74,3.59,3.59]::numeric[],array[]::text[],array['51-6011.00','51-9192.00']::text[],null),
  ('53-7062.00',2,2,0,2,array['4.A.3.a.1.j','4.A.3.a.3.h','4.A.3.a.1.f','4.A.1.b.2.e','4.A.2.a.2.b','4.A.1.b.1.a','4.A.1.a.1.b','4.A.4.a.2.c','4.A.3.b.6.h']::text[],array[7.63,7.09,4.52,4.48,4.26,4.14,4.13,4.13,4.02]::numeric[],array['Warehouse management system WMS']::text[],array['53-7063.00','53-7051.00','53-7064.00']::text[],null),
  ('53-7062.04',2,2,4,2,array['4.A.2.a.2.b','4.A.3.a.1.c','4.A.3.a.3.f','4.A.3.a.1.f','4.A.3.a.1.h','4.A.3.a.3.h','4.A.3.b.6.h','4.A.3.a.3.l','4.A.3.b.4.c']::text[],array[16.17,12.15,11.48,4.16,4.03,4.01,3.9,3.81,3.79]::numeric[],array[]::text[],array['53-7081.00','51-9111.00','53-7062.00']::text[],null),
  ('53-7063.00',2,2,2,2,array['4.A.1.b.2.f','4.A.1.b.3.a','4.A.3.a.1.c','4.A.3.a.3.f','4.A.3.a.2.ap','4.A.3.a.1.f','4.A.3.b.6.h','4.A.1.b.1.a','4.A.3.a.1.j']::text[],array[8.8,8.5,8.26,8.15,7.9,7.67,4.39,4.2,3.96]::numeric[],array[]::text[],array['51-9032.00','51-9191.00','51-9041.00']::text[],null),
  ('53-7064.00',2,2,0,2,array['4.A.3.a.1.j','4.A.1.b.3.a','4.A.3.a.2.at','4.A.3.a.1.f','4.A.1.a.2.b','4.A.1.b.2.f','4.A.3.a.1.e','4.A.3.b.6.h','4.A.2.a.2.b']::text[],array[12.24,8.8,8.32,7.99,4.5,4.5,4.28,4.24,4.08]::numeric[],array[]::text[],array['51-9111.00','53-7063.00','51-9191.00']::text[],null),
  ('53-7065.00',2,2,2,2,array['4.A.3.a.2.ak','4.A.4.c.1.e','4.A.2.b.1.a','4.A.3.b.6.h','4.A.3.a.2.ap','4.A.1.b.1.a','4.A.3.a.1.f','4.A.3.a.1.c','4.A.3.b.6.m']::text[],array[19.04,11.73,8.51,8.05,8.03,8.01,7.87,7.59,4.69]::numeric[],array[]::text[],array['43-5071.00','41-2021.00','43-5111.00']::text[],null),
  ('53-7071.00',2,2,36,9,array['4.A.3.a.3.b','4.A.3.b.6.h','4.A.1.a.2.a','4.A.3.a.1.c','4.A.1.b.2.c','4.A.3.a.2.b','4.A.3.a.2.ah','4.A.4.b.4.j']::text[],array[20.66,12.25,8.35,7.32,3.98,3.98,3.2,4.28]::numeric[],array[]::text[],array['51-8092.00','51-8093.00','51-8021.00']::text[],null),
  ('53-7072.00',2,2,18,4,array['4.A.1.a.2.a','4.A.4.a.2.c','4.A.3.a.3.b','4.A.4.a.2.g','4.A.3.b.6.h','4.A.2.b.6.b','4.A.3.a.2.ah','4.A.1.b.3.a','4.A.1.b.2.e']::text[],array[8.46,8.39,8.27,4.48,4.41,4.41,4.22,4.2,4.2]::numeric[],array['Microsoft Outlook','Microsoft Office software','Microsoft Excel']::text[],array['53-7071.00','51-8093.00','53-7073.00']::text[],null),
  ('53-7073.00',2,2,18,4,array['4.A.3.a.3.b','4.A.3.a.2.d','4.A.1.a.2.a','4.A.1.b.2.g','4.A.1.b.3.a','4.A.1.b.2.l','4.A.3.b.4.b','4.A.3.a.2.at','4.A.3.b.4.e']::text[],array[12.78,11.8,8.89,4.59,4.45,4.45,3.95,3.93,3.82]::numeric[],array[]::text[],array['51-8093.00','53-7072.00','51-8092.00']::text[],null),
  ('53-7081.00',2,2,18,1,array['4.A.4.a.2.g','4.A.1.b.2.d','4.A.3.a.4.a','4.A.3.b.4.e','4.A.3.a.1.e','4.A.3.b.6.o','4.A.3.a.3.h','4.A.3.a.1.n','4.A.3.a.3.f']::text[],array[7.92,4.53,4.35,4.33,4.32,4.27,4.05,3.99,3.98]::numeric[],array[]::text[],array['53-7062.04']::text[],null);

-- ---------------------------------------------------------------------------
-- 2b. Izin praktik
--
-- Tidak ada di O*NET (yang memetakan lisensi Amerika). Disusun manual dari
-- peraturan Indonesia; lihat supabase/roadmap/licenses.py untuk dasarnya.
-- ---------------------------------------------------------------------------
create temporary table _rm_license (
  career_name text primary key,
  license     text not null
) on commit drop;

insert into _rm_license values
  ('Ahli Gizi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Ahli Teknologi Laboratorium Medik','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Ahli Teknologi Laboratorium Medik (Jenjang Teknisi)','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Akupunkturis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Analis Informasi Kesehatan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Apoteker','Surat Tanda Registrasi Apoteker (STRA) dan Surat Izin Praktik Apoteker (SIPA)'),
  ('Asisten Apotek','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Asisten Bedah','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Asisten Dokter Gigi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Asisten Dokter Hewan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Asisten Fisioterapis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Asisten Perawat','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Audiolog','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Bidan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Bidan (Perawat Kebidanan)','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Caregiver Lansia/Homecare','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Caregiver Pendamping Pribadi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Chiropractor','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Gigi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP) setelah program profesi'),
  ('Dokter Gigi Spesialis Bedah Mulut dan Maksilofasial','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Gigi Spesialis Ortodonti','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Gigi Spesialis Prostodonsia','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Hewan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Alergi Imunologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Anak','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Anestesi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Bedah Anak','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Jantung dan Pembuluh Darah','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Jiwa','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Kedokteran Fisik dan Rehabilitasi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Kedokteran Gawat Darurat','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Kedokteran Komunitas','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Kedokteran Olahraga','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Kulit dan Kelamin','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Mata','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Obstetri dan Ginekologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Ortopedi dan Traumatologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Patologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Penyakit Dalam','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Radiologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Saraf','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Spesialis Urologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Dokter Umum','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP) setelah program profesi dan internsip'),
  ('Dosen Antropologi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Arsitektur','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Bahasa Asing','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Biologi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Bisnis dan Manajemen','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Filsafat dan Agama','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Fisika','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Geografi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Hukum','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Hukum Pidana dan Kepolisian','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Ekonomi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Kebumian dan Kelautan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Keolahragaan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Kesehatan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Kesejahteraan Sosial','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Komputer','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Komunikasi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Lingkungan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Perpustakaan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Pertanian','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Ilmu Politik','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Kajian Wilayah dan Budaya','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Kehutanan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Keperawatan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Kimia','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Matematika','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Pendidikan','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Psikologi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Sastra dan Pendidikan Bahasa Inggris','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Sejarah','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Seni','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Sosiologi','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Tata Boga dan Kesejahteraan Keluarga','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Dosen Teknik','Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional'),
  ('Fisikawan Medik (Dosimetri Radioterapi)','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Fisiolog Olahraga','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Fisioterapis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Fisioterapis Olahraga','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Flebotomis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Guru Kursus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Les Privat','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru PAUD','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru PAUD Pendidikan Khusus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Pendamping Khusus (GPK)','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Pendidikan Jasmani Adaptif','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Pendidikan Kesetaraan','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Pengganti','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru Prakarya/Keterampilan SMP','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SD','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SD Pendidikan Khusus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SMA','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SMA Pendidikan Khusus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SMK','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SMP','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru SMP Pendidikan Khusus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru TK','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Guru TK Pendidikan Khusus','sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)'),
  ('Histoteknologis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Instrumentator Bedah','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Konselor Genetik','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Optometris','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Ortotis Prostetis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Paramedis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Paramedis Veteriner','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Pekarya Kesehatan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Penata Anestesi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat Klinis Spesialis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat Kritis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat Perawatan Akut','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat Spesialis Jiwa','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perawat Vokasi (D3 Keperawatan)','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Perekam Medis dan Informasi Kesehatan','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Petugas Gawat Darurat','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Petugas Layanan Pasien','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Petugas Sterilisasi Alat Medis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Radiografer','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Radiografer Kedokteran Nuklir','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Radiografer MRI','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Radiografer Radioterapi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Refraksionis Optisien','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Refraksionis Optisien (Asisten Oftalmologi)','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Sitoteknologis','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Sonografer','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Spesialis Alat Bantu Dengar','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknisi Endoskopi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknisi Gizi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknisi Histologi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknisi Kardiovaskular','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknisi Neurodiagnostik','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknolog Oftalmik','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Teknolog Sitogenetika','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Tenaga Teknis Kefarmasian','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Gigi dan Mulut','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Musik','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Okupasi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Pijat','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Respirasi','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Seni','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)'),
  ('Terapis Wicara','Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)');

-- ---------------------------------------------------------------------------
-- 3. Perakit
--
-- Bentuk roadmap tiap profesi:
--
--   SEKOLAH      selesaikan pendidikan menengah      (hilang kalau sudah lulus)
--   KULIAH       tempuh jenjang yang dibutuhkan      (hilang kalau sudah dicapai)
--   FONDASI      kuasai 4 kemampuan inti teratas
--   PENGALAMAN   alat kerja + 2 kemampuan + pengalaman pertama
--   PROFESIONAL  rekrutmen + 3 kemampuan berikutnya
--   LANJUT       profesi lanjutan yang serumpun
--
-- Empat capaian teratas ditaruh di FONDASI dan sisanya didorong ke fase
-- berikutnya bukan karena yang belakangan kurang penting, melainkan karena
-- urutan bobot O*NET adalah urutan seberapa sering kemampuan itu dipakai di
-- pekerjaan — dan yang paling sering dipakai adalah yang paling masuk akal
-- dilatih lebih dulu.
-- ---------------------------------------------------------------------------
create or replace function _rm_generate() returns text
language plpgsql as $fn$
declare
  r            record;
  v_tpl        bigint;
  v_stage      bigint;
  v_ms         bigint;
  v_order      smallint;
  v_msorder    smallint;
  v_level      text;
  v_kuliah_m   integer;
  v_name       text;
  v_area       text;
  v_i          integer;
  v_tool       text;
  v_next       text;
  v_total      integer;
  v_exp_m      integer;
  v_license    text;
  n_tpl        integer := 0;
  n_stage      integer := 0;
  n_ms         integer := 0;
  n_act        integer := 0;
begin
  for r in
    select c.id as career_id, c.career_name, i.*
    from public.careers c
    join _rm_in i on i.soc_code = c.soc_code
    where c.is_active
    order by c.id
  loop
    -- Nama jenjang target, apa adanya dari tabel pendidikan supaya sebutan di
    -- roadmap sama persis dengan yang dipilih pengguna saat onboarding.
    -- Rank 6 ditempati dua jenjang sekaligus (D4 dan S1) dan datanya tidak
    -- bisa membedakan mana yang diminta, jadi keduanya disebut. Rank lain
    -- hanya punya satu nama.
    if r.target_rank = 6 then
      v_level := 'Sarjana (S1) atau Diploma 4 (D4)';
    else
      select level_name into v_level
      from public.education_levels
      where order_rank = r.target_rank
      order by id limit 1;
      v_level := coalesce(v_level, 'pendidikan tinggi');
    end if;

    v_kuliah_m := case r.target_rank
                    when 3 then 12 when 4 then 24 when 5 then 36
                    when 6 then 48 when 7 then 24 when 8 then 48 else 0 end;

    -- Fase pengalaman dibatasi 24 bulan.
    --
    -- Angka "Related Work Experience" O*NET adalah pengalaman yang DIMILIKI
    -- pemegang jabatan sekarang, bukan yang dibutuhkan untuk masuk. Untuk
    -- Software Developer nilainya 84 bulan; menampilkannya sebagai lama fase
    -- akan terbaca "kamu perlu 7 tahun pengalaman sebelum bisa mulai". Nilai
    -- aslinya tetap disebut di deskripsi fase sebagai gambaran jangka panjang.
    v_exp_m := least(greatest(r.exp_months, 6), 24);

    -- Total sengaja tidak menjumlahkan semua fase: FONDASI berjalan bersamaan
    -- dengan sekolah dan kuliah, jadi menjumlahkannya menghitung tahun yang
    -- sama dua kali. Yang dijumlahkan hanya tulang punggung yang benar-benar
    -- berurutan, dihitung dari lulus pendidikan menengah.
    v_total := v_kuliah_m + v_exp_m + greatest(r.ojt_months, 6);
    select license into v_license from _rm_license where career_name = r.career_name;

    insert into public.roadmap_templates
      (career_id, target_rank, job_zone, est_months, source, is_curated, curation_note)
    values
      (r.career_id, r.target_rank, r.job_zone, v_total, 'onet', r.note is not null, r.note)
    returning id into v_tpl;
    n_tpl := n_tpl + 1;

    v_order := 0;

    -- ---- SEKOLAH ----------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'SEKOLAH', 'Selesaikan pendidikan menengah',
            'Sambil sekolah, kenali profesi ini dari dekat dan pilih jurusan yang mendukung.',
            36, 2)
    returning id into v_stage;
    n_stage := n_stage + 1;

    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, 1, 'Kenali profesi ' || r.career_name,
            'Cari tahu isi pekerjaannya sebelum memilih jalur pendidikan.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET', 'Cari tahu keseharian seorang ' || r.career_name, 10, 2),
      (v_ms, 2, 'RISET', 'Ngobrol dengan satu orang yang bekerja sebagai ' || r.career_name, 25, 2),
      (v_ms, 3, 'BUKTI', 'Tulis alasanmu tertarik pada profesi ini', 10, 1);
    n_act := n_act + 3;

    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, 2, 'Pilih jurusan sekolah yang mendukung',
            'Jurusan di SMA/SMK menentukan pintu mana saja yang terbuka setelah lulus.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET', 'Bandingkan jurusan SMA/SMK yang mengarah ke profesi ini', 15, 3),
      (v_ms, 2, 'ADMIN', 'Tetapkan pilihan jurusanmu', 15, 1);
    n_act := n_act + 2;

    -- ---- KULIAH -----------------------------------------------------------
    if r.target_rank >= 3 then
      v_order := v_order + 1;
      insert into public.roadmap_stages
        (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
      values (v_tpl, v_order, 'KULIAH', 'Tempuh pendidikan ' || v_level,
              'Jenjang yang paling umum diminta untuk masuk ke profesi ini.',
              v_kuliah_m, r.target_rank)
      returning id into v_stage;
      n_stage := n_stage + 1;

      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, 1, 'Pilih program studi yang relevan',
              'Program studi yang tepat memangkas jarak antara bangku kuliah dan pekerjaan.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'RISET', 'Susun daftar program studi yang mengarah ke profesi ini', 15, 3),
        (v_ms, 2, 'RISET', 'Bandingkan kampus, biaya, dan jalur masuknya', 15, 4),
        (v_ms, 3, 'ADMIN', 'Daftar ke program studi pilihanmu', 25, 5);
      n_act := n_act + 3;

      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, 2, 'Selesaikan ' || v_level,
              'Kelulusan adalah syarat administratif yang tidak bisa dilewati untuk profesi ini.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Jaga capaian akademik tiap semester', 20, null),
        (v_ms, 2, 'PRAKTIK', 'Ambil tugas akhir yang berhubungan dengan profesi ini', 40, null),
        (v_ms, 3, 'ADMIN', 'Selesaikan kelulusan dan urus ijazah', 30, null);
      n_act := n_act + 3;
    end if;

    -- ---- FONDASI ----------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'FONDASI', 'Kuasai kemampuan inti',
            'Kemampuan yang paling sering dipakai seorang ' || r.career_name
            || ' dalam pekerjaannya. Fase ini berjalan berbarengan dengan sekolah '
            || 'atau kuliah, bukan setelahnya.',
            null, null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    v_msorder := 0;
    for v_i in 1 .. least(4, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8),
        (v_ms, 2, 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16),
        (v_ms, 3, 'BUKTI',   'Simpan bukti kemampuan ' || _rm_lower(v_name), 15, 2);
      n_act := n_act + 3;
    end loop;

    -- ---- PENGALAMAN -------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'PENGALAMAN', 'Kumpulkan pengalaman nyata',
            case when r.exp_months >= 36
                 then 'Mulai dari magang dan proyek kecil. Sebagai gambaran, pekerja di '
                      || 'profesi ini rata-rata sudah mengumpulkan sekitar '
                      || round(r.exp_months / 12.0) || ' tahun pengalaman terkait.'
                 else 'Pengalaman nyata, sekecil apa pun, yang membedakanmu dari pelamar lain.'
            end,
            v_exp_m, null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    v_msorder := 0;

    if coalesce(array_length(r.tools, 1), 0) > 0 then
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, v_msorder, 'Kuasai alat kerja yang dipakai di lapangan',
              'Perangkat yang paling sering diminta di lowongan profesi ini.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      for v_i in 1 .. array_length(r.tools, 1) loop
        v_tool := r.tools[v_i];
        insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours)
        values (v_ms, v_i, 'BELAJAR', 'Pelajari ' || v_tool, 20, 12);
        n_act := n_act + 1;
      end loop;
    end if;

    for v_i in 5 .. least(6, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8),
        (v_ms, 2, 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16);
      n_act := n_act + 2;
    end loop;

    v_msorder := v_msorder + 1;
    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, v_msorder, 'Dapatkan pengalaman pertama',
            'Magang, proyek nyata, atau pekerjaan lepas — apa pun yang bisa ditunjukkan.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET',   'Data tempat magang atau proyek yang menerima pemula', 15, 4),
      (v_ms, 2, 'PRAKTIK', 'Jalani satu magang atau proyek nyata', 60, null),
      (v_ms, 3, 'BUKTI',   'Rangkum hasilnya jadi satu portofolio', 30, 6);
    n_act := n_act + 3;

    -- ---- PROFESIONAL ------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'PROFESIONAL', 'Mulai berkarier sebagai ' || r.career_name,
            'Masuk ke peran pertama dan bertahan di dalamnya.',
            greatest(r.ojt_months, 6), null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    -- Izin praktik untuk profesi yang diatur negara.
    --
    -- Tanpa ini roadmap tenaga kesehatan dan guru salah secara faktual: ijazah
    -- saja tidak cukup untuk bekerja, dan siswa yang mengikuti roadmap sampai
    -- habis akan berhenti tepat sebelum syarat yang paling menentukan.
    v_msorder := 0;
    if v_license is not null then
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, v_msorder, 'Urus ' || v_license,
              'Syarat hukum untuk bekerja di profesi ini, diurus setelah lulus.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'RISET', 'Cari tahu syarat dan alur pengurusan ' || v_license, 20, 3),
        (v_ms, 2, 'ADMIN', 'Lengkapi berkas dan ajukan ' || v_license, 40, null);
      n_act := n_act + 2;
    end if;

    v_msorder := v_msorder + 1;
    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, v_msorder, 'Lolos proses rekrutmen',
            'Berkas dan wawancara adalah keterampilan tersendiri, terpisah dari kemampuan teknis.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'BUKTI',   'Susun CV yang menonjolkan pengalamanmu', 20, 4),
      (v_ms, 2, 'BELAJAR', 'Latih wawancara kerja untuk posisi ini', 20, 4),
      (v_ms, 3, 'ADMIN',   'Lamar ke minimal lima lowongan', 30, 6);
    n_act := n_act + 3;

    for v_i in 7 .. least(9, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'PRAKTIK', 'Terapkan di pekerjaan: ' || _rm_lower(v_name), 25, null);
      n_act := n_act + 1;
    end loop;

    -- ---- LANJUT -----------------------------------------------------------
    if coalesce(array_length(r.next_socs, 1), 0) > 0 then
      v_order := v_order + 1;
      insert into public.roadmap_stages
        (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
      values (v_tpl, v_order, 'LANJUT', 'Kembangkan karier',
              'Arah lanjutan yang paling dekat dengan kemampuan yang sudah kamu bangun.',
              null, null)
      returning id into v_stage;
      n_stage := n_stage + 1;

      v_msorder := 0;
      for v_i in 1 .. array_length(r.next_socs, 1) loop
        select career_name into v_next
        from public.careers
        where soc_code = r.next_socs[v_i] and is_active
        order by id limit 1;
        continue when v_next is null;
        v_msorder := v_msorder + 1;
        insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
        values (v_stage, v_msorder, 'Jajaki jalur ke ' || v_next,
                'Profesi yang sebagian besar kemampuannya sudah kamu miliki.')
        returning id into v_ms;
        n_ms := n_ms + 1;
        insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours)
        values (v_ms, 1, 'RISET', 'Cari tahu apa yang membedakan ' || v_next || ' dari peranmu sekarang', 15, 2);
        n_act := n_act + 1;
      end loop;

      -- Semua profesi lanjutannya ternyata tidak aktif: buang stage kosongnya
      -- daripada menampilkan fase tanpa isi.
      if v_msorder = 0 then
        delete from public.roadmap_stages where id = v_stage;
        n_stage := n_stage - 1;
      end if;
    end if;
  end loop;

  return format('template=%s stage=%s milestone=%s activity=%s', n_tpl, n_stage, n_ms, n_act);
end $fn$;

-- Menurunkan huruf pertama saja, supaya nama capaian bisa disisipkan ke tengah
-- kalimat ("Pelajari dasar merancang sistem ...") tanpa merusak nama diri di
-- dalamnya (lower() penuh akan menulis "excel" dan "autocad").
create or replace function _rm_lower(s text) returns text
language sql immutable as $$
  select case when s is null or s = '' then s
              else lower(left(s, 1)) || right(s, -1) end
$$;

-- ---------------------------------------------------------------------------
-- 4. Bangun ulang
--
-- Menghapus dulu, bukan menambal: template lama dan baru bisa berbeda jumlah
-- fasenya, jadi UPSERT per baris akan meninggalkan sisa yang tidak pernah
-- kelihatan. ON DELETE CASCADE menurun sampai ke aktivitas.
-- ---------------------------------------------------------------------------
delete from public.roadmap_templates;

select _rm_generate() as hasil;

drop function if exists _rm_generate();

commit;

-- ============================================================================
-- 5. Catatan untuk yang menjalankan ulang
--
-- `delete from roadmap_templates` ikut menghapus roadmap_activities, dan
-- user_roadmap_activities.activity_id punya ON DELETE CASCADE — artinya
-- menjalankan ulang file ini SETELAH ada pengguna yang mencentang aktivitas
-- akan menghapus centangnya (XP di xp_ledger tetap, karena tidak ikut cascade).
--
-- Selama masih tahap pengembangan itu tidak masalah. Begitu ada pengguna
-- sungguhan, ganti pola ini dengan generate ke tabel bayangan lalu tukar,
-- atau cocokkan aktivitas lama-baru lewat (career_id, stage_order,
-- milestone_order, activity_order) sebelum menghapus.
--
-- Verifikasi:
--
--   select count(*) from roadmap_templates;                     -- 477
--   select stage_kind, count(*) from roadmap_full
--     group by 1 order by 1;
--   select target_rank, count(*) from roadmap_templates
--     group by 1 order by 1;
-- ============================================================================
