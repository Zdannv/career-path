"use client";

/**
 * Lembar "Yakin Ambil Quest ini?" dan "Selesaikan Quest ini?".
 *
 * Satu komponen untuk keduanya: isinya sama — label, kalimat quest, durasi,
 * XP — yang berbeda judul, tombol utama, dan kolom jawaban.
 *
 * Usability test November 2026 menemukan tiga hal di lembar ini:
 *
 *   - "Bagaimana cara menyelesaikan quest?" Langkahnya sekarang ditulis di
 *     lembar itu sendiri, bukan diandaikan.
 *   - "Kenapa harus mencari sendiri?" Tombol sumber (AI, YouTube, Google)
 *     langsung membuka pencarian yang sudah terisi kalimat quest-nya. Untuk
 *     quest Eksplorasi ada juga tautan ke detail profesi di Navika sendiri.
 *   - "Kenapa cuma copy teks, tidak ada kolom jawaban?" Quest berjenis AMBIL
 *     kini ditutup dengan menulis jawaban (minimal MIN_JAWABAN karakter,
 *     dijaga juga oleh database). Quest LANGSUNG (magang, melamar) boleh
 *     diberi catatan, tidak wajib.
 *
 * Draf jawaban disimpan di localStorage per quest, karena mencari jawaban
 * berarti membuka tab lain dan ponsel kadang memuat ulang halaman yang
 * ditinggal. Pemanggil memberi `key` per quest dan aksi, jadi lembar dipasang
 * ulang untuk tiap quest dan drafnya dibaca saat itu.
 */

import { useState } from "react";
import Link from "next/link";
import { BookOpen, Check, Copy, Loader2 } from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import MetaQuest from "@/components/quest/MetaQuest";
import { MAKS_JAWABAN, MIN_JAWABAN, tautanSumber, type Quest, type QuestGrup } from "@/lib/quest";

export type Aksi = "ambil" | "selesaikan";

const kunciDraf = (key: string) => `navika.jawaban.${key}`;

function bacaDraf(key: string): string {
  try {
    return window.localStorage.getItem(kunciDraf(key)) ?? "";
  } catch {
    return "";
  }
}

function tulisDraf(key: string, isi: string) {
  try {
    if (isi) window.localStorage.setItem(kunciDraf(key), isi);
    else window.localStorage.removeItem(kunciDraf(key));
  } catch {
    // penyimpanan diblokir: draf hanya hidup selama lembar terbuka
  }
}

export function hapusDraf(key: string) {
  tulisDraf(key, "");
}

/** Diberi `key` per quest supaya tanda "Tersalin" tidak terbawa ke quest lain. */
function TombolSalin({ teks }: { teks: string }) {
  const [tersalin, setTersalin] = useState(false);

  async function salin() {
    try {
      await navigator.clipboard.writeText(teks);
      setTersalin(true);
      window.setTimeout(() => setTersalin(false), 2000);
    } catch {
      // Clipboard ditolak (HTTP biasa, izin peramban). Teksnya tetap terlihat
      // dan bisa dipilih manual, jadi tidak perlu pesan galat.
    }
  }

  return (
    <button
      type="button"
      onClick={salin}
      className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3 py-1.5 text-[12.5px] font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50"
    >
      {tersalin ? (
        <Check className="size-3.5 text-emerald-600" aria-hidden />
      ) : (
        <Copy className="size-3.5" aria-hidden />
      )}
      {tersalin ? "Tersalin" : "Copy teks"}
    </button>
  );
}

function IkonAi() {
  return (
    <span
      aria-hidden
      className="grid size-4 place-items-center rounded-full border-[1.5px] border-blue-600 text-[7px] font-bold leading-none text-blue-600"
    >
      AI
    </span>
  );
}

function IkonYoutube() {
  return (
    <svg viewBox="0 0 16 12" className="h-3 w-4" aria-hidden>
      <rect width="16" height="12" rx="3" fill="#FF0000" />
      <path d="M6.4 3.4v5.2L10.6 6z" fill="#fff" />
    </svg>
  );
}

