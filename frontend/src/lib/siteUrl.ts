/**
 * Alamat dasar aplikasi untuk link yang dikirim lewat email.
 *
 * Kenapa tidak `window.location.origin` saja: nilai itu dibekukan ke dalam
 * email pada detik pengguna menekan tombol daftar. Kalau ia mendaftar dari
 * `http://localhost:3000`, link verifikasinya selamanya menunjuk ke sana —
 * dan email itu biasanya dibuka beberapa menit kemudian, saat dev server sudah
 * dimatikan, atau dibuka di HP, di mana `localhost` berarti HP itu sendiri.
 * Dua-duanya berakhir di ERR_CONNECTION_REFUSED.
 *
 * `NEXT_PUBLIC_SITE_URL` memisahkan "di mana aku dibuka sekarang" dari "ke mana
 * orang harus kembali nanti". Isi dengan domain sungguhan di production.
 *
 * Catatan: alamat yang dihasilkan di sini juga harus terdaftar di Supabase
 * Dashboard -> Authentication -> URL Configuration -> Redirect URLs. Kalau
 * tidak, Supabase mengabaikannya dan diam-diam memakai Site URL.
 */

/**
 * Melengkapi alamat yang ditulis tanpa skema.
 *
 * Ini bukan kerapian: `NEXT_PUBLIC_SITE_URL=career-path-two-alpha.vercel.app`
 * membuat redirect_to jadi alamat relatif, dan Supabase menempelkannya ke
 * domainnya sendiri. Link verifikasi di email lalu mendarat di
 * `https://<ref>.supabase.co/career-path-two-alpha.vercel.app#access_token=…`
 * yang menjawab {"error":"requested path is invalid"} — persis yang terjadi di
 * produksi. Panel Vercel juga menyalin domain tanpa skema, jadi salah ketik ini
 * mudah terjadi dan pantas ditambal di sini.
 */
function rapikan(nilai: string | undefined): string | null {
  const v = nilai?.trim().replace(/\/+$/, "");
  if (!v) return null;

  const lokal = /^(localhost|127\.0\.0\.1|0\.0\.0\.0)(:|$)/.test(v);
  const lengkap = /^https?:\/\//i.test(v) ? v : `${lokal ? "http" : "https"}://${v}`;

  try {
    const url = new URL(lengkap);
    return url.origin + url.pathname.replace(/\/+$/, "");
  } catch {
    // Nilai yang tidak bisa diurai lebih buruk daripada tidak ada nilai:
    // biarkan pemanggil jatuh ke origin peramban.
    return null;
  }
}

export function siteUrl(path = "/"): string {
  const base =
    rapikan(process.env.NEXT_PUBLIC_SITE_URL) ??
    (typeof window !== "undefined" ? window.location.origin : "");

  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}
