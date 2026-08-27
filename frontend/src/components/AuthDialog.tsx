"use client";

import React, { useEffect, useRef } from "react";
import Image from "next/image";
import { X } from "lucide-react";

type AuthDialogProps = {
  /** Small label in the top-left of the dialog, e.g. "Email Terkirim". */
  title: string;
  imageSrc: string;
  imageAlt: string;
  /** Bold line under the illustration. */
  heading: string;
  description: string;
  actionLabel: string;
  onAction: () => void;
  actionPending?: boolean;
  onClose: () => void;
};

/**
 * Centered confirmation dialog used at the end of the reset-password flow.
 * Closes on Escape or backdrop click and traps initial focus on the action.
 */
export default function AuthDialog({
  title,
  imageSrc,
  imageAlt,
  heading,
  description,
  actionLabel,
  onAction,
  actionPending = false,
  onClose,
}: AuthDialogProps) {
  const actionRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    actionRef.current?.focus();
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 px-5"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[346px] rounded-2xl bg-white p-5 shadow-2xl"
      >
        <div className="flex items-start justify-between gap-4">
          <h2 className="text-sm font-bold text-slate-900">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Tutup"
            className="text-slate-400 hover:text-slate-600 transition-colors cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="mt-4 flex justify-center">
          <Image src={imageSrc} alt={imageAlt} width={200} height={200} className="w-[120px] h-auto" />
        </div>

        <p className="mt-4 text-center text-sm font-bold text-slate-900">{heading}</p>
        <p className="mt-1.5 text-center text-sm text-[#525252] leading-relaxed">{description}</p>

        <button
          ref={actionRef}
          type="button"
          onClick={onAction}
          disabled={actionPending}
          className="mt-5 w-full rounded-full py-3 text-sm font-semibold text-white transition-colors cursor-pointer bg-[#7033FF] hover:bg-[#5f27e6] disabled:bg-[#B698FE] disabled:cursor-not-allowed"
        >
          {actionPending ? "Mengirim..." : actionLabel}
        </button>
      </div>
    </div>
  );
}
