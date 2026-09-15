"use client";

/**
 * Halaman 404.
 *
 * Ada karena pernah terjadi: tombol terakhir onboarding mengarah ke
 * "/dashboard" yang tidak pernah dibuat, dan yang muncul adalah layar 404
 * bawaan Next tanpa satu pun jalan keluar. Sekarang minimal ada dua pintu, dan
 * pintunya menyesuaikan status masuk.
 */

import { useEffect, useState } from "react";
import Link from "next/link";
import { Compass, Home } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { HOME_AFTER_ONBOARDING, ROUTES } from "@/lib/routes";

export default function NotFound() {
  const [masuk, setMasuk] = useState(false);

  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => setMasuk(Boolean(data.session)));
  }, []);

  return (
    <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 px-6 text-center">
      <p className="text-[13px] font-semibold tracking-widest text-violet-600">404</p>
      <h1 className="text-[20px] font-bold tracking-tight text-slate-900">
        Halaman ini tidak ada
      </h1>
      <p className="max-w-sm text-[13.5px] leading-relaxed text-slate-500">
        Alamatnya mungkin salah ketik, atau halamannya sudah dipindahkan.
      </p>
      <div className="mt-2 flex flex-wrap items-center justify-center gap-2.5">
        {masuk && (
          <Link
            href={HOME_AFTER_ONBOARDING}
            className="inline-flex items-center gap-2 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
          >
            <Compass className="size-4" aria-hidden />
            Buka Explore
          </Link>
        )}
        <Link
          href={ROUTES.landing}
          className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-5 py-2.5 text-[13px] font-semibold text-slate-700 transition-colors hover:bg-slate-50"
        >
          <Home className="size-4" aria-hidden />
          Ke halaman utama
        </Link>
      </div>
    </div>
  );
}