function IkonGoogle() {
  return (
    <svg viewBox="0 0 16 16" className="size-3.5" aria-hidden>
      <path d="M15.7 8.2c0-.6-.1-1.1-.2-1.6H8v3h4.3a3.7 3.7 0 0 1-1.6 2.4v2h2.6c1.5-1.4 2.4-3.4 2.4-5.8z" fill="#4285F4" />
      <path d="M8 16c2.2 0 4-.7 5.3-1.9l-2.6-2c-.7.5-1.6.8-2.7.8-2.1 0-3.9-1.4-4.5-3.3H.8v2.1A8 8 0 0 0 8 16z" fill="#34A853" />
      <path d="M3.5 9.6a4.8 4.8 0 0 1 0-3.1V4.4H.8a8 8 0 0 0 0 7.2l2.7-2z" fill="#FBBC05" />
      <path d="M8 3.2c1.2 0 2.3.4 3.1 1.2l2.3-2.3A8 8 0 0 0 .8 4.4l2.7 2.1C4.1 4.6 5.9 3.2 8 3.2z" fill="#EA4335" />
    </svg>
  );
}

const GAYA_SUMBER =
  "inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3 py-2 text-[12.5px] font-medium text-slate-800 shadow-sm transition-colors hover:bg-slate-50";

/** Tombol sumber yang langsung membuka pencarian berisi kalimat quest. */
export function SumberQuest({ teks, infoHref }: { teks: string; infoHref?: string | null }) {
  const t = tautanSumber(teks);
  return (
    <div>
      <p className="text-[12.5px] font-semibold text-slate-700">Cari jawabannya di sini</p>
      <div className="mt-2 flex flex-wrap gap-2">
        {infoHref && (
          <Link href={infoHref} className={GAYA_SUMBER}>
            <BookOpen className="size-3.5 text-violet-600" aria-hidden />
            Detail profesi di Navika
          </Link>
        )}
        <a href={t.ai} target="_blank" rel="noopener noreferrer" className={GAYA_SUMBER}>
          <IkonAi />
          Tanya AI
        </a>
        <a href={t.youtube} target="_blank" rel="noopener noreferrer" className={GAYA_SUMBER}>
          <IkonYoutube />
          YouTube
        </a>
        <a href={t.google} target="_blank" rel="noopener noreferrer" className={GAYA_SUMBER}>
          <IkonGoogle />
          Google
        </a>
      </div>
    </div>
  );
}

function CaraMengerjakan({ aksi }: { aksi: Aksi }) {
  const langkah = [
    "Ambil quest ini supaya tercatat sedang kamu kerjakan.",
    "Cari jawabannya lewat tombol sumber di bawah. Pertanyaannya sudah terisi otomatis.",
    "Tulis jawabanmu dengan kata-katamu sendiri, lalu tekan Selesaikan Quest.",
  ];
  const aktif = aksi === "ambil" ? 0 : 2;
  return (
    <div className="rounded-2xl bg-slate-50 px-4 py-3.5">
      <p className="text-[12.5px] font-semibold text-slate-700">Cara mengerjakan</p>
      <ol className="mt-2 space-y-1.5">
        {langkah.map((l, i) => (
          <li key={l} className="flex items-start gap-2.5 text-[13px] leading-snug">
            <span
              className={`mt-px grid size-5 shrink-0 place-items-center rounded-full text-[11px] font-bold ${
                i < aktif
                  ? "bg-emerald-500 text-white"
                  : i === aktif
                    ? "bg-violet-600 text-white"
                    : "bg-slate-200 text-slate-500"
              }`}
              aria-hidden
            >
              {i < aktif ? <Check className="size-3" /> : i + 1}
            </span>
            <span className={i === aktif ? "font-medium text-slate-900" : "text-slate-500"}>{l}</span>
          </li>
        ))}
      </ol>
    </div>
  );
}

