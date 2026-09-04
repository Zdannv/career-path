-- ============================================================================
-- 0014_family_names.sql
--
-- Memberi nama yang benar pada 61 rumpun otomatis yang dibuat 0013.
--
-- 0013 mengelompokkan profesi menurut SOC minor group, lalu memberi nama rumpun
-- dengan nama profesi anggota pertama secara alfabet. Hasilnya menyesatkan:
-- "ERP Consultant" tampil berada di rumpun "QA Engineer / Software Tester",
-- seolah rumpun itu tentang pengujian perangkat lunak padahal isinya 38 profesi
-- komputer. Nama di bawah menggambarkan kelompoknya, bukan salah satu isinya.
--
-- Nama dan deskripsi ini saya susun dari daftar anggota tiap rumpun dan makna
-- SOC minor group-nya. Belum ditinjau manusia, jadi is_curated tetap false —
-- yang berubah cuma namanya jadi masuk akal untuk ditampilkan.
--
-- Jalankan setelah 0013. Aman diulang.
-- ============================================================================

begin;

create temp table _fam_nama (code text primary key, nama text, deskripsi text) on commit drop;

insert into _fam_nama values
('SOC_11_20','Manajer Pemasaran, Promosi & Humas','Memimpin fungsi pemasaran, promosi, dan hubungan masyarakat di sebuah organisasi.'),
('SOC_11_30','Manajer Fungsi Bisnis','Memimpin satu fungsi khusus dalam perusahaan: keuangan, produksi, mutu, pembelian, atau rantai pasok.'),
('SOC_11_91','Manajer Kepatuhan & Risiko','Memastikan kegiatan perusahaan patuh pada aturan dan mengelola risiko kerugian.'),
('SOC_13_10','Spesialis Operasi Bisnis & Pengadaan','Menganalisa dan menjalankan proses bisnis sehari-hari: pengadaan, logistik, kepatuhan, dan klaim.'),
('SOC_13_20','Spesialis Keuangan, Akuntansi & Investasi','Menganalisa uang, risiko, dan nilai aset: akuntansi, kredit, anggaran, pajak, dan investasi.'),
('SOC_15_12','Pengembang Perangkat Lunak & Infrastruktur TI','Membangun dan merawat perangkat lunak, jaringan, basis data, dan keamanan sistem.'),
('SOC_15_20','Data, Statistika & Sains Kuantitatif','Mengolah data menjadi model dan keputusan: analisa data, statistika, machine learning, dan aktuaria.'),
('SOC_17_20','Insinyur Elektro & Elektronika','Merancang perangkat dan sistem kelistrikan, elektronika, serta perangkat terhubung.'),
('SOC_17_21','Insinyur Teknik Industri, Mesin & Energi','Merancang mesin, proses produksi, material, dan sistem energi.'),
('SOC_17_30','Teknisi Keteknikan','Mendukung insinyur pada pengujian, pemasangan, dan pemeliharaan sistem teknik.'),
('SOC_19_10','Ilmuwan Hayati & Pangan','Meneliti organisme hidup dan bahan pangan untuk menghasilkan produk atau pengetahuan baru.'),
('SOC_19_20','Ilmuwan Fisik & Kebumian','Meneliti bumi, bahan, dan gejala fisik untuk kebutuhan industri maupun ilmu pengetahuan.'),
('SOC_19_40','Teknisi Laboratorium Sains & Pengujian','Menjalankan pengujian laboratorium dan lapangan untuk memastikan mutu dan keamanan.'),
('SOC_25_10','Dosen Bidang Sains, Teknologi & Ekonomi','Mengajar dan meneliti di perguruan tinggi pada rumpun eksakta, teknik, dan ekonomi.'),
('SOC_25_11','Dosen Bidang Humaniora, Sosial & Seni','Mengajar dan meneliti di perguruan tinggi pada rumpun bahasa, sosial, hukum, dan seni.'),
('SOC_25_20','Guru PAUD, SD & Sekolah Menengah','Mengajar di jenjang pendidikan formal, termasuk pendidikan khusus.'),
('SOC_25_30','Pengajar Nonformal & Bimbingan Belajar','Mengajar di luar sekolah formal: kursus, les privat, dan pendidikan kesetaraan.'),
('SOC_25_40','Pustakawan, Arsiparis & Kurator','Mengelola koleksi pengetahuan dan benda budaya agar tetap terpelihara dan bisa diakses.'),
('SOC_25_90','Tenaga Pendukung Pendidikan & Penyuluhan','Mendampingi proses belajar dan menyebarkan pengetahuan ke masyarakat.'),
('SOC_27_10','Desainer & Seniman Visual','Merancang tampilan produk, ruang, busana, dan karya visual.'),
('SOC_27_20','Produser, Sutradara & Pengarah Artistik','Memimpin pembuatan karya pertunjukan, film, siaran, dan musik.'),
('SOC_27_30','Penulis, Jurnalis & Komunikasi Publik','Menyusun dan menyampaikan informasi melalui tulisan dan siaran.'),
('SOC_27_40','Teknisi Media, Audio & Visual','Menangani kamera, suara, cahaya, dan penyuntingan dalam produksi media.'),
('SOC_29_10','Praktisi Kesehatan: Gigi, Farmasi, Gizi & Mata','Praktisi kesehatan berlisensi di luar kedokteran umum dan keperawatan.'),
('SOC_29_11','Perawat, Bidan & Terapis Klinis','Merawat dan memulihkan pasien secara langsung dalam tim layanan kesehatan.'),
('SOC_29_12','Dokter & Dokter Spesialis','Mendiagnosis dan mengobati penyakit sebagai dokter umum maupun spesialis.'),
('SOC_29_20','Teknolog & Teknisi Kesehatan','Menjalankan pemeriksaan laboratorium, pencitraan, dan alat medis penunjang diagnosis.'),
('SOC_29_90','Tenaga Kesehatan Penunjang Lainnya','Peran kesehatan khusus yang menunjang layanan klinis.'),
('SOC_31_11','Perawatan Pribadi & Pendampingan Pasien','Mendampingi kebutuhan harian pasien, lansia, dan penyandang disabilitas.'),
('SOC_31_20','Asisten Terapi Fisik & Okupasi','Membantu terapis menjalankan program pemulihan gerak dan aktivitas pasien.'),
('SOC_31_90','Asisten & Teknisi Layanan Kesehatan','Membantu tenaga medis pada tindakan, sterilisasi, dan penyiapan alat.'),
('SOC_39_50','Perawatan Diri & Tata Rias','Layanan penampilan dan perawatan tubuh, termasuk tata rias panggung dan film.'),
('SOC_41_20','Kasir & Pramuniaga Ritel','Melayani transaksi dan pelanggan langsung di gerai ritel.'),
('SOC_41_30','Penjualan Jasa & Perjalanan','Menjual layanan tak berwujud seperti perjalanan, tiket, dan paket wisata.'),
('SOC_41_90','Penjualan & Representasi Lainnya','Peran penjualan dan perwakilan yang tidak masuk kelompok penjualan lain.'),
('SOC_43_30','Administrasi Keuangan & Perbankan','Mengurus transaksi, pencatatan, dan dokumen keuangan di kantor.'),
('SOC_43_40','Layanan Pelanggan & Verifikasi Informasi','Menerima permintaan pelanggan dan memeriksa kelengkapan data.'),
('SOC_43_41','Administrasi Pemesanan & Kredit','Memproses pesanan, pengajuan kredit, dan berkas pendukungnya.'),
('SOC_43_50','Logistik, Gudang & Pengiriman','Mengatur perpindahan barang dari gudang sampai ke penerima.'),
('SOC_43_51','Pencatatan & Pengendalian Stok','Mencatat, menghitung, dan mencocokkan persediaan barang.'),
('SOC_47_10','Supervisi Konstruksi & Instalasi','Mengawasi pekerja lapangan pada proyek pemasangan dan pembangunan.'),
('SOC_47_21','Instalasi Sistem Termal & Pemanas','Memasang dan merawat sistem pemanas air serta perpipaan termal.'),
('SOC_47_22','Instalasi Surya & Energi Terbarukan','Memasang panel surya dan perangkat pembangkit energi terbarukan.'),
('SOC_47_40','Inspeksi & Audit Bangunan/Energi','Memeriksa kelayakan bangunan dan efisiensi penggunaan energi.'),
('SOC_47_50','Pertambangan, Migas & Pengeboran','Menjalankan alat dan proses pengambilan mineral serta minyak dan gas.'),
('SOC_49_20','Teknisi Servis Elektronik & Mesin Kantor','Memperbaiki perangkat elektronik dan mesin perkantoran.'),
('SOC_49_30','Mekanik Kendaraan & Alat Berat','Merawat dan memperbaiki mesin kendaraan, kapal, dan alat berat.'),
('SOC_49_90','Teknisi Instalasi & Pemeliharaan Lainnya','Pemasangan dan perbaikan mesin serta peralatan khusus.'),
('SOC_51_10','Supervisi Produksi & Manufaktur','Mengawasi jalannya lini produksi dan pekerja pabrik.'),
('SOC_51_20','Perakitan & Fabrikasi','Merakit komponen menjadi produk jadi di lingkungan produksi.'),
('SOC_51_30','Pengolahan Pangan & Daging','Mengolah bahan pangan mentah menjadi produk siap distribusi.'),
('SOC_51_40','Operator Permesinan Logam & Plastik','Menjalankan mesin pembentuk logam dan plastik seperti bubut, frais, dan press.'),
('SOC_51_41','Pengelasan, Tempa & Perlakuan Logam','Menyambung dan mengolah sifat logam melalui las, tempa, dan pelapisan.'),
('SOC_51_51','Percetakan & Finishing Grafika','Menjalankan proses cetak, pracetak, dan penyelesaian produk grafika.'),
('SOC_51_60','Tekstil, Garmen & Alas Kaki','Mengolah benang, kain, dan kulit menjadi pakaian serta alas kaki.'),
('SOC_51_70','Pengerjaan Kayu & Mebel','Mengolah kayu menjadi perabot dan komponen bangunan.'),
('SOC_51_80','Operator Pembangkit & Pengolahan Utilitas','Menjalankan pembangkit listrik, kilang, dan instalasi pengolahan air.'),
('SOC_51_90','Operator Proses Produksi Lainnya','Menjalankan mesin proses produksi yang tidak masuk kelompok lain.'),
('SOC_51_91','Operator Mesin Kemasan & Produksi Umum','Menjalankan mesin pengemasan, pengisian, dan produksi serbaguna.'),
('SOC_53_60','Layanan Transportasi & Pengisian Bahan Bakar','Melayani kebutuhan operasional kendaraan dan penumpang.'),
('SOC_53_70','Penanganan Material & Alat Angkat','Memindahkan barang dengan crane, conveyor, pompa, dan alat angkut.');

