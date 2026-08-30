"use client";

import React from "react";
import { Check, Sparkles } from "lucide-react";
import OnboardingIllustration, { type IllustrationKey } from "./OnboardingIllustration";

export type StepMeta = { title: string; description: string };

type StepSidebarProps = {
  step: 1 | 2 | 3;
  steps: StepMeta[];
  illustration: IllustrationKey;
};

/**
 * Panel kiri versi desktop: ilustrasi + daftar langkah.
 *
 * Hanya muncul dari `lg` ke atas. Di mobile dan tablet desainnya satu kolom,
 * dan kartu progres di atas konten sudah menyampaikan informasi yang sama —
 * menampilkan keduanya justru mengulang tanpa menambah kejelasan.
 */
export default function StepSidebar({ step, steps, illustration }: StepSidebarProps) {
  return (
    // Ilustrasinya nyaris penuh selebar panel (desain hanya menyisakan ~12px),
    // sementara daftar langkah menjorok lebih dalam — makanya padding luarnya
    // kecil dan teksnya diberi `px-5` sendiri, bukan satu padding seragam.
    <aside className="hidden lg:flex lg:flex-col lg:gap-9 lg:border-r lg:border-slate-100 lg:p-3">
      <OnboardingIllustration
        name={illustration}
        className="h-auto w-full rounded-2xl"
        priority
      />

      <div className="px-5 pb-3">
        <p className="text-sm font-bold text-slate-900">STEP ({step}/{steps.length})</p>

        <ol className="mt-5">
          {steps.map((s, i) => {
            const n = i + 1;
            const done = n < step;
            const current = n === step;
            const last = n === steps.length;

            return (
              <li key={s.title} className="relative flex gap-3 pb-6 last:pb-0">
                {/* Garis penghubung digambar di belakang bulatan, bukan di antaranya,
                    supaya tinggi tiap item bebas mengikuti panjang deskripsinya. */}
                {!last && (
                  <span
                    aria-hidden
                    className="absolute left-[11px] top-6 bottom-0 w-px bg-slate-200"
                  />
                )}

                <span
                  className={[
                    "relative z-10 mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[11px] font-semibold",
                    done
                      ? "bg-[#22A06B] text-white"
                      : current
                        ? "bg-[#7033FF] text-white"
                        : "bg-white text-[#7033FF] ring-1 ring-slate-200",
                  ].join(" ")}
                >
                  {done ? (
                    <Check className="h-3.5 w-3.5" strokeWidth={3} />
                  ) : current ? (
                    <Sparkles className="h-3.5 w-3.5" />
                  ) : (
                    n
                  )}
                </span>

                <div className="min-w-0 pt-0.5">
                  <p className="text-sm font-semibold text-[#7033FF]">{s.title}</p>
                  <p className="mt-0.5 text-sm leading-relaxed text-[#525252]">{s.description}</p>
                </div>
              </li>
            );
          })}
        </ol>
      </div>
    </aside>
  );
}
