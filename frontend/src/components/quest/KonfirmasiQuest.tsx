"use client";

/**
 * Lembar "Yakin Ambil Quest ini?" dan "Selesaikan Quest ini?".
 *
 * Satu komponen untuk keduanya: isinya sama — label, kalimat quest, durasi,
 * XP — yang berbeda hanya judul dan tombol utamanya.
 *
 * "Copy teks" menyalin kalimat quest supaya bisa langsung ditempel ke AI chat
 * atau kolom pencarian; itu cara mengerjakan yang dianjurkan banner tips.
 * Quest yang langsung diselesaikan (magang, lamaran) tidak punya tombol ini:
 * kalimatnya ajakan berbuat, bukan pertanyaan untuk dicari jawabannya.
 */

import { useState } from "react";
import { Check, Copy, Loader2 } from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import MetaQuest from "@/components/quest/MetaQuest";
import type { Quest } from "@/lib/quest";

export type Aksi = "ambil" | "selesaikan";

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

export default function KonfirmasiQuest({
  quest,
  aksi,
  bisaSalin,
  proses,
  galat,
  onYa,
  onTutup,
}: {
  quest: Quest | null;
  aksi: Aksi;
  bisaSalin: boolean;
  proses: boolean;
  galat: string | null;
  onYa: () => void;
  onTutup: () => void;
}) {
  const ambil = aksi === "ambil";

  return (
    <Sheet
      buka={quest != null}
      onTutup={proses ? () => {} : onTutup}
      judul={ambil ? "Yakin Ambil Quest ini?" : "Selesaikan Quest ini?"}
      garis={false}
      footer={
        <div className="space-y-2.5 px-4 pb-5 pt-2 sm:px-6" style={{ paddingBottom: "max(1.25rem, env(safe-area-inset-bottom))" }}>
          {galat && (
            <p role="alert" className="rounded-xl bg-rose-50 px-3.5 py-2.5 text-[13px] text-rose-700">
              {galat}
            </p>
          )}
          <button
            type="button"
            onClick={onYa}
            disabled={proses}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-[#7033FF] py-3 text-[15px] font-medium text-white transition-colors hover:bg-violet-700 disabled:opacity-70"
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
            Batalkan
          </button>
        </div>
      }
    >
      {quest && (
        <div className="px-4 pb-6 pt-1 sm:px-6">
          <p className="text-[13px] font-medium text-violet-600">{quest.label}</p>
          <p className="mt-1 text-[22px] leading-snug text-slate-600">{quest.teks}</p>
          <div className="mt-3 flex items-center justify-between gap-3">
            <MetaQuest min={quest.min_menit} max={quest.max_menit} xp={quest.xp} />
            {bisaSalin && <TombolSalin key={quest.key} teks={quest.teks} />}
          </div>
        </div>
      )}
    </Sheet>
  );
}
