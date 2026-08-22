# Refactor Navika — catatan kerja

Branch: `refactor/navika-mvp` (dari `master` @ `f871509`)

Repo ini sebelumnya berisi **CareerPath AI**: generator rekomendasi karier sekali
jalan untuk siswa anonim, dengan portal Guru BK berbasis kode kelas. Spec di
Notion sekarang mendeskripsikan produk yang berbeda secara arsitektur — aplikasi
career journey yang stateful, dengan akun, roadmap terstruktur (Stage → Milestone
→ Activity), progress tracking, dan gamifikasi. Prinsipnya "Database First, AI
Second": knowledge base jadi sumber isi roadmap, bukan LLM.

Dokumen ini mencatat apa yang berubah dan kenapa, supaya siapa pun yang membuka
repo ini tidak menebak-nebak.

---

## Fase 0 — amankan & bersihkan (selesai)

### Keamanan

| Masalah | Perbaikan |
|---|---|
| Service-role JWT + URL project ter-hardcode sebagai fallback di `lib/supabaseClient.ts`, ter-commit sejak `3f48c9f` | Fallback dihapus. Client sekarang **throw** kalau env var kosong, dan **throw** kalau key yang diberikan punya `role != "anon"` — supaya service-role key tidak bisa masuk ke bundle browser lagi. |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` di `.env.local` ternyata **berisi service-role key** | Perlu tindakan manual: rotate key di Supabase, isi ulang dengan anon key. Panduan ada di `frontend/.env.example`. |
| Backend tidak memverifikasi JWT sama sekali; `teacher_id` dikirim sebagai query param dari client | `backend/auth.py` baru: `require_user` / `optional_user` memverifikasi Supabase JWT (HS256, aud `authenticated`) via `SUPABASE_JWT_SECRET`. Fail closed kalau secret tidak diset. Endpoint `GET /api/me` untuk mengetes koneksinya. |
| `CORSMiddleware` dengan `allow_origins=["*"]` | Dibaca dari `CORS_ALLOWED_ORIGINS`, default `http://localhost:3000`. Method dan header dibatasi. |
| Tidak ada satu pun RLS policy | `supabase/migrations/0001_enable_rls.sql`. **Belum dijalankan** — perlu dijalankan setelah key dirotasi. |

### Yang dihapus

Dipindahkan ke `_to_delete/` (bukan `rm`, supaya bisa direview dulu sebelum
dihapus permanen):

- `app/jobs/` + `GET /api/jobs/trends` + `MOCK_GIGS` — eksplisit *out of scope* di Notion, datanya juga fiktif
- `app/teacher/` — portal guru lama (kelola kelas, export CSV, AI lesson plan). Spec baru cuma minta monitoring read-only
- `POST|GET /api/teacher/classes`, `GET /api/teacher/summary`, `POST /api/teacher/lesson-plan`, `GET /api/classes/validate`
- `llm_service.generate_lesson_plan()` + fallback markdown hardcoded-nya
- `components/PreChatForm.tsx` (945 baris dead code)
- `migration_classes_table.sql`, `migration_classes_teacher_id.sql` — sistem kode kelas tidak ada di IA baru

Diselamatkan sebelum dihapus: taksonomi `EDUCATION_LEVELS` / `MAJOR_MAP` /
`MAJOR_SKILLS_MAP` → `frontend/src/data/educationTaxonomy.ts`.

`main.py` 1046 → 587 baris. `llm_service.py` 265 → 200 baris.

### Bug yang diperbaiki

- `logger` dipanggil di 4 blok `except` di `main.py` tapi tidak pernah didefinisikan — tiap error handler justru melempar `NameError`. Sekarang `logging` dikonfigurasi di header.
- 20 kelas Tailwind yang tidak ada (`slate-55/150/350/650/750`) di 6 komponen — render tanpa warna. Dipetakan ke shade terdekat yang valid.
- 4 lint error: `catch (err: any)` × 2, `useState<any>` di Navbar (→ `User`), `require("posthog-js")` (→ static import), 3 import lucide yang tidak terpakai.

