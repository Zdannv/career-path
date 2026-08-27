import React from "react";
import Link from "next/link";

/** Centered "Navika | Career path journey" lockup shown above the auth cards. */
export default function AuthBrandHeader() {
  return (
    <div className="flex items-center justify-center gap-4 py-8 sm:py-10">
      <Link href="/" className="flex items-center gap-2 cursor-pointer">
        <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-black text-sm shadow-sm">
          N
        </div>
        <span className="font-black text-slate-900 text-xl tracking-tight">Navika</span>
      </Link>

      <div className="w-px h-9 bg-slate-300" />

      <div className="leading-tight">
        <div className="text-sm font-bold text-slate-900">Career path journey</div>
        <div className="text-sm text-slate-400">Sub1 Studio</div>
      </div>
    </div>
  );
}
