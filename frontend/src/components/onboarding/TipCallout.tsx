import React from "react";

/** Kotak tips ungu, mis. penjelasan kapan memilih "Semester Akhir". */
export default function TipCallout({
  children,
  muted = false,
}: {
  children: React.ReactNode;
  /** Pudar bersama pilihan semester saat tidak berlaku. */
  muted?: boolean;
}) {
  return (
    <div
      className={`rounded-lg px-4 py-3 text-sm leading-relaxed border-l-[3px] ${
        muted
          ? "bg-slate-50 text-slate-300 border-[#DDD0FF]"
          : "bg-[#F1EBFF] text-slate-700 border-[#7033FF]"
      }`}
    >
      {children}
    </div>
  );
}
