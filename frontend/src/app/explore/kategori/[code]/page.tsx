"use client";

/** Detail kategori profesi (rumpun). */

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { getFamilyDetail, type FamilyDetail } from "@/lib/careerDetail";
import { ROUTES } from "@/lib/routes";
import RequireAuth from "@/components/RequireAuth";
import KategoriDetail from "@/components/profesi/KategoriDetail";

function Isi({ code }: { code: string }) {
  const router = useRouter();
  const [detail, setDetail] = useState<FamilyDetail | null>(null);
  const [memuat, setMemuat] = useState(true);

  const muat = useCallback(async () => {
    setDetail(await getFamilyDetail(code));
    setMemuat(false);
  }, [code]);

  useEffect(() => {
    void muat();
  }, [muat]);

  if (memuat) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
        <p className="text-[12px] font-semibold text-slate-500">Membuka kategori…</p>
      </div>
    );
  }

  if (!detail) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 px-6 text-center">
        <p className="text-[15px] font-semibold text-slate-900">Kategori tidak ditemukan</p>
        <button
          onClick={() => router.push(ROUTES.explore)}
          className="mt-1 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
        >
          Kembali ke Explore
        </button>
      </div>
    );
  }

  return <KategoriDetail detail={detail} />;
}

export default function Page() {
  const params = useParams<{ code: string }>();
  return (
    <RequireAuth pesan="Membuka kategori…">
      <Isi code={decodeURIComponent(params?.code ?? "")} />
    </RequireAuth>
  );
}
