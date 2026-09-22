"use client";

/**
 * Layar Journey: isi satu tahap persiapan.
 *
 * Tahap mana yang dibuka datang dari query `?tahap=` — itulah yang ditulis
 * tombol "Tampilkan Journey" di Roadmap. Tanpa query, database memilihkan
 * tahap pertama yang belum selesai, jadi masuk lewat bar navigasi selalu
 * mendarat di tempat pengguna berhenti.
 *
 * Pemilih tahap di bawah hero memakai daftar dari roadmap_state(), termasuk
 * status terkuncinya, supaya pengguna tidak bisa melompat ke tahap yang belum
 * terbuka lewat mengubah URL sendiri — tombolnya memang tidak bisa ditekan.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Lock } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import IsiTahap from "@/components/journey/IsiTahap";
import {
  ambilJourneyStage,
  ambilRoadmapState,
  heroTahap,
  type JourneyStage,
  type RoadmapState,
} from "@/lib/roadmapJourney";
import { ROUTES } from "@/lib/routes";

export default function JourneyView() {
  const params = useSearchParams();
  const diminta = params.get("tahap") ?? undefined;

  const [state, setState] = useState<RoadmapState | null>(null);
  const [tahap, setTahap] = useState<JourneyStage | null>(null);
  const [pilih, setPilih] = useState<string | undefined>(diminta);
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => setPilih(diminta), [diminta]);

  useEffect(() => {
    let batal = false;
    (async () => {
      try {
        const s = await ambilRoadmapState();
        if (batal) return;
        setState(s);
        if (s?.career_id) {
          const t = await ambilJourneyStage(s.career_id, pilih);
          if (!batal) setTahap(t);
        }
      } catch {
        if (!batal) setGalat("Gagal memuat journey. Coba muat ulang halaman.");
      } finally {
        if (!batal) setMuat(false);
      }
    })();
    return () => {
      batal = true;
    };
  }, [pilih]);

  const daftar = state?.tahap ?? [];

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-10 pt-6 sm:px-6 lg:py-8">
        <h1 className="text-[30px] font-bold tracking-tight text-slate-900">Journey</h1>
        <p className="mt-1 text-[14px] text-slate-500">Apa yang perlu Kamu ketahui</p>

        {galat && (
          <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galat}</p>
        )}

        {muat ? (
          <div className="mt-5 space-y-4" aria-busy>
            <div className="h-56 animate-pulse rounded-2xl bg-slate-100" />
            <div className="h-72 animate-pulse rounded-2xl bg-slate-100" />
          </div>
        ) : !state?.has_career || !tahap ? (
          <div className="mt-8 rounded-2xl border border-slate-200 bg-white px-5 py-8 text-center">
            <h2 className="text-[16px] font-bold text-slate-900">Journey belum bisa dimulai</h2>
            <p className="mx-auto mt-2 max-w-sm text-[13.5px] leading-relaxed text-slate-500">
              Isinya menyesuaikan profesi yang Kamu tuju. Pilih profesinya dulu di Explore.
            </p>
            <Link
              href={ROUTES.explore}
              className="mt-4 inline-flex rounded-full bg-violet-600 px-5 py-2.5 text-[13.5px] font-semibold text-white transition-colors hover:bg-violet-700"
            >
              Jelajahi profesi
            </Link>
          </div>
        ) : (
          <>
            <section className="mt-5 overflow-hidden rounded-2xl bg-violet-50">
              <Image
                src={heroTahap(tahap.stage_code)}
                alt=""
                width={1916}
                height={732}
                sizes="(min-width: 42rem) 42rem, 100vw"
                priority
                className="h-auto w-full"
              />
              <div className="px-4 pb-5 pt-4">
                <span className="inline-flex items-center rounded-full bg-violet-600 px-3 py-1 text-[12px] font-semibold text-white">
                  Tahap {tahap.stage_order} • {tahap.persen}%
                </span>
                <h2 className="mt-2.5 text-[20px] font-bold tracking-tight text-violet-700">
                  {tahap.nama}
                </h2>
                <p className="mt-1.5 text-[14px] leading-relaxed text-slate-600">{tahap.hero}</p>
              </div>
            </section>

            {daftar.length > 1 && (
              <nav aria-label="Pilih tahap" className="mt-4 flex gap-2 overflow-x-auto pb-1">
                {daftar.map((t) => {
                  const on = t.kode === tahap.stage_code;
                  const kunci = t.status === "TERKUNCI";
                  return (
                    <button
                      key={t.kode}
                      type="button"
                      disabled={kunci}
                      onClick={() => setPilih(t.kode)}
                      aria-current={on ? "page" : undefined}
                      className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-3.5 py-2 text-[12.5px] font-medium transition-colors ${
                        on
                          ? "bg-violet-600 text-white"
                          : kunci
                            ? "bg-slate-100 text-slate-400"
                            : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                      }`}
                    >
                      {kunci && <Lock className="size-3.5" aria-hidden />}
                      {t.urutan}. {t.nama}
                    </button>
                  );
                })}
              </nav>
            )}

            <IsiTahap tahap={tahap} />
          </>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}
