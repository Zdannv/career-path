"use client";

/**
 * Halaman Insight Pertumbuhan Industri (desain Explore A-E01 .. A-E05) dan
 * sheet pemilihnya.
 *
 * Isinya dari lib/insightIndustri. Kartu profesi dicocokkan ke profesi Navika
 * lewat pencarian nama: kalau ketemu, kartunya bisa dibuka dan gaji serta
 * label permintaannya memakai data Navika, supaya angka di sini tidak
 * bertentangan dengan halaman detail profesinya.
 */

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  BadgeDollarSign,
  BarChart3,
  Brain,
  Building,
  Building2,
  CalendarDays,
  ChartNoAxesColumnIncreasing,
  ChevronDown,
  ChevronRight,
  Cloud,
  ConciergeBell,
  DatabaseZap,
  FileSearch,
  FileStack,
  Hotel,
  Landmark,
  Palmtree,
  Repeat2,
  Route as IkonRute,
  Settings2,
  ShieldCheck,
  Sparkles,
  TrendingUp,
  UserPlus,
  UsersRound,
  Wallet,
  X,
  type LucideIcon,
} from "lucide-react";
import { AppBottomNav, AppTopNav } from "@/components/explore/AppNav";
import { formatSalary, searchCareerCards, type CareerCard } from "@/lib/explore";
import { INSIGHT, type IkonInsight, type Insight, type ProfesiInsight } from "@/lib/insightIndustri";
import { ROUTES, profesiPath } from "@/lib/routes";

const IKON: Record<IkonInsight, LucideIcon> = {
  pembayaran: Wallet, bank: Landmark, hotel: Hotel, wisata: Palmtree, makanan: ConciergeBell,
  acara: CalendarDays, bangunan: Building2, kawasan: Building, properti: BadgeDollarSign,
  rute: IkonRute, katalog: FileStack, operasional: Settings2, data: DatabaseZap,
  proyek: Building2, grafik: ChartNoAxesColumnIncreasing, tim: UsersRound, rekrut: UserPlus,
  awan: Cloud, ai: Brain, dokumen: FileSearch, perisai: ShieldCheck, transformasi: Repeat2,
};

export const insightPath = (slug: string) => `${ROUTES.careerInsights}/${slug}`;

// ── Sheet pemilih ──────────────────────────────────────────────────────────

function Sheet({ judul, sub, onTutup, children }: {
  judul: string; sub: string; onTutup: () => void; children: React.ReactNode;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onTutup();
    window.addEventListener("keydown", onKey);
    const lama = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = lama;
    };
  }, [onTutup]);
  return (
    <div className="fixed inset-0 z-[60] flex items-end justify-center bg-slate-900/70 sm:items-center" onClick={onTutup}>
      <div role="dialog" aria-modal="true" aria-label={judul} onClick={(e) => e.stopPropagation()}
        className="w-full rounded-t-3xl bg-[#FDFDFD] px-6 pb-8 pt-6 sm:max-w-md sm:rounded-3xl">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h2 className="text-[18px] font-semibold text-slate-900">{judul}</h2>
            <p className="mt-0.5 text-[14px] text-slate-500">{sub}</p>
          </div>
          <button type="button" onClick={onTutup} aria-label="Tutup" className="rounded-full p-1.5 text-slate-600 hover:bg-slate-100">
            <X className="size-5" aria-hidden />
          </button>
        </div>
        <div className="mt-4">{children}</div>
      </div>
    </div>
  );
}

/** Daftar lima industri. Dipakai di sheet Explore dan pemilih di halaman detail. */
export function DaftarIndustri({ aktif, onPilih }: { aktif?: string; onPilih?: () => void }) {
  return (
    <ul className="divide-y divide-slate-200">
      {INSIGHT.map((i) => (
        <li key={i.slug}>
          <Link href={insightPath(i.slug)} onClick={onPilih}
            className={`flex items-center justify-between gap-3 py-3.5 text-[15px] ${i.slug === aktif ? "font-semibold text-violet-700" : "text-slate-900 hover:text-violet-700"}`}>
            {i.industri}
            <ChevronRight className="size-4 text-slate-400" aria-hidden />
          </Link>
        </li>
      ))}
    </ul>
  );
}

