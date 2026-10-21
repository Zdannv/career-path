import React from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { ROUTES } from "@/lib/routes";

export type BagianLegal = { id: string; judul: string; isi: React.ReactNode };

/**
 * Kerangka Syarat Layanan dan Kebijakan Privasi: judul, tanggal berlaku,
 * daftar isi bertaut, lalu bagian bernomor. Daftar isinya menempel di samping
 * dari `lg`; di ponsel ia berada di atas isi.
 */
export default function DokumenLegal({
  judul,
  ringkas,
  berlaku,
  bagian,
}: {
  judul: string;
  ringkas: string;
  berlaku: string;
  bagian: BagianLegal[];
}) {
  return (
    <div className="flex-1 bg-white">
      <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 sm:py-14">
        <Link
          href={ROUTES.landing}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-900"
        >
          <ArrowLeft className="size-4" />
          Beranda
        </Link>

        <h1 className="mt-6 text-3xl font-medium tracking-tight text-slate-900 sm:text-4xl">{judul}</h1>
        <p className="mt-3 max-w-2xl text-base leading-relaxed text-[#525252]">{ringkas}</p>
        <p className="mt-3 text-sm text-slate-400">Berlaku sejak {berlaku}</p>

        <div className="mt-10 lg:grid lg:grid-cols-[220px_minmax(0,1fr)] lg:gap-12">
          <nav aria-label="Daftar isi" className="mb-10 lg:mb-0">
            <div className="rounded-2xl bg-slate-50 p-4 lg:sticky lg:top-24">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">Daftar isi</p>
              <ol className="mt-3 space-y-2 text-sm">
                {bagian.map((b, i) => (
                  <li key={b.id}>
                    <a href={`#${b.id}`} className="text-slate-600 hover:text-[#7033FF]">
                      {i + 1}. {b.judul}
                    </a>
                  </li>
                ))}
              </ol>
            </div>
          </nav>

          <div className="space-y-10">
            {bagian.map((b, i) => (
              <section key={b.id} id={b.id} className="scroll-mt-24">
                <h2 className="text-lg font-bold text-slate-900">
                  {i + 1}. {b.judul}
                </h2>
                <div className="mt-3 space-y-3 text-sm leading-relaxed text-slate-700 [&_li]:ml-5 [&_li]:list-disc [&_li]:pl-1 [&_ul]:space-y-1.5">
                  {b.isi}
                </div>
              </section>
            ))}

            <div className="rounded-2xl bg-[#F1EBFF] p-5 text-sm leading-relaxed text-slate-700">
              Ada pertanyaan tentang dokumen ini? Hubungi kami lewat{" "}
              <Link href={`${ROUTES.feedback}?kategori=pertanyaan`} className="font-semibold text-[#7033FF]">
                halaman Feedback
              </Link>
              .
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
