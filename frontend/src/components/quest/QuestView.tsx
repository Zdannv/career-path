"use client";

/**
 * Layar Quest: "Apa yang perlu Kamu kerjakan minggu ini".
 *
 * Satu kartu per jenis quest yang sudah terbuka — grup pertama yang masih
 * punya quest belum selesai. Karena itu daftarnya pendek dan bergeser seiring
 * kemajuan: mula-mula hanya Eksplorasi Karier, lalu Soft Skill, lalu Hard
 * Skill dan Tools menyusul, dan seterusnya. Pemilihannya dilakukan database
 * (quest_beranda), layar ini hanya menggambar.
 *
 * Selama Eksplorasi belum selesai, hero-nya banner "Selesaikan quest untuk
 * unlock stage berikutnya" seperti desain A01; setelahnya ilustrasi biasa.
 *
 * Di bawahnya ada pratinjau "Quest berikutnya": jenis yang masih terkunci,
 * berapa quest-nya, dan apa syarat membukanya. Ini tambahan di luar desain —
 * tanpa itu pengguna baru hanya melihat dua quest Eksplorasi dan mengira
 * isinya memang cuma dua.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { ArrowUpRight, Lock, NotepadText } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import IkonGrup from "@/components/quest/IkonGrup";
import TipsBanner from "@/components/quest/TipsBanner";
import { ambilBeranda, type JenisTerkunci, type KartuGrup, type QuestBeranda } from "@/lib/quest";
import { ROUTES, questGrupPath } from "@/lib/routes";

function Kartu({ g }: { g: KartuGrup }) {
  // Eksplorasi tidak punya ubin ikon di desain A01.
  const berikon = g.jenis !== "EKSPLORASI";
  return (
    <li>
      <article className="flex gap-3.5 rounded-2xl bg-[#FAFAFA] p-3.5">
        {berikon && <IkonGrup ikon={g.ikon} tone={g.tone} />}
        <div className="min-w-0 flex-1">
          <p className="text-[12.5px] font-medium text-violet-600">{g.label}</p>
          <h2 className="mt-0.5 text-[16.5px] font-semibold leading-snug text-slate-900">{g.judul}</h2>
          {g.subjudul && (
            <p className="mt-0.5 text-[13.5px] text-slate-500">(Sub-skills) {g.subjudul}</p>
          )}
          <div className="mt-3 flex items-center justify-between gap-3">
            <p className="flex items-center gap-1.5 text-[13.5px] text-slate-600">
              <NotepadText className="size-4" aria-hidden />
              {g.n_quest} Quest
              {g.n_selesai > 0 && (
                <span className="text-slate-400">· {g.n_selesai} selesai</span>
              )}
            </p>
            <Link
              href={questGrupPath(g.slug, g.kode)}
              className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3.5 py-1.5 text-[12.5px] font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50"
            >
              Tampilkan Quest
              <ArrowUpRight className="size-3.5" aria-hidden />
            </Link>
          </div>
        </div>
      </article>
    </li>
  );
}

function KartuTerkunci({ j }: { j: JenisTerkunci }) {
  const satuan = j.n_grup > 1 ? ` dari ${j.n_grup} ${j.label.toLowerCase()}` : "";
  return (
    <li className="flex gap-3.5 rounded-2xl border border-dashed border-slate-200 p-3.5">
      <span className="opacity-50 grayscale">
        <IkonGrup ikon={j.ikon} tone={j.tone} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="text-[12.5px] font-medium text-slate-400">Tahap {j.tahap}</p>
        <h3 className="mt-0.5 text-[15.5px] font-semibold text-slate-500">
          {j.label} · {j.n_quest} Quest{satuan}
        </h3>
        {j.alasan && (
          <p className="mt-1.5 flex items-start gap-1.5 text-[12.5px] leading-snug text-slate-500">
            <Lock className="mt-0.5 size-3.5 shrink-0" aria-hidden />
            {j.alasan}
          </p>
        )}
      </div>
    </li>
  );
}

export default function QuestView() {
  const [data, setData] = useState<QuestBeranda | null>(null);
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => {
    let batal = false;
    ambilBeranda()
      .then((d) => {
        if (!batal) setData(d);
      })
      .catch(() => {
        if (!batal) setGalat("Gagal memuat quest. Coba muat ulang halaman.");
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
        <h1 className="text-[30px] font-bold tracking-tight text-slate-900">Quest</h1>
        <p className="mt-1 text-[14px] text-slate-500">Apa yang perlu Kamu kerjakan minggu ini</p>

        {galat && (
          <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galat}</p>
        )}

        {muat ? (
          <div className="mt-5 space-y-4" aria-busy>
            <div className="h-32 animate-pulse rounded-[20px] bg-slate-100" />
            <div className="h-28 animate-pulse rounded-2xl bg-slate-100" />
            <div className="h-28 animate-pulse rounded-2xl bg-slate-100" />
          </div>
        ) : !data?.has_career ? (
          !galat && (
            <div className="mt-8 rounded-2xl border border-slate-200 bg-white px-5 py-8 text-center">
              <h2 className="text-[16px] font-bold text-slate-900">Quest belum bisa dimulai</h2>
              <p className="mx-auto mt-2 max-w-sm text-[13.5px] leading-relaxed text-slate-500">
                Quest menyesuaikan profesi yang Kamu tuju. Pilih profesinya dulu di Explore.
              </p>
              <Link
                href={ROUTES.explore}
                className="mt-4 inline-flex rounded-full bg-violet-600 px-5 py-2.5 text-[13.5px] font-semibold text-white transition-colors hover:bg-violet-700"
              >
                Jelajahi profesi
              </Link>
            </div>
          )
        ) : (
          <>
            <div className="mt-5">
              {data.eksplorasi_selesai ? (
                <Image
                  src="/quest/header.jpg"
                  alt=""
                  width={1916}
                  height={732}
                  sizes="(min-width: 42rem) 42rem, 100vw"
                  priority
                  className="h-auto w-full rounded-[20px]"
                />
              ) : (
                <TipsBanner
                  besar={false}
                  tips={{
                    gambar: "WHATS_NEXT",
                    label: "Tips Navika",
                    judul: "Selesaikan quest untuk unlock stage berikutnya",
                    isi: null,
                    sumber: false,
                  }}
                />
              )}
            </div>

            {data.semua_selesai ? (
              <div className="mt-6 rounded-2xl bg-emerald-50 px-5 py-6 text-center">
                <h2 className="text-[16px] font-bold text-emerald-800">Semua quest sudah selesai 🎉</h2>
                <p className="mx-auto mt-1.5 max-w-sm text-[13.5px] leading-relaxed text-emerald-700">
                  Kamu sudah menuntaskan seluruh quest untuk {data.career_name}. Lihat perjalananmu di
                  Roadmap.
                </p>
              </div>
            ) : (
              <ul className="mt-5 space-y-3">
                {data.grup.map((g) => (
                  <Kartu key={`${g.jenis}:${g.kode}`} g={g} />
                ))}
              </ul>
            )}

            {data.terkunci.length > 0 && (
              <section className="mt-8">
                <h2 className="text-[16px] font-bold tracking-tight text-slate-900">Quest berikutnya</h2>
                <p className="mt-0.5 text-[13px] text-slate-500">
                  {data.terkunci.reduce((n, j) => n + j.n_quest, 0)} quest lagi terbuka bertahap
                  seiring progresmu.
                </p>
                <ul className="mt-3 space-y-2.5">
                  {data.terkunci.map((j) => (
                    <KartuTerkunci key={j.jenis} j={j} />
                  ))}
                </ul>
              </section>
            )}
          </>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}
