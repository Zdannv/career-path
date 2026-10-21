import React from "react";
import Link from "next/link";
import Image from "next/image";
import { ROUTES } from "@/lib/routes";

/** Centered "Navika | Career path journey" lockup shown above the auth cards. */
export default function AuthBrandHeader({ className = "" }: { className?: string }) {
  return (
    <div className={`flex items-center justify-center gap-4 py-8 sm:py-10 ${className}`}>
      <Link href={ROUTES.landing} className="cursor-pointer">
        <Image
          src="/navika-logo.png"
          alt="Navika"
          width={101}
          height={32}
          className="h-8 w-auto"
          priority
        />
      </Link>

      <div className="w-px h-9 bg-slate-300" />

      <div className="leading-tight">
        <div className="text-sm font-bold text-slate-900">Career path journey</div>
        <div className="text-sm text-slate-400">Sub1 Studio</div>
      </div>
    </div>
  );
}

/**
 * Penutup halaman auth versi ponsel. Di ponsel lockup atas diganti ilustrasi,
 * jadi nama produk pindah ke sini.
 */
export function AuthFooterMobile() {
  return (
    <p className="mt-16 border-t border-slate-200 py-5 text-center text-sm text-slate-600 sm:hidden">
      <span className="font-bold text-slate-900">Navika</span> - Career Path Journey
    </p>
  );
}
