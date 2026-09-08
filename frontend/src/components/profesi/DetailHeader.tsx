"use client";

/**
 * Bar atas layar detail: panah kembali, dua baris judul, tombol simpan.
 *
 * Menempel di atas karena isinya panjang dan pengguna sering menggulir jauh
 * sebelum memutuskan — tanpa ini, satu-satunya jalan keluar adalah tombol
 * kembali peramban, yang tidak ada di aplikasi terpasang.
 */

import { useRouter } from "next/navigation";
import { ArrowLeft, BookmarkPlus } from "lucide-react";

export default function DetailHeader({
  judul,
  subjudul,
  onSimpan,
}: {
  judul: string;
  subjudul?: string | null;
  onSimpan?: () => void;
}) {
  const router = useRouter();
  return (
    <header className="sticky top-0 z-30 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div className="mx-auto flex max-w-3xl items-center gap-3 px-4 py-3 sm:px-6">
        <button
          type="button"
          onClick={() => router.back()}
          aria-label="Kembali"
          className="-ml-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
        >
          <ArrowLeft className="size-5" aria-hidden />
        </button>
        <div className="min-w-0 flex-1 leading-tight">
          <p className="truncate text-[14px] font-semibold text-slate-900">{judul}</p>
          {subjudul && <p className="truncate text-[12px] text-slate-400">{subjudul}</p>}
        </div>
        <button
          type="button"
          onClick={onSimpan}
          aria-label="Simpan profesi"
          className="rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
        >
          <BookmarkPlus className="size-5" aria-hidden />
        </button>
      </div>
    </header>
  );
}
