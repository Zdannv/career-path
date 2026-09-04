"use client";

/**
 * Satu baris kartu profesi: judul, keterangan, tombol lihat semua, lalu
 * deretan kartu yang bisa digeser.
 *
 * Deretannya memakai scroll-snap dan bukan grid supaya jumlah kartu yang
 * terlihat mengikuti lebar layar tanpa breakpoint tambahan — di ponsel satu
 * setengah kartu, di desktop tiga sampai empat.
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";

type Props = {
  title: string;
  subtitle?: string;
  href: string;
  children: React.ReactNode;
  /** Ditampilkan kalau baris ini tidak menghasilkan satu kartu pun. */
  emptyLabel?: string;
  isEmpty?: boolean;
};

export default function CardRow({ title, subtitle, href, children, emptyLabel, isEmpty }: Props) {
  return (
    <section className="py-5">
      <div className="flex items-start justify-between gap-4 px-4 sm:px-6">
        <div className="min-w-0">
          <h2 className="text-[17px] font-bold tracking-tight text-slate-900">{title}</h2>
          {subtitle && <p className="mt-0.5 text-[13px] leading-relaxed text-slate-500">{subtitle}</p>}
        </div>
        <Link
          href={href}
          aria-label={`Lihat semua ${title}`}
          className="mt-0.5 grid size-9 shrink-0 place-items-center rounded-full border border-slate-200 bg-white text-slate-700 transition-colors hover:bg-slate-50"
        >
          <ArrowRight className="size-4" aria-hidden />
        </Link>
      </div>

      {isEmpty ? (
        <p className="mt-4 px-4 text-[13px] text-slate-400 sm:px-6">{emptyLabel}</p>
      ) : (
        <div className="mt-4 flex snap-x snap-mandatory items-stretch gap-3 overflow-x-auto px-4 pb-2 sm:px-6 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {children}
          <div className="w-1 shrink-0" aria-hidden />
        </div>
      )}
    </section>
  );
}
