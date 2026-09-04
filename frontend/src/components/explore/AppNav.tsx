"use client";

/**
 * Navigasi aplikasi: lima tujuan yang sama, dua bentuk.
 *
 * Di desktop ia jadi bar atas bersama lockup merek; di ponsel dan tablet jadi
 * bar bawah yang menempel. Daftar tujuannya satu, ditulis sekali di sini,
 * supaya kedua bentuk tidak pelan-pelan berbeda isi.
 */

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Compass, Map, Route, ClipboardList, LineChart } from "lucide-react";

export const TUJUAN = [
  { href: "/explore", label: "Explore", icon: Compass },
  { href: "/roadmap", label: "Roadmap", icon: Map },
  { href: "/journey", label: "Journey", icon: Route },
  { href: "/quest", label: "Quest", icon: ClipboardList },
  { href: "/progress", label: "Progress", icon: LineChart },
] as const;

function aktif(pathname: string, href: string): boolean {
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function AppTopNav() {
  const pathname = usePathname();
  return (
    <header className="sticky top-0 z-30 hidden border-b border-slate-200 bg-white/95 backdrop-blur lg:block">
      <div className="mx-auto flex h-16 max-w-[1440px] items-center gap-6 px-8">
        <Link href="/explore" className="flex items-center gap-3">
          <Image src="/navika-logo.png" alt="" width={28} height={28} className="size-7" aria-hidden />
          <span className="text-[17px] font-bold tracking-tight text-slate-900">Navika</span>
          <span className="h-6 w-px bg-slate-200" aria-hidden />
          <span className="leading-tight">
            <span className="block text-[13px] font-semibold text-slate-900">Career path journey</span>
            <span className="block text-[11px] text-slate-400">Sub1 Studio</span>
          </span>
        </Link>

        <nav aria-label="Navigasi utama" className="ml-auto flex items-center gap-1">
          {TUJUAN.map(({ href, label }) => {
            const on = aktif(pathname, href);
            return (
              <Link
                key={href}
                href={href}
                aria-current={on ? "page" : undefined}
                className={`rounded-full px-4 py-2 text-[14px] transition-colors ${
                  on
                    ? "border border-violet-300 font-semibold text-violet-700"
                    : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {label}
              </Link>
            );
          })}
        </nav>
      </div>
    </header>
  );
}

export function AppBottomNav() {
  const pathname = usePathname();
  return (
    <nav
      aria-label="Navigasi utama"
      className="sticky bottom-0 z-30 border-t border-slate-200 bg-[#EDEBFA] lg:hidden"
      style={{ paddingBottom: "env(safe-area-inset-bottom)" }}
    >
      <ul className="mx-auto flex max-w-2xl items-stretch">
        {TUJUAN.map(({ href, label, icon: Ikon }) => {
          const on = aktif(pathname, href);
          return (
            <li key={href} className="flex-1">
              <Link
                href={href}
                aria-current={on ? "page" : undefined}
                className={`flex flex-col items-center gap-1 py-2.5 text-[11px] transition-colors ${
                  on ? "font-semibold text-violet-700" : "text-slate-500"
                }`}
              >
                <Ikon className="size-5" aria-hidden />
                {label}
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
