"use client";

/**
 * Explore — layar utama setelah masuk.
 *
 * Halaman ini hanya mengurus dua hal: mengambil data seperlunya dan
 * menyerahkannya ke ExploreView. Pemeriksaan sesi dan onboarding diserahkan ke
 * RequireAuth, yang dipakai seluruh layar aplikasi.
 *
 * Yang menentukan tampilan mana yang muncul adalah `explore_state()` — satu
 * sumber kebenaran; jangan menyimpulkannya dari data lain, karena dua sumber
 * untuk hal yang sama adalah cara tercepat membuat layar ini salah tampil.
 */

import { useCallback, useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import {
  getByActivity,
  getByMatch,
  getByStudy,
  getExploreState,
  getTopDemand,
  getWeeklyQuests,
} from "@/lib/explore";
import RequireAuth from "@/components/RequireAuth";
import { ambilRoadmapState } from "@/lib/roadmapJourney";
import ExploreView, {
  barisDibutuhkan,
  type ExploreData,
} from "@/components/explore/ExploreView";

function ExploreIsi() {
  const [memuat, setMemuat] = useState(true);
  const [data, setData] = useState<ExploreData | null>(null);

  const muat = useCallback(async () => {
    const state = await getExploreState();
    if (!state) {
      setData(null);
      setMemuat(false);
      return;
    }

    const perlu = barisDibutuhkan(state);
    const [demand, study, match, activity, quests, roadmap] = await Promise.all([
      perlu.has("demand") ? getTopDemand(12) : Promise.resolve([]),
      perlu.has("study") ? getByStudy(12) : Promise.resolve([]),
      perlu.has("match") ? getByMatch(12) : Promise.resolve([]),
      perlu.has("activity") ? getByActivity(12) : Promise.resolve([]),
      state.has_career ? getWeeklyQuests(3) : Promise.resolve([]),
      // Gambar kartu profesi mengikuti tahap Journey yang sedang berjalan:
      // tahap pertama yang belum selesai, sama dengan yang dibuka Journey.
      state.has_career ? ambilRoadmapState().catch(() => null) : Promise.resolve(null),
    ]);
    const tahap = roadmap?.tahap.find((t) => t.status !== "SELESAI")?.kode ?? null;

    setData({ state, demand, study, match, activity, quests, tahap });
    setMemuat(false);
  }, []);

  useEffect(() => {
    void muat();
  }, [muat]);

  if (memuat) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
        <p className="text-[12px] font-semibold text-slate-500">Menyiapkan Explore…</p>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 px-6 text-center">
        <p className="text-[15px] font-semibold text-slate-900">Explore belum bisa dimuat</p>
        <p className="max-w-sm text-[13px] text-slate-500">
          Profilmu belum terbaca. Coba muat ulang halaman; kalau masih sama, selesaikan dulu
          onboarding-nya.
        </p>
        <button
          onClick={() => {
            setMemuat(true);
            void muat();
          }}
          className="mt-1 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
        >
          Coba lagi
        </button>
      </div>
    );
  }

  return <ExploreView data={data} />;
}

export default function ExplorePage() {
  return (
    <RequireAuth pesan="Menyiapkan Explore…">
      <ExploreIsi />
    </RequireAuth>
  );
}
