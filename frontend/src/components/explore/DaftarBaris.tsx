"use client";

/**
 * Daftar lengkap satu baris Explore — tujuan tombol panah di kepala tiap baris.
 *
 * Isinya diambil dari RPC yang sama dengan baris di Explore, hanya dengan
 * batas yang lebih longgar, supaya urutan di sini selalu melanjutkan urutan
 * yang sudah dilihat pengguna di deretan kartunya.
 */

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowRight, Loader2 } from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import KartuHasil from "@/components/profesi/KartuHasil";
import {
  getByActivity,
  getByMatch,
  getByStudy,
  getTopDemand,
  type CareerCard,
  type ScoredCard,
} from "@/lib/explore";
import type { KartuProfesi } from "@/lib/careerDetail";
import { ROUTES } from "@/lib/routes";

/** Cukup untuk menampung seluruh isi baris tanpa paginasi. */
const BATAS = 60;

type Baris = {
  judul: string;
  keterangan: string;
  ambil: () => Promise<(CareerCard | ScoredCard)[]>;
  /** Ditampilkan kalau barisnya kosong, beserta ke mana pengguna diarahkan. */
  kosong: { teks: string; ajakan: string; href: string };
};

export const BARIS: Record<string, Baris> = {
  "paling-diminati": {
    judul: "Paling Diminati tahun ini",
    keterangan: "Profesi dengan permintaan pasar tertinggi, diurutkan dari yang paling dicari.",
    ambil: () => getTopDemand(BATAS),
    kosong: {
      teks: "Data permintaan pasar belum tersedia.",
      ajakan: "Cari profesi",
      href: ROUTES.exploreCari,
    },
  },
  "program-studi": {
    judul: "Relevan dengan Program Studi",
    keterangan: "Profesi yang sejalan dengan program studi di profilmu.",
    ambil: () => getByStudy(BATAS),
    kosong: {
      teks: "Program studimu belum terisi di profil, jadi belum ada profesi yang bisa dicocokkan.",
      ajakan: "Lengkapi profil",
      href: ROUTES.profil,
    },
  },
  match: {
    judul: "Persentase Match Profesi",
    keterangan: "Diurutkan dari tingkat kecocokan tertinggi dengan Career DNA-mu.",
    ambil: () => getByMatch(BATAS),
    kosong: {
      teks: "Career DNA-mu belum terisi, jadi skor kecocokan belum bisa dihitung.",
      ajakan: "Isi Career DNA",
      href: ROUTES.careerDna,
    },
  },
  aktivitas: {
    judul: "Dari Aktivitas Pilihan",
    keterangan: "Profesi yang paling banyak memuat aktivitas pilihanmu di Career DNA.",
    ambil: () => getByActivity(BATAS),
    kosong: {
      teks: "Belum ada aktivitas yang kamu pilih di Career DNA.",
      ajakan: "Isi Career DNA",
      href: ROUTES.careerDna,
    },
  },
};

/** Kartu baris Explore membawa kolom yang sama; hanya skornya yang opsional. */
function keKartu(c: CareerCard | ScoredCard): KartuProfesi {
  const skor = "match_score" in c ? c : null;
  return {
    career_id: c.career_id,
    career_name: c.career_name,
    career_description: c.career_description,
    sub_industry: c.sub_industry,
    industry_code: c.industry_code,
    sub_industry_extra: c.sub_industry_extra,
    demand_score: c.demand_score,
    demand_label: c.demand_label,
    salary_min: c.salary_min,
    salary_max: c.salary_max,
    match_score: skor?.match_score ?? null,
    band_code: skor?.band_code ?? null,
  };
}

export default function DaftarBaris({ slug }: { slug: string }) {
  const router = useRouter();
  const baris = BARIS[slug];
  const [kartu, setKartu] = useState<KartuProfesi[] | null>(null);
  const [galat, setGalat] = useState(false);

  useEffect(() => {
    if (!baris) return;
    let batal = false;
    baris
      .ambil()
      .then((d) => {
        if (!batal) setKartu(d.map(keKartu));
      })
      .catch(() => {
        if (!batal) setGalat(true);
      });
    return () => {
      batal = true;
    };
  }, [baris]);

  function kembali() {
    if (window.history.length > 1) router.back();
    else router.push(ROUTES.explore);
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur lg:top-16">
        <div className="mx-auto flex max-w-3xl items-center gap-3 px-4 py-3 sm:px-6">
          <button
            type="button"
            onClick={kembali}
            aria-label="Kembali"
            className="-ml-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
          >
            <ArrowLeft className="size-5" aria-hidden />
          </button>
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate text-[14px] font-semibold text-slate-900">
              {baris?.judul ?? "Daftar Profesi"}
            </p>
            {kartu && kartu.length > 0 && (
              <p className="truncate text-[12px] text-slate-400">{kartu.length} profesi</p>
            )}
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-3xl flex-1 px-4 pb-10 pt-5 sm:px-6">
        {!baris ? (
          <Kosong
            teks="Daftar ini tidak ditemukan."
            ajakan="Kembali ke Explore"
            href={ROUTES.explore}
          />
        ) : galat ? (
          <p className="rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">
            Gagal memuat daftar profesi. Coba muat ulang halaman.
          </p>
        ) : kartu === null ? (
          <div className="flex min-h-[50vh] items-center justify-center" aria-busy>
            <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
          </div>
        ) : kartu.length === 0 ? (
          <Kosong {...baris.kosong} />
        ) : (
          <>
            <p className="text-[13px] leading-relaxed text-slate-500">{baris.keterangan}</p>
            <ul className="mt-4 flex flex-col gap-3">
              {kartu.map((k) => (
                <KartuHasil key={k.career_id} kartu={k} />
              ))}
            </ul>
          </>
        )}
      </main>

      <AppBottomNav />
    </div>
  );
}

function Kosong({ teks, ajakan, href }: { teks: string; ajakan: string; href: string }) {
  return (
    <div className="flex min-h-[45vh] flex-col items-center justify-center gap-4 text-center">
      <p className="max-w-sm text-[13.5px] leading-relaxed text-slate-500">{teks}</p>
      <Link
        href={href}
        className="inline-flex items-center gap-2 rounded-full bg-violet-600 px-5 py-2.5 text-[13px] font-semibold text-white transition-colors hover:bg-violet-700"
      >
        {ajakan}
        <ArrowRight className="size-4" aria-hidden />
      </Link>
    </div>
  );
}
