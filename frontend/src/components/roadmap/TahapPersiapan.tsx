"use client";

/**
 * Lini masa lima tahap persiapan.
 *
 * Satu garis vertikal menyambung bulatan tahap. Tahap yang sedang berjalan
 * memakai bulatan ungu pekat dan satu-satunya yang membawa tombol "Tampilkan
 * Journey"; tahap sesudahnya bergembok. Status dan tombolnya tidak dihitung di
 * sini — keduanya datang dari roadmap_state() supaya aturan "tahap aktif
 * adalah tahap pertama yang belum selesai" hanya hidup di satu tempat.
 */

import Link from "next/link";
import { ArrowRight, Check, Lock, Sparkles } from "lucide-react";
import type { Tahap } from "@/lib/roadmapJourney";
import { ROUTES } from "@/lib/routes";

function Bulatan({ status }: { status: Tahap["status"] }) {
  if (status === "SELESAI") {
    return (
      <span className="grid size-8 place-items-center rounded-full bg-emerald-500 text-white">
        <Check className="size-4" aria-hidden />
      </span>
    );
  }
  if (status === "AKTIF") {
    return (
      <span className="grid size-8 place-items-center rounded-full bg-violet-600 text-white">
        <Sparkles className="size-4" aria-hidden />
      </span>
    );
  }
  return (
    <span className="grid size-8 place-items-center rounded-full border border-slate-200 bg-white text-slate-400">
      <Lock className="size-[15px]" aria-hidden />
    </span>
  );
}

export default function TahapPersiapan({ tahap }: { tahap: Tahap[] }) {
  return (
    <section>
      <h2 className="text-[19px] font-bold tracking-tight text-slate-900">
        Tahap Persiapan Profesi
      </h2>

      <ol className="mt-4">
        {tahap.map((t, i) => {
          const terakhir = i === tahap.length - 1;
          return (
            <li key={t.kode} className="relative flex gap-3.5 pb-6 last:pb-0">
              {!terakhir && (
                <span
                  aria-hidden
                  className="absolute left-4 top-9 h-[calc(100%-2.25rem)] w-px bg-slate-200"
                />
              )}
              <Bulatan status={t.status} />

              <div className="min-w-0 flex-1 pt-1">
                <h3 className="text-[15px] font-semibold text-violet-700">{t.nama}</h3>
                <p className="mt-1 text-[13.5px] leading-relaxed text-slate-600">
                  {t.ringkasan}
                </p>

                {t.cta && (
                  <Link
                    href={`${ROUTES.journey}?tahap=${encodeURIComponent(t.kode)}`}
                    className="mt-3 inline-flex items-center gap-2 rounded-full bg-violet-600 px-4 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
                  >
                    Tampilkan Journey
                    <ArrowRight className="size-4" aria-hidden />
                  </Link>
                )}
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}
