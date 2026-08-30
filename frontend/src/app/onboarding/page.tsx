"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { GraduationCap, BookMarked, AlertCircle, ArrowRight } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import AuthBrandHeader from "@/components/AuthBrandHeader";
import ProgressHeader from "@/components/onboarding/ProgressHeader";
import ChipGroup, { type ChipOption } from "@/components/onboarding/ChipGroup";
import TipCallout from "@/components/onboarding/TipCallout";
import StepFooter from "@/components/onboarding/StepFooter";
import ReviewCard from "@/components/onboarding/ReviewCard";
import StartScreen from "@/components/onboarding/StartScreen";
import StepSidebar, { type StepMeta } from "@/components/onboarding/StepSidebar";
import OnboardingIllustration from "@/components/onboarding/OnboardingIllustration";
import StudyProgramCombobox, {
  type StudyProgramValue,
} from "@/components/onboarding/StudyProgramCombobox";
import {
  getEducationLevels,
  getStepRules,
  getSmkPrograms,
  ruleFor,
  majorKindForLevel,
  saveEducation,
  type EducationLevel,
  type StepRule,
  type SmkProgram,
  type LevelCode,
  type GraduationStatus,
} from "@/lib/education";

const TOTAL_STEPS = 3;

/** Judul langkah dipakai dua kali: di kartu progres dan di stepper desktop. */
const STEPS: StepMeta[] = [
  { title: "Latar belakang pendidikan", description: "Informasi riwayat pendidikanmu" },
  { title: "Status Kelulusan", description: "Status kelulusan dari jenjang pendidikan terakhir" },
  { title: "Review dan selesai!", description: "Rangkuman latar belakang pendidikanmu" },
];

const STATUS_OPTIONS: ChipOption[] = [
  { value: "sedang_studi", label: "Sedang menempuh studi" },
  { value: "sudah_lulus", label: "Sudah lulus" },
];

/** Rentang kelas per jenjang sekolah. SMP 7–9, SMA/SMK 10–12. */
function gradeOptions(level: LevelCode | null): ChipOption[] {
  const range = level === "SMP" ? [7, 8, 9] : [10, 11, 12];
  return range.map((n) => ({ value: String(n), label: `Kelas ${n}` }));
}

/** Semester 1–8 plus "Semester Akhir" untuk yang sedang menunggu wisuda. */
const SEMESTER_OPTIONS: ChipOption[] = [
  ...Array.from({ length: 8 }, (_, i) => ({
    value: String(i + 1),
    label: `Semester ${i + 1}`,
  })),
  { value: "akhir", label: "Semester Akhir" },
];

