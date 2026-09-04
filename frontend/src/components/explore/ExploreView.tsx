"use client";

/**
 * Tampilan Explore.
 *
 * Dipisah dari halamannya supaya bagian yang menggambar tidak ikut memikirkan
 * autentikasi dan pengambilan data — dan supaya harness verifikasi bisa
 * menyuapkan data apa adanya ke komponen yang sama dengan yang dipakai
 * produksi, bukan ke tiruannya.
 *
 * Empat tampilan ditentukan dua hal saja: sudah memilih profesi atau belum,
 * dan sudah mengisi Career DNA atau belum.
 *
 *   belum keduanya   Career Discovery + paling diminati + program studi
 *   profesi saja     kartu journey + ajakan Career DNA + dua baris yang sama
 *   DNA saja         persentase match + profesi dari atribut aktivitas
 *   sudah keduanya   kartu journey + quest minggu ini + dua dari empat baris
 */

import { useMemo } from "react";
import type {
  CareerCard as CardData,
  ExploreState,
  ScoredCard,
  WeeklyQuest,
} from "@/lib/explore";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import CardRow from "@/components/explore/CardRow";
import CareerCard from "@/components/explore/CareerCard";
import GreetingHeader from "@/components/explore/GreetingHeader";
import JourneyCard from "@/components/explore/JourneyCard";
import PromoBanner from "@/components/explore/PromoBanner";
import QuestWeek from "@/components/explore/QuestWeek";

export type BarisKode = "demand" | "study" | "match" | "activity";

export type ExploreData = {
  state: ExploreState;
  demand: CardData[];
  study: ScoredCard[];
  match: ScoredCard[];
  activity: ScoredCard[];
  quests: WeeklyQuest[];
};

/**
 * Baris mana yang perlu diambil untuk sebuah keadaan.
 *
 * Dipakai halaman sebelum menembak jaringan, supaya pengguna yang belum
 * mengisi DNA tidak membayar dua query pencocokan yang sudah pasti kosong.
 */
export function barisDibutuhkan(state: ExploreState): Set<BarisKode> {
  if (!state.has_dna) return new Set<BarisKode>(["demand", "study"]);
  if (!state.has_career) return new Set<BarisKode>(["match", "activity"]);
  return new Set<BarisKode>(["demand", "study", "match", "activity"]);
}

/**
 * Dua dari empat baris — permintaan tim desain untuk keadaan terakhir.
 *
 * Seed-nya tanggal ditambah profesi yang dituju, bukan Math.random(): kalau
 * acaknya benar-benar acak, isinya berganti tiap kali komponen ini dirender
 * ulang dan pengguna melihat baris berganti sendiri saat menggulir.
 */
export function pilihDuaBaris(seed: number, hariEpoch?: number): BarisKode[] {
  const semua: BarisKode[] = ["demand", "study", "match", "activity"];
  const hari = hariEpoch ?? Math.floor(Date.now() / 86_400_000);
  const a = (hari + seed) % semua.length;
  const b = (a + 1 + ((hari + seed) % (semua.length - 1))) % semua.length;
  return [semua[a], semua[b]];
}

