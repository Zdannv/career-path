"use client";

/**
 * Blok Explore dari desain "In Review":
 *
 *   ProfesiDisimpanBar   pita biru "Profesi Disimpan · N Profesi"
 *   DnaKamuCard          "Lihat kembali pilihan atribut DNA", membuka sheet DNA Kamu
 *   QuestBanner          "Quest Minggu ini · N Quest"
 *   SubIndustriCard      Rekomendasi Sub-Industri berdasarkan atribut DNA
 *   DemandList           "Paling Diminati tahun ini" versi daftar ringkas
 *
 * Datanya dari 0048 (simpanan dan sub-industri), dna_options/dna_progress
 * (DNA Kamu), dan quest_minggu_ini (0036).
 */

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight, Bookmark, Building2, ChevronRight, Dna, ScrollText, X } from "lucide-react";
import type { CareerCard, SubIndustriRekomendasi } from "@/lib/explore";
import { ROUTES, profesiPath } from "@/lib/routes";

export type DnaKelompok = { nama: string; isi: string[] };

export function ProfesiDisimpanBar({ jumlah }: { jumlah: number }) {
  return (
    <Link
      href="/explore/daftar/disimpan"
      className="flex items-center gap-3 rounded-2xl bg-gradient-to-r from-[#3B82F6] to-[#2563EB] px-4 py-3.5 text-white transition-opacity hover:opacity-95"
    >
      <Bookmark className="size-4 shrink-0" aria-hidden />
      <span className="flex-1 text-[14px] font-semibold">Profesi Disimpan</span>
      <span className="rounded-full bg-white/20 px-2.5 py-0.5 text-[12px] font-semibold">{jumlah} Profesi</span>
      <ChevronRight className="size-4 shrink-0" aria-hidden />
    </Link>
  );
}

