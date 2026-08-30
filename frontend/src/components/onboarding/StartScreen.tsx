"use client";

import React from "react";
import { ArrowRight, Timer } from "lucide-react";
import OnboardingIllustration from "./OnboardingIllustration";

/**
 * Layar pembuka (A-01).
 *
 * Kartunya lebih sempit daripada langkah 1-3 dan tidak punya panel samping —
 * di sini belum ada progres untuk ditampilkan, jadi satu kolom terpusat.
 */
export default function StartScreen({ onStart }: { onStart: () => void }) {
  return (
    <div className="mx-auto w-full max-w-[600px] px-4 pb-8 sm:px-6 lg:px-0">
      <div className="lg:rounded-2xl lg:bg-white lg:p-8 lg:shadow-sm">
        {/* Ilustrasi pembuka satu-satunya yang potret. Lebarnya ~54% dari lebar
            isi kartu, mengikuti proporsi di mockup A-01; kalau dibuat selebar
            kartu tingginya jadi ~700px dan tombolnya terdorong keluar layar. */}
        <OnboardingIllustration
          name="start"
          className="mx-auto h-auto w-full max-w-[300px] rounded-2xl"
          priority
        />

        <h1 className="mt-7 text-xl font-medium text-slate-900 sm:text-2xl">
          Selamat datang di <span className="font-bold">Navika</span>
        </h1>
        <p className="mt-2 text-sm leading-relaxed text-[#525252] sm:text-base">
          Sebelum kita mulai petualangan kariermu, yuk share dulu latar belakang dan status
          pendidikan Kamu!
        </p>

        <div className="mt-6 flex items-center gap-3 rounded-xl bg-[#F8FAFC] px-4 py-3.5">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white ring-1 ring-slate-200">
            <Timer className="h-4 w-4 text-slate-600" />
          </span>
          <span className="min-w-0">
            <span className="block text-sm font-bold text-slate-900">Estimasi penyelesaian</span>
            <span className="block text-sm text-[#525252]">~2 menit</span>
          </span>
        </div>

        <button
          type="button"
          onClick={onStart}
          className="mt-6 flex w-full cursor-pointer items-center justify-center gap-2 rounded-full bg-[#7033FF] px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-[#5f27e6] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7033FF]"
        >
          Ayo Mulai!
          <ArrowRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}
