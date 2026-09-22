/**
 * Ubin ikon di kiri kartu grup quest.
 *
 * Nama ikon dan nada warnanya datang dari quest_group_kinds, jadi yang dipakai
 * didaftarkan satu per satu di sini — alasan yang sama dengan journey/Ikon:
 * mengindeks `import * as lucide` menarik seluruh pustaka ke bundel.
 */

import {
  ChartNoAxesColumn,
  ChevronsRight,
  Compass,
  NotebookPen,
  Route,
  Sparkles,
  UsersRound,
  type LucideIcon,
} from "lucide-react";
import type { ToneGrup } from "@/lib/quest";

const IKON: Record<string, LucideIcon> = {
  ChartNoAxesColumn,
  ChevronsRight,
  Compass,
  NotebookPen,
  Route,
  UsersRound,
};

const TONE: Record<ToneGrup, string> = {
  hijau: "bg-[#C9F5DC] text-emerald-700",
  lime: "bg-[#DDF5A6] text-lime-700",
  biru: "bg-[#CFE0FF] text-blue-600",
  ungu: "bg-[#DDD6FE] text-violet-600",
  pink: "bg-[#FBD3E9] text-pink-600",
  violet: "bg-violet-100 text-violet-600",
};

export default function IkonGrup({ ikon, tone }: { ikon: string; tone: ToneGrup }) {
  const Komponen = IKON[ikon] ?? Sparkles;
  return (
    <span
      className={`grid size-[60px] shrink-0 place-items-center rounded-2xl ${TONE[tone] ?? TONE.violet}`}
    >
      <Komponen className="size-6" aria-hidden />
    </span>
  );
}
