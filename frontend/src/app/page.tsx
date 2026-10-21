"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import {
  Sparkles,
  ArrowRight,
  Search,
  Map,
  Route,
  TrendingUp,
  Trophy,
  Check,
  Globe,
} from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { postLoginDestination, HOME_AFTER_ONBOARDING } from "@/lib/postAuth";
import type { User } from "@supabase/supabase-js";
import KampusRelevanLanding from "@/components/landing/KampusRelevanLanding";

/** lucide-react v1 tidak lagi membawa ikon merek, jadi Instagram digambar di sini. */
function IkonInstagram({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
         strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden>
      <rect x="2" y="2" width="20" height="20" rx="5" />
      <circle cx="12" cy="12" r="4" />
      <circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

const TARGET_USERS = [
  {
    name: "Siswa",
    image: "/landing/persona-siswa.webp",
    description: "Cari profesi impianmu yang sesuai dengan minat dan kemampuanmu.",
  },
  {
    name: "Sekolah",
    image: "/landing/persona-sekolah.webp",
    description: "Bantu siswa memahami dan merencanakan arah karier mereka.",
  },
  {
    name: "Profesional",
    image: "/landing/persona-professional.webp",
    description: "Merancang roadmap karier impian atau memulai merintis usaha.",
  },
];

const PRODUCT_FEATURES = [
  {
    name: "Career Discovery",
    icon: Search,
    description: "Temukan profesi yang sesuai dengan minat dan kemampuanmu.",
  },
  {
    name: "Personalized Roadmap",
    icon: Map,
    description: "Dapatkan roadmap personal yang sesuai kondisi dan tujuanmu.",
  },
  {
    name: "Career Journey",
    icon: Route,
    description: "Lihat perjalananmu dari hari ini hingga mencapai tujuan karier.",
  },
  {
    name: "Progress Tracking",
    icon: TrendingUp,
    description: "Pantau perkembangan dan pencapaianmu secara real-time.",
  },
  {
    name: "Milestone & Quest",
    icon: Trophy,
    description: "Capai milestone kecil dan kumpulkan XP setiap harinya.",
  },
];

const DASHBOARD_HIGHLIGHTS = [
  "Ketahui tugas yang perlu diselesaikan",
  "Lihat milestone berikutnya",
  "Pantau progres karier",
  "Jaga motivasi sepanjang perjalanan",
];

export default function LandingPage() {
  const [user, setUser] = useState<User | null>(null);
  // Tujuan bagi pengunjung yang sudah login; perlu query profil, jadi
  // disimpan di state alih-alih dihitung saat render.
  const [signedInHref, setSignedInHref] = useState(HOME_AFTER_ONBOARDING);

  useEffect(() => {
    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) postLoginDestination().then(setSignedInHref);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) postLoginDestination().then(setSignedInHref);
    });

    return () => subscription.unsubscribe();
  }, []);

  // Pengunjung yang belum masuk ke halaman daftar; yang sudah masuk ke
  // onboarding kalau belum selesai, atau ke berandanya kalau sudah.
  const startJourneyHref = user ? signedInHref : "/daftar";

  return (
    <div className="w-full bg-white text-slate-900">
      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-b from-indigo-50 via-purple-50/60 to-white">
        <div className="absolute top-0 right-0 w-[36rem] h-[36rem] translate-x-1/4 -translate-y-1/4 rounded-full bg-gradient-to-br from-purple-300/50 via-indigo-300/40 to-transparent blur-3xl pointer-events-none" />

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-20 lg:py-24 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-left">
            <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#1E69DC] text-white text-xs font-semibold shadow-sm">
              <Sparkles className="w-3.5 h-3.5" />
              AI-Powered Career Journey
            </div>

            <h1 className="mt-5 text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight leading-none text-slate-900">
              Temukan Profesi Impianmu.
            </h1>

            {/* Di ponsel ilustrasinya duduk di antara judul dan paragraf, seperti
                desain; di layar lebar ia pindah ke kolom kanan. */}
            <Image
              src="/landing/hero-roadmap.webp"
              alt="Ilustrasi roadmap karier"
              width={997}
              height={1240}
              className="mx-auto mt-8 h-auto w-full max-w-sm lg:hidden"
              priority
            />

            <p className="mt-6 lg:mt-4 text-base text-slate-700 max-w-lg leading-relaxed">
              Navika membantumu menemukan profesi yang tepat, menyusun roadmap personal, dan
              menjalani langkah kecil setiap hari menuju karier impian.
            </p>

            <div className="mt-6 flex items-center gap-8">
              <div>
                <div className="text-3xl font-medium text-slate-900">300++</div>
                <div className="text-sm text-slate-400">Profesi</div>
              </div>
              <span className="h-12 w-px bg-slate-200" aria-hidden />
              <div>
                <div className="text-3xl font-medium text-slate-900">5000++</div>
                <div className="text-sm text-slate-400">Skill &amp; Aktivitas</div>
              </div>
            </div>

            <div className="mt-7">
              <Link
                href={startJourneyHref}
                className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-sm font-bold shadow-md hover:shadow-lg transition-all cursor-pointer border-0 outline-none"
              >
                Mulai Career Journey Gratis
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          <div className="hidden w-full lg:block">
            <Image
              src="/landing/hero-roadmap.webp"
              alt="Ilustrasi roadmap karier"
              width={997}
              height={1240}
              className="w-full h-auto"
              priority
            />
          </div>
        </div>
      </section>

      {/* Target Users */}
      <section className="bg-[#dde3f0] py-16 sm:py-20">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl sm:text-4xl font-medium text-slate-900">Siapa Pengguna Navika?</h2>

          <div className="mt-10 grid sm:grid-cols-3 gap-5 text-left">
            {TARGET_USERS.map((user) => (
              <div key={user.name} className="bg-white rounded-2xl p-5 shadow-sm flex items-start gap-4">
                <div className="w-14 h-14 rounded-full overflow-hidden shrink-0 bg-slate-100 relative">
                  <Image src={user.image} alt={user.name} fill sizes="56px" className="object-cover" />
                </div>
                <div>
                  <div className="font-bold text-sm text-slate-900">{user.name}</div>
                  <p className="mt-1 text-xs text-slate-500 leading-relaxed">{user.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Product Features */}
      <section className="bg-white pt-16 sm:pt-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="text-sm font-medium text-[#7033FF]">Product Features</div>
          <h2 className="mt-3 text-3xl sm:text-4xl font-medium text-slate-900">
            Semua yang Kamu Butuhkan dalam Satu Platform
          </h2>

          {/* Ponsel: daftar rata kiri dengan ikon sebaris judul, seperti desain.
              Layar lebar: lima kolom bersebelahan, ikonnya di atas judul. */}
          <div className="mt-10 grid grid-cols-1 gap-7 text-left sm:grid-cols-3 sm:gap-6 sm:text-center lg:grid-cols-5">
            {PRODUCT_FEATURES.map((feature) => {
              const Icon = feature.icon;
              return (
                <div key={feature.name} className="sm:flex sm:flex-col sm:items-center">
                  <div className="flex items-center gap-2.5 sm:flex-col sm:gap-0">
                    <Icon className="w-5 h-5 shrink-0 text-indigo-500 sm:mb-3 sm:h-6 sm:w-6" />
                    <div className="text-base font-bold text-slate-900 sm:text-sm">{feature.name}</div>
                  </div>
                  <p className="mt-1.5 text-sm text-slate-500 leading-relaxed sm:mt-1 sm:text-xs">
                    {feature.description}
                  </p>
                </div>
              );
            })}
          </div>

        </div>

        {/* Ilustrasinya duduk rapat di atas seksi ungu seperti desain: selebar
            layar di ponsel, dan ikut melebar sampai batas isi di layar besar. */}
        <div className="mt-10 w-full sm:mt-14 sm:px-6 lg:px-8">
          <Image
            src="/landing/journey-path.webp"
            alt="Ilustrasi perjalanan karier"
            width={1916}
            height={783}
            className="mx-auto h-auto w-full max-w-5xl"
          />
        </div>
      </section>

      {/* Dashboard CTA split */}
      <section className="bg-gradient-to-br from-indigo-600 via-purple-600 to-violet-700 py-16 sm:py-20 text-white">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-left lg:order-first">
            <div className="inline-flex items-center px-3 py-1 rounded-full border border-white/80 text-white text-xs font-medium">
              Tampilan dashboard-mu
            </div>
            <h2 className="mt-4 text-3xl sm:text-4xl font-medium text-white leading-tight">
              Fokus pada Langkahmu,
              <br />
              Navika yang Bantu Arahkan
            </h2>
            <p className="mt-3 text-base text-white/90 max-w-md leading-relaxed">
              Pantau tugas, milestone, dan progres kariermu dalam satu dashboard.
            </p>
            <ul className="mt-5 space-y-3 text-left">
              {DASHBOARD_HIGHLIGHTS.map((item) => (
                <li key={item} className="flex items-center gap-3 text-sm text-white/90">
                  <Check className="w-5 h-5 text-white shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <div className="max-w-md mx-auto w-full">
            <Image
              src="/landing/phone-mockup.webp"
              alt="Tampilan dashboard Navika"
              width={588}
              height={469}
              className="w-full h-auto"
            />
          </div>
        </div>
      </section>

      <KampusRelevanLanding />

      {/* Closing CTA */}
      <section className="px-4 sm:px-6 lg:px-8 py-16 sm:py-20">
        <div className="max-w-6xl mx-auto overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-700 via-purple-700 to-indigo-800 px-6 sm:px-10 pt-10 sm:py-12 flex flex-col items-start sm:flex-row sm:items-center gap-6 sm:gap-8 text-left">
          {/* Ilustrasinya jadi anak flex, bukan lapisan melayang: di layar
              sedang teksnya sempat tertimpa gunung waktu memakai posisi absolut. */}
          <div className="order-last w-full max-w-xs mx-auto -mb-10 shrink-0 pointer-events-none sm:order-none sm:mx-0 sm:mb-0 sm:-ml-4 sm:w-44 sm:max-w-none sm:self-end lg:w-60">
            <Image
              src="/landing/mountain-glow.webp"
              alt=""
              width={1400}
              height={788}
              className="w-full h-auto"
            />
          </div>

          <div className="flex-1">
            <h2 className="text-xl sm:text-2xl font-bold text-white leading-snug">
              Masa depan tidak dibangun dalam semalam,
              <br />
              tapi bisa dimulai dari hari ini.
            </h2>
            <p className="mt-2 text-sm text-indigo-100">
              Mulai perjalanan kariermu sekarang.
            </p>
          </div>

          <Link
            href={startJourneyHref}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white text-slate-900 text-sm font-bold shadow-md hover:shadow-lg transition-all shrink-0 cursor-pointer border-0 outline-none"
          >
            Mulai Gratis
            <ArrowRight className="w-4 h-4 text-slate-900" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-100 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Image
              src="/navika-logo.png"
              alt="Navika"
              width={101}
              height={32}
              className="h-6 w-auto"
            />
            <span className="h-7 w-px bg-slate-200" aria-hidden />
            <span className="leading-tight">
              <span className="block text-[13px] font-semibold text-slate-900">Career path journey</span>
              <span className="block text-[11px] text-slate-400">Sub1 Studio</span>
            </span>
          </div>

          <div className="flex flex-col items-start gap-3 text-slate-500 sm:flex-row sm:items-center sm:gap-4">
            <div className="flex items-center gap-3">
              <Globe className="w-4 h-4" />
              <IkonInstagram className="w-4 h-4" />
            </div>
            <p className="text-xs text-slate-400">
              Brewed with creativity and love by Sub1 Studio. &copy; 2026. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
