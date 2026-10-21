"use client";

import React from "react";
import { ArrowRight, Check, Loader2, Undo2 } from "lucide-react";

type StepFooterProps = {
  primaryLabel: string;
  onPrimary: () => void;
  primaryDisabled?: boolean;
  primaryBusy?: boolean;
  /** Ikon di tombol utama: panah untuk lanjut, centang untuk simpan. */
  primaryIcon?: "arrow" | "check";
  secondaryLabel?: string;
  onSecondary?: () => void;
};

/**
 * Footer aksi.
 *
 * Di layar kecil dia menempel di bawah viewport supaya tombol lanjut selalu
 * terjangkau tanpa menggulir daftar chip yang panjang. Dari `sm` ke atas dia
 * kembali mengalir mengikuti konten, karena di layar itu seluruh langkah sudah
 * muat sekaligus dan footer melayang justru memakan ruang.
 */
export default function StepFooter({
  primaryLabel,
  onPrimary,
  primaryDisabled = false,
  primaryBusy = false,
  primaryIcon = "arrow",
  secondaryLabel,
  onSecondary,
}: StepFooterProps) {
  const Icon = primaryIcon === "check" ? Check : ArrowRight;

  return (
    // Tombol kembali kecil di kiri, tombol lanjut mengisi sisanya, di semua
    // ukuran layar. Tanpa label, tombol kembali hanya berupa ikon.
    <div className="sticky bottom-0 z-10 -mx-4 mt-8 flex items-center gap-3 bg-[#F1EBFF] px-4 py-4 sm:static sm:mx-0 sm:rounded-xl sm:px-6 lg:mt-0 lg:rounded-none lg:px-6 lg:py-5">
      {onSecondary && (
        <button
          type="button"
          onClick={onSecondary}
          aria-label={secondaryLabel ?? "Kembali"}
          className={`flex shrink-0 cursor-pointer items-center justify-center gap-2 rounded-full bg-white text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-slate-200 transition-colors hover:bg-slate-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7033FF] ${
            secondaryLabel ? "px-5 py-3.5" : "size-11"
          }`}
        >
          <Undo2 className="h-4 w-4" />
          {secondaryLabel}
        </button>
      )}

      <button
        type="button"
        onClick={onPrimary}
        disabled={primaryDisabled || primaryBusy}
        className={[
          "flex flex-1 items-center justify-center gap-2 rounded-full px-6 py-3.5",
          "text-sm font-semibold text-white transition-colors",
          "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7033FF]",
          primaryDisabled || primaryBusy
            ? "cursor-not-allowed bg-[#B698FE]"
            : "cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6]",
        ].join(" ")}
      >
        {primaryBusy ? (
          <Loader2 className="h-4 w-4 animate-spin motion-reduce:animate-none" />
        ) : null}
        {primaryLabel}
        {!primaryBusy && <Icon className="h-4 w-4" />}
      </button>
    </div>
  );
}
