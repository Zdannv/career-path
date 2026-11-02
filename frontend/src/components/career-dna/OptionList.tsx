"use client";

/**
 * Daftar pilihan satu langkah Career DNA.
 *
 * Begitu batas maksimal tercapai, pilihan yang belum dicentang dinonaktifkan
 * dan diredupkan — persis keadaan yang digambar di mockup langkah 1, di mana
 * tiga minat sudah dipilih dan sisanya pudar. Tanpa itu pengguna mengetuk
 * pilihan keempat lalu tidak terjadi apa-apa, dan tidak jelas kenapa.
 *
 * Pilihan yang sudah dicentang naik ke atas daftar (masukan Pak Yoki dan
 * Nico): pengguna langsung melihat apa saja yang sudah ia pilih tanpa
 * menggulir, termasuk saat kembali ke langkah yang pernah diisi. Urutan di
 * dalam tiap kelompok tetap urutan aslinya, supaya posisi pilihan yang belum
 * dicentang tidak berpindah-pindah.
 */

import { Fragment } from "react";
import { Check } from "lucide-react";
import type { DnaAttributeOption } from "@/lib/careerDna";

type Props = {
  options: DnaAttributeOption[];
  selected: string[];
  maxPick: number;
  onToggle: (code: string) => void;
};

export default function OptionList({ options, selected, maxPick, onToggle }: Props) {
  const penuh = selected.length >= maxPick;
  const dipilih = options.filter((o) => selected.includes(o.code));
  const lainnya = options.filter((o) => !selected.includes(o.code));
  const urut = [...dipilih, ...lainnya];

  return (
    <ul className="flex flex-col gap-2.5">
      {urut.map((o, i) => {
        const aktif = selected.includes(o.code);
        const nonaktif = penuh && !aktif;
        return (
          <Fragment key={o.code}>
            {i === 0 && dipilih.length > 0 && (
              <li aria-hidden className="text-[12px] font-semibold text-violet-700">
                Pilihanmu ({dipilih.length}/{maxPick})
              </li>
            )}
            {i === dipilih.length && dipilih.length > 0 && lainnya.length > 0 && (
              <li aria-hidden className="pt-2 text-[12px] font-semibold text-slate-400">
                Pilihan lain
              </li>
            )}
          <li>
            <button
              type="button"
              onClick={() => onToggle(o.code)}
              disabled={nonaktif}
              aria-pressed={aktif}
              className={`flex w-full items-start gap-3 rounded-xl border px-4 py-3 text-left transition-colors ${
                aktif
                  ? "border-violet-500 bg-violet-50/60"
                  : nonaktif
                    ? "cursor-not-allowed border-slate-200 bg-white opacity-45"
                    : "border-slate-200 bg-white hover:border-slate-300"
              }`}
            >
              <span
                className={`mt-0.5 grid size-[18px] shrink-0 place-items-center rounded-[5px] border ${
                  aktif ? "border-violet-600 bg-violet-600" : "border-slate-300 bg-white"
                }`}
                aria-hidden
              >
                {aktif && <Check className="size-3 text-white" strokeWidth={3} />}
              </span>
              <span className="min-w-0">
                <span className="block text-[13.5px] font-semibold leading-snug text-slate-900">
                  {o.name}
                </span>
                {o.hint && (
                  <span className="mt-0.5 block text-[12.5px] leading-relaxed text-slate-500">
                    {o.hint}
                  </span>
                )}
              </span>
            </button>
          </li>
          </Fragment>
        );
      })}
    </ul>
  );
}
