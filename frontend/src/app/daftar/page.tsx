"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Mail, Lock, AlertCircle } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import AuthBrandHeader from "@/components/AuthBrandHeader";
import AuthPageShell from "@/components/AuthPageShell";
import AuthField from "@/components/AuthField";
import {
  SignupIllustrationPanel,
  SignupIllustrationBlock,
  SignupIllustrationCollapsible,
} from "@/components/SignupIllustration";

const EMAIL_HINT = "Gunakan format email yang benar, contoh: nama@domain.com";
const PASSWORD_HINT = "Minimal 8 karakter dengan kombinasi huruf dan angka.";

function validateEmail(value: string): string | null {
  if (!value.trim()) return EMAIL_HINT;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()) ? null : EMAIL_HINT;
}

function validatePassword(value: string): string | null {
  if (value.length < 8) return PASSWORD_HINT;
  if (!/[a-zA-Z]/.test(value) || !/\d/.test(value)) return PASSWORD_HINT;
  return null;
}

export default function DaftarPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [touched, setTouched] = useState({ email: false, password: false, confirm: false });
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [emailTaken, setEmailTaken] = useState(false);

  const emailError = emailTaken
    ? "Email ini sudah terdaftar. Coba masuk atau gunakan email lain."
    : validateEmail(email);
  const passwordError = validatePassword(password);
  const confirmError = confirm !== password ? "Konfirmasi sandi tidak sesuai" : null;

  // Errors only surface after a field is left or the form is submitted, so a
  // pristine form still shows the neutral state from the design.
  const shownEmailError = touched.email ? emailError : null;
  const shownConfirmError = touched.confirm ? confirmError : null;
  const hasVisibleError = Boolean(shownEmailError || shownConfirmError);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setTouched({ email: true, password: true, confirm: true });
    setFormError(null);

    if (emailError || passwordError || confirmError) return;

    setSubmitting(true);
    try {
      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        // TODO: point at /login once the Masuk screen lands (Authentication module).
        options: { emailRedirectTo: `${window.location.origin}/` },
      });

      if (error) {
        if (/already registered|already exists/i.test(error.message)) {
          setEmailTaken(true);
        } else {
          setFormError(error.message);
        }
        return;
      }

      // With email confirmation on, Supabase hides existing accounts by
      // returning a user with no identities instead of an error.
      if (data.user && data.user.identities?.length === 0) {
        setEmailTaken(true);
        return;
      }

      router.push(`/verifikasi?email=${encodeURIComponent(email.trim())}`);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "Gagal membuat akun. Coba lagi sebentar."
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AuthPageShell cancelHref="/">
      <AuthBrandHeader />

      <div className="mx-auto w-full max-w-[1013px] px-5 sm:px-11 lg:px-0">
        <div data-auth-card className="lg:grid lg:grid-cols-[1.61fr_1fr] lg:overflow-hidden lg:rounded-3xl lg:bg-white lg:shadow-xl">
          <SignupIllustrationPanel className="hidden lg:block min-h-[574px]" />

          <div className="lg:px-6 lg:py-8">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Buat Akun Kamu
            </h1>
            <p className="mt-1.5 text-sm text-[#525252] leading-relaxed">
              Mulai perjalanan karier Kamu bersama Navika dan dapatkan rekomendasi karier
              yang sesuai dengan minat, keahlian, dan tujuan Kamu.
            </p>

            <form onSubmit={handleSubmit} className="mt-8 space-y-4" noValidate>
              <AuthField
                label="Email"
                icon={Mail}
                type="email"
                value={email}
                onChange={(v) => {
                  setEmail(v);
                  setEmailTaken(false);
                }}
                onBlur={() => setTouched((t) => ({ ...t, email: true }))}
                placeholder="nama@email.com"
                autoComplete="email"
                error={shownEmailError}
              />

              <AuthField
                label="Kata Sandi"
                icon={Lock}
                type="password"
                value={password}
                onChange={setPassword}
                onBlur={() => setTouched((t) => ({ ...t, password: true }))}
                placeholder="Buat kata sandi kamu"
                autoComplete="new-password"
                hint={PASSWORD_HINT}
              />

              <AuthField
                label="Konfirmasi Kata Sandi"
                icon={Lock}
                type="password"
                value={confirm}
                onChange={setConfirm}
                onBlur={() => setTouched((t) => ({ ...t, confirm: true }))}
                placeholder="Konfirmasi kata sandi kamu"
                autoComplete="new-password"
                error={shownConfirmError}
              />

              {formError && (
                <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm text-[#E54B4F]">
                  <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={submitting || hasVisibleError}
                className="w-full rounded-full py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#B698FE] disabled:cursor-not-allowed"
              >
                {submitting ? "Membuat akun..." : "Daftar"}
              </button>
            </form>

            <p className="mt-5 text-center text-sm font-medium text-slate-900">
              Sudah punya akun?{" "}
              <Link href="/login" className="font-bold underline cursor-pointer">
                Masuk
              </Link>
            </p>
          </div>
        </div>

        {/* Tablet keeps the wide artwork, but below the form instead of beside it. */}
        <SignupIllustrationBlock className="hidden sm:block lg:hidden mt-10 rounded-2xl" />

        <div className="sm:hidden mt-10">
          <SignupIllustrationCollapsible />
        </div>

        <p className="py-8 text-center text-sm text-[#525252]">
          Dengan membuat akun, Kamu telah menyetujui{" "}
          <Link href="/syarat-layanan" className="text-[#1E69DC] cursor-pointer">
            Syarat Layanan
          </Link>{" "}
          dan{" "}
          <Link href="/kebijakan-privasi" className="text-[#1E69DC] cursor-pointer">
            Kebijakan Privasi
          </Link>
          .
        </p>
      </div>
    </AuthPageShell>
  );
}