### Struktur baru

```
supabase/migrations/     0000 legacy KB · 0000b majors · 0001 RLS
backend/auth.py          verifikasi JWT
frontend/.env.example    panduan env (menegaskan: anon key, bukan service_role)
backend/.env.example
frontend/src/data/       taksonomi pendidikan hasil salvage
docs/                    file ini
_to_delete/              kandidat hapus permanen, review dulu
```

### Hasil verifikasi

- `tsc --noEmit` bersih
- `next build` sukses — 4 route: `/`, `/_not-found`, `/student`, `/student/journey/[id]`
- Guard service-role terbukti menggagalkan build saat diberi key `role=service_role`
- `main.py` import bersih, 6 endpoint tersisa
- Smoke test auth: tanpa token / token ngawur / expired / secret salah → 401; token valid → 200
- Endpoint yang dihapus → 404
- Unit test engine 7/8 lolos (1 gagal karena `GROQ_API_KEY` tidak ada di sandbox CI, bukan regresi)

---

## Utang yang sengaja dibiarkan

Bukan lupa — ini keputusan sadar, karena file-file ini dijadwalkan diganti di Fase 2–3
dan memperbaikinya sekarang berarti kerja dua kali.

- **11 lint error** tersisa, semuanya di alur student lama: 7 `no-explicit-any` (bentuk payload API — hilang sendiri saat Fase 1 men-generate type dari schema DB), 4 `react-hooks/set-state-in-effect` + `immutability` di `Dashboard.tsx` dan `CostForecaster.tsx`. Tidak memblokir `next build`.
- **`class_code` masih ada** sebagai field pass-through di `ChatOnboarding` → `save-journey`. Validasinya ke DB sudah dicabut. Field-nya ikut hilang saat onboarding berbasis form menggantikan chat.
- **`save-journey` pakai `optional_user`, bukan `require_user`.** Akun siswa belum ada, jadi mewajibkan token sekarang akan mematikan alur legacy tanpa pengganti. Ada `TODO(fase-2)` di kodenya.
- **Schema drift `user_journeys`** belum direkonsiliasi — ditangani Fase 1 saat schema otoritatif ditulis.

## Berikutnya — Fase 1

Schema otoritatif via Supabase CLI migration: knowledge base (tambah `interests`,
`industries`, `tools`, `certifications`, `roadmap_templates` + stage/milestone/activity)
dan user state (`profiles`, `user_career_goals`, `user_roadmaps`, `user_activities`,
`xp_ledger`, `quests`, `achievements`). Migrasikan `knowledge_base_profesi_IT.xlsx`
secara penuh — termasuk `salary_benchmarks`, `program_studi`, `key_responsibilities`,
`career_path_next` yang selama ini terbuang. Lalu generate TypeScript type dari schema.

Helper `public.apply_owner_rls('nama_tabel')` sudah tersedia di `0001` — panggil sekali
per tabel milik user, jangan tulis empat policy manual tiap kali.

---

## Fase 1a — minat RIASEC (selesai)

Keputusan: dari O*NET **hanya R-I-A-S-E-C yang dipakai**. Work Styles, Work Activities,
Knowledge, dan Abilities tidak diimpor — data selain minat sudah punya sumber sendiri
(scraping LinkedIn untuk skill, `salary_benchmarks` untuk gaji, `education_majors` untuk jurusan).

Sisi profesi tidak diukur, hanya diimpor. Sisi user diukur lewat 18 item Likert.

**Yang dibuat**

