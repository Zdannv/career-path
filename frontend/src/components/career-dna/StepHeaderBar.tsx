"use client";

/**
 * Kepala kartu langkah: chip "STEP n/6" yang bisa dibuka, nama kategori, dan
 * bilah progres.
 *
 * Chip-nya membuka daftar keenam langkah — langkah yang sudah lewat bertanda
 * centang, langkah aktif berwarna, sisanya bernomor. Hanya langkah yang sudah
 * pernah dicapai boleh diklik: melompat ke langkah 5 sebelum mengisi langkah 2
 * hanya menghasilkan Review yang bolong.
 */

import { useEffect, useRef, useState } from "react";
import { Check, ChevronDown } from "lucide-react";

export type StepMeta = { order: number; name: string; question: string };

type Props = {
  steps: StepMeta[];
  current: number;
  /** Langkah tertinggi yang sudah dicapai; di atas ini tidak bisa dilompati. */
  reached: number;
  onJump: (order: number) => void;
};

export default function StepHeaderBar({ steps, current, reached, onJump }: Props) {
  const [buka, setBuka] = useState(false);
  const wrap = useRef<HTMLDivElement>(null);
  const aktif = steps.find((s) => s.order === current);

  useEffect(() => {
    function keluar(e: MouseEvent) {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setBuka(false);
    }
    document.addEventListener("mousedown", keluar);
    return () => document.removeEventListener("mousedown", keluar);
  }, []);

  return (
    <div className="border-b border-slate-200 bg-slate-50/80 px-4 pb-4 pt-3.5 sm:px-6">
      <div ref={wrap} className="relative flex items-center gap-3">
        <button
          type="button"
          onClick={() => setBuka((v) => !v)}
          aria-expanded={buka}
          className="inline-flex shrink-0 items-center gap-1 rounded-md bg-violet-600 px-2 py-1 text-[11px] font-bold text-white"
        >
          STEP {current}/{steps.length}
          <ChevronDown className={`size-3 transition-transform ${buka ? "rotate-180" : ""}`} aria-hidden />
        </button>
        <p className="truncate text-[14px] font-bold text-slate-900">{aktif?.name}</p>

        {buka && (
          <div className="absolute left-0 top-[calc(100%+10px)] z-30 w-[300px] rounded-2xl border border-slate-200 bg-white p-4 shadow-lg">
            <p className="text-[12px] font-bold text-slate-900">
              STEP ({current}/{steps.length})
            </p>
            <ol className="mt-3 flex flex-col">
              {steps.map((s, i) => {
                const selesai = s.order < reached;
                const kini = s.order === current;
                const bisa = s.order <= reached;
                return (
                  <li key={s.order} className="flex gap-3">
                    <span className="flex flex-col items-center">
                      <span
                        className={`grid size-5 shrink-0 place-items-center rounded-full text-[10px] font-bold ${
                          selesai
                            ? "bg-emerald-500 text-white"
                            : kini
                              ? "bg-violet-600 text-white"
                              : "text-slate-400"
                        }`}
                        aria-hidden
                      >
                        {selesai ? <Check className="size-3" strokeWidth={3} /> : s.order}
                      </span>
                      {i < steps.length - 1 && <span className="my-1 w-px flex-1 bg-slate-200" aria-hidden />}
                    </span>
                    <button
                      type="button"
                      disabled={!bisa}
                      onClick={() => {
                        setBuka(false);
                        onJump(s.order);
                      }}
                      className="flex-1 pb-4 text-left disabled:cursor-not-allowed"
                    >
                      <span
                        className={`block text-[13px] font-semibold ${
                          bisa ? "text-violet-700" : "text-slate-400"
                        }`}
                      >
                        {s.name}
                      </span>
                      <span className="mt-0.5 block text-[12px] leading-snug text-slate-500">
                        {s.question}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ol>
          </div>
        )}
      </div>

      <div
        className="mt-3 h-2 w-full overflow-hidden rounded-full bg-violet-100"
        role="progressbar"
        aria-valuenow={current}
        aria-valuemin={1}
        aria-valuemax={steps.length}
        aria-label={`Langkah ${current} dari ${steps.length}`}
      >
        <div
          className="h-full rounded-full bg-violet-600 transition-[width] duration-300"
          style={{ width: `${(current / steps.length) * 100}%` }}
        />
      </div>
    </div>
  );
}
