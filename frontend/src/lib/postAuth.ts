/**
 * Ke mana pengguna diarahkan setelah berhasil masuk.
 *
 * Ada satu aturan dan ia dipakai di beberapa tempat — tombol login, tombol
 * "Mulai Career Journey" di landing, penjaga rute, dan tautan dari email
 * verifikasi. Ditulis sekali di sini supaya semuanya tidak berbeda pendapat.
 *
 * Path-nya sendiri tinggal di lib/routes.ts; file ini hanya memutuskan yang
 * mana yang dipakai.
 */

import { supabase } from "@/lib/supabaseClient";
import { HOME_AFTER_ONBOARDING, ROUTES } from "@/lib/routes";

export { HOME_AFTER_ONBOARDING };
export const ONBOARDING_PATH = ROUTES.onboarding;

/** Sudahkah pengguna ini menyelesaikan onboarding? */
export async function sudahOnboarding(userId: string): Promise<boolean> {
  const { data, error } = await supabase
    .from("profiles")
    .select("onboarding_completed_at")
    .eq("user_id", userId)
    .maybeSingle();

  // Gagal membaca profil tidak dianggap sudah selesai: onboarding aman diulang
  // — semua langkahnya menulis ulang baris yang sama — jadi kalau ragu, ke sana.
  if (error) return false;
  return Boolean(data?.onboarding_completed_at);
}

/**
 * Tujuan sesudah login.
 *
 * `next` diisi dari query `?next=` ketika penjaga rute memulangkan seseorang ke
 * halaman login: setelah masuk ia kembali ke halaman yang tadi dituju, bukan
 * dilempar ke Explore dan harus mencari ulang.
 */
export async function postLoginDestination(next?: string | null): Promise<string> {
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return ROUTES.login;

  if (!(await sudahOnboarding(auth.user.id))) return ONBOARDING_PATH;
  return tujuanAman(next) ?? HOME_AFTER_ONBOARDING;
}

/**
 * Menyaring nilai `?next=`.
 *
 * Hanya path internal yang diterima. Tanpa ini, `?next=https://situs-lain`
 * mengubah halaman login kita jadi batu loncatan phishing — seseorang mengirim
 * tautan login Navika yang sah, lalu korban mendarat di tempat lain.
 */
export function tujuanAman(next?: string | null): string | null {
  if (!next) return null;
  if (!next.startsWith("/") || next.startsWith("//")) return null;
  return next;
}
