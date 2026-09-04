"use client";

/**
 * Sapaan, avatar, dan kolom pencarian.
 *
 * Pencariannya menembak RPC explore_search dan menampilkan hasilnya sebagai
 * daftar melayang. Dibatasi dua huruf dan ditunda 250 ms supaya mengetik satu
 * kata tidak berubah jadi delapan panggilan jaringan.
 */

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Search, Loader2 } from "lucide-react";
import { searchCareerCards, type CareerCard } from "@/lib/explore";

function inisial(nama: string | null): string {
  if (!nama) return "N";
  const p = nama.trim().split(/\s+/);
  return ((p[0]?.[0] ?? "") + (p.length > 1 ? (p[p.length - 1][0] ?? "") : "")).toUpperCase() || "N";
}

export default function GreetingHeader({ name }: { name: string | null }) {
  const [q, setQ] = useState("");
  const [hasil, setHasil] = useState<CareerCard[]>([]);
  const [mencari, setMencari] = useState(false);
  const [terbuka, setTerbuka] = useState(false);
  const wrap = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const teks = q.trim();
    if (teks.length < 2) {
      setHasil([]);
      setMencari(false);
      return;
    }
    setMencari(true);
    // Pencarian yang tertinggal tidak boleh menimpa hasil yang lebih baru.
    let batal = false;
    const t = setTimeout(async () => {
      const r = await searchCareerCards(teks, 8);
      if (batal) return;
      setHasil(r);
      setMencari(false);
    }, 250);
    return () => {
      batal = true;
      clearTimeout(t);
    };
  }, [q]);

  useEffect(() => {
    function keluar(e: MouseEvent) {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setTerbuka(false);
    }
    document.addEventListener("mousedown", keluar);
    return () => document.removeEventListener("mousedown", keluar);
  }, []);

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="text-[17px] font-bold tracking-tight text-slate-900">
            Halo, {name?.split(" ")[0] ?? "Sobat"}
          </p>
          <p className="mt-0.5 text-[12.5px] text-slate-500">
            Teruslah belajar dan capai profesi impianmu!
          </p>
        </div>
        <span
          className="grid size-10 shrink-0 place-items-center rounded-full bg-violet-200 text-[13px] font-bold text-violet-800"
          aria-hidden
        >
          {inisial(name)}
        </span>
      </div>

      <div ref={wrap} className="relative">
        <label htmlFor="cari-profesi" className="sr-only">
          Cari profesi impian kamu
        </label>
        <Search className="pointer-events-none absolute left-4 top-1/2 size-4 -translate-y-1/2 text-slate-400" aria-hidden />
        <input
          id="cari-profesi"
          type="search"
          value={q}
          onChange={(e) => {
            setQ(e.target.value);
            setTerbuka(true);
          }}
          onFocus={() => setTerbuka(true)}
          placeholder="Cari profesi impian kamu.."
          className="w-full rounded-full border border-slate-200 bg-white py-3 pl-11 pr-10 text-[13.5px] text-slate-900 outline-none placeholder:text-slate-400 focus:border-violet-400"
        />
        {mencari && (
          <Loader2 className="absolute right-4 top-1/2 size-4 -translate-y-1/2 animate-spin text-slate-400" aria-hidden />
        )}

        {terbuka && q.trim().length >= 2 && (
          <div className="absolute left-0 right-0 top-[calc(100%+8px)] z-20 max-h-80 overflow-y-auto rounded-2xl border border-slate-200 bg-white py-1 shadow-lg">
            {hasil.length === 0 && !mencari ? (
              <p className="px-4 py-3 text-[13px] text-slate-400">
                Tidak ada profesi yang cocok dengan &ldquo;{q.trim()}&rdquo;.
              </p>
            ) : (
              hasil.map((c) => (
                <Link
                  key={c.career_id}
                  href={`/explore/${c.career_id}`}
                  onClick={() => setTerbuka(false)}
                  className="block px-4 py-2.5 transition-colors hover:bg-slate-50"
                >
                  <span className="block text-[13.5px] font-medium text-slate-900">{c.career_name}</span>
                  <span className="block text-[12px] text-slate-500">{c.sub_industry}</span>
                </Link>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
