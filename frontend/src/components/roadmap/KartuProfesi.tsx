"use client";

/**
 * Kartu ungu di puncak layar Roadmap: profesi yang dituju dan level XP.
 *
 * Bar XP-nya menunjukkan jarak ke level berikutnya, bukan ke 100 XP mati —
 * ambangnya berbeda tiap level (500, 1500, 3000, 5000) dan diambil dari
 * tabel xp_levels, bukan ditulis ulang di sini.
 */

import Link from "next/link";
import { Info } from "lucide-react";
import { profesiPath } from "@/lib/routes";

export default function KartuProfesi({
  careerId,
  careerName,
  totalXp,
  levelName,
  minXp,
  nextXp,
}: {
  careerId: number;
  careerName: string;
  totalXp: number;
  levelName: string | null;
  minXp: number | null;
  nextXp: number | null;
}) {
  const bawah = minXp ?? 0;
  const atas = nextXp ?? Math.max(totalXp, 1);
  const persen = nextXp
    ? Math.max(0, Math.min(100, ((totalXp - bawah) / Math.max(atas - bawah, 1)) * 100))
    : 100;

  return (
    <section className="rounded-2xl bg-violet-600 p-5 text-white shadow-sm">
      <div className="flex items-start gap-3">
        <div className="min-w-0 flex-1">
          <p className="text-[12.5px] text-violet-200">Profesi Pilihan</p>
          <h2 className="mt-0.5 text-[22px] font-bold leading-tight tracking-tight">
            {careerName}
          </h2>
        </div>
        <Link
          href={profesiPath(careerId)}
          aria-label={`Lihat detail ${careerName}`}
          className="grid size-9 shrink-0 place-items-center rounded-full bg-white text-violet-700 transition-transform hover:scale-105"
        >
          <Info className="size-[18px]" aria-hidden />
        </Link>
      </div>

      <div className="mt-5 rounded-xl bg-violet-700/60 px-3.5 py-3">
        <div className="flex items-baseline justify-between text-[13px]">
          <span className="font-semibold">Level {levelName ?? "Explorer"}</span>
          <span>
            <strong className="font-bold">{totalXp}</strong>
            <span className="text-violet-200">/{nextXp ?? totalXp} XP</span>
          </span>
        </div>
        <div className="mt-2 h-2 overflow-hidden rounded-full bg-white">
          <div
            className="h-full rounded-full bg-emerald-400 transition-[width]"
            style={{ width: `${Math.max(persen, 3)}%` }}
          />
        </div>
      </div>
    </section>
  );
}
