"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Mail, Lock, AlertCircle } from "lucide-react";
import { supabase, setRememberMe } from "@/lib/supabaseClient";
import AuthBrandHeader from "@/components/AuthBrandHeader";
import AuthField from "@/components/AuthField";

const ILLUSTRATION_ALT = "Perjalanan karier menuju puncak bersama Navika";

/** Fills the desktop card's left column, cropping to whatever height the form needs. */
function LoginIllustrationPanel({ className = "" }: { className?: string }) {
  return (
    <div className={`relative overflow-hidden ${className}`}>
      <Image
        src="/auth/login-illustration.png"
        alt={ILLUSTRATION_ALT}
        fill
        sizes="(max-width: 1024px) 100vw, 625px"
        className="object-cover"
        priority
      />
    </div>
  );
}

export default function LoginPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setFormError(null);

    if (!email.trim() || !password) {
      setFormError("Email dan kata sandi wajib diisi.");
      return;
    }

    setSubmitting(true);
    try {
      // Decides whether the session goes to localStorage or sessionStorage, so
      // it must be set before the session is written.
      setRememberMe(remember);

      const { error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });

      if (error) {
        setFormError(
          /invalid login credentials/i.test(error.message)
            ? "Email atau kata sandi salah."
            : /email not confirmed/i.test(error.message)
              ? "Email Kamu belum diverifikasi. Cek inbox untuk link verifikasi."
              : error.message
        );
        return;
      }

      router.push("/student");
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "Gagal masuk. Coba lagi sebentar."
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex-1 bg-white lg:bg-[#CBD5E1]">
      <AuthBrandHeader />

      <div className="mx-auto w-full max-w-[1013px] px-5 sm:px-11 lg:px-0">
        <div className="lg:grid lg:grid-cols-[1.61fr_1fr] lg:overflow-hidden lg:rounded-3xl lg:bg-white lg:shadow-xl">
          <LoginIllustrationPanel className="hidden lg:block min-h-[520px]" />

          <div className="lg:px-6 lg:py-8">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Masuk Akun Kamu
            </h1>
            <p className="mt-1.5 text-sm text-[#525252] leading-relaxed">
              Masuk ke akun Kamu untuk melanjutkan aktivitas dan melihat pembaruan career
              path journey Kamu.
            </p>

            <form onSubmit={handleSubmit} className="mt-8 space-y-4" noValidate>
              <AuthField
                label="Email"
                icon={Mail}
                type="email"
                value={email}
                onChange={setEmail}
                placeholder="nama@email.com"
                autoComplete="email"
              />

              <AuthField
                label="Kata Sandi"
                icon={Lock}
                type="password"
                value={password}
                onChange={setPassword}
                placeholder="Masukkan kata sandi kamu"
                autoComplete="current-password"
              />

              <div className="flex items-center justify-between gap-4 pt-1">
                <label className="flex items-center gap-2 text-sm text-slate-900 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={remember}
                    onChange={(e) => setRemember(e.target.checked)}
                    className="w-4 h-4 rounded accent-[#7033FF] cursor-pointer"
                  />
                  Ingatkan saya
                </label>

                <Link
                  href="/lupa-sandi"
                  className="text-sm font-bold text-slate-900 hover:text-[#7033FF] transition-colors cursor-pointer"
                >
                  Lupa Kata Sandi?
                </Link>
              </div>

              {formError && (
                <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm text-[#E54B4F]">
                  <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={submitting}
                className="w-full rounded-full py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#B698FE] disabled:cursor-not-allowed"
              >
                {submitting ? "Masuk..." : "Masuk Akun"}
              </button>
            </form>

            <p className="mt-5 text-center text-sm font-medium text-slate-900">
              Belum punya akun?{" "}
              <Link href="/daftar" className="font-bold underline cursor-pointer">
                Daftar disini
              </Link>
            </p>
          </div>
        </div>

        {/* Below the form at mobile and tablet widths. */}
        <Image
          src="/auth/login-illustration.png"
          alt={ILLUSTRATION_ALT}
          width={688}
          height={525}
          className="lg:hidden mt-10 w-full h-auto rounded-2xl"
        />

        <div className="h-10" />
      </div>
    </div>
  );
}
