-- ============================================================================
-- 0021_deskripsi_rapi.sql
--
-- Dua perbaikan pada deskripsi profesi, keduanya baru kelihatan setelah layar
-- Explore jadi dan teksnya benar-benar tampil di kartu.
--
-- 1. 35 profesi masih berdeskripsi bahasa Inggris.
--
--    0013 melewatkan mereka karena daftar pengecualiannya menganggap seluruh
--    profesi penjualan dan pemasaran sudah dikurasi manual di 0011. Ternyata
--    hanya sebagian; sisanya masih membawa teks O*NET apa adanya, dan di kartu
--    Explore terbaca "Assist scientists or related professionals in building..."
--
-- 2. 228 deskripsi memuat huruf kapital nyasar di tengah kalimat.
--
--    Nama atribut DNA ditulis Judul Kapital ("Problem Solving", "Inspeksi &
--    Quality Control"). Fungsi perakit di 0013 hanya menurunkan huruf pertama
--    tiap penggalan, jadi yang keluar "problem Solving" dan "quality Control".
--    Tidak fatal, tapi terlihat seperti salah tempel begitu dibaca pengguna.
--
-- Cara merakit deskripsi tidak berubah: dari IWA yang sudah diterjemahkan,
-- Activity DNA, Environment DNA, dan jenjang pendidikan.
--
-- Jalankan setelah 0020. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Huruf kapital nyasar
--
-- Hanya menyentuh deskripsi hasil generate. Yang dikurasi manusia tidak boleh
-- ikut diubah — bisa saja memang ada nama diri di dalamnya.
-- ---------------------------------------------------------------------------
update public.careers set career_description = replace(career_description, 'problem Solving', 'problem solving')
  where description_source = 'generate_dari_dna' and career_description like '%problem Solving%';
update public.careers set career_description = replace(career_description, 'inspeksi dan quality Control', 'inspeksi dan quality control')
  where description_source = 'generate_dari_dna' and career_description like '%inspeksi dan quality Control%';
update public.careers set career_description = replace(career_description, 'kemampuan Numerik', 'kemampuan numerik')
  where description_source = 'generate_dari_dna' and career_description like '%kemampuan Numerik%';
update public.careers set career_description = replace(career_description, 'pengambilan Keputusan', 'pengambilan keputusan')
  where description_source = 'generate_dari_dna' and career_description like '%pengambilan Keputusan%';
update public.careers set career_description = replace(career_description, 'critical Thinking', 'critical thinking')
  where description_source = 'generate_dari_dna' and career_description like '%critical Thinking%';
update public.careers set career_description = replace(career_description, 'belajar Cepat', 'belajar cepat')
  where description_source = 'generate_dari_dna' and career_description like '%belajar Cepat%';
update public.careers set career_description = replace(career_description, 'manajemen Waktu', 'manajemen waktu')
  where description_source = 'generate_dari_dna' and career_description like '%manajemen Waktu%';
update public.careers set career_description = replace(career_description, 'berorientasi Detail', 'berorientasi detail')
  where description_source = 'generate_dari_dna' and career_description like '%berorientasi Detail%';
update public.careers set career_description = replace(career_description, 'berorientasi Target', 'berorientasi target')
  where description_source = 'generate_dari_dna' and career_description like '%berorientasi Target%';
update public.careers set career_description = replace(career_description, 'berorientasi Pelayanan', 'berorientasi pelayanan')
  where description_source = 'generate_dari_dna' and career_description like '%berorientasi Pelayanan%';
update public.careers set career_description = replace(career_description, 'pelayanan Kesehatan', 'pelayanan kesehatan')
  where description_source = 'generate_dari_dna' and career_description like '%pelayanan Kesehatan%';
update public.careers set career_description = replace(career_description, 'institusi Pendidikan', 'institusi pendidikan')
  where description_source = 'generate_dari_dna' and career_description like '%institusi Pendidikan%';

-- ---------------------------------------------------------------------------
-- 2. Sisa deskripsi bahasa Inggris
-- ---------------------------------------------------------------------------
create temp table _desc21 (career_id integer primary key, teks text) on commit drop;
insert into _desc21 (career_id, teks) values
  (38, 'Pekerjaan yang berfokus pada berkoordinasi soal rencana dan kegiatan operasional, memberikan informasi atau bantuan kepada publik, dan membuat materi pemasaran atau promosi. Kesehariannya banyak diisi kegiatan memimpin dan mengelola, berkomunikasi dan berinteraksi, serta analisa dan investigasi. Biasanya dijalankan dengan pola hybrid maupun secara jarak jauh. Umumnya menuntut pendidikan S1 atau D4.'),
  (96, 'Pekerjaan yang berfokus pada membuat desain atau tampilan visual, mengolah data digital atau daring, dan memberi saran tentang perancangan dan penggunaan teknologi. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, analisa dan investigasi, serta operasional dan administrasi. Biasanya dijalankan secara jarak jauh maupun di lingkungan kantor. Umumnya menuntut pendidikan D3.'),
  (122, 'Pekerjaan yang berfokus pada merancang sistem atau peralatan kelistrikan dan elektronik, merancang sistem atau peralatan industri, dan memilih material atau peralatan untuk proyek dan operasional. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, menciptakan dan mendesain, serta analisa dan investigasi. Biasanya dijalankan dengan pola hybrid maupun di lingkungan kantor. Umumnya menuntut pendidikan S1 atau D4.'),
  (125, 'Pekerjaan yang berfokus pada memprogram sistem komputer atau mesin produksi, merancang sistem atau peralatan kelistrikan dan elektronik, dan merancang sistem atau peralatan industri. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, problem solving, serta menciptakan dan mendesain. Biasanya dijalankan dengan pola hybrid maupun di lingkungan kantor. Umumnya menuntut pendidikan S1 atau D4.'),
  (129, 'Pekerjaan yang berfokus pada memprogram sistem komputer atau mesin produksi, merakit peralatan atau komponen, dan merawat alat dan peralatan kerja. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta analisa dan investigasi. Biasanya dijalankan dengan pola hybrid maupun di lingkungan kantor. Umumnya menuntut pendidikan D3.'),
  (190, 'Pekerjaan yang berfokus pada menilai kemampuan, kebutuhan, dan capaian peserta didik, memberi edukasi kesehatan kepada orang lain, dan menyusun materi informasi atau bahan ajar. Kesehariannya banyak diisi kegiatan membantu dan melayani, memimpin dan mengelola, serta menciptakan dan mendesain. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan sekolah atau kampus. Umumnya menuntut pendidikan S1 atau D4.'),
  (228, 'Pekerjaan yang berfokus pada menyusun rencana bisnis atau pemasaran, menulis naskah untuk keperluan seni atau komersial, dan membangun relasi dan jejaring profesional. Kesehariannya banyak diisi kegiatan memimpin dan mengelola, berkomunikasi dan berinteraksi, serta analisa dan investigasi. Biasanya dijalankan dengan pola hybrid maupun secara jarak jauh. Umumnya menuntut pendidikan S1 atau D4.'),
  (232, 'Pekerjaan yang berfokus pada menjadi penerjemah bahasa, budaya, atau keagamaan, menghimpun catatan, dokumentasi, dan data, dan menilai kualitas dan keakuratan data. Kesehariannya banyak diisi kegiatan berkomunikasi dan berinteraksi, eksperimen dan penelitian, serta membantu dan melayani. Biasanya dijalankan di lingkungan kantor maupun dengan pola hybrid. Umumnya menuntut pendidikan S1 atau D4.'),
  (240, 'Pekerjaan yang berfokus pada mengoperasikan peralatan audio visual, menyiapkan dan memasang peralatan, dan menentukan metode atau prosedur kerja. Kesehariannya banyak diisi kegiatan menciptakan dan mendesain, problem solving, serta berkomunikasi dan berinteraksi. Biasanya dijalankan dengan pola hybrid maupun di lingkungan kantor. Umumnya menuntut pendidikan D3.'),
  (241, 'Pekerjaan yang berfokus pada mengolah rekaman audio atau video, membuat konten berita, hiburan, atau karya seni, dan mengomunikasikan spesifikasi dan detail proyek. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, menciptakan dan mendesain, serta eksperimen dan penelitian. Biasanya dijalankan dengan pola hybrid maupun di lingkungan kantor. Umumnya menuntut pendidikan S1 atau D4.'),
  (264, 'Pekerjaan yang berfokus pada menyusun rencana perawatan pasien atau klien, menganalisis data kesehatan atau medis, dan mengevaluasi kondisi pasien dan pilihan penanganannya. Kesehariannya banyak diisi kegiatan menciptakan dan mendesain, membantu dan melayani, serta berkomunikasi dan berinteraksi. Biasanya dijalankan di lingkungan kantor maupun dengan pola hybrid. Umumnya menuntut pendidikan S2.'),
  (270, 'Pekerjaan yang berfokus pada memantau kondisi kesehatan manusia atau hewan, memberikan perawatan atau tindakan medis dasar, dan mengoperasikan peralatan medis. Kesehariannya banyak diisi kegiatan membantu dan melayani, problem solving, serta analisa dan investigasi. Biasanya dijalankan di fasilitas layanan kesehatan maupun di laboratorium. Umumnya menuntut pendidikan S1 atau D4.'),
  (368, 'Pekerjaan yang berfokus pada membuat materi pemasaran atau promosi, mempromosikan produk, layanan, atau program, dan menyiapkan dokumen kontrak, permohonan, atau perizinan. Kesehariannya banyak diisi kegiatan menjual dan mempengaruhi, berkomunikasi dan berinteraksi, serta membantu dan melayani. Biasanya dijalankan dengan pola hybrid maupun secara jarak jauh. Umumnya menuntut pendidikan S1 atau D4.'),
  (374, 'Pekerjaan yang berfokus pada menjelaskan detail teknis produk atau layanan, menjual produk atau layanan, dan menyusun proposal atau pengajuan hibah. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, menjual dan mempengaruhi, serta analisa dan investigasi. Biasanya dijalankan secara jarak jauh maupun di lingkungan kantor. Umumnya menuntut pendidikan D3.'),
  (401, 'Pekerjaan yang berfokus pada menentukan kebutuhan sumber daya proyek atau operasional, menilai teknologi atau proses ramah lingkungan, dan merencanakan aktivitas kerja. Kesehariannya banyak diisi kegiatan analisa dan investigasi, inspeksi dan quality control, serta memimpin dan mengelola. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan kantor. Umumnya menuntut pendidikan D3.'),
  (420, 'Pekerjaan yang berfokus pada memasang peralatan komersial atau produksi, memperbaiki peralatan listrik atau elektronik, dan menyetel peralatan agar kinerjanya optimal. Kesehariannya banyak diisi kegiatan eksperimen dan penelitian, membangun dan mengembangkan, serta problem solving. Biasanya dijalankan langsung di lokasi kerja maupun dengan pola hybrid. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (424, 'Pekerjaan yang berfokus pada memperbaiki alat atau peralatan, memperbaiki komponen kendaraan, dan menyetel peralatan agar kinerjanya optimal. Kesehariannya banyak diisi kegiatan analisa dan investigasi, membangun dan mengembangkan, serta eksperimen dan penelitian. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (428, 'Pekerjaan yang berfokus pada memperbaiki komponen kendaraan, memeriksa kendaraan, dan memperbaiki alat atau peralatan. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, membangun dan mengembangkan, serta mengajar dan membimbing. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (430, 'Pekerjaan yang berfokus pada merakit peralatan atau komponen, memperbaiki komponen kendaraan, dan memperbaiki alat atau peralatan. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, membangun dan mengembangkan, serta problem solving. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (457, 'Pekerjaan yang berfokus pada mengukur karakteristik fisik material, produk, atau peralatan, memeriksa hasil kerja atau produk jadi, dan menempatkan benda kerja atau material pada mesin. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, problem solving, serta inspeksi dan quality control. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (458, 'Pekerjaan yang berfokus pada mengoperasikan mesin pengolahan atau produksi industri, menempatkan benda kerja atau material pada mesin, dan membongkar peralatan. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, analisa dan investigasi, serta inspeksi dan quality control. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (460, 'Pekerjaan yang berfokus pada mengoperasikan mesin potong atau gerinda, menempatkan benda kerja atau material pada mesin, dan merawat alat dan peralatan kerja. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta problem solving. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (461, 'Pekerjaan yang berfokus pada memosisikan material atau komponen untuk dirakit, membaca dokumen kerja untuk memahami proses, dan menyetel peralatan agar kinerjanya optimal. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, analisa dan investigasi, serta inspeksi dan quality control. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (464, 'Pekerjaan yang berfokus pada menempatkan benda kerja atau material pada mesin, menyetel peralatan agar kinerjanya optimal, dan membaca dokumen kerja untuk memahami proses. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta problem solving. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (471, 'Pekerjaan yang berfokus pada menempatkan benda kerja atau material pada mesin, memuat produk, material, atau peralatan untuk diangkut, dan merawat alat dan peralatan kerja. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta problem solving. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (485, 'Pekerjaan yang berfokus pada mengoperasikan mesin pengolahan atau produksi industri, menempatkan benda kerja atau material pada mesin, dan menyiapkan material industri untuk diproses. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta membantu dan melayani. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMP.'),
  (490, 'Pekerjaan yang berfokus pada menjahit pakaian atau bahan, melakukan pengukuran fisik pada pasien atau klien, dan memotong material. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, menciptakan dan mendesain, serta problem solving. Biasanya dijalankan di lingkungan kantor maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (491, 'Pekerjaan yang berfokus pada memantau jalannya peralatan, membersihkan benda kerja atau produk jadi, dan menjahit pakaian atau bahan. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, membangun dan mengembangkan, serta analisa dan investigasi. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (492, 'Pekerjaan yang berfokus pada mengoperasikan mesin potong atau gerinda, memeriksa hasil kerja atau produk jadi, dan menempatkan benda kerja atau material pada mesin. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, membangun dan mengembangkan, serta eksperimen dan penelitian. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (493, 'Pekerjaan yang berfokus pada mengoperasikan mesin potong atau gerinda, memeriksa hasil kerja atau produk jadi, dan menempatkan benda kerja atau material pada mesin. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta berkomunikasi dan berinteraksi. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (497, 'Pekerjaan yang berfokus pada memperbaiki benda kerja atau produk, menjahit pakaian atau bahan, dan memosisikan material atau komponen untuk dirakit. Kesehariannya banyak diisi kegiatan eksperimen dan penelitian, inspeksi dan quality control, serta problem solving. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (507, 'Pekerjaan yang berfokus pada mengoperasikan peralatan produksi atau distribusi energi, merencanakan aktivitas kerja, dan memelihara catatan operasional. Kesehariannya banyak diisi kegiatan problem solving, inspeksi dan quality control, serta analisa dan investigasi. Biasanya dijalankan di lingkungan kantor maupun secara jarak jauh. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (519, 'Pekerjaan yang berfokus pada menyetel peralatan agar kinerjanya optimal, mengoperasikan sistem atau peralatan pompa, dan mengoperasikan mesin pengolahan atau produksi industri. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, membangun dan mengembangkan, serta analisa dan investigasi. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (558, 'Pekerjaan yang berfokus pada memuat produk, material, atau peralatan untuk diangkut, mengoperasikan kendaraan atau alat transportasi, dan mengoperasikan alat angkat dan alat pemindah. Kesehariannya banyak diisi kegiatan inspeksi dan quality control, analisa dan investigasi, serta problem solving. Biasanya dijalankan langsung di lokasi kerja maupun di lingkungan pabrik. Umumnya terbuka untuk lulusan SMA/SMK.'),
  (562, 'Pekerjaan yang berfokus pada memeriksa hasil kerja atau produk jadi, mengukur karakteristik fisik material, produk, atau peralatan, dan membersihkan alat, peralatan, fasilitas, dan area kerja. Kesehariannya banyak diisi kegiatan membangun dan mengembangkan, inspeksi dan quality control, serta eksperimen dan penelitian. Biasanya dijalankan di lingkungan pabrik maupun langsung di lokasi kerja. Umumnya terbuka untuk lulusan SMA/SMK.');

update public.careers c
set career_description = d.teks,
    description_source = 'generate_dari_dna'
from _desc21 d
where d.career_id = c.id;

-- ---------------------------------------------------------------------------
-- Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from public.careers
  where is_active
    and career_description ~ '\m(the|and|or|for|with|using|may|such as)\M'
    and career_description !~ '\m(dan|atau|untuk|yang|dengan)\M';
  if n > 0 then raise exception '% profesi aktif masih berdeskripsi bahasa Inggris', n; end if;

  select count(*) into n from public.careers
  where description_source = 'generate_dari_dna' and career_description ~ '[a-z]+ [A-Z][a-z]+';
  if n > 0 then raise exception '% deskripsi masih memuat huruf kapital nyasar di tengah kalimat', n; end if;
end $$;

commit;
