/**
 * Busur skor kecocokan.
 *
 * Setengah lingkaran, bukan lingkaran penuh: desain memakai bentuk ini supaya
 * angka besar di tengah punya ruang dan tetap terbaca di layar 360px. Digambar
 * dengan satu path dan stroke-dasharray, jadi tidak ada gambar yang perlu
 * dimuat dan skalanya ikut ukuran teks.
 */

type Props = {
  /** 0-100, atau null kalau Career DNA belum diisi. */
  skor: number | null;
  className?: string;
};

const R = 68;
const TEBAL = 20;
const PANJANG = Math.PI * R; // keliling setengah lingkaran

export default function MatchGauge({ skor, className = "" }: Props) {
  const nilai = skor == null ? 0 : Math.max(0, Math.min(100, Math.round(skor)));
  const terisi = (nilai / 100) * PANJANG;

  return (
    <div className={`relative mx-auto w-[184px] ${className}`}>
      <svg viewBox="0 0 184 100" className="w-full" role="img"
           aria-label={skor == null ? "Skor kecocokan belum tersedia" : `Skor kecocokan ${nilai} persen`}>
        <path
          d={`M ${92 - R} 92 A ${R} ${R} 0 0 1 ${92 + R} 92`}
          fill="none"
          stroke="#E5E7EB"
          strokeWidth={TEBAL}
          strokeLinecap="round"
        />
        {nilai > 0 && (
          <path
            d={`M ${92 - R} 92 A ${R} ${R} 0 0 1 ${92 + R} 92`}
            fill="none"
            stroke="#6D4AFF"
            strokeWidth={TEBAL}
            strokeLinecap="round"
            strokeDasharray={`${terisi} ${PANJANG}`}
          />
        )}
      </svg>
      <div className="pointer-events-none absolute inset-x-0 bottom-1 flex items-baseline justify-center">
        {skor == null ? (
          <span className="text-[15px] font-semibold text-slate-400">Belum dinilai</span>
        ) : (
          <>
            <span className="text-[34px] font-bold leading-none tracking-tight text-slate-900">
              {nilai}
            </span>
            <span className="text-[17px] font-semibold text-slate-900">%</span>
          </>
        )}
      </div>
    </div>
  );
}
