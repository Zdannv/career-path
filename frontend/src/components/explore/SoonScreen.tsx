"use client";

/**
 * Layar penampung untuk tujuan navigasi yang belum dibangun.
 *
 * Bar navigasi memuat lima tujuan sesuai desain, tapi baru Explore yang jadi.
 * Menautkannya ke halaman yang tidak ada berarti 404; menonaktifkannya berarti
 * bar-nya tidak lagi sama dengan desain. Jadi tujuannya tetap bisa diklik dan
 * mengaku apa adanya bahwa layarnya belum ada.
 */

import Link from "next/link";
import { ArrowLeft, Hammer } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";

export default function SoonScreen({ title, note }: { title: string; note: string }) {
  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />
      <main className="flex flex-1 flex-col items-center justify-center gap-3 px-6 text-center">
        <span className="grid size-12 place-items-center rounded-2xl bg-violet-50 text-violet-600">
          <Hammer className="size-5" aria-hidden />
        </span>
        <h1 className="text-[18px] font-bold tracking-tight text-slate-900">{title}</h1>
        <p className="max-w-sm text-[13.5px] leading-relaxed text-slate-500">{note}</p>
        <Link
          href="/explore"
          className="mt-2 inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-[13px] font-semibold text-slate-700 transition-colors hover:bg-slate-50"
        >
          <ArrowLeft className="size-4" aria-hidden />
          Kembali ke Explore
        </Link>
      </main>
      <AppBottomNav />
    </div>
  );
}
