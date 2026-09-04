/**
 * Akses data layar Explore.
 *
 * Satu panggilan per baris kartu, bukan satu per kartu: seluruh isi kartu —
 * sub-industri, permintaan pasar, gaji, lama perjalanan, atribut aktivitas —
 * sudah dirakit di view `career_card` (migrasi 0020).
 *
 * Fungsi RPC di sana memakai auth.uid() dan tidak menerima user id, jadi tidak
 * ada cara memanggilnya untuk data orang lain — bahkan kalau frontend salah.
 */

import { supabase } from "@/lib/supabaseClient";

export type CareerCard = {
  career_id: number;
  career_name: string;
  career_description: string | null;
  sub_industry: string | null;
  industry_code: string | null;
  sub_industry_extra: number;
  demand_score: number | null;
  demand_label: string;
  salary_min: number | null;
  salary_max: number | null;
  roadmap_months: number | null;
  activity_attributes: string[] | null;
};

/** Kartu yang membawa skor kecocokan. Hanya ada kalau Career DNA sudah diisi. */
export type ScoredCard = CareerCard & {
  match_score: number | null;
  band_code: string | null;
  band_label: string | null;
  reason?: string | null;
  n_cocok?: number | null;
  relevance?: number | null;
};

export type ExploreState = {
  full_name: string | null;
  has_career: boolean;
  has_dna: boolean;
  career_id: number | null;
  career_name: string | null;
  percent_done: number | null;
  study_label: string | null;
  top_activity: string | null;
};

export type WeeklyQuest = {
  activity_id: number;
  quest_title: string;
  tier_code: string | null;
  tier_emoji: string | null;
  quest_kind: string;
  xp: number;
  est_minutes: number;
  stage_order: number;
};

/**
 * Keadaan layar. Empat tampilan Explore ditentukan dua boolean saja, dan
 * keduanya datang dari sini — jangan menebaknya dari data lain.
 */
export async function getExploreState(): Promise<ExploreState | null> {
  const { data, error } = await supabase.rpc("explore_state").single();
  if (error) return null;
  return data as ExploreState;
}

export async function getTopDemand(limit = 12): Promise<CareerCard[]> {
  const { data } = await supabase.rpc("explore_top_demand", { p_limit: limit });
  return (data as CareerCard[]) ?? [];
}

export async function getByStudy(limit = 12): Promise<ScoredCard[]> {
  const { data } = await supabase.rpc("explore_by_study", { p_limit: limit });
  return (data as ScoredCard[]) ?? [];
}

export async function getByMatch(limit = 12): Promise<ScoredCard[]> {
  const { data } = await supabase.rpc("explore_by_match", { p_limit: limit });
  return (data as ScoredCard[]) ?? [];
}

export async function getByActivity(limit = 12): Promise<ScoredCard[]> {
  const { data } = await supabase.rpc("explore_by_activity", { p_limit: limit });
  return (data as ScoredCard[]) ?? [];
}

export async function getWeeklyQuests(limit = 3): Promise<WeeklyQuest[]> {
  const { data } = await supabase.rpc("explore_weekly_quests", { p_limit: limit });
  return (data as WeeklyQuest[]) ?? [];
}

export async function searchCareerCards(query: string, limit = 20): Promise<CareerCard[]> {
  const { data } = await supabase.rpc("explore_search", { p_query: query, p_limit: limit });
  return (data as CareerCard[]) ?? [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Pemformatan
//
// Database mengirim angka mentah; bentuk tampilannya diputuskan di sini supaya
// satu profesi terbaca sama di mana pun kartunya muncul.
// ─────────────────────────────────────────────────────────────────────────────

/** 5.900.000–9.200.000 → "Rp5,9-9,2Juta". Nilai bulat kehilangan koma nol. */
export function formatSalary(min: number | null, max: number | null): string {
  const juta = (n: number) => {
    const v = n / 1_000_000;
    const s = v >= 10 ? Math.round(v).toString() : v.toFixed(1);
    return s.replace(/\.0$/, "").replace(".", ",");
  };
  if (min == null && max == null) return "Belum ada data gaji";
  if (min == null) return `Rp${juta(max as number)}Juta`;
  if (max == null) return `Rp${juta(min)}Juta`;
  if (min === max) return `Rp${juta(min)}Juta`;
  return `Rp${juta(min)}-${juta(max)}Juta`;
}

/**
 * 60 bulan → "5 tahun", 66 → "5-6 tahun", 18 → "1,5 tahun".
 *
 * Rentang dipakai saat angkanya jatuh di tengah tahun, karena "5,5 tahun"
 * terbaca lebih presisi daripada yang pantas untuk sebuah estimasi.
 */
export function formatDuration(months: number | null): string {
  if (!months || months <= 0) return "Durasi belum dihitung";
  if (months < 12) return `${months} bulan`;
  const years = months / 12;
  if (Number.isInteger(years)) return `${years} tahun`;
  const low = Math.floor(years);
  const high = Math.ceil(years);
  return high - low === 1 && months % 12 >= 4 && months % 12 <= 8
    ? `${low},5 tahun`
    : `${low}-${high} tahun`;
}

/** Warna chip band mengikuti tiga pita di tabel match_score_bands. */
export function bandTone(bandCode: string | null): { bg: string; text: string } {
  switch (bandCode) {
    case "HIGHLY_RECOMMENDED":
      return { bg: "bg-emerald-100", text: "text-emerald-700" };
    case "RECOMMENDED":
      return { bg: "bg-sky-100", text: "text-sky-700" };
    default:
      return { bg: "bg-amber-100", text: "text-amber-700" };
  }
}
