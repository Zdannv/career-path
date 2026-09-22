"use client";

/**
 * "Quest minggu ini" — quest yang bisa dikerjakan sekarang, satu per jenis.
 *
 * Datanya dari quest_minggu_ini (0036), sumber yang sama dengan layar Quest,
 * jadi yang terlihat di sini selalu ada di sana. Angka di judul adalah jumlah
 * quest yang benar-benar bisa dikerjakan saat ini, bukan tebakan.
 */

import Link from "next/link";
import {
  ArrowRight,
  ChartNoAxesColumn,
  ChevronsRight,
  Compass,
  NotebookPen,
  Route,
  UsersRound,
} from "lucide-react";
import type { WeeklyQuest } from "@/lib/explore";
import { rentangMenit } from "@/lib/quest";
import { ROUTES, questGrupPath } from "@/lib/routes";

const IKON: Record<string, typeof Compass> = {
  EKSPLORASI: Compass,
  SOFT_SKILL: UsersRound,
  HARD_SKILL: NotebookPen,
  TOOL: ChartNoAxesColumn,
  PENGALAMAN: ChevronsRight,
  BERKARIER: Route,
};

export default function QuestWeek({ quests, total }: { quests: WeeklyQuest[]; total: number }) {
  if (quests.length === 0) return null;

  return (
    <section className="px-4 py-5 sm:px-6">
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
        <div className="flex items-center justify-between gap-4 bg-slate-100/80 px-4 py-3">
          <h2 className="text-[16px] font-bold tracking-tight text-slate-900">
            Quest minggu ini ({total})
          </h2>
          <Link
            href={ROUTES.quest}
            aria-label="Lihat semua quest"
            className="grid size-8 shrink-0 place-items-center rounded-full border border-slate-200 bg-white text-slate-700 transition-colors hover:bg-slate-50"
          >
            <ArrowRight className="size-4" aria-hidden />
          </Link>
        </div>

        <ul className="divide-y divide-slate-100">
          {quests.map((q) => {
            const Ikon = IKON[q.jenis] ?? Compass;
            const durasi = rentangMenit(q.min_menit, q.max_menit);
            return (
              <li key={q.quest_key}>
                <Link
                  href={questGrupPath(q.slug, q.kode)}
                  className="flex items-center gap-3 px-4 py-3.5 transition-colors hover:bg-slate-50"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-indigo-50 text-indigo-600">
                    <Ikon className="size-4" aria-hidden />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="line-clamp-2 text-[13.5px] font-medium leading-snug text-slate-900">
                      {q.teks}
                    </span>
                    <span className="mt-0.5 block text-[12px] text-slate-500">
                      {q.label}
                      {durasi && ` · ${durasi}`}
                      {q.status === "DIAMBIL" && " · sedang dikerjakan"}
                    </span>
                  </span>
                  <span className="shrink-0 text-[13px] font-bold text-slate-900">
                    +{q.xp} <span className="text-[11px] font-semibold text-emerald-600">XP</span>
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
