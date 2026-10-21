"use client";

import React, { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useSearchParams } from "next/navigation";
import { AlertCircle, ArrowLeft, Loader2, Send, Star } from "lucide-react";
import type { User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";
import { ROUTES } from "@/lib/routes";
import {
  KATEGORI_FEEDBACK,
  PESAN_MAX,
  PESAN_MIN,
  kirimFeedback,
  type KategoriFeedback,
} from "@/lib/feedback";

const PLACEHOLDER: Record<KategoriFeedback, string> = {
  saran: "Fitur apa yang ingin Kamu lihat, atau apa yang bisa dibuat lebih mudah?",
  masalah:
    "Ceritakan apa yang terjadi: halaman mana, apa yang Kamu lakukan, dan apa yang muncul.",
  pertanyaan: "Tulis pertanyaanmu. Kami balas lewat email.",
  hapus_data:
    "Tulis alasan singkat (opsional tapi membantu). Akun dan seluruh datamu akan kami hapus.",
  lainnya: "Tulis pesanmu di sini.",
};

const LABEL_RATING = ["Sangat kecewa", "Kurang puas", "Biasa saja", "Puas", "Sangat puas"];

const EMAIL_VALID = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function isKategori(v: string | null): v is KategoriFeedback {
  return KATEGORI_FEEDBACK.some((k) => k.value === v);
}

function FeedbackForm() {
  const params = useSearchParams();
  const awal = params.get("kategori");

  const [user, setUser] = useState<User | null>(null);
  const [kategori, setKategori] = useState<KategoriFeedback>(isKategori(awal) ? awal : "saran");
  const [rating, setRating] = useState<number | null>(null);
  const [pesan, setPesan] = useState("");
  const [email, setEmail] = useState("");
  const [mencoba, setMencoba] = useState(false);
  const [mengirim, setMengirim] = useState(false);
  const [galat, setGalat] = useState<string | null>(null);
  const [terkirim, setTerkirim] = useState(false);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setUser(data.session?.user ?? null));
  }, []);

  // Penghapusan akun harus datang dari pemilik akun itu sendiri. Pertanyaan
  // butuh alamat balasan; pengguna yang masuk memakai email akunnya.
  const perluMasuk = kategori === "hapus_data" && !user;
  const emailWajib = !user && kategori === "pertanyaan";
  const pakaiRating = kategori === "saran" || kategori === "masalah" || kategori === "lainnya";

  const panjang = pesan.trim().length;
  const galatPesan =
    kategori !== "hapus_data" && panjang < PESAN_MIN
      ? `Tulis minimal ${PESAN_MIN} karakter supaya kami paham maksudnya.`
      : null;
  const galatEmail =
    email.trim() && !EMAIL_VALID.test(email.trim())
      ? "Format email belum benar, contoh: nama@domain.com"
      : emailWajib && !email.trim()
        ? "Isi email supaya kami bisa membalas pertanyaanmu."
        : null;

  const kirim = async (e: React.FormEvent) => {
    e.preventDefault();
    setMencoba(true);
    setGalat(null);
    if (perluMasuk || galatPesan || galatEmail) return;

    setMengirim(true);
    try {
      await kirimFeedback({
        kategori,
        // Permintaan hapus data boleh tanpa alasan; kolomnya tetap butuh
        // minimal 10 karakter, jadi beri keterangan baku.
        pesan:
          kategori === "hapus_data" && panjang < PESAN_MIN
            ? `Permintaan hapus akun dan data. ${pesan.trim()}`.trim()
            : pesan,
        rating: pakaiRating ? rating : null,
        email: user ? null : email,
        halaman: params.get("dari") ?? (document.referrer || null),
      });
      setTerkirim(true);
    } catch (err) {
      setGalat(err instanceof Error ? err.message : "Gagal mengirim. Coba lagi sebentar.");
    } finally {
      setMengirim(false);
    }
  };

  if (terkirim) {
    return (
      <div className="mx-auto flex w-full max-w-md flex-col items-center px-5 py-16 text-center">
        <Image src="/onboarding/done.webp" alt="" width={351} height={390} className="h-auto w-32" />
        <h1 className="mt-6 text-2xl font-bold text-slate-900">Terima kasih!</h1>
        <p className="mt-2 text-sm leading-relaxed text-[#525252]">
          {kategori === "hapus_data"
            ? "Permintaanmu sudah kami terima. Akun dan datamu akan dihapus paling lambat 14 hari kerja, dan kami kabari lewat email."
            : kategori === "pertanyaan"
              ? "Pertanyaanmu sudah kami terima. Balasan akan dikirim ke emailmu."
              : "Masukanmu sudah sampai ke tim Navika dan akan kami baca satu per satu."}
        </p>
        <div className="mt-8 grid w-full grid-cols-2 gap-3">
          <button
            type="button"
            onClick={() => {
              setTerkirim(false);
              setPesan("");
              setRating(null);
              setMencoba(false);
            }}
            className="cursor-pointer rounded-full bg-white py-3 text-sm font-semibold text-slate-900 shadow-sm ring-1 ring-slate-200 hover:bg-slate-50"
          >
            Kirim lagi
          </button>
          <Link
            href={user ? ROUTES.explore : ROUTES.landing}
            className="rounded-full bg-[#7033FF] py-3 text-sm font-semibold text-white hover:bg-[#5f27e6]"
          >
            {user ? "Ke Dashboard" : "Ke Beranda"}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-10 sm:px-6 sm:py-14">
      <Link
        href={ROUTES.bantuan}
        className="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-900"
      >
        <ArrowLeft className="size-4" />
        Pusat Bantuan
      </Link>

      <p className="mt-6 text-sm font-medium text-[#7033FF]">Feedback</p>
      <h1 className="mt-2 text-3xl font-medium tracking-tight text-slate-900 sm:text-4xl">
        Bantu Navika jadi lebih baik
      </h1>
      <p className="mt-3 text-base leading-relaxed text-[#525252]">
        Saran, laporan masalah, atau pertanyaan, semuanya dibaca langsung oleh tim kami.
      </p>

      <form
        onSubmit={kirim}
        noValidate
        className="mt-8 space-y-7 rounded-3xl bg-white p-5 shadow-sm ring-1 ring-slate-200 sm:p-8"
      >
        <fieldset>
          <legend className="text-base font-bold text-slate-900">Jenis masukan</legend>
          <div className="mt-3 flex flex-wrap gap-2.5">
            {KATEGORI_FEEDBACK.map((k) => {
              const aktif = kategori === k.value;
              return (
                <label
                  key={k.value}
                  className={`cursor-pointer select-none rounded-full px-4 py-2 text-sm font-medium ring-1 transition-colors focus-within:outline focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-[#7033FF] ${
                    aktif
                      ? "bg-[#F1EBFF] text-[#7033FF] ring-[#DDD0FF]"
                      : "bg-white text-slate-900 ring-slate-200 hover:bg-slate-50"
                  }`}
                >
                  <input
                    type="radio"
                    name="kategori"
                    value={k.value}
                    checked={aktif}
                    onChange={() => setKategori(k.value)}
                    className="sr-only"
                  />
                  {k.label}
                </label>
              );
            })}
          </div>
        </fieldset>

        {perluMasuk ? (
          <div className="rounded-2xl bg-[#F1EBFF] p-5 text-sm leading-relaxed text-slate-700">
            <p className="font-bold text-slate-900">Masuk dulu ke akun yang ingin dihapus</p>
            <p className="mt-1">
              Supaya tidak ada orang lain yang bisa meminta penghapusan atas namamu, permintaan
              ini hanya bisa dikirim dari akun itu sendiri.
            </p>
            <Link
              href={`${ROUTES.login}?next=${encodeURIComponent(`${ROUTES.feedback}?kategori=hapus_data`)}`}
              className="mt-4 inline-block rounded-full bg-[#7033FF] px-5 py-2.5 font-semibold text-white hover:bg-[#5f27e6]"
            >
              Masuk Akun
            </Link>
          </div>
        ) : (
          <>
            {pakaiRating && (
              <fieldset>
                <legend className="text-base font-bold text-slate-900">
                  Seberapa puas Kamu dengan Navika?{" "}
                  <span className="font-normal text-slate-400">(opsional)</span>
                </legend>
                <div className="mt-3 flex items-center gap-1.5">
                  {LABEL_RATING.map((label, i) => {
                    const n = i + 1;
                    const nyala = rating !== null && n <= rating;
                    return (
                      <button
                        key={n}
                        type="button"
                        onClick={() => setRating(rating === n ? null : n)}
                        aria-label={`${n} dari 5, ${label}`}
                        aria-pressed={rating === n}
                        className="cursor-pointer rounded-lg p-1 transition-transform hover:scale-110 focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#7033FF]"
                      >
                        <Star
                          className={`size-8 ${nyala ? "fill-amber-400 text-amber-400" : "text-slate-300"}`}
                        />
                      </button>
                    );
                  })}
                  <span className="ml-2 text-sm text-[#525252]">
                    {rating ? LABEL_RATING[rating - 1] : ""}
                  </span>
                </div>
              </fieldset>
            )}

            <div>
              <label htmlFor="pesan" className="text-base font-bold text-slate-900">
                {kategori === "hapus_data" ? "Alasan (opsional)" : "Pesan"}
              </label>
              <textarea
                id="pesan"
                value={pesan}
                onChange={(e) => setPesan(e.target.value.slice(0, PESAN_MAX))}
                placeholder={PLACEHOLDER[kategori]}
                rows={6}
                aria-invalid={mencoba && galatPesan ? true : undefined}
                className={`mt-3 w-full resize-y rounded-2xl border bg-white px-4 py-3 text-sm leading-relaxed text-slate-900 outline-none transition-colors placeholder:text-slate-400 ${
                  mencoba && galatPesan
                    ? "border-[#E54B4F]"
                    : "border-slate-200 focus:border-[#7033FF]"
                }`}
              />
              <div className="mt-1.5 flex justify-between gap-4 text-xs">
                <span className="text-[#E54B4F]">{mencoba ? galatPesan : ""}</span>
                <span className="shrink-0 text-slate-400">
                  {pesan.length}/{PESAN_MAX}
                </span>
              </div>
            </div>

            {user ? (
              <p className="rounded-xl bg-slate-50 px-4 py-3 text-sm text-[#525252]">
                Dikirim sebagai <span className="font-semibold text-slate-900">{user.email}</span>.
                Balasan, kalau ada, kami kirim ke email ini.
              </p>
            ) : (
              <div>
                <label htmlFor="email" className="text-base font-bold text-slate-900">
                  Email{" "}
                  {!emailWajib && <span className="font-normal text-slate-400">(opsional)</span>}
                </label>
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nama@email.com"
                  autoComplete="email"
                  className={`mt-3 w-full rounded-full border bg-white px-4 py-2.5 text-sm text-slate-900 outline-none transition-colors placeholder:text-slate-400 ${
                    mencoba && galatEmail
                      ? "border-[#E54B4F]"
                      : "border-slate-200 focus:border-[#7033FF]"
                  }`}
                />
                <p className={`mt-1.5 text-xs ${mencoba && galatEmail ? "text-[#E54B4F]" : "text-slate-400"}`}>
                  {mencoba && galatEmail ? galatEmail : "Isi kalau Kamu ingin kami balas."}
                </p>
              </div>
            )}

            {galat && (
              <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm text-[#E54B4F]">
                <AlertCircle className="mt-0.5 size-4 shrink-0" />
                <span>{galat}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={mengirim}
              className="flex w-full cursor-pointer items-center justify-center gap-2 rounded-full bg-[#7033FF] py-3.5 text-sm font-semibold text-white transition-colors hover:bg-[#5f27e6] disabled:cursor-not-allowed disabled:bg-[#B698FE]"
            >
              {mengirim ? <Loader2 className="size-4 animate-spin" /> : <Send className="size-4" />}
              {mengirim
                ? "Mengirim..."
                : kategori === "hapus_data"
                  ? "Kirim Permintaan Hapus"
                  : "Kirim Masukan"}
            </button>
          </>
        )}
      </form>

      <p className="mt-6 text-center text-xs leading-relaxed text-slate-400">
        Masukan disimpan sesuai{" "}
        <Link href={ROUTES.kebijakanPrivasi} className="text-[#1E69DC]">
          Kebijakan Privasi
        </Link>{" "}
        Navika.
      </p>
    </div>
  );
}

export default function FeedbackPage() {
  return (
    <div className="flex-1 bg-slate-50">
      <Suspense fallback={null}>
        <FeedbackForm />
      </Suspense>
    </div>
  );
}
