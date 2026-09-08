"use client";

/**
 * Layar pencarian profesi.
 *
 * Tiga keadaan, satu layar:
 *   kotak kosong, belum diketik  daftar "Terpopuler" + kartu industri
 *   sedang mengetik              saran nama profesi
 *   sudah dicari / difilter      hasil berupa kartu, chip keahlian ikut tampil
 *
 * Chip keahlian di atas hasil adalah jalan pintas ke filter yang sama: menekan
 * satu chip sama dengan mencentangnya di lembar Filters, jadi tidak ada dua
 * sumber kebenaran untuk keadaan filter.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Building2, Loader2, Search, SlidersHorizontal } from "lucide-react";
import KartuHasil from "@/components/profesi/KartuHasil";
import FilterSheet from "@/components/profesi/FilterSheet";
import {
  getFilterOptions,
  getSearchSuggest,
  searchCareers,
  type Filter,
  type KartuProfesi,
  type OpsiFilter,
  type SaranCari,
} from "@/lib/careerDetail";

function jumlahFilter(f: Filter): number {
  return (
    (f.industries?.length ?? 0) +
    (f.skills?.length ?? 0) +
    (f.rankMax ? 1 : 0) +
    (f.salaryMin || f.salaryMax ? 1 : 0)
  );
}

export default function PencarianView({
  saranAwal = [],
  opsiAwal = null,
  hasilAwal = null,
}: {
  /** Ketiganya hanya diisi harness verifikasi yang tidak punya Supabase. */
  saranAwal?: SaranCari[];
  opsiAwal?: OpsiFilter | null;
  hasilAwal?: KartuProfesi[] | null;
} = {}) {
  const router = useRouter();
  const [q, setQ] = useState(hasilAwal ? "Perawat" : "");
  const [saran, setSaran] = useState<SaranCari[]>(saranAwal);
  const [hasil, setHasil] = useState<KartuProfesi[]>(hasilAwal ?? []);
  const [opsi, setOpsi] = useState<OpsiFilter | null>(opsiAwal);
  const [filter, setFilter] = useState<Filter>({});
  const [filterBuka, setFilterBuka] = useState(false);
  const [mencari, setMencari] = useState(false);
  const [sudahCari, setSudahCari] = useState(hasilAwal != null);
  const kotak = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!opsiAwal) void getFilterOptions().then(setOpsi);
    kotak.current?.focus();
  }, [opsiAwal]);

  // Saran mengikuti ketikan; hasil hanya berubah saat pencarian dijalankan.
  useEffect(() => {
    if (sudahCari || saranAwal.length > 0) return;
    let batal = false;
    const t = setTimeout(() => {
      void getSearchSuggest(q, 8).then((s) => {
        if (!batal) setSaran(s);
      });
    }, 200);
    return () => {
      batal = true;
      clearTimeout(t);
    };
  }, [q, sudahCari]);

  const jalankan = useCallback(
    async (f: Filter) => {
      setMencari(true);
      setSudahCari(true);
      const r = await searchCareers(f, 30, 0);
      setHasil(r);
      setMencari(false);
    },
    [],
  );

  const terapkan = useCallback(
    (f: Filter) => {
      const gabung = { ...f, query: q };
      setFilter(gabung);
      void jalankan(gabung);
    },
    [q, jalankan],
  );

  const toggleChip = useCallback(
    (kode: string) => {
      const kini = filter.skills ?? [];
      const baru = kini.includes(kode) ? kini.filter((x) => x !== kode) : [...kini, kode];
      terapkan({ ...filter, skills: baru });
    },
    [filter, terapkan],
  );

  const nFilter = useMemo(() => jumlahFilter(filter), [filter]);

  return (
    <div className="flex min-h-[100dvh] flex-col bg-white">
      <header className="sticky top-0 z-30 border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-3xl items-center gap-2.5 px-4 py-3 sm:px-6">
          <button
            type="button"
            onClick={() => router.back()}
            aria-label="Kembali"
            className="-ml-1 shrink-0 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
          >
            <ArrowLeft className="size-5" aria-hidden />
          </button>

          <form
            className="flex min-w-0 flex-1 items-center gap-2 rounded-full border border-slate-300 px-3.5 py-2"
            onSubmit={(e) => {
              e.preventDefault();
              void jalankan({ ...filter, query: q });
            }}
          >
            <Search className="size-4 shrink-0 text-slate-400" aria-hidden />
            <input
              ref={kotak}
              value={q}
              onChange={(e) => {
                setQ(e.target.value);
                setSudahCari(false);
              }}
              placeholder="Cari profesi impian Kamu.."
              className="min-w-0 flex-1 bg-transparent text-[14px] text-slate-900 outline-none placeholder:text-slate-400"
            />
          </form>

          <button
            type="button"
            onClick={() => setFilterBuka(true)}
            aria-label="Filter"
            className="relative shrink-0 rounded-full border border-slate-300 p-2 text-slate-700 transition-colors hover:bg-slate-50"
          >
            <SlidersHorizontal className="size-4" aria-hidden />
            {nFilter > 0 && (
              <span className="absolute -right-1 -top-1 grid size-4 place-items-center rounded-full bg-violet-600 text-[10px] font-bold text-white">
                {nFilter}
              </span>
            )}
          </button>
        </div>

        {sudahCari && (opsi?.keahlian.length ?? 0) > 0 && (
          <div className="mx-auto max-w-3xl overflow-x-auto px-4 pb-3 sm:px-6">
            <ul className="flex w-max gap-2">
              {opsi!.keahlian.map((k) => {
                const on = (filter.skills ?? []).includes(k.code);
                return (
                  <li key={k.code}>
                    <button
                      type="button"
                      onClick={() => toggleChip(k.code)}
                      aria-pressed={on}
                      className={`whitespace-nowrap rounded-full border px-3.5 py-1.5 text-[13px] transition-colors ${
                        on
                          ? "border-violet-300 bg-violet-50 font-semibold text-violet-700"
                          : "border-slate-300 text-slate-700"
                      }`}
                    >
                      {k.nama}
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>
        )}
      </header>

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 pb-10 pt-4 sm:px-6">
        {mencari && (
          <div className="flex items-center gap-2 py-10 text-[13px] text-slate-500">
            <Loader2 className="size-4 animate-spin" aria-hidden />
            Mencari…
          </div>
        )}

        {!mencari && !sudahCari && (
          <>
            {q.trim() === "" && (
              <p className="mb-2 text-[12.5px] font-medium text-slate-400">Terpopuler</p>
            )}
            <ul className="divide-y divide-slate-200">
              {saran.map((s) => (
                <li key={s.career_id}>
                  <Link href={`/explore/${s.career_id}`} className="block py-3">
                    <p className="text-[14.5px] text-slate-900">
                      {q.trim() === "" ? (
                        s.career_name
                      ) : (
                        <Sorot teks={s.career_name} kata={q.trim()} />
                      )}
                    </p>
                    {s.sub_industries.length > 0 && (
                      <ul className="mt-1.5 flex flex-wrap gap-1.5">
                        {s.sub_industries.map((n) => (
                          <li
                            key={n}
                            className="inline-flex items-center gap-1 rounded-md bg-indigo-50 px-2 py-1 text-[11px] font-medium text-indigo-700"
                          >
                            <Building2 className="size-3" aria-hidden />
                            {n}
                          </li>
                        ))}
                        {s.extra > 0 && (
                          <li className="rounded-md bg-slate-100 px-2 py-1 text-[11px] font-medium text-slate-500">
                            +{s.extra}
                          </li>
                        )}
                      </ul>
                    )}
                  </Link>
                </li>
              ))}
            </ul>

            {saran.length === 0 && q.trim() !== "" && (
              <p className="py-10 text-center text-[13px] text-slate-500">
                Tidak ada profesi yang cocok dengan &ldquo;{q}&rdquo;.
              </p>
            )}
          </>
        )}

        {!mencari && sudahCari && (
          <>
            <p className="mb-3 text-[12.5px] text-slate-500">
              {hasil.length === 0
                ? "Tidak ada profesi yang cocok"
                : `${hasil[0].total ?? hasil.length} profesi ditemukan`}
            </p>
            <ul className="flex flex-col gap-3">
              {hasil.map((k) => (
                <KartuHasil key={k.career_id} kartu={k} chips />
              ))}
            </ul>
          </>
        )}
      </main>

      {opsi && (
        <FilterSheet
          buka={filterBuka}
          onTutup={() => setFilterBuka(false)}
          opsi={opsi}
          awal={{ ...filter, query: q }}
          onTerapkan={terapkan}
        />
      )}
    </div>
  );
}

/** Menebalkan bagian nama yang cocok dengan yang diketik, seperti di desain. */
function Sorot({ teks, kata }: { teks: string; kata: string }) {
  const i = teks.toLowerCase().indexOf(kata.toLowerCase());
  if (i < 0) return <>{teks}</>;
  return (
    <>
      {teks.slice(0, i)}
      <strong className="font-bold">{teks.slice(i, i + kata.length)}</strong>
      {teks.slice(i + kata.length)}
    </>
  );
}
