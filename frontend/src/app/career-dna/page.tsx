"use client";

/**
 * Career DNA (Discovery).
 *
 * Halaman ini hanya mengurus dua hal: memuat opsi dan progres, lalu
 * menyerahkan sisanya ke DnaFlow. Sesi dijaga RequireAuth. Kalau DNA-nya sudah
 * selesai,
 * pengguna dibawa langsung ke layar penutup — bukan disuruh mengisi ulang dari
 * langkah satu.
 */

import { useCallback, useEffect, useState } from "react";
import { Loader2 } from "lucide-react";
import {
  completeDna,
  getDnaProgress,
  getDnaSteps,
  saveDnaStep,
  type DnaLayerStep,
} from "@/lib/careerDna";
import RequireAuth from "@/components/RequireAuth";
import DnaFlow from "@/components/career-dna/DnaFlow";

function CareerDnaIsi() {
  const [memuat, setMemuat] = useState(true);
  const [steps, setSteps] = useState<DnaLayerStep[]>([]);
  const [picks, setPicks] = useState<Record<string, string[]>>({});
  const [reached, setReached] = useState(1);
  const [sudahSelesai, setSudahSelesai] = useState(false);

  const muat = useCallback(async () => {
    const [s, p] = await Promise.all([getDnaSteps(), getDnaProgress()]);
    setSteps(s);
    setPicks(p.picks);
    setReached(p.currentStep);
    setSudahSelesai(p.completedAt !== null);
    setMemuat(false);
  }, []);

  useEffect(() => {
    void muat();
  }, [muat]);

  if (memuat) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
        <p className="text-[12px] font-semibold text-slate-500">Menyiapkan Career DNA…</p>
      </div>
    );
  }

  if (steps.length === 0) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3 px-6 text-center">
        <p className="text-[15px] font-semibold text-slate-900">Career DNA belum bisa dimuat</p>
        <p className="max-w-sm text-[13px] text-slate-500">
          Daftar pilihannya tidak terbaca. Coba muat ulang halaman ini.
        </p>
        <button
          onClick={() => {
            setMemuat(true);
            void muat();
          }}
          className="mt-1 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
        >
          Coba lagi
        </button>
      </div>
    );
  }

  return (
    <DnaFlow
      steps={steps}
      initialPicks={picks}
      initialReached={reached}
      initialScreen={sudahSelesai ? "selesai" : "intro"}
      onSaveStep={async (layerCode, codes, nextStep) => {
        const { error } = await saveDnaStep(layerCode, codes, nextStep);
        return error;
      }}
      onComplete={async () => {
        const { error } = await completeDna();
        return error;
      }}
    />
  );
}

export default function CareerDnaPage() {
  return (
    <RequireAuth pesan="Menyiapkan Career DNA…">
      <CareerDnaIsi />
    </RequireAuth>
  );
}
