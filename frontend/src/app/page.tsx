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
  CheckCircle2,
  Settings,
  Globe,
} from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import type { User } from "@supabase/supabase-js";

const TARGET_USERS = [
  {
    name: "Siswa",
    image: "/landing/persona-siswa.png",
    description: "Cari profesi impianmu yang sesuai dengan minat dan kemampuanmu.",
  },
  {
    name: "Sekolah",
    image: "/landing/persona-sekolah.png",
    description: "Bantu siswa memahami dan merencanakan arah karier mereka.",
  },
  {
    name: "Professional",
    image: "/landing/persona-professional.png",
    description: "Rancang roadmap karier impian atau rintis usaha lewat panduan rencana aksi harian.",
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
  "Mudah mengetahui apa yang harus dilakukan hari ini",
  "Melihat milestone berikutnya",
  "Melacak progress secara konsisten",
  "Tetap termotivasi setiap hari",
];

export default function LandingPage() {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleStartJourney = (e: React.MouseEvent) => {
    if (!user) {
      e.preventDefault();
      // Dispatch custom event to open auth modal
      window.dispatchEvent(
        new CustomEvent("open-auth-modal", { detail: { mode: "prompt" } })
      );
    }
  };

  return (
    <div className="w-full bg-[#fdfdfd] text-slate-900 overflow-x-hidden">
      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-b from-[#f3f8ff]/50 via-white to-white">
        <div className="absolute top-0 right-0 w-[36rem] h-[36rem] translate-x-1/4 -translate-y-1/4 rounded-full bg-gradient-to-br from-[#ddd5fc]/50 via-[#ddd5fc]/20 to-transparent blur-3xl pointer-events-none" />

        <div className="relative max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-20 lg:py-24 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <div className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-[#1e69dc] text-white text-xs font-extrabold shadow-xs select-none">
              <Sparkles className="w-3.5 h-3.5 fill-white/20" />
              AI-Powered Career Journey
            </div>

            <h1 className="mt-5 text-3xl sm:text-4xl lg:text-5xl font-black tracking-tight leading-[1.1] text-slate-900">
              Temukan Profesi Impianmu.
              <br />
              Jalani Langkahnya.
              <br />
              Capai Masa Depanmu.
            </h1>

            <p className="mt-4 text-sm sm:text-base text-slate-500 max-w-lg mx-auto lg:mx-0 leading-relaxed font-semibold">
              Navika membantumu menemukan profesi yang tepat, menyusun roadmap personal, dan
              menjalani langkah kecil setiap hari menuju karier impian.
            </p>

            <div className="mt-6 flex items-center justify-center lg:justify-start gap-8">
              <div>
                <div className="text-xl sm:text-2xl font-black text-slate-900">300++</div>
                <div className="text-xs text-slate-500 font-bold">Profesi</div>
              </div>
              <div>
                <div className="text-xl sm:text-2xl font-black text-slate-900">5000++</div>
                <div className="text-xs text-slate-500 font-bold">Skill &amp; Aktivitas</div>
              </div>
            </div>

            <div className="mt-7">
              <Link
                href="/student"
                onClick={handleStartJourney}
                className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-[#7033ff] hover:bg-[#5c25e6] active:bg-[#4b1ec5] text-white text-sm font-bold shadow-sm hover:shadow-md transition-all cursor-pointer border-0 outline-none"
              >
                Mulai Career Journey Gratis
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          <div className="w-full max-w-md mx-auto lg:max-w-none">
            <Image
              src="/landing/hero-roadmap.png"
              alt="Ilustrasi roadmap karier"
              width={748}
              height={499}
              className="w-full h-auto"
              priority
            />
          </div>
        </div>
      </section>

      {/* Target Users */}
      <section className="bg-[#e2e8f0] py-16 sm:py-20 border-y border-slate-100/50">
        <div className="max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="text-xs font-black uppercase tracking-wider text-[#7033ff]">Target Users</div>
          <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900">Siapa Pengguna Navika?</h2>
          <p className="mt-3 text-sm text-slate-500 max-w-2xl mx-auto leading-relaxed font-semibold">
            Setiap orang memiliki perjalanan karier yang berbeda. Kami membantu siswa menemukan
            arah, sekolah membimbing talenta, fresh graduate memasuki dunia kerja, dan profesional
            yang memulai bidang profesi baru.
          </p>

          <div className="mt-10 grid sm:grid-cols-3 gap-5 text-left">
            {TARGET_USERS.map((user) => (
              <div key={user.name} className="bg-white rounded-2xl p-5 shadow-xs border border-slate-100 flex items-start gap-4 hover:shadow-sm transition-all duration-300">
                <div className="w-14 h-14 rounded-full overflow-hidden shrink-0 bg-slate-100 relative">
                  <Image src={user.image} alt={user.name} fill sizes="56px" className="object-cover" />
                </div>
                <div>
                  <div className="font-extrabold text-sm text-slate-900">{user.name}</div>
                  <p className="mt-1 text-xs text-slate-500 leading-relaxed font-semibold">{user.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Product Features */}
      <section className="bg-[#f8fafc] py-16 sm:py-20">
        <div className="max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="text-xs font-black uppercase tracking-wider text-[#7033ff]">Product Features</div>
          <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900">
            Semua yang Kamu Butuhkan dalam Satu Platform
          </h2>
          <p className="mt-3 text-sm text-slate-500 max-w-2xl mx-auto leading-relaxed font-semibold">
            Navika - Career Journey membantu mengubah tujuan karier menjadi langkah-langkah nyata
            melalui rekomendasi personal, roadmap terstruktur, dan progres yang mudah dipahami.
          </p>

          <div className="mt-10 grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-6">
            {PRODUCT_FEATURES.map((feature) => {
              const Icon = feature.icon;
              return (
                <div key={feature.name} className="flex flex-row sm:flex-col items-center sm:text-center gap-4 sm:gap-0 text-left bg-white sm:bg-transparent p-4 sm:p-0 rounded-2xl border border-slate-100 sm:border-0 shadow-xs sm:shadow-none hover:shadow-xs sm:hover:shadow-none transition-all">
                  <div className="w-12 h-12 rounded-full bg-[#7033ff]/10 flex items-center justify-center text-[#7033ff] shrink-0">
                    <Icon className="w-5 h-5" />
                  </div>
                  <div className="sm:mt-3">
                    <div className="text-sm font-extrabold text-slate-900">{feature.name}</div>
                    <p className="mt-1 text-xs text-slate-500 leading-relaxed font-semibold">{feature.description}</p>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="mt-14 max-w-4xl mx-auto rounded-3xl overflow-hidden shadow-xs border border-slate-100 bg-white p-2">
            <Image
              src="/landing/journey-path.png"
              alt="Ilustrasi perjalanan karier"
              width={807}
              height={374}
              className="w-full h-auto rounded-2xl"
            />
          </div>
        </div>
      </section>

      {/* Dashboard CTA split */}
      <section className="bg-[#5b21b6] py-16 sm:py-20 text-white relative overflow-hidden">
        <div className="absolute top-0 left-0 w-full h-full bg-linear-to-b from-black/5 to-transparent pointer-events-none" />
        <div className="max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center relative z-10">
          <div className="text-center lg:text-left order-2 lg:order-1">
            <div className="inline-flex items-center px-3 py-1 rounded-full bg-white/10 text-white text-[10px] font-black uppercase tracking-wider border border-white/10">
              Tampilan dashboard-mu
            </div>
            <h2 className="mt-4 text-2xl sm:text-3xl font-black text-white leading-tight">
              Fokus pada Langkahmu,
              <br />
              Kami yang Bantu Arahkan
            </h2>
            <p className="mt-3 text-sm text-indigo-100 max-w-md mx-auto lg:mx-0 leading-relaxed font-medium">
              Lihat tugas hari ini, milestone berikutnya, dan progress perjalanan kariermu dalam
              dashboard yang sederhana.
            </p>
            <ul className="mt-6 space-y-2.5 inline-block text-left">
              {DASHBOARD_HIGHLIGHTS.map((item) => (
                <li key={item} className="flex items-center gap-2.5 text-sm text-white/90 font-semibold">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
          </div>

          <div className="order-1 lg:order-2 max-w-md mx-auto w-full">
            <Image
              src="/landing/phone-mockup.png"
              alt="Tampilan dashboard Navika"
              width={588}
              height={469}
              className="w-full h-auto drop-shadow-2xl"
            />
          </div>
        </div>
      </section>

      {/* Career Knowledge Graph */}
      <section className="bg-white py-16 sm:py-20">
        <div className="max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <div className="text-xs font-black uppercase tracking-wider text-[#7033ff]">Career Building</div>
            <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
              Menggunakan Career
              <br className="hidden sm:block" /> Knowledge Graph
            </h2>
            <p className="mt-3 text-sm text-slate-500 max-w-md mx-auto lg:mx-0 leading-relaxed font-semibold">
              Diambil dari berbagai sumber dan semua entitas data saling terhubung untuk
              menampilkan rekomendasi yang lebih relevan dan akurat.
            </p>
          </div>

          <div className="max-w-xs mx-auto w-full">
            <Image
              src="/landing/knowledge-graph.png"
              alt="Ilustrasi Career Knowledge Graph"
              width={384}
              height={555}
              className="w-full h-auto drop-shadow-md"
            />
          </div>
        </div>
      </section>

      {/* Closing CTA */}
      <section className="px-4 sm:px-6 lg:px-8 pb-16 sm:pb-20">
        <div className="max-w-[1200px] mx-auto relative overflow-hidden rounded-3xl bg-gradient-to-r from-[#7033ff] via-[#5c25e6] to-[#4b1ec5] px-6 sm:px-10 py-10 sm:py-12 flex flex-col sm:flex-row items-center gap-6 text-center sm:text-left min-h-[220px] sm:min-h-[260px] shadow-lg">
          <div className="absolute left-0 sm:left-4 bottom-0 w-64 sm:w-96 opacity-95 pointer-events-none hidden sm:block">
            <Image
              src="/landing/mountain-glow.png"
              alt=""
              width={355}
              height={180}
              className="w-full h-auto"
            />
          </div>

          <div className="relative flex-1 sm:pl-40 lg:pl-48">
            <h2 className="text-xl sm:text-2xl font-black text-white leading-snug">
              Masa depan tidak dibangun dalam semalam,
              <br />
              tapi bisa dimulai dari hari ini.
            </h2>
            <p className="mt-2 text-sm text-indigo-100 font-semibold">
              Mulai perjalanan kariermu sekarang. Gratis.
            </p>
          </div>

          <Link
            href="/student"
            onClick={handleStartJourney}
            className="relative inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white text-[#7033ff] hover:text-[#5c25e6] hover:bg-slate-50 text-sm font-bold shadow-md hover:shadow-lg transition-all shrink-0 cursor-pointer border-0 outline-none"
          >
            Mulai Gratis
            <ArrowRight className="w-4 h-4 text-[#7033ff]" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-100 py-8 bg-[#fdfdfd]">
        <div className="max-w-[1200px] mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2 select-none">
            <div className="w-6 h-6 rounded-md bg-gradient-to-br from-[#7033ff] to-[#a98df7] flex items-center justify-center text-white font-black text-xs">
              N
            </div>
            <span className="font-black text-slate-900 text-sm">Navika</span>
          </div>

          <div className="flex items-center gap-4 text-slate-400">
            <Settings className="w-4 h-4 hover:text-[#7033ff] transition-colors cursor-pointer" />
            <Globe className="w-4 h-4 hover:text-[#7033ff] transition-colors cursor-pointer" />
            <p className="text-xs text-slate-400 font-semibold">
              Brewed with creativity and love by Sub1 Studio. &copy; 2026. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
