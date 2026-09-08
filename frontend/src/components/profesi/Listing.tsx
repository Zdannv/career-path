"use client";

/**
 * Daftar berpembatas yang dipakai tab Skill & Kompetensi.
 *
 * Semua blok di tab itu punya bentuk yang sama: judul, sub-judul abu-abu,
 * beberapa baris, lalu tautan "Lihat Semua (+N)". Ditulis sekali di sini —
 * empat blok yang masing-masing menulis ulang pembatas dan jaraknya adalah
 * cara tercepat membuat tab ini terlihat tidak rapi.
 */

import { ArrowRight } from "lucide-react";

export function Blok({
  judul,
  keterangan,
  subjudul,
  children,
}: {
  judul: string;
  /** Teks abu-abu dalam kurung di sebelah judul, mis. "(Ketrampilan teknis)". */
  keterangan?: string;
  /** Baris penjelas di bawah judul. */
  subjudul?: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <h3 className="text-[15px] font-semibold text-slate-900">
        {judul}
        {keterangan && <span className="ml-1.5 font-normal text-slate-400">{keterangan}</span>}
      </h3>
      {subjudul && <p className="mt-0.5 text-[12.5px] text-slate-500">{subjudul}</p>}
      <div className="mt-3">{children}</div>
    </section>
  );
}

export function BarisIsi({
  utama,
  penjelas,
  kanan,
}: {
  utama: string;
  penjelas?: string | null;
  kanan?: React.ReactNode;
}) {
  return (
    <li className="border-b border-slate-200 py-3 last:border-b-0">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[13.5px] font-semibold leading-snug text-slate-900">{utama}</p>
          {penjelas && (
            <p className="mt-1 text-[12.5px] leading-relaxed text-slate-400">{penjelas}</p>
          )}
        </div>
        {kanan}
      </div>
    </li>
  );
}

export function BarisDuaKolom({ kiri, kanan }: { kiri: string; kanan: string }) {
  return (
    <li className="grid grid-cols-[108px_1fr] gap-3 border-b border-slate-200 py-3 last:border-b-0">
      <span className="text-[13.5px] font-semibold text-slate-900">{kiri}</span>
      <span className="text-[13px] leading-relaxed text-slate-600">{kanan}</span>
    </li>
  );
}

export function LihatSemua({
  label,
  sisa,
  onClick,
}: {
  label: string;
  sisa: number;
  onClick: () => void;
}) {
  if (sisa <= 0) return null;
  return (
    <button
      type="button"
      onClick={onClick}
      className="mt-3 inline-flex items-center gap-1.5 text-[13px] font-semibold text-violet-700 transition-colors hover:text-violet-800"
    >
      {label} (+{sisa})
      <ArrowRight className="size-3.5" aria-hidden />
    </button>
  );
}
