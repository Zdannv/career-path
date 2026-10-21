import Link from "next/link";
import type { Metadata } from "next";
import {
  Bug,
  ChevronDown,
  ChevronRight,
  MessageCircleQuestion,
  Send,
  UserX,
  type LucideIcon,
} from "lucide-react";
import { ROUTES } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Pusat Bantuan · Navika",
  description: "Jawaban untuk pertanyaan yang sering diajukan tentang Navika, dan cara menghubungi tim.",
};

const AKSI: { judul: string; isi: string; href: string; icon: LucideIcon }[] = [
  {
    judul: "Laporkan masalah",
    isi: "Ada halaman yang error atau tombol yang tidak berfungsi?",
    href: `${ROUTES.feedback}?kategori=masalah`,
    icon: Bug,
  },
  {
    judul: "Ajukan pertanyaan",
    isi: "Tidak menemukan jawabannya di bawah? Tanya langsung ke tim.",
    href: `${ROUTES.feedback}?kategori=pertanyaan`,
    icon: MessageCircleQuestion,
  },
  {
    judul: "Hapus akun & data",
    isi: "Minta penghapusan akun beserta seluruh data yang tersimpan.",
    href: `${ROUTES.feedback}?kategori=hapus_data`,
    icon: UserX,
  },
];

/**
 * Jawaban ditulis dari perilaku aplikasi yang sebenarnya. Kalau alurnya
 * berubah (mis. status kelulusan bisa dibuka lagi), ubah jawabannya juga.
 */
const FAQ: { grup: string; item: { t: string; j: string }[] }[] = [
  {
    grup: "Akun & masuk",
    item: [
      {
        t: "Apakah Navika gratis?",
        j: "Ya. Semua fitur Navika (Career DNA, rekomendasi profesi, roadmap, journey, dan quest) bisa dipakai tanpa biaya.",
      },
      {
        t: "Email verifikasi tidak masuk. Apa yang harus saya lakukan?",
        j: "Cek folder spam atau promotions lebih dulu. Kalau tetap tidak ada, tunggu hitung mundur di halaman verifikasi selesai, lalu tekan Kirim Ulang Email. Pastikan alamat yang Kamu daftarkan tidak salah ketik.",
      },
      {
        t: "Saya lupa kata sandi.",
        j: "Di halaman Masuk, pilih Lupa Kata Sandi? lalu masukkan email yang terdaftar. Navika akan mengirim link untuk membuat kata sandi baru. Link itu hanya bisa dipakai sekali.",
      },
      {
        t: "Bagaimana cara keluar dari akun?",
        j: "Buka halaman Profil lalu tekan Keluar dari Akun. Di ponsel, Kamu juga bisa keluar lewat menu di pojok kanan atas halaman utama.",
      },
    ],
  },
  {
    grup: "Career DNA & rekomendasi",
    item: [
      {
        t: "Apa itu Career DNA?",
        j: "Serangkaian pilihan singkat tentang minat, aktivitas yang Kamu sukai, dan kecenderunganmu. Jawabannya dipakai untuk menghitung seberapa cocok Kamu dengan setiap profesi di Navika.",
      },
      {
        t: "Bagaimana persentase kecocokan dihitung?",
        j: "Navika membandingkan pilihan Career DNA-mu dengan profil tiap profesi, lalu menyesuaikannya dengan latar pendidikanmu. Jurusan yang relevan menambah skor, sedangkan jurusan yang jauh dari profesi itu sedikit menguranginya. Makin lengkap pilihanmu di tiap langkah, makin akurat hasilnya.",
      },
      {
        t: "Hasil rekomendasinya terasa kurang pas.",
        j: "Buka lagi Career DNA dari Explore dan perbarui pilihanmu, terutama di langkah minat dan aktivitas. Kalau masih terasa janggal, kirim laporan lewat Feedback beserta profesi yang Kamu harapkan muncul. Masukan seperti ini membantu kami memperbaiki perhitungannya.",
      },
      {
        t: "Saya salah mengisi data pendidikan.",
        j: "Jenjang, jurusan, dan kelas atau semester bisa diubah di tab Pendidikan pada halaman Profil. Status yang sudah diisi Sudah lulus terkunci; kalau itu keliru, hubungi kami lewat Feedback.",
      },
    ],
  },
  {
    grup: "Roadmap, journey & quest",
    item: [
      {
        t: "Apa bedanya roadmap, journey, dan quest?",
        j: "Roadmap adalah gambaran tahapan menuju profesi pilihanmu. Journey menunjukkan posisimu di tahapan itu dan milestone berikutnya. Quest adalah tugas kecil yang bisa Kamu kerjakan setiap minggu untuk maju di journey.",
      },
      {
        t: "Bagaimana cara mendapatkan XP?",
        j: "Selesaikan quest. Setiap quest mencantumkan XP yang didapat, dan XP yang terkumpul menaikkan level serta membuka badge di halaman Progress.",
      },
    ],
  },
  {
    grup: "Data & privasi",
    item: [
      {
        t: "Data apa saja yang Navika simpan?",
        j: "Email, nama dan foto profil (kalau Kamu isi), data pendidikan, jawaban Career DNA, serta progres roadmap dan quest. Rinciannya ada di Kebijakan Privasi.",
      },
      {
        t: "Bagaimana cara menghapus akun saya?",
        j: "Masuk ke akunmu, lalu kirim permintaan lewat Feedback dengan jenis Hapus akun & data. Akun beserta seluruh datanya kami hapus paling lambat 14 hari kerja, dan kami kabari lewat email.",
      },
    ],
  },
];

