import React from "react";

/** Kotak tips ungu, mis. penjelasan kapan memilih "Semester Akhir". */
export default function TipCallout({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-lg bg-[#F1EBFF] px-4 py-3 text-sm leading-relaxed text-slate-700 border-l-[3px] border-[#7033FF]">
      {children}
    </div>
  );
}
