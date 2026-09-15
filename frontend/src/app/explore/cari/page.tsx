"use client";

/** Pencarian profesi beserta lembar Filters. */

import RequireAuth from "@/components/RequireAuth";
import PencarianView from "@/components/profesi/PencarianView";

export default function Page() {
  return (
    <RequireAuth pesan="Menyiapkan pencarian…">
      <PencarianView />
    </RequireAuth>
  );
}
