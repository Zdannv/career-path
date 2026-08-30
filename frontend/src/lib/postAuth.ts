/**
 * Ke mana pengguna diarahkan setelah berhasil masuk.
 *
 * Ada satu aturan dan ia dipakai di beberapa tempat — tombol login, tombol
 * "Mulai Career Journey" di landing, dan nanti tautan dari email verifikasi.
 * Ditulis sekali di sini supaya ketiganya tidak berbeda pendapat: pernah
 * terjadi onboarding sudah jadi tapi tidak ada satu pun jalan menuju ke sana,
 * karena setiap tempat menulis "/student" sendiri-sendiri.
 */

import { supabase } from "@/lib/supabaseClient";

/**
 * Tujuan sementara bagi pengguna yang onboarding-nya sudah selesai.
 *
 * `/student` adalah layar CareerPath AI lama. Ia bertahan sampai dashboard
 * baru ada; begitu itu terjadi, cukup satu baris ini yang diganti.
 */
export const HOME_AFTER_ONBOARDING = "/student";

export const ONBOARDING_PATH = "/onboarding";

/**
 * Pengguna yang belum menyelesaikan onboarding dikirim ke sana lebih dulu.
 *
 * Penandanya `profiles.onboarding_completed_at`, yang diisi `saveEducation()`
 * di langkah terakhir. Kalau profilnya belum ada — trigger `handle_new_user`
 * biasanya sudah membuatnya, tapi jangan diandalkan — anggap belum onboarding.
 */
export async function postLoginDestination(): Promise<string> {
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return "/login";

  const { data, error } = await supabase
    .from("profiles")
    .select("onboarding_completed_at")
    .eq("user_id", auth.user.id)
    .maybeSingle();

  // Gagal membaca profil bukan alasan menahan orang di halaman login. Onboarding
  // aman diulang — semua langkahnya menulis ulang baris yang sama — jadi kalau
  // ragu, ke sana saja.
  if (error) return ONBOARDING_PATH;

  return data?.onboarding_completed_at ? HOME_AFTER_ONBOARDING : ONBOARDING_PATH;
}
