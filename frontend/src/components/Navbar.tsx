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
import { ambilProfil } from "@/lib/profil";
import {
  ChevronRight,
  ChevronsUpDown,
  LayoutDashboard,
  Map,
  Menu,
  PieChart,
  ScrollText,
  X,
  type LucideIcon,
} from "lucide-react";
import {
  APP_SHELL_ROUTES,
  CHROMELESS_ROUTES,
  HOME_AFTER_ONBOARDING,
  ROUTES,
  cocok,
} from "@/lib/routes";

/** Isi grup "Platform" di menu ponsel. Dashboard adalah Explore. */
const MENU_PLATFORM: { label: string; href: string; icon: LucideIcon }[] = [
  { label: "Dashboard", href: HOME_AFTER_ONBOARDING, icon: LayoutDashboard },
  { label: "Journey", href: ROUTES.journey, icon: Map },
  { label: "Quest", href: ROUTES.quest, icon: ScrollText },
  { label: "Progress", href: ROUTES.progress, icon: PieChart },
];

/** Lockup "Navika | Career path journey" yang sama dengan halaman auth. */
function Lockup() {
  return (
    <Link href={ROUTES.landing} className="flex select-none items-center gap-3">
      <Image src="/navika-logo.png" alt="Navika" width={101} height={32} className="h-7 w-auto" priority />
      <span className="h-8 w-px bg-slate-200" aria-hidden />
      <span className="leading-tight">
        <span className="block text-sm font-bold text-slate-900">Career path journey</span>
        <span className="block text-xs text-slate-400">Sub1 Studio</span>
      </span>
    </Link>
  );
}

/**
 * Pengunjung yang belum masuk tetap melihat menu Platform, tetapi memilihnya
 * membuka ajakan masuk ini alih-alih melempar ke halaman login tanpa konteks.
 */
