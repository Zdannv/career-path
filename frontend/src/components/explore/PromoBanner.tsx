"use client";

/**
 * Banner promosi (Career Discovery, Career DNA, Career Insights).
 *
 * Ketiganya diekspor tim desain sebagai satu gambar utuh — teks dan tombolnya
 * ikut tergambar di dalamnya. Jadi yang dilakukan di sini hanya menjadikan
 * seluruh banner satu tautan, dengan teks alternatif yang menyebutkan isinya
 * supaya pembaca layar tidak kehilangan apa pun.
 */

import Image from "next/image";
import Link from "next/link";

export const BANNERS = {
  discovery: {
    src: "/explore/career-discovery.png",
    width: 341,
    height: 202,
    alt: "Career Discovery — masih bingung mau jadi apa? Mulai Career Discovery untuk rekomendasi profesi yang paling sesuai minat dan keahlianmu.",
  },
  dna: {
    src: "/explore/career-dna.png",
    width: 341,
    height: 180,
    alt: "Career DNA — selangkah lagi. Lengkapi data minat dan keahlian untuk menyusun rencana belajar yang paling pas.",
  },
  insights: {
    src: "/explore/career-insights.png",
    width: 341,
    height: 206,
    alt: "Career Insights — cari tahu prediksi karier menjanjikan 10 tahun ke depan yang minim tergeser oleh teknologi dan AI.",
  },
} as const;

type Props = {
  variant: keyof typeof BANNERS;
  href: string;
  className?: string;
  priority?: boolean;
};

export default function PromoBanner({ variant, href, className = "", priority = false }: Props) {
  const b = BANNERS[variant];
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
