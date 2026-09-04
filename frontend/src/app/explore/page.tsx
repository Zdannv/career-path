"use client";

/**
 * Explore — layar utama setelah masuk.
 *
 * Halaman ini hanya mengurus tiga hal: memastikan ada sesi, mengambil data
 * seperlunya, dan menyerahkannya ke ExploreView. Yang menentukan tampilan mana
 * yang muncul adalah `explore_state()` — satu sumber kebenaran; jangan
 * menyimpulkannya dari data lain, karena dua sumber untuk hal yang sama adalah
 * cara tercepat membuat layar ini salah tampil.
 */

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import type { User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";
import {
  getByActivity,
  getByMatch,
  getByStudy,
  getExploreState,
  getTopDemand,
  getWeeklyQuests,
} from "@/lib/explore";
import ExploreView, {
  barisDibutuhkan,
  type ExploreData,
} from "@/components/explore/ExploreView";

export default function ExplorePage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [memuat, setMemuat] = useState(true);
  const [data, setData] = useState<ExploreData | null>(null);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session?.user) {
        router.replace("/login");
        return;
      }
      setUser(session.user);
    });
  }, [router]);

  const muat = useCallback(async () => {
    const state = await getExploreState();
    if (!state) {
      setData(null);
      setMemuat(false);
      return;
    }

    const perlu = barisDibutuhkan(state);
    const [demand, study, match, activity, quests] = await Promise.all([
      perlu.has("demand") ? getTopDemand(12) : Promise.resolve([]),
      perlu.has("study") ? getByStudy(12) : Promise.resolve([]),
      perlu.has("match") ? getByMatch(12) : Promise.resolve([]),
      perlu.has("activity") ? getByActivity(12) : Promise.resolve([]),
      state.has_career ? getWeeklyQuests(3) : Promise.resolve([]),
    ]);

    setData({ state, demand, study, match, activity, quests });
    setMemuat(false);
  }, []);

  useEffect(() => {
    if (user) void muat();
  }, [user, muat]);

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