function DialogMasukDulu({ tujuan, onClose }: { tujuan: string; onClose: () => void }) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const next = `?next=${encodeURIComponent(tujuan)}`;
  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/40 px-5" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Masuk Akun"
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[400px] rounded-3xl bg-white p-6 shadow-2xl"
      >
        <div className="flex items-start justify-between">
          <h2 className="text-lg font-bold text-slate-900">Masuk Akun</h2>
          <button type="button" onClick={onClose} aria-label="Tutup" className="cursor-pointer text-slate-500 hover:text-slate-900">
            <X className="h-5 w-5" />
          </button>
        </div>
        <Image
          src="/auth/login-illustration.webp"
          alt=""
          width={1376}
          height={933}
          className="mx-auto mt-6 h-auto w-full max-w-[300px]"
        />
        <p className="mt-4 text-center text-lg font-bold text-slate-900">Ups, masuk dulu yuk!</p>
        <p className="mt-1.5 text-center text-sm leading-relaxed text-slate-700">
          Kamu perlu login ke akunmu untuk lanjut ke halaman berikutnya
        </p>
        <div className="mt-8 grid grid-cols-2 gap-3">
          <Link
            href={ROUTES.daftar}
            className="rounded-full bg-white py-3 text-center text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-slate-200 hover:bg-slate-50"
          >
            Daftar
          </Link>
          <Link
            href={`${ROUTES.login}${next}`}
            className="rounded-full bg-[#7033FF] py-3 text-center text-sm font-semibold text-white hover:bg-[#5f27e6]"
          >
            Masuk Akun
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function Navbar() {
  const pathname = usePathname();
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  // Menu dan ajakan masuk dicatat beserta halaman tempat keduanya dibuka.
  // Pindah halaman otomatis menutup keduanya tanpa effect tambahan.
  const [menuDi, setMenuDi] = useState<string | null>(null);
  const menuTerbuka = menuDi === pathname;
  const [perluMasukDi, setPerluMasukDi] = useState<{ di: string; tujuan: string } | null>(null);
  const perluMasuk = perluMasukDi?.di === pathname ? perluMasukDi.tujuan : null;
  const setPerluMasuk = (tujuan: string | null) =>
    setPerluMasukDi(tujuan ? { di: pathname, tujuan } : null);
  const [profil, setProfil] = useState<{ nama: string; email: string; avatar: string | null } | null>(null);

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

  // Nama dan avatar untuk kartu akun di bawah menu ponsel. Diambil sekali
  // saat menu pertama dibuka, bukan di setiap halaman publik.
  useEffect(() => {
    if (!menuTerbuka || !user || profil) return;
    ambilProfil()
      .then((p) => p && setProfil({ nama: p.nama_tampil, email: p.email, avatar: p.avatar_url }))
      .catch(() => setProfil({ nama: user.email?.split("@")[0] ?? "Akun", email: user.email ?? "", avatar: null }));
  }, [menuTerbuka, user, profil]);

  // Laci menu menutupi seluruh layar; halaman di belakangnya tidak boleh ikut
  // tergulir.
  useEffect(() => {
    if (!menuTerbuka) return;
    const lama = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = lama;
    };
  }, [menuTerbuka]);

  const keluar = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setProfil(null);
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
          <Lockup />

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
            onClick={() => setMenuDi(menuTerbuka ? null : pathname)}
            className="-mr-2 cursor-pointer rounded p-2 text-slate-700 hover:bg-slate-100 sm:hidden"
            aria-label={menuTerbuka ? "Tutup menu" : "Menu"}
            aria-expanded={menuTerbuka}
          >
            {menuTerbuka ? <X className="size-5" /> : <Menu className="size-6" />}
          </button>
        </div>
      </div>

      {menuTerbuka && (
        <div className="fixed inset-x-0 bottom-0 top-16 z-50 flex flex-col bg-slate-50 px-5 pb-5 pt-6 sm:hidden">
          <p className="px-1 text-sm text-slate-500">Platform</p>
          <ul className="mt-3 space-y-1">
            {MENU_PLATFORM.map(({ label, href, icon: Icon }) => {
              const isi = (
                <>
                  <Icon className="size-5 text-slate-700" />
                  <span className="flex-1 text-left">{label}</span>
                  <ChevronRight className="size-4 text-slate-700" />
                </>
              );
              const kelas = "flex w-full cursor-pointer items-center gap-3 rounded-lg px-1 py-2.5 text-base text-slate-900 hover:bg-slate-100";
              return (
                <li key={label}>
                  {user ? (
                    <Link href={href} className={kelas}>{isi}</Link>
                  ) : (
                    <button type="button" onClick={() => setPerluMasuk(href)} className={kelas}>{isi}</button>
                  )}
                </li>
              );
            })}
          </ul>

          <div className="mt-auto">
            {user ? (
              <div className="space-y-2">
                <Link href={ROUTES.profil} className="flex items-center gap-3 rounded-xl px-1 py-2 hover:bg-slate-100">
                  <Image
                    src={profil?.avatar || "/avatar-default.webp"}
                    alt=""
                    width={40}
                    height={40}
                    unoptimized={Boolean(profil?.avatar)}
                    className="size-10 rounded-full object-cover"
                  />
                  <span className="min-w-0 flex-1 leading-tight">
                    <span className="block truncate text-base font-bold text-slate-900">
                      {profil?.nama ?? user.email?.split("@")[0]}
                    </span>
                    <span className="block truncate text-sm text-slate-600">{profil?.email ?? user.email}</span>
                  </span>
                  <ChevronsUpDown className="size-4 text-slate-700" />
                </Link>
                <button
                  onClick={keluar}
                  className="w-full cursor-pointer rounded-full bg-white py-3 text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-slate-200"
                >
                  Keluar
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3">
                <Link
                  href={ROUTES.login}
                  className="rounded-full bg-white py-3 text-center text-base font-semibold text-slate-900 shadow-sm ring-1 ring-slate-200"
                >
                  Masuk
                </Link>
                <Link
                  href={ROUTES.daftar}
                  className="rounded-full bg-[#7033FF] py-3 text-center text-base font-semibold text-white"
                >
                  Daftar
                </Link>
              </div>
            )}
          </div>
        </div>
      )}

      {perluMasuk && <DialogMasukDulu tujuan={perluMasuk} onClose={() => setPerluMasuk(null)} />}
    </nav>
  );
}
