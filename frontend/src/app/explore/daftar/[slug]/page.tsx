"use client";

/** Daftar lengkap satu baris Explore: paling-diminati, program-studi, match, aktivitas. */

import { useParams } from "next/navigation";
import RequireAuth from "@/components/RequireAuth";
import DaftarBaris from "@/components/explore/DaftarBaris";

export default function Page() {
  const params = useParams<{ slug: string }>();
  return (
    <RequireAuth pesan="Menyiapkan daftar profesi…">
      <DaftarBaris slug={params?.slug ?? ""} />
    </RequireAuth>
  );
}
