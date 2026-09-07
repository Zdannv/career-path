"use client";

/**
 * Kolom kiri versi desktop: ilustrasi dan daftar keenam langkah.
 *
 * CATATAN ASET: mockup langkah memakai ilustrasi lain (anak merakit drone di
 * meja) yang tidak ada di folder assets raw. Sementara ini dipakai ilustrasi
 * Career DNA yang tersedia; ganti satu baris di bawah kalau berkasnya sudah
 * dikirim.
 */

import Image from "next/image";
import { Check } from "lucide-react";
import type { StepMeta } from "@/components/career-dna/StepHeaderBar";

type Props = {
  steps: StepMeta[];
  current: number;
  reached: number;
  onJump: (order: number) => void;
};

export default function DnaStepper({ steps, current, reached, onJump }: Props) {
  return (
    <aside className="hidden w-[300px] shrink-0 flex-col gap-6 lg:flex">
      <div className="overflow-hidden rounded-2xl bg-violet-50/60">
        <Image
          src="/career-dna/intro.png"
          alt=""
          width={267}
          height={340}
          className="h-auto w-full"
          aria-hidden
        />
      </div>

      <div>
        <p className="text-[13px] font-bold text-slate-900">
          STEP {current}/{steps.length}
        </p>
        <ol className="mt-4 flex flex-col">
          {steps.map((s, i) => {
            const selesai = s.order < reached;
            const kini = s.order === current;
            const bisa = s.order <= reached;
            return (
              <li key={s.order} className="flex gap-3">
                <span className="flex flex-col items-center">
                  <span
                    className={`grid size-6 shrink-0 place-items-center rounded-full text-[11px] font-bold ${
                      selesai
                        ? "bg-emerald-500 text-white"
                        : kini
                          ? "bg-violet-600 text-white"
                          : "text-slate-400"
                    }`}
                    aria-hidden
                  >
                    {selesai ? <Check className="size-3.5" strokeWidth={3} /> : s.order}
                  </span>
                  {i < steps.length - 1 && <span className="my-1 w-px flex-1 bg-slate-200" aria-hidden />}
                </span>
                <button
                  type="button"
                  disabled={!bisa}
                  onClick={() => onJump(s.order)}
                  aria-current={kini ? "step" : undefined}
                  className="flex-1 pb-6 text-left disabled:cursor-not-allowed"
                >
                  <span
                    className={`block text-[14px] font-semibold ${
                      bisa ? "text-violet-700" : "text-slate-400"
                    }`}
                  >
                    {s.name}
                  </span>
                  <span className="mt-0.5 block text-[12.5px] leading-snug text-slate-500">
                    {s.question}
                  </span>
                </button>
              </li>
            );
          })}
        </ol>
      </div>
    </aside>
  );
}
