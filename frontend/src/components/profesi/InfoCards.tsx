"use client";

/**
 * Kartu-kartu ringkas di tab Analisa: permintaan pasar, sub-industri, dan
 * estimasi pencapaian.
 */

import { Building2, TrendingUp, Timer } from "lucide-react";
import type { SubIndustri } from "@/lib/careerDetail";

export function KartuDemand({
  growth,
  label,
}: {
  growth: number | null;
  label: string;
}) {
  const tinggi = label === "Demand tinggi";
  return (
    <section className="flex items-center justify-between gap-3 rounded-2xl bg-violet-50 px-4 py-3.5">
      <div className="min-w-0">
        <h3 className="text-[14.5px] font-semibold text-slate-900">Market Demand</h3>
        <p className="mt-0.5 text-[11.5px] leading-snug text-slate-500">
          Permintaan pasar dalam 2 tahun terakhir
        </p>
      </div>
      <div className="shrink-0 text-right">
        <p className="text-[19px] font-bold leading-none text-slate-900">
          {growth == null ? "—" : `+${Number(growth).toFixed(0)}%`}
          <span className="ml-1 align-baseline text-[11.5px] font-normal text-slate-500">
            (tahun)
          </span>
        </p>
        <span
          className={`mt-1.5 inline-flex items-center gap-1 rounded-md px-2 py-1 text-[11px] font-medium ${
            tinggi ? "bg-emerald-100 text-emerald-800" : "bg-slate-200 text-slate-700"
          }`}
        >
          <TrendingUp className="size-3" aria-hidden />
          {label}
        </span>
      </div>
    </section>
  );
}

export function DaftarSubIndustri({ isi }: { isi: SubIndustri[] }) {
  if (isi.length === 0) return null;
  return (
    <section>
      <h3 className="text-[14.5px] font-semibold text-slate-900">
        Sub-Industri yang membutuhkan
      </h3>
      <ul className="mt-2.5 flex flex-wrap gap-2">
        {isi.map((s) => (
          <li
            key={s.code}
            className="inline-flex items-center gap-1.5 rounded-md bg-indigo-50 px-2.5 py-1.5 text-[12px] font-medium text-indigo-700"
          >
            <Building2 className="size-3.5 shrink-0" aria-hidden />
            {s.nama}
          </li>
        ))}
      </ul>
    </section>
  );
}

/** 84 bulan → "7 tahun", 90 → "7-8 tahun". Sengaja kasar; ini estimasi. */
export function durasiTahun(bulan: number | null): string {
  if (!bulan || bulan <= 0) return "Belum dihitung";
  if (bulan < 12) return `${bulan} bulan`;
  const y = bulan / 12;
  if (Number.isInteger(y)) return `${y} tahun`;
  return `${Math.floor(y)}-${Math.ceil(y)} tahun`;
}

export function KartuEstimasi({
  bulan,
  posisi,
  persen,
}: {
  bulan: number | null;
  posisi: string | null;
  persen: number | null;
}) {
  const p = Math.max(0, Math.min(100, Math.round(Number(persen ?? 0))));
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200">
      <div className="flex items-center justify-between gap-3 px-4 py-3.5">
        <div>
          <p className="text-[12.5px] text-slate-500">Estimasi Pencapaian Profesi</p>
          <p className="mt-0.5 text-[17px] font-bold text-slate-900">{durasiTahun(bulan)}</p>
        </div>
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-violet-100 text-violet-700">
          <Timer className="size-5" aria-hidden />
        </span>
      </div>

      <div className="border-t border-slate-200 bg-slate-50 px-4 py-3.5">
        <p className="text-[12.5px] text-slate-500">Posisi Kamu saat ini</p>
        <div className="mt-1 flex items-baseline justify-between gap-3">
          <p className="text-[15px] font-semibold text-slate-900">
            {posisi ?? "Belum diisi di profil"}
          </p>
          <p className="text-[14px] font-bold text-violet-700">{p}%</p>
        </div>
        <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-slate-200">
          <div className="h-full rounded-full bg-violet-600" style={{ width: `${p}%` }} />
        </div>
        <p className="mt-2 text-[11px] leading-snug text-slate-500">
          Perubahan estimasi pencapaian ditentukan oleh penyelesaian quest dan pencapaian skill
          gap
        </p>
      </div>
    </section>
  );
}
