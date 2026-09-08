"use client";

/**
 * Layar Detail Profesi — tiga tab.
 *
 *   Analisa            skor kecocokan, alasan, permintaan pasar, estimasi
 *   Skill & Kompetensi pendidikan, soft skill, hard skill, tools, lisensi
 *   Insight            gaji per senioritas, Skill Gap Analysis, Ketahanan AI
 *
 * Tab kedua dan ketiga mengambil datanya sendiri saat pertama dibuka, bukan
 * ikut terangkut saat halaman dimuat: dua pertiga pengguna berhenti di tab
 * pertama, dan di koneksi seluler tiga panggilan berbarengan terasa.
 *
 * Dirancang untuk ponsel lebih dulu — lebar isi dikunci ke max-w-3xl dan
 * seluruh ukuran teks ditulis untuk layar 360-430px; layar lebar hanya
 * mendapat jarak tepi yang lebih longgar, bukan tata letak lain.
 */

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, FileText, Loader2, ShieldCheck } from "lucide-react";
import DetailHeader from "@/components/profesi/DetailHeader";
import MatchBlock from "@/components/profesi/MatchBlock";
import StickyCta from "@/components/profesi/StickyCta";
import TabSwitch from "@/components/profesi/TabSwitch";
import SkillGapSheet from "@/components/profesi/SkillGapSheet";
import AiCard, { AiInfoSheet } from "@/components/profesi/AiCard";
import { KartuDemand, KartuEstimasi, DaftarSubIndustri } from "@/components/profesi/InfoCards";
import { Blok, BarisDuaKolom, BarisIsi, LihatSemua } from "@/components/profesi/Listing";
import {
  getCareerCompetency,
  getCareerInsight,
  gajiPanjang,
  pilihProfesi,
  type CareerCompetency,
  type CareerDetail,
  type CareerInsight,
  type SkillGap,
} from "@/lib/careerDetail";

type Tab = "analisa" | "skill" | "insight";

const TABS = [
  { kode: "analisa" as const, label: "Analisa" },
  { kode: "skill" as const, label: "Skill & Kompetensi" },
  { kode: "insight" as const, label: "Insight" },
];

/** Berapa baris yang tampil sebelum "Lihat Semua". Angka dari desain. */
const TAMPIL_AWAL = 3;

