"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Mail, Undo2, AlertCircle } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import AuthBrandHeader from "@/components/AuthBrandHeader";
import AuthField from "@/components/AuthField";
import AuthDialog from "@/components/AuthDialog";

const EMAIL_HINT = "Gunakan format email yang benar, contoh: nama@domain.com";
const ILLUSTRATION_ALT = "Lupa kata sandi";

export default function LupaSandiPage() {
  const [email, setEmail] = useState("");
  const [touched, setTouched] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  const emailError = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()) ? null : EMAIL_HINT;
  const shownEmailError = touched ? emailError : null;

  const sendResetLink = async () => {
    setSubmitting(true);
    setFormError(null);
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/reset-sandi`,
      });
      if (error) {
        setFormError(error.message);
        return false;
      }
      return true;
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "Gagal mengirim link. Coba lagi sebentar."
      );
      return false;
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setTouched(true);
    if (emailError) return;
    if (await sendResetLink()) setSent(true);
  };

  return (
    <div className="flex-1 bg-white lg:bg-[#CBD5E1]">
      <AuthBrandHeader />

      <div className="mx-auto w-full max-w-[1014px] px-5 sm:px-11 lg:px-0">
        <div className="lg:grid lg:grid-cols-[1.61fr_1fr] lg:items-center lg:overflow-hidden lg:rounded-3xl lg:bg-white lg:shadow-xl">
          {/* Desktop: artwork fills the left column of the card. */}
          <div className="relative hidden lg:block min-h-[378px]">
            <Image
              src="/auth/forgot-password-wide.png"
              alt={ILLUSTRATION_ALT}
              fill
              sizes="625px"
              className="object-contain"
              priority
            />
          </div>

          {/* Mobile & tablet: artwork sits above the form. */}
          <Image
            src="/auth/forgot-password.png"
            alt={ILLUSTRATION_ALT}
            width={335}
            height={248}
            className="lg:hidden mx-auto w-[280px] sm:w-[335px] h-auto"
            priority
          />

          <div className="mt-6 lg:mt-0 lg:pr-10 lg:py-10">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Lupa Kata Sandi?
            </h1>
            <p className="mt-1.5 text-sm text-[#525252] leading-relaxed">
              Masukkan email yang terdaftar.
              <br />
              Navika akan mengirimkan link untuk mengatur ulang kata sandi.
            </p>

            <form onSubmit={handleSubmit} className="mt-7 space-y-4" noValidate>
              <AuthField
                label="Email"
                icon={Mail}
                type="email"
                value={email}
                onChange={setEmail}
                onBlur={() => setTouched(true)}
                placeholder="nama@email.com"
                autoComplete="email"
                error={shownEmailError}
              />

              {formError && (
                <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm text-[#E54B4F]">
                  <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={submitting || Boolean(shownEmailError)}
                className="w-full rounded-full py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#B698FE] disabled:cursor-not-allowed"
              >
                {submitting ? "Mengirim..." : "Kirim Link"}
              </button>
            </form>

            <Link
              href="/login"
              className="mt-5 flex items-center justify-center gap-2 text-sm font-semibold text-slate-900 hover:text-[#7033FF] transition-colors cursor-pointer"
            >
              <Undo2 className="w-4 h-4" />
              kembali ke Halaman Login
            </Link>
          </div>
        </div>

        <div className="h-10" />
      </div>

      {sent && (
        <AuthDialog
          title="Email Terkirim"
          imageSrc="/auth/verify-email.png"
          imageAlt="Email reset kata sandi terkirim"
          heading="Cek Email Kamu!"
          description="kami telah mengirimkan link email reset kata sandi ke email Kamu."
          actionLabel="Kirim Ulang"
          actionPending={submitting}
          onAction={() => void sendResetLink()}
          onClose={() => setSent(false)}
        />
      )}
    </div>
  );
}