/**
 * Kartu "Insight Industri" di Explore. Menekannya membuka sheet tiga pilihan
 * informasi (desain), lalu "Industri dengan pertumbuhan tercepat" membuka
 * daftar industri.
 */
export function InsightIndustriCard({ className = "" }: { className?: string }) {
  const [layar, setLayar] = useState<null | "menu" | "industri">(null);
  const pilihan = [
    { ikon: TrendingUp, label: "Industri dengan pertumbuhan tercepat", aksi: () => setLayar("industri") },
    { ikon: Sparkles, label: "Keterampilan yang paling dibutuhkan", segera: true },
    { ikon: BarChart3, label: "Profesi yang paling banyak dicari", href: "/explore/daftar/paling-diminati" },
  ];
  return (
    <>
      <button type="button" onClick={() => setLayar("menu")}
        className={`block w-full overflow-hidden rounded-2xl border border-slate-200 bg-white text-left transition-shadow hover:shadow-md ${className}`}>
        <Image src="/insight/teknologi-ai.webp" alt="" width={1400} height={600} className="h-36 w-full object-cover" />
        <span className="block px-4 py-3.5">
          <span className="block text-[15px] font-semibold text-slate-900">Insight Industri</span>
          <span className="mt-0.5 block text-[13px] text-slate-500">Kenali peluang karir dan tren dunia kerja.</span>
        </span>
      </button>

      {layar === "menu" && (
        <Sheet judul="Insight Industri" sub="Pilih informasi di bawah ini" onTutup={() => setLayar(null)}>
          <ul className="divide-y divide-slate-200">
            {pilihan.map(({ ikon: Ikon, label, aksi, href, segera }) => {
              const isi = (
                <>
                  <Ikon className="size-4 shrink-0 text-slate-500" aria-hidden />
                  <span className="flex-1">{label}</span>
                  {segera ? <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[11.5px] text-slate-500">Segera hadir</span>
                    : <ChevronRight className="size-4 text-slate-400" aria-hidden />}
                </>
              );
              const kelas = "flex w-full items-center gap-3 py-3.5 text-left text-[14.5px]";
              return (
                <li key={label}>
                  {href ? <Link href={href} className={`${kelas} text-slate-900 hover:text-violet-700`}>{isi}</Link>
                    : <button type="button" onClick={aksi} disabled={segera}
                        className={`${kelas} ${segera ? "cursor-not-allowed text-slate-400" : "text-slate-900 hover:text-violet-700"}`}>{isi}</button>}
                </li>
              );
            })}
          </ul>
        </Sheet>
      )}
      {layar === "industri" && (
        <Sheet judul="Insight Pertumbuhan Industri" sub="Pilih informasi di bawah ini" onTutup={() => setLayar(null)}>
          <DaftarIndustri onPilih={() => setLayar(null)} />
        </Sheet>
      )}
    </>
  );
}

// ── Halaman detail ─────────────────────────────────────────────────────────

/** Cocokkan nama profesi di desain ke profesi Navika. Null kalau tidak ada yang sepadan. */
async function cocokkan(p: ProfesiInsight): Promise<CareerCard | null> {
  const nama = p.navika ?? p.nama;
  const n = nama.toLowerCase();
  const hasil = await searchCareerCards(nama, 5).catch(() => []);
  return hasil.find((c) => {
    const m = c.career_name.toLowerCase();
    return m === n || m.startsWith(`${n} `) || m.startsWith(`${n} /`) || m.includes(`(${n})`) || n === m.split(" / ")[0];
  }) ?? null;
}

function KartuProfesi({ p, cocok }: { p: ProfesiInsight; cocok: CareerCard | null | undefined }) {
  const gaji = cocok ? formatSalary(cocok.salary_min, cocok.salary_max) : p.gaji;
  const permintaan = cocok?.demand_label ?? "Permintaan tinggi";
  const isi = (
    <>
      <p className="text-[15px] font-medium text-slate-900">{p.nama}</p>
      <p className="mt-1 text-[14px] leading-relaxed text-slate-500">{p.deskripsi}</p>
      <div className="mt-3 flex items-center gap-8 text-[12.5px] text-slate-600">
        <span className="inline-flex items-center gap-1.5"><ChartNoAxesColumnIncreasing className="size-4" aria-hidden /> {permintaan}</span>
        <span className="inline-flex items-center gap-1.5"><Wallet className="size-4" aria-hidden /> {gaji}</span>
      </div>
    </>
  );
  const kelas = "block rounded-2xl border border-slate-200 bg-[#FCFCFC] px-4 py-4";
  return cocok ? (
    <Link href={profesiPath(cocok.career_id)} className={`${kelas} transition-colors hover:border-violet-300`}>{isi}</Link>
  ) : <div className={kelas}>{isi}</div>;
}

