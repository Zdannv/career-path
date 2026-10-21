"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import { X, ZoomIn } from "lucide-react";

const SRC = "/landing/knowledge-graph.webp";
const ALT =
  "Career Knowledge Graph: profesi terhubung dengan pola kepribadian, tahapan, kompetensi, keterampilan, alat dan teknologi, pendidikan, sertifikasi, peran kerja, industri, gaji, permintaan pasar, dan jalur karier";

/**
 * Seksi "Career Building" di landing.
 *
 * Ilustrasinya tinggi (962x1634) dan teksnya kecil, jadi di halaman ia
 * dipotong ke tinggi yang wajar. "Tampilkan lebih detail" membuka versi
 * penuhnya di lapisan layar penuh yang bisa digulir.
 */
export default function KnowledgeGraphLanding() {
  const [buka, setBuka] = useState(false);

  useEffect(() => {
    if (!buka) return;
    const lama = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setBuka(false);
    window.addEventListener("keydown", onKey);
    return () => {
      document.body.style.overflow = lama;
      window.removeEventListener("keydown", onKey);
    };
  }, [buka]);

  return (
    <section className="bg-white py-16 sm:py-20">
      <div className="mx-auto grid max-w-6xl items-center gap-10 px-4 sm:px-6 lg:grid-cols-2 lg:gap-16 lg:px-8">
        <div className="text-center lg:text-left">
          <p className="text-sm font-medium text-[#7033FF]">Career Building</p>
          <h2 className="mt-3 text-3xl font-medium text-slate-900 sm:text-4xl">
            Menggunakan Career Knowledge Graph
          </h2>
          <p className="mx-auto mt-3 max-w-md text-base leading-relaxed text-[#525252] lg:mx-0">
            Data dari berbagai sumber saling terhubung untuk menghasilkan rekomendasi yang lebih
            akurat dan relevan.
          </p>
          <button
            type="button"
            onClick={() => setBuka(true)}
            className="mt-6 hidden cursor-pointer items-center gap-2 rounded-full bg-slate-100 px-5 py-2.5 text-sm font-medium text-slate-900 transition-colors hover:bg-slate-200 lg:inline-flex"
          >
            Tampilkan lebih detail
            <ZoomIn className="size-4" />
          </button>
        </div>

        <div className="flex flex-col items-center">
          <button
            type="button"
            onClick={() => setBuka(true)}
            aria-label="Perbesar Career Knowledge Graph"
            className="relative w-full max-w-[340px] cursor-zoom-in overflow-hidden rounded-3xl sm:max-w-[400px]"
          >
            <Image src={SRC} alt={ALT} width={962} height={1634} className="h-auto w-full" />
          </button>
          <button
            type="button"
            onClick={() => setBuka(true)}
            className="mt-6 inline-flex cursor-pointer items-center gap-2 rounded-full bg-slate-100 px-5 py-2.5 text-sm font-medium text-slate-900 transition-colors hover:bg-slate-200 lg:hidden"
          >
            Tampilkan lebih detail
            <ZoomIn className="size-4" />
          </button>
        </div>
      </div>

      {buka && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Career Knowledge Graph"
          className="fixed inset-0 z-[70] overflow-y-auto bg-slate-900/80 px-3 py-14 sm:px-6"
          onClick={() => setBuka(false)}
        >
          <button
            type="button"
            onClick={() => setBuka(false)}
            aria-label="Tutup"
            className="fixed right-4 top-4 z-10 grid size-10 cursor-pointer place-items-center rounded-full bg-white text-slate-900 shadow-lg"
          >
            <X className="size-5" />
          </button>
          <Image
            src={SRC}
            alt={ALT}
            width={962}
            height={1634}
            sizes="(max-width: 768px) 100vw, 760px"
            onClick={(e) => e.stopPropagation()}
            className="mx-auto h-auto w-full max-w-[760px] rounded-2xl"
          />
        </div>
      )}
    </section>
  );
}
