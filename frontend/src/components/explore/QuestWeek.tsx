"use client";

/**
 * "Quest minggu ini" — tiga langkah berikutnya di roadmap yang sedang dijalani.
 *
 * Yang ditampilkan quest, bukan langkah di dalamnya, supaya angka progres di
 * sini dan di layar Roadmap dihitung dari hal yang sama.
 */

import Link from "next/link";
import { ArrowRight, BookOpen, Compass, FileCheck2, PlayCircle, Wrench } from "lucide-react";
import type { WeeklyQuest } from "@/lib/explore";

const IKON: Record<string, typeof BookOpen> = {
  HARD_SKILL: Wrench,
  AKTIVITAS: PlayCircle,
  EDUKASI: BookOpen,
  PENGALAMAN: Compass,
  KARIER: FileCheck2,
  LANJUT: Compass,
};

/**
 * Dibulatkan ke setengah jam terdekat.
 *
 * Angka aslinya penjumlahan estimasi tiap langkah, jadi keluar "3,7 jam" —
 * presisi yang tidak pantas untuk sebuah perkiraan, dan lebih sulit dibaca
 * sekilas daripada "3,5 jam".
 */
function durasi(menit: number): string {
  if (!menit) return "Durasi belum dihitung";
  if (menit < 60) return `${menit} menit`;
  const jam = Math.round(menit / 30) / 2;
  return `${String(jam).replace(".", ",")} jam`;
}

export default function QuestWeek({ quests, total }: { quests: WeeklyQuest[]; total: number }) {
  if (quests.length === 0) return null;

  return (
    <section className="px-4 py-5 sm:px-6">
      <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
        <div className="flex items-center justify-between gap-4 bg-slate-100/80 px-4 py-3">
          <h2 className="text-[16px] font-bold tracking-tight text-slate-900">
            Quest minggu ini ({total}+)
          </h2>
          <Link
            href="/quest"
            aria-label="Lihat semua quest"
            className="grid size-8 shrink-0 place-items-center rounded-full border border-slate-200 bg-white text-slate-700 transition-colors hover:bg-slate-50"
          >
            <ArrowRight className="size-4" aria-hidden />
          </Link>
        </div>

        <ul className="divide-y divide-slate-100">
          {quests.map((q) => {
            const Ikon = IKON[q.quest_kind] ?? BookOpen;
            return (
              <li key={q.activity_id}>
                <Link
                  href="/quest"
                  className="flex items-center gap-3 px-4 py-3.5 transition-colors hover:bg-slate-50"
                >
                  <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-indigo-50 text-indigo-600">
                    <Ikon className="size-4" aria-hidden />
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[13.5px] font-medium leading-snug text-slate-900">
                      {q.quest_title}
                    </span>
                    <span className="mt-0.5 block text-[12px] text-slate-500">
                      {durasi(q.est_minutes)}
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