function DaftarProfesi({ profesi, cocok }: { profesi: ProfesiInsight[]; cocok: Record<string, CareerCard | null> }) {
  return (
    <>
      <h3 className="mt-5 text-[15px] font-medium text-slate-900">Profesi yang dapat dijelajahi</h3>
      <div className="mt-3 flex flex-col gap-3">
        {profesi.map((p) => <KartuProfesi key={p.nama} p={p} cocok={cocok[p.nama]} />)}
      </div>
    </>
  );
}

function Statistik({ s }: { s: Insight["statistik"] }) {
  if (s.jenis === "angka") {
    return (
      <section className="mt-8">
        <h2 className="text-[15px] font-medium text-slate-900">{s.judul}</h2>
        <dl className="mt-4 flex flex-col gap-4">
          {s.items.map((x) => (
            <div key={x.label} className="border-l border-slate-300 pl-6">
              <dt className="text-[30px] font-medium leading-tight tracking-tight text-slate-900">{x.nilai}</dt>
              <dd className="text-[13px] text-slate-600">{x.label}</dd>
            </div>
          ))}
        </dl>
        <p className="mt-4 text-[12.5px] text-slate-400">Sumber data: {s.sumber}</p>
      </section>
    );
  }
  const maks = Math.max(...s.items.map((x) => x.nilai));
  const warna = ["bg-[#3B82F6]", "bg-[#2563EB]", "bg-[#1D4ED8]"];
  return (
    <section className="mt-8">
      <h2 className="text-[15px] font-medium text-slate-900">{s.judul}</h2>
      {s.catatan && <p className="text-[13px] text-slate-400">{s.catatan}</p>}
      <ul className="mt-4 flex flex-col gap-3">
        {s.items.map((x, i) => (
          <li key={x.label} className="flex items-center gap-3">
            <span className={`flex h-8 min-w-[52px] items-center justify-end rounded-full px-3 text-[13px] font-semibold text-white ${warna[i % warna.length]}`}
              style={{ width: `${Math.max(16, (x.nilai / maks) * 60)}%` }}>
              {x.nilai.toLocaleString("id-ID")}%
            </span>
            <span className="text-[13.5px] text-slate-600">{x.label}</span>
          </li>
        ))}
      </ul>
      <p className="mt-3 text-[12.5px] text-slate-400">Sumber data: {s.sumber}</p>
    </section>
  );
}

