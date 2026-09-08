"use client";

/**
 * Lembar Filters.
 *
 * Angka di tombol diperbarui tiap kali pilihan berubah, bukan setelah ditutup:
 * itu yang membuat filter terasa bisa dijelajahi — pengguna melihat "80 Profesi"
 * berubah jadi "12 Profesi" dan tahu ia sudah terlalu sempit sebelum menekan
 * apa pun.
 *
 * Filter belum diterapkan sampai tombol ditekan. Menutup lembar tanpa menekan
 * mengembalikan keadaan semula.
 */

import { useCallback, useEffect, useMemo, useState } from "react";
import { ArrowRight, ChevronDown, ChevronUp, Loader2 } from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import { countCareers, type Filter, type OpsiFilter } from "@/lib/careerDetail";

const RINGKAS = 3;

function rupiah(n: number): string {
  return n.toLocaleString("id-ID");
}

export default function FilterSheet({
  buka,
  onTutup,
  opsi,
  awal,
  onTerapkan,
}: {
  buka: boolean;
  onTutup: () => void;
  opsi: OpsiFilter;
  awal: Filter;
  onTerapkan: (f: Filter) => void;
}) {
  const [industri, setIndustri] = useState<string[]>(awal.industries ?? []);
  const [skills, setSkills] = useState<string[]>(awal.skills ?? []);
  const [rankMax, setRankMax] = useState<number | null>(awal.rankMax ?? null);
  const [gajiMin, setGajiMin] = useState<number>(awal.salaryMin ?? opsi.gaji_min);
  const [gajiMax, setGajiMax] = useState<number>(awal.salaryMax ?? opsi.gaji_max);
  const [semuaIndustri, setSemuaIndustri] = useState(false);
  const [semuaSkill, setSemuaSkill] = useState(false);
  const [jumlah, setJumlah] = useState<number | null>(null);
  const [menghitung, setMenghitung] = useState(false);

  useEffect(() => {
    if (!buka) return;
    setIndustri(awal.industries ?? []);
    setSkills(awal.skills ?? []);
    setRankMax(awal.rankMax ?? null);
    setGajiMin(awal.salaryMin ?? opsi.gaji_min);
    setGajiMax(awal.salaryMax ?? opsi.gaji_max);
  }, [buka, awal, opsi.gaji_min, opsi.gaji_max]);

  const filterKini = useMemo<Filter>(
    () => ({
      query: awal.query,
      industries: industri,
      skills,
      rankMax,
      salaryMin: gajiMin > opsi.gaji_min ? gajiMin : null,
      salaryMax: gajiMax < opsi.gaji_max ? gajiMax : null,
    }),
    [awal.query, industri, skills, rankMax, gajiMin, gajiMax, opsi.gaji_min, opsi.gaji_max],
  );

  useEffect(() => {
    if (!buka) return;
    let batal = false;
    setMenghitung(true);
    const t = setTimeout(() => {
      void countCareers(filterKini).then((n) => {
        if (!batal) {
          setJumlah(n);
          setMenghitung(false);
        }
      });
    }, 250);
    return () => {
      batal = true;
      clearTimeout(t);
    };
  }, [buka, filterKini]);

  const toggle = useCallback(
    (arr: string[], set: (v: string[]) => void, kode: string) =>
      set(arr.includes(kode) ? arr.filter((x) => x !== kode) : [...arr, kode]),
    [],
  );

  const bersihkan = () => {
    setIndustri([]);
    setSkills([]);
    setRankMax(null);
    setGajiMin(opsi.gaji_min);
    setGajiMax(opsi.gaji_max);
  };

  const industriTampil = semuaIndustri ? opsi.industri : opsi.industri.slice(0, RINGKAS);
  const skillTampil = semuaSkill ? opsi.keahlian : opsi.keahlian.slice(0, RINGKAS * 2 + 1);

  return (
    <Sheet
      buka={buka}
      onTutup={onTutup}
      judul="Filters"
      penuh
      footer={
        <div
          className="flex items-center gap-3 border-t border-slate-200 bg-white px-4 py-3 sm:px-6"
          style={{ paddingBottom: "max(0.75rem, env(safe-area-inset-bottom))" }}
        >
          <button
            type="button"
            onClick={bersihkan}
            className="rounded-full border border-slate-300 px-5 py-2.5 text-[13px] font-semibold text-slate-700 transition-colors hover:bg-slate-50"
          >
            Clear All
          </button>
          <button
            type="button"
            onClick={() => {
              onTerapkan(filterKini);
              onTutup();
            }}
            className="ml-auto inline-flex items-center gap-2 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
          >
            {menghitung ? (
              <Loader2 className="size-4 animate-spin" aria-hidden />
            ) : (
              <>Tampilkan {jumlah ?? 0} Profesi</>
            )}
            {!menghitung && <ArrowRight className="size-3.5" aria-hidden />}
          </button>
        </div>
      }
    >
      <div className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-5 sm:px-6">
        <section>
          <h3 className="text-[14px] font-semibold text-slate-900">Minat Bidang Industri</h3>
          <p className="mt-0.5 text-[12.5px] leading-snug text-slate-500">
            Sortir profesi berdasarkan bidang Industri yang Kamu minati.
          </p>
          <ul className="mt-3 flex flex-wrap gap-2">
            {industriTampil.map((i) => {
              const on = industri.includes(i.code);
              return (
                <li key={i.code}>
                  <button
                    type="button"
                    onClick={() => toggle(industri, setIndustri, i.code)}
                    aria-pressed={on}
                    className={`rounded-full border px-3.5 py-2 text-[13px] transition-colors ${
                      on
                        ? "border-violet-300 bg-violet-50 font-semibold text-violet-700"
                        : "border-slate-300 text-slate-700 hover:bg-slate-50"
                    }`}
                  >
                    {i.nama}
                  </button>
                </li>
              );
            })}
          </ul>
          {opsi.industri.length > RINGKAS && (
            <button
              type="button"
              onClick={() => setSemuaIndustri((v) => !v)}
              className="mt-2.5 inline-flex items-center gap-1 text-[13px] font-semibold text-violet-700"
            >
              {semuaIndustri ? "Tampilkan lebih sedikit" : "Tampilkan lebih banyak"}
              {semuaIndustri ? (
                <ChevronUp className="size-3.5" aria-hidden />
              ) : (
                <ChevronDown className="size-3.5" aria-hidden />
              )}
            </button>
          )}
        </section>

        <section className="border-t border-slate-200 pt-5">
          <h3 className="text-[14px] font-semibold text-slate-900">Kisaran Gaji</h3>
          <p className="mt-0.5 text-[12.5px] text-slate-500">
            Cari profesi sesuai kisaran gaji yang dipilih
          </p>
          <div className="mt-4 flex flex-col gap-3">
            <input
              type="range"
              aria-label="Gaji minimum"
              min={opsi.gaji_min}
              max={opsi.gaji_max}
              step={500000}
              value={gajiMin}
              onChange={(e) => setGajiMin(Math.min(Number(e.target.value), gajiMax))}
              className="w-full accent-violet-600"
            />
            <input
              type="range"
              aria-label="Gaji maksimum"
              min={opsi.gaji_min}
              max={opsi.gaji_max}
              step={500000}
              value={gajiMax}
              onChange={(e) => setGajiMax(Math.max(Number(e.target.value), gajiMin))}
              className="w-full accent-violet-600"
            />
          </div>
          <div className="mt-3 grid grid-cols-2 gap-3">
            <div>
              <p className="text-[12.5px] text-slate-500">Minimum</p>
              <p className="mt-1 rounded-xl border border-slate-300 px-3 py-2.5 text-[14px] text-slate-900">
                {rupiah(gajiMin)}
              </p>
            </div>
            <div className="text-right">
              <p className="text-[12.5px] text-slate-500">Maksimum</p>
              <p className="mt-1 rounded-xl border border-slate-300 px-3 py-2.5 text-right text-[14px] text-slate-900">
                {rupiah(gajiMax)}
              </p>
            </div>
          </div>
        </section>

        <section className="border-t border-slate-200 pt-5">
          <h3 className="text-[14px] font-semibold text-slate-900">Minimum Pendidikan</h3>
          <ul className="mt-3 flex flex-col gap-2.5">
            {opsi.jenjang.map((j) => {
              const on = rankMax === j.rank_max;
              return (
                <li key={j.code}>
                  <label className="flex cursor-pointer items-center gap-2.5">
                    <input
                      type="radio"
                      name="jenjang"
                      checked={on}
                      onChange={() => setRankMax(on ? null : j.rank_max)}
                      onClick={() => on && setRankMax(null)}
                      className="size-4 accent-violet-600"
                    />
                    <span className={`text-[13.5px] ${on ? "text-slate-900" : "text-slate-500"}`}>
                      {j.nama}
                    </span>
                  </label>
                </li>
              );
            })}
          </ul>
          <p className="mt-2 text-[11.5px] leading-snug text-slate-400">
            Menampilkan profesi yang syarat minimumnya tidak lebih tinggi dari pilihan ini.
          </p>
        </section>

        <section className="border-t border-slate-200 pt-5">
          <h3 className="text-[14px] font-semibold text-slate-900">Atribut keahlian</h3>
          <p className="mt-0.5 text-[12.5px] leading-snug text-slate-500">
            Sortir dan tampilkan profesi berdasarkan keahlian di bawah ini
          </p>
          <ul className="mt-3 flex flex-wrap gap-2">
            {skillTampil.map((k) => {
              const on = skills.includes(k.code);
              return (
                <li key={k.code}>
                  <button
                    type="button"
                    onClick={() => toggle(skills, setSkills, k.code)}
                    aria-pressed={on}
                    className={`rounded-full border px-3.5 py-2 text-[13px] transition-colors ${
                      on
                        ? "border-violet-300 bg-violet-50 font-semibold text-violet-700"
                        : "border-slate-300 text-slate-700 hover:bg-slate-50"
                    }`}
                  >
                    {k.nama}
                  </button>
                </li>
              );
            })}
          </ul>
          {opsi.keahlian.length > RINGKAS * 2 + 1 && (
            <button
              type="button"
              onClick={() => setSemuaSkill((v) => !v)}
              className="mt-2.5 inline-flex items-center gap-1 text-[13px] font-semibold text-violet-700"
            >
              {semuaSkill ? "Tampilkan lebih sedikit" : "Tampilkan lebih banyak"}
              {semuaSkill ? (
                <ChevronUp className="size-3.5" aria-hidden />
              ) : (
                <ChevronDown className="size-3.5" aria-hidden />
              )}
            </button>
          )}
        </section>
      </div>
    </Sheet>
  );
}
