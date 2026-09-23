/**
 * Kartu total progress.
 *
 * Ilustrasinya berwarna sebanyak progres yang sudah dicapai dan hitam-putih
 * sisanya — cara yang diminta desain: dua salinan gambar yang sama ditumpuk,
 * yang bawah `grayscale(100%)`, yang atas dipotong selebar persen progres.
 *
 * Yang dipotong wadahnya, bukan gambarnya: `w-[N%]` pada pembungkus ber-
 * overflow-hidden sementara gambar di dalamnya tetap selebar kartu. Kalau
 * gambarnya sendiri yang dipersempit, ia ikut menyusut dan kedua lapisan tidak
 * lagi bertumpuk pas.
 */

import Image from "next/image";

const SRC = "/progress/hero.jpg";

export default function HeroProgress({ persen }: { persen: number }) {
  const p = Math.max(0, Math.min(100, persen));
  return (
    <section
      className="flex h-[122px] overflow-hidden rounded-2xl bg-white shadow-sm"
      aria-label={`Total progress ${p} persen`}
    >
      <div className="relative min-w-0 flex-1">
        <Image
          src={SRC}
          alt=""
          width={1088}
          height={612}
          priority
          className="absolute inset-0 size-full object-cover object-left grayscale"
        />
        {/* Lapisan berwarna, selebar progres. */}
        <div className="absolute inset-y-0 left-0 overflow-hidden" style={{ width: `${p}%` }}>
          <Image
            src={SRC}
            alt=""
            width={1088}
            height={612}
            priority
            aria-hidden
            className="absolute inset-y-0 left-0 h-full w-[var(--lebar)] max-w-none object-cover object-left"
            style={{ "--lebar": `${p > 0 ? (100 / p) * 100 : 100}%` } as React.CSSProperties}
          />
        </div>
      </div>

      <div className="flex w-[118px] shrink-0 flex-col items-center justify-center rounded-2xl bg-[#7033FF] text-white">
        <p className="text-[30px] font-bold leading-none tracking-tight">
          {p}
          <span className="text-[17px] font-semibold">%</span>
        </p>
        <p className="mt-1.5 text-[11.5px] text-violet-100">Total Progress</p>
      </div>
    </section>
  );
}
