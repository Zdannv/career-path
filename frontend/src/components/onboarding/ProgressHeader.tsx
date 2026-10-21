"use client";

import React, { useEffect, useRef, useState } from "react";
import { ChevronDown } from "lucide-react";
import OnboardingIllustration, { type IllustrationKey } from "./OnboardingIllustration";
import { StepList, type StepMeta } from "./StepSidebar";

type ProgressHeaderProps = {
  step: number;
  steps: StepMeta[];
  illustration: IllustrationKey;
};

/**
 * Kartu progres di atas tiap langkah onboarding.
 *
 * Bar-nya memakai `aria-valuenow` dan bukan cuma lebar visual, supaya pembaca
 * layar ikut tahu posisi user — onboarding ini wajib dilewati semua orang.
 *
 * Di bawah `lg` panel langkah di kiri tidak ada, jadi label "STEP x/3" menjadi
 * tombol yang membuka daftar langkah yang sama dalam kartu tarik-turun.
 */
export default function ProgressHeader({ step, steps, illustration }: ProgressHeaderProps) {
  const totalSteps = steps.length;
  const pct = Math.round((step / totalSteps) * 100);
  // Menyimpan langkah saat daftar dibuka, bukan sekadar true/false: begitu
  // langkah berganti, daftarnya otomatis tertutup tanpa effect tambahan.
  const [openAt, setOpenAt] = useState<number | null>(null);
  const open = openAt === step;
  const setOpen = (v: boolean | ((cur: boolean) => boolean)) =>
    setOpenAt((cur) => ((typeof v === "function" ? v(cur === step) : v) ? step : null));
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpenAt(null);
    };
    const onEsc = (e: KeyboardEvent) => e.key === "Escape" && setOpenAt(null);
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onEsc);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onEsc);
    };
  }, [open]);

  return (
    <div
      ref={rootRef}
      className="relative rounded-xl bg-[#F8FAFC] px-4 py-4 sm:px-6 sm:py-5 lg:rounded-none lg:border-b lg:border-slate-100"
    >
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          aria-expanded={open}
          aria-label={`Langkah ${step} dari ${totalSteps}, lihat semua langkah`}
          className="inline-flex cursor-pointer items-center gap-1 rounded-full bg-[#7033FF] px-3 py-1 text-xs font-semibold text-white lg:pointer-events-none"
        >
          STEP {step}/{totalSteps}
          <ChevronDown className={`size-3.5 transition-transform lg:hidden ${open ? "rotate-180" : ""}`} />
        </button>
        <span className="text-sm font-bold text-slate-500 sm:text-base">{steps[step - 1].title}</span>
      </div>

      <div
        role="progressbar"
        aria-valuenow={step}
        aria-valuemin={1}
        aria-valuemax={totalSteps}
        aria-label={`Langkah ${step} dari ${totalSteps}`}
        className="mt-4 h-2 w-full overflow-hidden rounded-full bg-[#DBEAFE]"
      >
        <div
          className="h-full rounded-full bg-[#7033FF] transition-[width] duration-300 motion-reduce:transition-none"
          style={{ width: `${pct}%` }}
        />
      </div>

      {open && (
        <div className="absolute left-3 right-3 top-14 z-30 rounded-2xl bg-white p-4 shadow-xl ring-1 ring-slate-200 sm:right-auto sm:w-[320px] lg:hidden">
          <p className="text-sm font-bold text-slate-900">
            STEP ({step}/{totalSteps})
          </p>
          <StepList step={step} steps={steps} className="mt-4" />
          <OnboardingIllustration name={illustration} className="mt-4 h-auto w-full rounded-xl" />
        </div>
      )}
    </div>
  );
}
