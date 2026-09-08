"use client";

/**
 * Layar Detail Kategori — dua tab.
 *
 *   Ringkasan               gambaran satu kategori: kecocokan, gaji, atribut
 *   Profesi di kategori ini daftar anggotanya, bisa disaring per sub-industri
 *
 * Angka di tab pertama adalah agregat anggota (lihat migrasi 0030), bukan data
 * terpisah — jadi tidak ada kemungkinan kategori dan anggotanya bercerita beda.
 */

import { useCallback, useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import StickyCta from "@/components/profesi/StickyCta";
import DetailHeader from "@/components/profesi/DetailHeader";
import TabSwitch from "@/components/profesi/TabSwitch";
import MatchBlock from "@/components/profesi/MatchBlock";
import KartuHasil from "@/components/profesi/KartuHasil";
import { KartuDemand } from "@/components/profesi/InfoCards";
import { Blok, BarisDuaKolom } from "@/components/profesi/Listing";
import {
  gajiPanjang,
  getFamilyCareers,
  getFamilySubIndustries,
  type FamilyDetail,
  type KartuProfesi,
} from "@/lib/careerDetail";

type Tab = "ringkas" | "profesi";

const TABS = [
  { kode: "ringkas" as const, label: "Ringkasan" },
  { kode: "profesi" as const, label: "Profesi di kategori ini" },
];

/** Lapisan yang tampil di Ringkasan. Minat industri sengaja tidak ikut:
 *  ia sudah terwakili nama kategori dan chip sub-industri di kartu anggotanya. */
const LAPIS_TAMPIL = ["ACTIVITY", "SKILL", "ENVIRONMENT", "WORKSTYLE"];

export default function KategoriDetail({
  detail,
  daftarAwal = [],
  subAwal = [],
}: {
  detail: FamilyDetail;
  /** Dua prop berikut hanya diisi harness verifikasi yang tidak punya Supabase. */
  daftarAwal?: KartuProfesi[];
  subAwal?: { code: string; nama: string; n_profesi: number }[];
}) {
  const [tab, setTab] = useState<Tab>("ringkas");
  const [sub, setSub] = useState<string | null>(null);
  const [opsi, setOpsi] = useState<{ code: string; nama: string; n_profesi: number }[]>(subAwal);
  const [daftar, setDaftar] = useState<KartuProfesi[]>(daftarAwal);
  const [memuat, setMemuat] = useState(false);

  const muat = useCallback(async () => {
    setMemuat(true);
    const [list, subs] = await Promise.all([
      getFamilyCareers(detail.family_code, sub),
      opsi.length ? Promise.resolve(opsi) : getFamilySubIndustries(detail.family_code),
    ]);
    setDaftar(list);
    setOpsi(subs);
    setMemuat(false);
  }, [detail.family_code, sub, opsi]);

  useEffect(() => {
    if (tab === "profesi" && daftarAwal.length === 0) void muat();
    // muat sengaja tidak masuk dependensi: ia berubah tiap render karena opsi.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, sub, detail.family_code]);

  const atribut = (detail.atribut ?? []).filter((a) => LAPIS_TAMPIL.includes(a.layer));

  return (
    <div className="flex min-h-[100dvh] flex-col bg-white">
      <DetailHeader
        judul={detail.family_name}
        subjudul={tab === "ringkas" ? "Ringkasan" : "Profesi di kategori ini"}
      />

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 pb-8 pt-6 sm:px-6">
        <h1 className="text-[27px] font-bold leading-[1.15] tracking-tight text-slate-900">
          {detail.family_name}
        </h1>
        <p className="mt-2.5 text-[14.5px] leading-relaxed text-slate-500">
          {detail.description_id}
        </p>

        <div className="mt-5">
          <TabSwitch tabs={TABS} aktif={tab} onPilih={setTab} />
        </div>

        {tab === "ringkas" && (
          <div className="mt-7 flex flex-col gap-7">
            <MatchBlock
              skor={detail.match_score}
              band={detail.band_code}
              alasan={[]}
              ringkas
            />

            <section>
              <p className="text-[13.5px] font-semibold text-violet-700">Kisaran Gaji</p>
              <p className="mt-1 text-[26px] font-bold leading-tight tracking-tight text-slate-900">
                {gajiPanjang(detail.salary_min, detail.salary_max)}
                <span className="ml-1.5 align-baseline text-[13px] font-normal text-slate-500">
                  /bulan
                </span>
              </p>
              <p className="mt-1.5 text-[13px] leading-relaxed text-slate-500">
                Besaran gaji bergantung pada jabatan, pengalaman, perusahaan bekerja, dan lokasi.
              </p>
            </section>

            <section className="grid grid-cols-2 divide-x divide-slate-200 border-y border-slate-200 py-4 text-center">
              <div>
                <p className="text-[20px] font-bold text-slate-900">{detail.n_sub_industri}</p>
                <p className="mt-0.5 text-[12.5px] text-slate-500">Sub-Industri</p>
              </div>
              <div>
                <p className="text-[20px] font-bold text-slate-900">
                  {detail.growth_pct == null ? "—" : `+${Number(detail.growth_pct).toFixed(0)}%`}
                  <span className="ml-1 text-[11.5px] font-normal text-slate-500">(tahun)</span>
                </p>
                <p className="mt-0.5 text-[12.5px] text-slate-500">{detail.demand_label}</p>
              </div>
            </section>

            {atribut.map((a) => (
              <section key={a.layer}>
                <h3 className="text-[14.5px] font-semibold text-slate-900">{a.judul}</h3>
                <ul className="mt-2.5 flex flex-wrap gap-1.5">
                  {a.isi.map((n) => (
                    <li
                      key={n}
                      className={`rounded-md px-2.5 py-1.5 text-[12px] font-medium ${
                        a.layer === "SKILL" || a.layer === "ENVIRONMENT"
                          ? "bg-cyan-100 text-cyan-800"
                          : "bg-indigo-100 text-indigo-800"
                      }`}
                    >
                      {n}
                    </li>
                  ))}
                </ul>
              </section>
            ))}

            <Blok
              judul="Minimum Pendidikan"
              subjudul="Standar kelulusan minimum untuk profesi ini"
            >
              <ul>
                {detail.pendidikan.map((p, i) => (
                  <BarisDuaKolom key={i} kiri={p.jenjang} kanan={p.catatan} />
                ))}
              </ul>
            </Blok>

            <KartuDemand growth={detail.growth_pct} label={detail.demand_label} />
          </div>
        )}

        {tab === "profesi" && (
          <div className="mt-6">
            <label className="block rounded-xl border border-slate-300 px-3.5 py-2.5">
              <span className="block text-[11.5px] text-slate-400">
                Berdasarkan Bidang Sub Industri
              </span>
              <select
                value={sub ?? ""}
                onChange={(e) => setSub(e.target.value === "" ? null : e.target.value)}
                className="mt-0.5 w-full bg-transparent text-[14px] font-semibold text-slate-900 outline-none"
              >
                <option value="">Semua Sub Industri</option>
                {opsi.map((o) => (
                  <option key={o.code} value={o.code}>
                    {o.nama} ({o.n_profesi})
                  </option>
                ))}
              </select>
            </label>

            {memuat ? (
              <div className="flex items-center gap-2 py-10 text-[13px] text-slate-500">
                <Loader2 className="size-4 animate-spin" aria-hidden />
                Memuat profesi…
              </div>
            ) : daftar.length === 0 ? (
              <p className="py-10 text-center text-[13px] text-slate-500">
                Belum ada profesi di sub-industri ini.
              </p>
            ) : (
              <ul className="mt-4 flex flex-col gap-3">
                {daftar.map((k) => (
                  <KartuHasil key={k.career_id} kartu={k} />
                ))}
              </ul>
            )}
          </div>
        )}
      </main>

      {/* Kategori bukan profesi yang bisa dipilih — ia payung. Jadi tombolnya
          mengantar ke daftar anggotanya, bukan memulai roadmap apa pun. */}
      <StickyCta
        label={tab === "ringkas" ? "Pilih Profesi di kategori ini" : "Kembali ke Ringkasan"}
        onClick={() => setTab(tab === "ringkas" ? "profesi" : "ringkas")}
      />
    </div>
  );
}
