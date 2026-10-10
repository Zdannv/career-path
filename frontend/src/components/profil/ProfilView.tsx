"use client";

/**
 * Layar Profile (desain 11 Profile A01–A05).
 *
 * Tiga tab dalam satu layar: Profile (nama, avatar, email), Pendidikan (status
 * studi), dan Notifikasi. Tombol "Simpan Perubahan" menempel di bawah dan baru
 * hidup kalau ada yang benar-benar berubah — tombol yang selalu bisa ditekan
 * membuat orang menekannya untuk memastikan, padahal tidak ada yang tersimpan.
 *
 * Jenjang dan jurusan sengaja tidak bisa diubah di sini: keduanya menentukan
 * seluruh roadmap, dan menggantinya di tengah jalan bukan urusan layar profil.
 * Keduanya tetap ditampilkan, tapi redup — pengguna perlu tahu apa yang
 * tersimpan, sekalipun tidak bisa menggantinya.
 */

import { useCallback, useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  ArrowLeft,
  Box,
  CircleCheck,
  Layers,
  Loader2,
  Medal,
  NotepadText,
  type LucideIcon,
} from "lucide-react";
import Sheet from "@/components/profesi/Sheet";
import { pesanGalat } from "@/lib/quest";
import {
  ambilNotifikasi,
  ambilProfil,
  AVATAR_BAWAAN,
  hapusAvatarLama,
  periksaAvatar,
  simpanPendidikan,
  simpanProfil,
  tandaiNotifikasiDibaca,
  unggahAvatar,
  type JenisNotifikasi,
  type Notifikasi,
  type ProfilState,
} from "@/lib/profil";
import { ROUTES } from "@/lib/routes";

type Tab = "profil" | "pendidikan" | "notifikasi";

// ── potongan tampilan ───────────────────────────────────────────────────────

function Label({ judul, catatan }: { judul: string; catatan: string }) {
  return (
    <>
      <h2 className="text-[15px] font-bold text-slate-900">{judul}</h2>
      <p className="mt-1 text-[13.5px] text-slate-500">{catatan}</p>
    </>
  );
}

/** Kotak isian dengan label kecil di dalamnya, seperti di desain tab Pendidikan. */
function Kotak({
  label,
  kunci = false,
  children,
}: {
  label: string;
  kunci?: boolean;
  children: React.ReactNode;
}) {
  return (
    <div
      className={`rounded-2xl border px-4 py-2.5 ${
        kunci ? "border-slate-100 bg-slate-100" : "border-slate-200 bg-white"
      }`}
    >
      <p className={`text-[11.5px] ${kunci ? "text-slate-400" : "text-slate-500"}`}>{label}</p>
      {children}
    </div>
  );
}

const IKON_NOTIF: Record<JenisNotifikasi, LucideIcon> = {
  QUEST_MINGGUAN: NotepadText,
  BADGE: Medal,
  LEVEL: Layers,
  TAHAP: Box,
};

const LABEL_TAUTAN: Record<JenisNotifikasi, string> = {
  QUEST_MINGGUAN: "Tampilkan Quest",
  BADGE: "Lihat pencapaian",
  LEVEL: "Lihat progress",
  TAHAP: "Buka Journey",
};

// ── layar ───────────────────────────────────────────────────────────────────