-- Hanya menyentuh rumpun otomatis. Tujuh rumpun kurasi manual dari 0011 tidak
-- boleh ikut tertimpa.
update public.career_families f
set name_id        = n.nama,
    description_id = n.deskripsi
from _fam_nama n
where f.code = n.code and f.is_curated = false;

-- Tiap rumpun otomatis harus kebagian nama. Kalau ada kode baru muncul dari
-- 0013 yang belum ada di daftar ini, guard ini yang memberi tahu.
do $$
declare
  sisa text;
begin
  select string_agg(code, ', ') into sisa
  from public.career_families
  where is_curated = false and code like 'SOC\_%' and code not in (select code from _fam_nama);
  if sisa is not null then
    raise exception 'rumpun otomatis belum diberi nama: %', sisa;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Satu profesi warisan tanpa nama
--
-- careers id 364 (SOC 41-2012, Gaming Change Persons) tersimpan dengan
-- career_name = '-'. Ia sudah nonaktif, jadi tidak pernah muncul ke pengguna,
-- tapi tetap ikut terekspor ke tiap laporan dan terbaca seperti data rusak.
-- Diberi nama apa adanya; statusnya tetap nonaktif karena profesinya memang
-- tidak relevan di Indonesia.
-- ---------------------------------------------------------------------------
update public.careers
set career_name = 'Petugas Penukaran Chip Kasino',
    curation_note = coalesce(curation_note || ' | ', '') ||
                    'nama diisi di 0014; sebelumnya kosong. Nonaktif: tidak relevan di Indonesia.'
where soc_code = '41-2012.00' and career_name = '-';

commit;

-- ============================================================================
-- Verifikasi:
--   select code, name_id, is_curated from career_families order by is_curated desc, code;
--   -- tidak boleh ada name_id yang sama persis dengan salah satu careers.career_name
-- ============================================================================
