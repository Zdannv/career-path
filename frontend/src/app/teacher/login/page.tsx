"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { Sparkles, GraduationCap, Lock, Mail, Loader2, ArrowLeft } from "lucide-react";
import Link from "next/link";

export default function TeacherLogin() {
  const router = useRouter();
  const [email, setEmail] = useState<string>("");
  const [password, setPassword] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // If already authenticated, redirect to /teacher dashboard
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        router.push("/teacher");
      }
    });
  }, [router]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) return;

    setLoading(true);
    setErrorMsg(null);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password: password.trim(),
      });

      if (error) {
        throw error;
      }

      if (data.session) {
        router.push("/teacher");
      }
    } catch (err: any) {
      setErrorMsg(err.message || "Gagal masuk. Periksa kembali email dan kata sandi Anda.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[85vh] bg-slate-50 flex flex-col justify-center items-center px-4 py-8 relative">
      
      {/* Background effect */}
      <div className="absolute top-1/3 left-1/3 w-64 h-64 bg-indigo-100 rounded-full mix-blend-multiply filter blur-xl opacity-40 pointer-events-none -z-10" />

      <div className="w-full max-w-md space-y-6">
        
        {/* Back Link */}
        <div className="text-center sm:text-left">
          <Link 
            href="/"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-900 transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" /> Kembali ke Home
          </Link>
        </div>

        {/* Card */}
        <div className="bg-white rounded-lg border border-slate-200 p-6 md:p-8 shadow-md space-y-6">
          
          {/* Header */}
          <div className="text-center space-y-2">
            <div className="w-12 h-12 rounded bg-slate-900 text-white flex items-center justify-center shadow mx-auto">
              <GraduationCap className="w-6 h-6" />
            </div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight">Portal Pengajar & Guru BK</h2>
            <p className="text-xs text-slate-500 font-medium leading-relaxed">
              Masuk dengan akun Anda untuk melihat laporan serta mengelola kelas bimbingan karir siswa.
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-4 text-xs font-semibold">
            
            {/* Email field */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-bold text-slate-650 flex items-center gap-1">
                <Mail className="w-3.5 h-3.5 text-slate-400" />
                Alamat Email Guru
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="guru@sekolah.sch.id"
                className="w-full bg-slate-50 border border-slate-200 rounded px-3 py-2.5 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
              />
            </div>

            {/* Password field */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-bold text-slate-650 flex items-center gap-1">
                <Lock className="w-3.5 h-3.5 text-slate-400" />
                Kata Sandi
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Masukkan kata sandi Anda"
                className="w-full bg-slate-50 border border-slate-200 rounded px-3 py-2.5 text-xs focus:outline-none focus:border-slate-400 text-slate-900 font-semibold"
              />
            </div>

            {/* Error Message */}
            {errorMsg && (
              <div className="p-3 rounded bg-rose-50 border border-rose-100 text-rose-700 font-medium text-[11px]">
                ⚠️ {errorMsg}
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded bg-slate-900 hover:bg-slate-800 disabled:opacity-50 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors cursor-pointer shadow-sm hover:shadow"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" /> Sedang Masuk...
                </>
              ) : (
                <>
                  Masuk ke Dasbor BK
                </>
              )}
            </button>

          </form>

        </div>

      </div>
    </div>
  );
}
