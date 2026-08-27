"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Lock, X, AlertCircle, Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import AuthBrandHeader from "@/components/AuthBrandHeader";
import AuthField from "@/components/AuthField";
import AuthDialog from "@/components/AuthDialog";

const PASSWORD_HINT = "Minimal 8 karakter dengan kombinasi huruf dan angka.";

/** How long to wait for Supabase to turn the emailed token into a session. */
const RECOVERY_DETECT_TIMEOUT_MS = 2500;

function validatePassword(value: string): string | null {
  if (value.length < 8) return PASSWORD_HINT;
  if (!/[a-zA-Z]/.test(value) || !/\d/.test(value)) return PASSWORD_HINT;
  return null;
}

export default function ResetSandiPage() {
  const router = useRouter();

  // The page is opened from the emailed link, so it first has to confirm that
  // Supabase managed to establish a recovery session from the URL.
  const [status, setStatus] = useState<"checking" | "ready" | "invalid">("checking");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [touched, setTouched] = useState({ password: false, confirm: false });
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [done, setDone] = useState(false);

  useEffect(() => {
    let settled = false;
    const markReady = () => {
      if (settled) return;
      settled = true;
      setStatus("ready");
    };

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (session && (event === "PASSWORD_RECOVERY" || event === "SIGNED_IN" || event === "INITIAL_SESSION")) {
        markReady();
      }
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) markReady();
    });

    const timer = setTimeout(() => {
      if (!settled) {
        settled = true;
        setStatus("invalid");
      }
    }, RECOVERY_DETECT_TIMEOUT_MS);

    return () => {
      subscription.unsubscribe();
      clearTimeout(timer);
    };
  }, []);

  const passwordError = validatePassword(password);
  const confirmError = confirm !== password ? "Konfirmasi sandi tidak sesuai" : null;
  const shownConfirmError = touched.confirm ? confirmError : null;
  const canSubmit = !passwordError && !confirmError && !submitting;

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setTouched({ password: true, confirm: true });
    setFormError(null);
    if (passwordError || confirmError) return;

    setSubmitting(true);
    try {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) {
        setFormError(error.message);
        return;
      }
      setDone(true);
    } catch (err) {
      setFormError(
        err instanceof Error ? err.message : "Gagal menyimpan kata sandi. Coba lagi sebentar."
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="flex-1 bg-white lg:bg-[#CBD5E1]">
      <AuthBrandHeader />

      <div className="mx-auto w-full max-w-[592px] px-5 sm:px-11 lg:px-0">
        <div className="lg:rounded-3xl lg:bg-white lg:px-10 lg:py-10 lg:shadow-xl">
          {status === "checking" && (
            <div className="flex flex-col items-center gap-3 py-16">
              <Loader2 className="w-6 h-6 animate-spin text-[#7033FF]" />
              <p className="text-sm text-[#525252]">Memeriksa link reset kata sandi...</p>
            </div>
          )}

          {status === "invalid" && (
            <div className="py-12 text-center">
              <h1 className="text-2xl font-black tracking-tight text-slate-900">
                Link Tidak Berlaku
              </h1>
              <p className="mt-2 text-sm text-[#525252] leading-relaxed">
                Link reset kata sandi sudah kedaluwarsa atau pernah dipakai. Minta link baru
                untuk melanjutkan.
              </p>
              <Link
                href="/lupa-sandi"
                className="mt-6 inline-block rounded-full bg-[#7033FF] px-6 py-3 text-sm font-semibold text-white hover:bg-[#5f27e6] transition-colors cursor-pointer"
              >
                Minta Link Baru
              </Link>
            </div>
          )}

          {status === "ready" && (
            <>
              <div className="flex justify-center">
                <Image
                  src="/auth/reset-password.png"
                  alt="Buat kata sandi baru"
                  width={200}
                  height={200}
                  className="w-[160px] h-auto"
                  priority
                />
              </div>

              <h1 className="mt-3 text-center text-2xl font-black tracking-tight text-slate-900">
                Buat Kata Sandi Baru
              </h1>
              <p className="mt-1.5 text-center text-sm text-[#525252] leading-relaxed">
                Silakan ketik kata sandi baru kamu untuk melanjutkan masuk ke akun
              </p>

              <form onSubmit={handleSubmit} className="mt-8 space-y-4" noValidate>
                <AuthField
                  label="Kata Sandi"
                  icon={Lock}
                  type="password"
                  value={password}
                  onChange={setPassword}
                  onBlur={() => setTouched((t) => ({ ...t, password: true }))}
                  placeholder="Buat kata sandi baru"
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
                  placeholder="Konfirmasi kata sandi"
                  autoComplete="new-password"
                  error={shownConfirmError}
                />

                {formError && (
                  <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm text-[#E54B4F]">
                    <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                    <span>{formError}</span>
                  </div>
                )}

                <hr className="!mt-8 border-slate-200" />

                <div className="flex items-center justify-end gap-5 !mt-6">
                  <Link
                    href="/login"
                    className="inline-flex items-center gap-2 text-sm font-semibold text-slate-900 hover:text-[#7033FF] transition-colors cursor-pointer"
                  >
                    <X className="w-4 h-4" />
                    Batalkan
                  </Link>

                  <button
                    type="submit"
                    disabled={!canSubmit}
                    className="rounded-full px-6 py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#D5C4FE] disabled:cursor-not-allowed"
                  >
                    {submitting ? "Menyimpan..." : "Simpan Kata Sandi"}
                  </button>
                </div>
              </form>
            </>
          )}
        </div>

        <div className="h-10" />
      </div>

      {done && (
        <AuthDialog
          title="Berhasil!"
          imageSrc="/auth/reset-password.png"
          imageAlt="Kata sandi berhasil diperbarui"
          heading="Kata sandi berhasil diperbarui."
          description="Sekarang kamu bisa melanjutkan perjalanan kariermu."
          actionLabel="Masuk Akun"
          onAction={() => router.push("/login")}
          onClose={() => router.push("/login")}
        />
      )}
    </div>
  );
}
