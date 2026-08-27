"use client";

import React from "react";
import { useRouter } from "next/navigation";

type AuthPageShellProps = {
  children: React.ReactNode;
  /** Where a backdrop click sends the user. */
  cancelHref?: string;
  className?: string;
};

/**
 * Wraps an auth screen and treats the area around the card like a modal
 * backdrop: clicking it leaves the flow.
 *
 * Only active from `lg` up. Below that breakpoint the screen is a full-bleed
 * white page with no backdrop at all, so a tap on blank space would navigate
 * away with nothing on screen to suggest it would.
 */
export default function AuthPageShell({
  children,
  cancelHref = "/",
  className = "",
}: AuthPageShellProps) {
  const router = useRouter();

  const handleBackdropClick = (event: React.MouseEvent<HTMLDivElement>) => {
    const target = event.target as HTMLElement | null;
    if (!target) return;

    // The card, any open dialog, and every control keep their own behaviour.
    if (target.closest("[data-auth-card]")) return;
    if (target.closest("a, button, input, label, select, textarea, [role='dialog']")) return;

    if (!window.matchMedia("(min-width: 1024px)").matches) return;

    router.push(cancelHref);
  };

  return (
    <div
      onClick={handleBackdropClick}
      className={`flex-1 bg-white lg:bg-[#CBD5E1] ${className}`}
    >
      {children}
    </div>
  );
}
