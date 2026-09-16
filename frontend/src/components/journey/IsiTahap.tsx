"use client";

/**
 * Isi tengah layar Journey. Bentuknya berbeda tiap tahap:
 *
 *   TOPIK        daftar ikon + judul + penjelasan (tahap Eksplorasi)
 *   SOFT_SKILL   kartu berikon warna dengan "3 Quest" dan lembar detail
 *   SKILL_TOOLS  dua tab, hard skill dan tools, dalam tabel berstatus
 *   KEGIATAN     daftar kegiatan yang bisa ditempuh (tahap Pengalaman)
 *   NONE         tidak ada isi; tahap terakhir hanya hero dan kotak hasil
 *
 * Yang membedakan hanya penyajian — semua datanya sudah dirakit RPC
 * journey_stage(), termasuk statusnya, jadi komponen ini tidak menghitung apa
 * pun sendiri.
 */

import { useState } from "react";
import { ArrowUpRight, Check, ScrollText } from "lucide-react";
import HasilBox from "@/components/journey/HasilBox";
import Ikon from "@/components/journey/Ikon";
import Sheet from "@/components/profesi/Sheet";
import StatusPill from "@/components/roadmap/StatusPill";
import TabSwitch from "@/components/profesi/TabSwitch";
import type {
  ItemSkill,
  ItemSoftSkill,
  ItemTopik,
  JourneyStage,
  KontenSkillTools,
} from "@/lib/roadmapJourney";

// ── tahap 1 dan 4: daftar sederhana ─────────────────────────────────────────

function DaftarTopik({ items }: { items: ItemTopik[] }) {
  return (
    <ul className="divide-y divide-slate-100">
      {items.map((t) => (
        <li key={t.kode} className="py-4 first:pt-0">
          <div className="flex items-center gap-2.5">
            <Ikon nama={t.ikon} className="size-5 shrink-0 text-violet-600" />
            <h3 className="text-[15.5px] font-bold text-slate-900">{t.judul}</h3>
          </div>
          <p className="mt-1.5 text-[13.5px] leading-relaxed text-slate-500">{t.isi}</p>
        </li>
      ))}
    </ul>
  );
}

// ── tahap 2: kartu soft skill ───────────────────────────────────────────────

const TONE: Record<string, string> = {
  biru: "bg-sky-100 text-sky-600",
  hijau: "bg-emerald-100 text-emerald-600",
  ungu: "bg-violet-100 text-violet-600",
  oranye: "bg-orange-100 text-orange-600",
  kuning: "bg-amber-100 text-amber-600",
  merah: "bg-rose-100 text-rose-600",
};

function KartuSoftSkill({
  item,
  onDetail,
}: {
  item: ItemSoftSkill;
  onDetail: () => void;
}) {
  return (
    <article className="flex gap-3.5 border-b border-slate-100 py-4 last:border-b-0">
      <span
        className={`grid size-11 shrink-0 place-items-center rounded-xl ${
          TONE[item.tone] ?? TONE.ungu
        }`}
      >
        <Ikon nama={item.ikon} className="size-5" />
      </span>

      <div className="min-w-0 flex-1">
        <h3 className="text-[15.5px] font-bold text-slate-900">{item.judul}</h3>
        <p className="mt-1 text-[13.5px] leading-relaxed text-slate-500">{item.isi}</p>

        <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
          <span className="inline-flex items-center gap-1.5 text-[13px] font-medium text-slate-600">
            <ScrollText className="size-4 text-violet-500" aria-hidden />
            {item.n_quest} Quest
          </span>
          <button
            type="button"
            onClick={onDetail}
            className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 px-3.5 py-2 text-[13px] font-medium text-slate-700 transition-colors hover:bg-slate-50"
          >
            Tampilkan Detail
            <ArrowUpRight className="size-4" aria-hidden />
          </button>
        </div>
      </div>
    </article>
  );
}

// ── tahap 3: tabel hard skill dan tools ─────────────────────────────────────

