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
export function siteUrl(path = "/"): string {
  const configured = process.env.NEXT_PUBLIC_SITE_URL?.trim();
  const base = (
    configured || (typeof window !== "undefined" ? window.location.origin : "")
  ).replace(/\/+$/, "");

  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}