export default function ExploreView({
  data,
  hariEpoch,
}: {
  data: ExploreData;
  /** Hanya diisi oleh harness verifikasi supaya pilihan barisnya bisa ditebak. */
  hariEpoch?: number;
}) {
  const { state, demand, study, match, activity, quests } = data;

  const barisTerpilih = useMemo<BarisKode[]>(() => {
    if (state.has_dna && state.has_career) {
      return pilihDuaBaris(state.career_id ?? 0, hariEpoch);
    }
    if (state.has_dna) return ["match", "activity"];
    return ["demand", "study"];
  }, [state, hariEpoch]);

  const baris: Record<BarisKode, React.ReactNode> = {
    demand: (
      <CardRow
        key="demand"
        title="Paling Diminati tahun ini 🔥"
        href="/explore/daftar/paling-diminati"
        isEmpty={demand.length === 0}
        emptyLabel="Data permintaan pasar belum tersedia."
      >
        {demand.map((c) => (
          <CareerCard key={c.career_id} card={c} />
        ))}
      </CardRow>
    ),
    study: (
      <CardRow
        key="study"
        title="Relevan dengan Program Studi"
        subtitle={
          state.study_label
            ? `Berdasarkan program studi “${state.study_label}” yang Kamu ambil`
            : "Lengkapi program studi di profil untuk melihat baris ini"
        }
        href="/explore/daftar/program-studi"
        isEmpty={study.length === 0}
        emptyLabel="Program studimu belum terisi di profil, jadi belum ada profesi yang bisa dicocokkan."
      >
        {study.map((c) => (
          <CareerCard key={c.career_id} card={c} />
        ))}
      </CardRow>
    ),
    match: (
      <CardRow
        key="match"
        title="Persentase Match Profesi"
        subtitle="Berdasarkan nilai tingkat kecocokan profil dengan profesi"
        href="/explore/daftar/match"
        isEmpty={match.length === 0}
        emptyLabel="Career DNA-mu belum terisi, jadi skor kecocokan belum bisa dihitung."
      >
        {match.map((c) => (
          <CareerCard key={c.career_id} card={c} showDescription={false} showScore />
        ))}
      </CardRow>
    ),
    activity: (
      <CardRow
        key="activity"
        title="Dari Aktivitas Pilihan"
        subtitle={
          state.top_activity
            ? `Berdasarkan aktivitas “${state.top_activity}” pilihan Kamu`
            : "Berdasarkan aktivitas yang kamu pilih di Career DNA"
        }
        href="/explore/daftar/aktivitas"
        isEmpty={activity.length === 0}
        emptyLabel="Belum ada aktivitas yang kamu pilih di Career DNA."
      >
        {activity.map((c) => (
          <CareerCard key={c.career_id} card={c} showDescription={false} showAttributes showScore />
        ))}
      </CardRow>
    ),
  };

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <div className="mx-auto flex w-full max-w-[1440px] flex-1 flex-col lg:flex-row lg:items-start lg:gap-8 lg:px-8 lg:py-8">
        {/* Blok atas: pita abu-abu selebar layar di ponsel, kolom kiri yang
            menempel saat digulir di desktop. */}
        <div className="bg-[#E7EAF2] px-4 py-5 sm:px-6 lg:sticky lg:top-24 lg:w-[380px] lg:shrink-0 lg:rounded-2xl lg:px-5">
          <div className="flex flex-col gap-4">
            <GreetingHeader name={state.full_name} />
            {state.has_career && state.career_name ? (
              <JourneyCard
                careerName={state.career_name}
                percent={Math.round(Number(state.percent_done ?? 0))}
                href="/roadmap"
              />
            ) : (
              !state.has_dna && <PromoBanner variant="discovery" href="/career-dna" priority />
            )}
            {state.has_career && !state.has_dna && (
              <PromoBanner variant="dna" href="/career-dna" />
            )}
            {/* Di desktop banner ini menutup kolom kiri, sesuai mockup. Di layar
                sempit ia pindah ke ujung bawah isi supaya tidak menyela deretan
                kartu di paruh atas layar. */}
            <PromoBanner variant="insights" href="/career-insights" className="hidden lg:block" />
          </div>
        </div>

        <main className="min-w-0 flex-1">
          {state.has_career && quests.length > 0 && (
            <QuestWeek quests={quests} total={quests.length + 5} />
          )}
          {barisTerpilih.map((k) => baris[k])}
          <div className="px-4 pb-8 pt-2 sm:px-6 lg:hidden">
            <PromoBanner variant="insights" href="/career-insights" />
          </div>
        </main>
      </div>

      <AppBottomNav />
    </div>
  );
}
