"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import { Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import type { User } from "@supabase/supabase-js";
import ChatOnboarding from "@/components/ChatOnboarding";
import Dashboard from "@/components/Dashboard";

export default function StudentOnboarding() {
  const [view, setView] = useState<"onboarding" | "dashboard">("onboarding");
  const [results, setResults] = useState<any>(null);
  const [user, setUser] = useState<User | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);

  useEffect(() => {
    // Get current session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setCheckingAuth(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      setCheckingAuth(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleOnboardingComplete = (data: any) => {
    setResults(data);
    setView("dashboard");
  };

  const handleRestart = () => {
    setResults(null);
    setView("onboarding");
  };

  if (checkingAuth) {
    return (
      <div className="min-h-[80vh] w-full flex flex-col items-center justify-center gap-3">
        <Loader2 className="w-8 h-8 animate-spin text-[#7033ff]" />
        <p className="text-xs text-slate-500 font-bold">Memeriksa status masuk...</p>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-[80vh] w-full flex items-center justify-center p-4 bg-[#f8fafc]">
        <div className="w-full max-w-[360px] bg-white rounded-[28px] border border-slate-200/60 shadow-xl p-6 flex flex-col items-center text-center">
          <h2 className="w-full text-left font-black text-slate-900 text-lg tracking-tight mb-2 px-1">
            Masuk Akun
          </h2>
          <div className="w-full flex items-center justify-center my-4 h-[130px] relative select-none">
            <Image
              src="/landing/auth-illustration.png"
              alt="Ilustrasi autentikasi"
              width={300}
              height={130}
              className="object-contain"
              priority
            />
          </div>
          <h3 className="text-sm font-extrabold text-slate-900 tracking-tight leading-tight mt-2">
            Ups, masuk dulu yuk!
          </h3>
          <p className="text-xs text-slate-400 mt-2 leading-relaxed px-2 font-medium">
            Kamu perlu login ke akunmu untuk lanjut ke halaman berikutnya
          </p>
          <div className="w-full flex gap-3 mt-6">
            <button
              onClick={() =>
                window.dispatchEvent(
                  new CustomEvent("open-auth-modal", { detail: { mode: "daftar" } })
                )
              }
              className="flex-1 py-3 rounded-full border border-slate-200 bg-white hover:bg-slate-50 text-slate-800 text-xs font-bold transition-all shadow-xs cursor-pointer text-center"
            >
              Daftar
            </button>
            <button
              onClick={() =>
                window.dispatchEvent(
                  new CustomEvent("open-auth-modal", { detail: { mode: "login" } })
                )
              }
              className="flex-1 py-3 rounded-full bg-[#7033ff] hover:bg-[#5c25e6] active:bg-[#4b1ec5] text-white text-xs font-bold transition-all shadow-sm hover:shadow-md cursor-pointer text-center"
            >
              Masuk Akun
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-[90vh] w-full bg-slate-50 flex items-center justify-center p-0 sm:p-6">
      {view === "onboarding" ? (
        /* Chat Onboarding supports split desktop layout with live summary */
        <div className="w-full min-h-[85vh] sm:max-w-5xl sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-md overflow-hidden transition-all duration-300">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <ChatOnboarding onComplete={handleOnboardingComplete} />
          </div>
        </div>
      ) : (
        /* Dashboard expands to max-w-7xl for side-by-side matching and cost planning sheets */
        <div className="w-full min-h-[90vh] sm:rounded-xl sm:border sm:border-slate-200 bg-white flex flex-col shadow-md overflow-hidden max-w-7xl transition-all duration-300">
          <div className="flex-1 flex flex-col overflow-hidden relative">
            <Dashboard data={results} onRestart={handleRestart} />
          </div>
        </div>
      )}
    </div>
  );
}
