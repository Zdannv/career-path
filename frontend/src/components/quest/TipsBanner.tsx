/**
 * Banner "Tips" di layar Quest.
 *
 * Ekspor Figma-nya menggambar judul dan keterangan sebagai kurva di dalam SVG.
 * Di sini ilustrasinya saja yang dipakai (public/quest/tips-*.svg, dipotong
 * persis seperti bingkai aslinya berikut gradasi pudarnya), sedangkan
 * teksnya teks sungguhan — sama seperti banner Explore: tajam di ukuran apa
 * pun, terbaca pembaca layar, dan kalimatnya datang dari database.
 */

import { Sparkles } from "lucide-react";
import type { Tips } from "@/lib/quest";

const RAGAM = {
  RESOURCE: {
    bg: "bg-[#E2EBFF]",
    art: "/quest/tips-sumber.svg",
    // 164 dari 335 px di desain.
    lebar: "w-[49%]",
  },
  WHATS_NEXT: {
    bg: "bg-[#DDD6FE]",
    art: "/quest/tips-lanjut.svg",
    // 119 dari 335 px.
    lebar: "w-[36%]",
  },
} as const;

function IkonAi() {
  return (
    <span
      aria-hidden
      className="grid size-4 place-items-center rounded-full border-[1.5px] border-blue-600 text-[7px] font-bold leading-none text-blue-600"
    >
      AI
    </span>
  );
}

function IkonYoutube() {
  return (
    <svg viewBox="0 0 16 12" className="h-3 w-4" aria-hidden>
      <rect width="16" height="12" rx="3" fill="#FF0000" />
      <path d="M6.4 3.4v5.2L10.6 6z" fill="#fff" />
    </svg>
  );
}

function IkonGoogle() {
  return (
    <svg viewBox="0 0 16 16" className="size-3.5" aria-hidden>
      <path d="M15.7 8.2c0-.6-.1-1.1-.2-1.6H8v3h4.3a3.7 3.7 0 0 1-1.6 2.4v2h2.6c1.5-1.4 2.4-3.4 2.4-5.8z" fill="#4285F4" />
      <path d="M8 16c2.2 0 4-.7 5.3-1.9l-2.6-2c-.7.5-1.6.8-2.7.8-2.1 0-3.9-1.4-4.5-3.3H.8v2.1A8 8 0 0 0 8 16z" fill="#34A853" />
      <path d="M3.5 9.6a4.8 4.8 0 0 1 0-3.1V4.4H.8a8 8 0 0 0 0 7.2l2.7-2z" fill="#FBBC05" />
      <path d="M8 3.2c1.2 0 2.3.4 3.1 1.2l2.3-2.3A8 8 0 0 0 .8 4.4l2.7 2.1C4.1 4.6 5.9 3.2 8 3.2z" fill="#EA4335" />
    </svg>
  );
}

export default function TipsBanner({ tips, besar = true }: { tips: Tips; besar?: boolean }) {
  const r = RAGAM[tips.gambar] ?? RAGAM.RESOURCE;
  return (
    <section
      className={`relative overflow-hidden rounded-[20px] ${r.bg}`}
      aria-label={tips.label}
    >
      {/* eslint-disable-next-line @next/next/no-img-element -- SVG kecil, tidak perlu dioptimasi next/image */}
      <img
        src={r.art}
        alt=""
        aria-hidden
        className={`pointer-events-none absolute right-0 top-0 h-auto max-w-[220px] ${r.lebar}`}
      />

      <div className="relative px-4 py-4">
        <p className="flex items-center gap-1.5 text-[13px] font-semibold text-violet-600">
          <Sparkles className="size-3.5" aria-hidden />
          {tips.label}
        </p>
        <h2
          className={`mt-1 max-w-[75%] font-bold tracking-tight text-slate-900 ${
            besar ? "text-[22px] leading-[1.25]" : "text-[17px] font-semibold leading-snug"
          }`}
        >
          {tips.judul}
        </h2>
        {tips.isi && (
          <p className="mt-1.5 max-w-[80%] text-[13px] leading-snug text-slate-600">{tips.isi}</p>
        )}
        {tips.sumber && (
          <ul className="mt-2.5 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-[12.5px] font-medium text-slate-800">
            <li className="flex items-center gap-1.5">
              <IkonAi />
              AI Chat
            </li>
            <li className="flex items-center gap-1.5">
              <IkonYoutube />
              Youtube
            </li>
            <li className="flex items-center gap-1.5">
              <IkonGoogle />
              Browsing Artikel
            </li>
          </ul>
        )}
      </div>
    </section>
  );
}