| File | Isi |
|---|---|
| `supabase/migrations/0002_riasec.sql` | 1.190 baris. `riasec_types` (6), `onet_occupations` (923), `career_onet_map` (35), view `career_riasec`, `assessment_items` (18), `user_assessment_responses`, `user_riasec_profile`, + RLS |
| `supabase/onet_riasec.csv` | Ekstraksi mentah dari `Career Interest Types.xlsx`, 923 baris |
| `frontend/src/data/onboardingQuestions.ts` | 9 langkah onboarding, seluruh pertanyaan dan opsinya, 18 item RIASEC |
| `frontend/src/lib/riasec.ts` | `computeProfile`, `interestFit`, `weightsFor`, `combinedScore` |

**Catatan penting**

- File RIASEC di O*NET 30.3 adalah **`Career Interest Types.xlsx`**, bukan `Interests.xlsx` — file itu sudah tidak ada sejak versi 30.
- Pemetaan 35 profesi → SOC: 19 high, 14 medium, 2 low. Yang `low` (Product Manager, Scrum Master) perlu ditinjau — O*NET tidak punya padanannya.
- `career_riasec` sengaja dibuat **view**, bukan tabel. Perbaiki pemetaan sekali, seluruh aplikasi ikut terkoreksi.
- Untuk matching pakai kolom `*_raw` (skala 1–7), bukan `*_pct`. Normalisasi persen menghapus perbedaan intensitas minat antar profesi.
- Skoring **memusatkan** kedua vektor sebelum dikorelasikan. Tanpa itu, yang terukur adalah gaya mengisi kuesioner, bukan minat. Sudah diuji: user yang mencentang angka sama untuk semua item mendapat skor rata 50, bukan rekomendasi palsu yang meyakinkan.
- Bobot minat vs skill bergeser per jenjang (SMP 0.90/0.10 → Fresh Grad 0.30/0.70). Ini yang membuat rekomendasi bekerja untuk siswa SMP, yang skor CBF-nya selalu nol karena belum punya satu pun dari 113 skill di knowledge base.
- Lisensi O*NET **CC BY 4.0** — atribusi wajib tampil di aplikasi. Teks atributnya ada di footer `docs/` dan di komentar `0002_riasec.sql`.

**Urutan migration:** `0000` → `0000b` → `0001` → `0002`. Jalankan setelah key Supabase dirotasi.

**Perlu diputuskan tim:** dokumen Notion *Out of Scope* masih melarang "Personality test / IQ test",
dan prompt lama punya "STRICT NON-PSYCHOLOGICAL RULE". Tes minat vokasional bukan tes kepribadian,
tapi barisnya perlu diperjelas supaya desain dan dev tidak berjalan dengan asumsi berbeda.

---

## Fase 1b — perluasan knowledge base ke 9 sektor (selesai)

Dari 35 profesi IT menjadi **477 profesi aktif** di 9 sektor. Pemerintahan & BUMN
dikecualikan atas permintaan (cakupannya terlalu luas untuk dimodelkan).

### Sumber

Seluruh struktur profesi diambil dari **O*NET 30.3** — tidak ada scraping. 559 okupasi
di 9 sektor, masing-masing sudah lengkap dengan RIASEC, skill, knowledge, ability,
work activity, Job Zone, task statement, tools, dan profesi terkait. CC BY 4.0.

### Penamaan

Nama profesi **bukan terjemahan harfiah** O*NET, melainkan istilah yang benar-benar
dipakai di pasar kerja Indonesia. Dikerjakan per sektor lalu dikonsolidasi:

- IT dan kreatif sebagian besar tetap Inggris (`Software Developer`, `UI/UX Designer`) — memang begitu bunyi lowongannya.
- Kesehatan dan pendidikan memakai nomenklatur Indonesia (`Perawat`, `Bidan`, `Apoteker`, `Guru SD`, `Dosen`, `Guru BK`).
- Jenjang sekolah AS dipetakan ke jenjang Indonesia: Elementary → SD, Middle → SMP, Secondary → SMA, Career/Technical Education Secondary → SMK, semua `Postsecondary` → Dosen.
- Nama asli O*NET disimpan di `careers.name_en`; istilah alternatif di `careers.name_alt` untuk pencarian.

