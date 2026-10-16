"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight, GraduationCap } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { getKampusRelevan, type KampusRelevan } from "@/lib/careerDetail";

/** Contoh profesi di landing. Dicari lewat nama karena id profesi berbentuk
 *  serial dan bisa berbeda antara database lokal dan produksi. */
const CONTOH_PROFESI = [
  "Data Scientist",
  "Dokter Umum",
  "Apoteker",
  "Akuntan / Auditor",
  "Backend Developer",
  "Perawat",
  "Guru SMA",
];

type Profesi = { id: number; nama: string };

export default function KampusRelevanLanding() {
  const [profesi, setProfesi] = useState<Profesi[]>([]);
  const [pilih, setPilih] = useState<number | null>(null);
  const [kampus, setKampus] = useState<Record<number, KampusRelevan[]>>({});

  useEffect(() => {
    supabase
      .from("careers")
      .select("id, career_name")
      .in("career_name", CONTOH_PROFESI)
      .eq("is_active", true)
      .then(({ data }) => {
        const urut = CONTOH_PROFESI.map((n) => data?.find((d) => d.career_name === n))
          .filter((d): d is { id: number; career_name: string } => !!d)
          .map((d) => ({ id: d.id, nama: d.career_name }));
        setProfesi(urut);
        if (urut.length) setPilih(urut[0].id);
      });
  }, []);

  useEffect(() => {
    if (pilih === null || kampus[pilih]) return;
    getKampusRelevan(pilih, 6).then((isi) => setKampus((k) => ({ ...k, [pilih]: isi })));
  }, [pilih, kampus]);

  // Seksi ini pelengkap: kalau datanya belum ada, landing tetap utuh tanpanya.
  if (!profesi.length) return null;

  const daftar = pilih !== null ? kampus[pilih] : undefined;
  const lainnya = daftar?.[0] ? Math.max(daftar[0].n_kampus - daftar.length, 0) : 0;

  // Tanpa jarak bawah: kartu penutup di bawahnya sudah membawa jarak atas sendiri.
  return (
    <section className="bg-white pt-16 sm:pt-20">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <div className="text-xs font-bold uppercase tracking-wide text-indigo-600">Jalur Kuliah</div>
          <h2 className="mt-2 text-2xl sm:text-3xl font-bold text-slate-900">
            Kampus dengan Program Studi Relevan
          </h2>
          <p className="mt-3 text-sm text-slate-500 max-w-2xl mx-auto leading-relaxed">
            Mau jadi apa nanti? Lihat kampus yang membuka program studi untuk profesi itu, diurutkan
            dari akreditasi tertinggi.
          </p>
        </div>

        <div className="mt-8 flex flex-wrap justify-center gap-2">
          {profesi.map((p) => (
            <button
              key={p.id}
              type="button"
              onClick={() => setPilih(p.id)}
              className={`px-4 py-2 rounded-full text-xs font-bold border transition-colors cursor-pointer ${
                p.id === pilih
                  ? "bg-indigo-600 border-indigo-600 text-white"
                  : "bg-white border-slate-200 text-slate-600 hover:border-indigo-300"
              }`}
            >
              {p.nama}
            </button>
          ))}
        </div>

        <div className="mt-8 grid sm:grid-cols-2 lg:grid-cols-3 gap-3 min-h-[9rem]">
          {daftar === undefined
            ? Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="h-[4.5rem] rounded-2xl bg-slate-100 animate-pulse" />
              ))
            : daftar.map((k) => (
                <div key={k.pt_name} className="rounded-2xl border border-slate-200 p-4 flex items-start gap-3">
                  <div className="w-9 h-9 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                    <GraduationCap className="w-4 h-4" />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <div className="font-bold text-sm text-slate-900 truncate">{k.pt_name}</div>
                      {k.negeri && (
                        <span className="shrink-0 px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 text-[10px] font-bold">
                          Negeri
                        </span>
                      )}
                    </div>
                    <div className="mt-0.5 text-xs text-slate-500">
                      {k.prodi} ({k.jenjang}) · Akreditasi {k.akreditasi}
                    </div>
                  </div>
                </div>
              ))}
        </div>

        {daftar !== undefined && daftar.length === 0 && (
          <p className="mt-4 text-center text-sm text-slate-500">Belum ada data kampus untuk profesi ini.</p>
        )}

        <div className="mt-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-400">
          <span>
            {lainnya > 0 && <>dan {lainnya} kampus lain · </>}
            Sumber: direktori akreditasi BAN-PT, diakses 16 Oktober 2026.
          </span>
          {pilih !== null && (
            <Link
              href={`/explore/${pilih}`}
              className="inline-flex items-center gap-1 text-indigo-600 font-bold hover:underline"
            >
              Lihat detail profesi
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          )}
        </div>
      </div>
    </section>
  );
}
