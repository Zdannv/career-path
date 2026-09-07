"use client";

/**
 * Daftar pilihan satu langkah Career DNA.
 *
 * Begitu batas maksimal tercapai, pilihan yang belum dicentang dinonaktifkan
 * dan diredupkan — persis keadaan yang digambar di mockup langkah 1, di mana
 * tiga minat sudah dipilih dan sisanya pudar. Tanpa itu pengguna mengetuk
 * pilihan keempat lalu tidak terjadi apa-apa, dan tidak jelas kenapa.
 */

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

  return (
    <ul className="flex flex-col gap-2.5">
      {options.map((o) => {
        const aktif = selected.includes(o.code);
        const nonaktif = penuh && !aktif;
        return (
          <li key={o.code}>
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
        );
      })}
    </ul>
  );
}
