"use client";

/** Layar pembuka Career DNA. */

import Image from "next/image";
import { ArrowRight, Timer } from "lucide-react";

export default function IntroScreen({
  onStart,
  lanjutkan,
}: {
  onStart: () => void;
  /** True kalau sudah ada progres tersimpan — tombolnya berganti kalimat. */
  lanjutkan: boolean;
}) {
  return (
    <div className="mx-auto w-full max-w-[486px] px-4 py-8 sm:px-0">
      <div className="rounded-2xl bg-slate-50/80 p-6 text-center">
        <Image
          src="/career-dna/intro.png"
          alt=""
          width={267}
          height={340}
          priority
          className="mx-auto h-auto w-[218px]"
          aria-hidden
        />
        <h1 className="mt-4 text-[17px] font-bold tracking-tight text-slate-900">
          Kenali Career DNA-mu
        </h1>
        <p className="mx-auto mt-1 max-w-[380px] text-[13.5px] leading-relaxed text-slate-600">
          Temukan profesi yang sesuai dengan minat, aktivitas, keahlian, dan cara kerjamu.
        </p>
      </div>

      <div className="mt-4 flex items-center gap-3 rounded-xl bg-slate-100/80 px-4 py-3">
        <span className="grid size-9 shrink-0 place-items-center rounded-full bg-violet-100 text-violet-600">
          <Timer className="size-4" aria-hidden />
        </span>
        <span>
          <span className="block text-[12.5px] font-bold text-slate-900">Estimasi penyelesaian</span>
          <span className="block text-[12.5px] text-slate-600">~2 menit</span>
        </span>
      </div>

      <button
        type="button"
        onClick={onStart}
        className="mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-violet-600 py-3.5 text-[14px] font-semibold text-white transition-colors hover:bg-violet-700"
      >
        {lanjutkan ? "Lanjutkan progress-mu" : "Ayo Mulai!"}
        <ArrowRight className="size-4" aria-hidden />
      </button>
    </div>
  );
}
