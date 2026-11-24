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
 * status terkuncinya. Tahap yang masih terkunci tetap bisa dibuka untuk dilihat
 * isinya — Journey itu layar "apa yang perlu Kamu ketahui", dan melihat apa
 * yang menunggu di depan tidak merugikan siapa pun. Yang tetap terkunci adalah
 * quest-nya: itu dijaga database di layar Quest, bukan di sini.
 *
 * Usability test November 2026: kelima partisipan bingung ke mana harus pergi
 * dari Journey ke Quest — layar ini tidak punya satu tombol pun ke sana.
 * Sekarang ada kartu "Langkah berikutnya" tepat di bawah hero dan tombol
 * penutup di kaki halaman, keduanya menuju grup quest yang terbuka untuk
 * tahap ini (dari quest_beranda). Kartu soft skill, hard skill, dan tools juga
 * menaut langsung ke quest-nya masing-masing (lihat IsiTahap).
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowRight, Lock, ScrollText } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import IsiTahap from "@/components/journey/IsiTahap";
import {
  ambilJourneyStage,
  ambilRoadmapState,
  heroTahap,
  type JourneyStage,
  type RoadmapState,
} from "@/lib/roadmapJourney";
import { ambilBeranda, type JenisGrup, type QuestBeranda } from "@/lib/quest";
import { ROUTES, questGrupPath } from "@/lib/routes";

/** Jenis quest per tahap Journey; sama dengan quest_group_kinds.stage_code. */
const JENIS_TAHAP: Record<string, JenisGrup[]> = {
  EKSPLORASI: ["EKSPLORASI"],
  PONDASI: ["SOFT_SKILL"],
  KEAHLIAN: ["HARD_SKILL", "TOOL"],
  PENGALAMAN: ["PENGALAMAN"],
  BERKARIER: ["BERKARIER"],
};

type TujuanQuest = { href: string; judul: string; isi: string; tombol: string };

/**
 * Ke mana tombol quest di Journey mengarah.
 *
 *   tahap punya grup terbuka   -> grup itu ("Kerjakan quest Komunikasi")
 *   tahap masih terkunci       -> grup terbuka pertama di tahap lain, dengan
 *                                 penjelasan kenapa harus ke sana dulu
 *   semuanya selesai           -> layar Quest
 */
function tujuanQuest(stage: string, terkunci: boolean, b: QuestBeranda | null): TujuanQuest {
  const jenis = JENIS_TAHAP[stage] ?? [];
  const grup = b?.grup.find((x) => jenis.includes(x.jenis));
  if (grup) {
    const sisa = Math.max(grup.n_quest - grup.n_selesai, 0);
    return {
      href: questGrupPath(grup.slug, grup.kode),
      judul: sisa > 0 ? `Kerjakan ${sisa} quest di tahap ini` : "Lanjutkan quest tahap ini",
      isi: `Mulai dari ${grup.label}: ${grup.judul}. Quest-nya yang membuka tahap berikutnya.`,
      tombol: "Mulai Quest",
    };
  }
  const lain = b?.grup[0];
  if (terkunci && lain) {
    return {
      href: questGrupPath(lain.slug, lain.kode),
      judul: "Selesaikan quest tahap sebelumnya dulu",
      isi: `Quest tahap ini terbuka setelah ${lain.label} dikerjakan. Ayo lanjutkan dari sana.`,
      tombol: `Kerjakan ${lain.label}`,
    };
  }
  return {
    href: ROUTES.quest,
    judul: b?.semua_selesai ? "Semua quest sudah selesai 🎉" : "Lihat semua quest",
    isi: "Daftar quest yang perlu kamu kerjakan ada di layar Quest.",
    tombol: "Buka Quest",
  };
}