export default function ProfesiDetail({
  detail,
  kompAwal = null,
  insightAwal = null,
  gapAwal = null,
}: {
  detail: CareerDetail;
  /** Tiga prop berikut hanya diisi harness verifikasi, yang tidak punya
   *  koneksi Supabase. Di produksi semuanya null dan datanya diambil sendiri. */
  kompAwal?: CareerCompetency | null;
  insightAwal?: CareerInsight | null;
  gapAwal?: SkillGap | null;
}) {
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("analisa");
  const [komp, setKomp] = useState<CareerCompetency | null>(kompAwal);
  const [insight, setInsight] = useState<CareerInsight | null>(insightAwal);
  const [memuatTab, setMemuatTab] = useState(false);
  const [gapBuka, setGapBuka] = useState(false);
  const [gapTab, setGapTab] = useState<"hard" | "soft" | "tools">("hard");
  const [aiBuka, setAiBuka] = useState(false);
  const [semuaSoft, setSemuaSoft] = useState(false);
  const [semuaHard, setSemuaHard] = useState(false);
  const [semuaTool, setSemuaTool] = useState(false);
  const [semuaLisensi, setSemuaLisensi] = useState(false);
  const [memilih, setMemilih] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => {
    if (tab === "skill" && !komp) {
      setMemuatTab(true);
      void getCareerCompetency(detail.career_id).then((d) => {
        setKomp(d);
        setMemuatTab(false);
      });
    }
    if (tab === "insight" && !insight) {
      setMemuatTab(true);
      void getCareerInsight(detail.career_id).then((d) => {
        setInsight(d);
        setMemuatTab(false);
      });
    }
  }, [tab, komp, insight, detail.career_id]);

  const pilih = useCallback(async () => {
    setMemilih(true);
    setGalat(null);
    const hasil = await pilihProfesi(detail.career_id);
    setMemilih(false);
    if (!hasil.ok) {
      setGalat(hasil.pesan ?? "Gagal memilih profesi ini. Coba lagi.");
      return;
    }
    router.push("/roadmap");
  }, [detail.career_id, router]);

  const bukaGap = (t: "hard" | "soft" | "tools") => {
    setGapTab(t);
    setGapBuka(true);
  };

  const soft = komp?.soft_skill ?? [];
  const hard = komp?.hard_skill ?? [];
  const tools = komp?.tools ?? [];
  const lisensi = komp?.lisensi ?? [];

  return (
    <div className="flex min-h-[100dvh] flex-col bg-white">
      <DetailHeader judul="Detail Profesi" subjudul={detail.career_name} />

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 pb-8 pt-6 sm:px-6">
        <h1 className="text-[27px] font-bold leading-[1.15] tracking-tight text-slate-900">
          {detail.career_name}
        </h1>
        {detail.career_description && (
          <p className="mt-2.5 text-[14.5px] leading-relaxed text-slate-500">
            {detail.career_description}
          </p>
        )}

        {detail.family_code && (
          <Link
            href={`/explore/kategori/${detail.family_code}`}
            className="mt-3 inline-flex items-center gap-1.5 text-[12.5px] font-semibold text-violet-700 hover:text-violet-800"
          >
            Lihat kategori {detail.family_name}
            <ArrowRight className="size-3.5" aria-hidden />
          </Link>
        )}

        <div className="mt-5">
          <TabSwitch tabs={TABS} aktif={tab} onPilih={setTab} />
        </div>

        {/* ── Tab 1 · Analisa ─────────────────────────────────────────── */}
        {tab === "analisa" && (
          <div className="mt-7 flex flex-col gap-6">
            <MatchBlock
              skor={detail.match_score}
              band={detail.band_code}
              alasan={detail.reasons ?? []}
            />
            <KartuDemand growth={detail.growth_pct} label={detail.demand_label} />
            <DaftarSubIndustri isi={detail.sub_industries ?? []} />
            <KartuEstimasi
              bulan={detail.roadmap_months}
              posisi={detail.posisi_sekarang}
              persen={detail.percent_done}
            />
          </div>
        )}

        {/* ── Tab 2 · Skill & Kompetensi ──────────────────────────────── */}
        {tab === "skill" && (
          <div className="mt-7 flex flex-col gap-7">
            {memuatTab && (
              <div className="flex items-center gap-2 py-8 text-[13px] text-slate-500">
                <Loader2 className="size-4 animate-spin" aria-hidden />
                Menyiapkan kompetensi…
              </div>
            )}

            {komp && (
              <>
                <Blok judul="Minimum Pendidikan" subjudul="Standar kelulusan minimum untuk profesi ini">
                  <ul>
                    {komp.pendidikan.map((p, i) => (
                      <BarisDuaKolom key={i} kiri={p.jenjang} kanan={p.catatan} />
                    ))}
                  </ul>
                </Blok>

                <Blok judul="Soft Skill" keterangan="(Ketrampilan non teknis)">
                  <ul>
                    {(semuaSoft ? soft : soft.slice(0, TAMPIL_AWAL)).map((s, i) => (
                      <BarisIsi key={i} utama={s.nama} penjelas={s.deskripsi} />
                    ))}
                  </ul>
                  {!semuaSoft && (
                    <LihatSemua
                      label="Lihat Semua Ketrampilan"
                      sisa={soft.length - TAMPIL_AWAL}
                      onClick={() => setSemuaSoft(true)}
                    />
                  )}
                </Blok>

                <Blok judul="Hard Skill" keterangan="(Ketrampilan teknis)">
                  <ul>
                    {(semuaHard ? hard : hard.slice(0, TAMPIL_AWAL)).map((s) => (
                      <BarisIsi key={s.kode} utama={s.nama} penjelas={s.deskripsi} />
                    ))}
                  </ul>
                  {!semuaHard && (
                    <LihatSemua
                      label="Lihat Semua Ketrampilan"
                      sisa={hard.length - TAMPIL_AWAL}
                      onClick={() => setSemuaHard(true)}
                    />
                  )}
                </Blok>

                <Blok judul="Tools" keterangan="(Penggunaan aplikasi)">
                  <ul>
                    {(semuaTool ? tools : tools.slice(0, TAMPIL_AWAL)).map((t) => (
                      <BarisIsi key={t.kode} utama={t.nama} />
                    ))}
                  </ul>
                  {!semuaTool ? (
                    <LihatSemua
                      label="Lihat Semua Tools"
                      sisa={tools.length - TAMPIL_AWAL}
                      onClick={() => setSemuaTool(true)}
                    />
                  ) : (
                    <button
                      type="button"
                      onClick={() => bukaGap("tools")}
                      className="mt-3 inline-flex items-center gap-1.5 text-[13px] font-semibold text-violet-700 hover:text-violet-800"
                    >
                      Lihat kapan tiap tools dipakai
                      <ArrowRight className="size-3.5" aria-hidden />
                    </button>
                  )}
                </Blok>

                <Blok judul="Lisensi & Sertifikasi">
                  <ul className="flex flex-col gap-2.5">
                    {(semuaLisensi ? lisensi : lisensi.slice(0, TAMPIL_AWAL)).map((l) => (
                      <li
                        key={l.kode}
                        className="flex items-start gap-3 rounded-2xl border border-slate-200 px-3.5 py-3"
                      >
                        <span className="grid size-10 shrink-0 place-items-center rounded-xl bg-violet-50 text-violet-600">
                          {l.sifat === "WAJIB" ? (
                            <FileText className="size-5" aria-hidden />
                          ) : (
                            <ShieldCheck className="size-5" aria-hidden />
                          )}
                        </span>
                        <div className="min-w-0">
                          <p className="text-[13.5px] font-semibold leading-snug text-slate-900">
                            {l.nama}
                          </p>
                          <p className="mt-0.5 text-[12.5px] leading-snug text-slate-400">
                            {l.penerbit}
                          </p>
                        </div>
                      </li>
                    ))}
                  </ul>
                  {!semuaLisensi && (
                    <LihatSemua
                      label="Lihat Semua"
                      sisa={lisensi.length - TAMPIL_AWAL}
                      onClick={() => setSemuaLisensi(true)}
                    />
                  )}
                </Blok>
              </>
            )}
          </div>
        )}

        {/* ── Tab 3 · Insight ─────────────────────────────────────────── */}
        {tab === "insight" && (
          <div className="mt-7 flex flex-col gap-6">
            {memuatTab && (
              <div className="flex items-center gap-2 py-8 text-[13px] text-slate-500">
                <Loader2 className="size-4 animate-spin" aria-hidden />
                Menyiapkan insight…
              </div>
            )}

            {insight && (
              <>
                <section>
                  <h3 className="text-[15px] font-semibold text-slate-900">
                    Kisaran Gaji (Indonesia)
                  </h3>
                  <ul className="mt-3">
                    {insight.gaji.map((g) => (
                      <li
                        key={g.kode}
                        className="flex items-start justify-between gap-3 border-b border-slate-200 py-3 last:border-b-0"
                      >
                        <div>
                          <p className="text-[13.5px] font-semibold text-slate-900">{g.tingkat}</p>
                          <p className="mt-0.5 text-[12px] text-slate-400">({g.pengalaman})</p>
                        </div>
                        <p className="shrink-0 text-[13.5px] font-bold text-slate-900">
                          {gajiPanjang(g.salary_min, g.salary_max).replace(" juta", " Juta")}
                        </p>
                      </li>
                    ))}
                  </ul>
                  <p className="mt-2.5 text-[11px] text-slate-400">**{insight.sumber_gaji}</p>
                </section>

                <button
                  type="button"
                  onClick={() => bukaGap("hard")}
                  className="relative overflow-hidden rounded-2xl border border-violet-100 bg-violet-50 p-4 text-left"
                >
                  <Image
                    src="/profesi/skill-gap-banner.png"
                    alt=""
                    width={341}
                    height={164}
                    className="pointer-events-none absolute -right-6 bottom-0 h-[86%] w-auto object-contain"
                  />
                  <div className="relative max-w-[64%]">
                    <p className="text-[15px] font-bold text-violet-700">Skill Gap Analysis</p>
                    <p className="mt-1 text-[12.5px] leading-relaxed text-slate-600">
                      Tampilkan ketrampilan apa saja yang perlu Kamu kembangkan di profesi ini
                    </p>
                    <span className="mt-3 inline-flex items-center gap-1.5 rounded-full bg-violet-600 px-4 py-2 text-[12.5px] font-semibold text-white">
                      Tampilkan
                      <ArrowRight className="size-3.5" aria-hidden />
                    </span>
                  </div>
                </button>

                <AiCard
                  skor={insight.ai_resilience}
                  label={insight.ai_label}
                  penjelasan={insight.ai_penjelasan}
                  onInfo={() => setAiBuka(true)}
                />
              </>
            )}
          </div>
        )}

        {galat && (
          <p className="mt-6 rounded-xl bg-rose-50 px-4 py-3 text-[12.5px] text-rose-700">{galat}</p>
        )}
      </main>

      <StickyCta
        label={detail.is_pilihan ? "Lanjutkan Roadmap" : "Pilih Profesi ini"}
        onClick={pilih}
        sedang={memilih}
      />

      <SkillGapSheet
        careerId={detail.career_id}
        buka={gapBuka}
        onTutup={() => setGapBuka(false)}
        tabAwal={gapTab}
        dataAwal={gapAwal}
      />
      <AiInfoSheet buka={aiBuka} onTutup={() => setAiBuka(false)} />
    </div>
  );
}
