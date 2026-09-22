"use client";

/**
 * Isi satu grup quest (desain 09 Quest B01 / C01 / D01 / E01).
 *
 * Alur satu quest:
 *
 *   mode AMBIL     Ambil Quest -> lembar konfirmasi -> tombol jadi "Selesaikan"
 *                  -> lembar konfirmasi -> layar sukses -> baris jadi "Selesai"
 *   mode LANGSUNG  Selesaikan -> lembar konfirmasi -> layar sukses
 *
 * Yang boleh ditekan ditentukan database (`bisa`): grup terbuka, level
 * sebelumnya selesai untuk hard skill dan tools, syarat waktu magang, dan
 * seterusnya. Setelah setiap aksi, grup dimuat ulang dari server — status
 * dan kunci level berikutnya tidak ditebak di sini.
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowUpRight, Check, ChevronRight, CircleCheck, Loader2, Lock } from "lucide-react";
import { AppTopNav } from "@/components/explore/AppNav";
import Sheet from "@/components/profesi/Sheet";
import KonfirmasiQuest, { type Aksi } from "@/components/quest/KonfirmasiQuest";
import MetaQuest from "@/components/quest/MetaQuest";
import SuksesQuest from "@/components/quest/SuksesQuest";
import TipsBanner from "@/components/quest/TipsBanner";
import {
  ambilGrup,
  ambilQuest,
  pesanGalat,
  selesaikanQuest,
  type HasilSelesai,
  type Quest,
  type QuestGrup,
} from "@/lib/quest";
import { ROUTES } from "@/lib/routes";

// ── tombol di kanan baris quest ────────────────────────────────────────────

function TombolQuest({
  q,
  mode,
  onAksi,
}: {
  q: Quest;
  mode: QuestGrup["mode"];
  onAksi: (a: Aksi) => void;
}) {
  if (q.status === "SELESAI") {
    return (
      <span className="inline-flex shrink-0 items-center gap-1 rounded-full bg-emerald-500 px-3 py-1.5 text-[12.5px] font-medium text-white">
        <Check className="size-3.5" aria-hidden />
        Selesai
      </span>
    );
  }

  // Sudah diambil, atau quest yang langsung diselesaikan.
  if (q.status === "DIAMBIL" || mode === "LANGSUNG") {
    const bisa = q.status === "DIAMBIL" || q.bisa;
    return (
      <button
        type="button"
        onClick={() => onAksi("selesaikan")}
        disabled={!bisa}
        className="inline-flex shrink-0 items-center gap-1.5 rounded-full bg-[#7033FF] px-3.5 py-1.5 text-[12.5px] font-medium text-white transition-colors hover:bg-violet-700 disabled:bg-violet-200"
      >
        <CircleCheck className="size-4" aria-hidden />
        Selesaikan
      </button>
    );
  }

  return (
    <button
      type="button"
      onClick={() => onAksi("ambil")}
      disabled={!q.bisa}
      title={q.alasan ?? undefined}
      className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3.5 py-1.5 text-[12.5px] font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50 disabled:border-slate-100 disabled:text-slate-300 disabled:shadow-none"
    >
      Ambil Quest
      <ArrowUpRight className="size-3.5" aria-hidden />
    </button>
  );
}

function BarisQuest({
  q,
  mode,
  onAksi,
}: {
  q: Quest;
  mode: QuestGrup["mode"];
  onAksi: (a: Aksi) => void;
}) {
  const selesai = q.status === "SELESAI";
  // Alasan kunci ditulis di bawah baris hanya untuk syarat yang tidak
  // tertebak dari urutan (waktu magang, jenjang untuk melamar). Kunci urutan
  // level sudah jelas dari tombol level sebelumnya.
  const tampilAlasan = !selesai && !q.bisa && q.alasan && mode === "LANGSUNG";
  return (
    <li className="border-b border-slate-200 bg-[#FAFAFA] px-3 py-4">
      <p className={`text-[12.5px] font-medium ${selesai ? "text-violet-300" : "text-violet-600"}`}>
        {q.label}
      </p>
      <p
        className={`mt-1 text-[17px] leading-relaxed ${selesai ? "text-slate-400" : "text-slate-600"}`}
      >
        {q.teks}
      </p>
      <div className="mt-2.5 flex items-center justify-between gap-3">
        <MetaQuest min={q.min_menit} max={q.max_menit} xp={q.xp} redup={selesai} />
        <TombolQuest q={q} mode={mode} onAksi={onAksi} />
      </div>
      {tampilAlasan && (
        <p className="mt-2 flex items-center gap-1.5 text-[12.5px] text-slate-500">
          <Lock className="size-3.5 shrink-0" aria-hidden />
          {q.alasan}
        </p>
      )}
    </li>
  );
}

// ── layar ──────────────────────────────────────────────────────────────────

export default function QuestGrupView({ slug, kode }: { slug: string; kode: string }) {
  const router = useRouter();
  const [grup, setGrup] = useState<QuestGrup | null>(null);
  const [muat, setMuat] = useState(true);
  const [galatMuat, setGalatMuat] = useState<string | null>(null);

  const [pilih, setPilih] = useState<{ q: Quest; aksi: Aksi } | null>(null);
  const [proses, setProses] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);
  const [hasil, setHasil] = useState<HasilSelesai | null>(null);
  const [tujuanBuka, setTujuanBuka] = useState(false);

  useEffect(() => {
    let batal = false;
    ambilGrup(slug, kode)
      .then((g) => {
        if (!batal) setGrup(g);
      })
      .catch(() => {
        if (!batal) setGalatMuat("Gagal memuat quest. Coba muat ulang halaman.");
      })
      .finally(() => {
        if (!batal) setMuat(false);
      });
    return () => {
      batal = true;
    };
  }, [slug, kode]);

  /** Setelah ambil/selesaikan: status dan kunci level berikutnya dari server. */
  async function muatUlang() {
    try {
      setGrup(await ambilGrup(slug, kode));
    } catch {
      // Aksinya sudah tersimpan; daftar yang basi diperbaiki saat halaman
      // dibuka lagi. Tidak perlu membatalkan layar sukses karena ini.
    }
  }

  function buka(q: Quest, aksi: Aksi) {
    setGalat(null);
    setPilih({ q, aksi });
  }

  async function konfirmasi() {
    if (!pilih) return;
    setProses(true);
    setGalat(null);
    try {
      if (pilih.aksi === "ambil") {
        await ambilQuest(pilih.q.key);
      } else {
        setHasil(await selesaikanQuest(pilih.q.key));
      }
      setPilih(null);
      await muatUlang();
    } catch (e) {
      setGalat(pesanGalat(e));
    } finally {
      setProses(false);
    }
  }

  const tutupSukses = useCallback(() => setHasil(null), []);

  function kembali() {
    // Masuk langsung lewat tautan: tidak ada riwayat untuk dimundurkan.
    if (window.history.length > 1) router.back();
    else router.push(ROUTES.quest);
  }

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <AppTopNav />

      <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur lg:top-16">
        <div className="mx-auto flex max-w-2xl items-start gap-3 px-4 py-3 sm:px-6">
          <button
            type="button"
            onClick={kembali}
            aria-label="Kembali"
            className="-ml-1 mt-0.5 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
          >
            <ArrowLeft className="size-5" aria-hidden />
          </button>
          <div className="min-w-0 flex-1 py-1 leading-tight">
            <p className="text-[14.5px] font-semibold text-slate-900">
              {grup?.judul ?? (muat ? "Memuat quest…" : "Quest")}
            </p>
            {grup && grup.jenis !== "HARD_SKILL" && (
              <p className="mt-0.5 text-[12px] text-slate-400">
                {grup.subjudul ? `(Sub-skills) ${grup.subjudul}` : grup.label}
              </p>
            )}
          </div>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-10 pt-5 sm:px-6">
        {galatMuat && (
          <p className="rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">{galatMuat}</p>
        )}

        {muat ? (
          <div className="flex min-h-[50vh] items-center justify-center" aria-busy>
            <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
          </div>
        ) : !grup ? (
          !galatMuat && (
            <div className="mt-6 rounded-2xl border border-slate-200 px-5 py-8 text-center">
              <h2 className="text-[16px] font-bold text-slate-900">Quest tidak ditemukan</h2>
              <p className="mx-auto mt-2 max-w-sm text-[13.5px] leading-relaxed text-slate-500">
                Quest ini bukan bagian dari profesi pilihanmu saat ini.
              </p>
              <Link
                href={ROUTES.quest}
                className="mt-4 inline-flex rounded-full bg-violet-600 px-5 py-2.5 text-[13.5px] font-semibold text-white transition-colors hover:bg-violet-700"
              >
                Kembali ke Quest
              </Link>
            </div>
          )
        ) : (
          <>
            <TipsBanner tips={grup.tips} besar={grup.tips.gambar === "RESOURCE"} />

            {!grup.terbuka && grup.alasan_kunci && (
              <p className="mt-4 flex items-start gap-2 rounded-xl bg-slate-100 px-4 py-3 text-[13px] text-slate-600">
                <Lock className="mt-0.5 size-4 shrink-0" aria-hidden />
                {grup.alasan_kunci}
              </p>
            )}

            <ul className="mt-5">
              {grup.quest.map((q) => (
                <BarisQuest key={q.key} q={q} mode={grup.mode} onAksi={(a) => buka(q, a)} />
              ))}
            </ul>

            {grup.tujuan && grup.tujuan.length > 0 && (
              <button
                type="button"
                onClick={() => setTujuanBuka(true)}
                className="mt-6 flex w-full items-center gap-3 rounded-2xl bg-slate-100 px-4 py-3.5 text-left transition-colors hover:bg-slate-200/70"
              >
                <span className="min-w-0 flex-1">
                  <span className="block text-[12px] text-slate-500">Tujuan Quest</span>
                  <span className="block text-[14px] font-semibold text-slate-900">
                    Apa yang Kamu dapat dari Quest ini?
                  </span>
                </span>
                <ChevronRight className="size-5 shrink-0 text-slate-700" aria-hidden />
              </button>
            )}

            {grup.catatan && (
              <aside className="mt-6 border-l-[6px] border-blue-600 bg-[#EEEAFE] px-4 py-3.5">
                <p className="text-[13.5px] font-bold text-slate-900">Catatan:</p>
                <p className="mt-0.5 text-[13px] leading-relaxed text-slate-700">{grup.catatan}</p>
              </aside>
            )}
          </>
        )}
      </main>

      <KonfirmasiQuest
        quest={pilih?.q ?? null}
        aksi={pilih?.aksi ?? "ambil"}
        bisaSalin={grup?.mode === "AMBIL"}
        proses={proses}
        galat={galat}
        onYa={konfirmasi}
        onTutup={() => setPilih(null)}
      />

      <Sheet buka={tujuanBuka} onTutup={() => setTujuanBuka(false)} judul="Tujuan Quest" garis={false}>
        <div className="px-4 pb-8 pt-1 sm:px-6">
          <p className="text-[14.5px] leading-relaxed text-slate-800">
            Apa yang akan Kamu pelajari dari quest yang diberikan Navika?
          </p>
          <ul className="mt-4 space-y-3">
            {grup?.tujuan?.map((t) => (
              <li key={t} className="flex items-center gap-2.5 text-[14.5px] text-slate-900">
                <Check className="size-4 shrink-0" aria-hidden />
                {t}
              </li>
            ))}
          </ul>
        </div>
      </Sheet>

      <SuksesQuest hasil={hasil} onTutup={tutupSukses} />
    </div>
  );
}
