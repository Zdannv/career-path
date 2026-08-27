"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Timer, ChevronUp, ChevronDown } from "lucide-react";

const WIDE_SRC = "/auth/signup-illustration.png";
const WIDE_ALT = "Mulai perjalanan kariermu bersama Navika";

/**
 * Wide onboarding artwork for the desktop card's left panel. Stretches to
 * whatever height the form column ends up at. The "Estimasi penyelesaian"
 * pill is part of the exported artwork, so nothing is overlaid here.
 */
export function SignupIllustrationPanel({ className = "" }: { className?: string }) {
  return (
    <div className={`relative overflow-hidden ${className}`}>
      <Image
        src={WIDE_SRC}
        alt={WIDE_ALT}
        fill
        sizes="(max-width: 1024px) 100vw, 625px"
        className="object-cover"
        priority
      />
    </div>
  );
}

/**
 * Tablet artwork — a slightly wider composition than the desktop panel, shown at
 * its natural aspect ratio underneath the form rather than beside it.
 */
export function SignupIllustrationBlock({ className = "" }: { className?: string }) {
  return (
    <Image
      src="/auth/signup-illustration-tablet.png"
      alt={WIDE_ALT}
      width={688}
      height={574}
      className={`w-full h-auto ${className}`}
    />
  );
}

/**
 * Mobile-only variant: an estimate bar that doubles as a toggle for the tall
 * version of the artwork.
 */
export function SignupIllustrationCollapsible() {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="rounded-2xl border border-slate-200 overflow-hidden bg-white">
      {expanded && (
        <Image
          src="/auth/signup-illustration-mobile.png"
          alt={WIDE_ALT}
          width={343}
          height={618}
          className="w-full h-auto"
        />
      )}

      <div className="flex items-center gap-3 px-4 py-3">
        <div className="w-9 h-9 rounded-full bg-indigo-50 flex items-center justify-center shrink-0">
          <Timer className="w-4 h-4 text-[#7033FF]" />
        </div>
        <div className="leading-tight flex-1">
          <div className="text-sm font-bold text-slate-900">Estimasi penyelesaian</div>
          <div className="text-sm text-[#525252]">~3 menit</div>
        </div>
        <button
          type="button"
          onClick={() => setExpanded((v) => !v)}
          aria-expanded={expanded}
          aria-label={expanded ? "Sembunyikan ilustrasi" : "Tampilkan ilustrasi"}
          className="w-9 h-9 rounded-full border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-slate-50 transition-colors cursor-pointer shrink-0"
        >
          {expanded ? <ChevronDown className="w-4 h-4" /> : <ChevronUp className="w-4 h-4" />}
        </button>
      </div>
    </div>
  );
}
