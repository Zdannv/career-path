"use client";

import React from "react";

type ProgressHeaderProps = {
  step: number;
  totalSteps: number;
  title: string;
};

/**
 * Kartu progres di atas tiap langkah onboarding.
 *
 * Bar-nya memakai `aria-valuenow` dan bukan cuma lebar visual, supaya pembaca
 * layar ikut tahu posisi user — onboarding ini wajib dilewati semua orang.
 */
export default function ProgressHeader({ step, totalSteps, title }: ProgressHeaderProps) {
  const pct = Math.round((step / totalSteps) * 100);

  return (
    <div className="rounded-xl bg-[#F8FAFC] px-4 py-4 sm:px-6 sm:py-5 lg:rounded-none lg:border-b lg:border-slate-100">
      <div className="flex items-center gap-3">
        <span className="inline-flex items-center rounded-full bg-[#7033FF] px-3 py-1 text-xs font-semibold text-white">
          STEP {step}/{totalSteps}
        </span>
        <span className="text-sm font-bold text-slate-500 sm:text-base">{title}</span>
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
    </div>
  );
}
