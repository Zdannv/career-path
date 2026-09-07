"use client";

/**
 * Dialog "Simpan Progress" — muncul saat pengguna menekan Simpan di kepala
 * layar.
 *
 * Progresnya sebenarnya sudah tersimpan setiap kali berpindah langkah, jadi
 * dialog ini sebetulnya konfirmasi keluar, bukan penyimpan. Kalimatnya
 * mengikuti desain apa adanya supaya tidak menjanjikan hal lain.
 */

import Image from "next/image";
import { X } from "lucide-react";

type Props = {
  onCancel: () => void;
  onConfirm: () => void;
  menyimpan?: boolean;
};

export default function SaveProgressDialog({ onCancel, onConfirm, menyimpan = false }: Props) {
  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center bg-slate-900/40 px-5"
      role="dialog"
      aria-modal="true"
      aria-labelledby="judul-simpan-progress"
    >
      <div className="w-full max-w-[340px] overflow-hidden rounded-2xl bg-white">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-3.5">
          <h2 id="judul-simpan-progress" className="text-[14px] font-bold text-slate-900">
            Simpan Progress
          </h2>
          <button
            type="button"
            onClick={onCancel}
            aria-label="Tutup"
            className="grid size-7 place-items-center rounded-full text-slate-400 transition-colors hover:bg-slate-100"
          >
            <X className="size-4" aria-hidden />
          </button>
        </div>

        <div className="flex flex-col items-center gap-1 px-6 py-5 text-center">
          <Image
            src="/career-dna/save-progress.png"
            alt=""
            width={292}
            height={121}
            className="h-auto w-[170px]"
            aria-hidden
          />
          <p className="mt-2 text-[13.5px] font-bold text-slate-900">Keluar sekarang dan isi nanti?</p>
          <p className="text-[12.5px] leading-relaxed text-slate-500">
            Progres Kamu akan otomatis tersimpan, kamu dapat melanjutkannya di lain waktu.
          </p>
        </div>

        <div className="flex gap-3 px-5 pb-5">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-full border border-slate-200 py-2.5 text-[13px] font-semibold text-slate-700 transition-colors hover:bg-slate-50"
          >
            Batalkan
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={menyimpan}
            className="flex-1 rounded-full bg-violet-600 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700 disabled:opacity-60"
          >
            {menyimpan ? "Menyimpan…" : "Simpan"}
          </button>
        </div>
      </div>
    </div>
  );
}
