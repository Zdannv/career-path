/**
 * Akses data layar Detail Profesi, Detail Kategori, dan Pencarian.
 *
 * Satu fungsi per tab, mengikuti pembagian RPC di migrasi 0029 dan 0030: tab
 * kedua dan ketiga baru diminta saat pengguna menyentuhnya, jadi membuka satu
 * profesi tidak menarik 8 hard skill + 10 tools + 6 lisensi yang belum tentu
 * dilihat.
 *
 * Semua RPC memakai auth.uid() di dalam database dan tidak menerima user id,
 * jadi tidak ada cara memanggilnya untuk data orang lain.
 */

import { supabase } from "@/lib/supabaseClient";

// ─────────────────────────────────────────────────────────────────────────────
// Bentuk data
// ─────────────────────────────────────────────────────────────────────────────

export type Nada = "cocok" | "belum";

export type Alasan = { nada: Nada; teks: string };

export type SubIndustri = { code: string; nama: string; industry_code: string | null };

export type CareerDetail = {
  career_id: number;
  career_name: string;
  career_description: string | null;
  family_code: string | null;
  family_name: string | null;
  match_score: number | null;
  band_code: string | null;
  band_label: string | null;
  reasons: Alasan[];
  demand_score: number | null;
  demand_label: string;
  growth_pct: number | null;
  salary_min: number | null;
  salary_max: number | null;
  sub_industries: SubIndustri[];
  n_sub_industri: number;
  roadmap_months: number | null;
  posisi_sekarang: string | null;
  percent_done: number | null;
  min_education_rank: number;
  min_education_label: string | null;
  ai_resilience: number | null;
  ai_label: string | null;
  ai_penjelasan: string | null;
  is_pilihan: boolean;
};

export type BarisPendidikan = { jenjang: string; catatan: string };
export type SoftSkill = { layer: "ACTIVITY" | "SKILL"; nama: string; deskripsi: string };
export type HardSkill = { kode: string; nama: string; deskripsi: string };
export type Tool = {
  kode: string;
  nama: string;
  deskripsi: string;
  contoh: string | null;
  fase: FaseKode;
};
export type Lisensi = {
  kode: string;
  nama: string;
  penerbit: string;
  sifat: "WAJIB" | "PROFESI" | "TAMBAHAN";
  deskripsi: string;
};

export type FaseKode = "MANDIRI" | "MAGANG" | "KERJA";

export type CareerCompetency = {
  pendidikan: BarisPendidikan[];
  soft_skill: SoftSkill[];
  hard_skill: HardSkill[];
  tools: Tool[];
  lisensi: Lisensi[];
};

export type PitaGaji = {
  kode: string;
  tingkat: string;
  pengalaman: string;
  salary_min: number;
  salary_max: number;
};

export type CareerInsight = {
  gaji: PitaGaji[];
  ai_resilience: number | null;
  ai_label: string | null;
  ai_penjelasan: string | null;
  sumber_gaji: string;
};

export type FaseTools = {
  fase: FaseKode;
  fase_nama: string;
  fase_subtitle: string;
  isi: { nama: string; deskripsi: string; contoh: string | null }[];
};

export type SkillGap = {
  hard_skill: { nama: string; deskripsi: string }[];
  soft_sesuai: Partial<Record<"ACTIVITY" | "SKILL", string[]>>;
  soft_kembangkan: Partial<Record<"ACTIVITY" | "SKILL", string[]>>;
  tools: FaseTools[];
  has_dna: boolean;
};

export type KelompokAtribut = { layer: string; judul: string; isi: string[] };

export type FamilyDetail = {
  family_code: string;
  family_name: string;
  description_id: string;
  n_profesi: number;
  match_score: number | null;
  band_code: string | null;
  band_label: string | null;
  salary_min: number | null;
  salary_max: number | null;
  n_sub_industri: number;
  growth_pct: number | null;
  demand_label: string;
  atribut: KelompokAtribut[];
  pendidikan: BarisPendidikan[];
};

export type KartuProfesi = {
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
  match_score: number | null;
  band_code: string | null;
  skill_chips?: string[];
  total?: number;
};

export type SaranCari = {
  career_id: number;
  career_name: string;
  family_code: string | null;
  sub_industries: string[];
  extra: number;
  is_populer: boolean;
};

export type OpsiFilter = {
  industri: { code: string; nama: string; n_profesi: number }[];
  jenjang: { code: string; nama: string; rank_max: number }[];
  keahlian: { code: string; nama: string }[];
  gaji_min: number;
  gaji_max: number;
};

export type Filter = {
  query?: string;
  industries?: string[];
  salaryMin?: number | null;
  salaryMax?: number | null;
  rankMax?: number | null;
  skills?: string[];
};

// ─────────────────────────────────────────────────────────────────────────────
// Panggilan
// ─────────────────────────────────────────────────────────────────────────────

export async function getCareerDetail(id: number): Promise<CareerDetail | null> {
  const { data, error } = await supabase.rpc("career_detail", { p_career_id: id }).maybeSingle();
  if (error || !data) return null;
  return data as CareerDetail;
}

export async function getCareerCompetency(id: number): Promise<CareerCompetency | null> {
  const { data, error } = await supabase
    .rpc("career_competency", { p_career_id: id })
    .maybeSingle();
  if (error || !data) return null;
  return data as CareerCompetency;
}

export async function getCareerInsight(id: number): Promise<CareerInsight | null> {
  const { data, error } = await supabase.rpc("career_insight", { p_career_id: id }).maybeSingle();
  if (error || !data) return null;
  return data as CareerInsight;
}

export async function getSkillGap(id: number): Promise<SkillGap | null> {
  const { data, error } = await supabase
    .rpc("career_skill_gap", { p_career_id: id })
    .maybeSingle();
  if (error || !data) return null;
  return data as SkillGap;
}

