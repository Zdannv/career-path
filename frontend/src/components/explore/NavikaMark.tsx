"use client";

/**
 * Lambang "N" Navika sebagai SVG, bukan berkas gambar.
 *
 * Sebelumnya bar atas memakai navika-logo.png berukuran 101x32 piksel — pada
 * layar retina ia diregangkan dan terbaca kabur. Bentuk di bawah ditelusuri
 * dari Vector 1.png kiriman tim desain, lalu digambar ulang sebagai tiga
 * bidang bergaris lurus supaya tajam di ukuran berapa pun.
 *
 * CATATAN: berkas kiriman itu raster 15x20 piksel, bukan vektor, jadi bentuk
 * ini pendekatan yang sangat dekat — bukan salinan persis. Begitu SVG asli dari
 * Figma tersedia, cukup ganti isi <g> di bawah; tidak ada tempat lain yang
 * perlu disentuh.
 */

export default function NavikaMark({ className = "size-7" }: { className?: string }) {
  return (
    <svg viewBox="0 0 15 20" className={className} role="img" aria-label="Navika">
      <g fill="currentColor">
        <path d="M2 0 L5 0 L3 19.5 L0 19.5 Z" />
        <path d="M2.5 0 L5.5 0 L14 19.5 L11 19.5 Z" />
        <path d="M12 5.5 L15 5.5 L13.5 19.5 L10.5 19.5 Z" />
      </g>
    </svg>
  );
}
