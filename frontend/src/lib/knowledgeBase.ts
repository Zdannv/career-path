/**
 * Akses knowledge base dari frontend.
 *
 * Semua tabel referensi (careers, dna_*, onet_*, industries) berstatus
 * public-read lewat RLS, jadi bisa dibaca dengan anon key tanpa login.
 * Tabel milik user (user_dna) hanya bisa diakses pemiliknya — RLS yang
 * mengurus, tidak perlu filter manual di sini.
 */

import { supabase } from "@/lib/supabaseClient";

export type LayerCode = "INTEREST" | "ACTIVITY" | "SKILL" | "ENVIRONMENT" | "WORKSTYLE";

export type DnaLayer = {
  code: LayerCode;
  name_id: string;
  description_id: string;
  role: "main" | "supporting";
  selection_count: number;
  display_order: number;
};

export type DnaAttribute = {
  code: string;
  layer_code: LayerCode;
  name_id: string;
  description_id: string;
  display_order: number;
};

export type CareerMatch = {
  career_id: number;
  career_name: string;
  match_score: number;
  layers: Partial<Record<LayerCode, number>>;
};

export type CareerSummary = {
  id: number;
  career_name: string;
  name_en: string | null;
  job_zone: number | null;
  relevance: "umum" | "terbatas" | "tidak_relevan";
  salary_min: number | null;
  salary_max: number | null;
  salary_confidence: "high" | "medium" | "low" | "none" | null;
};

export type CareerDetailRow = {
  id: number;
  career_name: string;
  career_description: string | null;
  name_en: string | null;
  name_alt: string | null;
  job_zone: number | null;
  min_education_rank: number | null;
  relevance: "umum" | "terbatas" | "tidak_relevan";
  source: string | null;
  salary_min: number | null;
  salary_max: number | null;
  salary_source: string | null;
  salary_confidence: "high" | "medium" | "low" | "none" | null;
  curation_note: string | null;
};

export type CareerDnaRow = {
  attribute_code: string;
  layer_code: LayerCode;
  attribute_name: string;
  score: number;
  rank_in_layer: number;
  is_dominant: boolean;
  dna_source: string;
};

// ─────────────────────────────────────────────────────────────────────────────
// Career Discovery — bahan untuk layar pemilihan DNA
// ─────────────────────────────────────────────────────────────────────────────

/** 5 layer beserta berapa atribut yang harus dipilih user di masing-masing. */
export async function getDnaLayers(): Promise<DnaLayer[]> {
  const { data, error } = await supabase
    .from("dna_layers")
    .select("code, name_id, description_id, role, selection_count, display_order")
    .order("display_order");
  if (error) throw error;
  return (data ?? []) as DnaLayer[];
}

/** 54 atribut, sudah terurut siap render sebagai chip. */
export async function getDnaAttributes(layer?: LayerCode): Promise<DnaAttribute[]> {
  let q = supabase
    .from("dna_attributes")
    .select("code, layer_code, name_id, description_id, display_order")
    .eq("is_active", true)
    .order("display_order");
  if (layer) q = q.eq("layer_code", layer);
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as DnaAttribute[];
}

/**
 * Simpan pilihan DNA user. Menimpa pilihan sebelumnya, jadi aman dipanggil
 * ulang kalau user mengubah jawabannya.
 */
export async function saveUserDna(userId: string, attributeCodes: string[]): Promise<void> {
  const del = await supabase.from("user_dna").delete().eq("user_id", userId);
  if (del.error) throw del.error;
  if (attributeCodes.length === 0) return;

  const { error } = await supabase
    .from("user_dna")
    .insert(attributeCodes.map((code) => ({ user_id: userId, attribute_code: code })));
  if (error) throw error;
}

export async function getUserDna(userId: string): Promise<string[]> {
  const { data, error } = await supabase
    .from("user_dna")
    .select("attribute_code")
    .eq("user_id", userId);
  if (error) throw error;
  return (data ?? []).map((r) => r.attribute_code as string);
}

// ─────────────────────────────────────────────────────────────────────────────
// Career Matching
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Career Match Score untuk semua profesi aktif, terurut dari yang paling cocok.
 *
 * `layers` memuat skor per layer — pakai itu untuk menjelaskan ALASAN
 * kecocokannya ("minatmu 92% cocok, lingkungan kerjanya 40%"), bukan cuma
 * menampilkan satu angka besar tanpa konteks.
 */
