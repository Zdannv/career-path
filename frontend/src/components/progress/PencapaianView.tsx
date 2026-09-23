"use client";

/**
 * Layar Pencapaian (desain 10 Progress A02).
 *
 * Seluruh badge ditampilkan sekaligus, yang belum terbuka dalam hitam-putih —
 * bukan disembunyikan. Badge yang terlihat tapi belum didapat itu yang membuat
 * daftar ini berguna: ia memberi tahu apa yang bisa dikejar berikutnya.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { ArrowLeft, Loader2 } from "lucide-react";
import { AppTopNav } from "@/components/explore/AppNav";
import { ambilPencapaian, type Pencapaian } from "@/lib/progress";
import { ROUTES } from "@/lib/routes";

const TAB = [
  { kode: "semua", label: "Semua" },
  { kode: "terkunci", label: "Terkunci" },
  { kode: "selesai", label: "Selesai" },
] as const;

type Tab = (typeof TAB)[number]["kode"];

export default function PencapaianView() {
  const router = useRouter();
  const [semua, setSemua] = useState<Pencapaian[]>([]);
  const [tab, setTab] = useState<Tab>("semua");
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);

  useEffect(() => {
    let batal = false;
    ambilPencapaian()
      .then((d) => {
        if (!batal) setSemua(d);
      })
      .catch(() => {
        if (!batal) setGalat("Gagal memuat pencapaian. Coba muat ulang halaman.");
      })
      .finally(() => {
        if (!batal) setMuat(false);
      });
    return () => {
      batal = true;
    };
  }, []);

  const tampil = semua.filter((p) =>
    tab === "semua" ? true : tab === "selesai" ? p.waktu != null : p.waktu == null,
  );

  function kembali() {
    if (window.history.length > 1) router.back();
    else router.push(ROUTES.progress);
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur lg:top-16">
        <div className="mx-auto flex max-w-2xl items-center gap-3 px-4 py-3 sm:px-6">
          <button
            type="button"
            onClick={kembali}
            aria-label="Kembali"
            className="-ml-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
          >
            <ArrowLeft className="size-5" aria-hidden />
          </button>
          <p className="text-[14.5px] font-semibold text-slate-900">Pencapaian</p>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-12 pt-5 sm:px-6">
        <div
          role="tablist"
          aria-label="Saring pencapaian"
          className="inline-flex rounded-full bg-slate-100 p-1"
        >
          {TAB.map((t) => {
            const on = t.kode === tab;
            return (
              <button
                key={t.kode}
                type="button"
                role="tab"
                aria-selected={on}
                onClick={() => setTab(t.kode)}
                className={`rounded-full px-4 py-1.5 text-[13.5px] transition-colors ${
                  on ? "bg-white font-semibold text-slate-900 shadow-sm" : "text-slate-600"
                }`}
              >
                {t.label}
              </button>
            );
          })}
        </div>

        {galat && (
          <p className="mt-4 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galat}</p>
        )}

        {muat ? (
          <div className="flex min-h-[50vh] items-center justify-center" aria-busy>
            <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
          </div>
        ) : tampil.length === 0 ? (
          <p className="mt-8 text-center text-[13.5px] text-slate-500">
            {tab === "selesai"
              ? "Belum ada badge yang terbuka. Selesaikan quest pertamamu."
              : "Semua badge sudah terbuka 🎉"}
          </p>
        ) : (
          <ul className="mt-5 grid grid-cols-2 gap-x-5 gap-y-8">
            {tampil.map((p) => {
              const terbuka = p.waktu != null;
              return (
                <li key={p.code} className="flex flex-col items-center text-center">
                  <Image
                    src={p.gambar}
                    alt=""
                    width={420}
                    height={480}
                    className={`h-[150px] w-auto ${terbuka ? "" : "opacity-60 grayscale"}`}
                  />
                  <h2
                    className={`mt-2.5 text-[14.5px] font-semibold ${
                      terbuka ? "text-blue-600" : "text-slate-400"
                    }`}
                  >
                    {p.nama}
                  </h2>
                  <p
                    className={`mt-1 text-[13px] leading-snug ${
                      terbuka ? "text-slate-700" : "text-slate-400"
                    }`}
                  >
                    {p.deskripsi}
                  </p>
                </li>
              );
            })}
          </ul>
        )}
      </main>
    </div>
  );
}
