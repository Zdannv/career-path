/**
 * Pil status yang dipakai tabel jalur pendidikan dan tabel skill/tools.
 *
 * Tiga warna, tiga arti: hijau sudah lewat, ungu sedang dijalani, abu belum
 * disentuh. Ditulis sekali supaya kedua tabel tidak berbeda tinggi dan radius.
 */

import { LABEL_STATUS, type StatusItem } from "@/lib/roadmapJourney";

const NADA: Record<StatusItem, string> = {
  SELESAI: "bg-emerald-500 text-white",
  BERLANGSUNG: "bg-violet-600 text-white",
  BELUM_MULAI: "bg-slate-300 text-white",
};

export default function StatusPill({ status }: { status: StatusItem }) {
  return (
    <span
      className={`inline-flex shrink-0 items-center rounded-full px-2.5 py-1 text-[11px] font-semibold ${NADA[status]}`}
    >
      {LABEL_STATUS[status]}
    </span>
  );
}
