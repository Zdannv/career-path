"use client";

import React from "react";
import AuthModal from "@/components/AuthModal";

export default function DaftarPage() {
  return (
    <div className="min-h-[85vh] bg-[#f8fafc] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-[360px]">
        <AuthModal
          isOpen={true}
          onClose={() => {}}
          initialMode="daftar"
          isPageMode={true}
        />
      </div>
    </div>
  );
}
