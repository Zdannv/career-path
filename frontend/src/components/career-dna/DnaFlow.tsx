"use client";

/**
 * Alur Career DNA (Discovery): pembuka, lima langkah pemilihan, Review, penutup.
 *
 * Dipisah dari halamannya supaya bagian yang menggambar tidak ikut memikirkan
 * autentikasi dan pemanggilan RPC — dan supaya harness verifikasi bisa
 * menyuapkan data ke komponen yang sama dengan yang dipakai produksi.
 *
 * Progres disimpan setiap kali berpindah langkah, bukan hanya saat menekan
 * Simpan. Tombol Simpan di kepala layar karena itu sebenarnya konfirmasi
 * keluar; dialognya menyebut apa adanya bahwa progres sudah tersimpan.
 */

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowRight, ChevronRight, CornerUpLeft, Home, Save, X } from "lucide-react";
import { REVIEW_STEP, TOTAL_STEPS, type DnaLayerStep } from "@/lib/careerDna";
import DnaStepper from "@/components/career-dna/DnaStepper";
import DoneScreen from "@/components/career-dna/DoneScreen";
import IntroScreen from "@/components/career-dna/IntroScreen";
import OptionList from "@/components/career-dna/OptionList";
import ReviewList from "@/components/career-dna/ReviewList";
import SaveProgressDialog from "@/components/career-dna/SaveProgressDialog";
import StepHeaderBar, { type StepMeta } from "@/components/career-dna/StepHeaderBar";

type Layar = "intro" | "langkah" | "selesai";

export type DnaFlowProps = {
  steps: DnaLayerStep[];
  initialPicks: Record<string, string[]>;
  /** Langkah tertinggi yang sudah dicapai, 1..6. */
  initialReached: number;
  /** Mulai langsung di langkah tertentu, melewati pembuka. */
  initialScreen?: Layar;
  onSaveStep: (layerCode: string, codes: string[], nextStep: number) => Promise<string | null>;
  onComplete: () => Promise<string | null>;
};

export default function DnaFlow({
  steps,
  initialPicks,
  initialReached,
  initialScreen = "intro",
  onSaveStep,
  onComplete,
}: DnaFlowProps) {
  const router = useRouter();
  const [layar, setLayar] = useState<Layar>(initialScreen);
  const [step, setStep] = useState(Math.min(Math.max(initialReached, 1), TOTAL_STEPS));
  const [reached, setReached] = useState(Math.min(Math.max(initialReached, 1), TOTAL_STEPS));
  const [picks, setPicks] = useState<Record<string, string[]>>(initialPicks);
  const [sibuk, setSibuk] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);
  const [dialog, setDialog] = useState(false);

  const meta: StepMeta[] = useMemo(
    () => [
      ...steps.map((s) => ({ order: s.order, name: s.name, question: s.question })),
      { ...REVIEW_STEP },
    ],
    [steps]
  );

  const aktif = steps.find((s) => s.order === step) ?? null;
  const isReview = step === REVIEW_STEP.order;
  const terpilih = aktif ? picks[aktif.layerCode] ?? [] : [];

  function toggle(code: string) {
    if (!aktif) return;
    setGalat(null);
    setPicks((lama) => {
      const kini = lama[aktif.layerCode] ?? [];
      const baru = kini.includes(code)
        ? kini.filter((c) => c !== code)
        : kini.length >= aktif.maxPick
          ? kini
          : [...kini, code];
      return { ...lama, [aktif.layerCode]: baru };
    });
  }

  /** Menyimpan langkah aktif lalu berpindah. Review tidak punya yang disimpan. */
  async function simpanLalu(tujuan: number) {
    setGalat(null);
    if (aktif) {
      setSibuk(true);
      const err = await onSaveStep(aktif.layerCode, terpilih, Math.max(reached, tujuan));
      setSibuk(false);
      if (err) {
        setGalat(err);
        return false;
      }
    }
    setReached((r) => Math.max(r, tujuan));
    setStep(tujuan);
    return true;
  }

  async function selesaikan() {
    setGalat(null);
    setSibuk(true);
    const err = await onComplete();
    setSibuk(false);
    if (err) {
      setGalat(err);
      return;
    }
    setLayar("selesai");
  }

  if (layar === "intro") {
    return (
      <Kerangka step={null}>
        <IntroScreen
          onStart={() => setLayar("langkah")}
          lanjutkan={Object.values(initialPicks).some((v) => v.length > 0)}
        />
      </Kerangka>
    );
  }

  if (layar === "selesai") {
    return (
      <Kerangka step={null}>
        <DoneScreen />
      </Kerangka>
    );
  }

  const labelLanjut = isReview
    ? "Simpan Career DNA-mu"
    : `Lanjut ke Step ${step + 1}`;
  const bisaLanjut = isReview ? true : terpilih.length > 0;

  return (
    <Kerangka step={step} onSimpan={() => setDialog(true)}>
      <div className="mx-auto flex w-full max-w-[1160px] gap-8 px-0 py-0 lg:px-6 lg:py-8">
        <DnaStepper steps={meta} current={step} reached={reached} onJump={(o) => void simpanLalu(o)} />

        <div className="min-w-0 flex-1 lg:overflow-hidden lg:rounded-2xl lg:border lg:border-slate-200">
          <StepHeaderBar
            steps={meta}
            current={step}
            reached={reached}
            onJump={(o) => void simpanLalu(o)}
          />

          {/* Ruang bawah ekstra di layar sempit: tombolnya menempel di bawah,
              dan tanpa ini kartu terakhir tertutup dan tidak bisa dibuka. */}
          <div className="px-4 pb-28 pt-5 sm:px-6 lg:pb-5">
            {isReview ? (
              <>
                <h1 className="text-[17px] font-bold tracking-tight text-slate-900">
                  {REVIEW_STEP.name}
                </h1>
                <p className="mt-0.5 text-[13px] text-slate-500">
                  Periksa kembali pilihan Kamu sebelumnya
                </p>
                <div className="mt-4">
                  <ReviewList steps={steps} picks={picks} onEdit={(o) => void simpanLalu(o)} />
                </div>
              </>
            ) : aktif ? (
              <>
                <h1 className="text-[17px] font-bold tracking-tight text-slate-900">{aktif.name}</h1>
                <p className="mt-0.5 text-[13px] text-slate-500">
                  {aktif.question} (Maks {aktif.maxPick} pilihan)
                </p>
                <div className="mt-4">
                  <OptionList
                    options={aktif.attributes}
                    selected={terpilih}
                    maxPick={aktif.maxPick}
                    onToggle={toggle}
                  />
                </div>
              </>
            ) : null}

            {galat && (
              <p className="mt-4 rounded-xl bg-red-50 px-4 py-3 text-[12.5px] text-red-700">{galat}</p>
            )}
          </div>

          {/* Tombol utama di atas pada layar sempit, di kanan pada desktop —
              mengikuti kedua mockup. */}
          <div className="sticky bottom-0 flex flex-col gap-2.5 border-t border-slate-200 bg-violet-50/70 px-4 py-4 sm:px-6 lg:flex-row-reverse lg:items-center lg:justify-between lg:bg-white">
            <button
              type="button"
              disabled={!bisaLanjut || sibuk}
              onClick={() => (isReview ? void selesaikan() : void simpanLalu(step + 1))}
              className="inline-flex items-center justify-center gap-2 rounded-full bg-violet-600 px-6 py-3 text-[13.5px] font-semibold text-white transition-colors hover:bg-violet-700 disabled:opacity-50"
            >
              {sibuk ? "Menyimpan…" : labelLanjut}
              <ArrowRight className="size-4" aria-hidden />
            </button>

            {step > 1 ? (
              <button
                type="button"
                disabled={sibuk}
                onClick={() => void simpanLalu(step - 1)}
                className="inline-flex items-center justify-center gap-2 rounded-full py-3 text-[13.5px] font-semibold text-slate-600 transition-colors hover:bg-slate-100 lg:px-5"
              >
                <CornerUpLeft className="size-4" aria-hidden />
                Kembali ke Step {step - 1}
              </button>
            ) : (
              <button
                type="button"
                onClick={() => router.push("/explore")}
                className="hidden items-center justify-center gap-2 rounded-full py-3 text-[13.5px] font-semibold text-slate-600 transition-colors hover:bg-slate-100 lg:inline-flex lg:px-5"
              >
                <X className="size-4" aria-hidden />
                Batalkan
              </button>
            )}
          </div>
        </div>
      </div>

      {dialog && (
        <SaveProgressDialog
          menyimpan={sibuk}
          onCancel={() => setDialog(false)}
          onConfirm={async () => {
            const ok = await simpanLalu(step);
            setDialog(false);
            if (ok) router.push("/explore");
          }}
        />
      )}
    </Kerangka>
  );
}

