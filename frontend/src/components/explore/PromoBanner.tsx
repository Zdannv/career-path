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
 * Career Insights masih memakai gambar utuh karena asetnya membawa teks —
 * wordmark bergradien yang tidak bisa ditiru dengan CSS begitu saja. Ia dipasang
 * dari berkas 734 piksel supaya tetap tajam.
 */

import Image from "next/image";
import Link from "next/link";
import { ArrowRight } from "lucide-react";

type ArtBanner = {
  jenis: "art";
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

type ImageBanner = {
  jenis: "image";
  src: string;
  width: number;
  height: number;
  alt: string;
};

export const BANNERS: Record<string, ArtBanner | ImageBanner> = {
  discovery: {
    jenis: "art",
    art: "/explore/discovery-art.png",
    artWide: "/explore/discovery-art-wide.png",
    textW: "max-w-[80%] sm:max-w-[62%]",
    eyebrow: "Career Discovery",
    title: "Masih bingung mau jadi apa?",
    body: "Merekomendasikan profesi yang paling sesuai dengan minat dan keahlianmu",
    cta: "Mulai Career Discovery",
  },
  dna: {
    jenis: "art",
    art: "/explore/dna-art.png",
    artWide: "/explore/dna-art-wide.png",
    textW: "max-w-[76%] sm:max-w-[58%]",
    eyebrow: "Career DNA",
    title: "Selangkah lagi!",
    body: "Lengkapi data minat dan keahlian untuk menyusun rencana belajar yang paling pas.",
    cta: "Personalisasi Sekarang",
  },
  insights: {
    jenis: "image",
    src: "/explore/career-insights.png",
    width: 734,
    height: 206,
    alt: "Career Insights — cari tahu prediksi karier menjanjikan 10 tahun ke depan yang minim tergeser oleh teknologi dan AI.",
  },
};

type Props = {
  variant: keyof typeof BANNERS;
  href: string;
  className?: string;
  priority?: boolean;
};

export default function PromoBanner({ variant, href, className = "", priority = false }: Props) {
  const b = BANNERS[variant];

  if (b.jenis === "image") {
    return (
      <Link
        href={href}
        className={`block overflow-hidden rounded-2xl transition-opacity hover:opacity-95 ${className}`}
      >
        <Image
          src={b.src}
          alt={b.alt}
          width={b.width}
          height={b.height}
          priority={priority}
          sizes="(min-width: 1024px) 384px, 100vw"
          className="h-auto w-full"
        />
      </Link>
    );
  }

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
        <p className="text-[12px] font-bold text-violet-600">{b.eyebrow}</p>
        <h3 className="text-[18px] font-bold leading-tight tracking-tight text-slate-900 sm:text-[19px]">
          {b.title}
        </h3>
        <p className="text-[12.5px] leading-relaxed text-slate-600">{b.body}</p>
        {/* Tombolnya harus tetap satu baris: di kolom kiri desktop yang cuma 340px,
            "Mulai Career Discovery" pecah jadi dua baris dan bentuk pilnya rusak. */}
        <span className="mt-3 inline-flex w-fit items-center gap-2 whitespace-nowrap rounded-full bg-violet-600 px-4 py-2 text-[12px] font-semibold text-white transition-colors group-hover:bg-violet-700 sm:text-[12.5px]">
          {b.cta}
          <ArrowRight className="size-3.5" aria-hidden />
        </span>
      </div>
    </Link>
  );
}
