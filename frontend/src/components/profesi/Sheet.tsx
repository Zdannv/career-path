"use client";

/**
 * Lembar yang naik dari bawah.
 *
 * Dua ragam: `penuh` untuk Skill Gap Analysis dan Filters yang memenuhi layar,
 * dan bentuk pendek untuk penjelasan singkat. Keduanya memakai satu komponen
 * supaya perilaku menutup — tombol silang, klik latar, tombol Esc — sama di
 * semua tempat.
 */

import { useEffect } from "react";
import { X } from "lucide-react";

export default function Sheet({
  buka,
  onTutup,
  judul,
  penuh = false,
  footer,
  children,
}: {
  buka: boolean;
  onTutup: () => void;
  judul: string;
  penuh?: boolean;
  footer?: React.ReactNode;
  children: React.ReactNode;
}) {
  useEffect(() => {
    if (!buka) return;
    const onEsc = (e: KeyboardEvent) => {
      if (e.key === "Escape") onTutup();
    };
    document.addEventListener("keydown", onEsc);
    const semula = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onEsc);
      document.body.style.overflow = semula;
    };
  }, [buka, onTutup]);

  if (!buka) return null;

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end" role="dialog" aria-modal="true"
         aria-label={judul}>
      <button
        type="button"
        aria-label="Tutup"
        onClick={onTutup}
        className="absolute inset-0 bg-slate-900/60"
      />
      <div
        className={`relative mx-auto flex w-full max-w-3xl flex-col overflow-hidden bg-white ${
          penuh ? "h-[100dvh] rounded-none sm:h-[92dvh] sm:rounded-t-2xl" : "max-h-[85dvh] rounded-t-2xl"
        }`}
      >
        <div className="flex items-center gap-3 border-b border-slate-200 px-4 py-3.5 sm:px-6">
          {penuh ? (
            <>
              <button
                type="button"
                onClick={onTutup}
                aria-label="Tutup"
                className="-ml-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
              >
                <X className="size-5" aria-hidden />
              </button>
              <h2 className="text-[15px] font-semibold text-slate-900">{judul}</h2>
            </>
          ) : (
            <>
              <h2 className="flex-1 text-[15px] font-semibold text-slate-900">{judul}</h2>
              <button
                type="button"
                onClick={onTutup}
                aria-label="Tutup"
                className="-mr-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
              >
                <X className="size-5" aria-hidden />
              </button>
            </>
          )}
        </div>

        <div className="flex-1 overflow-y-auto overscroll-contain">{children}</div>
        {footer}
      </div>
    </div>
  );
}
