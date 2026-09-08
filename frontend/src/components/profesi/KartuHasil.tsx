"use client";

/**
 * Kartu profesi bentuk daftar — satu per baris, bukan kartu geser.
 *
 * Dipakai di tiga tempat: daftar "Profesi di kategori ini", hasil pencarian,
 * dan hasil berfilter. Bedanya dengan CareerCard di Explore adalah arah
 * tumbuhnya: yang ini melebar penuh dan menaruh angka di satu baris kaki,
 * karena daftar vertikal dibaca dengan memindai ke bawah.
 */

import Link from "next/link";
import { BarChart3, Building2, ChevronRight, CircleDollarSign, PieChart } from "lucide-react";
import { gajiKartu, type KartuProfesi } from "@/lib/careerDetail";

export default function KartuHasil({
  kartu,
  chips = false,
}: {
  kartu: KartuProfesi;
  /** Menampilkan chip atribut keahlian di bawah — dipakai di hasil pencarian. */
  chips?: boolean;
}) {
  const skor = kartu.match_score == null ? null : Math.round(Number(kartu.match_score));
  return (
    <li>
      <Link
        href={`/explore/${kartu.career_id}`}
        className="flex flex-col gap-2.5 rounded-2xl border border-slate-200 bg-white px-4 py-3.5 transition-colors hover:border-slate-300"
      >
        <div className="flex items-center justify-between gap-2">
          <span className="inline-flex min-w-0 items-center gap-1.5 rounded-md bg-indigo-50 px-2 py-1 text-[11.5px] font-medium text-indigo-700">
            <Building2 className="size-3 shrink-0" aria-hidden />
            <span className="truncate">{kartu.sub_industry ?? "Belum dikelompokkan"}</span>
          </span>
          {kartu.sub_industry_extra > 0 && (
            <span className="shrink-0 rounded-md bg-slate-100 px-1.5 py-1 text-[11px] font-medium text-slate-500">
              +{kartu.sub_industry_extra}
            </span>
          )}
          <span className="ml-auto inline-flex shrink-0 items-center gap-0.5 text-[12px] font-medium text-slate-600">
            Lihat Profesi
            <ChevronRight className="size-3.5" aria-hidden />
          </span>
        </div>

        <h3 className="text-[15px] font-semibold leading-snug text-slate-900">
          {kartu.career_name}
        </h3>
        {kartu.career_description && (
          <p className="line-clamp-2 text-[12.5px] leading-relaxed text-slate-500">
            {kartu.career_description}
          </p>
        )}

        {chips && (kartu.skill_chips?.length ?? 0) > 0 && (
          <ul className="flex flex-wrap gap-1.5">
            {kartu.skill_chips!.map((c) => (
              <li
                key={c}
                className="rounded-md bg-cyan-50 px-2 py-1 text-[11px] font-medium text-cyan-800"
              >
                {c}
              </li>
            ))}
          </ul>
        )}

        <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[12px] text-slate-500">
          <span className="inline-flex items-center gap-1.5">
            <BarChart3 className="size-3.5 text-slate-400" aria-hidden />
            {kartu.demand_label}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <CircleDollarSign className="size-3.5 text-slate-400" aria-hidden />
            {gajiKartu(kartu.salary_min, kartu.salary_max)}
          </span>
          {skor != null && (
            <span className="ml-auto inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2.5 py-1 text-[11.5px] font-semibold text-emerald-800">
              <PieChart className="size-3" aria-hidden />
              {skor}%
            </span>
          )}
        </div>
      </Link>
    </li>
  );
}
