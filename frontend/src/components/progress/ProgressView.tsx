"use client";

/**
 * Layar Progress (desain 10 Progress A01).
 *
 * Empat blok: kartu total progress, kartu level, statistik, dan pencapaian
 * terbaru. Semua angkanya datang dari progress_state() — layar ini tidak
 * menghitung persen atau level sendiri.
 *
 * Membuka layar ini juga membagikan hadiah yang sudah pantas didapat (lihat
 * progress_state di 0038), jadi badge onboarding dan Career DNA muncul di sini
 * walau akunnya dibuat sebelum mesin pencapaian ada.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ChevronRight, Info } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import HeroProgress from "@/components/progress/HeroProgress";
import { ambilProgress, type ProgressState } from "@/lib/progress";
import { ROUTES } from "@/lib/routes";

function KartuLevel({ data }: { data: ProgressState }) {
  const [tips, setTips] = useState(false);
  const maks = data.xp_level_berikutnya == null;
  const persen = maks ? 100 : data.persen_level;

  return (
    <section className="rounded-2xl border border-slate-200 bg-white px-4 py-3.5 shadow-sm">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="relative flex items-center gap-1.5 text-[14px] text-slate-500">
            Level {data.level_label}
            <button
              type="button"
              onClick={() => setTips((v) => !v)}
              aria-label="Cara menaikkan level"
              aria-expanded={tips}
              className="rounded-full text-slate-400 transition-colors hover:text-slate-600"
            >
              <Info className="size-4" aria-hidden />
            </button>
            {tips && (
              <span className="absolute left-0 top-6 z-10 whitespace-nowrap rounded-full bg-[#7033FF] px-3 py-1.5 text-[12px] font-medium text-white shadow-sm">
                Selesaikan Quest untuk naik level
              </span>
            )}
          </p>
          <h2 className="mt-0.5 text-[21px] font-bold tracking-tight text-slate-900">
            {data.title}
          </h2>
        </div>

        <div className="w-[150px] shrink-0 pt-1">
          <p className="text-right text-[13px] text-slate-400">
            <strong className="font-bold text-slate-900">{data.xp_di_level}</strong>
            {maks ? " XP" : `/${data.xp_level_berikutnya} XP`}
          </p>
          <div className="mt-2 h-2 overflow-hidden rounded-full bg-slate-200">
            <div
              className="h-full rounded-full bg-emerald-500 transition-[width]"
              style={{ width: `${Math.max(persen, 2)}%` }}
            />
          </div>
        </div>
      </div>
    </section>
  );
}

function Statistik({ nilai, label }: { nilai: number; label: string }) {
  return (
    <div className="flex-1 rounded-2xl border border-slate-200 bg-white px-4 py-4 text-center shadow-sm">
      <p className="text-[24px] font-bold tracking-tight text-slate-900">{nilai}</p>
      <p className="mt-0.5 text-[13.5px] text-slate-500">{label}</p>
    </div>
  );
}

export default function ProgressView() {
  const [data, setData] = useState<ProgressState | null>(null);
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => {
    let batal = false;
    ambilProgress()
      .then((d) => {
        if (!batal) setData(d);
      })
      .catch(() => {
        if (!batal) setGalat("Gagal memuat progress. Coba muat ulang halaman.");
      })
      .finally(() => {
        if (!batal) setMuat(false);
      });
    return () => {
      batal = true;
    };
  }, []);

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-10 pt-6 sm:px-6 lg:py-8">
        <h1 className="text-[30px] font-bold tracking-tight text-slate-900">Progress</h1>
        <p className="mt-1 text-[14px] text-slate-500">Apa yang sudah Kamu capai</p>

        {galat && (
          <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galat}</p>
        )}

        {muat ? (
          <div className="mt-5 space-y-4" aria-busy>
            <div className="h-[122px] animate-pulse rounded-2xl bg-slate-100" />
            <div className="h-24 animate-pulse rounded-2xl bg-slate-100" />
            <div className="h-24 animate-pulse rounded-2xl bg-slate-100" />
          </div>
        ) : !data ? (
          !galat && (
            <p className="mt-6 rounded-2xl border border-slate-200 px-5 py-8 text-center text-[13.5px] text-slate-500">
              Progresmu belum bisa dibaca. Coba muat ulang halaman.
            </p>
          )
        ) : (
          <>
            <div className="mt-5">
              <HeroProgress persen={data.total_persen} />
            </div>

            <div className="mt-4">
              <KartuLevel data={data} />
            </div>

            {!data.has_career && (
              <p className="mt-3 text-[12.5px] leading-relaxed text-slate-500">
                Total progress dihitung dari quest profesi pilihanmu. Pilih profesinya dulu di{" "}
                <Link href={ROUTES.explore} className="font-semibold text-violet-600">
                  Explore
                </Link>
                .
              </p>
            )}

            <h2 className="mt-7 text-[17px] font-bold tracking-tight text-slate-900">
              Statistik Pencapaian
            </h2>
            <div className="mt-3 flex gap-3">
              <Statistik nilai={data.n_quest_selesai} label="Quest Selesai" />
              <Statistik nilai={data.n_achievement} label="Achievement" />
            </div>

            <Link
              href={ROUTES.pencapaian}
              className="mt-7 flex items-center justify-between gap-3 rounded-xl py-1 transition-colors hover:bg-slate-50"
            >
              <h2 className="text-[17px] font-bold tracking-tight text-slate-900">
                Pencapaian Terbaru
              </h2>
              <ChevronRight className="size-5 shrink-0 text-slate-700" aria-hidden />
            </Link>

            {data.terbaru.length === 0 ? (
              <p className="mt-3 rounded-2xl bg-[#FAFAFA] px-4 py-5 text-[13.5px] leading-relaxed text-slate-500">
                Belum ada pencapaian. Selesaikan quest pertamamu untuk membuka badge.
              </p>
            ) : (
              <ul className="mt-3 space-y-2.5">
                {data.terbaru.map((b) => (
                  <li key={b.kode} className="flex items-center gap-3.5 rounded-2xl bg-[#FAFAFA] p-3">
                    <Image
                      src={b.gambar}
                      alt=""
                      width={420}
                      height={480}
                      className="h-14 w-auto shrink-0"
                    />
                    <div className="min-w-0 flex-1">
                      <h3 className="text-[15.5px] font-semibold text-slate-900">{b.nama}</h3>
                      <p className="mt-0.5 text-[13px] leading-snug text-slate-500">{b.deskripsi}</p>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}
