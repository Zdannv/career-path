/**
 * Serah-terima antartab setelah link verifikasi email diklik.
 *
 * Link di email selalu dibuka di tab baru. Sebelum ini tab lama — layar "Cek
 * email kamu" — diam saja, dan di usability test November 2026 partisipan
 * mengira pendaftarannya macet ("halaman awal tidak dapat refresh, stuck").
 * Yang menguji dengan mode ponsel di DevTools malah kehilangan tampilan
 * ponselnya, karena tab baru tidak ikut mode itu ("layout berubah dari mobile
 * ke desktop").
 *
 * Sekarang:
 *   1. Tab baru (onboarding, mendarat dari link) menyimpan sesinya seperti
 *      biasa, lalu mengumumkan "terverifikasi" lewat BroadcastChannel.
 *   2. Tab lama yang masih membuka layar verifikasi menjawab "diterima" dan
 *      melanjutkan sendiri ke onboarding — sesinya sama, karena tersimpan di
 *      penyimpanan peramban yang sama.
 *   3. Kalau ada yang menjawab, tab baru menyarankan kembali ke tab lama.
 *      Kalau tidak ada (tab lama sudah ditutup, atau email dibuka di perangkat
 *      lain), tab baru langsung melanjutkan onboarding seperti sebelumnya.
 *
 * Peramban tanpa BroadcastChannel tetap jalan seperti sebelum perubahan ini;
 * tab lama juga memeriksa ulang sesi setiap kali kembali difokuskan.
 */

const KANAL = "navika-verifikasi";

type Pesan = { tipe: "terverifikasi" } | { tipe: "diterima" };

function bukaKanal(): BroadcastChannel | null {
  if (typeof window === "undefined" || typeof BroadcastChannel === "undefined") return null;
  try {
    return new BroadcastChannel(KANAL);
  } catch {
    return null;
  }
}

/**
 * Apakah halaman ini dibuka dari link verifikasi.
 *
 * Harus dipanggil SEBELUM klien Supabase dipakai pertama kali: klien membaca
 * token dari URL lalu menghapusnya dari address bar.
 */
export function dibukaDariLinkEmail(): boolean {
  if (typeof window === "undefined") return false;
  const { hash, search } = window.location;
  return (
    /(^|[#&])access_token=/.test(hash) ||
    /(^|[#&])type=(signup|email)/.test(hash) ||
    new URLSearchParams(search).has("code")
  );
}

/** Tab baru: umumkan verifikasi, tunggu apakah ada tab lama yang mengambil alih. */
export function umumkanTerverifikasi(tungguMs = 1500): Promise<boolean> {
  const kanal = bukaKanal();
  if (!kanal) return Promise.resolve(false);
  return new Promise((selesai) => {
    const batas = window.setTimeout(() => {
      kanal.close();
      selesai(false);
    }, tungguMs);
    kanal.onmessage = (e: MessageEvent<Pesan>) => {
      if (e.data?.tipe !== "diterima") return;
      window.clearTimeout(batas);
      kanal.close();
      selesai(true);
    };
    kanal.postMessage({ tipe: "terverifikasi" } satisfies Pesan);
  });
}

/** Tab lama: dengarkan pengumuman, jawab, lalu jalankan `lanjut`. */
export function dengarVerifikasi(lanjut: () => void): () => void {
  const kanal = bukaKanal();
  if (!kanal) return () => {};
  kanal.onmessage = (e: MessageEvent<Pesan>) => {
    if (e.data?.tipe !== "terverifikasi") return;
    kanal.postMessage({ tipe: "diterima" } satisfies Pesan);
    lanjut();
  };
  return () => kanal.close();
}