Kolom `relevance` (`umum` / `terbatas` / `tidak_relevan`) menandai seberapa nyata profesi
itu di Indonesia. Yang `tidak_relevan` (mis. Nuclear Power Reactor Operators, Physician
Assistants, peran perjudian) **tidak dihapus** tapi `is_active = false`, jadi tidak pernah
muncul di rekomendasi. Kategori sisa O*NET (`..., All Other`) juga dimatikan otomatis —
bukan nama jabatan nyata dan O*NET tidak memberinya skor RIASEC.

**28 baris bertanda "perlu verifikasi" di `curation_note`** — perlu ditinjau manusia:
```sql
select career_name, name_en, relevance, curation_note
from careers where curation_note ilike '%verifikasi%';
```
Review lengkapnya ada di `supabase/careers_review.csv` (554 baris).

### Industri dibuat many-to-many — ini keputusan penting

Sepuluh kategori awal mencampur dua hal: Teknologi Informasi dan Kreatif adalah
**fungsi pekerjaan**, sedangkan Perbankan, Healthcare, FMCG, E-commerce, Energi, dan
Manufaktur adalah **industri**. Satu Data Analyst bekerja di enam-enamnya.

Kalau industri jadi satu kolom di `careers`, profesi itu harus diduplikasi enam kali
dan skill gap-nya jadi kacau. Karena itu ada tabel `industries` (9) + `career_industries`
(636 relasi, **68 profesi tercatat di lebih dari satu industri**). Chip "bidang yang
menarik" di onboarding jadi filter, bukan pengelompokan.

### Gaji sengaja dikosongkan

Profesi baru masuk dengan `salary_min`/`salary_max` NULL, `salary_confidence = 'none'`.
Data gaji O*NET adalah pasar kerja AS dan **tidak boleh** ditampilkan ke siswa Indonesia.
Setiap angka gaji nanti wajib menyebut asalnya lewat `salary_source`. **Jangan tampilkan
rentang gaji saat `salary_confidence = 'none'`.**

35 profesi IT lama tetap membawa gajinya dari scraping LinkedIn, ditandai
`salary_source = 'scraping_linkedin_2025'`, `salary_confidence = 'medium'`.

### Perubahan di 0003 yang memengaruhi 0002

View `career_riasec` diperluas. Versi di `0002` join lewat `career_onet_map` sehingga
hanya mencakup 35 profesi IT — tanpa perbaikan ini, 533 profesi baru tidak akan punya
skor RIASEC sama sekali dan matching minat diam-diam hanya bekerja untuk sektor IT.
Sekarang join langsung ke `careers.soc_code`.

### Verifikasi

Seluruh migration `0000` → `0000b` → `0001` → `0002` → `0003` dijalankan berurutan di
**PostgreSQL 16 lokal** dari database kosong, dengan tiruan `auth.users` dan `auth.uid()`.
Hasil:

| Cek | Hasil |
|---|---|
| Semua migration jalan tanpa error | ✅ |
| careers total | 568 (477 aktif, 91 nonaktif) |
| Profesi aktif tanpa skor RIASEC | **0** |
| Nama tampilan duplikat | **0** |
| Relasi industri | 636 |
| `0003` dijalankan dua kali | tidak ada duplikat ✅ |

Idempotensi dijaga indeks parsial `uq_careers_onet_soc on careers(soc_code) where source='onet'`.

### Sisa pekerjaan yang diketahui

- **`career_description` masih bahasa Inggris** untuk 533 profesi baru — diambil apa adanya dari O*NET. Ini terlihat oleh user di halaman Career Detail dan perlu diterjemahkan.
- Data gaji dan demand Indonesia belum ada (lihat di atas).
- Bobot skill per profesi baru belum ada — `career_skills` masih hanya untuk 35 profesi IT. O*NET punya Essential Skills (10) + Transferable Skills (25) + Software Skills (8.753 tools) yang bisa diimpor untuk menutup ini.
