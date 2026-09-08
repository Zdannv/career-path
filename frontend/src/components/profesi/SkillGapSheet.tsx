"use client";

/**
 * Lembar Skill Gap Analysis — tiga tab.
 *
 * Bedanya dengan tab Skill & Kompetensi: di sini isinya dibandingkan dengan
 * jawaban Career DNA pengguna, jadi soft skill terbelah menjadi yang sudah
 * sesuai dan yang perlu dikembangkan. Kalau DNA belum diisi, semuanya masuk
 * kelompok "perlu dikembangkan" — itu jujur, karena memang belum ada yang bisa
 * diklaim.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import { Dna, FolderCog, GraduationCap, Briefcase, Loader2 } from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import TabSwitch from "@/components/profesi/TabSwitch";
import { getSkillGap, type FaseKode, type SkillGap } from "@/lib/careerDetail";

type Tab = "hard" | "soft" | "tools";

const TABS = [
  { kode: "hard" as const, label: "Hard Skill" },
  { kode: "soft" as const, label: "Soft Skill" },
  { kode: "tools" as const, label: "Tools" },
];

const IKON_FASE: Record<FaseKode, typeof FolderCog> = {
  MANDIRI: FolderCog,
  MAGANG: GraduationCap,
  KERJA: Briefcase,
};

const JUDUL_LAYER: Record<string, string> = {
  ACTIVITY: "Atribut Aktivitas",
  SKILL: "Atribut Keahlian",
};

function SpandukNavika({ teks }: { teks: string }) {
  return (
    <div className="flex items-center gap-3 rounded-xl bg-indigo-50 px-3 py-3">
      <Image
        src="/profesi/navika-bot.png"
        alt=""
        width={80}
        height={80}
        className="size-14 shrink-0"
      />
      <p className="text-[13px] leading-relaxed text-violet-800">{teks}</p>
    </div>
  );
}

function ChipGrup({
  isi,
  nada,
}: {
  isi: Partial<Record<string, string[]>>;
  nada: "aktivitas" | "keahlian";
}) {
  const urut = ["ACTIVITY", "SKILL"].filter((l) => (isi[l]?.length ?? 0) > 0);
  if (urut.length === 0) {
    return (
      <p className="px-4 py-4 text-[12.5px] text-slate-500">
        Tidak ada atribut di kelompok ini.
      </p>
    );
  }
  return (
    <>
      {urut.map((layer) => (
        <div key={layer} className="border-t border-slate-200 px-4 py-3.5 first:border-t-0">
          <p className="text-[13.5px] font-semibold text-slate-900">{JUDUL_LAYER[layer]}</p>
          <ul className="mt-2 flex flex-wrap gap-1.5">
            {isi[layer]!.map((n) => (
              <li
                key={n}
                className={`rounded-md px-2.5 py-1.5 text-[12px] font-medium ${
                  layer === "ACTIVITY"
                    ? "bg-indigo-100 text-indigo-800"
                    : "bg-cyan-100 text-cyan-800"
                } ${nada === "aktivitas" ? "" : ""}`}
              >
                {n}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </>
  );
}

export default function SkillGapSheet({
  careerId,
  buka,
  onTutup,
  tabAwal = "hard",
  dataAwal = null,
}: {
  careerId: number;
  buka: boolean;
  onTutup: () => void;
  tabAwal?: Tab;
  /** Hanya diisi harness verifikasi; di produksi null dan diambil sendiri. */
  dataAwal?: SkillGap | null;
}) {
  const [tab, setTab] = useState<Tab>(tabAwal);
  const [data, setData] = useState<SkillGap | null>(dataAwal);
  const [memuat, setMemuat] = useState(false);

  useEffect(() => {
    if (buka) setTab(tabAwal);
  }, [buka, tabAwal]);

  useEffect(() => {
    if (!buka || data) return;
    setMemuat(true);
    void getSkillGap(careerId).then((d) => {
      setData(d);
      setMemuat(false);
    });
  }, [buka, careerId, data]);

  return (
    <Sheet buka={buka} onTutup={onTutup} judul="Skill Gap Analysis" penuh>
      <div className="mx-auto max-w-3xl px-4 pb-10 pt-4 sm:px-6">
        <TabSwitch tabs={TABS} aktif={tab} onPilih={setTab} />

        {memuat && (
          <div className="flex items-center gap-2 py-10 text-[13px] text-slate-500">
            <Loader2 className="size-4 animate-spin" aria-hidden />
            Menyiapkan analisis…
          </div>
        )}

        {!memuat && data && tab === "hard" && (
          <div className="mt-5">
            <h3 className="text-[19px] font-bold leading-snug text-slate-900">
              Kemampuan Teknis yang Perlu dipelajari
            </h3>
            <p className="mt-1.5 text-[13px] leading-relaxed text-slate-500">
              Kemampuan teknis dan kompetensi dalam menyelesaikan tugas operasional profesi ini.
            </p>
            <div className="mt-4">
              <SpandukNavika teks="Navika akan memandu Kamu dalam membangun pondasi hard skill yang dibutuhkan profesi ini." />
            </div>
            <ul className="mt-4">
              {data.hard_skill.map((s, i) => (
                <li key={i} className="border-b border-slate-200 py-3.5 last:border-b-0">
                  <p className="text-[14px] font-semibold leading-snug text-slate-900">{s.nama}</p>
                  <p className="mt-1 text-[12.5px] leading-relaxed text-slate-400">
                    {s.deskripsi}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        )}

        {!memuat && data && tab === "soft" && (
          <div className="mt-5">
            <h3 className="text-[19px] font-bold leading-snug text-slate-900">
              Kemampuan non-Teknis Profesi yang Perlu dikembangkan
            </h3>
            <p className="mt-1.5 text-[13px] leading-relaxed text-slate-500">
              Ketahui atribut soft skills yang perlu ditingkatkan agar sesuai dengan profesi ini.
            </p>

            <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200">
              <div className="flex items-start gap-2.5 bg-slate-50 px-4 py-3.5">
                <Dna className="mt-0.5 size-5 shrink-0 text-violet-600" aria-hidden />
                <p className="text-[13.5px] font-semibold leading-snug text-slate-900">
                  Soft Skill Kamu yang Sudah sesuai dengan Soft Skill Profesi
                </p>
              </div>
              <ChipGrup isi={data.soft_sesuai} nada="aktivitas" />
            </div>

            <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200">
              <div className="flex items-start gap-2.5 bg-slate-50 px-4 py-3.5">
                <Dna className="mt-0.5 size-5 shrink-0 text-slate-400" aria-hidden />
                <p className="text-[13.5px] font-semibold leading-snug text-slate-900">
                  Soft Skill yang Perlu dikembangkan, agar Selaras dengan Profesi
                </p>
              </div>
              <div className="border-t border-slate-200 px-3 py-3">
                <SpandukNavika teks="Navika akan membantu Kamu mengembangkan soft skill yang masih belum terpenuhi." />
              </div>
              <ChipGrup isi={data.soft_kembangkan} nada="keahlian" />
            </div>

            {!data.has_dna && (
              <p className="mt-4 text-[12px] leading-relaxed text-slate-500">
                Career DNA belum diisi, jadi semua atribut masuk kelompok yang perlu dikembangkan.
                Selesaikan Career DNA untuk melihat perbandingan yang sesungguhnya.
              </p>
            )}
          </div>
        )}

        {!memuat && data && tab === "tools" && (
          <div className="mt-5">
            <h3 className="text-[19px] font-bold leading-snug text-slate-900">
              Tools yang Akan Kamu Gunakan
            </h3>
            <p className="mt-1.5 text-[13px] leading-relaxed text-slate-500">
              Aplikasi yang nantinya digunakan di setiap rutinitas kerja profesi ini
            </p>

            <div className="mt-4 flex flex-col gap-4">
              {data.tools.map((f) => {
                const Ikon = IKON_FASE[f.fase] ?? FolderCog;
                return (
                  <div key={f.fase} className="overflow-hidden rounded-2xl border border-slate-200">
                    <div className="flex items-start gap-2.5 bg-slate-50 px-4 py-3.5">
                      <Ikon className="mt-0.5 size-5 shrink-0 text-violet-600" aria-hidden />
                      <div>
                        <p className="text-[13.5px] font-bold text-slate-900">{f.fase_nama}</p>
                        <p className="mt-0.5 text-[12px] leading-relaxed text-slate-500">
                          {f.fase_subtitle}
                        </p>
                      </div>
                    </div>
                    {f.fase === "MANDIRI" && (
                      <div className="border-t border-slate-200 px-3 py-3">
                        <SpandukNavika teks="Navika akan membantumu memberikan panduan belajar melalui quest mingguan." />
                      </div>
                    )}
                    <ul>
                      {f.isi.map((t, i) => (
                        <li key={i} className="border-t border-slate-200 px-4 py-3">
                          <p className="text-[13.5px] font-semibold leading-snug text-slate-900">
                            {t.nama}
                          </p>
                          <p className="mt-1 text-[12.5px] leading-relaxed text-slate-400">
                            {t.deskripsi}
                            {/* Nama kategori sudah menyebut contoh produknya di dalam
                                kurung untuk aplikasi yang umum dikenal; menambah
                                "Contoh: ..." di situ hanya mengulang. */}
                            {t.contoh && !t.nama.includes("(") && (
                              <span> Contoh: {t.contoh}.</span>
                            )}
                          </p>
                        </li>
                      ))}
                    </ul>
                  </div>
                );
              })}
            </div>

            <div className="mt-4 rounded-r-lg border-l-4 border-violet-600 bg-violet-50 px-4 py-3">
              <p className="text-[13px] font-bold text-slate-900">Catatan:</p>
              <p className="mt-1 text-[12.5px] leading-relaxed text-slate-700">
                Penggunaan tools atau aplikasi dapat berbeda tergantung SOP dan kebijakan internal
                yang berlaku.
              </p>
            </div>
          </div>
        )}
      </div>
    </Sheet>
  );
}