export default function ProfilView() {
  const router = useRouter();
  const [tab, setTab] = useState<Tab>("profil");
  const [data, setData] = useState<ProfilState | null>(null);
  const [muat, setMuat] = useState(true);
  const [galat, setGalat] = useState<string | null>(null);
  const [tersimpan, setTersimpan] = useState(false);
  const [menyimpan, setMenyimpan] = useState(false);

  // tab Profile
  const [nama, setNama] = useState("");
  const [avatar, setAvatar] = useState<string | null>(null);
  const [mengunggah, setMengunggah] = useState(false);
  const berkas = useRef<HTMLInputElement>(null);

  // tab Pendidikan
  const [status, setStatus] = useState<"sedang_studi" | "sudah_lulus">("sedang_studi");
  const [kelas, setKelas] = useState<number | null>(null);
  const [semester, setSemester] = useState<number | null>(null);
  const [akhir, setAkhir] = useState(false);

  // tab Notifikasi
  const [notif, setNotif] = useState<Notifikasi[]>([]);
  const [notifSiap, setNotifSiap] = useState(false);

  const pasang = useCallback((p: ProfilState) => {
    setData(p);
    setNama(p.full_name ?? "");
    setAvatar(p.avatar_url);
    setStatus(p.graduation_status ?? "sedang_studi");
    setKelas(p.grade_level);
    setSemester(p.semester);
    setAkhir(p.is_final_semester);
  }, []);

  useEffect(() => {
    let batal = false;
    ambilProfil()
      .then((p) => {
        if (!batal && p) pasang(p);
      })
      .catch(() => {
        if (!batal) setGalat("Gagal memuat profil. Coba muat ulang halaman.");
      })
      .finally(() => {
        if (!batal) setMuat(false);
      });
    return () => {
      batal = true;
    };
  }, [pasang]);

  // Notifikasi diambil saat tabnya dibuka, lalu langsung ditandai terbaca —
  // lencana angka di tab itu berarti "ada yang belum kamu lihat", dan begitu
  // dilihat ia harus hilang.
  useEffect(() => {
    if (tab !== "notifikasi") return;
    let batal = false;
    ambilNotifikasi()
      .then(async (n) => {
        if (batal) return;
        setNotif(n);
        if (n.some((x) => !x.dibaca)) {
          await tandaiNotifikasiDibaca();
          if (!batal) setData((d) => (d ? { ...d, n_notifikasi_baru: 0 } : d));
        }
      })
      .catch(() => {
        if (!batal) setGalat("Gagal memuat notifikasi.");
      })
      .finally(() => {
        if (!batal) setNotifSiap(true);
      });
    return () => {
      batal = true;
    };
  }, [tab]);

  const berubahProfil =
    !!data && (nama.trim() !== (data.full_name ?? "").trim() || avatar !== data.avatar_url);
  const berubahPendidikan =
    !!data &&
    (status !== (data.graduation_status ?? "sedang_studi") ||
      kelas !== data.grade_level ||
      semester !== data.semester ||
      akhir !== data.is_final_semester);
  const bisaSimpan = tab === "profil" ? berubahProfil : tab === "pendidikan" ? berubahPendidikan : false;

  async function pilihBerkas(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f) return;

    const salah = periksaAvatar(f);
    if (salah) {
      setGalat(salah);
      return;
    }

    setGalat(null);
    setMengunggah(true);
    try {
      setAvatar(await unggahAvatar(f));
    } catch (err) {
      setGalat(pesanGalat(err));
    } finally {
      setMengunggah(false);
    }
  }

  // Mengganti status lulus mengubah banyak hal sekaligus: perkiraan durasi
  // roadmap, langkah jalur pendidikan, dan quest yang terbuka (magang, lamaran
  // kerja). Karena itu ia diminta konfirmasi dulu; mengganti kelas atau
  // semester saja tidak.
  const [konfirmasi, setKonfirmasi] = useState(false);
  const statusBerubah =
    tab === "pendidikan" && !!data && status !== (data.graduation_status ?? "sedang_studi");

  function tekanSimpan() {
    if (!data || !bisaSimpan) return;
    if (statusBerubah) setKonfirmasi(true);
    else void simpan();
  }

  async function simpan() {
    if (!data || !bisaSimpan) return;
    setKonfirmasi(false);
    setMenyimpan(true);
    setGalat(null);
    try {
      if (tab === "profil") {
        await simpanProfil(nama, avatar);
        // Berkas lama dibuang setelah profil menunjuk yang baru, bukan
        // sebelumnya: kalau penyimpanan gagal, avatar lama masih dipakai.
        if (data.avatar_url && data.avatar_url !== avatar) {
          void hapusAvatarLama(data.avatar_url);
        }
      } else {
        await simpanPendidikan({
          status,
          kelas: status === "sedang_studi" && data.pakai_kelas ? kelas : null,
          semester: status === "sedang_studi" && !data.pakai_kelas ? semester : null,
          semesterAkhir: status === "sedang_studi" && !data.pakai_kelas ? akhir : false,
        });
      }

      const segar = await ambilProfil();
      if (segar) pasang(segar);
      setTersimpan(true);
      window.setTimeout(() => setTersimpan(false), 4000);
    } catch (err) {
      setGalat(pesanGalat(err));
    } finally {
      setMenyimpan(false);
    }
  }

  function kembali() {
    if (window.history.length > 1) router.back();
    else router.push(ROUTES.explore);
  }

  const TABS: { kode: Tab; label: string; lencana?: number }[] = [
    { kode: "profil", label: "Profile" },
    { kode: "pendidikan", label: "Pendidikan" },
    { kode: "notifikasi", label: "Notifikasi", lencana: data?.n_notifikasi_baru ?? 0 },
  ];

  return (
    <div className="flex min-h-screen flex-col bg-white">
      <header className="sticky top-0 z-20 border-b border-slate-100 bg-white/95 backdrop-blur">
        <div className="mx-auto flex max-w-2xl items-center gap-3 px-4 py-3.5 sm:px-6">
          <button
            type="button"
            onClick={kembali}
            aria-label="Kembali"
            className="-ml-1 rounded-full p-1.5 text-slate-700 transition-colors hover:bg-slate-100"
          >
            <ArrowLeft className="size-5" aria-hidden />
          </button>
          <p className="text-[15px] font-semibold text-slate-900">Profile</p>
        </div>
      </header>

      <main className="mx-auto w-full max-w-2xl flex-1 px-4 pb-8 pt-5 sm:px-6">
        <div role="tablist" aria-label="Bagian profil" className="inline-flex rounded-full bg-slate-100 p-1">
          {TABS.map((t) => {
            const on = t.kode === tab;
            return (
              <button
                key={t.kode}
                type="button"
                role="tab"
                aria-selected={on}
                onClick={() => setTab(t.kode)}
                className={`inline-flex items-center gap-1.5 rounded-full px-4 py-1.5 text-[13.5px] transition-colors ${
                  on ? "bg-white font-semibold text-slate-900 shadow-sm" : "text-slate-600"
                }`}
              >
                {t.label}
                {!!t.lencana && t.lencana > 0 && (
                  <span className="grid size-5 place-items-center rounded-full bg-violet-600 text-[11px] font-semibold text-white">
                    {t.lencana}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {muat ? (
          <div className="flex min-h-[40vh] items-center justify-center" aria-busy>
            <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
          </div>
        ) : !data ? (
          <p className="mt-8 text-center text-[13.5px] text-slate-500">
            Profil belum bisa dibaca. Coba muat ulang halaman.
          </p>
        ) : tab === "profil" ? (
          <section className="mt-6 space-y-6">
            <div>
              <Label judul="Nama Kamu" catatan="Ini akan ditampilkan di samping Avatar Kamu" />
              <input
                type="text"
                value={nama}
                maxLength={60}
                onChange={(e) => setNama(e.target.value)}
                placeholder="Ketik Nama Kamu"
                aria-label="Nama Kamu"
                className="mt-3 w-full rounded-full border border-slate-200 px-4 py-3 text-[14.5px] text-slate-900 outline-none placeholder:text-slate-400 focus:border-violet-400"
              />
            </div>

            <div>
              <Label judul="Avatar" catatan="Ini akan ditampilkan di samping nama Kamu" />
              <div className="mt-3 flex items-center gap-4">
                <Image
                  src={avatar ?? AVATAR_BAWAAN}
                  alt=""
                  width={64}
                  height={64}
                  unoptimized={!!avatar}
                  className="size-16 shrink-0 rounded-full object-cover"
                />

                <div className="min-w-0">
                  <button
                    type="button"
                    onClick={() => berkas.current?.click()}
                    disabled={mengunggah}
                    className="flex items-center gap-2 text-[15px] font-bold text-slate-900 transition-opacity hover:opacity-70 disabled:opacity-60"
                  >
                    {mengunggah && <Loader2 className="size-4 animate-spin" aria-hidden />}
                    Upload Gambar
                  </button>
                  <p className="mt-0.5 text-[13px] text-slate-400">Maksimal 2 MB, PNG atau JPEG</p>
                  {avatar && (
                    <button
                      type="button"
                      onClick={() => setAvatar(null)}
                      className="mt-2 rounded-full border border-rose-200 px-3.5 py-1 text-[12.5px] font-medium text-rose-500 transition-colors hover:bg-rose-50"
                    >
                      Hapus
                    </button>
                  )}
                </div>

                <input
                  ref={berkas}
                  type="file"
                  accept="image/png,image/jpeg"
                  onChange={pilihBerkas}
                  className="hidden"
                />
              </div>
            </div>

            <div>
              <Label judul="Email Akun" catatan="Email yang terdaftar" />
              <input
                type="email"
                value={data.email}
                readOnly
                aria-label="Email akun"
                className="mt-3 w-full rounded-full bg-slate-100 px-4 py-3 text-[14.5px] text-slate-400 outline-none"
              />
            </div>
          </section>
        ) : tab === "pendidikan" ? (
          <section className="mt-6 space-y-4">
            <div>
              <Label judul="Pendidikan Terakhir" catatan="Informasi riwayat pendidikanmu" />
            </div>

            <Kotak label="Jenjang Pendidikan" kunci>
              <p className="text-[14.5px] text-slate-500">{data.level_label ?? "Belum diisi"}</p>
            </Kotak>

            <Kotak label="Jurusan/Program Studi" kunci>
              <p className="text-[14.5px] text-slate-500">{data.study_label ?? "Belum diisi"}</p>
            </Kotak>

            <Kotak label="Status Saat Ini">
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value as typeof status)}
                aria-label="Status saat ini"
                className="w-full bg-transparent text-[14.5px] text-slate-900 outline-none"
              >
                <option value="sedang_studi">Sedang menempuh studi</option>
                <option value="sudah_lulus">Sudah lulus</option>
              </select>
            </Kotak>

            {status === "sedang_studi" &&
              (data.pakai_kelas ? (
                <Kotak label="Kelas Saat ini">
                  <select
                    value={kelas ?? ""}
                    onChange={(e) => setKelas(e.target.value ? Number(e.target.value) : null)}
                    aria-label="Kelas saat ini"
                    className="w-full bg-transparent text-[14.5px] text-slate-900 outline-none"
                  >
                    <option value="">Pilih kelas</option>
                    {(data.level_code === "SMP" ? [7, 8, 9] : [10, 11, 12]).map((k) => (
                      <option key={k} value={k}>
                        Kelas {k}
                      </option>
                    ))}
                  </select>
                </Kotak>
              ) : (
                <>
                  <Kotak label="Semester Saat ini">
                    <select
                      value={semester ?? ""}
                      onChange={(e) => setSemester(e.target.value ? Number(e.target.value) : null)}
                      aria-label="Semester saat ini"
                      className="w-full bg-transparent text-[14.5px] text-slate-900 outline-none"
                    >
                      <option value="">Pilih semester</option>
                      {Array.from({ length: 14 }, (_, i) => i + 1).map((s) => (
                        <option key={s} value={s}>
                          Semester {s}
                        </option>
                      ))}
                    </select>
                  </Kotak>

                  <label className="flex items-center gap-2.5 px-1 text-[13.5px] text-slate-600">
                    <input
                      type="checkbox"
                      checked={akhir}
                      onChange={(e) => setAkhir(e.target.checked)}
                      className="size-4 rounded border-slate-300 accent-violet-600"
                    />
                    Sedang di semester akhir (tinggal tugas akhir)
                  </label>
                </>
              ))}

            <p className="px-1 text-[12.5px] leading-relaxed text-slate-400">
              Jenjang dan jurusan menentukan seluruh roadmap, jadi keduanya tidak bisa diubah dari
              sini.
            </p>
          </section>
        ) : (
          <section className="mt-5">
            {!notifSiap ? (
              <div className="flex min-h-[30vh] items-center justify-center" aria-busy>
                <Loader2 className="size-6 animate-spin text-violet-600" aria-hidden />
              </div>
            ) : notif.length === 0 ? (
              <p className="mt-8 text-center text-[13.5px] text-slate-500">
                Belum ada notifikasi. Selesaikan quest pertamamu untuk mulai mengisinya.
              </p>
            ) : (
              <ul className="space-y-3">
                {notif.map((n) => {
                  const Ikon = IKON_NOTIF[n.kind] ?? NotepadText;
                  return (
                    <li
                      key={n.id}
                      className="flex gap-3.5 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm"
                    >
                      <span className="grid size-9 shrink-0 place-items-center rounded-xl bg-violet-100 text-violet-600">
                        <Ikon className="size-4" aria-hidden />
                      </span>
                      <div className="min-w-0 flex-1">
                        <h3 className="text-[15px] font-semibold text-slate-900">{n.judul}</h3>
                        <p className="mt-1 text-[13.5px] leading-relaxed text-slate-500">{n.isi}</p>
                        {n.link && (
                          <Link
                            href={n.link}
                            className="mt-2.5 inline-block text-[13.5px] font-semibold text-violet-600"
                          >
                            {LABEL_TAUTAN[n.kind]}
                          </Link>
                        )}
                      </div>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>
        )}

        {galat && (
          <p role="alert" className="mt-5 rounded-xl bg-rose-50 px-4 py-3 text-[13px] text-rose-700">
            {galat}
          </p>
        )}
      </main>

      {tab !== "notifikasi" && (
        <div
          className="sticky bottom-0 z-20 bg-white/95 px-4 pb-4 pt-3 backdrop-blur sm:px-6"
          style={{ paddingBottom: "max(1rem, env(safe-area-inset-bottom))" }}
        >
          <div className="mx-auto max-w-2xl">
            {tersimpan && (
              <div
                role="status"
                className="mb-3 flex items-start gap-2.5 rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-sm"
              >
                <CircleCheck className="mt-0.5 size-4 shrink-0 text-emerald-500" aria-hidden />
                <div>
                  <p className="text-[14px] font-semibold text-slate-900">Tersimpan!</p>
                  <p className="text-[13px] text-slate-500">Perubahan data telah berhasil diperbarui.</p>
                </div>
              </div>
            )}

            <button
              type="button"
              onClick={tekanSimpan}
              disabled={!bisaSimpan || menyimpan || mengunggah}
              className="flex w-full items-center justify-center gap-2 rounded-full bg-[#7033FF] py-3.5 text-[15px] font-semibold text-white transition-colors hover:bg-violet-700 disabled:bg-violet-300"
            >
              {menyimpan && <Loader2 className="size-4 animate-spin" aria-hidden />}
              Simpan Perubahan
            </button>
          </div>
        </div>
      )}

      <Sheet
        buka={konfirmasi}
        onTutup={() => setKonfirmasi(false)}
        judul="Ubah status pendidikan?"
        garis={false}
        footer={
          <div
            className="space-y-2.5 px-4 pb-5 pt-2 sm:px-6"
            style={{ paddingBottom: "max(1.25rem, env(safe-area-inset-bottom))" }}
          >
            <button
              type="button"
              onClick={() => void simpan()}
              className="w-full rounded-full bg-[#7033FF] py-3 text-[15px] font-medium text-white transition-colors hover:bg-violet-700"
            >
              Ya, simpan perubahan
            </button>
            <button
              type="button"
              onClick={() => setKonfirmasi(false)}
              className="w-full rounded-full border border-slate-200 bg-white py-3 text-[15px] font-medium text-slate-900 shadow-sm transition-colors hover:bg-slate-50"
            >
              Batalkan
            </button>
          </div>
        }
      >
        <div className="px-4 pb-5 pt-1 sm:px-6">
          <p className="text-[14.5px] leading-relaxed text-slate-600">
            Status Kamu akan diubah menjadi{" "}
            <strong className="font-semibold text-slate-900">
              {status === "sudah_lulus" ? "Sudah lulus" : "Sedang menempuh studi"}
            </strong>
            . Navika akan menghitung ulang roadmap-mu berdasarkan status ini:
          </p>
          <ul className="mt-3 list-disc space-y-1.5 pl-5 text-[13.5px] leading-relaxed text-slate-600">
            <li>Perkiraan waktu menuju profesi pilihanmu</li>
            <li>Status langkah di Jalur Pendidikan</li>
            <li>Quest yang terbuka, seperti praktik magang dan kirim lamaran kerja</li>
          </ul>
          <p className="mt-3 text-[13px] leading-relaxed text-slate-500">
            Quest yang sudah Kamu selesaikan dan XP-mu tidak berubah.
          </p>
        </div>
      </Sheet>
    </div>
  );
}
