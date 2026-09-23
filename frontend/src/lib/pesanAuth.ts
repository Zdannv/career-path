/**
 * Menerjemahkan galat autentikasi Supabase ke kalimat yang layak dibaca.
 *
 * Supabase menjawab dalam bahasa Inggris dan dengan istilahnya sendiri —
 * "email rate limit exceeded", "invalid login credentials". Sebelum ini
 * kalimat itu ditempel apa adanya ke layar daftar dan login, jadi pengguna
 * membaca istilah teknis dalam bahasa asing untuk situasi yang sebenarnya
 * biasa (misalnya: terlalu sering minta email verifikasi).
 *
 * Yang tidak dikenali dikembalikan apa adanya: lebih baik kalimat Inggris
 * daripada "terjadi kesalahan" yang tidak memberi petunjuk apa-apa.
 */

const PETA: { cocok: RegExp; pesan: string }[] = [
  {
    // Batas kirim email Supabase. Layanan email bawaannya hanya untuk
    // pengembangan; batas itu naik setelah SMTP sendiri dipasang.
    cocok: /email rate limit exceeded|over_email_send_rate_limit/i,
    pesan:
      "Terlalu banyak email terkirim dalam waktu singkat. Tunggu sekitar satu jam, lalu coba lagi.",
  },
  {
    cocok: /for security purposes.*(\d+)\s*seconds|request this after/i,
    pesan: "Tunggu sebentar sebelum mencoba lagi.",
  },
  {
    cocok: /rate limit|too many requests/i,
    pesan: "Terlalu banyak percobaan. Coba lagi beberapa saat.",
  },
  {
    cocok: /invalid login credentials/i,
    pesan: "Email atau kata sandi salah.",
  },
  {
    cocok: /email not confirmed/i,
    pesan: "Email Kamu belum diverifikasi. Cek inbox untuk link verifikasi.",
  },
  {
    cocok: /already registered|already exists|user_already_exists/i,
    pesan: "Email ini sudah terdaftar. Coba masuk, atau pakai email lain.",
  },
  {
    cocok: /password should be at least|weak.?password/i,
    pesan: "Kata sandi terlalu pendek. Pakai minimal 8 karakter.",
  },
  {
    cocok: /new password should be different/i,
    pesan: "Kata sandi baru harus berbeda dari yang lama.",
  },
  {
    cocok: /invalid.*email|unable to validate email/i,
    pesan: "Alamat email tidak dikenali. Periksa ejaannya.",
  },
  {
    cocok: /token has expired|otp_expired|invalid.*token/i,
    pesan: "Link-nya sudah kedaluwarsa. Minta link baru lalu coba lagi.",
  },
  {
    cocok: /failed to fetch|network|load failed/i,
    pesan: "Tidak bisa menghubungi server. Periksa koneksimu lalu coba lagi.",
  },
];

export function pesanAuth(e: unknown): string {
  const teks =
    typeof e === "string" ? e : ((e as { message?: string })?.message ?? "");
  if (!teks) return "Terjadi kesalahan. Coba lagi sebentar.";

  return PETA.find((p) => p.cocok.test(teks))?.pesan ?? teks;
}
