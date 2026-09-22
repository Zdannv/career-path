"use client";

import { useParams } from "next/navigation";
import RequireAuth from "@/components/RequireAuth";
import QuestGrupView from "@/components/quest/QuestGrupView";

export default function Page() {
  const params = useParams<{ jenis: string; kode: string }>();
  return (
    <RequireAuth pesan="Membuka quest…">
      <QuestGrupView
        slug={params?.jenis ?? ""}
        kode={decodeURIComponent(params?.kode ?? "")}
      />
    </RequireAuth>
  );
}
