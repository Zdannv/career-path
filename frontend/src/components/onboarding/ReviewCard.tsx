import React from "react";
import type { LucideIcon } from "lucide-react";

export type ReviewRow = { label: string; value: string };

type ReviewCardProps = {
  icon: LucideIcon;
  title: string;
  subtitle: string;
  rows: ReviewRow[];
};

/** Kartu ringkasan di Step 3 — header berikon, lalu baris label/nilai. */
export default function ReviewCard({ icon: Icon, title, subtitle, rows }: ReviewCardProps) {
  return (
    <div className="overflow-hidden rounded-xl bg-white ring-1 ring-slate-200">
      <div className="flex gap-3 px-5 py-4">
        <Icon className="mt-0.5 h-5 w-5 shrink-0 text-slate-900" aria-hidden />
        <div className="min-w-0">
          <h3 className="text-base font-bold text-slate-900">{title}</h3>
          <p className="mt-0.5 text-sm leading-relaxed text-[#525252]">{subtitle}</p>
        </div>
      </div>

      {/* Di layar kecil tiap baris menumpuk; dari `lg` desainnya menaruh dua
          kolom berdampingan, karena kartunya jadi jauh lebih lebar dan satu
          nilai per baris menyisakan ruang kosong yang lebar. */}
      <dl className="border-t border-slate-100 bg-[#F8FAFC] lg:grid lg:grid-cols-2">
        {rows.map((row, i) => (
          <div
            key={row.label}
            className={`px-5 py-3.5 ${i > 0 ? "border-t border-slate-100 lg:border-t-0" : ""}`}
          >
            <dt className="text-sm font-bold text-slate-900">{row.label}</dt>
            <dd className="mt-0.5 text-sm text-[#525252]">{row.value}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}
