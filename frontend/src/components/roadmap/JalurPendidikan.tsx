"use client";

/**
 * Tab "Jalur Pendidikan": dua keadaan dalam satu komponen.
 *
 *   belum memilih   kartu perbandingan Vokasi dan Akademik, masing-masing
 *                   dengan lama tempuh dan tiga keunggulan
 *   sudah memilih   ringkasan jalur + tabel langkah berstatus
 *
 * Statusnya bukan centang manual: ia dihitung di database dari jenjang
 * pendidikan yang diisi pengguna saat onboarding, jadi seorang mahasiswa
 * semester 7 melihat "Lulus SMA/SMK" sudah hijau tanpa harus mencentangnya.
 */

import { useState } from "react";
import { ArrowUpRight, Check, GraduationCap, ScrollText } from "lucide-react";
import StatusPill from "@/components/roadmap/StatusPill";
import { rentangTahun, type Jalur } from "@/lib/roadmapJourney";

// ── kartu pilihan ───────────────────────────────────────────────────────────

function KartuPilihan({
  jalur,
  utama,
  sibuk,
  onPilih,
}: {
  jalur: Jalur;
  /** Kartu kedua digambar terbalik — biru pekat dengan teks putih. */
  utama: boolean;
  sibuk: boolean;
  onPilih: () => void;
}) {
  const Ikon = jalur.kind_code === "VOKASI" ? ScrollText : GraduationCap;
  return (
    <article
      className={`rounded-2xl p-5 ${
        utama ? "bg-blue-600 text-white" : "border border-slate-200 bg-white"
      }`}
    >
      <span
        className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[12px] font-semibold ${
          utama ? "bg-emerald-400 text-emerald-950" : "bg-blue-600 text-white"
        }`}
      >
        <Ikon className="size-3.5" aria-hidden />
        {jalur.kind_label}
      </span>

      <h3
        className={`mt-3.5 text-[17px] font-bold tracking-tight ${
          utama ? "text-white" : "text-slate-900"
        }`}
      >
        {jalur.title_id}
      </h3>
      <p
        className={`mt-1.5 text-[13.5px] leading-relaxed ${
          utama ? "text-blue-100" : "text-slate-500"
        }`}
      >
        {jalur.tagline_id}
      </p>

      <p className="mt-4 flex items-baseline gap-1.5">
        <span className={`text-[30px] font-bold leading-none ${utama ? "text-white" : "text-slate-900"}`}>
          {rentangTahun(jalur.years_min, jalur.years_max)}
        </span>
        <span className={`text-[13px] ${utama ? "text-blue-100" : "text-slate-500"}`}>Tahun</span>
      </p>

      <button
        type="button"
        onClick={onPilih}
        disabled={sibuk}
        className={`mt-4 w-full rounded-full px-4 py-3 text-[14px] font-semibold transition-colors disabled:opacity-60 ${
          utama
            ? "bg-white text-slate-900 hover:bg-blue-50"
            : "bg-slate-100 text-slate-700 hover:bg-slate-200"
        }`}
      >
        {jalur.cta_label_id}
      </button>

      <ul className="mt-4 space-y-2.5">
        {jalur.keunggulan.map((k) => (
          <li key={k} className="flex items-start gap-2.5 text-[13.5px] leading-relaxed">
            <Check
              className={`mt-0.5 size-4 shrink-0 ${utama ? "text-white" : "text-slate-400"}`}
              aria-hidden
            />
            <span className={utama ? "text-white" : "text-slate-700"}>{k}</span>
          </li>
        ))}
      </ul>
    </article>
  );
}

// ── jalur yang sudah dipilih ────────────────────────────────────────────────

function JalurTerpilih({
  jalur,
  sibuk,
  onUbah,
}: {
  jalur: Jalur;
  sibuk: boolean;
  onUbah: () => void;
}) {
  const Ikon = jalur.kind_code === "VOKASI" ? ScrollText : GraduationCap;
  return (
    <article className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
      <header className="flex items-center gap-3 px-4 py-4">
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-violet-600 text-white">
          <Ikon className="size-[18px]" aria-hidden />
        </span>
        <div className="min-w-0">
          <p className="text-[13px] font-semibold text-violet-700">{jalur.kind_label}</p>
          <h3 className="truncate text-[15.5px] font-bold text-slate-900">{jalur.title_id}</h3>
        </div>
      </header>

      <div className="flex items-end justify-between gap-3 bg-slate-100 px-4 py-3.5">
        <div>
          <p className="text-[12.5px] text-slate-500">Estimasi Waktu</p>
          <p className="mt-0.5 flex items-baseline gap-1.5">
            <span className="text-[26px] font-bold leading-none text-slate-900">
              {rentangTahun(jalur.years_min, jalur.years_max)}
            </span>
            <span className="text-[13px] text-slate-500">Tahun</span>
          </p>
        </div>
        <button
          type="button"
          onClick={onUbah}
          disabled={sibuk}
          className="inline-flex shrink-0 items-center gap-1.5 rounded-full bg-white px-3.5 py-2.5 text-[13px] font-medium text-slate-600 transition-colors hover:bg-slate-50 disabled:opacity-60"
        >
          Ubah jalur lain
          <ArrowUpRight className="size-4" aria-hidden />
        </button>
      </div>

      <div className="flex items-center justify-between gap-3 bg-slate-200/70 px-4 py-2.5">
        <span className="text-[13.5px] font-semibold text-slate-700">{jalur.table_label_id}</span>
        <span className="text-[13.5px] font-semibold text-slate-700">Status</span>
      </div>

      <ol>
        {jalur.langkah.map((l) => (
          <li
            key={l.urutan}
            className="flex items-start gap-3 border-b border-slate-100 px-4 py-3.5 last:border-b-0"
          >
            <span
              aria-hidden
              className={`mt-0.5 grid size-5 shrink-0 place-items-center rounded ${
                l.status === "BELUM_MULAI"
                  ? "border border-slate-200 bg-slate-100"
                  : l.status === "SELESAI"
                    ? "bg-violet-200 text-white"
                    : "bg-violet-600 text-white"
              }`}
            >
              {l.status !== "BELUM_MULAI" && <Check className="size-3.5" aria-hidden />}
            </span>

            <div className="min-w-0 flex-1">
              <p className="text-[14px] font-semibold leading-snug text-slate-900">{l.judul}</p>
              {l.catatan && (
                <p className="mt-0.5 text-[12.5px] leading-relaxed text-slate-500">{l.catatan}</p>
              )}
            </div>

            <StatusPill status={l.status} />
          </li>
        ))}
      </ol>
    </article>
  );
}

// ── penampung ───────────────────────────────────────────────────────────────

export default function JalurPendidikan({
  jalur,
  sibuk,
  onPilih,
  onUbah,
}: {
  jalur: Jalur[];
  sibuk: boolean;
  onPilih: (pathId: number) => void;
  onUbah: () => void;
}) {
  const [terbuka] = useState(true);
  const terpilih = jalur.find((j) => j.dipilih);

  if (!jalur.length) {
    return (
      <p className="rounded-2xl border border-slate-200 bg-white px-4 py-6 text-center text-[13.5px] text-slate-500">
        Jalur pendidikan untuk profesi ini belum tersedia.
      </p>
    );
  }

  return (
    <section>
      <h2 className="text-[19px] font-bold tracking-tight text-slate-900">Jalur Pendidikan</h2>
      <p className="mt-1 text-[13.5px] leading-relaxed text-slate-500">
        {terpilih
          ? "Langkah yang perlu Kamu tempuh di jalur ini."
          : "Pilih jalur pendidikan yang sesuai dengan tujuan dan rencana Kamu."}
      </p>

      <div className="mt-4 space-y-5">
        {terpilih ? (
          <JalurTerpilih jalur={terpilih} sibuk={sibuk} onUbah={onUbah} />
        ) : (
          terbuka &&
          jalur.map((j, i) => (
            <KartuPilihan
              key={j.path_id}
              jalur={j}
              utama={jalur.length > 1 && i === jalur.length - 1}
              sibuk={sibuk}
              onPilih={() => onPilih(j.path_id)}
            />
          ))
        )}
      </div>
    </section>
  );
}