export async function getCareerMatches(userId: string, limit = 20): Promise<CareerMatch[]> {
  const { data, error } = await supabase.rpc("career_match_scores", { p_user_id: userId });
  if (error) throw error;
  return ((data ?? []) as CareerMatch[]).slice(0, limit);
}

/** Profesi dengan DNA dominan paling banyak beririsan. */
export async function getSimilarCareers(careerId: number, limit = 6) {
  const { data, error } = await supabase.rpc("similar_careers", {
    p_career_id: careerId,
    p_limit: limit,
  });
  if (error) throw error;
  return (data ?? []) as {
    career_id: number;
    career_name: string;
    shared_dna: number;
    similarity: number;
  }[];
}

// ─────────────────────────────────────────────────────────────────────────────
// Eksplorasi & detail profesi
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Pencarian profesi. Mencari di nama Indonesia, nama O*NET, dan istilah
 * alternatif sekaligus — user bisa mengetik "designer" maupun "desainer".
 */
export async function searchCareers(query: string, industryCode?: string, limit = 30) {
  let q = supabase
    .from("careers")
    .select("id, career_name, name_en, job_zone, relevance, salary_min, salary_max, salary_confidence")
    .eq("is_active", true)
    .limit(limit);

  if (query.trim()) {
    const t = query.trim();
    q = q.or(`career_name.ilike.%${t}%,name_en.ilike.%${t}%,name_alt.ilike.%${t}%`);
  }
  if (industryCode) {
    const { data: ids, error: e1 } = await supabase
      .from("career_industries")
      .select("career_id")
      .eq("industry_code", industryCode);
    if (e1) throw e1;
    q = q.in("id", (ids ?? []).map((r) => r.career_id));
  }

  const { data, error } = await q.order("career_name");
  if (error) throw error;
  return (data ?? []) as CareerSummary[];
}

export async function getIndustries() {
  const { data, error } = await supabase
    .from("industries")
    .select("code, name_id, icon, display_order")
    .order("display_order");
  if (error) throw error;
  return data ?? [];
}

/** Semua yang dibutuhkan halaman Career Detail, dalam satu pemanggilan. */
export async function getCareerDetail(careerId: number) {
  const [career, dna, riasec, industries] = await Promise.all([
    supabase
      .from("careers")
      .select(
        "id, career_name, career_description, name_en, name_alt, job_zone, " +
          "min_education_rank, relevance, source, salary_min, salary_max, " +
          "salary_source, salary_confidence, curation_note"
      )
      .eq("id", careerId)
      .single<CareerDetailRow>(),
    supabase
      .from("career_dna")
      .select("attribute_code, layer_code, attribute_name, score, rank_in_layer, is_dominant, dna_source")
      .eq("career_id", careerId)
      .order("rank_in_layer"),
    supabase
      .from("career_riasec")
      .select("holland_code, r_pct, i_pct, a_pct, s_pct, e_pct, c_pct, confidence")
      .eq("career_id", careerId)
      .maybeSingle(),
    supabase
      .from("career_industries")
      .select("industry_code, industries(name_id, icon)")
      .eq("career_id", careerId),
  ]);

  if (career.error) throw career.error;
  if (dna.error) throw dna.error;
  if (industries.error) throw industries.error;

  const rows = (dna.data ?? []) as CareerDnaRow[];
  const byLayer = rows.reduce<Record<string, CareerDnaRow[]>>((acc, r) => {
    (acc[r.layer_code] ??= []).push(r);
    return acc;
  }, {});

  return {
    career: career.data,
    dna: rows,
    dnaByLayer: byLayer,
    dominantDna: rows.filter((r) => r.is_dominant),
    riasec: riasec.data ?? null,
    industries: industries.data ?? [],
    /**
     * Rentang gaji hanya boleh ditampilkan kalau sumbernya jelas.
     * `none` berarti belum ada data pasar Indonesia — jangan tampilkan
     * angka apa pun, dan jangan pakai angka O*NET (itu pasar AS).
     */
    showSalary:
      career.data?.salary_confidence != null &&
      career.data.salary_confidence !== "none" &&
      career.data.salary_min != null,
  };
}
