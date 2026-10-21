import Link from "next/link";
import type { Metadata } from "next";
import DokumenLegal, { type BagianLegal } from "@/components/DokumenLegal";
import { ROUTES } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Syarat Layanan · Navika",
  description: "Aturan pemakaian Navika dan batas tanggung jawab atas rekomendasi karier.",
};

const BAGIAN: BagianLegal[] = [
  {
    id: "penerimaan",
    judul: "Penerimaan syarat",
    isi: (
      <>
        <p>
          Syarat Layanan ini mengatur pemakaian Navika, platform perencanaan karier yang
          dikembangkan oleh Sub1 Studio (&ldquo;kami&rdquo;). Dengan membuat akun atau memakai
          Navika, Kamu menyetujui syarat ini dan{" "}
          <Link href={ROUTES.kebijakanPrivasi} className="font-semibold text-[#7033FF]">
            Kebijakan Privasi
          </Link>
          .
        </p>
        <p>
          Kalau Kamu berusia di bawah 18 tahun, Kamu menyatakan sudah mendapat persetujuan orang
          tua atau wali untuk memakai Navika.
        </p>
      </>
    ),
  },
  {
    id: "layanan",
    judul: "Layanan Navika",
    isi: (
      <p>
        Navika membantu Kamu mengenali profesi yang sesuai dengan minat dan latar pendidikanmu,
        lalu menyusun roadmap, journey, dan quest untuk mencapainya. Layanan ini disediakan
        secara gratis dan dapat berubah, bertambah, atau dihentikan sebagian seiring
        pengembangan.
      </p>
    ),
  },
  {
    id: "akun",
    judul: "Akun Kamu",
    isi: (
      <ul>
        <li>Gunakan email yang aktif dan milikmu sendiri, dan isi data dengan jujur.</li>
        <li>
          Kamu bertanggung jawab menjaga kerahasiaan kata sandi dan atas aktivitas yang terjadi di
          akunmu.
        </li>
        <li>Satu akun untuk satu orang. Akun tidak boleh dipindahtangankan atau dijual.</li>
      </ul>
    ),
  },
  {
    id: "larangan",
    judul: "Yang tidak boleh dilakukan",
    isi: (
      <>
        <p>Saat memakai Navika, Kamu setuju untuk tidak:</p>
        <ul>
          <li>Mengakses akun orang lain atau mencoba melewati pembatasan keamanan.</li>
          <li>
            Mengambil data Navika secara otomatis dalam jumlah besar (scraping) atau membebani
            server dengan sengaja.
          </li>
          <li>
            Mengunggah foto atau mengirim pesan yang melanggar hukum, mengandung SARA, pornografi,
            atau melanggar hak orang lain.
          </li>
          <li>Memakai Navika untuk menipu atau menyamar sebagai pihak lain.</li>
        </ul>
        <p>
          Kami dapat menangguhkan atau menutup akun yang melanggar ketentuan ini, dengan atau
          tanpa pemberitahuan lebih dulu bila pelanggarannya membahayakan pengguna lain.
        </p>
      </>
    ),
  },
  {
    id: "rekomendasi",
    judul: "Sifat rekomendasi karier",
    isi: (
      <>
        <p>
          Persentase kecocokan, rekomendasi profesi, informasi gaji, kampus, sertifikasi, dan
          roadmap di Navika disusun dari data publik dan perhitungan otomatis. Semuanya adalah{" "}
          <strong>bahan pertimbangan</strong>, bukan jaminan diterima kerja, diterima di kampus,
          atau besaran penghasilan tertentu.
        </p>
        <p>
          Keputusan pendidikan dan karier tetap ada di tanganmu. Untuk keputusan besar, kami
          menyarankan Kamu juga berdiskusi dengan orang tua, guru BK, dosen, atau praktisi di
          bidangnya. Data seperti gaji dan akreditasi dapat berubah sewaktu-waktu.
        </p>
      </>
    ),
  },
  {
    id: "konten",
    judul: "Hak atas konten",
    isi: (
      <p>
        Desain, ilustrasi, teks, dan susunan data di Navika adalah milik Sub1 Studio atau pemberi
        lisensinya, dan tidak boleh disalin untuk keperluan komersial tanpa izin. Data yang Kamu
        isi tetap milikmu; Kamu memberi kami izin memakainya sebatas untuk menjalankan layanan,
        sebagaimana dijelaskan di Kebijakan Privasi.
      </p>
    ),
  },
  {
    id: "tanggung-jawab",
    judul: "Batas tanggung jawab",
    isi: (
      <p>
        Navika disediakan &ldquo;sebagaimana adanya&rdquo;. Kami berusaha menjaga layanan tetap
        tersedia dan datanya akurat, tetapi tidak menjamin layanan bebas gangguan atau bebas
        kesalahan. Sejauh diizinkan hukum, kami tidak bertanggung jawab atas kerugian yang timbul
        dari keputusan yang diambil semata-mata berdasarkan rekomendasi Navika.
      </p>
    ),
  },
  {
    id: "penghentian",
    judul: "Menghentikan pemakaian",
    isi: (
      <p>
        Kamu bisa berhenti memakai Navika kapan saja dan meminta akunmu dihapus lewat{" "}
        <Link href={`${ROUTES.feedback}?kategori=hapus_data`} className="font-semibold text-[#7033FF]">
          halaman Feedback
        </Link>
        . Setelah akun dihapus, progres, XP, dan data lain di dalamnya tidak bisa dipulihkan.
      </p>
    ),
  },
  {
    id: "perubahan",
    judul: "Perubahan dan hukum yang berlaku",
    isi: (
      <p>
        Syarat ini dapat diperbarui sewaktu-waktu; tanggal berlaku di atas akan ikut berubah, dan
        perubahan penting kami umumkan lebih dulu. Syarat ini tunduk pada hukum Republik
        Indonesia.
      </p>
    ),
  },
];

export default function Page() {
  return (
    <DokumenLegal
      judul="Syarat Layanan"
      ringkas="Aturan pemakaian Navika: apa yang boleh dan tidak boleh dilakukan, serta batas tanggung jawab kami atas rekomendasi karier yang ditampilkan."
      berlaku="21 Oktober 2026"
      bagian={BAGIAN}
    />
  );
}
