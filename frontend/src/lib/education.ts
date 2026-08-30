/**
 * Onboarding pendidikan — 3 langkah sesuai desain tim desain.
 *
 * Aturan percabangannya TIDAK dihardcode di sini. Matriks 20 kombinasi
 * (10 jenjang x 2 status kelulusan) hidup di tabel `education_step_rules`,
 * jadi kalau desainnya berubah cukup ubah barisnya, bukan kodenya.
 */

import { supabase } from "@/lib/supabaseClient";

export type LevelCode = "SMP" | "SMA" | "SMK" | "D1" | "D2" | "D3" | "D4" | "S1" | "S2" | "S3";
export type GraduationStatus = "sedang_studi" | "sudah_lulus";
export type MajorKind = "smk_concentration" | "study_program" | null;

export type EducationLevel = {
  code: LevelCode;
  level_name: string;
  description_id: string | null;
  order_rank: number;
};

export type StepRule = {
  level_code: LevelCode;
  graduation_status: GraduationStatus;
  major_kind: MajorKind;
  needs_grade: boolean;
  needs_semester: boolean;
};

export type SmkProgram = {
  code: string;
  name_id: string;
  concentrations: { id: number; name_id: string }[];
};

export type Profile = {
  user_id: string;
  full_name: string | null;
  date_of_birth: string | null;
  city: string | null;
  education_level_code: LevelCode | null;
  graduation_status: GraduationStatus | null;
  grade_level: number | null;
  semester: number | null;
  is_final_semester: boolean;
  smk_concentration_id: number | null;
  study_program_id: number | null;
  study_program_custom: string | null;
  target_graduation_year: number | null;
  onboarding_completed_at: string | null;
};

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — jenjang & jurusan
// ─────────────────────────────────────────────────────────────────────────────

export async function getEducationLevels(): Promise<EducationLevel[]> {
  const { data, error } = await supabase
    .from("education_levels")
    .select("code, level_name, description_id, order_rank")
    .order("order_rank")
    .order("code");
  if (error) throw error;
  return (data ?? []) as EducationLevel[];
}

/** Seluruh matriks percabangan. Ambil sekali, simpan di state onboarding. */
export async function getStepRules(): Promise<StepRule[]> {
  const { data, error } = await supabase
    .from("education_step_rules")
    .select("level_code, graduation_status, major_kind, needs_grade, needs_semester");
  if (error) throw error;
  return (data ?? []) as StepRule[];
}

/** Field mana yang harus muncul untuk kombinasi jenjang + status ini. */
export function ruleFor(
  rules: StepRule[],
  level: LevelCode | null,
  status: GraduationStatus | null
): StepRule | null {
  if (!level || !status) return null;
  return rules.find((r) => r.level_code === level && r.graduation_status === status) ?? null;
}

/** Jurusan mana yang ditanyakan di Step 1 — sebelum status kelulusan diketahui. */
export function majorKindForLevel(level: LevelCode | null): MajorKind {
  if (!level) return null;
  if (level === "SMP" || level === "SMA") return null;
  if (level === "SMK") return "smk_concentration";
  return "study_program";
}

/** 50 Program Keahlian SMK beserta konsentrasinya, siap jadi dropdown bergrup. */
export async function getSmkPrograms(): Promise<SmkProgram[]> {
  const [progs, cons] = await Promise.all([
    supabase.from("smk_expertise_programs").select("code, name_id, display_order").order("display_order"),
    supabase.from("smk_concentrations").select("id, program_code, name_id, display_order").order("display_order"),
  ]);
  if (progs.error) throw progs.error;
  if (cons.error) throw cons.error;

  const byProgram = new Map<string, { id: number; name_id: string }[]>();
  for (const c of cons.data ?? []) {
    const list = byProgram.get(c.program_code as string) ?? [];
    list.push({ id: c.id as number, name_id: c.name_id as string });
    byProgram.set(c.program_code as string, list);
  }
  return (progs.data ?? []).map((p) => ({
    code: p.code as string,
    name_id: p.name_id as string,
    concentrations: byProgram.get(p.code as string) ?? [],
  }));
}

