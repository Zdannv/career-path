"use client";

import React from "react";

export type ChipOption = { value: string; label: string };

type ChipGroupProps = {
  legend: string;
  description?: string;
  options: ChipOption[];
  value: string | null;
  onChange: (value: string) => void;
  /** Dipakai untuk menautkan radiogroup ke legend-nya. */
  name: string;
  /** Tampil pudar dan tak bisa dipilih, mis. kelas/semester saat sudah lulus. */
  disabled?: boolean;
};

/**
 * Pilihan berbentuk pill, satu jawaban.
 *
 * Dibangun dari <input type="radio"> yang disembunyikan secara visual, bukan
 * dari <button>. Dengan begitu keyboard bisa berpindah pakai panah seperti
 * radio group biasa, dan pembaca layar mengumumkan "1 dari 10" — perilaku yang
 * harus ditulis manual kalau memakai tombol.
 */
export default function ChipGroup({
  legend,
  description,
  options,
  value,
  onChange,
  name,
  disabled = false,
}: ChipGroupProps) {
  return (
    <fieldset className="min-w-0" disabled={disabled}>
      <legend className={`text-lg font-bold sm:text-xl ${disabled ? "text-slate-300" : "text-slate-900"}`}>
        {legend}
      </legend>
      {description && (
        <p className={`mt-1 text-sm ${disabled ? "text-slate-300" : "text-[#525252]"}`}>{description}</p>
      )}

      <div className="mt-4 flex flex-wrap gap-3">
        {options.map((opt) => {
          const selected = value === opt.value;
          return (
            <label
              key={opt.value}
              className={[
                "select-none rounded-full px-4 py-2.5 text-sm font-medium",
                "shadow-sm ring-1 transition-colors",
                "focus-within:outline focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-[#7033FF]",
                disabled
                  ? "cursor-not-allowed bg-white text-slate-300 ring-slate-100 shadow-none"
                  : selected
                  ? "cursor-pointer bg-[#F1EBFF] text-[#7033FF] ring-[#DDD0FF]"
                  : "cursor-pointer bg-white text-slate-900 ring-slate-200 hover:bg-slate-50",
              ].join(" ")}
            >
              <input
                type="radio"
                name={name}
                value={opt.value}
                checked={selected}
                onChange={() => onChange(opt.value)}
                className="sr-only"
              />
              {opt.label}
            </label>
          );
        })}
      </div>
    </fieldset>
  );
}
