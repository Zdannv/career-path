"use client";

/**
 * Layar penuh setelah quest diselesaikan.
 *
 * Dua bentuk dari desain: "Yay! Satu Misi Selesai" biasa, dan versi "New
 * Badge Unlocked!" yang muncul kalau database melaporkan badge baru — saat ini
 * hanya Quest Starter, untuk quest pertama.
 *
 * Ilustrasi badge disusun dari dua gambar, anak yang bersorak dan badge-nya,
 * dengan letak persis bingkai Figma (335 x 322). Dipisah supaya badge
 * berikutnya cukup mengganti satu gambar, bukan mengekspor ulang komposisinya.
 */

import { useEffect } from "react";
import Image from "next/image";
import type { HasilSelesai } from "@/lib/quest";

const PESAN = "Satu misi terselesaikan. Setiap langkah kecil membawa dampak besar bagi progresmu.";

export default function SuksesQuest({
  hasil,
  onTutup,
}: {
  hasil: HasilSelesai | null;
  onTutup: () => void;
}) {
  useEffect(() => {
    if (!hasil) return;
    const semula = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onEsc = (e: KeyboardEvent) => {
      if (e.key === "Escape") onTutup();
    };
    document.addEventListener("keydown", onEsc);
    return () => {
      document.body.style.overflow = semula;
      document.removeEventListener("keydown", onEsc);
    };
  }, [hasil, onTutup]);

  if (!hasil) return null;
  const badge = hasil.badge;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={badge ? `Badge baru: ${badge.nama}` : "Quest selesai"}
      className="fixed inset-0 z-50 overflow-y-auto bg-white"
    >
      <div className="mx-auto flex min-h-full w-full max-w-md flex-col justify-center px-5 py-10">
        {badge ? (
          <>
            <div className="relative mx-auto aspect-[335/322] w-full max-w-[300px]">
              <Image
                src="/quest/rayakan.png"
                alt=""
                width={600}
                height={600}
                priority
                className="absolute left-[23.1%] top-0 h-auto w-[56.9%]"
              />
              <Image
                src={badge.gambar}
                alt={`Badge ${badge.nama}`}
                width={500}
                height={571}
                priority
                className="absolute left-[26.6%] top-[44.3%] h-auto w-[46.9%]"
              />
            </div>
            <div className="mt-4 text-center">
              <p className="text-[13px] font-semibold text-violet-600">New Badge Unlocked!</p>
              <h2 className="mt-1 text-[26px] font-bold tracking-tight text-slate-900">{badge.nama}</h2>
              <p className="mt-1 text-[14px] text-slate-600">{badge.deskripsi}</p>
            </div>
            <div className="mt-5 rounded-2xl bg-[#E8EEFF] px-5 py-4 text-center">
              <p className="text-[15px] font-bold text-slate-900">Yay! Satu Misi Selesai 🎉</p>
              <p className="mt-1.5 text-[12.5px] leading-relaxed text-slate-500">{PESAN}</p>
            </div>
          </>
        ) : (
          <>
            <Image
              src="/quest/sukses.png"
              alt=""
              width={640}
              height={640}
              priority
              className="mx-auto h-auto w-full max-w-[260px]"
            />
            <div className="mt-10 text-center">
              <h2 className="text-[18px] font-bold text-slate-900">Yay! Satu Misi Selesai 🎉</h2>
              <p className="mx-auto mt-2 max-w-xs text-[13.5px] leading-relaxed text-slate-500">{PESAN}</p>
            </div>
          </>
        )}

        <p className="mt-4 text-center text-[13px] font-semibold text-slate-700">
          +{hasil.xp} <span className="text-emerald-500">XP</span>
          <span className="font-normal text-slate-400"> · total {hasil.total_xp} XP, Level {hasil.level_name}</span>
        </p>

        <button
          type="button"
          onClick={onTutup}
          autoFocus
          className="mt-8 w-full rounded-full bg-[#7033FF] py-3 text-[15px] font-medium text-white transition-colors hover:bg-violet-700"
        >
          Close
        </button>
      </div>
    </div>
  );
}
