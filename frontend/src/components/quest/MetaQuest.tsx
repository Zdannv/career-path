/**
 * Baris kecil di bawah kalimat quest: durasi dan XP.
 * Quest tanpa durasi (Asah Pengalaman, Siap Berkarier) hanya menampilkan XP.
 */

import { Layers, Timer } from "lucide-react";
import { rentangMenit } from "@/lib/quest";

export default function MetaQuest({
  min,
  max,
  xp,
  redup = false,
}: {
  min: number | null;
  max: number | null;
  xp: number;
  redup?: boolean;
}) {
  const durasi = rentangMenit(min, max);
  return (
    <p
      className={`flex flex-wrap items-center gap-x-4 gap-y-1 text-[14px] ${
        redup ? "text-slate-400" : "text-slate-900"
      }`}
    >
      {durasi && (
        <span className="flex items-center gap-1.5">
          <Timer className={`size-4 ${redup ? "" : "text-blue-600"}`} aria-hidden />
          {durasi}
        </span>
      )}
      <span className="flex items-center gap-1.5">
        <Layers className={`size-4 ${redup ? "" : "text-slate-700"}`} aria-hidden />
        <span className="font-semibold">+{xp}</span>
        <span className={redup ? "" : "text-emerald-500"}>XP</span>
      </span>
    </p>
  );
}
