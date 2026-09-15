"use client";

/**
 * Bilah navigasi global — hanya untuk halaman publik.
 *
 * Aplikasi ini punya dua dunia yang navigasinya berbeda, dan mencampurnya
 * adalah sumber kekacauan sebelumnya:
 *
 *   halaman publik   landing, auth, onboarding — dilayani file ini
 *   layar aplikasi   Explore dan tetangganya — punya AppNav sendiri
 *                    (bar atas di desktop, bar bawah di ponsel)
 *
 * Karena itu file ini tidak lagi memuat menu "Dashboard Siswa" ke /student:
 * layar itu sudah dihapus, dan tujuan aplikasi ditentukan AppNav, bukan di
 * sini. Daftar rute yang menyembunyikannya diambil dari lib/routes.ts supaya
 * rute baru cukup didaftarkan di satu tempat.
 */

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import type { User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";
import { Menu, X } from "lucide-react";
import {
  APP_SHELL_ROUTES,
  CHROMELESS_ROUTES,
  HOME_AFTER_ONBOARDING,
  ROUTES,
  cocok,
} from "@/lib/routes";

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [menuTerbuka, setMenuTerbuka] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });
    return () => subscription.unsubscribe();
  }, []);

  // Menutup menu ponsel saat pindah halaman. Tanpa ini, menu tetap terbuka
  // menutupi halaman tujuan.
  useEffect(() => {
    setMenuTerbuka(false);
  }, [pathname]);

  const keluar = async () => {
    await supabase.auth.signOut();
    setUser(null);
    router.push(ROUTES.landing);
  };

  // Auth dan onboarding membawa lockup mereknya sendiri dan merupakan alur yang
  // harus diselesaikan, bukan halaman yang boleh ditinggalkan lewat menu.
  if (cocok(pathname, CHROMELESS_ROUTES)) return null;

  // Layar aplikasi membawa AppNav sendiri. Dua bar bertumpuk membingungkan.
  if (cocok(pathname, APP_SHELL_ROUTES)) return null;

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-slate-100 bg-white">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          <Link href={ROUTES.landing} className="select-none">
            <Image
              src="/navika-logo.png"
              alt="Navika"
              width={101}
              height={32}
              className="h-7 w-auto"
              priority
            />
          </Link>

          <div className="hidden items-center gap-6 sm:flex">
            {user ? (
              <>
                <Link
                  href={HOME_AFTER_ONBOARDING}
                  className="text-sm font-bold text-slate-600 transition-colors hover:text-slate-900"
                >
                  Buka Aplikasi
                </Link>
                <button
                  onClick={keluar}
                  className="cursor-pointer rounded-full border border-slate-200 bg-white px-5 py-2 text-sm font-semibold text-slate-800 transition-all hover:bg-slate-50"
                >
                  Keluar
                </button>
              </>
            ) : (
              <>
                <Link
                  href={ROUTES.login}
                  className="text-sm font-semibold text-slate-500 transition-colors hover:text-slate-900"
                >
                  Masuk
                </Link>
                <Link
                  href={ROUTES.daftar}
                  className="rounded-full bg-gradient-to-r from-indigo-600 to-purple-600 px-5 py-2 text-sm font-semibold text-white shadow-sm transition-all hover:shadow-md"
                >
                  Daftar
                </Link>
              </>
            )}
          </div>

          <button
            onClick={() => setMenuTerbuka((v) => !v)}
            className="-mr-2 cursor-pointer rounded p-2 text-slate-600 hover:bg-slate-100 sm:hidden"
            aria-label="Menu"
            aria-expanded={menuTerbuka}
          >
            {menuTerbuka ? <X className="size-5" /> : <Menu className="size-5" />}
          </button>
        </div>
      </div>

      {menuTerbuka && (
        <div className="space-y-2 border-t border-slate-100 bg-white px-4 py-3 sm:hidden">
          {user ? (
            <>
              <Link
                href={HOME_AFTER_ONBOARDING}
                className="block rounded-md px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Buka Aplikasi
              </Link>
              <button
                onClick={keluar}
                className="block w-full rounded-md bg-slate-800 px-3 py-2 text-center text-sm font-semibold text-white"
              >
                Keluar
              </button>
            </>
          ) : (
            <>
              <Link
                href={ROUTES.login}
                className="block rounded-md px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50"
              >
                Masuk
              </Link>
              <Link
                href={ROUTES.daftar}
                className="block w-full rounded-md bg-gradient-to-r from-indigo-600 to-purple-600 px-3 py-2 text-center text-sm font-semibold text-white"
              >
                Daftar
              </Link>
            </>
          )}
        </div>
      )}
    </nav>
  );
}
