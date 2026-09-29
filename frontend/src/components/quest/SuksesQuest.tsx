"use client";

/**
 * Layar penuh setelah quest diselesaikan.
 *
 * Dua bentuk dari desain: "Yay! Satu Misi Selesai" biasa, dan versi "New Badge
 * Unlocked!" yang muncul kalau database melaporkan badge baru.
 *
 * Tombolnya berbeda di antara keduanya, dan itu disengaja di desain: yang biasa
 * menawarkan dua jalan keluar (lanjut mengerjakan quest, atau kembali ke
 * Explore), sedangkan yang berbadge hanya "Close" — supaya badge-nya sempat
 * dilihat dulu, bukan langsung terlewat oleh tombol lanjut.
 */

import { useEffect } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ArrowRight, Compass } from "lucide-react";
import { ROUTES } from "@/lib/routes";
import type { HasilSelesai } from "@/lib/quest";

const PESAN = "Satu misi terselesaikan. Setiap langkah kecil membawa dampak besar bagi progresmu.";

export default function SuksesQuest({
  hasil,
  onTutup,
}: {
  hasil: HasilSelesai | null;
  onTutup: () => void;
}) {
  const router = useRouter();

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
            <Image
              src={badge.gambar}
              alt={`Badge ${badge.nama}`}
              width={500}
              height={571}
              priority
              className="mx-auto h-auto w-full max-w-[190px]"
            />
            <div className="mt-6 text-center">
              <p className="text-[14px] font-semibold text-blue-600">New Badge Unlocked!</p>
              <h2 className="mt-1 text-[26px] font-bold tracking-tight text-slate-900">{badge.nama}</h2>
              <p className="mt-1 text-[14px] text-slate-500">{badge.deskripsi}</p>
            </div>

            <div className="mt-6 rounded-2xl bg-[#EEF2FF] px-5 py-4 text-center">
              <p className="text-[15px] font-bold text-slate-900">Yay! Satu Misi Selesai 🎉</p>
              <p className="mt-1.5 text-[12.5px] leading-relaxed text-slate-500">{PESAN}</p>
            </div>

            <p className="mt-4 text-center text-[13px] font-semibold text-slate-700">
              +{hasil.xp} <span className="text-emerald-500">XP</span>
              <span className="font-normal text-slate-400">
                {" "}
                · total {hasil.total_xp} XP, Level {hasil.level_name}
              </span>
            </p>

            <button
              type="button"
              onClick={onTutup}
              autoFocus
              className="mt-7 w-full rounded-full bg-[#7033FF] py-3.5 text-[15px] font-medium text-white transition-colors hover:bg-violet-700"
            >
              Close
            </button>
          </>
        ) : (
          <>
            <Image
              src="/quest/sukses.png"
              alt=""
              width={560}
              height={560}
              priority
              className="mx-auto h-auto w-full max-w-[220px]"
            />
            <div className="mt-8 text-center">
              <h2 className="text-[18px] font-bold text-slate-900">Yay! Satu Misi Selesai 🎉</h2>
              <p className="mx-auto mt-2 max-w-xs text-[13.5px] leading-relaxed text-slate-500">
                {PESAN}
              </p>
            </div>

            <p className="mt-4 text-center text-[13px] font-semibold text-slate-700">
              +{hasil.xp} <span className="text-emerald-500">XP</span>
              <span className="font-normal text-slate-400">
                {" "}
                · total {hasil.total_xp} XP, Level {hasil.level_name}
              </span>
            </p>

            <div className="mt-8 space-y-2.5">
              <button
                type="button"
                onClick={onTutup}
                autoFocus
                className="flex w-full items-center justify-center gap-2 rounded-full bg-[#7033FF] py-3.5 text-[15px] font-medium text-white transition-colors hover:bg-violet-700"
              >
                Kembali ke Quest
                <ArrowRight className="size-4" aria-hidden />
              </button>
              <button
                type="button"
                onClick={() => router.push(ROUTES.explore)}
                className="flex w-full items-center justify-center gap-2 rounded-full bg-slate-100 py-3.5 text-[15px] font-medium text-slate-700 transition-colors hover:bg-slate-200"
              >
                <Compass className="size-4" aria-hidden />
                Kembali ke Explore
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
