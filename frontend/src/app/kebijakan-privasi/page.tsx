import Link from "next/link";
import type { Metadata } from "next";
import DokumenLegal, { type BagianLegal } from "@/components/DokumenLegal";
import { ROUTES } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Kebijakan Privasi · Navika",
  description: "Data apa yang Navika kumpulkan, untuk apa dipakai, dan bagaimana menghapusnya.",
};

/**
 * Isi mengikuti data yang benar-benar disimpan aplikasi (profil, pendidikan,
 * Career DNA, progres, avatar di Storage, tabel feedback). Kalau ada data
 * baru yang dikumpulkan, bagian 2 dan 4 wajib diperbarui.
 */
const BAGIAN: BagianLegal[] = [
  {
    id: "tentang",
    judul: "Tentang kebijakan ini",
    isi: (
      <>
        <p>
          Navika adalah platform perencanaan karier yang dikembangkan oleh Sub1 Studio
          (&ldquo;kami&rdquo;). Kebijakan ini menjelaskan data pribadi apa yang kami kumpulkan saat
          Kamu memakai Navika, untuk apa data itu dipakai, dan hak yang Kamu miliki atasnya,
          sesuai Undang-Undang Nomor 27 Tahun 2022 tentang Pelindungan Data Pribadi.
        </p>
        <p>
          Dengan membuat akun, Kamu menyatakan telah membaca kebijakan ini. Kalau Kamu berusia di
          bawah 18 tahun, pastikan orang tua atau walimu mengetahui dan menyetujui pemakaian
          Navika.
        </p>
      </>
    ),
  },
  {
    id: "data",
    judul: "Data yang kami kumpulkan",
    isi: (
      <>
        <p>Kami hanya mengumpulkan data yang diperlukan untuk menjalankan fitur Navika:</p>
        <ul>
          <li>
            <strong>Data akun:</strong> alamat email dan kata sandi. Kata sandi disimpan dalam
            bentuk terenkripsi (hash) dan tidak bisa dibaca oleh siapa pun, termasuk tim kami.
          </li>
          <li>
            <strong>Data profil:</strong> nama dan foto profil, kalau Kamu mengisinya.
          </li>
          <li>
            <strong>Data pendidikan:</strong> jenjang, jurusan atau program studi, status
            kelulusan, serta kelas atau semester.
          </li>
          <li>
            <strong>Jawaban Career DNA:</strong> pilihan minat, aktivitas, dan kecenderungan yang
            Kamu isi.
          </li>
          <li>
            <strong>Data aktivitas:</strong> profesi yang Kamu simpan atau pilih, jalur pendidikan,
            progres roadmap dan journey, quest yang diselesaikan, XP, badge, dan notifikasi.
          </li>
          <li>
            <strong>Masukan:</strong> isi pesan, penilaian, dan email yang Kamu kirim lewat halaman
            Feedback, beserta halaman asal dan jenis peramban.
          </li>
          <li>
            <strong>Data teknis:</strong> catatan akses standar seperti waktu masuk dan jenis
            perangkat, yang dipakai untuk keamanan dan memperbaiki gangguan.
          </li>
        </ul>
        <p>
          Kami tidak meminta nomor identitas, alamat rumah, data keuangan, maupun data kesehatan.
        </p>
      </>
    ),
  },
  {
    id: "penggunaan",
    judul: "Untuk apa data dipakai",
    isi: (
      <ul>
        <li>Membuat dan mengamankan akunmu, termasuk verifikasi email dan reset kata sandi.</li>
        <li>
          Menghitung kecocokanmu dengan setiap profesi dan menyusun rekomendasi, roadmap, serta
          quest yang sesuai dengan latar pendidikanmu.
        </li>
        <li>Menampilkan progres, level, dan pencapaianmu.</li>
        <li>Membalas pertanyaan dan menindaklanjuti laporan yang Kamu kirim.</li>
        <li>
          Memahami cara Navika dipakai secara keseluruhan agar fitur dan perhitungannya bisa
          diperbaiki. Untuk keperluan ini kami memakai data gabungan yang tidak menunjuk ke orang
          tertentu.
        </li>
      </ul>
    ),
  },
  {
    id: "berbagi",
    judul: "Dengan siapa data dibagikan",
    isi: (
      <>
        <p>
          Kami <strong>tidak menjual</strong> data pribadimu dan tidak membagikannya kepada
          pihak lain untuk iklan. Data hanya diproses oleh penyedia layanan yang membantu Navika
          berjalan, dengan perjanjian untuk menjaganya:
        </p>
        <ul>
          <li>
            <strong>Supabase:</strong> penyimpanan database, autentikasi akun, dan penyimpanan
            foto profil.
          </li>
          <li>
            <strong>Penyedia hosting aplikasi:</strong> menjalankan situs Navika.
          </li>
          <li>
            <strong>Layanan analitik:</strong> mencatat kunjungan halaman untuk memahami pemakaian
            secara umum.
          </li>
        </ul>
        <p>
          Sebagian penyedia tersebut dapat menyimpan data di server luar Indonesia. Kami memilih
          penyedia yang menerapkan standar pelindungan data yang setara. Data juga dapat kami
          serahkan bila diwajibkan oleh peraturan perundang-undangan atau perintah aparat yang
          berwenang.
        </p>
      </>
    ),
  },
  {
    id: "keamanan",
    judul: "Keamanan data",
    isi: (
      <p>
        Data dikirim melalui koneksi terenkripsi (HTTPS). Akses ke database dibatasi dengan aturan
        per baris, sehingga setiap akun hanya bisa membaca datanya sendiri. Meski begitu, tidak
        ada sistem yang sepenuhnya kebal. Jaga kerahasiaan kata sandimu dan segera beri tahu kami
        kalau Kamu menduga akunmu disalahgunakan.
      </p>
    ),
  },
  {
    id: "penyimpanan",
    judul: "Berapa lama data disimpan",
    isi: (
      <p>
        Data disimpan selama akunmu aktif. Setelah Kamu meminta penghapusan, akun beserta seluruh
        data yang terkait dengannya kami hapus paling lambat 14 hari kerja. Pesan feedback yang
        tidak terhubung ke akun disimpan paling lama 2 tahun, lalu dihapus.
      </p>
    ),
  },
  {
    id: "hak",
    judul: "Hak Kamu",
    isi: (
      <>
        <p>Sebagai pemilik data, Kamu berhak untuk:</p>
        <ul>
          <li>Melihat dan memperbarui data profil serta pendidikan lewat halaman Profil.</li>
          <li>Meminta salinan data pribadi yang kami simpan tentangmu.</li>
          <li>Meminta koreksi atas data yang tidak bisa Kamu ubah sendiri.</li>
          <li>Menarik persetujuan dan meminta penghapusan akun beserta seluruh datanya.</li>
        </ul>
        <p>
          Kirim permintaan lewat{" "}
          <Link href={`${ROUTES.feedback}?kategori=hapus_data`} className="font-semibold text-[#7033FF]">
            halaman Feedback
          </Link>{" "}
          dari akun yang bersangkutan. Kami menanggapi paling lambat 3 × 24 jam dan
          menyelesaikannya dalam waktu yang disebutkan di atas.
        </p>
      </>
    ),
  },
  {
    id: "perubahan",
    judul: "Perubahan kebijakan",
    isi: (
      <p>
        Kebijakan ini dapat diperbarui ketika Navika menambah fitur atau ketika aturan berubah.
        Tanggal berlaku di bagian atas halaman akan ikut berubah. Untuk perubahan penting, kami
        memberi tahu lewat notifikasi di aplikasi atau email sebelum perubahan berlaku.
      </p>
    ),
  },
];

export default function Page() {
  return (
    <DokumenLegal
      judul="Kebijakan Privasi"
      ringkas="Data apa saja yang Navika kumpulkan, untuk apa dipakai, berapa lama disimpan, dan bagaimana cara menghapusnya."
      berlaku="21 Oktober 2026"
      bagian={BAGIAN}
    />
  );
}