export async function getFamilyDetail(code: string): Promise<FamilyDetail | null> {
  const { data, error } = await supabase
    .rpc("family_detail", { p_family_code: code })
    .maybeSingle();
  if (error || !data) return null;
  return data as FamilyDetail;
}

export async function getFamilyCareers(
  code: string,
  subIndustry: string | null = null,
  limit = 50,
): Promise<KartuProfesi[]> {
  const { data } = await supabase.rpc("family_careers", {
    p_family_code: code,
    p_sub_industry: subIndustry,
    p_limit: limit,
  });
  return (data as KartuProfesi[]) ?? [];
}

export async function getFamilySubIndustries(
  code: string,
): Promise<{ code: string; nama: string; n_profesi: number }[]> {
  const { data } = await supabase.rpc("family_sub_industries", { p_family_code: code });
  return (data as { code: string; nama: string; n_profesi: number }[]) ?? [];
}

export async function getSearchSuggest(query: string, limit = 8): Promise<SaranCari[]> {
  const { data } = await supabase.rpc("search_suggest", {
    p_query: query.trim() === "" ? null : query,
    p_limit: limit,
  });
  return (data as SaranCari[]) ?? [];
}

export async function getFilterOptions(): Promise<OpsiFilter | null> {
  const { data, error } = await supabase.rpc("search_filter_options").maybeSingle();
  if (error || !data) return null;
  return data as OpsiFilter;
}

function argFilter(f: Filter) {
  return {
    p_query: f.query?.trim() ? f.query.trim() : null,
    p_industries: f.industries?.length ? f.industries : null,
    p_salary_min: f.salaryMin ?? null,
    p_salary_max: f.salaryMax ?? null,
    p_rank_max: f.rankMax ?? null,
    p_skills: f.skills?.length ? f.skills : null,
  };
}

export async function searchCareers(f: Filter, limit = 20, offset = 0): Promise<KartuProfesi[]> {
  const { data } = await supabase.rpc("search_careers", {
    ...argFilter(f),
    p_limit: limit,
    p_offset: offset,
  });
  return (data as KartuProfesi[]) ?? [];
}

export async function countCareers(f: Filter): Promise<number> {
  const { data } = await supabase.rpc("search_count", argFilter(f));
  return Number(data ?? 0);
}

/** Memulai roadmap profesi ini — tombol "Pilih Profesi ini". */
export async function pilihProfesi(id: number): Promise<{ ok: boolean; pesan?: string }> {
  const { error } = await supabase.rpc("start_roadmap", { p_career_id: id });
  // Pesan dari database berbentuk "start_roadmap: <kalimat>"; nama fungsinya
  // tidak perlu dibaca pengguna.
  return error ? { ok: false, pesan: error.message.replace(/^start_roadmap:\s*/, "") } : { ok: true };
}

export type KunciProfesi = { career_id: number; career_name: string; terkunci: boolean };

/**
 * Profesi pilihan dan apakah sudah terkunci (0037).
 *
 * Untuk MVP, profesi tidak bisa diganti setelah ada progres — quest diambil,
 * item Journey ditandai. Database yang menolak; ini hanya supaya tombolnya
 * tidak menawarkan sesuatu yang pasti gagal.
 */
export async function ambilKunciProfesi(): Promise<KunciProfesi | null> {
  const { data, error } = await supabase.rpc("profesi_terkunci").maybeSingle();
  if (error) return null;
  return (data as KunciProfesi) ?? null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pemformatan khusus layar detail
// ─────────────────────────────────────────────────────────────────────────────

/** 6.800.000–12.000.000 → "Rp 6,8-12 juta". Bentuk panjang, dipakai di judul. */
export function gajiPanjang(min: number | null, max: number | null): string {
  const juta = (n: number) => {
    const v = n / 1_000_000;
    const s = v >= 10 ? Math.round(v).toString() : v.toFixed(1);
    return s.replace(/\.0$/, "").replace(".", ",");
  };
  if (min == null && max == null) return "Belum ada data gaji";
  if (min == null) return `Rp ${juta(max as number)} juta`;
  if (max == null) return `Rp ${juta(min)} juta`;
  return `Rp ${juta(min)}-${juta(max)} juta`;
}

/** "Rp 5,5-10,5 Juta" — bentuk yang dipakai kartu di daftar. */
export function gajiKartu(min: number | null, max: number | null): string {
  return gajiPanjang(min, max).replace(" juta", " Juta");
}

export function labelBand(band: string | null): string {
  switch (band) {
    case "HIGHLY_RECOMMENDED":
      return "Sangat Direkomendasikan";
    case "RECOMMENDED":
      return "Direkomendasikan";
    case "EXPLORE":
      return "Belum Direkomendasikan";
    default:
      return "Belum dinilai";
  }
}

/** Tiga pita Ketahanan AI punya warnanya sendiri, terpisah dari band kecocokan. */
export function nadaKetahanan(skor: number | null): {
  bg: string;
  text: string;
  chipBg: string;
  chipText: string;
} {
  if (skor == null) return { bg: "bg-slate-50", text: "text-slate-700", chipBg: "bg-slate-200", chipText: "text-slate-700" };
  if (skor >= 70)
    return { bg: "bg-emerald-50", text: "text-violet-700", chipBg: "bg-emerald-200", chipText: "text-emerald-900" };
  if (skor >= 50)
    return { bg: "bg-amber-50", text: "text-violet-700", chipBg: "bg-amber-200", chipText: "text-amber-900" };
  return { bg: "bg-rose-50", text: "text-violet-700", chipBg: "bg-rose-200", chipText: "text-rose-900" };
}