function TabelSkill({ label, items }: { label: string; items: ItemSkill[] }) {
  if (!items.length) {
    return (
      <p className="rounded-xl bg-slate-50 px-4 py-5 text-center text-[13px] text-slate-500">
        Belum ada data {label.toLowerCase()} untuk profesi ini.
      </p>
    );
  }
  return (
    <div className="overflow-hidden rounded-xl border border-slate-200">
      <div className="flex items-center justify-between gap-3 bg-slate-100 px-4 py-2.5">
        <span className="text-[13.5px] font-semibold text-slate-700">{label}</span>
        <span className="text-[13.5px] font-semibold text-slate-700">Status</span>
      </div>
      <ul>
        {items.map((s) => (
          <li
            key={s.kode}
            className="flex items-start gap-3 border-b border-slate-100 px-4 py-3.5 last:border-b-0"
          >
            <div className="min-w-0 flex-1">
              <p className="text-[14px] font-semibold leading-snug text-slate-900">{s.judul}</p>
              {s.isi && (
                <p className="mt-0.5 text-[12.5px] leading-relaxed text-slate-500">{s.isi}</p>
              )}
            </div>
            <StatusPill status={s.status} />
          </li>
        ))}
      </ul>
    </div>
  );
}

function SkillDanTools({ konten }: { konten: KontenSkillTools }) {
  const [tab, setTab] = useState<"hard" | "tools">("hard");
  return (
    <div>
      <TabSwitch
        tabs={[
          { kode: "hard" as const, label: "Hard Skill" },
          { kode: "tools" as const, label: "Tools" },
        ]}
        aktif={tab}
        onPilih={setTab}
      />
      <div className="mt-4">
        {tab === "hard" ? (
          <TabelSkill label="Hard Skill" items={konten.hard_skill} />
        ) : (
          <TabelSkill label="Tools" items={konten.tools} />
        )}
      </div>
    </div>
  );
}

// ── penampung ───────────────────────────────────────────────────────────────

export default function IsiTahap({ tahap }: { tahap: JourneyStage }) {
  const [detail, setDetail] = useState<ItemSoftSkill | null>(null);

  return (
    <>
      <section className="mt-6">
        <h2 className="text-[19px] font-bold tracking-tight text-slate-900">
          Apa yang akan kamu pelajari?
        </h2>
        <p className="mt-1.5 text-[14.5px] leading-relaxed text-slate-700">{tahap.learn_intro}</p>

        <div className="mt-5">
          {tahap.content_kind === "TOPIK" && <DaftarTopik items={tahap.konten as ItemTopik[]} />}
          {tahap.content_kind === "KEGIATAN" && (
            <DaftarTopik items={tahap.konten as ItemTopik[]} />
          )}
          {tahap.content_kind === "SOFT_SKILL" &&
            (tahap.konten as ItemSoftSkill[]).map((s) => (
              <KartuSoftSkill key={s.kode} item={s} onDetail={() => setDetail(s)} />
            ))}
          {tahap.content_kind === "SKILL_TOOLS" && (
            <SkillDanTools konten={tahap.konten as KontenSkillTools} />
          )}
        </div>
      </section>

      <div className="mt-7">
        <HasilBox hasil={tahap.hasil} />
      </div>

      <Sheet buka={detail !== null} onTutup={() => setDetail(null)} judul={detail?.judul ?? ""}>
        <div className="px-4 pb-8 pt-4 sm:px-6">
          <p className="text-[14px] leading-relaxed text-slate-700">
            Apa yang akan Kamu pelajari dari quest yang diberikan Navika?
          </p>
          <ul className="mt-4 space-y-3.5">
            {(detail?.quest ?? []).map((q) => (
              <li key={q} className="flex items-start gap-2.5">
                <Check className="mt-0.5 size-4 shrink-0 text-slate-500" aria-hidden />
                <span className="text-[14px] leading-relaxed text-slate-800">{q}</span>
              </li>
            ))}
          </ul>
        </div>
      </Sheet>
    </>
  );
}
