/**
 * Pita (band) Career Match Score: label dan warnanya.
 *
 * Ambangnya mengikuti tabel match_score_bands: 80–100 Highly Recommended,
 * 50–79 Recommended, 0–49 Explore. Warnanya seperti lampu lalu lintas —
 * hijau, kuning, merah lembut — sama dengan pita Ketahanan AI di tab Insight,
 * jadi satu bahasa warna dipakai di seluruh aplikasi.
 *
 * Sebelumnya tiap komponen mewarnai sendiri: kartu daftar/pencarian dan
 * rekomendasi sub-industri selalu hijau, dan pita tengah berwarna biru,
 * sehingga skor 60% tampak sama baiknya dengan 90%.
 *
 * Pita dihitung dari angka yang DITAMPILKAN (dibulatkan), bukan dari band_code
 * database. band_code memakai skor dua desimal, jadi 79,6 tampil "80%" tetapi
 * berpita Recommended — angka hijau-kuning yang bertentangan di depan mata
 * pengguna. Kalau ambang di match_score_bands diubah, ubah juga di sini.
 */

export type KodeBand = "HIGHLY_RECOMMENDED" | "RECOMMENDED" | "EXPLORE";

export const AMBANG_BAND = { sangat: 80, direkomendasikan: 50 } as const;

/** Pita untuk skor 0–100. Null kalau skornya belum ada (Career DNA belum diisi). */
export function bandDariSkor(skor: number | string | null | undefined): KodeBand | null {
  if (skor == null) return null;
  const n = Math.round(Number(skor));
  if (Number.isNaN(n)) return null;
  if (n >= AMBANG_BAND.sangat) return "HIGHLY_RECOMMENDED";
  if (n >= AMBANG_BAND.direkomendasikan) return "RECOMMENDED";
  return "EXPLORE";
}

export function labelBand(band: string | null): string {
  switch (band) {
    case "HIGHLY_RECOMMENDED":
      return "Sangat Direkomendasikan";
    case "RECOMMENDED":
      return "Direkomendasikan";
    case "EXPLORE":
      return "Belum Direkomendasikan";
    default:
      return "Belum dinilai";
  }
}

/**
 * Kelas Tailwind per pita. `chip` untuk lencana berlatar penuh (kartu),
 * `lembut` + `garis` untuk lencana bergaris (blok skor di detail).
 */
export type NadaBand = { chip: string; lembut: string; garis: string; teks: string };

/** Kelas latar + teks untuk chip angka skor, langsung dari skornya. */
export function kelasChipSkor(skor: number | string | null | undefined): string {
  const n = nadaBand(bandDariSkor(skor));
  return `${n.chip} ${n.teks}`;
}

export function nadaBand(band: string | null): NadaBand {
  switch (band) {
    case "HIGHLY_RECOMMENDED":
      return { chip: "bg-emerald-100", lembut: "bg-emerald-50", garis: "border-emerald-200", teks: "text-emerald-700" };
    case "RECOMMENDED":
      return { chip: "bg-amber-100", lembut: "bg-amber-50", garis: "border-amber-200", teks: "text-amber-700" };
    case "EXPLORE":
      return { chip: "bg-rose-100", lembut: "bg-rose-50", garis: "border-rose-200", teks: "text-rose-700" };
    default:
      return { chip: "bg-slate-100", lembut: "bg-slate-50", garis: "border-slate-200", teks: "text-slate-600" };
  }
}
