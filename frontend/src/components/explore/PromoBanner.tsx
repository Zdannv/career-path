"use client";

/**
 * Banner promosi di kolom kiri Explore.
 *
 * Dulu ketiganya dipasang sebagai satu gambar utuh — teks dan tombolnya ikut
 * tergambar di dalamnya. Hasilnya kabur: berkas kiriman hanya 341 piksel,
 * sedangkan kolomnya 380 dan layar retina menuntut dua kali lipat.
 *
 * Sekarang gambar hanya jadi latar, sedangkan judul, keterangan, dan tombolnya
 * teks sungguhan. Selain tajam di ukuran berapa pun, teksnya jadi bisa dipilih,
 * dibaca pembaca layar, dan diubah tanpa menunggu ekspor ulang dari desainer.
 *
 * Banner Career Insights dihapus dari Explore atas permintaan tim.
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";

type Banner = {
  /** Ilustrasi untuk wadah sempit: ponsel dan kolom kiri desktop. */
  art: string;
  /** Ilustrasi untuk wadah lebar: tablet, tempat banner memenuhi lebar layar. */
  artWide: string;
  eyebrow: string;
  title: string;
  body: string;
  cta: string;
  /** Lebar kolom teks — sisanya dibiarkan kosong untuk ilustrasi di kanan. */
  textW: string;
};

export const BANNERS: Record<string, Banner> = {
  discovery: {
    art: "/explore/discovery-art.png",
    artWide: "/explore/discovery-art-wide.png",
    textW: "max-w-[80%] sm:max-w-[62%]",
    eyebrow: "Career Discovery",
    title: "Masih bingung mau jadi apa?",
    body: "Merekomendasikan profesi yang paling sesuai dengan minat dan keahlianmu",
    cta: "Mulai Career Discovery",
  },
  dna: {
    art: "/explore/dna-art.png",
    artWide: "/explore/dna-art-wide.png",
    textW: "max-w-[76%] sm:max-w-[58%]",
    eyebrow: "Career DNA",
    title: "Selangkah lagi!",
    body: "Lengkapi data minat dan keahlian untuk menyusun rencana belajar yang paling pas.",
    cta: "Personalisasi Sekarang",
  },
};

type Props = {
  variant: keyof typeof BANNERS;
  href: string;
  className?: string;
  /**
   * Menimpa teks banner. Dipakai banner Career DNA saat pengisiannya sudah
   * berjalan sebagian: eyebrow-nya menyebut langkah keberapa dan tombolnya
   * berbunyi "Lanjutkan progress-mu", bukan mengajak mulai dari awal.
   */
  overrides?: { eyebrow?: string; cta?: string };
};

export default function PromoBanner({ variant, href, className = "", overrides }: Props) {
  const b = BANNERS[variant];

  return (
    <Link
      href={href}
      className={`group relative block min-h-[200px] overflow-hidden rounded-2xl bg-[#EFEBFB] transition-opacity hover:opacity-95 sm:min-h-[180px] lg:min-h-[200px] ${className}`}
    >
      {/* Dua berkas untuk satu ilustrasi karena wadahnya berubah bentuk:
          4:1 saat memenuhi lebar tablet, 1,7:1 di ponsel dan di kolom kiri
          desktop. Memakai satu berkas untuk keduanya berarti salah satunya
          terpotong parah — persis yang terjadi sebelum ini. */}
      <div
        className="absolute inset-0 bg-cover bg-right-bottom bg-no-repeat sm:hidden lg:block"
        style={{ backgroundImage: `url('${b.art}')` }}
        aria-hidden
      />
      <div
        className="absolute inset-0 hidden bg-cover bg-right-bottom bg-no-repeat sm:block lg:hidden"
        style={{ backgroundImage: `url('${b.artWide}')` }}
        aria-hidden
      />
      <div
        className="absolute inset-0 bg-gradient-to-r from-[#EFEBFB] via-[#EFEBFB]/85 to-transparent"
        aria-hidden
      />

      <div className={`relative flex flex-col gap-1.5 p-5 ${b.textW}`}>
        <p className="text-[12px] font-bold text-violet-600">{overrides?.eyebrow ?? b.eyebrow}</p>
        <h3 className="text-[18px] font-bold leading-tight tracking-tight text-slate-900 sm:text-[19px]">
          {b.title}
        </h3>
        <p className="text-[12.5px] leading-relaxed text-slate-600">{b.body}</p>
        {/* Tombolnya harus tetap satu baris: di kolom kiri desktop yang cuma 340px,
            "Mulai Career Discovery" pecah jadi dua baris dan bentuk pilnya rusak. */}
        <span className="mt-3 inline-flex w-fit items-center gap-2 whitespace-nowrap rounded-full bg-violet-600 px-4 py-2 text-[12px] font-semibold text-white transition-colors group-hover:bg-violet-700 sm:text-[12.5px]">
          {overrides?.cta ?? b.cta}
          <ArrowRight className="size-3.5" aria-hidden />
        </span>
      </div>
    </Link>
  );
}
