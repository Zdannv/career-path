"use client";

/**
 * Ringkasan pilihan yang menempel di atas saat daftar digulir (desain Nico,
 * menggantikan pengurutan pilihan ke atas).
 *
 * Mengurutkan pilihan ke atas memang membuat pilihan langsung terlihat, tetapi
 * kartu yang sudah dicentang ikut memakan tinggi layar dan area gulir untuk
 * pilihan lain jadi sempit. Di sini urutan opsi tetap seperti aslinya; begitu
 * judul langkah tergulir keluar layar, muncul bar "<Kategori> yang kamu pilih
 * n/maks". Menekannya membuka sheet berisi pilihan beserta tombol hapus.
 *
 * Hanya di ponsel dan tablet. Di desktop daftar opsinya umumnya muat satu
 * layar dan panel langkah di kiri sudah memberi konteks.
 */

import { useEffect, useState, type RefObject } from "react";
import { ChevronDown, Trash2, X } from "lucide-react";
import type { DnaAttributeOption } from "@/lib/careerDna";

/** Tinggi kepala layar Career DNA di ponsel (header sticky di DnaFlow). */
const TINGGI_KEPALA = 49;

type Props = {
  /** Judul dan pertanyaan langkah; bar muncul begitu elemen ini lewat ke atas. */
  judulRef: RefObject<HTMLElement | null>;
  kategori: string;
  options: DnaAttributeOption[];
  selected: string[];
  maxPick: number;
  onToggle: (code: string) => void;
};

export default function PilihanRingkas({ judulRef, kategori, options, selected, maxPick, onToggle }: Props) {
  const [tampil, setTampil] = useState(false);
  const [buka, setBuka] = useState(false);

  useEffect(() => {
    const el = judulRef.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([e]) => setTampil(!e.isIntersecting && e.boundingClientRect.top < TINGGI_KEPALA),
      { rootMargin: `-${TINGGI_KEPALA}px 0px 0px 0px` },
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, [judulRef]);

  useEffect(() => {
    if (!buka) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setBuka(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [buka]);

  const dipilih = options.filter((o) => selected.includes(o.code));

  return (
    <>
      {tampil && (
        <div
          className="fixed inset-x-0 z-10 flex items-center justify-between gap-3 border-b border-slate-200 bg-slate-50 px-4 py-2.5 sm:px-6 lg:hidden"
          style={{ top: TINGGI_KEPALA }}
        >
          <span className="truncate text-[13px] text-slate-600">{kategori} yang kamu pilih</span>
          <button
            type="button"
            onClick={() => setBuka(true)}
            aria-label={`Lihat ${selected.length} dari ${maxPick} pilihan`}
            className="inline-flex shrink-0 items-center gap-1 rounded-full bg-violet-600 px-2.5 py-1 text-[12px] font-semibold text-white"
          >
            {selected.length}/{maxPick}
            <ChevronDown className="size-3.5" aria-hidden />
          </button>
        </div>
      )}

      {buka && (
        <div className="fixed inset-0 z-[60] flex items-end bg-slate-900/70 lg:hidden" onClick={() => setBuka(false)}>
          <div
            role="dialog"
            aria-modal="true"
            aria-label={`${kategori} yang kamu pilih`}
            onClick={(e) => e.stopPropagation()}
            className="max-h-[70vh] w-full overflow-y-auto rounded-t-2xl bg-white px-5 pb-6 pt-5"
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 className="text-[15px] font-semibold text-slate-900">{kategori} yang kamu pilih</h2>
                <p className="text-[12.5px] text-slate-500">Maksimum {maxPick} pilihan</p>
              </div>
              <button type="button" onClick={() => setBuka(false)} aria-label="Tutup" className="rounded-full p-1 text-slate-500 hover:bg-slate-100">
                <X className="size-4.5" aria-hidden />
              </button>
            </div>
            {dipilih.length === 0 ? (
              <p className="mt-4 text-[13px] text-slate-400">Belum ada yang dipilih.</p>
            ) : (
              <ul className="mt-3 divide-y divide-slate-200">
                {dipilih.map((o) => (
                  <li key={o.code} className="flex items-center gap-3 py-3">
                    <span className="min-w-0 flex-1">
                      <span className="block text-[13.5px] font-medium text-slate-900">{o.name}</span>
                      {o.hint && <span className="block text-[12.5px] text-slate-500">{o.hint}</span>}
                    </span>
                    <button
                      type="button"
                      onClick={() => onToggle(o.code)}
                      aria-label={`Hapus ${o.name}`}
                      className="rounded-full p-1.5 text-slate-500 transition-colors hover:bg-red-50 hover:text-red-600"
                    >
                      <Trash2 className="size-4" aria-hidden />
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      )}
    </>
  );
}