export default function BantuanPage() {
  return (
    <div className="flex-1 bg-slate-50">
      <section className="bg-gradient-to-b from-indigo-50 via-purple-50/60 to-slate-50">
        <div className="mx-auto max-w-3xl px-4 pb-10 pt-12 sm:px-6 sm:pt-16">
          <p className="text-sm font-medium text-[#7033FF]">Support</p>
          <h1 className="mt-2 text-3xl font-medium tracking-tight text-slate-900 sm:text-4xl">
            Ada yang bisa kami bantu?
          </h1>
          <p className="mt-3 max-w-xl text-base leading-relaxed text-[#525252]">
            Temukan jawaban cepat di bawah, atau hubungi tim Navika langsung.
          </p>

          <div className="mt-8 grid gap-3 sm:grid-cols-3">
            {AKSI.map(({ judul, isi, href, icon: Icon }) => (
              <Link
                key={judul}
                href={href}
                className="group flex items-start gap-3 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-slate-200 transition-shadow hover:shadow-md sm:flex-col"
              >
                <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-[#F1EBFF] text-[#7033FF]">
                  <Icon className="size-5" />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="flex items-center gap-1 text-sm font-bold text-slate-900">
                    {judul}
                    <ChevronRight className="size-4 text-slate-400 transition-transform group-hover:translate-x-0.5" />
                  </span>
                  <span className="mt-1 block text-sm leading-relaxed text-[#525252]">{isi}</span>
                </span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-3xl px-4 pb-16 sm:px-6">
        <h2 className="text-xl font-bold text-slate-900">Pertanyaan yang sering diajukan</h2>

        <div className="mt-6 space-y-8">
          {FAQ.map(({ grup, item }) => (
            <div key={grup}>
              <h3 className="text-sm font-semibold uppercase tracking-wide text-slate-400">{grup}</h3>
              <div className="mt-3 divide-y divide-slate-100 overflow-hidden rounded-2xl bg-white ring-1 ring-slate-200">
                {item.map(({ t, j }) => (
                  <details key={t} className="group">
                    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 text-sm font-semibold text-slate-900 hover:bg-slate-50 [&::-webkit-details-marker]:hidden">
                      {t}
                      <ChevronDown className="size-4 shrink-0 text-slate-400 transition-transform group-open:rotate-180" />
                    </summary>
                    <p className="px-5 pb-5 text-sm leading-relaxed text-[#525252]">{j}</p>
                  </details>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 flex flex-col items-start gap-4 rounded-3xl bg-gradient-to-r from-indigo-700 via-purple-700 to-indigo-800 p-6 text-white sm:flex-row sm:items-center sm:justify-between sm:p-8">
          <div>
            <p className="text-lg font-bold">Punya ide untuk Navika?</p>
            <p className="mt-1 text-sm text-indigo-100">Saran kecil pun kami baca dan pertimbangkan.</p>
          </div>
          <Link
            href={`${ROUTES.feedback}?kategori=saran`}
            className="inline-flex shrink-0 items-center gap-2 rounded-full bg-white px-5 py-3 text-sm font-semibold text-slate-900 shadow-md hover:shadow-lg"
          >
            <Send className="size-4" />
            Kirim Feedback
          </Link>
        </div>
      </section>
    </div>
  );
}
