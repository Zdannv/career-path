"use client";

/**
 * Daftar pilihan satu langkah Career DNA.
 *
 * Begitu batas maksimal tercapai, pilihan yang belum dicentang dinonaktifkan
 * dan diredupkan — persis keadaan yang digambar di mockup langkah 1, di mana
 * tiga minat sudah dipilih dan sisanya pudar. Tanpa itu pengguna mengetuk
 * pilihan keempat lalu tidak terjadi apa-apa, dan tidak jelas kenapa.
 *
 * Pilihan yang sudah dicentang pindah ke kelompok ringkas di atas daftar
 * (desain "After" dari Nico). Di ponsel kelompok itu menempel di bawah kepala
 * layar saat daftar digulir, jadi pengguna selalu melihat apa saja yang sudah
 * ia pilih. Bentuknya satu baris per pilihan supaya area gulir untuk opsi
 * lain tetap lega. Menekannya melepas pilihan itu.
 */

import { Check } from "lucide-react";
import type { DnaAttributeOption } from "@/lib/careerDna";

type Props = {
  options: DnaAttributeOption[];
  selected: string[];
  maxPick: number;
  onToggle: (code: string) => void;
};

/** Tinggi kepala layar Career DNA di ponsel (header sticky di DnaFlow). */
const TINGGI_KEPALA = 49;

function Kotak({ aktif }: { aktif: boolean }) {
  return (
    <span
      className={`grid size-[18px] shrink-0 place-items-center rounded-[5px] border ${
        aktif ? "border-violet-600 bg-violet-600" : "border-slate-300 bg-white"
      }`}
      aria-hidden
    >
      {aktif && <Check className="size-3 text-white" strokeWidth={3} />}
    </span>
  );
}

export default function OptionList({ options, selected, maxPick, onToggle }: Props) {
  const penuh = selected.length >= maxPick;
  const dipilih = options.filter((o) => selected.includes(o.code));
  const lainnya = options.filter((o) => !selected.includes(o.code));

  return (
    <div>
      {dipilih.length > 0 && (
        <ul
          aria-label="Pilihanmu"
          className="sticky z-10 -mx-4 flex flex-col gap-2 bg-white px-4 pb-3 pt-2 sm:-mx-6 sm:px-6 lg:static lg:mx-0 lg:px-0 lg:pt-0"
          style={{ top: TINGGI_KEPALA }}
        >
          {dipilih.map((o) => (
            <li key={o.code}>
              <button
                type="button"
                onClick={() => onToggle(o.code)}
                aria-pressed
                aria-label={`${o.name} (dipilih, ketuk untuk melepas)`}
                className="flex w-full items-center gap-3 rounded-xl border border-violet-500 bg-violet-50/60 px-4 py-2.5 text-left"
              >
                <Kotak aktif />
                <span className="min-w-0 truncate text-[13.5px] text-slate-900">
                  <span className="font-semibold">{o.name}</span>
                  {o.hint && <span className="text-slate-500"> · {o.hint}</span>}
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}

      <ul className="flex flex-col gap-2.5">
        {lainnya.map((o) => {
          const nonaktif = penuh;
          return (
            <li key={o.code}>
              <button
                type="button"
                onClick={() => onToggle(o.code)}
                disabled={nonaktif}
                aria-pressed={false}
                className={`flex w-full items-start gap-3 rounded-xl border px-4 py-3 text-left transition-colors ${
                  nonaktif
                    ? "cursor-not-allowed border-slate-200 bg-white opacity-45"
                    : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                <span className="mt-0.5"><Kotak aktif={false} /></span>
                <span className="min-w-0">
                  <span className="block text-[13.5px] font-semibold leading-snug text-slate-900">{o.name}</span>
                  {o.hint && (
                    <span className="mt-0.5 block text-[12.5px] leading-relaxed text-slate-500">{o.hint}</span>
                  )}
                </span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
