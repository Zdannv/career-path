"use client";

/**
 * Kartu perjalanan — profesi yang sedang dituju pengguna.
 *
 * Latar ungunya dua berkas berbeda karena ilustrasinya ada di sisi kanan:
 * versi ponsel (341×154) memotong terlalu banyak kalau diregangkan selebar
 * desktop, jadi di atas sm dipakai versi lebar (734×154).
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";

type Props = {
  careerName: string;
  percent: number;
  href: string;
};

export default function JourneyCard({ careerName, percent, href }: Props) {
  return (
    <div className="relative overflow-hidden rounded-2xl bg-[#4B21B5]">
      <div
        className="absolute inset-0 bg-cover bg-right bg-no-repeat sm:hidden"
        style={{ backgroundImage: "url('/explore/journey-card.png')" }}
        aria-hidden
      />
      <div
        className="absolute inset-0 hidden bg-cover bg-right bg-no-repeat sm:block"
        style={{ backgroundImage: "url('/explore/journey-card-wide.png')" }}
        aria-hidden
      />
      {/* Nama profesi bisa panjang dan ilustrasinya terang di bagian tengah,
          jadi sisi kiri diberi gradien supaya teksnya tetap terbaca. */}
      <div
        className="absolute inset-0 bg-gradient-to-r from-[#4B21B5] via-[#4B21B5]/85 to-transparent"
        aria-hidden
      />

      <div className="relative flex flex-col gap-2 p-5">
        <p className="text-[12px] font-semibold text-white/80">Level 1 ({percent}%)</p>
        <h2 className="max-w-[70%] text-[20px] font-bold leading-tight tracking-tight text-white">
          {careerName}
        </h2>
        <p className="max-w-[62%] text-[12.5px] leading-relaxed text-white/80">
          Lihat roadmap dan tingkatkan skill-mu untuk mencapai level selanjutnya
        </p>
        <Link
          href={href}
          className="mt-2 inline-flex w-fit items-center gap-2 rounded-full bg-[#2B1170] px-4 py-2 text-[12.5px] font-semibold text-white transition-colors hover:bg-[#1F0B55]"
        >
          Lanjutkan journey
          <ArrowRight className="size-3.5" aria-hidden />
        </Link>
      </div>
    </div>
  );
}
