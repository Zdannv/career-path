/**
 * Akses data layar Quest.
 *
 * RPC dari migrasi 0036:
 *
 *   quest_beranda()          kartu "Apa yang perlu Kamu kerjakan minggu ini"
 *   quest_grup(slug, kode)   isi satu grup: banner tips, quest, tujuan, catatan
 *   ambil_quest(key)         tombol "Ambil Quest"
 *   selesaikan_quest(key, jawaban)  tombol "Selesaikan", mengembalikan XP dan badge baru.
 *                            Sejak 0051 quest AMBIL wajib dijawab (minimal 20 karakter).
 *   quest_minggu_ini(n)      kartu "Quest minggu ini" di Explore
 *   quest_streak()           hari beruntun menyelesaikan quest (0051)
 *
 * Aturan buka-kunci, urutan level, syarat magang, dan nilai XP semuanya
 * diputuskan database. Layar hanya menampilkan `bisa` dan `alasan` yang
 * dikirimkannya — tombol yang dinonaktifkan di sini kenyamanan, bukan aturan.
 */

import { supabase } from "@/lib/supabaseClient";

// ─────────────────────────────────────────────────────────────────────────────
// Bentuk data
// ─────────────────────────────────────────────────────────────────────────────

export type JenisGrup =
  | "EKSPLORASI"
  | "SOFT_SKILL"
  | "HARD_SKILL"
  | "TOOL"
  | "PENGALAMAN"
  | "BERKARIER";

export type ToneGrup = "hijau" | "lime" | "biru" | "ungu" | "pink" | "violet";

export type KartuGrup = {
  jenis: JenisGrup;
  slug: string;
  kode: string;
  label: string;
  judul: string;
  subjudul: string | null;
  ikon: string;
  tone: ToneGrup;
  n_quest: number;
  n_selesai: number;
  n_diambil: number;
};

/** Jenis quest yang belum terbuka, untuk pratinjau "Quest berikutnya". */
export type JenisTerkunci = {
  jenis: JenisGrup;
  label: string;
  /** Nama tahap Journey tempat jenis ini berada. */
  tahap: string;
  ikon: string;
  tone: ToneGrup;
  n_quest: number;
  n_grup: number;
  alasan: string | null;
};

export type QuestBeranda = {
  career_id: number | null;
  career_name: string | null;
  has_career: boolean;
  eksplorasi_selesai: boolean;
  semua_selesai: boolean;
  grup: KartuGrup[];
  terkunci: JenisTerkunci[];
};

export type StatusQuest = "BELUM" | "DIAMBIL" | "SELESAI";

export type Quest = {
  key: string;
  label: string;
  teks: string;
  min_menit: number | null;
  max_menit: number | null;
  xp: number;
  status: StatusQuest;
  /** Bisa ditekan sekarang: grup terbuka, urutan terpenuhi, syarat terpenuhi. */
  bisa: boolean;
  /** Kenapa belum bisa. NULL kalau bisa atau sudah selesai. */
  alasan: string | null;
  /** Jawaban atau catatan yang ditulis saat menyelesaikan (0051). */
  jawaban?: string | null;
};

export type Tips = {
  gambar: "RESOURCE" | "WHATS_NEXT";
  label: string;
  judul: string;
  isi: string | null;
  /** Tampilkan tiga sumber: AI Chat, Youtube, Browsing Artikel. */
  sumber: boolean;
};

export type QuestGrup = {
  jenis: JenisGrup;
  kode: string;
  label: string;
  judul: string;
  subjudul: string | null;
  /** AMBIL: Ambil Quest lalu Selesaikan. LANGSUNG: satu tombol Selesaikan. */
  mode: "AMBIL" | "LANGSUNG";
  berurutan: boolean;
  terbuka: boolean;
  alasan_kunci: string | null;
  tips: Tips;
  tujuan: string[] | null;
  catatan: string | null;
  quest: Quest[];
  /** Profesi pilihan, untuk tautan "Detail profesi di Navika" (0051). */
  career_id?: number | null;
};

export type Badge = { kode: string; nama: string; deskripsi: string; gambar: string };

