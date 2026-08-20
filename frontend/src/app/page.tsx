"use client";

import React from "react";
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
  return (
    <div className="w-full bg-white text-slate-900">
      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-b from-indigo-50 via-purple-50/60 to-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 sm:py-20 lg:py-24 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-white text-indigo-600 text-xs font-bold shadow-sm border border-indigo-100">
              <Sparkles className="w-3.5 h-3.5" />
              AI-Powered Career Journey
            </div>

            <h1 className="mt-5 text-3xl sm:text-4xl lg:text-5xl font-black tracking-tight leading-[1.1] text-slate-900">
              Temukan Profesi Impianmu.
              <br />
              Jalani Langkahnya.
              <br />
              Capai Masa Depanmu.
            </h1>

            <p className="mt-4 text-sm sm:text-base text-slate-500 max-w-lg mx-auto lg:mx-0 leading-relaxed">
              Navika membantumu menemukan profesi yang tepat, menyusun roadmap personal, dan
              menjalani langkah kecil setiap hari menuju karier impian.
            </p>

            <div className="mt-6 flex items-center justify-center lg:justify-start gap-8">
              <div>
                <div className="text-xl sm:text-2xl font-black text-slate-900">300++</div>
                <div className="text-xs text-slate-500 font-medium">Profesi</div>
              </div>
              <div>
                <div className="text-xl sm:text-2xl font-black text-slate-900">5000++</div>
                <div className="text-xs text-slate-500 font-medium">Skill &amp; Aktivitas</div>
              </div>
            </div>

            <div className="mt-7">
              <Link
                href="/daftar"
                className="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white text-sm font-bold shadow-md hover:shadow-lg transition-all cursor-pointer"
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
      <section className="bg-[#dde3f0] py-16 sm:py-20">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="text-xs font-bold uppercase tracking-wide text-indigo-600">Target Users</div>
          <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900">Siapa Pengguna Navika?</h2>
          <p className="mt-3 text-sm text-slate-500 max-w-2xl mx-auto leading-relaxed">
            Setiap orang memiliki perjalanan karier yang berbeda. Kami membantu siswa menemukan
            arah, sekolah membimbing talenta, fresh graduate memasuki dunia kerja, dan profesional
            yang memulai bidang profesi baru.
          </p>

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
      <section className="bg-white py-16 sm:py-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="text-xs font-bold uppercase tracking-wide text-indigo-600">Product Features</div>
          <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900">
            Semua yang Kamu Butuhkan dalam Satu Platform
          </h2>
          <p className="mt-3 text-sm text-slate-500 max-w-2xl mx-auto leading-relaxed">
            Navika - Career Journey membantu mengubah tujuan karier menjadi langkah-langkah nyata
            melalui rekomendasi personal, roadmap terstruktur, dan progres yang mudah dipahami.
          </p>

          <div className="mt-10 grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-6">
            {PRODUCT_FEATURES.map((feature) => {
              const Icon = feature.icon;
              return (
                <div key={feature.name} className="flex flex-row sm:flex-col items-center sm:text-center gap-4 sm:gap-0 text-left">
                  <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 shrink-0">
                    <Icon className="w-5 h-5" />
                  </div>
                  <div className="sm:mt-3">
                    <div className="text-sm font-bold text-slate-900">{feature.name}</div>
                    <p className="mt-1 text-xs text-slate-500 leading-relaxed">{feature.description}</p>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="mt-14 max-w-4xl mx-auto">
            <Image
              src="/landing/journey-path.png"
              alt="Ilustrasi perjalanan karier"
              width={807}
              height={374}
              className="w-full h-auto"
            />
          </div>
        </div>
      </section>

      {/* Dashboard CTA split */}
      <section className="bg-gradient-to-br from-indigo-600 via-purple-600 to-violet-700 py-16 sm:py-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left order-2 lg:order-1">
            <div className="inline-flex items-center px-3 py-1 rounded-full bg-white/15 text-white text-xs font-bold">
              Tampilan dashboard-mu
            </div>
            <h2 className="mt-4 text-2xl sm:text-3xl font-black text-white leading-tight">
              Fokus pada Langkahmu,
              <br />
              Kami yang Bantu Arahkan
            </h2>
            <p className="mt-3 text-sm text-indigo-100 max-w-md mx-auto lg:mx-0 leading-relaxed">
              Lihat tugas hari ini, milestone berikutnya, dan progress perjalanan kariermu dalam
              dashboard yang sederhana.
            </p>
            <ul className="mt-5 space-y-2 inline-block text-left">
              {DASHBOARD_HIGHLIGHTS.map((item) => (
                <li key={item} className="flex items-center gap-2 text-sm text-white/90">
                  <CheckCircle2 className="w-4 h-4 text-emerald-300 shrink-0" />
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
              className="w-full h-auto"
            />
          </div>
        </div>
      </section>

      {/* Career Knowledge Graph */}
      <section className="bg-white py-16 sm:py-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 grid lg:grid-cols-2 gap-12 items-center">
          <div className="text-center lg:text-left">
            <div className="text-xs font-bold uppercase tracking-wide text-indigo-600">Career Building</div>
            <h2 className="mt-2 text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
              Menggunakan Career
              <br className="hidden sm:block" /> Knowledge Graph
            </h2>
            <p className="mt-3 text-sm text-slate-500 max-w-md mx-auto lg:mx-0 leading-relaxed">
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
              className="w-full h-auto"
            />
          </div>
        </div>
      </section>

      {/* Closing CTA */}
      <section className="px-4 sm:px-6 lg:px-8 pb-16 sm:pb-20">
        <div className="max-w-6xl mx-auto relative overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-700 via-purple-700 to-indigo-800 px-6 sm:px-10 py-10 sm:py-12 flex flex-col sm:flex-row items-center gap-6 text-center sm:text-left min-h-[220px] sm:min-h-[260px]">
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
            <p className="mt-2 text-sm text-indigo-100">
              Mulai perjalanan kariermu sekarang. Gratis.
            </p>
          </div>

          <Link
            href="/daftar"
            className="relative inline-flex items-center gap-2 px-6 py-3 rounded-full bg-white text-slate-900 text-sm font-bold shadow-md hover:shadow-lg transition-all shrink-0 cursor-pointer"
          >
            Mulai Gratis
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-100 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 rounded-md bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-black text-xs">
              N
            </div>
            <span className="font-black text-slate-900 text-sm">Navika</span>
          </div>

          <div className="flex items-center gap-4 text-slate-400">
            <Settings className="w-4 h-4" />
            <Globe className="w-4 h-4" />
            <p className="text-xs text-slate-400">
              Brewed with creativity and love by Sub1 Studio. &copy; 2026. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
