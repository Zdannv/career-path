"use client";

/**
 * Kartu Ketahanan AI dan lembar penjelasnya.
 *
 * Angkanya estimasi model, bukan survei — itulah kenapa tanda tanya di judul
 * bukan hiasan. Lembar penjelas menerangkan apa yang diukur sebelum pengguna
 * memakai angkanya untuk mengambil keputusan.
 */

import Image from "next/image";
import { Info } from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import { nadaKetahanan } from "@/lib/careerDetail";

export default function AiCard({
  skor,
  label,
  penjelasan,
  onInfo,
}: {
  skor: number | null;
  label: string | null;
  penjelasan: string | null;
  onInfo: () => void;
}) {
  const nada = nadaKetahanan(skor);
  return (
    <section className={`flex items-start gap-3 rounded-2xl p-4 ${nada.bg}`}>
      <Image
        src="/profesi/ketahanan-ai.png"
        alt=""
        width={80}
        height={80}
        className="size-[68px] shrink-0"
      />
      <div className="min-w-0">
        <div className="flex items-center gap-1.5">
          <h3 className="text-[14.5px] font-bold text-slate-900">Ketahanan AI</h3>
          <button
            type="button"
            onClick={onInfo}
            aria-label="Apa itu Ketahanan AI"
            className="rounded-full p-0.5 text-slate-500 transition-colors hover:bg-white/60"
          >
            <Info className="size-3.5" aria-hidden />
          </button>
        </div>
        <p className="mt-1 flex items-center gap-2">
          <span className={`text-[26px] font-bold leading-none ${nada.text}`}>{skor ?? "—"}</span>
          <span className="text-[13px] text-slate-500">/100</span>
          {label && (
            <span
              className={`rounded-full px-2.5 py-1 text-[11.5px] font-medium ${nada.chipBg} ${nada.chipText}`}
            >
              {label}
            </span>
          )}
        </p>
        <p className="mt-1.5 text-[12.5px] leading-relaxed text-slate-600">{penjelasan}</p>
      </div>
    </section>
  );
}

export function AiInfoSheet({ buka, onTutup }: { buka: boolean; onTutup: () => void }) {
  return (
    <Sheet buka={buka} onTutup={onTutup} judul="Ketahanan AI">
      <div className="flex items-start gap-3 px-4 pb-6 pt-2 sm:px-6">
        <Image
          src="/profesi/ketahanan-ai.png"
          alt=""
          width={80}
          height={80}
          className="size-[68px] shrink-0"
        />
        <div className="text-[13.5px] leading-relaxed text-violet-800">
          <p>
            Mengukur tingkat ketahanan profesi terhadap otomatisasi dan penggantian tugas oleh AI.
          </p>
          <p className="mt-3 text-[12px] text-slate-500">
            Skor dihitung dari komposisi aktivitas kerja profesi ini: tugas yang menuntut kehadiran
            fisik, penilaian situasional, dan interaksi manusia lebih sulit digantikan, sedangkan
            tugas yang mengolah informasi menurut aturan tetap paling mudah. Angkanya estimasi
            model, bukan hasil survei.
          </p>
        </div>
      </div>
    </Sheet>
  );
}
