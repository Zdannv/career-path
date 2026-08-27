"use client";

import React, { useId, useState } from "react";
import { Eye, EyeOff, type LucideIcon } from "lucide-react";

type AuthFieldProps = {
  label: string;
  icon: LucideIcon;
  type?: "text" | "email" | "password";
  value: string;
  onChange: (value: string) => void;
  onBlur?: () => void;
  placeholder?: string;
  /** Shown under the field. Rendered in red together with the label when `error` is set. */
  hint?: string;
  /** When set, the label + border turn red and this replaces `hint`. */
  error?: string | null;
  autoComplete?: string;
};

/**
 * Pill-shaped labelled input used across the auth screens. Password fields get a
 * show/hide toggle; the label turns red alongside the border when `error` is set.
 */
export default function AuthField({
  label,
  icon: Icon,
  type = "text",
  value,
  onChange,
  onBlur,
  placeholder,
  hint,
  error,
  autoComplete,
}: AuthFieldProps) {
  const id = useId();
  const [revealed, setRevealed] = useState(false);
  const isPassword = type === "password";
  const message = error ?? hint;

  return (
    <div>
      <label
        htmlFor={id}
        className={`block text-sm font-bold mb-1.5 ${error ? "text-[#E54B4F]" : "text-slate-900"}`}
      >
        {label}
      </label>

      <div className="relative">
        <Icon
          className={`pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 ${
            error ? "text-[#E54B4F]" : "text-slate-400"
          }`}
        />
        <input
          id={id}
          type={isPassword && revealed ? "text" : type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onBlur={onBlur}
          placeholder={placeholder}
          autoComplete={autoComplete}
          aria-invalid={error ? true : undefined}
          aria-describedby={message ? `${id}-message` : undefined}
          className={`w-full rounded-full border bg-white pl-11 ${
            isPassword ? "pr-11" : "pr-4"
          } py-2.5 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition-colors ${
            error
              ? "border-[#E54B4F] focus:border-[#E54B4F]"
              : "border-slate-200 focus:border-[#7033FF]"
          }`}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setRevealed((v) => !v)}
            aria-label={revealed ? "Sembunyikan kata sandi" : "Tampilkan kata sandi"}
            className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors cursor-pointer"
          >
            {revealed ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
        )}
      </div>

      {message && (
        <p id={`${id}-message`} className="mt-1.5 text-sm text-[#525252] leading-snug">
          {message}
        </p>
      )}
    </div>
  );
}
