"use client";

/**
 * Tombol utama yang menempel di bawah.
 *
 * Latarnya diberi warna, bukan transparan: isi layar detail panjang dan sering
 * berakhir dengan kartu putih, jadi tombol tanpa alas akan terlihat mengambang
 * di atas teks yang lewat di belakangnya.
 */

import { ArrowRight, Loader2 } from "lucide-react";

export default function StickyCta({
  label,
  onClick,
  sedang = false,
  nonaktif = false,
}: {
  label: string;
  onClick?: () => void;
  sedang?: boolean;
  nonaktif?: boolean;
}) {
  return (
    <div
      className="sticky bottom-0 z-20 border-t border-violet-100 bg-[#EDEBFA] px-4 py-3 sm:px-6 lg:bottom-0"
      style={{ paddingBottom: "max(0.75rem, env(safe-area-inset-bottom))" }}
    >
      <div className="mx-auto max-w-3xl">
        <button
          type="button"
          onClick={onClick}
          disabled={sedang || nonaktif}
          className="flex w-full items-center justify-center gap-2 rounded-full bg-violet-600 px-6 py-3.5 text-[15px] font-semibold text-white transition-colors hover:bg-violet-700 disabled:cursor-not-allowed disabled:bg-violet-300"
        >
          {sedang && <Loader2 className="size-4 animate-spin" aria-hidden />}
          {label}
          {!sedang && <ArrowRight className="size-4" aria-hidden />}
        </button>
      </div>
    </div>
  );
}
