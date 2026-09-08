"use client";

/**
 * Blok skor kecocokan: busur, judul, lencana pita, dan daftar alasan.
 *
 * Dipakai dua layar dengan sedikit beda: di detail profesi alasannya langsung
 * terbuka, di detail kategori ia bersembunyi di balik "Tampilkan detail".
 */

import { useState } from "react";
import { Check, ChevronDown, Info, PieChart } from "lucide-react";
import MatchGauge from "@/components/profesi/MatchGauge";
import { labelBand, type Alasan } from "@/lib/careerDetail";

function TeksTebal({ teks }: { teks: string }) {
  // Database mengirim <b> di tengah kalimat. Dipecah manual, bukan
  // dangerouslySetInnerHTML: satu-satunya penanda yang diizinkan adalah <b>,
  // jadi tidak ada alasan menyerahkan HTML mentah ke peramban.
  const bagian = teks.split(/<b>|<\/b>/);
  return (
    <>
      {bagian.map((s, i) =>
        i % 2 === 1 ? (
          <strong key={i} className="font-semibold text-slate-900">
            {s}
          </strong>
        ) : (
          <span key={i}>{s}</span>
        ),
      )}
    </>
  );
}

export function DaftarAlasan({ alasan }: { alasan: Alasan[] }) {
  if (alasan.length === 0) return null;
  return (
    <ul className="flex flex-col gap-3.5">
      {alasan.map((a, i) => (
        <li key={i} className="flex items-start gap-2.5">
          <span
            className={`mt-0.5 grid size-[18px] shrink-0 place-items-center rounded-full border ${
              a.nada === "cocok"
                ? "border-emerald-500 text-emerald-600"
                : "border-amber-500 text-amber-600"
            }`}
            aria-hidden
          >
            {a.nada === "cocok" ? <Check className="size-3" /> : <Info className="size-3" />}
          </span>
          <p className="text-[13.5px] leading-relaxed text-slate-600">
            <TeksTebal teks={a.teks} />
          </p>
        </li>
      ))}
    </ul>
  );
}

export function LencanaBand({
  skor,
  band,
}: {
  skor: number | null;
  band: string | null;
}) {
  if (skor == null) return null;
  const hijau = band === "HIGHLY_RECOMMENDED";
  const biru = band === "RECOMMENDED";
  return (
    <span
      className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-[12.5px] ${
        hijau
          ? "border-emerald-200 bg-emerald-50"
          : biru
            ? "border-sky-200 bg-sky-50"
            : "border-amber-200 bg-amber-50"
      }`}
    >
      <PieChart
        className={`size-3.5 ${hijau ? "text-emerald-700" : biru ? "text-sky-700" : "text-amber-700"}`}
        aria-hidden
      />
      <span className="font-semibold text-slate-900">{Math.round(skor)}%</span>
      <span className={hijau ? "text-emerald-700" : biru ? "text-sky-700" : "text-amber-700"}>
        {labelBand(band)}
      </span>
    </span>
  );
}

export default function MatchBlock({
  skor,
  band,
  alasan,
  ringkas = false,
}: {
  skor: number | null;
  band: string | null;
  alasan: Alasan[];
  /** true = alasan disembunyikan di balik tombol "Tampilkan detail". */
  ringkas?: boolean;
}) {
  const [buka, setBuka] = useState(false);
  return (
    <section className="flex flex-col items-center">
      <MatchGauge skor={skor} />
      <h2 className="mt-1 text-[15px] font-semibold text-slate-900">
        Skor Kecocokan dengan Profesi
      </h2>
      <div className="mt-2.5">
        <LencanaBand skor={skor} band={band} />
      </div>

      {skor == null && (
        <p className="mt-3 max-w-xs text-center text-[12.5px] leading-relaxed text-slate-500">
          Selesaikan Career DNA dulu untuk melihat seberapa cocok profesi ini denganmu.
        </p>
      )}

      {alasan.length > 0 && ringkas && !buka && (
        <button
          type="button"
          onClick={() => setBuka(true)}
          className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-4 py-2 text-[12.5px] font-medium text-slate-600 transition-colors hover:bg-slate-200"
        >
          Tampilkan detail
          <ChevronDown className="size-3.5" aria-hidden />
        </button>
      )}

      {alasan.length > 0 && (!ringkas || buka) && (
        <div className="mt-5 w-full">
          <DaftarAlasan alasan={alasan} />
        </div>
      )}
    </section>
  );
}
