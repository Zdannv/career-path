"use client";

/**
 * Kartu perjalanan — profesi yang sedang dituju pengguna.
 *
 * Ilustrasinya hero tahap Journey yang sedang berjalan, gambar yang sama
 * dengan yang muncul saat "Lanjutkan journey" ditekan. Gambarnya ditaruh di
 * kanan dan dipudarkan ke ungu di kiri supaya teks putihnya tetap terbaca;
 * bg-cover dari kanan, jadi satu berkas cukup untuk ponsel dan desktop.
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { heroTahap } from "@/lib/roadmapJourney";
import { ROUTES } from "@/lib/routes";

type Props = {
  careerName: string;
  percent: number;
  /** Kode tahap Journey yang sedang berjalan. NULL = tahap pertama. */
  tahap: string | null;
};

export default function JourneyCard({ careerName, percent, tahap }: Props) {
  const href = tahap ? `${ROUTES.journey}?tahap=${encodeURIComponent(tahap)}` : ROUTES.journey;
  return (
    <div className="relative overflow-hidden rounded-2xl bg-[#4B21B5]">
      <div
        className="absolute inset-y-0 right-0 w-[78%] bg-cover bg-right bg-no-repeat"
        style={{ backgroundImage: `url('${heroTahap(tahap ?? "EKSPLORASI")}')` }}
        aria-hidden
      />
      {/* Nama profesi bisa panjang dan ilustrasinya terang di bagian tengah,
          jadi sisi kiri diberi gradien supaya teksnya tetap terbaca. */}
      <div
        className="absolute inset-0 bg-gradient-to-r from-[#4B21B5] from-35% via-[#4B21B5]/80 via-60% to-[#4B21B5]/10"
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