/**
 * Kerangka bersama: kepala layar ponsel dan breadcrumb desktop.
 *
 * `step` null berarti layar pembuka atau penutup — keduanya tidak punya nomor
 * langkah dan tidak punya tombol Simpan.
 */
function Kerangka({
  step,
  onSimpan,
  children,
}: {
  step: number | null;
  onSimpan?: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen flex-col bg-white">
      {/* Ponsel dan tablet */}
      <header className="sticky top-0 z-20 flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3.5 lg:hidden">
        <Link href="/explore" className="flex items-center gap-3 text-slate-900">
          <ArrowLeft className="size-4.5" aria-hidden />
          <span className="text-[14px] font-bold">Career DNA</span>
        </Link>
        {onSimpan && (
          <button
            type="button"
            onClick={onSimpan}
            className="inline-flex items-center gap-1.5 text-[13px] font-semibold text-violet-600"
          >
            <Save className="size-4" aria-hidden />
            Simpan
          </button>
        )}
      </header>

      {/* Desktop */}
      <nav
        aria-label="Breadcrumb"
        className="hidden border-b border-slate-200 bg-white px-8 py-3.5 lg:block"
      >
        <ol className="mx-auto flex max-w-[1160px] items-center gap-2 text-[13px] text-slate-500">
          <li>
            <Link href="/explore" aria-label="Explore" className="grid place-items-center text-slate-500 hover:text-slate-800">
              <Home className="size-4" aria-hidden />
            </Link>
          </li>
          <ChevronRight className="size-3.5 text-slate-300" aria-hidden />
          <li className={step === null ? "text-slate-800" : ""}>Kenali Career DNA-mu</li>
          {step !== null && (
            <>
              <ChevronRight className="size-3.5 text-slate-300" aria-hidden />
              <li className="font-semibold text-slate-800">
                STEP {step}/{TOTAL_STEPS}
              </li>
            </>
          )}
        </ol>
      </nav>

      <main className="flex-1">{children}</main>
    </div>
  );
}