export type HasilSelesai = {
  xp: number;
  total_xp: number;
  level_name: string;
  badge: Badge | null;
};

export type QuestMingguIni = {
  quest_key: string;
  jenis: JenisGrup;
  slug: string;
  kode: string;
  label: string;
  teks: string;
  min_menit: number | null;
  max_menit: number | null;
  xp: number;
  status: StatusQuest;
  total: number;
};

// ─────────────────────────────────────────────────────────────────────────────
// Panggilan
// ─────────────────────────────────────────────────────────────────────────────

export async function ambilBeranda(): Promise<QuestBeranda | null> {
  const { data, error } = await supabase.rpc("quest_beranda").maybeSingle();
  if (error) throw error;
  return (data as QuestBeranda) ?? null;
}

export async function ambilGrup(slug: string, kode: string): Promise<QuestGrup | null> {
  const { data, error } = await supabase
    .rpc("quest_grup", { p_slug: slug, p_group_code: kode })
    .maybeSingle();
  if (error) throw error;
  return (data as QuestGrup) ?? null;
}

export async function ambilQuest(key: string): Promise<void> {
  const { error } = await supabase.rpc("ambil_quest", { p_quest_key: key });
  if (error) throw error;
}

export async function selesaikanQuest(key: string, jawaban?: string): Promise<HasilSelesai> {
  const { data, error } = await supabase
    .rpc("selesaikan_quest", { p_quest_key: key, p_jawaban: jawaban?.trim() || null })
    .single();
  if (error) throw error;
  return data as HasilSelesai;
}

export type Streak = {
  /** Hari beruntun sampai hari ini atau kemarin; 0 kalau sudah putus. */
  hari: number;
  /** Sudah menyelesaikan quest hari ini. */
  hari_ini: boolean;
  total_hari: number;
};

export async function ambilStreak(): Promise<Streak | null> {
  const { data, error } = await supabase.rpc("quest_streak").maybeSingle();
  // Fitur pelengkap: kalau migrasinya belum jalan, layar tetap tampil tanpanya.
  if (error) return null;
  return (data as Streak) ?? null;
}

export async function ambilQuestMingguIni(limit = 3): Promise<QuestMingguIni[]> {
  const { data, error } = await supabase.rpc("quest_minggu_ini", { p_limit: limit });
  if (error) throw error;
  return (data as QuestMingguIni[]) ?? [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Penyajian
// ─────────────────────────────────────────────────────────────────────────────

/** Jawaban quest AMBIL minimal sepanjang ini; sama dengan aturan di database. */
export const MIN_JAWABAN = 20;
export const MAKS_JAWABAN = 2000;

/**
 * Tautan pencarian yang sudah terisi kalimat quest.
 *
 * Partisipan usability test bertanya kenapa harus mencari sendiri di tempat
 * lain. Sumbernya tetap di luar Navika, tapi sekarang satu ketukan langsung
 * membuka hasil pencarian untuk quest itu, bukan halaman kosong.
 */
export function tautanSumber(teks: string) {
  const q = encodeURIComponent(teks);
  return {
    ai: `https://chatgpt.com/?q=${q}`,
    youtube: `https://www.youtube.com/results?search_query=${q}`,
    google: `https://www.google.com/search?q=${q}`,
  };
}

/** "10-15 menit", "15 menit", atau null untuk quest tanpa durasi. */
export function rentangMenit(min: number | null, max: number | null): string | null {
  if (min == null) return null;
  return max == null || max === min ? `${min} menit` : `${min}-${max} menit`;
}

/**
 * Pesan galat RPC untuk manusia.
 *
 * Fungsi quest menulis "ambil_quest: <alasan>". Bagian setelah titik dua
 * sudah kalimat yang layak dibaca pengguna; nama fungsinya tidak.
 */
export function pesanGalat(e: unknown): string {
  const m = (e as { message?: string })?.message ?? "";
  const alasan = m.includes(": ") ? m.slice(m.indexOf(": ") + 2) : "";
  if (!alasan) return "Gagal menyimpan. Periksa koneksimu lalu coba lagi.";
  return alasan.charAt(0).toUpperCase() + alasan.slice(1);
}
