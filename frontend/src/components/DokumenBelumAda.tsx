"use client";

/**
 * Penampung untuk halaman dokumen yang sudah ditautkan tapi isinya belum ada.
 *
 * Halaman daftar sudah menautkan Syarat Layanan dan Kebijakan Privasi, dan
 * tautan itu memang harus ada di sana. Yang tidak boleh adalah tautannya jatuh
 * ke 404 — pengguna jadi menduga situsnya rusak, tepat pada saat ia diminta
 * menyerahkan datanya. Jadi halamannya ada dan mengaku apa adanya.
 */

import Link from "next/link";
import { ArrowLeft, FileText } from "lucide-react";
import { ROUTES } from "@/lib/routes";

export default function DokumenBelumAda({
  judul,
  ringkas,
}: {
  judul: string;
  ringkas: string;
}) {
  return (
    <main className="mx-auto flex min-h-[70vh] w-full max-w-2xl flex-col justify-center gap-3 px-6 py-16">
      <span className="grid size-12 place-items-center rounded-2xl bg-violet-50 text-violet-600">
        <FileText className="size-5" aria-hidden />
      </span>
      <h1 className="text-[22px] font-bold tracking-tight text-slate-900">{judul}</h1>
      <p className="text-[14px] leading-relaxed text-slate-600">{ringkas}</p>
      <p className="text-[13px] leading-relaxed text-slate-500">
        Dokumen resminya sedang disusun dan akan terbit di halaman ini. Sementara itu, kalau ada
        yang ingin Kamu tanyakan soal data yang Navika simpan, hubungi tim lewat kontak di
        halaman utama.
      </p>
      <Link
        href={ROUTES.landing}
        className="mt-3 inline-flex w-fit items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-[13px] font-semibold text-slate-700 transition-colors hover:bg-slate-50"
      >
        <ArrowLeft className="size-4" aria-hidden />
        Kembali ke halaman utama
      </Link>
    </main>
  );
}
