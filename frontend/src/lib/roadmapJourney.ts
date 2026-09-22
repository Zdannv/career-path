/**
 * Akses data layar Roadmap dan Journey.
 *
 * Empat RPC dari migrasi 0035, satu per bagian layar:
 *
 *   roadmap_state()      kartu profesi + level XP + lima tahap persiapan
 *   roadmap_jalur(id)    pilihan jalur pendidikan beserta langkahnya
 *   journey_stage(id, ?) isi satu tahap Journey
 *   set_journey_item()   tandai satu item sudah dipelajari
 *
 * Tab "Jalur Pendidikan" baru diminta saat pengguna menyentuhnya: membuka
 * Roadmap tidak perlu menarik dua jalur berisi delapan langkah yang belum
 * tentu dilihat.
 *
 * Semua RPC memakai auth.uid() di dalam database dan tidak menerima user id.
 */

import { supabase } from "@/lib/supabaseClient";

// ─────────────────────────────────────────────────────────────────────────────
// Bentuk data
// ─────────────────────────────────────────────────────────────────────────────

export type StatusTahap = "SELESAI" | "AKTIF" | "TERKUNCI";

export type Tahap = {
  kode: string;
  urutan: number;
  nama: string;
  ringkasan: string;
  persen: number;
  status: StatusTahap;
  /** Tombol "Tampilkan Journey" hanya ada di tahap yang sedang berjalan. */
  cta: boolean;
};

export type RoadmapState = {
  career_id: number | null;
  career_name: string | null;
  has_career: boolean;
  total_xp: number;
  level_name: string | null;
  min_xp: number | null;
  next_xp: number | null;
  tahap: Tahap[];
};

export type StatusItem = "BELUM_MULAI" | "BERLANGSUNG" | "SELESAI";

export type JenisLangkah =
  | "SEKOLAH"
  | "KULIAH"
  | "ALIH_JENJANG"
  | "PROFESI"
  | "UJI"
  | "LISENSI"
  | "SERTIFIKASI"
  | "PKL"
  | "KERJA"
  | "SPESIALISASI"
  | "TUJUAN";

export type Langkah = {
  urutan: number;
  judul: string;
  catatan: string | null;
  jenis: JenisLangkah;
  status: StatusItem;
};

export type Jalur = {
  path_id: number;
  kind_code: "VOKASI" | "AKADEMIK";
  kind_label: string;
  level_code: string;
  title_id: string;
  tagline_id: string;
  years_min: number;
  years_max: number;
  cta_label_id: string;
  table_label_id: string;
  display_order: number;
  dipilih: boolean;
  keunggulan: string[];
  langkah: Langkah[];
};

export type JenisKonten = "TOPIK" | "SOFT_SKILL" | "SKILL_TOOLS" | "KEGIATAN" | "NONE";

export type ItemTopik = {
  kode: string;
  ikon: string;
  judul: string;
  isi: string;
  status: StatusItem;
};

export type ItemSoftSkill = ItemTopik & {
  tone: "biru" | "hijau" | "ungu" | "oranye" | "kuning" | "merah";
  n_quest: number;
  quest: string[];
};

export type ItemSkill = {
  kode: string;
  judul: string;
  isi: string | null;
  fase?: string;
  status: StatusItem;
};

export type KontenSkillTools = { hard_skill: ItemSkill[]; tools: ItemSkill[] };

export type JourneyStage = {
  stage_code: string;
  stage_order: number;
  nama: string;
  hero: string;
  ringkasan: string;
  learn_intro: string;
  content_kind: JenisKonten;
  persen: number;
  konten: ItemTopik[] | ItemSoftSkill[] | KontenSkillTools | [];
  hasil: string[];
};

// ─────────────────────────────────────────────────────────────────────────────
// Panggilan
// ─────────────────────────────────────────────────────────────────────────────

export async function ambilRoadmapState(): Promise<RoadmapState | null> {
  const { data, error } = await supabase.rpc("roadmap_state").maybeSingle();
  if (error) throw error;
  return (data as RoadmapState) ?? null;
}

export async function ambilJalur(careerId: number): Promise<Jalur[]> {
  const { data, error } = await supabase.rpc("roadmap_jalur", { p_career_id: careerId });
  if (error) throw error;
  return (data as Jalur[]) ?? [];
}

export async function simpanJalur(careerId: number, pathId: number): Promise<void> {
  const { error } = await supabase.rpc("pilih_jalur", {
    p_career_id: careerId,
    p_path_id: pathId,
  });
  if (error) throw error;
}

export async function batalkanJalur(careerId: number): Promise<void> {
  const { error } = await supabase.rpc("batal_jalur", { p_career_id: careerId });
  if (error) throw error;
}

export async function ambilJourneyStage(
  careerId: number,
  stageCode?: string,
): Promise<JourneyStage | null> {
  const { data, error } = await supabase
    .rpc("journey_stage", { p_career_id: careerId, p_stage_code: stageCode ?? null })
    .maybeSingle();
  if (error) throw error;
  return (data as JourneyStage) ?? null;
}

export async function tandaiItem(
  careerId: number,
  jenis: "TOPIK" | "SOFT_SKILL" | "HARD_SKILL" | "TOOL" | "KEGIATAN",
  kode: string,
  status: StatusItem,
): Promise<void> {
  const { error } = await supabase.rpc("set_journey_item", {
    p_career_id: careerId,
    p_item_kind: jenis,
    p_item_code: kode,
    p_status: status,
  });
  if (error) throw error;
}

// ─────────────────────────────────────────────────────────────────────────────
// Penyajian
// ─────────────────────────────────────────────────────────────────────────────

export const LABEL_STATUS: Record<StatusItem, string> = {
  BELUM_MULAI: "Belum Mulai",
  BERLANGSUNG: "Berlangsung",
  SELESAI: "Selesai",
};

/** "±5-6 Tahun", atau "±5 Tahun" kalau rentangnya sama. */
export function rentangTahun(min: number, max: number): string {
  return min === max ? `±${min}` : `±${min}-${max}`;
}

/**
 * Gambar hero per tahap.
 *
 * Dipotong dari ekspor SVG Figma (1916 px, bingkai 335:128) — SVG aslinya
 * hanya membungkus satu PNG besar, jadi disimpan sebagai JPG ±200 KB alih-alih
 * SVG 2-3 MB dengan hasil tampilan yang sama.
 */
export const HERO_TAHAP: Record<string, string> = {
  EKSPLORASI: "/journey/eksplorasi.jpg",
  PONDASI: "/journey/pondasi.jpg",
  KEAHLIAN: "/journey/keahlian.jpg",
  PENGALAMAN: "/journey/pengalaman.jpg",
  BERKARIER: "/journey/berkarier.jpg",
};

export function heroTahap(kode: string): string {
  return HERO_TAHAP[kode] ?? HERO_TAHAP.EKSPLORASI;
}
