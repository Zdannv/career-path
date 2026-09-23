/**
 * Akses data layar Progress.
 *
 *   progress_state()        total progress, level, title, statistik, badge terbaru
 *   progress_pencapaian()   seluruh badge beserta waktu terbukanya
 *
 * Keduanya dari migrasi 0038. progress_state() juga membagikan hadiah yang
 * sudah pantas didapat sebelum menjawab — jadi XP onboarding dan Career DNA
 * ikut terhitung untuk akun yang dibuat sebelum mesin pencapaian ada.
 */

import { supabase } from "@/lib/supabaseClient";

export type BadgeSingkat = {
  kode: string;
  nama: string;
  deskripsi: string;
  gambar: string;
  waktu: string;
};

export type ProgressState = {
  career_id: number | null;
  career_name: string | null;
  has_career: boolean;
  /** Persen quest yang sudah selesai dari seluruh quest profesi pilihan. */
  total_persen: number;
  n_quest_total: number;
  n_quest_selesai: number;
  n_achievement: number;
  n_achievement_total: number;
  level: number;
  /** "1".."10", lalu "10+" di level tertinggi. */
  level_label: string;
  title: string;
  total_xp: number;
  xp_di_level: number;
  /** NULL di level tertinggi: tidak ada level berikutnya. */
  xp_level_berikutnya: number | null;
  persen_level: number;
  terbaru: BadgeSingkat[];
};

export type Pencapaian = {
  code: string;
  nama: string;
  deskripsi: string;
  gambar: string;
  kategori: string;
  urutan: number;
  /** NULL berarti masih terkunci. */
  waktu: string | null;
};

export async function ambilProgress(): Promise<ProgressState | null> {
  const { data, error } = await supabase.rpc("progress_state").maybeSingle();
  if (error) throw error;
  return (data as ProgressState) ?? null;
}

export async function ambilPencapaian(): Promise<Pencapaian[]> {
  const { data, error } = await supabase.rpc("progress_pencapaian");
  if (error) throw error;
  return (data as Pencapaian[]) ?? [];
}
