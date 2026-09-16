"use client";

/**
 * Layar Roadmap.
 *
 * Dua tab di atas satu kartu profesi: "Persiapan" (lima tahap menuju profesi)
 * dan "Jalur Pendidikan" (rute sekolah dan kuliahnya). Keduanya berbicara
 * tentang profesi yang sama, jadi kartu ungunya tidak ikut berganti.
 *
 * Data jalur baru diambil saat tabnya dibuka pertama kali, lalu disimpan di
 * state — berpindah tab bolak-balik tidak menembak jaringan berulang kali.
 *
 * Desain tim desainer masih berhenti di ponsel. Di layar lebar isinya dikunci
 * pada satu kolom yang ditengahkan, bukan direntangkan: merentangkan tabel
 * langkah selebar 1440px hanya membuat status dan judulnya berjauhan.
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import JalurPendidikan from "@/components/roadmap/JalurPendidikan";
import KartuProfesi from "@/components/roadmap/KartuProfesi";
import TahapPersiapan from "@/components/roadmap/TahapPersiapan";
import TabSwitch from "@/components/profesi/TabSwitch";
import {
  ambilJalur,
  ambilRoadmapState,
  batalkanJalur,
  simpanJalur,
  type Jalur,
  type RoadmapState,
} from "@/lib/roadmapJourney";
import { ROUTES } from "@/lib/routes";

type TabKode = "persiapan" | "jalur";

const TABS = [
  { kode: "persiapan" as const, label: "Persiapan" },
  { kode: "jalur" as const, label: "Jalur Pendidikan" },
];

export default function RoadmapView() {
  const [state, setState] = useState<RoadmapState | null>(null);
  const [jalur, setJalur] = useState<Jalur[] | null>(null);
  const [tab, setTab] = useState<TabKode>("persiapan");
  const [muat, setMuat] = useState(true);
  const [sibuk, setSibuk] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => {
    let batal = false;
    (async () => {
      try {
        const s = await ambilRoadmapState();
        if (!batal) setState(s);
      } catch {
        if (!batal) setGalat("Gagal memuat roadmap. Coba muat ulang halaman.");
      } finally {
        if (!batal) setMuat(false);
      }
    })();
    return () => {
      batal = true;
    };
  }, []);

  const careerId = state?.career_id ?? null;

  const muatJalur = useCallback(async () => {
    if (!careerId) return;
    try {
      setJalur(await ambilJalur(careerId));
    } catch {
      setGalat("Gagal memuat jalur pendidikan.");
    }
  }, [careerId]);

  useEffect(() => {
    if (tab === "jalur" && jalur === null) void muatJalur();
  }, [tab, jalur, muatJalur]);

  async function pilih(pathId: number) {
    if (!careerId) return;
    setSibuk(true);
    try {
      await simpanJalur(careerId, pathId);
      await muatJalur();
    } catch {
      setGalat("Pilihan jalur gagal disimpan.");
    } finally {
      setSibuk(false);
    }
  }

  async function ubah() {
    if (!careerId) return;
    setSibuk(true);
    try {
      await batalkanJalur(careerId);
      await muatJalur();
    } catch {
      setGalat("Gagal mengubah jalur.");
    } finally {
      setSibuk(false);
    }
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-10 pt-6 sm:px-6 lg:py-8">
        <h1 className="text-[30px] font-bold tracking-tight text-slate-900">Roadmap</h1>
        <p className="mt-1 text-[14px] text-slate-500">Peta Jalan Kariermu</p>

        {galat && (
          <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galat}</p>
        )}

        {muat ? (
          <div className="mt-5 space-y-4" aria-busy>
            <div className="h-36 animate-pulse rounded-2xl bg-slate-100" />
            <div className="h-10 w-64 animate-pulse rounded-full bg-slate-100" />
            <div className="h-64 animate-pulse rounded-2xl bg-slate-100" />
          </div>
        ) : !state?.has_career || !careerId ? (
          <div className="mt-8 rounded-2xl border border-slate-200 bg-white px-5 py-8 text-center">
            <h2 className="text-[16px] font-bold text-slate-900">Belum ada profesi pilihan</h2>
            <p className="mx-auto mt-2 max-w-sm text-[13.5px] leading-relaxed text-slate-500">
              Roadmap disusun mengikuti satu profesi tujuan. Pilih profesinya dulu di Explore,
              lalu peta jalannya muncul di sini.
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
            <div className="mt-5">
              <KartuProfesi
                careerId={careerId}
                careerName={state.career_name ?? "Profesi pilihan"}
                totalXp={state.total_xp}
                levelName={state.level_name}
                minXp={state.min_xp}
                nextXp={state.next_xp}
              />
            </div>

            <div className="mt-5">
              <TabSwitch tabs={TABS} aktif={tab} onPilih={setTab} />
            </div>

            <div className="mt-6">
              {tab === "persiapan" ? (
                <TahapPersiapan tahap={state.tahap ?? []} />
              ) : jalur === null ? (
                <div className="h-64 animate-pulse rounded-2xl bg-slate-100" aria-busy />
              ) : (
                <JalurPendidikan jalur={jalur} sibuk={sibuk} onPilih={pilih} onUbah={ubah} />
              )}
            </div>
          </>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}
