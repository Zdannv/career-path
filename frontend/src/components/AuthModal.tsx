"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import { X, Mail, Lock, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialMode?: "prompt" | "login" | "daftar";
  isPageMode?: boolean; // For standalone page rendering on /login and /daftar
}

export default function AuthModal({
  isOpen,
  onClose,
  initialMode = "prompt",
  isPageMode = false,
}: AuthModalProps) {
  const [mode, setMode] = useState<"prompt" | "login" | "daftar">(initialMode);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Sync mode with initialMode prop when it changes
  useEffect(() => {
    setMode(initialMode);
  }, [initialMode]);

  // Reset states on modal close/open
  useEffect(() => {
    if (isOpen) {
      setError(null);
      setSuccessMsg(null);
      setEmail("");
      setPassword("");
    }
  }, [isOpen]);

  if (!isOpen && !isPageMode) return null;

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError("Email dan kata sandi harus diisi.");
      return;
    }

    setLoading(true);
    setError(null);
    setSuccessMsg(null);

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password: password.trim(),
      });

      if (authError) throw authError;

      setSuccessMsg("Berhasil masuk! Mengalihkan...");
      setTimeout(() => {
        onClose();
        window.location.reload();
      }, 1000);
    } catch (err: any) {
      console.error("[AuthModal] Login error:", err);
      // Friendly messages for common errors
      if (err.status === 400 || err.message?.includes("Invalid login credentials")) {
        setError("Email atau kata sandi Anda salah.");
      } else {
        setError(err.message || "Gagal masuk. Silakan coba lagi.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError("Email dan kata sandi harus diisi.");
      return;
    }
    if (password.length < 6) {
      setError("Kata sandi minimal harus terdiri dari 6 karakter.");
      return;
    }

    setLoading(true);
    setError(null);
    setSuccessMsg(null);

    try {
      const { data, error: authError } = await supabase.auth.signUp({
        email: email.trim(),
        password: password.trim(),
        options: {
          emailRedirectTo: typeof window !== "undefined" ? window.location.origin : undefined,
        },
      });

      if (authError) throw authError;

      // Check if user is auto-confirmed or needs confirmation
      if (data.user && data.session) {
        setSuccessMsg("Pendaftaran berhasil! Mengalihkan...");
        setTimeout(() => {
          onClose();
          window.location.reload();
        }, 1000);
      } else {
        setSuccessMsg("Pendaftaran berhasil! Silakan periksa kotak masuk email Anda untuk verifikasi.");
      }
    } catch (err: any) {
      console.error("[AuthModal] Register error:", err);
      setError(err.message || "Gagal mendaftar. Silakan coba lagi.");
    } finally {
      setLoading(false);
    }
  };

  // Main container class depending on mode
  const containerClasses = isPageMode
    ? "w-full max-w-[360px] bg-white rounded-[28px] border border-slate-100 shadow-xl p-6 relative flex flex-col items-center justify-between min-h-[423px]"
    : "w-full max-w-[360px] bg-white rounded-[28px] border border-slate-100 shadow-2xl p-6 relative flex flex-col items-center justify-between min-h-[423px] animate-in fade-in zoom-in duration-200";

  return (
    <div
      className={
        isPageMode
          ? "flex items-center justify-center min-h-[85vh] py-12 px-4"
          : "fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-xs p-4"
      }
      onClick={isPageMode ? undefined : () => onClose()}
    >
      <div
        className={containerClasses}
        onClick={(e) => e.stopPropagation()}
        style={{ minHeight: "423px" }}
      >
        {/* Close Button */}
        {!isPageMode && (
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-1.5 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-all cursor-pointer"
            aria-label="Tutup"
          >
            <X className="w-5 h-5" />
          </button>
        )}

        {/* Modal Title */}
        <h2 className="w-full text-left font-black text-slate-900 text-lg tracking-tight px-1">
          {mode === "prompt" && "Masuk Akun"}
          {mode === "login" && "Masuk ke Akun"}
          {mode === "daftar" && "Buat Akun Baru"}
        </h2>

        {/* Illustration or Notification Area */}
        <div className="w-full flex flex-col items-center my-2 select-none relative h-[140px] justify-center">
          {mode === "prompt" ? (
            <div className="w-full h-full relative overflow-hidden flex items-center justify-center">
              <Image
                src="/landing/auth-illustration.png"
                alt="Ilustrasi autentikasi"
                width={300}
                height={130}
                className="object-contain"
                priority
              />
            </div>
          ) : (
            <div className="w-full px-2 text-center flex flex-col items-center justify-center h-full">
              {error && (
                <div className="flex flex-col items-center gap-2 text-rose-600 bg-rose-50 border border-rose-100 rounded-2xl p-4 w-full text-xs font-semibold">
                  <AlertCircle className="w-6 h-6 shrink-0" />
                  <span>{error}</span>
                </div>
              )}
              {successMsg && (
                <div className="flex flex-col items-center gap-2 text-emerald-600 bg-emerald-50 border border-emerald-100 rounded-2xl p-4 w-full text-xs font-semibold">
                  <Loader2 className="w-6 h-6 shrink-0 animate-spin text-emerald-500" />
                  <span>{successMsg}</span>
                </div>
              )}
              {!error && !successMsg && (
                <div className="w-full h-full relative overflow-hidden flex items-center justify-center opacity-40 grayscale">
                  <Image
                    src="/landing/auth-illustration.png"
                    alt="Ilustrasi"
                    width={220}
                    height={100}
                    className="object-contain"
                  />
                </div>
              )}
            </div>
          )}
        </div>

        {/* Mode contents */}
        {mode === "prompt" && (
          <div className="w-full flex flex-col items-center text-center px-1">
            <h3 className="text-sm font-extrabold text-slate-900 tracking-tight leading-tight">
              Ups, masuk dulu yuk!
            </h3>
            <p className="text-xs text-slate-400 mt-2 leading-relaxed px-2 font-medium">
              Kamu perlu login ke akunmu untuk lanjut ke halaman berikutnya
            </p>

            <div className="w-full flex gap-3 mt-6">
              <button
                onClick={() => setMode("daftar")}
                className="flex-1 py-3 rounded-full border border-slate-200 bg-white hover:bg-slate-50 text-slate-800 text-xs font-bold transition-all shadow-xs cursor-pointer text-center"
              >
                Daftar
              </button>
              <button
                onClick={() => setMode("login")}
                className="flex-1 py-3 rounded-full bg-[#7033ff] hover:bg-[#5c25e6] active:bg-[#4b1ec5] text-white text-xs font-bold transition-all shadow-sm hover:shadow-md cursor-pointer text-center"
              >
                Masuk Akun
              </button>
            </div>
          </div>
        )}

        {mode === "login" && (
          <form onSubmit={handleLogin} className="w-full flex flex-col gap-3 px-1 mt-2">
            <div className="relative">
              <span className="absolute inset-y-0 left-3.5 flex items-center text-slate-400">
                <Mail className="w-4 h-4" />
              </span>
              <input
                type="email"
                placeholder="Masukkan email Anda"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                className="w-full pl-10 pr-4 py-2.5 text-xs text-slate-800 border border-slate-200 rounded-full focus:outline-none focus:border-[#7033ff] bg-slate-50 focus:bg-white transition-all font-semibold"
                required
              />
            </div>

            <div className="relative">
              <span className="absolute inset-y-0 left-3.5 flex items-center text-slate-400">
                <Lock className="w-4 h-4" />
              </span>
              <input
                type="password"
                placeholder="Masukkan kata sandi"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                className="w-full pl-10 pr-4 py-2.5 text-xs text-slate-800 border border-slate-200 rounded-full focus:outline-none focus:border-[#7033ff] bg-slate-50 focus:bg-white transition-all font-semibold"
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 mt-1 rounded-full bg-[#7033ff] hover:bg-[#5c25e6] active:bg-[#4b1ec5] disabled:bg-slate-300 text-white text-xs font-bold transition-all shadow-sm hover:shadow-md cursor-pointer flex items-center justify-center gap-1.5"
            >
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : "Masuk Akun"}
            </button>

            <p className="text-[10px] text-slate-400 text-center mt-3 font-semibold">
              Belum punya akun?{" "}
              <button
                type="button"
                onClick={() => {
                  setError(null);
                  setSuccessMsg(null);
                  setMode("daftar");
                }}
                className="text-[#7033ff] hover:underline cursor-pointer font-bold"
              >
                Daftar di sini
              </button>
            </p>
          </form>
        )}

        {mode === "daftar" && (
          <form onSubmit={handleRegister} className="w-full flex flex-col gap-3 px-1 mt-2">
            <div className="relative">
              <span className="absolute inset-y-0 left-3.5 flex items-center text-slate-400">
                <Mail className="w-4 h-4" />
              </span>
              <input
                type="email"
                placeholder="Masukkan alamat email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                className="w-full pl-10 pr-4 py-2.5 text-xs text-slate-800 border border-slate-200 rounded-full focus:outline-none focus:border-[#7033ff] bg-slate-50 focus:bg-white transition-all font-semibold"
                required
              />
            </div>

            <div className="relative">
              <span className="absolute inset-y-0 left-3.5 flex items-center text-slate-400">
                <Lock className="w-4 h-4" />
              </span>
              <input
                type="password"
                placeholder="Buat kata sandi (min. 6 karakter)"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
                className="w-full pl-10 pr-4 py-2.5 text-xs text-slate-800 border border-slate-200 rounded-full focus:outline-none focus:border-[#7033ff] bg-slate-50 focus:bg-white transition-all font-semibold"
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 mt-1 rounded-full bg-[#7033ff] hover:bg-[#5c25e6] active:bg-[#4b1ec5] disabled:bg-slate-300 text-white text-xs font-bold transition-all shadow-sm hover:shadow-md cursor-pointer flex items-center justify-center gap-1.5"
            >
              {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : "Daftar Akun"}
            </button>

            <p className="text-[10px] text-slate-400 text-center mt-3 font-semibold">
              Sudah punya akun?{" "}
              <button
                type="button"
                onClick={() => {
                  setError(null);
                  setSuccessMsg(null);
                  setMode("login");
                }}
                className="text-[#7033ff] hover:underline cursor-pointer font-bold"
              >
                Masuk di sini
              </button>
            </p>
          </form>
        )}
      </div>
    </div>
  );
}
