"use client";

import React, {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { createPortal } from "react-dom";
import { Search, ChevronsUpDown, Check } from "lucide-react";
import { searchStudyPrograms, type StudyProgram } from "@/lib/education";

export type StudyProgramValue = { id: number | null; label: string | null; custom: boolean };

type Props = {
  value: StudyProgramValue;
  onChange: (v: StudyProgramValue) => void;
  placeholder?: string;
};

/**
 * Prodi yang paling sering dipilih, ditampilkan sebelum user mengetik apa pun.
 *
 * Sengaja konstanta di kode, bukan kolom di database: daftarnya belum
 * didasarkan pada data pemakaian nyata. Begitu ada cukup user, ganti dengan
 * hitungan dari `profiles.study_program_id` supaya benar-benar "terpopuler"
 * dan bukan tebakan.
 */
const POPULAR = [
  "Teknik Informatika",
  "Sistem Informasi",
  "Akuntansi",
  "Kedokteran",
  "Teknik Elektro",
  "Manajemen Pemasaran",
];

/**
 * Pemilih program studi: pemicu combobox yang membuka panel pencarian.
 *
 * Dari `sm` ke atas panel muncul sebagai popover menempel di pemicu; di layar
 * kecil ia naik sebagai bottom sheet dengan latar gelap. Dua-duanya memakai
 * daftar yang sama persis — yang berubah cuma cara munculnya, sesuai desain.
 *
 * Popover desktop dirender lewat portal ke <body>, bukan sebagai anak pemicu.
 * Sebelumnya ia `absolute` di dalam kartu onboarding, dan kartu itu memakai
 * `lg:overflow-hidden` demi sudut membulatnya — jadi panelnya terpotong persis
 * di tepi kartu dan daftar prodinya nyaris tak terlihat. Portal membuatnya
 * kebal terhadap `overflow` induk mana pun; posisinya dihitung dari letak
 * pemicu, dan ia membalik ke atas kalau ruang di bawah tidak cukup.
 *
 * Daftar di database berisi 243 nama, bukan ~29.000 prodi per kampus dari
 * PDDikti. Jadi user pasti akan menemui prodi yang tidak ada, dan itu bukan
 * kasus tepi: "pakai yang saya ketik" adalah opsi setara, bukan jalan darurat.
 */
/** Letak dan ukuran popover desktop, dihitung dari kotak pemicu. */
type PosisiPopover = { left: number; width: number; top: number; maxHeight: number };

/** Tinggi panel yang diinginkan; dipakai untuk memutuskan buka ke atas atau bawah. */
const TINGGI_IDEAL = 340;
const JARAK = 8;
const TEPI = 12;

export default function StudyProgramCombobox({
  value,
  onChange,
  placeholder = "Pilih program studi",
}: Props) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<StudyProgram[]>([]);
  const [popular, setPopular] = useState<StudyProgram[]>([]);
  const [loading, setLoading] = useState(false);
  const reqId = useRef(0);
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const [posisi, setPosisi] = useState<PosisiPopover | null>(null);

  // Muat daftar terpopuler sekali saat panel pertama dibuka.
  useEffect(() => {
    if (!open || popular.length > 0) return;
    let alive = true;
    Promise.all(POPULAR.map((n) => searchStudyPrograms(n, 1)))
      .then((lists) => {
        if (!alive) return;
        const seen = new Set<number>();
        const found: StudyProgram[] = [];
        for (const l of lists) {
          const hit = l[0];
          if (hit && !seen.has(hit.id)) {
            seen.add(hit.id);
            found.push(hit);
          }
        }
        setPopular(found);
      })
      .catch(() => {
        /* daftar terpopuler bersifat pelengkap; pencarian tetap jalan tanpanya */
      });
    return () => {
      alive = false;
    };
  }, [open, popular.length]);

  useEffect(() => {
    if (!open) return;
    const q = query.trim();
    const id = ++reqId.current;
    const timer = setTimeout(() => {
      if (id !== reqId.current) return;
      if (q.length < 2) {
        setResults([]);
        setLoading(false);
        return;
      }
      setLoading(true);
      searchStudyPrograms(q, 30)
        .then((r) => {
          if (id === reqId.current) setResults(r);
        })
        .catch(() => {
          if (id === reqId.current) setResults([]);
        })
        .finally(() => {
          if (id === reqId.current) setLoading(false);
        });
    }, 250);
    return () => clearTimeout(timer);
  }, [query, open]);

  // Tutup saat klik di luar (hanya relevan untuk mode popover).
  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      const t = e.target as Node;
      // Panel desktop hidup di portal, di luar rootRef — keduanya harus
      // diperiksa, kalau tidak panel menutup sendiri saat diklik.
      if (rootRef.current?.contains(t)) return;
      if (panelRef.current?.contains(t)) return;
      setOpen(false);
    };
    const onEsc = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    document.addEventListener("keydown", onEsc);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("keydown", onEsc);
    };
  }, [open]);

  /**
   * Menghitung letak popover dari kotak pemicu.
   *
   * Dipakai lewat useLayoutEffect supaya panel tidak sempat tergambar di posisi
   * salah lalu melompat. Dihitung ulang saat menggulir atau mengubah ukuran
   * jendela: koordinatnya fixed terhadap viewport, jadi tanpa itu panel akan
   * tertinggal di tempat lamanya.
   */
  const hitungPosisi = useCallback(() => {
    const el = triggerRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const ruangBawah = window.innerHeight - r.bottom - JARAK - TEPI;
    const ruangAtas = r.top - JARAK - TEPI;

    // Buka ke bawah selama muat; kalau tidak, pilih sisi yang lebih lapang.
    const keBawah = ruangBawah >= Math.min(TINGGI_IDEAL, ruangAtas) || ruangBawah >= 240;
    const maxHeight = Math.max(180, Math.min(TINGGI_IDEAL, keBawah ? ruangBawah : ruangAtas));

    setPosisi({
      left: Math.max(TEPI, Math.min(r.left, window.innerWidth - r.width - TEPI)),
      width: r.width,
      top: keBawah ? r.bottom + JARAK : r.top - JARAK - maxHeight,
      maxHeight,
    });
  }, []);

  useLayoutEffect(() => {
    if (!open) {
      setPosisi(null);
      return;
    }
    hitungPosisi();
    // capture: true supaya gulir di dalam kartu ikut tertangkap, bukan cuma
    // gulir halaman.
    window.addEventListener("scroll", hitungPosisi, true);
    window.addEventListener("resize", hitungPosisi);
    return () => {
      window.removeEventListener("scroll", hitungPosisi, true);
      window.removeEventListener("resize", hitungPosisi);
    };
  }, [open, hitungPosisi]);

  /** Hasil pencarian dikelompokkan per rumpun, mengikuti desain. */
  const grouped = useMemo(() => {
    const map = new Map<string, StudyProgram[]>();
    for (const p of results) {
      const key = p.rumpun[0] ?? "Lainnya";
      const list = map.get(key) ?? [];
      list.push(p);
      map.set(key, list);
    }
    return [...map.entries()];
  }, [results]);

  const q = query.trim();
  const exact = results.some((r) => r.name_id.toLowerCase() === q.toLowerCase());
  const canUseCustom = q.length >= 3 && !exact && !loading;

  const pick = (p: StudyProgram) => {
    onChange({ id: p.id, label: p.name_id, custom: false });
    setOpen(false);
    setQuery("");
  };
  const useCustom = () => {
    onChange({ id: null, label: q, custom: true });
    setOpen(false);
    setQuery("");
  };

  const Row = ({ p }: { p: StudyProgram }) => (
    <li>
      <button
        type="button"
        onClick={() => pick(p)}
        className="flex w-full cursor-pointer items-center justify-between gap-3 rounded-lg px-3 py-2.5 text-left text-sm text-slate-900 transition-colors hover:bg-[#EEF2FF]"
      >
        <span className="truncate">{p.name_id}</span>
        {value.id === p.id && <Check className="h-4 w-4 shrink-0 text-[#7033FF]" />}
      </button>
    </li>
  );

  const panel = (maxHeight?: number) => (
    <div
      className="flex max-h-[60vh] flex-col overflow-hidden"
      style={maxHeight ? { maxHeight } : undefined}
    >
      <div className="relative border-b border-slate-100 px-3 py-2.5">
        <Search className="pointer-events-none absolute left-6 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
        <input
          autoFocus
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Cari program studi.."
          className="w-full bg-transparent py-1 pl-8 pr-2 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none"
        />
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto p-2">
        {q.length < 2 && popular.length > 0 && (
          <>
            <p className="px-3 pb-1 pt-2 text-xs text-slate-400">Terpopuler</p>
            <ul>
              {popular.map((p) => (
                <Row key={p.id} p={p} />
              ))}
            </ul>
          </>
        )}

        {q.length >= 2 && loading && (
          <p className="px-3 py-3 text-sm text-slate-400">Mencari…</p>
        )}

        {grouped.map(([rumpun, items]) => (
          <div key={rumpun}>
            <p className="px-3 pb-1 pt-3 text-xs text-slate-400">{rumpun}</p>
            <ul>
              {items.map((p) => (
                <Row key={p.id} p={p} />
              ))}
            </ul>
          </div>
        ))}

        {canUseCustom && (
          <div className="mt-2 border-t border-slate-100 pt-2">
            <button
              type="button"
              onClick={useCustom}
              className="w-full cursor-pointer rounded-lg px-3 py-2.5 text-left text-sm text-[#7033FF] transition-colors hover:bg-[#EEF2FF]"
            >
              Pakai &ldquo;{q}&rdquo; — tidak ada di daftar
            </button>
          </div>
        )}

        {q.length >= 2 && !loading && results.length === 0 && !canUseCustom && (
          <p className="px-3 py-3 text-sm text-slate-400">Tidak ada hasil.</p>
        )}
      </div>
    </div>
  );

  return (
    <div ref={rootRef} className="relative max-w-md">
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="listbox"
        aria-expanded={open}
        className="flex w-full cursor-pointer items-center justify-between gap-3 rounded-full bg-white px-4 py-3 text-left text-sm shadow-sm ring-1 ring-slate-200 transition-colors hover:bg-slate-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7033FF]"
      >
        <span className={value.label ? "truncate text-slate-900" : "truncate text-slate-400"}>
          {value.label ?? placeholder}
        </span>
        <ChevronsUpDown className="h-4 w-4 shrink-0 text-slate-400" />
      </button>

      {value.custom && value.label && (
        <p className="mt-2 px-1 text-xs text-slate-400">Di luar daftar — akan ditinjau admin.</p>
      )}

      {open && (
        <>
          {/* Mobile: bottom sheet berlatar gelap. Sudah fixed, jadi tidak
              terpotong induk mana pun — tidak perlu portal. */}
          <div className="fixed inset-0 z-40 bg-slate-900/60 sm:hidden" aria-hidden />
          <div className="fixed inset-x-0 bottom-0 z-50 rounded-t-2xl bg-white shadow-2xl sm:hidden">
            {panel()}
          </div>

          {/* sm ke atas: popover di portal, diposisikan dari kotak pemicu. */}
          {posisi &&
            typeof document !== "undefined" &&
            createPortal(
              <div
                ref={panelRef}
                role="listbox"
                className="fixed z-[60] hidden overflow-hidden rounded-xl bg-white shadow-lg ring-1 ring-slate-200 sm:block"
                style={{
                  left: posisi.left,
                  top: posisi.top,
                  width: posisi.width,
                  maxHeight: posisi.maxHeight,
                }}
              >
                {panel(posisi.maxHeight)}
              </div>,
              document.body,
            )}
        </>
      )}
    </div>
  );
}