export function DnaKamuCard({ kelompok }: { kelompok: DnaKelompok[] }) {
  const [buka, setBuka] = useState(false);
  const total = kelompok.reduce((n, k) => n + k.isi.length, 0);

  useEffect(() => {
    if (!buka) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setBuka(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [buka]);

  if (total === 0) return null;
  return (
    <>
      <button
        type="button"
        onClick={() => setBuka(true)}
        className="relative flex w-full items-center gap-3 overflow-hidden rounded-2xl bg-gradient-to-r from-[#6D5DF6] to-[#8B5CF6] p-4 text-left text-white transition-opacity hover:opacity-95"
      >
        <span className="min-w-0 flex-1">
          <span className="block text-[13px] leading-snug text-white/85">
            Lihat kembali pilihan atribut DNA yang kamu pilih
          </span>
          <span className="mt-2.5 inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-[12.5px] font-semibold text-violet-700">
            Cek {total} DNA Kamu <ArrowRight className="size-3.5" aria-hidden />
          </span>
        </span>
        <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-white/15">
          <Dna className="size-7" aria-hidden />
        </span>
      </button>

      {buka && (
        <div className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/50 sm:items-center" onClick={() => setBuka(false)}>
          <div
            role="dialog"
            aria-modal="true"
            aria-label="DNA Kamu"
            onClick={(e) => e.stopPropagation()}
            className="max-h-[85vh] w-full overflow-y-auto rounded-t-3xl bg-white p-5 sm:max-w-md sm:rounded-3xl"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 className="text-[17px] font-bold text-slate-900">DNA Kamu</h2>
                <p className="text-[13px] text-slate-500">{total} DNA yang kamu pilih</p>
              </div>
              <button type="button" onClick={() => setBuka(false)} aria-label="Tutup" className="rounded-full p-1.5 text-slate-500 hover:bg-slate-100">
                <X className="size-5" aria-hidden />
              </button>
            </div>
            <div className="mt-4 flex flex-col gap-3">
              {kelompok.filter((k) => k.isi.length > 0).map((k) => (
                <section key={k.nama} className="rounded-2xl bg-[#EEF2FF] p-4">
                  <h3 className="text-[14px] font-semibold text-slate-900">{k.nama}</h3>
                  <ul className="mt-2.5 flex flex-wrap gap-2">
                    {k.isi.map((n) => (
                      <li key={n} className="rounded-full bg-white px-3 py-1 text-[12.5px] font-medium text-violet-700 ring-1 ring-violet-200">
                        {n}
                      </li>
                    ))}
                  </ul>
                </section>
              ))}
            </div>
            <Link
              href={ROUTES.careerDna}
              className="mt-5 flex w-full items-center justify-center rounded-full bg-slate-100 py-3 text-[14px] font-semibold text-slate-800 hover:bg-slate-200"
            >
              Ubah pilihan Career DNA
            </Link>
          </div>
        </div>
      )}
    </>
  );
}

export function QuestBanner({ jumlah }: { jumlah: number }) {
  return (
    <Link
      href={ROUTES.quest}
      className="relative flex items-center gap-3 overflow-hidden rounded-2xl bg-gradient-to-r from-[#2563EB] to-[#4F46E5] p-4 text-white transition-opacity hover:opacity-95"
    >
      <span className="min-w-0 flex-1">
        <span className="block text-[16px] font-bold">Quest Minggu ini</span>
        <span className="mt-1 block text-[13px] leading-snug text-white/85">
          Selesaikan quest dan kenali lebih dalam profesi pilihanmu.
        </span>
        <span className="mt-2.5 inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-[12.5px] font-semibold text-blue-700">
          {jumlah} Quest <ArrowRight className="size-3.5" aria-hidden />
        </span>
      </span>
      <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-white/15">
        <ScrollText className="size-7" aria-hidden />
      </span>
    </Link>
  );
}

/** Kalimat alasan dari pilihan DNA yang sejalan dengan sub-industri itu. */
function alasan(s: SubIndustriRekomendasi): string {
  const daftar = (xs: string[]) =>
    xs.length <= 1 ? (xs[0] ?? "") : `${xs.slice(0, -1).join(", ")} dan ${xs[xs.length - 1]}`;
  const minat = s.minat.slice(0, 2).map((x) => x.toLowerCase());
  const akt = s.aktivitas.slice(0, 2).map((x) => x.toLowerCase());
  const bagian = [
    minat.length ? `Minat ${daftar(minat)}` : "",
    akt.length ? `${minat.length ? "serta aktivitas" : "Aktivitas"} ${daftar(akt)}` : "",
  ].filter(Boolean);
  if (!bagian.length) return `Profilmu cukup cocok dengan sejumlah profesi di ${s.name_id.toLowerCase()}.`;
  return `${bagian.join(" ")} relevan dengan sejumlah profesi di ${s.name_id.toLowerCase()}.`;
}

export function SubIndustriCard({ data }: { data: SubIndustriRekomendasi[] }) {
  if (data.length === 0) return null;
  return (
    <section className="px-4 py-5 sm:px-6">
      <h2 className="text-[17px] font-bold tracking-tight text-slate-900">Rekomendasi Sub-Industri</h2>
      <p className="mt-0.5 text-[13px] text-slate-500">Berdasarkan Atribut DNA kamu</p>
      <div className="mt-4 flex flex-col gap-3">
        {data.map((s) => (
          <article key={s.code} className="rounded-2xl border border-slate-200 bg-white p-4">
            <div className="flex items-start gap-3">
              <span className="grid size-14 shrink-0 place-items-center rounded-xl bg-[#EEF2FF] text-indigo-600">
                <Building2 className="size-6" aria-hidden />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-[16px] font-semibold leading-snug text-slate-900">{s.name_id}</p>
                <p className="text-[12.5px] text-slate-500">{s.industry_name}</p>
                <Link
                  href={`/explore/daftar/sub-${encodeURIComponent(s.code)}`}
                  className="mt-2 inline-flex items-center gap-1 rounded-full bg-[#2563EB] px-3 py-1 text-[12px] font-semibold text-white hover:bg-blue-700"
                >
                  {s.n_profesi} Profesi terkait <ChevronRight className="size-3.5" aria-hidden />
                </Link>
              </div>
            </div>
            <div className="mt-3 border-t border-slate-100 pt-3">
              <div className="flex items-center justify-between gap-2">
                <p className="text-[13px] font-semibold text-slate-900">Mengapa direkomendasikan?</p>
                <span className="rounded-full bg-emerald-50 px-2 py-0.5 text-[12px] font-semibold text-emerald-700">
                  {Math.round(Number(s.skor))}%
                </span>
              </div>
              <p className="mt-1 text-[13px] leading-relaxed text-slate-600">{alasan(s)}</p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

export function DemandList({ data }: { data: CareerCard[] }) {
  if (data.length === 0) return null;
  return (
    <section className="px-4 py-5 sm:px-6">
      <div className="rounded-2xl border border-slate-200 bg-white p-4">
        <h2 className="text-[16px] font-bold tracking-tight text-slate-900">Paling Diminati tahun ini 🔥</h2>
        <ul className="mt-2 divide-y divide-slate-100">
          {data.slice(0, 5).map((c) => (
            <li key={c.career_id}>
              <Link href={profesiPath(c.career_id)} className="flex items-center justify-between gap-3 py-3 text-[14px] text-slate-800 hover:text-violet-700">
                <span className="min-w-0">{c.career_name}</span>
                <ChevronRight className="size-4 shrink-0 text-slate-400" aria-hidden />
              </Link>
            </li>
          ))}
        </ul>
        <Link
          href="/explore/daftar/paling-diminati"
          className="mt-2 flex items-center justify-center gap-1.5 rounded-full bg-slate-100 py-2.5 text-[13px] font-semibold text-slate-700 hover:bg-slate-200"
        >
          Lihat 10 Profesi teratas <ArrowRight className="size-3.5" aria-hidden />
        </Link>
      </div>
    </section>
  );
}