export default function InsightView({ data }: { data: Insight }) {
  const router = useRouter();
  const [pilihBuka, setPilihBuka] = useState(false);
  const [cocok, setCocok] = useState<Record<string, CareerCard | null>>({});

  useEffect(() => {
    let hidup = true;
    const semua = [...data.seksi.flatMap((s) => s.profesi), ...(data.profesi ?? [])];
    Promise.all(semua.map(async (p) => [p.nama, await cocokkan(p)] as const)).then((h) => {
      if (hidup) setCocok(Object.fromEntries(h));
    });
    return () => {
      hidup = false;
    };
  }, [data]);

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />
      <header className="sticky top-0 z-20 bg-white/95 px-4 pb-3 pt-3 backdrop-blur sm:px-6 lg:top-16">
        <div className="mx-auto flex max-w-2xl items-center gap-3">
          <button type="button" onClick={() => (window.history.length > 1 ? router.back() : router.push(ROUTES.explore))}
            aria-label="Kembali" className="-ml-1 rounded-full p-1.5 text-slate-800 hover:bg-slate-100">
            <ArrowLeft className="size-5" aria-hidden />
          </button>
          <button type="button" onClick={() => setPilihBuka(true)}
            className="flex flex-1 items-center justify-between gap-3 rounded-full bg-white px-4 py-2 text-left shadow-[0_2px_10px_rgba(15,23,42,0.08)] ring-1 ring-slate-200">
            <span className="min-w-0 leading-tight">
              <span className="block text-[12px] text-slate-400">Insight pertumbuhan industri</span>
              <span className="block truncate text-[14.5px] font-medium text-slate-900">{data.industri}</span>
            </span>
            <ChevronDown className="size-4 shrink-0 text-slate-500" aria-hidden />
          </button>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-12 pt-4 sm:px-6">
        <Image src={data.gambar} alt="" width={1400} height={600} priority className="h-auto w-full rounded-3xl" />
        <h1 className="mt-8 text-[24px] font-medium leading-snug tracking-tight text-slate-900">{data.judul}</h1>
        <p className="mt-2 text-[15px] leading-relaxed text-slate-500">{data.lead}</p>

        <Statistik s={data.statistik} />

        {data.peluang && (
          <section className="mt-8">
            <h2 className="text-[15px] font-medium text-slate-900">Mengapa ini membuka peluang karier?</h2>
            {data.peluang.pengantar.map((t) => (
              <p key={t} className="mt-2 text-[14.5px] leading-relaxed text-slate-800">{t}</p>
            ))}
            <ul className="mt-3 divide-y divide-slate-200">
              {data.peluang.alasan.map(({ ikon, judul, isi }) => {
                const Ikon = IKON[ikon];
                return (
                  <li key={judul} className="flex gap-3 py-3">
                    <Ikon className="mt-0.5 size-5 shrink-0 text-slate-500" aria-hidden />
                    <div>
                      <p className="text-[14.5px] leading-relaxed text-slate-900">{judul}</p>
                      {isi && <p className="text-[14px] leading-relaxed text-slate-500">{isi}</p>}
                    </div>
                  </li>
                );
              })}
            </ul>
          </section>
        )}

        {data.seksi.map((s) => {
          const Ikon = IKON[s.ikon];
          return (
            <section key={s.nama} className="mt-8 border-t border-slate-200 pt-8">
              <div className="flex gap-4">
                <span className="grid size-8 shrink-0 place-items-center rounded-full bg-[#EEF2FF] text-[#2563EB] ring-1 ring-slate-200">
                  <Ikon className="size-4" aria-hidden />
                </span>
                <div>
                  <h2 className="text-[15px] font-medium text-slate-900">{s.nama}</h2>
                  <p className="text-[14px] text-slate-500">{s.cakupan}</p>
                </div>
              </div>
              <p className="mt-3 text-[14.5px] leading-relaxed text-slate-800">{s.isi}</p>
              <DaftarProfesi profesi={s.profesi} cocok={cocok} />
            </section>
          );
        })}

        {data.profesi && (
          <section className="mt-8 border-t border-slate-200 pt-6">
            <DaftarProfesi profesi={data.profesi} cocok={cocok} />
          </section>
        )}
      </main>

      {pilihBuka && (
        <Sheet judul="Insight Pertumbuhan Industri" sub="Pilih informasi di bawah ini" onTutup={() => setPilihBuka(false)}>
          <DaftarIndustri aktif={data.slug} onPilih={() => setPilihBuka(false)} />
        </Sheet>
      )}
      <AppBottomNav />
    </div>
  );
}

/** /career-insights tanpa slug: daftar lima industri dengan gambarnya. */
export function InsightHub() {
  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />
      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-12 pt-6 sm:px-6">
        <Link href={ROUTES.explore} className="inline-flex items-center gap-1.5 text-[14px] text-slate-500 hover:text-slate-900">
          <ArrowLeft className="size-4" aria-hidden /> Explore
        </Link>
        <h1 className="mt-4 text-[22px] font-semibold tracking-tight text-slate-900">Insight Pertumbuhan Industri</h1>
        <p className="mt-1 text-[14px] text-slate-500">Kenali peluang karir dan tren dunia kerja di lima industri.</p>
        <ul className="mt-6 flex flex-col gap-4">
          {INSIGHT.map((i) => (
            <li key={i.slug}>
              <Link href={insightPath(i.slug)} className="block overflow-hidden rounded-2xl border border-slate-200 transition-shadow hover:shadow-md">
                <Image src={i.gambar} alt="" width={1400} height={600} className="h-32 w-full object-cover" />
                <span className="block px-4 py-3">
                  <span className="block text-[15px] font-semibold text-slate-900">{i.industri}</span>
                  <span className="mt-0.5 block text-[13px] leading-snug text-slate-500">{i.judul}</span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </main>
      <AppBottomNav />
    </div>
  );
}
