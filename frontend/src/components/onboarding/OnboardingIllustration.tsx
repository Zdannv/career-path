"use client";

import React, { useState } from "react";
import Image from "next/image";

/**
 * Ilustrasi per layar onboarding.
 *
 * Aset diekspor tim desain ke `public/onboarding/`. Kalau salah satu belum ada,
 * komponen ini menyisakan ruang kosong berbingkai lembut alih-alih ikon gambar
 * rusak: onboarding tetap bisa dipakai dan dites walau asetnya menyusul.
 *
 * `width`/`height` di sini adalah ukuran asli tiap file, bukan angka seragam.
 * Semua pemanggil memakai `h-auto`, jadi rasio inilah yang menentukan tinggi
 * slot — kalau diseragamkan (mis. semua 640x480) gambar portrait ikut ditarik
 * jadi lanskap dan ilustrasinya gepeng.
 */
type Illustration = { src: string; width: number; height: number };

export const ILLUSTRATIONS = {
  start: { src: "/onboarding/start.png", width: 283, height: 360 },
  step1: { src: "/onboarding/step-1.png", width: 472, height: 237 },
  step2: { src: "/onboarding/step-2.png", width: 472, height: 237 },
  step3: { src: "/onboarding/step-3.png", width: 472, height: 237 },
  done: { src: "/onboarding/done.png", width: 320, height: 320 },
} as const satisfies Record<string, Illustration>;

export type IllustrationKey = keyof typeof ILLUSTRATIONS;

type Props = {
  name: IllustrationKey;
  className?: string;
  priority?: boolean;
};

export default function OnboardingIllustration({ name, className = "", priority }: Props) {
  const [failed, setFailed] = useState(false);
  const asset = ILLUSTRATIONS[name];

  if (failed) {
    // Rasio eksplisit wajib: className pemanggil memakai `h-auto` yang mengikuti
    // tinggi gambar asli. Tanpa gambar, tanpa rasio, kotaknya jadi setinggi nol
    // dan slot ilustrasi hilang begitu saja alih-alih terlihat sedang kosong.
    return (
      <div
        aria-hidden
        style={{ aspectRatio: `${asset.width} / ${asset.height}` }}
        className={`rounded-2xl bg-gradient-to-b from-[#F5F1FF] to-[#EDE7FF] ring-1 ring-[#E6DEFF] ${className}`}
      />
    );
  }

  return (
    <Image
      src={asset.src}
      alt=""
      width={asset.width}
      height={asset.height}
      className={className}
      onError={() => setFailed(true)}
      priority={priority}
    />
  );
}
