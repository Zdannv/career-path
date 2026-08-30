"use client";

import React, { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { MailSearch, TriangleAlert, TimerReset, Undo2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import AuthPageShell from "@/components/AuthPageShell";

/** Seconds the user has to wait before another verification email can be sent. */
const RESEND_COOLDOWN_SECONDS = 90;

function formatCountdown(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

/** Icon in a soft indigo circle, shared by the three info rows. */
function InfoIcon({ children }: { children: React.ReactNode }) {
  return (
    <div className="w-9 h-9 rounded-full bg-indigo-50 flex items-center justify-center shrink-0 text-[#7033FF]">
      {children}
    </div>
  );
}

export default function VerifikasiContent({ email }: { email: string }) {
  const [secondsLeft, setSecondsLeft] = useState(RESEND_COOLDOWN_SECONDS);
  const [resending, setResending] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const timer = setInterval(() => setSecondsLeft((s) => (s > 0 ? s - 1 : 0)), 1000);
    return () => clearInterval(timer);
  }, [secondsLeft]);

  const canResend = secondsLeft <= 0 && !resending && Boolean(email);

  const handleResend = useCallback(async () => {
    if (!canResend) return;
    setResending(true);
    setNotice(null);
    try {
      const { error } = await supabase.auth.resend({
        type: "signup",
        email,
        options: { emailRedirectTo: `${window.location.origin}/` },
      });
      if (error) {
        setNotice(error.message);
        return;
      }
      setNotice("Email verifikasi sudah dikirim ulang. Cek inbox Kamu.");
      setSecondsLeft(RESEND_COOLDOWN_SECONDS);
    } catch (err) {
      setNotice(
        err instanceof Error ? err.message : "Gagal mengirim ulang email. Coba lagi sebentar."
      );
    } finally {
      setResending(false);
    }
  }, [canResend, email]);

  return (
    <AuthPageShell cancelHref="/" className="lg:py-14">
      <div className="mx-auto w-full max-w-[800px] px-5 sm:px-10 lg:px-0">
        <div className="lg:rounded-3xl lg:bg-white lg:px-10 lg:py-12 lg:shadow-xl">
          {/* Illustration */}
          <div className="flex justify-center pt-10 lg:pt-0">
            <div className="rounded-3xl bg-gradient-to-b from-indigo-50/70 to-transparent p-4">
              <Image
                src="/auth/verify-email.png"
                alt="Email verifikasi terkirim"
                width={200}
                height={200}
                className="w-[180px] h-auto"
                priority
              />
            </div>
          </div>

          <h1 className="mt-4 text-center text-2xl font-bold tracking-tight text-slate-900">
            Verifikasi Email Kamu
          </h1>
          <p className="mt-1.5 text-center text-sm text-[#525252] leading-relaxed">
            Navika telah mengirimkan link email verifikasi ke email Kamu.
          </p>

          {/* Email recap */}
          <div className="mt-8 flex items-center gap-4 rounded-2xl border border-slate-200 bg-[#F5F5F5] px-4 py-4">
            <InfoIcon>
              <MailSearch className="w-4 h-4" />
            </InfoIcon>
            <div className="leading-tight min-w-0">
              <div className="text-sm font-bold text-slate-900">Email Kamu</div>
              <div className="text-sm text-[#525252] truncate">
                {email || "Email tidak diketahui"}
              </div>
            </div>
          </div>

          {/* Help + resend timer */}
          <div className="mt-6 grid gap-5 sm:grid-cols-2">
            <div className="flex items-center gap-4">
              <InfoIcon>
                <TriangleAlert className="w-4 h-4" />
              </InfoIcon>
              <div className="leading-tight">
                <div className="text-sm font-bold text-slate-900">Belum menerima email?</div>
                <div className="text-sm text-[#525252]">Cek folder spam atau promotions.</div>
              </div>
            </div>

            <div className="flex items-center gap-4">
              <InfoIcon>
                <TimerReset className="w-4 h-4" />
              </InfoIcon>
              <div className="leading-tight">
                <div className="text-sm font-bold text-slate-900">
                  Kirim ulang email verifikasi..
                </div>
                {secondsLeft > 0 ? (
                  <div className="text-sm text-[#1E69DC]">
                    {formatCountdown(secondsLeft)} detik
                  </div>
                ) : (
                  <div className="text-sm text-[#525252]">link email verifikasi tersedia</div>
                )}
              </div>
            </div>
          </div>

          {notice && (
            <p className="mt-5 text-center text-sm text-[#525252] sm:text-left">{notice}</p>
          )}

          <hr className="my-7 border-slate-200" />

          {/* Actions — full-width button above the link on mobile and tablet;
              only the desktop card puts them inline and right-aligned. */}
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-end">
            <Link
              href="/"
              className="order-2 lg:order-1 inline-flex items-center justify-center gap-2 text-sm font-semibold text-slate-900 hover:text-[#7033FF] transition-colors cursor-pointer lg:mr-3"
            >
              <Undo2 className="w-4 h-4" />
              kembali ke halaman utama
            </Link>

            <button
              type="button"
              onClick={handleResend}
              disabled={!canResend}
              className="order-1 lg:order-2 rounded-full px-6 py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#D5C4FE] disabled:cursor-not-allowed"
            >
              {resending ? "Mengirim..." : "Kirim Ulang Email"}
            </button>
          </div>
        </div>
      </div>
    </AuthPageShell>
  );
}
