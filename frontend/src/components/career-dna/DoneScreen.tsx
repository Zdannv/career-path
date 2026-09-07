"use client";

/** Layar penutup setelah Career DNA tersimpan. */

import Image from "next/image";
import Link from "next/link";
import { ArrowRight, Compass } from "lucide-react";

export default function DoneScreen() {
  return (
    <div className="mx-auto w-full max-w-[860px] px-4 py-10 sm:px-6">
      <div className="rounded-2xl bg-slate-50/70 px-6 py-10 text-center">
        <Image
          src="/career-dna/done.png"
          alt=""
          width={320}
          height={320}
          priority
          className="mx-auto h-auto w-[240px]"
          aria-hidden
        />
        <h1 className="mt-4 text-[17px] font-bold tracking-tight text-slate-900">
          Yay! Data kamu tersimpan 🎉
        </h1>
        <p className="mx-auto mt-2 max-w-[460px] text-[13.5px] leading-relaxed text-slate-600">
          Terima kasih! informasi yang Kamu berikan akan membantu Navika dalam membuat roadmap
          journey profesi impian Kamu.
        </p>

        <div className="mx-auto mt-6 max-w-[520px] border-t border-slate-200 pt-6">
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-center">
            <Link
              href="/explore"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-slate-100 px-5 py-3 text-[13.5px] font-semibold text-slate-700 transition-colors hover:bg-slate-200"
            >
              <Compass className="size-4" aria-hidden />
              Kembali ke Explore
            </Link>
            <Link
              href="/explore/daftar/match"
              className="inline-flex items-center justify-center gap-2 rounded-full bg-violet-600 px-5 py-3 text-[13.5px] font-semibold text-white transition-colors hover:bg-violet-700"
            >
              Tampilkan Rekomendasi Profesi
              <ArrowRight className="size-4" aria-hidden />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