export type StudyProgram = { id: number; name_id: string; rumpun: string[] };

/**
 * Autocomplete program studi. Kalau tidak ketemu, user boleh mengetik sendiri —
 * simpan lewat `study_program_custom`, bukan dipaksa memilih yang mendekati.
 *
 * Satu prodi bisa berada di lebih dari satu rumpun ("Ilmu Keolahragaan" ada di
 * Ilmu Kesehatan sekaligus Ilmu Olahraga), jadi `rumpun` berupa array.
 */
export async function searchStudyPrograms(query: string, limit = 20): Promise<StudyProgram[]> {
  let q = supabase
    .from("study_programs")
    .select("id, name_id, study_program_rumpun(rumpun_code, study_rumpun(name_id))")
    .limit(limit);
  if (query.trim()) q = q.ilike("name_id", `%${query.trim()}%`);
  const { data, error } = await q.order("name_id");
  if (error) throw error;

  type Row = {
    id: number;
    name_id: string;
    study_program_rumpun: { study_rumpun: { name_id: string } | null }[] | null;
  };
  return ((data ?? []) as unknown as Row[]).map((r) => ({
    id: r.id,
    name_id: r.name_id,
    rumpun: (r.study_program_rumpun ?? [])
      .map((x) => x.study_rumpun?.name_id)
      .filter((v): v is string => Boolean(v)),
  }));
}

/** 12 rumpun, untuk filter atau pengelompokan di dropdown. */
export async function getStudyRumpun() {
  const { data, error } = await supabase
    .from("study_rumpun")
    .select("code, name_id, display_order")
    .order("display_order");
  if (error) throw error;
  return (data ?? []) as { code: string; name_id: string; display_order: number }[];
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 & 3 — simpan
// ─────────────────────────────────────────────────────────────────────────────

export async function getProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle<Profile>();
  if (error) throw error;
  return data;
}

export type EducationInput = {
  level: LevelCode;
  status: GraduationStatus;
  gradeLevel?: number | null;
  semester?: number | null;
  isFinalSemester?: boolean;
  smkConcentrationId?: number | null;
  studyProgramId?: number | null;
  studyProgramCustom?: string | null;
};

/**
 * Simpan Step 1-3 sekaligus.
 *
 * Field yang tidak berlaku sengaja di-NULL-kan, bukan dibiarkan apa adanya —
 * kalau user mundur dan mengganti jenjang dari SMK ke SMA, jurusan SMK-nya
 * harus ikut hilang. Tanpa ini, CHECK constraint di database akan menolak
 * simpannya dan user melihat error yang tidak dia mengerti.
 */
export async function saveEducation(userId: string, input: EducationInput): Promise<void> {
  const kind = majorKindForLevel(input.level);
  const isSchool = input.level === "SMP" || input.level === "SMA" || input.level === "SMK";
  const studying = input.status === "sedang_studi";

  const payload = {
    education_level_code: input.level,
    graduation_status: input.status,
    grade_level: isSchool && studying ? input.gradeLevel ?? null : null,
    semester: !isSchool && studying ? input.semester ?? null : null,
    is_final_semester: !isSchool && studying ? input.isFinalSemester ?? false : false,
    smk_concentration_id: kind === "smk_concentration" ? input.smkConcentrationId ?? null : null,
    study_program_id: kind === "study_program" ? input.studyProgramId ?? null : null,
    study_program_custom:
      kind === "study_program" && !input.studyProgramId
        ? input.studyProgramCustom?.trim() || null
        : null,
    onboarding_completed_at: new Date().toISOString(),
  };

  const { error } = await supabase.from("profiles").update(payload).eq("user_id", userId);
  if (error) throw error;
}

/** Ringkasan untuk layar Review (Step 3). */
export async function getEducationSummary(userId: string) {
  const { data, error } = await supabase
    .from("profiles")
    .select(
      "education_level_code, graduation_status, grade_level, semester, is_final_semester, " +
        "study_program_custom, " +
        "education_levels(level_name), " +
        "smk_concentrations(name_id), " +
        "study_programs(name_id)"
    )
    .eq("user_id", userId)
    .maybeSingle();
  if (error) throw error;
  return data;
}
