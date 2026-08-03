"use client";

import React from "react";
import Link from "next/link";
import { Sparkles, Brain, GraduationCap, Users, ArrowRight, Briefcase, Landmark } from "lucide-react";

export default function LandingPage() {
  return (
    <div className="min-h-[90vh] bg-slate-55 text-slate-900 font-sans flex flex-col justify-center items-center px-4 py-12 md:py-20">
      
      {/* Background blur effects */}
      <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-purple-200 rounded-full mix-blend-multiply filter blur-xl opacity-30 animate-pulse pointer-events-none -z-10" />
      <div className="absolute bottom-1/3 right-1/4 w-80 h-80 bg-indigo-200 rounded-full mix-blend-multiply filter blur-xl opacity-30 animate-pulse pointer-events-none -z-10" />

      <div className="w-full max-w-4xl text-center space-y-8 relative">
        
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-900 text-white text-xs font-bold shadow-sm tracking-wide border border-slate-950 animate-bounce">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Platform Perencanaan Karir IT Modern</span>
        </div>

        {/* Hero Headline */}
        <div className="space-y-4">
          <h1 className="text-4xl md:text-6xl font-black text-slate-900 tracking-tight leading-none">
            Temukan & Petakan <span className="underline decoration-indigo-500 decoration-wavy decoration-3">Karir IT</span> Impianmu
          </h1>
          <p className="text-sm md:text-lg text-slate-550 max-w-2xl mx-auto font-medium leading-relaxed">
            CareerPath AI memadukan kecerdasan buatan (*Active Probing*) dan pencocokan hibrida untuk membimbing siswa SMA/SMK, Kuliah, serta Guru BK dalam merancang peta jalan karier IT multi-tahun yang komprehensif.
          </p>
        </div>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row justify-center items-center gap-4 pt-4">
          <Link 
            href="/student"
            className="w-full sm:w-auto px-8 py-3.5 rounded-lg bg-slate-900 hover:bg-slate-800 text-white font-bold text-sm md:text-base flex items-center justify-center gap-2 shadow-md hover:shadow-lg transition-all transform hover:-translate-y-0.5 cursor-pointer"
          >
            <Brain className="w-5 h-5" /> Mulai Perjalanan Karir <ArrowRight className="w-4 h-4" />
          </Link>
          
          <Link 
            href="/teacher/login"
            className="w-full sm:w-auto px-8 py-3.5 rounded-lg border border-slate-300 bg-white hover:bg-slate-50 text-slate-700 font-bold text-sm md:text-base flex items-center justify-center gap-2 shadow-sm hover:shadow transition-all transform hover:-translate-y-0.5 cursor-pointer"
          >
            <GraduationCap className="w-5 h-5 text-slate-650" /> Portal Guru BK & Pengajar
          </Link>
        </div>

        {/* Feature Highlights Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-12 text-left">
          
          {/* Card 1 */}
          <div className="bg-white/80 backdrop-blur-sm p-6 rounded-xl border border-slate-200 shadow-sm space-y-3 hover:border-slate-350 transition-colors">
            <div className="w-10 h-10 rounded bg-slate-900 text-white flex items-center justify-center shadow">
              <Sparkles className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-sm text-slate-900 leading-snug">Rekomendasi Hibrida</h3>
            <p className="text-xs text-slate-500 font-medium leading-relaxed">
              Pencocokan presisi menggunakan Knowledge-Based & Content-Based Filtering berdasarkan tingkat pendidikan, keahlian spesifik, dan target gaji.
            </p>
          </div>

          {/* Card 2 */}
          <div className="bg-white/80 backdrop-blur-sm p-6 rounded-xl border border-slate-200 shadow-sm space-y-3 hover:border-slate-350 transition-colors">
            <div className="w-10 h-10 rounded bg-slate-900 text-white flex items-center justify-center shadow">
              <Landmark className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-sm text-slate-900 leading-snug">Kalkulator Pendidikan</h3>
            <p className="text-xs text-slate-500 font-medium leading-relaxed">
              Proyeksi pengeluaran biaya sekolah, tempat tinggal, dan biaya hidup riil per bulan yang disesuaikan untuk kebutuhan Wali Murid.
            </p>
          </div>

          {/* Card 3 */}
          <div className="bg-white/80 backdrop-blur-sm p-6 rounded-xl border border-slate-200 shadow-sm space-y-3 hover:border-slate-350 transition-colors">
            <div className="w-10 h-10 rounded bg-slate-900 text-white flex items-center justify-center shadow">
              <Users className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-sm text-slate-900 leading-snug">Dasbor Guru BK</h3>
            <p className="text-xs text-slate-500 font-medium leading-relaxed">
              Monitoring tren pemilihan karir siswa, pembuatan modul orientasi BK berbasis AI, serta pengelolaan kelompok kelas rombel.
            </p>
          </div>

        </div>

      </div>
    </div>
  );
}
