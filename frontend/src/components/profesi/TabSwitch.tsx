"use client";

/**
 * Sakelar tab berbentuk pil.
 *
 * Dipakai tiga kali dengan isi berbeda — dua tab di layar kategori, tiga di
 * detail profesi, tiga di lembar Skill Gap. Ditulis sekali supaya ketiganya
 * tidak pelan-pelan berbeda tinggi dan radiusnya.
 */

type Props<T extends string> = {
  tabs: readonly { kode: T; label: string }[];
  aktif: T;
  onPilih: (kode: T) => void;
  className?: string;
};

export default function TabSwitch<T extends string>({
  tabs,
  aktif,
  onPilih,
  className = "",
}: Props<T>) {
  return (
    <div
      role="tablist"
      className={`inline-flex max-w-full items-center gap-1 overflow-x-auto rounded-full bg-slate-100 p-1 ${className}`}
    >
      {tabs.map((t) => {
        const on = t.kode === aktif;
        return (
          <button
            key={t.kode}
            role="tab"
            type="button"
            aria-selected={on}
            onClick={() => onPilih(t.kode)}
            className={`shrink-0 whitespace-nowrap rounded-full px-3.5 py-2 text-[13px] transition-colors ${
              on
                ? "bg-white font-semibold text-slate-900 shadow-sm"
                : "font-medium text-slate-500 hover:text-slate-700"
            }`}
          >
            {t.label}
          </button>
        );
      })}
    </div>
  );
}
