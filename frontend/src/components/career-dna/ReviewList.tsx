"use client";

/**
 * Langkah 6 — Review.
 *
 * Satu kartu lipat per kategori. Yang dibuka menampilkan berapa banyak dipilih
 * dari batasnya, lalu nama-nama pilihannya. Tombol Edit melompat kembali ke
 * langkah kategori itu.
 */

import { useState } from "react";
import {
  Building2,
  Activity,
  ListChecks,
  Gauge,
  Building,
  Check,
  ChevronDown,
} from "lucide-react";
import type { DnaLayerStep } from "@/lib/careerDna";

const IKON: Record<string, typeof Building2> = {
  INTEREST: Building2,
  ACTIVITY: Activity,
  SKILL: ListChecks,
  WORKSTYLE: Gauge,
  ENVIRONMENT: Building,
};

type Props = {
  steps: DnaLayerStep[];
  picks: Record<string, string[]>;
  onEdit: (order: number) => void;
};

export default function ReviewList({ steps, picks, onEdit }: Props) {
  // Aktivitas dibuka lebih dulu, mengikuti mockup; satu kartu terbuka cukup
  // untuk menunjukkan bentuknya tanpa membuat layar sepanjang enam daftar.
  const [terbuka, setTerbuka] = useState<string | null>("ACTIVITY");

  return (
    <ul className="flex flex-col gap-3">
      {steps.map((s) => {
        const Ikon = IKON[s.layerCode] ?? Building2;
        const dipilih = picks[s.layerCode] ?? [];
        const nama = s.attributes.filter((a) => dipilih.includes(a.code));
        const buka = terbuka === s.layerCode;
        return (
          <li
            key={s.layerCode}
            className="overflow-hidden rounded-2xl border border-slate-200 bg-white"
          >
            <div className="flex items-center gap-3 px-4 py-3.5">
              <Ikon className="size-5 shrink-0 text-slate-700" aria-hidden />
              <div className="min-w-0 flex-1">
                <p className="text-[14px] font-bold text-slate-900">{s.name}</p>
                <p className="mt-0.5 text-[12.5px] text-slate-500">{s.question}</p>
              </div>
              {buka && (
                <button
                  type="button"
                  onClick={() => onEdit(s.order)}
                  className="shrink-0 rounded-full bg-slate-100 px-3 py-1.5 text-[12px] font-semibold text-slate-700 transition-colors hover:bg-slate-200"
                >
                  Edit
                </button>
              )}
              <button
                type="button"
                onClick={() => setTerbuka(buka ? null : s.layerCode)}
                aria-expanded={buka}
                aria-label={`${buka ? "Tutup" : "Buka"} ${s.name}`}
                className="grid size-7 shrink-0 place-items-center rounded-full text-slate-500 transition-colors hover:bg-slate-100"
              >
                <ChevronDown className={`size-4 transition-transform ${buka ? "rotate-180" : ""}`} aria-hidden />
              </button>
            </div>

            {buka && (
              <div className="border-t border-slate-100 bg-slate-50/70 px-4 py-4">
                <p className="text-[13px] text-slate-700">
                  Kamu memilih {nama.length} dari batas maksimal {s.maxPick} pilihan yang diberikan.
                </p>
                {nama.length === 0 ? (
                  <p className="mt-3 text-[13px] text-amber-700">
                    Belum ada pilihan di kategori ini. Tekan Edit untuk mengisinya.
                  </p>
                ) : (
                  <ul className="mt-3 flex flex-col gap-2">
                    {nama.map((a) => (
                      <li key={a.code} className="flex items-center gap-2.5">
                        <Check className="size-4 shrink-0 text-slate-400" aria-hidden />
                        <span className="text-[13.5px] text-slate-900">{a.name}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
