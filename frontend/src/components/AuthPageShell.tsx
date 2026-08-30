"use client";

import React from "react";
import Link from "next/link";
import { X } from "lucide-react";

type AuthPageShellProps = {
  children: React.ReactNode;
  /** Where the close button sends the user. */
  cancelHref?: string;
  className?: string;
};

/**
 * Chrome around an auth card: the page background plus the way out of the flow.
 *
 * Leaving is an explicit close button rather than a click on the backdrop. The
 * backdrop only exists from `lg` up, so dismissing that way would work on
 * desktop and silently not exist on phones; it is also invisible, and these
 * cards hold half-typed credentials that a stray click should not discard.
 */
export default function AuthPageShell({
  children,
  cancelHref = "/",
  className = "",
}: AuthPageShellProps) {
  return (
    <div className={`relative flex-1 bg-white lg:bg-[#CBD5E1] ${className}`}>
      <Link
        href={cancelHref}
        aria-label="Tutup"
        className="absolute right-4 top-4 sm:right-6 sm:top-6 z-10 flex h-9 w-9 items-center justify-center rounded-full bg-white/80 text-slate-500 shadow-sm ring-1 ring-slate-200 transition-colors hover:bg-white hover:text-slate-900 cursor-pointer"
      >
        <X className="h-4 w-4" />
      </Link>

      {children}
    </div>
  );
}