export default function OnboardingPage() {
  const router = useRouter();

  const [userId, setUserId] = useState<string | null>(null);
  const [levels, setLevels] = useState<EducationLevel[]>([]);
  const [rules, setRules] = useState<StepRule[]>([]);
  const [smk, setSmk] = useState<SmkProgram[]>([]);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  const [step, setStep] = useState<0 | 1 | 2 | 3 | 4>(0);
  const [level, setLevel] = useState<LevelCode | null>(null);
  const [status, setStatus] = useState<GraduationStatus | null>(null);
  const [grade, setGrade] = useState<string | null>(null);
  const [semester, setSemester] = useState<string | null>(null);
  const [smkConcentrationId, setSmkConcentrationId] = useState<number | null>(null);
  const [studyProgram, setStudyProgram] = useState<StudyProgramValue>({
    id: null,
    label: null,
    custom: false,
  });
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  // ── muat sesi + data referensi ────────────────────────────────────────────
  useEffect(() => {
    let alive = true;
    (async () => {
      const { data } = await supabase.auth.getSession();
      if (!alive) return;
      if (!data.session) {
        router.replace("/login?next=/onboarding");
        return;
      }
      setUserId(data.session.user.id);

      try {
        const [lv, rl, sk] = await Promise.all([
          getEducationLevels(),
          getStepRules(),
          getSmkPrograms(),
        ]);
        if (!alive) return;
        setLevels(lv);
        setRules(rl);
        setSmk(sk);
      } catch {
        if (!alive) return;
        // Paling sering karena migration 0005 belum dijalankan. Katakan apa
        // adanya, jangan tampilkan layar kosong tanpa penjelasan.
        setLoadError(
          "Data pendidikan belum tersedia di server. Pastikan migration terbaru sudah dijalankan."
        );
      } finally {
        if (alive) setReady(true);
      }
    })();
    return () => {
      alive = false;
    };
  }, [router]);

  const levelOptions: ChipOption[] = useMemo(
    () => levels.map((l) => ({ value: l.code, label: l.level_name })),
    [levels]
  );

  const rule = ruleFor(rules, level, status);
  const majorKind = majorKindForLevel(level);

  /**
   * Ganti jenjang berarti jawaban turunannya tidak berlaku lagi.
   *
   * Ini bukan kerapian belaka: constraint di database menolak baris seperti
   * "SMA punya jurusan SMK". Kalau sisa jawaban lama tidak dibersihkan, user
   * akan melihat error simpan yang tidak ada hubungannya dengan apa yang baru
   * saja dia klik.
   */
  const changeLevel = useCallback((next: string) => {
    setLevel(next as LevelCode);
    setSmkConcentrationId(null);
    setStudyProgram({ id: null, label: null, custom: false });
    setGrade(null);
    setSemester(null);
  }, []);

  const changeStatus = useCallback((next: string) => {
    setStatus(next as GraduationStatus);
    setGrade(null);
    setSemester(null);
  }, []);

  // ── syarat lanjut per langkah ─────────────────────────────────────────────
  const step1Complete =
    level !== null &&
    (majorKind === null ||
      (majorKind === "smk_concentration" && smkConcentrationId !== null) ||
      (majorKind === "study_program" && (studyProgram.id !== null || !!studyProgram.label)));

  const step2Complete =
    status !== null &&
    (!rule?.needs_grade || grade !== null) &&
    (!rule?.needs_semester || semester !== null);

  const smkOptions: ChipOption[] = useMemo(
    () =>
      smk.flatMap((p) =>
        p.concentrations.map((c) => ({ value: String(c.id), label: c.name_id }))
      ),
    [smk]
  );

  const labelOf = (code: LevelCode | null) =>
    levels.find((l) => l.code === code)?.level_name ?? "—";

  /**
   * Nilai kolom "Jurusan / Program Studi" di layar review.
   *
   * SMP dan SMA tidak punya jurusan, dan desain menampilkan "Umum" di sana —
   * bukan baris yang dihilangkan. Barisnya selalu ada supaya grid dua kolom di
   * desktop tetap seimbang dan user melihat semua yang tersimpan tentang dia,
   * termasuk yang kosong.
   */
  const majorLabel = () => {
    if (majorKind === "smk_concentration") {
      const c = smk
        .flatMap((p) => p.concentrations)
        .find((x) => x.id === smkConcentrationId);
      return c?.name_id ?? "-";
    }
    if (majorKind === "study_program") {
      return studyProgram.label ?? "-";
    }
    return "Umum";
  };

  const isSchoolLevel = level === "SMP" || level === "SMA" || level === "SMK";

  /** Baris kedua kartu status: Kelas untuk siswa, Semester untuk mahasiswa. */
  const periodRow = () => {
    if (isSchoolLevel) {
      return { label: "Kelas saat ini", value: grade ? `Kelas ${grade}` : "-" };
    }
    if (!semester) return { label: "Semester saat ini", value: "-" };
    return {
      label: "Semester saat ini",
      value: semester === "akhir" ? "Semester Akhir" : `Semester ${semester}`,
    };
  };

  const handleSave = async () => {
    if (!userId) return;
    setSaving(true);
    setSaveError(null);
    try {
      await saveEducation(userId, {
        level: level as LevelCode,
        status: status as GraduationStatus,
        gradeLevel: grade ? Number(grade) : null,
        semester: semester && semester !== "akhir" ? Number(semester) : null,
        isFinalSemester: semester === "akhir",
        smkConcentrationId,
        studyProgramId: studyProgram.id,
        studyProgramCustom: studyProgram.custom ? studyProgram.label : null,
      });
      setStep(4);
    } catch (err) {
      setSaveError(
        err instanceof Error ? err.message : "Gagal menyimpan. Coba lagi sebentar."
      );
    } finally {
      setSaving(false);
    }
  };

  // ── render ────────────────────────────────────────────────────────────────
  if (!ready) {
    return (
      <div className="flex flex-1 items-center justify-center bg-white">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-slate-200 border-t-[#7033FF] motion-reduce:animate-none" />
      </div>
    );
  }

  if (loadError) {
    return (
      <div className="flex flex-1 flex-col bg-white">
        <AuthBrandHeader />
        <div className="mx-auto w-full max-w-[560px] px-5">
          <div className="flex gap-3 rounded-xl bg-red-50 px-5 py-4 text-sm text-[#E54B4F]">
            <AlertCircle className="mt-0.5 h-5 w-5 shrink-0" />
            <p>{loadError}</p>
          </div>
        </div>
      </div>
    );
  }

  if (step === 4) {
    return (
      <div className="flex flex-1 flex-col bg-white lg:bg-[#CBD5E1]">
        <AuthBrandHeader />

        <div className="mx-auto flex w-full max-w-[560px] flex-1 flex-col px-4 sm:px-6 lg:mb-12 lg:max-w-[600px] lg:flex-none lg:px-0">
          <div className="flex flex-1 flex-col lg:flex-none lg:rounded-2xl lg:bg-white lg:p-8 lg:shadow-lg">
            <div className="flex flex-1 flex-col items-center justify-center py-10 text-center lg:flex-none lg:py-0">
              <OnboardingIllustration
                name="done"
                className="h-auto w-[260px] sm:w-[300px] lg:w-[320px]"
                priority
              />
              <h1 className="mt-8 text-xl font-bold text-slate-900 sm:text-2xl">
                Yay! Data kamu tersimpan 🎉
              </h1>
              <p className="mx-auto mt-3 max-w-[420px] text-sm leading-relaxed text-[#525252]">
                Terima kasih! Informasi yang Kamu berikan akan membantu Navika dalam membuat
                roadmap journey profesi impian Kamu.
              </p>
            </div>

            {/* Di desktop tombolnya menyatu di dalam kartu, bukan bilah footer
                terpisah seperti langkah 1-3. */}
            <div className="sticky bottom-0 -mx-4 bg-[#F1EBFF] px-4 py-4 sm:static sm:mx-0 sm:rounded-xl sm:px-6 lg:mt-7 lg:bg-transparent lg:p-0">
              {/* Hanya di desktop tombolnya menyempit dan terpusat (C-01); di
                  mobile dan tablet ia melebar penuh di dalam bilah lilac. */}
              <button
                type="button"
                onClick={() => router.push("/dashboard")}
                className="flex w-full cursor-pointer items-center justify-center gap-2 rounded-full bg-[#7033FF] px-6 py-3.5 text-sm font-semibold text-white transition-colors hover:bg-[#5f27e6] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7033FF] lg:mx-auto lg:w-auto lg:min-w-[320px] lg:px-8"
              >
                Lanjut ke Dashboard
                <ArrowRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const illustration = step === 1 ? "step1" : step === 2 ? "step2" : "step3";

  return (
    // Latar abu-abu hanya dari `lg`: di situ desain memakai kartu melayang.
    // Di mobile dan tablet halamannya putih penuh tanpa kartu.
    <div className="flex flex-1 flex-col bg-white lg:bg-[#CBD5E1]">
      <AuthBrandHeader />

      {step === 0 ? (
        <StartScreen onStart={() => setStep(1)} />
      ) : (
        <div className="mx-auto flex w-full max-w-[560px] flex-1 flex-col px-4 sm:max-w-[750px] sm:px-6 lg:mb-12 lg:max-w-[1120px] lg:px-0">
          <div className="flex flex-1 flex-col lg:grid lg:flex-none lg:grid-cols-[minmax(0,420px)_minmax(0,1fr)] lg:overflow-hidden lg:rounded-2xl lg:bg-white lg:shadow-lg">
            <StepSidebar step={step} steps={STEPS} illustration={illustration} />

            <div className="flex flex-1 flex-col lg:min-h-[620px]">
              <ProgressHeader
                step={step}
                totalSteps={TOTAL_STEPS}
                title={STEPS[step - 1].title}
              />

              <div className="flex-1 space-y-8 py-7 lg:px-6">
                {step === 1 && (
                  <>
                    <ChipGroup
                      name="jenjang"
                      legend="Pendidikan terakhir"
                      description="Jenjang pendidikan terakhir atau saat ini."
                      options={levelOptions}
                      value={level}
                      onChange={changeLevel}
                    />

                    {majorKind === "smk_concentration" && (
                      <div className="border-t border-slate-200 pt-7">
                        <ChipGroup
                          name="jurusan"
                          legend="Jurusan"
                          description="Pilih konsentrasi keahlian yang Kamu ambil."
                          options={smkOptions}
                          value={smkConcentrationId ? String(smkConcentrationId) : null}
                          onChange={(v) => setSmkConcentrationId(Number(v))}
                        />
                      </div>
                    )}

                    {majorKind === "study_program" && (
                      <div className="border-t border-slate-200 pt-7">
                        <h2 className="text-lg font-bold text-slate-900 sm:text-xl">
                          Program studi
                        </h2>
                        <p className="mt-1 text-sm text-[#525252]">
                          Pilih program studi yang Kamu ambil
                        </p>
                        <div className="mt-4">
                          <StudyProgramCombobox value={studyProgram} onChange={setStudyProgram} />
                        </div>
                      </div>
                    )}
                  </>
                )}

                {step === 2 && (
                  <>
                    <ChipGroup
                      name="status"
                      legend="Status Saat Ini"
                      description="Apakah Kamu sudah lulus dari jenjang ini?"
                      options={STATUS_OPTIONS}
                      value={status}
                      onChange={changeStatus}
                    />

                    {rule?.needs_grade && (
                      <div className="border-t border-slate-200 pt-7">
                        <ChipGroup
                          name="kelas"
                          legend="Kelas saat ini"
                          description="Saat ini ada di kelas berapa?"
                          options={gradeOptions(level)}
                          value={grade}
                          onChange={setGrade}
                        />
                      </div>
                    )}

                    {rule?.needs_semester && (
                      <div className="space-y-4 border-t border-slate-200 pt-7">
                        <ChipGroup
                          name="semester"
                          legend="Semester saat ini"
                          description="Pilih semester yang sedang kamu jalani."
                          options={SEMESTER_OPTIONS}
                          value={semester}
                          onChange={setSemester}
                        />
                        <TipCallout>
                          <strong className="font-bold">Tips:</strong> Sudah di tahap akhir kuliah
                          menunggu wisuda? Pilih{" "}
                          <strong className="font-bold">&ldquo;Semester Akhir&rdquo;</strong>.
                        </TipCallout>
                      </div>
                    )}
                  </>
                )}

                {step === 3 && (
                  <div className="space-y-5">
                    <ReviewCard
                      icon={BookMarked}
                      title="Pendidikan terakhir"
                      subtitle="Informasi riwayat pendidikanmu"
                      rows={[
                        { label: "Jenjang Pendidikan", value: labelOf(level) },
                        { label: "Jurusan / Program Studi", value: majorLabel() },
                      ]}
                    />

                    <ReviewCard
                      icon={GraduationCap}
                      title="Status Kelulusan"
                      subtitle="Status kelulusan dari jenjang pendidikan terakhir"
                      rows={[
                        {
                          label: "Status Saat Ini",
                          value:
                            status === "sudah_lulus" ? "Sudah lulus" : "Sedang menempuh studi",
                        },
                        periodRow(),
                      ]}
                    />

                    {saveError && (
                      <div className="flex gap-3 rounded-xl bg-red-50 px-5 py-4 text-sm text-[#E54B4F]">
                        <AlertCircle className="mt-0.5 h-5 w-5 shrink-0" />
                        <p>{saveError}</p>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {step === 1 && (
                <StepFooter
                  primaryLabel="Lanjut ke Step 2"
                  onPrimary={() => setStep(2)}
                  primaryDisabled={!step1Complete}
                />
              )}
              {step === 2 && (
                <StepFooter
                  primaryLabel="Lanjut ke Step 3"
                  onPrimary={() => setStep(3)}
                  primaryDisabled={!step2Complete}
                  secondaryLabel="Kembali ke Step 1"
                  onSecondary={() => setStep(1)}
                />
              )}
              {step === 3 && (
                <StepFooter
                  primaryLabel="Simpan"
                  primaryIcon="check"
                  onPrimary={handleSave}
                  primaryBusy={saving}
                  secondaryLabel="Kembali ke Step 2"
                  onSecondary={() => setStep(2)}
                />
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
