"use client";

/**
 * Kartu profesi — satu-satunya bentuk kartu di layar Explore.
 *
 * Empat baris Explore memakai kartu yang sama dengan bagian bawah yang
 * berbeda: baris tanpa Career DNA berhenti di durasi, baris ber-DNA menambah
 * skor kecocokan dan satu kalimat alasan, dan baris "Dari Aktivitas Pilihan"
 * menambah daftar atribut. Menyatukannya di satu komponen yang membuat empat
 * baris itu tidak pelan-pelan berbeda tampilan.
 */

import Link from "next/link";
import { BarChart3, CircleDollarSign, History, ChevronRight, PieChart, Building2 } from "lucide-react";
import {
  bandTone,
  formatDuration,
  formatSalary,
  type CareerCard as CareerCardData,
  type ScoredCard,
} from "@/lib/explore";

type Props = {
  card: CareerCardData | ScoredCard;
  /** Deskripsi hanya muncul di baris yang tidak menampilkan atribut aktivitas. */
  showDescription?: boolean;
  showAttributes?: boolean;
  showScore?: boolean;
};

function isScored(c: CareerCardData | ScoredCard): c is ScoredCard {
  return "match_score" in c;
}

export default function CareerCard({
  card,
  showDescription = true,
  showAttributes = false,
  showScore = false,
}: Props) {
  const scored = isScored(card) ? card : null;
  const score = scored?.match_score == null ? null : Math.round(Number(scored.match_score));
  const tone = bandTone(scored?.band_code ?? null);

  return (
    <Link
      href={`/explore/${card.career_id}`}
      className="group flex w-[260px] shrink-0 snap-start flex-col rounded-2xl border border-slate-200 bg-white transition-colors hover:border-slate-300 sm:w-[268px]"
    >
      <div className="flex flex-col gap-2.5 p-4">
        <div className="flex items-start justify-between gap-2">
          <span className="inline-flex max-w-full items-center gap-1 rounded-md bg-indigo-50 px-2 py-1 text-[11px] font-medium text-indigo-700">
            <Building2 className="size-3 shrink-0" aria-hidden />
            <span className="truncate">{card.sub_industry ?? "Belum dikelompokkan"}</span>
            {card.sub_industry_extra > 0 && (
              <span className="shrink-0 text-indigo-400">(+{card.sub_industry_extra})</span>
            )}
          </span>
          {showScore && (
            <ChevronRight className="mt-0.5 size-4 shrink-0 text-slate-400" aria-hidden />
          )}
        </div>

        <h3 className="text-[15px] font-semibold leading-snug text-slate-900">
          {card.career_name}
        </h3>

        {showDescription && card.career_description && (
          <p className="line-clamp-3 text-[13px] leading-relaxed text-slate-500">
            {card.career_description}
          </p>
        )}

        <dl className="mt-0.5 flex flex-col gap-1.5 text-[12.5px] text-slate-600">
          <div className="flex items-center gap-2">
            <BarChart3 className="size-3.5 shrink-0 text-slate-400" aria-hidden />
            <dd>{card.demand_label}</dd>
          </div>
          <div className="flex items-center gap-2">
            <CircleDollarSign className="size-3.5 shrink-0 text-slate-400" aria-hidden />
            <dd>{formatSalary(card.salary_min, card.salary_max)}</dd>
          </div>
          <div className="flex items-center gap-2">
            <History className="size-3.5 shrink-0 text-slate-400" aria-hidden />
            <dd>{formatDuration(card.roadmap_months)}</dd>
          </div>
        </dl>

        {showAttributes && (card.activity_attributes?.length ?? 0) > 0 && (
          <div className="mt-1 border-t border-slate-100 pt-3">
            <p className="text-[12px] font-medium text-slate-500">Atribut Aktivitas</p>
            <ul className="mt-2 flex flex-wrap gap-1.5">
              {card.activity_attributes!.slice(0, 3).map((a) => (
                <li
                  key={a}
                  className="rounded-md bg-indigo-50 px-2 py-1 text-[11px] font-medium text-indigo-700"
                >
                  {a}
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {showScore && score != null && (
        <div className="mt-auto border-t border-slate-100 px-4 py-3">
          <div className="flex items-center gap-2">
            <PieChart className="size-3.5 shrink-0 text-slate-500" aria-hidden />
            <span className="text-[12.5px] font-semibold text-slate-900">{score}%</span>
            {scored?.band_label && (
              <span
                className={`rounded-md px-2 py-0.5 text-[11px] font-medium ${tone.bg} ${tone.text}`}
              >
                {scored.band_label === "Highly Recommended"
                  ? "Sangat Direkomendasikan"
                  : scored.band_label === "Recommended"
                    ? "Direkomendasikan"
                    : "Tidak Direkomendasikan"}
              </span>
            )}
          </div>
          {scored?.reason && (
            <p className="mt-2 text-[12.5px] leading-relaxed text-slate-500">{scored.reason}</p>
          )}
        </div>
      )}
    </Link>
  );
}
