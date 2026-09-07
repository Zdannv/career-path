/**
 * Akses data layar Career DNA (Discovery).
 *
 * Opsi keenam langkah diambil sekali lewat `dna_options()` dan dikelompokkan
 * di sini — layar butuh semuanya sekaligus (daftar pada langkah aktif, judul
 * dan pertanyaan di sidebar, nama atribut di layar Review), dan isinya tidak
 * pernah berubah saat orang mengisi.
 *
 * Penyimpanannya per langkah. Batas maksimal pilihan divalidasi di database,
 * bukan hanya di layar — tombol yang dinonaktifkan itu kenyamanan, bukan
 * aturan.
 */

import { supabase } from "@/lib/supabaseClient";

export type DnaAttributeOption = {
  code: string;
  order: number;
  name: string;
  hint: string | null;
};

export type DnaLayerStep = {
  layerCode: string;
  order: number;
  name: string;
  question: string;
  maxPick: number;
  attributes: DnaAttributeOption[];
};

export type DnaProgress = {
  currentStep: number;
  completedAt: string | null;
  /** Kode atribut yang tersimpan, dikelompokkan per kategori. */
  picks: Record<string, string[]>;
};

type OptionRow = {
  layer_code: string;
  layer_order: number;
  layer_name: string;
  layer_question: string;
  max_pick: number;
  attribute_code: string;
  attribute_order: number;
  attribute_name: string;
  attribute_hint: string | null;
};

/** Enam langkah: lima kategori DNA, lalu Review sebagai langkah keenam. */
export const TOTAL_STEPS = 6;

export const REVIEW_STEP = {
  order: 6,
  name: "Review Career DNA-mu",
  question: "Cek lagi dan selesai!",
} as const;

export async function getDnaSteps(): Promise<DnaLayerStep[]> {
  const { data, error } = await supabase.rpc("dna_options");
  if (error || !data) return [];

  const perLayer = new Map<string, DnaLayerStep>();
  for (const r of data as OptionRow[]) {
    let step = perLayer.get(r.layer_code);
    if (!step) {
      step = {
        layerCode: r.layer_code,
        order: r.layer_order,
        name: r.layer_name,
        question: r.layer_question,
        maxPick: r.max_pick,
        attributes: [],
      };
      perLayer.set(r.layer_code, step);
    }
    step.attributes.push({
      code: r.attribute_code,
      order: r.attribute_order,
      name: r.attribute_name,
      hint: r.attribute_hint,
    });
  }
  return [...perLayer.values()].sort((a, b) => a.order - b.order);
}

export async function getDnaProgress(): Promise<DnaProgress> {
  const { data, error } = await supabase.rpc("dna_progress").single();
  if (error || !data) return { currentStep: 1, completedAt: null, picks: {} };
  const row = data as { current_step: number; completed_at: string | null; picks: Record<string, string[]> };
  return {
    currentStep: row.current_step ?? 1,
    completedAt: row.completed_at ?? null,
    picks: row.picks ?? {},
  };
}

/**
 * Menyimpan satu kategori. `nextStep` adalah langkah tertinggi yang sudah
 * dicapai; database menyimpan yang terbesar, jadi mundur untuk mengubah
 * pilihan tidak menurunkan progres.
 */
export async function saveDnaStep(
  layerCode: string,
  codes: string[],
  nextStep: number
): Promise<{ error: string | null }> {
  const { error } = await supabase.rpc("save_dna_step", {
    p_layer_code: layerCode,
    p_codes: codes,
    p_next_step: nextStep,
  });
  return { error: error?.message ?? null };
}

export async function completeDna(): Promise<{ error: string | null }> {
  const { error } = await supabase.rpc("complete_dna");
  return { error: error?.message ?? null };
}
