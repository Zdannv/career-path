"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { 
  Briefcase, 
  MapPin, 
  Landmark, 
  Cpu, 
  ArrowLeft, 
  Search, 
  Sparkles,
  Layers,
  Loader2
} from "lucide-react";

interface JobItem {
  title: string;
  type: "Full-time" | "Gigs / Freelance";
  city: string;
  salary_min?: number;
  salary_max?: number;
  salary_range?: string; // For gigs
  skills: string[];
}

export default function JobsGigsExplorer() {
  const [jobs, setJobs] = useState<JobItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Filters State
  const [selectedCity, setSelectedCity] = useState<string>("Semua Kota");
  const [selectedType, setSelectedType] = useState<string>("Semua Tipe");
  const [searchQuery, setSearchQuery] = useState<string>("");

  useEffect(() => {
    fetchJobsAndGigs();
  }, []);

  const fetchJobsAndGigs = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("http://localhost:8000/api/jobs/trends");
      if (!res.ok) {
        throw new Error("Gagal memuat tren lowongan kerja IT.");
      }
      const data = await res.json();
      
      // Combine full time and freelance lists
      const combined: JobItem[] = [];
      
      if (data.full_time_jobs) {
        data.full_time_jobs.forEach((j: any) => {
          combined.push(j);
        });
      }
      if (data.freelance_gigs) {
        data.freelance_gigs.forEach((g: any) => {
          combined.push(g);
        });
      }
      
      setJobs(combined);
    } catch (err: any) {
      setError(err.message || "Gagal menghubungi API Server.");
    } finally {
      setLoading(false);
    }
  };

  const formatIDR = (num?: number) => {
    if (num === undefined) return "Rp 0";
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0
    }).format(num);
  };

  // Filter logic
  const filteredJobs = jobs.filter((job) => {
    const matchesCity = selectedCity === "Semua Kota" || job.city.toLowerCase().includes(selectedCity.toLowerCase());
    const matchesType = selectedType === "Semua Tipe" || job.type === selectedType;
    const matchesSearch = searchQuery.trim() === "" || 
      job.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      job.skills.some(s => s.toLowerCase().includes(searchQuery.toLowerCase()));
    
    return matchesCity && matchesType && matchesSearch;
  });

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 md:p-8 w-full flex justify-center">
      <div className="w-full max-w-5xl space-y-6">

        {/* Top Header Banner */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div className="space-y-1">
            <Link 
              href="/"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> Kembali ke Halaman Utama
            </Link>
            <h1 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-2">
              <Briefcase className="w-6 h-6 text-slate-900" />
              Eksplorasi Tren Lowongan & Gigs IT
            </h1>
            <p className="text-xs text-slate-500 font-medium">Tren Pasar Kerja IT Indonesia untuk Lulusan Baru (Fresh Graduate) & Siswa SMA/SMK</p>
          </div>

          <div className="px-3 py-1.5 rounded-full bg-emerald-50 text-[10px] font-bold text-emerald-700 border border-emerald-250/60 flex items-center gap-1">
            <Sparkles className="w-3.5 h-3.5 animate-pulse" /> Update LinkedIn 2025
          </div>
        </div>

        {/* Filters Panel */}
        <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-sm grid grid-cols-1 sm:grid-cols-12 gap-3 text-xs font-semibold">
          
          {/* Search bar */}
          <div className="sm:col-span-6 relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="Cari karir IT atau keahlian (contoh: React, Figma)..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded pl-9 pr-3 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
            />
          </div>

          {/* City filter */}
          <div className="sm:col-span-3">
            <select
              value={selectedCity}
              onChange={(e) => setSelectedCity(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded px-2.5 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
            >
              <option value="Semua Kota">Semua Kota</option>
              <option value="Jakarta">Jakarta</option>
              <option value="Bandung">Bandung</option>
              <option value="Surabaya">Surabaya</option>
              <option value="Yogyakarta">Yogyakarta</option>
              <option value="Malang">Malang</option>
            </select>
          </div>

          {/* Job Type filter */}
          <div className="sm:col-span-3">
            <select
              value={selectedType}
              onChange={(e) => setSelectedType(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded px-2.5 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
            >
              <option value="Semua Tipe">Semua Tipe Pekerjaan</option>
              <option value="Full-time">Full-time (Penuh Waktu)</option>
              <option value="Gigs / Freelance">Gigs / Freelance</option>
            </select>
          </div>

        </div>

        {/* Content list */}
        {loading ? (
          <div className="bg-white p-16 rounded-lg border border-slate-200 shadow-sm flex flex-col items-center justify-center space-y-3">
            <Loader2 className="w-8 h-8 animate-spin text-slate-500" />
            <p className="text-xs text-slate-500 font-bold">Menghubungkan ke Pusat Tren Karir IT...</p>
          </div>
        ) : error ? (
          <div className="bg-white p-12 rounded-lg border border-slate-200 shadow-sm text-center space-y-4">
            <p className="text-sm text-rose-600 font-bold">{error}</p>
            <button
              onClick={fetchJobsAndGigs}
              className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded shadow cursor-pointer transition-colors"
            >
              Coba Hubungkan Kembali
            </button>
          </div>
        ) : (
          <div className="space-y-4">
            <div className="flex justify-between items-center text-xs font-bold text-slate-500">
              <p>Menampilkan {filteredJobs.length} Tren Peluang IT</p>
              <p className="italic">Data bersifat direktif & indikatif gaji pasar</p>
            </div>

            {filteredJobs.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {filteredJobs.map((job, idx) => {
                  const isGig = job.type === "Gigs / Freelance";
                  
                  return (
                    <div 
                      key={idx} 
                      className="bg-white rounded-lg border border-slate-200 p-5 shadow-sm hover:border-slate-350 transition-all duration-200 flex flex-col justify-between space-y-4"
                    >
                      <div className="space-y-2">
                        {/* Type Badge */}
                        <div className="flex justify-between items-start">
                          <span className={`px-2 py-0.5 rounded text-[9px] font-bold border flex items-center gap-1 ${
                            isGig 
                              ? "bg-purple-50 text-purple-700 border-purple-200" 
                              : "bg-slate-900 text-white border-slate-950"
                          }`}>
                            {isGig ? <Layers className="w-3 h-3" /> : <Briefcase className="w-3 h-3" />}
                            {job.type}
                          </span>

                          <span className="text-[10px] font-bold text-slate-500 flex items-center gap-1">
                            <MapPin className="w-3.5 h-3.5 text-slate-400" />
                            {job.city}
                          </span>
                        </div>

                        {/* Title */}
                        <h3 className="font-bold text-sm text-slate-900 tracking-tight leading-snug">
                          {job.title}
                        </h3>
                      </div>

                      {/* Salary Projections */}
                      <div className="flex items-center gap-1.5 text-slate-500 border-t border-slate-100 pt-3">
                        <Landmark className="w-4 h-4 text-slate-400 shrink-0" />
                        <span className="text-[10px] font-bold">Estimasi Pendapatan:</span>
                        <span className="text-xs font-black text-slate-900">
                          {isGig 
                            ? job.salary_range 
                            : `${formatIDR(job.salary_min)} - ${formatIDR(job.salary_max)} /bln`
                          }
                        </span>
                      </div>

                      {/* Skills Badges */}
                      <div className="space-y-1.5 pt-2 border-t border-slate-100">
                        <span className="text-[9px] font-bold text-slate-400 uppercase tracking-wider block">Keahlian Utama:</span>
                        <div className="flex flex-wrap gap-1">
                          {job.skills.map((skill, sIdx) => (
                            <span 
                              key={sIdx}
                              className="px-2 py-0.5 rounded text-[9px] bg-slate-100 text-slate-650 border border-slate-200 font-bold"
                            >
                              {skill}
                            </span>
                          ))}
                        </div>
                      </div>

                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="p-12 text-center bg-white border border-slate-200 rounded-lg flex flex-col items-center justify-center space-y-2">
                <Cpu className="w-10 h-10 text-slate-300" />
                <p className="text-xs text-slate-500 font-bold">Tidak ada kecocokan lowongan/gigs IT.</p>
                <p className="text-[10px] text-slate-400 font-medium">Ubah kata pencarian atau setelan filter kota Anda.</p>
              </div>
            )}
          </div>
        )}

      </div>
    </div>
  );
}
