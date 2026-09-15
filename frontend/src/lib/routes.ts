/**
 * Satu-satunya daftar rute aplikasi.
 *
 * Sebelum ini tiap file menulis path-nya sendiri: Navbar punya daftar rute
 * chromeless-nya, halaman onboarding menulis tujuan akhirnya sendiri, dan tiap
 * layar aplikasi menyalin ulang pemeriksaan sesi. Akibatnya tombol terakhir
 * onboarding mengarah ke "/dashboard" — rute yang tidak pernah ada — dan tidak
 * ada yang sadar karena tidak ada tempat untuk membandingkannya.
 *
 * Aturannya sekarang: rute baru ditambahkan di sini dulu, baru dipakai.
 */

export const ROUTES = {
  // publik
  landing: "/",
  login: "/login",
  daftar: "/daftar",
  verifikasi: "/verifikasi",
  lupaSandi: "/lupa-sandi",
  resetSandi: "/reset-sandi",
  syaratLayanan: "/syarat-layanan",
  kebijakanPrivasi: "/kebijakan-privasi",

  // alur yang harus diselesaikan
  onboarding: "/onboarding",
  careerDna: "/career-dna",

  // layar aplikasi
  explore: "/explore",
  exploreCari: "/explore/cari",
  roadmap: "/roadmap",
  journey: "/journey",
  quest: "/quest",
  progress: "/progress",
  careerInsights: "/career-insights",
} as const;

/** Detail profesi, kategori, dan daftar per baris — path-nya bergantung id. */
export const profesiPath = (careerId: number | string) => `/explore/${careerId}`;
export const kategoriPath = (familyCode: string) =>
  `/explore/kategori/${encodeURIComponent(familyCode)}`;
export const daftarBarisPath = (slug: string) => `/explore/daftar/${slug}`;

/**
 * Tujuan setelah onboarding selesai, dan setelah login bagi yang sudah
 * onboarding. Dulu "/student" (CareerPath AI lama), lalu "/dashboard" yang
 * tidak pernah ada. Sekarang Explore, layar utama aplikasi.
 */
export const HOME_AFTER_ONBOARDING: string = ROUTES.explore;

/**
 * Rute yang menyembunyikan navigasi aplikasi sepenuhnya.
 *
 * Auth dan onboarding membawa lockup "Navika | Career path journey" sendiri di
 * tengah, dan keduanya alur yang harus diselesaikan — bukan halaman yang boleh
 * ditinggalkan lewat menu.
 */
export const CHROMELESS_ROUTES: string[] = [
  ROUTES.daftar,
  ROUTES.login,
  ROUTES.verifikasi,
  ROUTES.lupaSandi,
  ROUTES.resetSandi,
  ROUTES.onboarding,
  ROUTES.careerDna,
];

/**
 * Layar aplikasi yang membawa bar atas dan bar bawahnya sendiri (AppNav).
 * Navbar global tidak boleh ikut muncul di sini — dua bar bertumpuk hanya
 * membingungkan.
 */
export const APP_SHELL_ROUTES: string[] = [
  ROUTES.explore,
  ROUTES.roadmap,
  ROUTES.journey,
  ROUTES.quest,
  ROUTES.progress,
  ROUTES.careerInsights,
];

/**
 * Rute yang menuntut sesi masuk DAN onboarding yang sudah selesai.
 *
 * Dipakai RequireAuth. Career DNA ikut di sini walau chromeless: ia butuh
 * profil pengguna, jadi tidak masuk akal dibuka sebelum onboarding.
 */
export const PROTECTED_ROUTES: string[] = [
  ...APP_SHELL_ROUTES,
  ROUTES.careerDna,
];

/** true kalau `pathname` berada di dalam salah satu prefiks. */
export function cocok(pathname: string, daftar: string[]): boolean {
  return daftar.some((r) => pathname === r || pathname.startsWith(`${r}/`));
}
