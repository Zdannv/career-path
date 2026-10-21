"use client";

import React from "react";
import Image from "next/image";

const WIDE_SRC = "/auth/signup-illustration.webp";
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
      src="/auth/signup-illustration-tablet.webp"
      alt={WIDE_ALT}
      width={1254}
      height={729}
      className={`w-full h-auto ${className}`}
    />
  );
}
