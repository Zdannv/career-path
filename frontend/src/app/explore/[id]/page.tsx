"use client";

/**
 * Detail profesi.
 *
 * Hanya tab pertama yang diambil di sini; dua tab lainnya mengambil datanya
 * sendiri saat dibuka (lihat ProfesiDetail).
 */

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { getCareerDetail, type CareerDetail } from "@/lib/careerDetail";
import { ROUTES } from "@/lib/routes";
import RequireAuth from "@/components/RequireAuth";
import ProfesiDetail from "@/components/profesi/ProfesiDetail";

function Isi({ id }: { id: number }) {
  const router = useRouter();
  const [detail, setDetail] = useState<CareerDetail | null>(null);
  const [memuat, setMemuat] = useState(true);

  const muat = useCallback(async () => {
    if (!Number.isFinite(id)) {
      setMemuat(false);
      return;
    }
    setDetail(await getCareerDetail(id));
    setMemuat(false);
  }, [id]);

  useEffect(() => {
    void muat();
  }, [muat]);

  if (memuat) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
        <p className="text-[12px] font-semibold text-slate-500">Membuka profesi…</p>
      </div>
    );
  }

  if (!detail) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 px-6 text-center">
        <p className="text-[15px] font-semibold text-slate-900">Profesi tidak ditemukan</p>
        <p className="max-w-sm text-[13px] text-slate-500">
          Profesi ini mungkin sudah tidak aktif. Coba cari lagi dari Explore.
        </p>
        <button
          onClick={() => router.push(ROUTES.explore)}
          className="mt-1 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
        >
          Kembali ke Explore
        </button>
      </div>
    );
  }

  return <ProfesiDetail detail={detail} />;
}

export default function Page() {
  const params = useParams<{ id: string }>();
  return (
    <RequireAuth pesan="Membuka profesi…">
      <Isi id={Number(params?.id)} />
    </RequireAuth>
  );
}
