"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import {  GraduationCap, 
  Users, 
  Wallet, 
  BookOpen, 
  Sparkles, 
  Printer, 
  Copy, 
  Check, 
  Briefcase, 
  ArrowLeft, 
  FileText,
  Loader2,
  Plus
} from "lucide-react";

interface TopCareer {
  career_name: string;
  count: number;
}

interface StudentItem {
  student_name: string;
  career_name: string;
  class_code: string;
}

interface AnalyticsData {
  total_journeys: number;
  top_careers: TopCareer[];
  average_cost: number;
  students: StudentItem[];
}

export default function TeacherDashboard() {
  const [activeTab, setActiveTab] = useState<"analytics" | "lesson-helper" | "manage-classes">("analytics");
  
  // Analytics State
  const [analytics, setAnalytics] = useState<AnalyticsData | null>(null);
  const [loadingAnalytics, setLoadingAnalytics] = useState<boolean>(true);
  const [analyticsError, setAnalyticsError] = useState<string | null>(null);

  // Class Code Filtering State
  const [classCodeFilter, setClassCodeFilter] = useState<string>("");
  const [activeClassCode, setActiveClassCode] = useState<string>("");

  // Lesson Helper State
  const [topic, setTopic] = useState<string>("");
  const [gradeLevel, setGradeLevel] = useState<string>("Kelas 12 SMK");
  const [generatingPlan, setGeneratingPlan] = useState<boolean>(false);
  const [generatedPlan, setGeneratedPlan] = useState<string>("");
  const [copied, setCopied] = useState<boolean>(false);

  // Manage Classes State
  const [classes, setClasses] = useState<any[]>([]);
  const [loadingClasses, setLoadingClasses] = useState<boolean>(false);
  const [classesWarning, setClassesWarning] = useState<string | null>(null);
  const [newClassName, setNewClassName] = useState<string>("");
  const [creatingClass, setCreatingClass] = useState<boolean>(false);
  const [createdClassCode, setCreatedClassCode] = useState<string | null>(null);
  const [copiedCodeIndex, setCopiedCodeIndex] = useState<number | null>(null);

  const router = useRouter();
  const [checkingAuth, setCheckingAuth] = useState<boolean>(true);
  const [teacherId, setTeacherId] = useState<string | null>(null);

  // Fetch Analytics & Classes on Mount after checking auth
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (!session) {
        router.push("/teacher/login");
      } else {
        setTeacherId(session.user.id);
        setCheckingAuth(false);
        fetchAnalytics(undefined, session.user.id);
        fetchClasses(session.user.id);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) {
        router.push("/teacher/login");
      } else {
        setTeacherId(session?.user?.id ?? null);
        setCheckingAuth(false);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [router]);

  async function fetchClasses(tId?: string) {
    setLoadingClasses(true);
    setClassesWarning(null);
    try {
      const targetId = tId || teacherId;
      const queryParam = targetId ? `?teacher_id=${targetId}` : "";
      const res = await fetch(`http://localhost:8000/api/teacher/classes${queryParam}`);
      if (!res.ok) {
        throw new Error("Gagal mengambil daftar kelas.");
      }
      const data = await res.json();
      setClasses(data.classes || []);
      if (data.warning) {
        setClassesWarning(data.warning);
      }
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoadingClasses(false);
    }
  }

  const handleCreateClass = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newClassName.trim()) return;
    
    setCreatingClass(true);
    setCreatedClassCode(null);
    try {
      const res = await fetch("http://localhost:8000/api/teacher/classes", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ class_name: newClassName, teacher_id: teacherId })
      });
      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.detail || "Gagal membuat kelas baru.");
      }
      const data = await res.json();
      setCreatedClassCode(data.data.class_code);
      setNewClassName("");
      fetchClasses(); // refresh list
    } catch (err: any) {
      alert(err.message || "Gagal membuat kelas.");
    } finally {
      setCreatingClass(false);
    }
  };

  async function fetchAnalytics(code?: string, tId?: string) {
    setLoadingAnalytics(true);
    setAnalyticsError(null);
    try {
      const targetId = tId || teacherId;
      const params = [];
      if (code) params.push(`class_code=${encodeURIComponent(code)}`);
      if (targetId) params.push(`teacher_id=${targetId}`);
      const queryStr = params.length > 0 ? `?${params.join("&")}` : "";
      
      const res = await fetch(`http://localhost:8000/api/teacher/summary${queryStr}`);
      if (!res.ok) {
        throw new Error("Gagal mengambil data ringkasan siswa.");
      }
      const data = await res.json();
      setAnalytics(data);
    } catch (err: any) {
      setAnalyticsError(err.message || "Gagal menghubungkan ke server backend.");
    } finally {
      setLoadingAnalytics(false);
    }
  }

  const handleFilterSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setActiveClassCode(classCodeFilter);
    fetchAnalytics(classCodeFilter);
  };

  const handleResetFilter = () => {
    setClassCodeFilter("");
    setActiveClassCode("");
    fetchAnalytics();
  };

  const handleGenerateLessonPlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!topic.trim()) return;
    
    setGeneratingPlan(true);
    setGeneratedPlan("");
    try {
      const res = await fetch("http://localhost:8000/api/teacher/lesson-plan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topic, grade_level: gradeLevel })
      });
      if (!res.ok) {
        throw new Error("Gagal menghasilkan materi orientasi dari AI.");
      }
      const data = await res.json();
      setGeneratedPlan(data.lesson_plan);
    } catch (err: any) {
      alert(err.message || "Gagal menghasilkan materi pembelajaran.");
    } finally {
      setGeneratingPlan(false);
    }
  };

  const copyToClipboard = () => {
    if (!generatedPlan) return;
    navigator.clipboard.writeText(generatedPlan);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const printLessonPlan = () => {
    const printWindow = window.open("", "_blank");
    if (!printWindow) return;
    printWindow.document.write(`
      <html>
        <head>
          <title>Materi Pelajaran BK - ${topic}</title>
          <style>
            body { font-family: sans-serif; padding: 40px; color: #1e293b; line-height: 1.6; }
            h1 { font-size: 24px; border-bottom: 2px solid #0f172a; padding-bottom: 10px; margin-bottom: 20px; }
            h2 { font-size: 18px; margin-top: 30px; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; }
            p, li { font-size: 14px; }
            ul { padding-left: 20px; }
            li { margin-bottom: 8px; }
            .meta { font-size: 12px; color: #64748b; margin-bottom: 30px; font-style: italic; }
          </style>
        </head>
        <body>
          <h1>Materi Bimbingan Karir BK</h1>
          <div class="meta">Target Kelas: ${gradeLevel} | Dihasilkan secara otomatis oleh AI Lesson Helper</div>
          <div>${generatedPlan.replace(/\n/g, "<br/>")}</div>
          <script>window.print();</script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const formatIDR = (num: number) => {
    return new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0
    }).format(num);
  };

  if (checkingAuth) {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center space-y-3">
        <Loader2 className="w-8 h-8 animate-spin text-slate-500" />
        <p className="text-xs text-slate-500 font-bold">Memverifikasi sesi Guru BK...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans p-4 md:p-8 w-full flex justify-center">
      <div className="w-full max-w-5xl space-y-6">
        
        {/* Breadcrumb / Top Banner */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
          <div className="space-y-1">
            <Link 
              href="/"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> Kembali ke Halaman Utama
            </Link>
            <h1 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-2">
              <GraduationCap className="w-6 h-6 text-slate-900" />
              Dasbor Administrasi Guru BK & Pengajar
            </h1>
            <p className="text-xs text-slate-500 font-medium">Panel Pemantauan Karir Siswa & Penyusunan Materi Orientasi Akademik</p>
          </div>
          
          <div className="flex gap-2 bg-slate-100 p-1 rounded border border-slate-200">
            <button
              onClick={() => setActiveTab("analytics")}
              className={`px-4 py-1.5 rounded text-xs font-bold transition-all cursor-pointer ${
                activeTab === "analytics" 
                  ? "bg-slate-900 text-white shadow-sm" 
                  : "text-slate-650 hover:text-slate-900"
              }`}
            >
              Ringkasan Siswa
            </button>
            <button
              onClick={() => setActiveTab("manage-classes")}
              className={`px-4 py-1.5 rounded text-xs font-bold transition-all cursor-pointer ${
                activeTab === "manage-classes" 
                  ? "bg-slate-900 text-white shadow-sm" 
                  : "text-slate-650 hover:text-slate-900"
              }`}
            >
              Kelola Kelas
            </button>
            <button
              onClick={() => setActiveTab("lesson-helper")}
              className={`px-4 py-1.5 rounded text-xs font-bold transition-all cursor-pointer ${
                activeTab === "lesson-helper" 
                  ? "bg-slate-900 text-white shadow-sm" 
                  : "text-slate-650 hover:text-slate-900"
              }`}
            >
              AI Asisten Materi
            </button>
          </div>
        </div>

        {/* Tab CONTENT 1: ANALYTICS */}
        {activeTab === "analytics" && (
          <div className="space-y-6">
            
            {/* Filter Bar */}
            <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-sm">
              <form onSubmit={handleFilterSubmit} className="flex flex-col sm:flex-row gap-3 items-end sm:items-center text-xs font-semibold">
                <div className="flex-1 space-y-1 w-full">
                  <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wide">Filter Kode Kelas BK</label>
                  <input
                    type="text"
                    value={classCodeFilter}
                    onChange={(e) => setClassCodeFilter(e.target.value)}
                    placeholder="Masukkan Kode Kelas (Contoh: SMK-BISA-26)"
                    className="w-full bg-slate-50 border border-slate-200 rounded px-3 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
                  />
                </div>
                <div className="flex gap-2 w-full sm:w-auto">
                  <button
                    type="submit"
                    className="flex-1 sm:flex-none px-4 py-2.5 bg-slate-900 hover:bg-slate-800 text-white font-bold rounded shadow transition-colors cursor-pointer"
                  >
                    Filter Kelas
                  </button>
                  {(activeClassCode || classCodeFilter) && (
                    <button
                      type="button"
                      onClick={handleResetFilter}
                      className="flex-1 sm:flex-none px-4 py-2.5 border border-slate-200 hover:bg-slate-100 text-slate-650 font-bold rounded transition-colors cursor-pointer"
                    >
                      Reset
                    </button>
                  )}
                </div>
              </form>
              {activeClassCode && (
                <p className="text-[10px] text-slate-900 font-bold mt-2 bg-slate-100 border border-slate-200 px-2.5 py-1 rounded w-fit">
                  Aktif memfilter kelas: "{activeClassCode}"
                </p>
              )}
            </div>

            {loadingAnalytics ? (
              <div className="bg-white p-12 rounded-lg border border-slate-200 shadow-sm flex flex-col items-center justify-center space-y-3">
                <Loader2 className="w-8 h-8 animate-spin text-slate-500" />
                <p className="text-xs text-slate-500 font-bold">Sedang memproses statistik data siswa...</p>
              </div>
            ) : analyticsError ? (
              <div className="bg-white p-12 rounded-lg border border-slate-200 shadow-sm text-center space-y-4">
                <p className="text-sm text-rose-600 font-bold">{analyticsError}</p>
                <button
                  onClick={() => fetchAnalytics(activeClassCode)}
                  className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded shadow cursor-pointer transition-colors"
                >
                  Coba Lagi
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                
                {/* Stats Card: Total Journeys */}
                <div className="bg-white p-5 rounded-lg border border-slate-200 shadow-sm flex items-center gap-4">
                  <div className="w-12 h-12 rounded bg-slate-900 text-white flex items-center justify-center shadow-md">
                    <Users className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wide">Total Siswa Terdaftar</p>
                    <h2 className="text-2xl font-black text-slate-900 tracking-tight leading-none mt-1">
                      {analytics?.total_journeys} Siswa
                    </h2>
                    <p className="text-[9px] text-slate-500 font-medium mt-1">Telah menyelesaikan asesmen karir BK</p>
                  </div>
                </div>

                {/* Stats Card: Average Cost */}
                <div className="bg-white p-5 rounded-lg border border-slate-200 shadow-sm flex items-center gap-4 md:col-span-2">
                  <div className="w-12 h-12 rounded bg-slate-500 text-white flex items-center justify-center shadow-md">
                    <Wallet className="w-6 h-6" />
                  </div>
                  <div>
                    <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wide">Rata-Rata Anggaran Biaya Pendidikan (Proyeksi Wali Murid)</p>
                    <h2 className="text-2xl font-black text-slate-900 tracking-tight leading-none mt-1">
                      {formatIDR(analytics?.average_cost || 0)}
                    </h2>
                    <p className="text-[9px] text-slate-500 font-medium mt-1">Dihitung secara akumulatif berdasarkan durasi studi anak</p>
                  </div>
                </div>

                {/* Top Matched Careers Table Board */}
                <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-sm md:col-span-3 space-y-4">
                  <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
                    <Briefcase className="w-5 h-5 text-slate-900" />
                    <div>
                      <h3 className="font-bold text-sm text-slate-900 leading-tight">Bidang IT Terpopuler</h3>
                      <p className="text-[10px] text-slate-500 font-semibold">5 Pilihan karir yang paling sering direkomendasikan sistem</p>
                    </div>
                  </div>

                  <div className="overflow-x-auto border border-slate-200 rounded">
                    <table className="w-full text-left border-collapse text-xs">
                      <thead>
                        <tr className="bg-slate-50 border-b border-slate-200 font-bold text-slate-650">
                          <th className="p-3">Peringkat</th>
                          <th className="p-3">Nama Karir IT</th>
                          <th className="p-3 text-right">Jumlah Siswa Terkait</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 font-semibold text-slate-800">
                        {analytics?.top_careers && analytics.top_careers.length > 0 ? (
                          analytics.top_careers.map((career, idx) => (
                            <tr key={idx} className="hover:bg-slate-50/50 transition-colors">
                              <td className="p-3 text-slate-500 font-bold"># {idx + 1}</td>
                              <td className="p-3">{career.career_name}</td>
                              <td className="p-3 text-right text-slate-900 font-bold">{career.count} Siswa</td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td colSpan={3} className="p-6 text-center text-slate-400 italic">Belum ada data akumulasi siswa.</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>

                {/* Student Registry Table Board */}
                <div className="bg-white p-6 rounded-lg border border-slate-200 shadow-sm md:col-span-3 space-y-4">
                  <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
                    <Users className="w-5 h-5 text-slate-900" />
                    <div>
                      <h3 className="font-bold text-sm text-slate-900 leading-tight">Daftar Pilihan Karir Siswa</h3>
                      <p className="text-[10px] text-slate-500 font-semibold">Pemetaan pilihan karir individu siswa berdasarkan sesi asesmen</p>
                    </div>
                  </div>

                  <div className="overflow-x-auto border border-slate-200 rounded">
                    <table className="w-full text-left border-collapse text-xs">
                      <thead>
                        <tr className="bg-slate-50 border-b border-slate-200 font-bold text-slate-650">
                          <th className="p-3">Nama Siswa</th>
                          <th className="p-3">Rencana Karir IT</th>
                          <th className="p-3 text-right">Kode Kelas</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 font-semibold text-slate-800">
                        {analytics?.students && analytics.students.length > 0 ? (
                          analytics.students.map((student, idx) => (
                            <tr key={idx} className="hover:bg-slate-50/50 transition-colors">
                              <td className="p-3 font-bold text-slate-900">{student.student_name}</td>
                              <td className="p-3">{student.career_name}</td>
                              <td className="p-3 text-right text-slate-500 font-bold">{student.class_code}</td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td colSpan={3} className="p-6 text-center text-slate-400 italic">Belum ada siswa yang terdaftar untuk kelas ini.</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>

              </div>
            )}
          </div>
        )}

        {/* Tab CONTENT 2: AI LESSON HELPER */}
        {activeTab === "lesson-helper" && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Input form */}
            <div className="lg:col-span-5 bg-white p-5 rounded-lg border border-slate-200 shadow-sm space-y-4 h-fit">
              <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
                <BookOpen className="w-5 h-5 text-slate-900" />
                <div>
                  <h3 className="font-bold text-sm text-slate-900 leading-tight">Buat Orientasi 3 Bulan</h3>
                  <p className="text-[10px] text-slate-500 font-semibold">Tingkatkan pemahaman karir IT siswa di kelas BK</p>
                </div>
              </div>

              <form onSubmit={handleGenerateLessonPlan} className="space-y-4 text-xs font-semibold">
                
                {/* Topic Input */}
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-slate-650">Topik Peluang Karir / Pembelajaran</label>
                  <textarea
                    rows={3}
                    value={topic}
                    onChange={(e) => setTopic(e.target.value)}
                    required
                    className="w-full bg-white border border-slate-200 rounded p-2.5 text-xs focus:outline-none focus:border-slate-400 text-slate-900 leading-relaxed"
                    placeholder="Contoh: Prospek kerja Cybersecurity di Indonesia dan pentingnya sertifikasi CompTIA Security+."
                  />
                  <p className="text-[9px] text-slate-400 font-medium italic">Jelaskan karir IT spesifik yang ingin diajarkan ke siswa.</p>
                </div>

                {/* Grade Level Select */}
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-slate-650">Target Jenjang / Tingkat Kelas</label>
                  <select
                    value={gradeLevel}
                    onChange={(e) => setGradeLevel(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded px-2 py-2 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
                  >
                    <option value="Kelas 10 SMA/SMK">Kelas 10 SMA/SMK</option>
                    <option value="Kelas 11 SMA/SMK">Kelas 11 SMA/SMK</option>
                    <option value="Kelas 12 SMA/SMK">Kelas 12 SMA/SMK</option>
                    <option value="Mahasiswa Baru (Kuliah)">Mahasiswa Baru (Kuliah)</option>
                  </select>
                </div>

                {/* Generate Button */}
                <button
                  type="submit"
                  disabled={generatingPlan || !topic.trim()}
                  className="w-full py-2.5 rounded bg-slate-900 hover:bg-slate-800 disabled:opacity-50 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                >
                  {generatingPlan ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" /> Sedang Menyusun Materi...
                    </>
                  ) : (
                    <>
                      <Sparkles className="w-4 h-4" /> Susun Rencana Pelajaran BK
                    </>
                  )}
                </button>
              </form>
            </div>

            {/* Markdown Display Area */}
            <div className="lg:col-span-7 bg-white p-6 rounded-lg border border-slate-200 shadow-sm space-y-4 min-h-[450px] flex flex-col justify-between">
              
              <div className="space-y-4 flex-1">
                <div className="flex justify-between items-center border-b border-slate-100 pb-3">
                  <div className="flex items-center gap-2">
                    <FileText className="w-5 h-5 text-slate-900" />
                    <div>
                      <h3 className="font-bold text-sm text-slate-900 leading-tight">Draft Orientasi BK</h3>
                      <p className="text-[10px] text-slate-500 font-semibold">Materi non-psikologis berbasis IT & Anggaran</p>
                    </div>
                  </div>
                  
                  {generatedPlan && (
                    <div className="flex gap-1">
                      <button
                        onClick={copyToClipboard}
                        className="p-2 rounded border border-slate-200 hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-all cursor-pointer"
                        title="Salin Materi"
                      >
                        {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                      </button>
                      <button
                        onClick={printLessonPlan}
                        className="p-2 rounded border border-slate-200 hover:bg-slate-50 text-slate-600 hover:text-slate-900 transition-all cursor-pointer"
                        title="Cetak Rencana"
                      >
                        <Printer className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  )}
                </div>

                {generatedPlan ? (
                  <div className="text-xs text-slate-800 leading-relaxed font-sans prose prose-slate max-w-none overflow-y-auto whitespace-pre-line border border-slate-100 p-4 rounded bg-slate-50 max-h-[500px]">
                    {generatedPlan}
                  </div>
                ) : (
                  <div className="h-64 flex flex-col items-center justify-center text-center p-6 border-2 border-dashed border-slate-200 rounded-lg bg-slate-50/50">
                    <BookOpen className="w-10 h-10 text-slate-350 mb-2" />
                    <p className="text-xs text-slate-500 font-bold">Belum ada orientasi yang disusun.</p>
                    <p className="text-[10px] text-slate-400 font-medium mt-1">Masukkan topik di panel kiri untuk memicu perumusan materi orientasi BK oleh AI.</p>
                  </div>
                )}
              </div>

              {/* Persona BK Info Alert */}
              <div className="p-3.5 rounded bg-amber-50 border border-amber-200 text-[10px] text-amber-800 leading-relaxed font-semibold">
                ⚠️ **Pemberitahuan BK (Non-Psikologis)**: Selaras dengan panduan akademis, materi orientasi BK ini berfokus murni pada eksplorasi teknis jalur studi IT, penyiapan skill, dan anggaran biaya studi secara logis. Tanpa analisis tipe kepribadian (MBTI) atau diagnosa psikologis klinis.
              </div>

            </div>

          </div>
        )}
        {/* Tab CONTENT 3: MANAGE CLASSES */}
        {activeTab === "manage-classes" && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Warning Banner if table classes is not found */}
            {classesWarning && (
              <div className="lg:col-span-12 p-4 rounded-lg bg-amber-50 border border-amber-200 text-xs text-amber-800 leading-relaxed font-semibold space-y-2 shadow-sm">
                <div className="flex items-center gap-2 font-bold text-amber-950">
                  <span className="text-base">⚠️</span> WARNING: Skema Database Belum Siap
                </div>
                <p>
                  Tabel database `classes` belum terdeteksi di Supabase Anda. Anda tetap dapat menggunakan dasbor (sistem akan menggunakan simulasi data kelas sementara), namun untuk mengaktifkan penyimpanan permanen:
                </p>
                <div className="bg-slate-900 text-slate-100 p-3 rounded font-mono text-[10px] mt-2 whitespace-pre-wrap select-all relative group">
                  {`CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_code VARCHAR UNIQUE NOT NULL,
    class_name VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);`}
                </div>
                <p className="text-[10px] text-amber-700 italic">
                  Salin dan jalankan script SQL di atas pada menu SQL Editor di Dashboard Supabase Anda.
                </p>
              </div>
            )}

            {/* Input Form Card */}
            <div className="lg:col-span-5 bg-white p-5 rounded-lg border border-slate-200 shadow-sm space-y-4 h-fit">
              <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
                <Plus className="w-5 h-5 text-slate-900" />
                <div>
                  <h3 className="font-bold text-sm text-slate-900 leading-tight">Buat Kelas Baru</h3>
                  <p className="text-[10px] text-slate-500 font-semibold">Dapatkan kode unik untuk dibagikan ke siswa</p>
                </div>
              </div>

              <form onSubmit={handleCreateClass} className="space-y-4 text-xs font-semibold">
                <div className="space-y-1.5">
                  <label className="text-[11px] font-bold text-slate-650">Nama Kelas / Rombel</label>
                  <input
                    type="text"
                    value={newClassName}
                    onChange={(e) => setNewClassName(e.target.value)}
                    required
                    placeholder="Contoh: XII RPL 1, Kelas BK Budi"
                    className="w-full bg-white border border-slate-200 rounded px-3 py-2.5 text-xs focus:outline-none focus:border-slate-400 text-slate-900"
                  />
                  <p className="text-[9px] text-slate-400 font-medium italic">Saran: Gunakan format yang mudah dipahami siswa.</p>
                </div>

                <button
                  type="submit"
                  disabled={creatingClass || !newClassName.trim()}
                  className="w-full py-2.5 rounded bg-slate-900 hover:bg-slate-800 disabled:opacity-50 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
                >
                  {creatingClass ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" /> Menghasilkan Kode...
                    </>
                  ) : (
                    <>
                      <Plus className="w-4 h-4" /> Buat Kode Kelas
                    </>
                  )}
                </button>
              </form>

              {createdClassCode && (
                <div className="mt-4 p-4 rounded bg-emerald-50 border border-emerald-200 space-y-2">
                  <div className="text-[10px] font-bold text-emerald-800 uppercase tracking-wider">Kode Kelas Berhasil Dibuat!</div>
                  <div className="flex items-center justify-between gap-2 bg-white px-3 py-2 rounded border border-emerald-100 font-mono text-sm font-bold text-slate-800">
                    <span>{createdClassCode}</span>
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText(createdClassCode);
                        alert("Kode kelas disalin ke clipboard!");
                      }}
                      className="text-slate-500 hover:text-slate-900 p-1 cursor-pointer transition-colors"
                      title="Salin Kode"
                    >
                      <Copy className="w-4 h-4" />
                    </button>
                  </div>
                  <p className="text-[9px] text-emerald-700 leading-normal">
                    Bagikan kode ini kepada siswa Anda agar mereka dapat memasukkannya di form chat onboarding.
                  </p>
                </div>
              )}
            </div>

            {/* List Active Classes Card */}
            <div className="lg:col-span-7 bg-white p-6 rounded-lg border border-slate-200 shadow-sm space-y-4">
              <div className="flex items-center gap-2 border-b border-slate-100 pb-3">
                <Users className="w-5 h-5 text-slate-900" />
                <div>
                  <h3 className="font-bold text-sm text-slate-900 leading-tight">Daftar Kelas BK</h3>
                  <p className="text-[10px] text-slate-500 font-semibold">Daftar kode kelas aktif yang telah terdaftar</p>
                </div>
              </div>

              {loadingClasses ? (
                <div className="h-64 flex flex-col items-center justify-center space-y-3">
                  <Loader2 className="w-8 h-8 animate-spin text-slate-500" />
                  <p className="text-xs text-slate-500 font-bold">Mengambil data kelas...</p>
                </div>
              ) : classes.length > 0 ? (
                <div className="overflow-x-auto border border-slate-200 rounded">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="bg-slate-50 border-b border-slate-200 font-bold text-slate-650">
                        <th className="p-3">Nama Kelas</th>
                        <th className="p-3">Kode Kelas</th>
                        <th className="p-3 text-right">Aksi</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-semibold text-slate-800">
                      {classes.map((cls, idx) => (
                        <tr key={cls.id || idx} className="hover:bg-slate-50/50 transition-colors">
                          <td className="p-3 font-bold text-slate-900">{cls.class_name}</td>
                          <td className="p-3">
                            <span className="font-mono bg-slate-100 border border-slate-200 px-2 py-0.5 rounded text-[11px] text-slate-700 select-all">
                              {cls.class_code}
                            </span>
                          </td>
                          <td className="p-3 text-right space-x-2">
                            <button
                              onClick={() => {
                                navigator.clipboard.writeText(cls.class_code);
                                setCopiedCodeIndex(idx);
                                setTimeout(() => setCopiedCodeIndex(null), 2000);
                              }}
                              className="inline-flex items-center gap-1 px-2 py-1 rounded border border-slate-200 bg-white hover:bg-slate-50 text-[10px] text-slate-600 hover:text-slate-900 transition-all cursor-pointer"
                            >
                              {copiedCodeIndex === idx ? (
                                <>
                                  <Check className="w-3 h-3 text-emerald-600" /> Tersalin!
                                </>
                              ) : (
                                <>
                                  <Copy className="w-3 h-3" /> Salin
                                </>
                              )}
                            </button>
                            <button
                              onClick={() => {
                                setClassCodeFilter(cls.class_code);
                                setActiveClassCode(cls.class_code);
                                fetchAnalytics(cls.class_code);
                                setActiveTab("analytics");
                              }}
                              className="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-slate-900 hover:bg-slate-800 text-[10px] font-bold text-white transition-all cursor-pointer shadow-sm hover:shadow"
                            >
                              Lihat Laporan
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="h-48 flex flex-col items-center justify-center text-center p-6 border border-slate-200 rounded bg-slate-50/50">
                  <Users className="w-8 h-8 text-slate-350 mb-2" />
                  <p className="text-xs text-slate-500 font-bold">Belum ada kelas terdaftar.</p>
                  <p className="text-[10px] text-slate-400 mt-1">Silakan daftarkan kelas pertama Anda di form sebelah kiri.</p>
                </div>
              )}
            </div>

          </div>
        )}

      </div>
    </div>
  );
}