export default function KonfirmasiQuest({
  quest,
  aksi,
  mode,
  infoHref,
  proses,
  galat,
  onYa,
  onTutup,
}: {
  quest: Quest | null;
  aksi: Aksi;
  mode: QuestGrup["mode"];
  /** Tautan bacaan bawaan Navika untuk quest ini (detail profesi). */
  infoHref?: string | null;
  proses: boolean;
  galat: string | null;
  onYa: (jawaban: string) => void;
  onTutup: () => void;
}) {
  const ambil = aksi === "ambil";
  const tanya = mode === "AMBIL";
  const [jawaban, setJawaban] = useState(() => (quest ? bacaDraf(quest.key) : ""));

  function ubah(isi: string) {
    setJawaban(isi);
    if (quest) tulisDraf(quest.key, isi);
  }

  const panjang = jawaban.trim().length;
  const butuhJawaban = tanya && !ambil;
  const kurang = butuhJawaban && panjang < MIN_JAWABAN;

  return (
    <Sheet
      buka={quest != null}
      onTutup={proses ? () => {} : onTutup}
      judul={ambil ? "Yakin Ambil Quest ini?" : "Selesaikan Quest ini?"}
      garis={false}
      footer={
        <div className="space-y-2.5 border-t border-slate-100 px-4 pb-5 pt-3 sm:px-6" style={{ paddingBottom: "max(1.25rem, env(safe-area-inset-bottom))" }}>
          {galat && (
            <p role="alert" className="rounded-xl bg-rose-50 px-3.5 py-2.5 text-[13px] text-rose-700">
              {galat}
            </p>
          )}
          <button
            type="button"
            onClick={() => onYa(jawaban)}
            disabled={proses || kurang}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-[#7033FF] py-3 text-[15px] font-medium text-white transition-colors hover:bg-violet-700 disabled:bg-violet-300"
          >
            {proses && <Loader2 className="size-4 animate-spin" aria-hidden />}
            {ambil ? "Ambil Quest" : "Selesaikan Quest"}
          </button>
          <button
            type="button"
            onClick={onTutup}
            disabled={proses}
            className="w-full rounded-full border border-slate-200 bg-white py-3 text-[15px] font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50"
          >
            {ambil ? "Batalkan" : "Nanti dulu"}
          </button>
        </div>
      }
    >
      {quest && (
        <div className="space-y-4 px-4 pb-6 pt-1 sm:px-6">
          <div>
            <p className="text-[13px] font-medium text-violet-600">{quest.label}</p>
            <p className="mt-1 text-[20px] leading-snug text-slate-700">{quest.teks}</p>
            <div className="mt-3 flex items-center justify-between gap-3">
              <MetaQuest min={quest.min_menit} max={quest.max_menit} xp={quest.xp} />
              {tanya && <TombolSalin key={quest.key} teks={quest.teks} />}
            </div>
          </div>

          {tanya && <CaraMengerjakan aksi={aksi} />}
          {tanya && <SumberQuest teks={quest.teks} infoHref={infoHref} />}

          {!ambil && (
            <div>
              <label htmlFor={`jawaban-${quest.key}`} className="text-[13px] font-semibold text-slate-900">
                {tanya ? "Jawabanmu" : "Catatan (opsional)"}
              </label>
              <textarea
                id={`jawaban-${quest.key}`}
                value={jawaban}
                onChange={(e) => ubah(e.target.value.slice(0, MAKS_JAWABAN))}
                rows={tanya ? 5 : 3}
                placeholder={
                  tanya
                    ? "Tulis apa yang kamu temukan, dengan kata-katamu sendiri…"
                    : "Misalnya: di mana, posisi apa, atau apa yang kamu pelajari."
                }
                className="mt-1.5 w-full resize-y rounded-2xl border border-slate-200 bg-white px-3.5 py-3 text-[14px] leading-relaxed text-slate-900 outline-none transition-colors placeholder:text-slate-400 focus:border-violet-500"
              />
              {tanya && (
                <p className={`mt-1 text-[12px] ${kurang ? "text-slate-500" : "text-emerald-600"}`}>
                  {kurang
                    ? `Minimal ${MIN_JAWABAN} karakter (${panjang}/${MIN_JAWABAN}).`
                    : "Siap diselesaikan. Jawabanmu tersimpan dan bisa dibaca lagi."}
                </p>
              )}
            </div>
          )}

          {ambil && tanya && (
            <p className="text-[12.5px] leading-relaxed text-slate-500">
              Tidak ada jawaban benar atau salah. Yang penting kamu benar-benar mencari tahu.
            </p>
          )}
        </div>
      )}
    </Sheet>
  );
}