function KartuLangkah({ t }: { t: TujuanQuest }) {
  return (
    <Link
      href={t.href}
      className="mt-4 flex items-center gap-3.5 rounded-2xl bg-violet-600 px-4 py-4 text-white shadow-sm transition-colors hover:bg-violet-700"
    >
      <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-white/15">
        <ScrollText className="size-5" aria-hidden />
      </span>
      <span className="min-w-0 flex-1 leading-tight">
        <span className="block text-[12px] font-medium text-violet-100">Langkah berikutnya</span>
        <span className="mt-0.5 block text-[15.5px] font-bold">{t.judul}</span>
        <span className="mt-1 block text-[12.5px] leading-snug text-violet-100">{t.isi}</span>
      </span>
      <span className="hidden shrink-0 items-center gap-1.5 rounded-full bg-white px-3.5 py-2 text-[13px] font-semibold text-violet-700 sm:inline-flex">
        {t.tombol}
        <ArrowRight className="size-4" aria-hidden />
      </span>
      <ArrowRight className="size-5 shrink-0 sm:hidden" aria-hidden />
    </Link>
  );
}

export default function JourneyView() {
  const params = useSearchParams();
  const diminta = params.get("tahap") ?? undefined;

  const [state, setState] = useState<RoadmapState | null>(null);
  const [beranda, setBeranda] = useState<QuestBeranda | null>(null);
  const [tahap, setTahap] = useState<JourneyStage | null>(null);
  const [pilih, setPilih] = useState<string | undefined>(diminta);
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => setPilih(diminta), [diminta]);

  // Grup quest yang terbuka, untuk tombol "Mulai Quest". Gagal memuat tidak
  // menghalangi Journey: tombolnya jatuh ke layar Quest.
  useEffect(() => {
    let batal = false;
    ambilBeranda()
      .then((b) => {
        if (!batal) setBeranda(b);
      })
      .catch(() => {});
    return () => {
      batal = true;
    };
  }, []);

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
  const terkunci = daftar.find((t) => t.kode === tahap?.stage_code)?.status === "TERKUNCI";
  const tujuan = tahap ? tujuanQuest(tahap.stage_code, terkunci, beranda) : null;

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      {/* Desktop (lg): dua kolom — hero, pemilih tahap, dan langkah berikutnya
          menempel di kiri; isi tahap di kanan. Ponsel dan tablet tetap satu
          kolom seperti desain. */}
      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-10 pt-6 sm:px-6 lg:max-w-6xl lg:px-8 lg:py-8">
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
          <div className="lg:grid lg:grid-cols-[minmax(0,440px)_minmax(0,1fr)] lg:items-start lg:gap-10">
            <div className="lg:sticky lg:top-24">
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
                <nav aria-label="Pilih tahap" className="mt-4 flex gap-2 overflow-x-auto pb-1 lg:flex-wrap lg:overflow-visible">
                  {daftar.map((t) => {
                    const on = t.kode === tahap.stage_code;
                    const kunci = t.status === "TERKUNCI";
                    return (
                      <button
                        key={t.kode}
                        type="button"
                        onClick={() => setPilih(t.kode)}
                        aria-current={on ? "page" : undefined}
                        className={`inline-flex shrink-0 items-center gap-1.5 rounded-full px-3.5 py-2 text-[12.5px] font-medium transition-colors ${
                          on
                            ? "bg-violet-600 text-white"
                            : kunci
                              ? "bg-slate-100 text-slate-400 hover:bg-slate-200"
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

              {tujuan && <KartuLangkah t={tujuan} />}

              {terkunci && (
                <p className="mt-4 flex items-start gap-2 rounded-xl bg-slate-100 px-4 py-3 text-[13px] leading-relaxed text-slate-600">
                  <Lock className="mt-0.5 size-4 shrink-0" aria-hidden />
                  Tahap ini masih terkunci. Isinya bisa Kamu lihat dulu, tapi quest-nya baru terbuka
                  setelah quest di tahap sebelumnya dikerjakan.
                </p>
              )}
            </div>

            <div className="min-w-0 lg:pt-5">
              <IsiTahap tahap={tahap} terkunci={terkunci} />

              {tujuan && (
                <Link
                  href={tujuan.href}
                  className="mt-6 flex w-full items-center justify-center gap-2 rounded-full bg-violet-600 py-3.5 text-[15px] font-semibold text-white transition-colors hover:bg-violet-700"
                >
                  {tujuan.tombol}
                  <ArrowRight className="size-4" aria-hidden />
                </Link>
              )}
            </div>
          </div>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}
