/**
 * Skoring minat RIASEC.
 *
 * Alurnya: jawaban Likert 1-5 -> skor per tipe di skala 1-7 (setara skala OI
 * O*NET) -> pemusatan -> korelasi terhadap vektor profesi dari `career_riasec`.
 *
 * Pemusatan itu bukan hiasan. Sebagian orang mencentang 4-5 untuk semua
 * pertanyaan dan sebagian lagi 2-3 untuk semua. Tanpa dikurangi rata-rata
 * dirinya sendiri, yang terukur adalah kemurahan hati mereka mengisi
 * kuesioner, bukan minatnya.
 */

import { RIASEC_ITEMS, type RiasecCode } from "@/data/onboardingQuestions";

export const RIASEC_CODES: RiasecCode[] = ["R", "I", "A", "S", "E", "C"];

export type RiasecVector = Record<RiasecCode, number>;
export type ItemResponses = Record<string, number>; // item id -> 1..5

export type RiasecProfile = {
  scores: RiasecVector;      // skala 1-7, sebanding dengan skor O*NET
  percentages: RiasecVector; // proporsi dari total, untuk ditampilkan
  hollandCode: string;       // tiga huruf tertinggi, mis. "IAC"
  itemsAnswered: number;
};

/** Bonus kecil dari chip bidang/aktivitas bila dipakai sebagai prior. */
export type Priors = Partial<Record<RiasecCode, number>>;

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/**
 * Hitung profil dari jawaban mentah.
 * Tipe tanpa satu pun jawaban jatuh ke titik tengah (4.0), bukan nol —
 * "tidak ditanya" tidak sama dengan "tidak tertarik".
 */
export function computeProfile(responses: ItemResponses, priors: Priors = {}): RiasecProfile {
  const scores = {} as RiasecVector;
  let answered = 0;

  for (const code of RIASEC_CODES) {
    const values = RIASEC_ITEMS
      .filter((it) => it.riasec === code)
      .map((it) => responses[it.id])
      .filter((v): v is number => typeof v === "number");

    answered += values.length;

    if (values.length === 0) {
      scores[code] = 4.0; // netral di skala 1-7
      continue;
    }
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    scores[code] = clamp(1 + (mean - 1) * 1.5 + (priors[code] ?? 0), 1, 7); // 1..5 -> 1..7
  }

  const total = RIASEC_CODES.reduce((sum, c) => sum + scores[c], 0);
  const percentages = {} as RiasecVector;
  for (const code of RIASEC_CODES) {
    percentages[code] = Math.round((scores[code] / total) * 1000) / 10;
  }

  const hollandCode = [...RIASEC_CODES]
    .sort((a, b) => scores[b] - scores[a])
    .slice(0, 3)
    .join("");

  return { scores, percentages, hollandCode, itemsAnswered: answered };
}

/** Kurangi rata-rata vektor itu sendiri. Wajib untuk kedua sisi. */
function center(v: RiasecVector): number[] {
  const arr = RIASEC_CODES.map((c) => v[c]);
  const mean = arr.reduce((a, b) => a + b, 0) / arr.length;
  return arr.map((x) => x - mean);
}

/**
 * Kecocokan minat user dengan sebuah profesi, 0-100.
 * Pada vektor terpusat ini setara korelasi Pearson, dipetakan ke rentang
 * yang enak ditampilkan.
 */
export function interestFit(user: RiasecVector, career: RiasecVector): number {
  const u = center(user);
  const c = center(career);
  const dot = u.reduce((s, x, i) => s + x * c[i], 0);
  const nu = Math.sqrt(u.reduce((s, x) => s + x * x, 0));
  const nc = Math.sqrt(c.reduce((s, x) => s + x * x, 0));
  if (nu === 0 || nc === 0) return 50; // profil datar: tidak ada preferensi
  return Math.round(((dot / (nu * nc) + 1) / 2) * 100);
}

/**
 * Bobot minat vs skill, bergeser sesuai jenjang.
 *
 * Ini yang membuat rekomendasi bekerja untuk siswa termuda. Mereka belum punya
 * satu pun skill di knowledge base, jadi skor CBF selalu nol dan hasilnya acak.
 * Minat adalah satu-satunya sinyal nyata yang mereka punya.
 */
export function weightsFor(educationLevel: string): { interest: number; skill: number } {
  switch (educationLevel) {
    case "SMP":        return { interest: 0.90, skill: 0.10 };
    case "SMA":
    case "SMK":        return { interest: 0.70, skill: 0.30 };
    case "KULIAH":     return { interest: 0.45, skill: 0.55 };
    case "FRESH_GRAD": return { interest: 0.30, skill: 0.70 };
    default:           return { interest: 0.50, skill: 0.50 };
  }
}

/** Skor akhir sebelum filter KBF (pendidikan, gaji, lokasi). */
export function combinedScore(
  interestScore: number,
  skillScore: number,
  educationLevel: string
): number {
  const w = weightsFor(educationLevel);
  return Math.round(interestScore * w.interest + skillScore * w.skill);
}
