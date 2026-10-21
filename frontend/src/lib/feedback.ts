/**
 * Kirim masukan dari halaman Feedback dan Support.
 *
 * Tabel `feedback` (migration 0045) hanya menerima INSERT dari klien. Karena
 * itu insert-nya tanpa `.select()`: membaca balik baris yang baru dibuat akan
 * ditolak RLS dan membuat pengiriman yang sebenarnya berhasil tampak gagal.
 */

import { supabase } from "@/lib/supabaseClient";

export type KategoriFeedback = "saran" | "masalah" | "pertanyaan" | "hapus_data" | "lainnya";

export const KATEGORI_FEEDBACK: { value: KategoriFeedback; label: string }[] = [
  { value: "saran", label: "Saran & ide" },
  { value: "masalah", label: "Laporkan masalah" },
  { value: "pertanyaan", label: "Pertanyaan" },
  { value: "hapus_data", label: "Hapus akun & data" },
  { value: "lainnya", label: "Lainnya" },
];

export const PESAN_MIN = 10;
export const PESAN_MAX = 2000;

export async function kirimFeedback(isi: {
  kategori: KategoriFeedback;
  pesan: string;
  rating: number | null;
  email: string | null;
  halaman: string | null;
}): Promise<void> {
  const { error } = await supabase.from("feedback").insert({
    kategori: isi.kategori,
    pesan: isi.pesan.trim(),
    rating: isi.rating,
    email: isi.email?.trim() || null,
    halaman: isi.halaman?.slice(0, 300) ?? null,
    user_agent: typeof navigator !== "undefined" ? navigator.userAgent.slice(0, 500) : null,
  });
  if (error) {
    // Tabel belum ada: migration 0045 belum dijalankan.
    if (error.code === "42P01" || /relation .*feedback/i.test(error.message)) {
      throw new Error("Layanan masukan belum aktif di server. Coba lagi nanti.");
    }
    throw new Error("Gagal mengirim. Periksa koneksi lalu coba lagi.");
  }
}
