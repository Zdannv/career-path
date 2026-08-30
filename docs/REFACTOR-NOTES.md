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

---

## Fase 1c — Career DNA (selesai)

Mengikuti spesifikasi baru di `Career path.xlsx` (sheet **Career DNA** dan
**Arsitektur Data Profesi**): 54 atribut dalam 5 layer.

| Layer | Atribut | Dipilih user | Peran |
|---|---:|---:|---|
| Interest DNA | 10 | 3 | main |
| Activity DNA | 12 | 4 | main |
| Skill DNA | 16 | 5 | supporting |
| Environment DNA | 8 | 3 | supporting |
| Work Style DNA | 8 | 2 | supporting |

### Perbedaan penting dari spesifikasi

Spesifikasi menyebut skor DNA per profesi berasal dari **"AI Mapping"**.
Implementasi ini **tidak memakai AI sama sekali** — seluruh 54 atribut diturunkan
secara deterministik dari elemen O*NET yang bisa ditunjuk satu per satu:

| Layer | Sumber O*NET |
|---|---|
| Interest | Specific Interest Areas (41 area) |
| Activity | Work Activities (41 GWA) |
| Skill | Essential Skills + Transferable Skills + Abilities + Work Styles |
| Environment | Work Context + Work Activities + Essential Skills |
| Work Style | Work Styles (21 elemen) |

Pemetaan tiap atribut tersimpan di kolom `dna_attributes.onet_mapping`, jadi setiap
angka bisa ditelusuri asalnya. Hasilnya bisa direproduksi kapan saja:
`python3 supabase/dna/derive_dna.py`. Ini jauh lebih bisa dipertahankan daripada
tagging AI — tidak ada yang perlu dipercaya begitu saja.

### Keputusan metodologis

**Agregasi berbeda per layer, dan ini disengaja.**
- **MAX** untuk Interest & Activity — komponennya adalah *jalur alternatif* menuju
  atribut yang sama. Software developer "membangun" lewat komputer, teknisi lewat
  mesin; keduanya sah. Awalnya dirata-rata dan hasilnya salah: Software Developer
  keluar dengan aktivitas dominan "Operasional & Administrasi".
- **MEAN** untuk Skill, Work Style, Environment — komponennya adalah *faset* dari
  satu konstruk. Komunikasi menuntut bicara DAN mendengar DAN menulis.
  Environment juga: satu sinyal yang kebetulan tinggi (semua profesi banyak rapat)
  tidak boleh cukup untuk menyimpulkan lingkungan kerja. Sempat dipakai MAX dan
  hasilnya rusak — dokter keluar "Sekolah", welder keluar "Laboratorium".

**Normalisasi per atribut lintas okupasi.** Tanpa ini, atribut dengan sedikit
komponen selalu unggul atas atribut dengan banyak komponen yang saling menetralkan.
Gejalanya nyata: Perawat sempat keluar dengan minat dominan "Pendidikan" mengalahkan
"Kesehatan", karena INT_PENDIDIKAN hanya punya 1 area sedangkan INT_KESEHATAN punya 3.

**Dua pengecualian yang ditandai jujur di `dna_source`:**
- `rule` — ENV_REMOTE dan ENV_HYBRID. O*NET tidak punya data kerja remote sama
  sekali (datanya mendahului pola kerja pascapandemi), jadi dihitung dari aturan:
  tinggi di "Working with Computers" + "E-Mail", rendah di "Physical Proximity" dan
  aktivitas fisik.
- `inherited:<soc>` — 38 okupasi baru yang belum disurvei O*NET mewarisi sebagian
  layer dari profesi terkait terdekat. Termasuk **UI/UX Designer** (15-1255.00),
  yang di O*NET hanya punya Interest dan Work Style; Activity dan Environment
  diwarisi dari Web Developers.

### File

| File | Isi |
|---|---|
| `supabase/migrations/0004_career_dna.sql` | Skema, 5 layer, 54 atribut, view `career_dna`, fungsi `career_match_scores()` dan `similar_careers()`, tabel bobot, RLS |
| `supabase/migrations/0004b_onet_dna_data.sql` | 28.044 baris skor DNA untuk 555 okupasi. **Besar (1,5 MB) — jalankan lewat `supabase db push` atau psql, bukan editor SQL di browser** |
| `supabase/dna/derive_dna.py` | Skrip derivasi, bisa dijalankan ulang |
| `supabase/dna/dna_map.py` | Pemetaan 54 atribut → elemen O*NET. **Ubah di sini, bukan di SQL** |
| `supabase/dna/career_dna_raw.csv` | Hasil derivasi lengkap 923 okupasi |

### Verifikasi

Seluruh migration `0000` → `0004b` dijalankan berurutan di PostgreSQL 16 dari
database kosong. 535 profesi aktif punya DNA, **0 profesi aktif tanpa DNA**,
dijalankan dua kali tidak menduplikasi.

Uji tiga persona lewat `career_match_scores()`:

| Persona | Hasil teratas |
|---|---|
| Kreativitas + Teknologi, hybrid | Art Director, Game Developer, **UI/UX Designer** |
| Kesehatan + Sosial, klinis | Dokter Spesialis Jiwa, Dokter Spesialis Anak, Perawat, Bidan |
| Teknologi + lapangan, pabrik | Insinyur Pertambangan, Manajer QA/QC, Teknisi Perawatan Pesawat |

`similar_careers()` untuk UI/UX Designer: Video Editor 94%, Animator/VFX 82%,
Frontend Developer 82%. Untuk Perawat: Bidan 94%, Perawat Vokasi 94%.

Cocok dengan contoh di spreadsheet: Dokter → Kesehatan/Riset/Sosial ✅,
UI/UX Designer → Kreativitas/Teknologi ✅.

### Celah taksonomi yang ditemukan — perlu keputusan tim

1. **Tidak ada Interest DNA untuk kerja teknik/manual/konstruksi.** Padahal
   Manufaktur & Otomotif adalah sektor terbesar (115 profesi aktif) dan paling
   banyak jalurnya untuk siswa SMK. Area O*NET `Construction/Woodwork`,
   `Transportation/Machine Operation`, dan `Physical/Manual Labor` terpaksa
   dimasukkan ke "Teknologi" — yang deskripsinya "Software, AI, komputer".
   **Saran: tambah Interest DNA ke-11, mis. "Teknik & Industri".**
2. **Tidak ada Activity DNA untuk kerja fisik.** Tiga GWA (`Handling and Moving
   Objects`, `Performing General Physical Activities`, `Operating Vehicles`)
   sengaja tidak dipetakan; kalau dipaksa masuk "Membangun & Mengembangkan",
   profesi knowledge work justru tenggelam.
3. **Environment DNA mencampur dua dimensi.** Kantor/Lab/RS/Sekolah/Pabrik adalah
   *tempat*; Remote/Hybrid/Onsite adalah *pengaturan kerja*. Keduanya ortogonal —
   perawat bekerja di RS *dan* onsite. Sekarang user memilih 3 dari campuran itu.
   **Saran: pisah jadi dua dimensi.**
4. **Skill DNA punya pasangan yang nyaris kembar:** "Logika & Analisa" vs
   "Critical Thinking", "Perencanaan & Organisasi" vs "Manajemen Waktu".
   Keduanya hampir selalu naik-turun bersama, jadi memakan jatah pilihan user
   tanpa menambah informasi.
5. **Sheet "Career Matching Score" masih kosong** — rumusnya belum ditentukan.
   Sementara dipakai rata-rata tertimbang per layer (Interest 30%, Activity 30%,
   Skill 20%, Environment 10%, Work Style 10%), disimpan di tabel
   `dna_layer_weights` supaya bisa disetel tanpa ubah kode.

---

## Fase 1d — data pendidikan Indonesia (selesai)

Menyesuaikan knowledge base dengan desain onboarding 3-langkah dari tim desain.
Tiga hal membuat desain itu sebelumnya **tidak bisa dibangun**:

1. **`education_levels` menggabung SMA dengan SMK.** Seluruh percabangan desain
   bergantung persis pada bedanya — SMK punya Jurusan, SMA tidak. D1/D2 juga
   digabung, D4 menempel ke S1, dan SMP belum ada padahal itu baris pertama
   di matriks percabangan.
2. **Daftar jurusan SMK tidak ada.** Mockup menampilkan "(Broadcasting) Produksi
   dan Siaran Program Televisi" — data yang ada (14 baris IT) tidak menjangkau itu.
3. **Tabel `profiles` belum pernah dibuat.** Onboarding tidak punya tempat menyimpan.

### Yang dibuat — `0005_education_indonesia.sql`

| Tabel | Baris | Sumber |
|---|---:|---|
| `education_levels` | 10 | SMP, SMA, SMK, D1–D4, S1–S3 (dari 6) |
| `smk_expertise_programs` | 50 | **smk.kemendikdasmen.go.id/spektrum-keahlian** |
| `smk_concentrations` | 128 | sumber yang sama |
| `study_rumpun` | 12 | daftar rumpun dari tim |
| `study_programs` | 243 | daftar jurusan dari tim |
| `study_program_rumpun` | 244 | relasi many-to-many |
| `education_step_rules` | 20 | matriks percabangan tim desain |
| `profiles` | — | baru |

`order_rank` boleh sama untuk jenjang setara: SMA dan SMK sama-sama 2, D4 dan S1
sama-sama 6. Yang membedakan adalah `code`, bukan peringkatnya.

**Jurusan SMK adalah data Tier 1** — dari situs resmi Kemendikdasmen, bukan kurasi.

**Program studi kuliah kini dari daftar tim** (Agustus 2026), menggantikan kurasi
158 nama sebelumnya: 12 rumpun, 244 entri, 243 nama unik. Statusnya naik dari
"kurasi Claude" jadi "daftar tim", tapi `is_verified` tetap `false` karena belum
dicocokkan ke PDDikti.

Rumpun dibuat **many-to-many**, bukan satu kolom: "Ilmu Keolahragaan" memang
terdaftar di Ilmu Kesehatan *dan* Ilmu Olahraga. Kalau dipaksa satu kolom, salah
satunya harus dibuang atau namanya diduplikasi.

PDDikti (~29.000 prodi per kampus) tidak realistis jadi dropdown, jadi user tetap
boleh mengetik sendiri; isian bebasnya masuk `profiles.study_program_custom` untuk
ditinjau dan dipromosikan admin.

**Tujuh koreksi saat transkripsi daftar tim** — semuanya perlu kamu konfirmasi:

| Di sumber | Dipakai | Alasan |
|---|---|---|
| Teknik Rasiodiagnostik dan Radioterapi | Teknik **Radio**diagnostik dan Radioterapi | salah ketik |
| Bioentrepeneurship | Bioentre**p**reneurship | salah ketik |
| Silvikulutur | Silvikul**t**ur | salah ketik |
| Industrial RoboticsDesign | Industrial Robotics Design | spasi hilang |
| Rekayasa hayati | Rekayasa Hayati | kapitalisasi |
| Fakultas Akuntansi | Akuntansi | sumber menulis nama fakultas, bukan prodi |
| Rekayasa Pertanian (muncul 2x di Ilmu Pertanian) | dihapus satu | duplikat |

Karena itu Ilmu Pertanian berisi 31, bukan 32 seperti di daftar asli.

### Aturan percabangan disimpan sebagai data

`education_step_rules` memuat 20 kombinasi (10 jenjang × 2 status). Frontend
membacanya lewat `ruleFor()`, tidak menghardcode. Kalau desainnya berubah, cukup
ubah satu baris tabel.

### CHECK constraint menegakkan matriks di level database

Frontend boleh punya bug; data yang mustahil tetap tidak akan masuk. Sudah diuji —
enam kombinasi salah **ditolak**, empat kombinasi benar **diterima**:

| Ditolak | Diterima |
|---|---|
| SMA punya jurusan SMK | SMK sedang studi + jurusan + kelas 11 |
| SMA punya program studi | S1 sedang studi + prodi + semester 5 |
| Sudah lulus tapi punya kelas | S1 lulus + prodi ketikan bebas |
| Siswa SMK punya semester | SMP sedang studi + kelas 8 |
| Mahasiswa punya kelas | |
| Prodi dipilih **dan** diketik | |

Trigger `handle_new_user()` membuat baris profil otomatis saat user mendaftar,
jadi onboarding tinggal UPDATE dan tidak perlu menangani kasus "baris belum ada".

### Efek samping yang ditangani

**477 profesi dipetakan ulang `min_education_rank`-nya** dari skala 6 ke skala 8.
Nilainya berasal dari Job Zone O*NET jadi pemetaannya deterministik, bukan tebakan.
Blok migrasinya dijaga agar hanya berjalan sekali — kalau diulang, rank akan
bergeser dua kali. Sudah diuji: menjalankan `0005` dua kali tidak menggeser apa pun.

**`backend/engine.py` ikut diperbaiki.** `map_user_education_rank()` masih memakai
skala 6 lama; kalau dibiarkan, filter KBF akan menyaring profesi yang salah untuk
setiap user. Sekarang mengenali kode jenjang baru dan urutan kata kuncinya
diperbaiki supaya "diploma 3" tidak tertangkap oleh "diploma". 13 kasus uji lolos.

### File frontend

`frontend/src/lib/education.ts` — `getEducationLevels`, `getStepRules`, `ruleFor`,
`getSmkPrograms`, `searchStudyPrograms`, `saveEducation`, `getEducationSummary`.
`tsc` dan `eslint` bersih.

### Masih terbuka

- 243 nama program studi belum dicocokkan ke PDDikti (`is_verified = false`).
- Tujuh koreksi transkripsi di atas perlu dikonfirmasi tim.
- `education_majors` (60 baris, IT-only) sekarang tumpang tindih dengan tabel baru
  dan mengacu ke nama jenjang lama. Belum dibuang karena masih dipakai alur chat
  legacy — bereskan saat alur itu diganti.
- Target tahun lulus belum dihitung otomatis dari jenjang + kelas/semester.

---

## Fase 2a — layar Onboarding (selesai)

Rute `/onboarding`, mengikuti desain tim untuk **mobile, tablet, dan desktop**.

### Struktur

| File | Isi |
|---|---|
| `app/onboarding/page.tsx` | Orkestrator: Start → Step 1 → 2 → 3 → Done |
| `components/onboarding/StartScreen.tsx` | Layar pembuka A-01 |
| `components/onboarding/StepSidebar.tsx` | Panel kiri desktop: ilustrasi + stepper 3 langkah |
| `components/onboarding/ProgressHeader.tsx` | Pill STEP n/3 + judul + progress bar |
| `components/onboarding/ChipGroup.tsx` | Pilihan pill, satu jawaban |
| `components/onboarding/StudyProgramCombobox.tsx` | Pemilih prodi: popover (≥sm) / bottom sheet (mobile) |
| `components/onboarding/ReviewCard.tsx` | Kartu ringkasan Step 3 |
| `components/onboarding/StepFooter.tsx` | Footer aksi |
| `components/onboarding/TipCallout.tsx` | Kotak tips |
| `components/onboarding/OnboardingIllustration.tsx` | Ilustrasi + fallback |

### Keputusan yang perlu diketahui

**Percabangan dibaca dari `education_step_rules`**, tidak dihardcode. SMK memunculkan
Jurusan, SMA tidak; siswa dapat Kelas, mahasiswa dapat Semester — semuanya mengikuti
tabel. Ganti jenjang membersihkan jawaban turunannya, karena CHECK constraint di
database menolak kombinasi seperti "SMA punya jurusan SMK"; tanpa pembersihan itu user
melihat error simpan yang tidak nyambung dengan apa yang baru dia klik.

**Layout beda per breakpoint, sesuai desain.** Mobile dan tablet satu kolom penuh di
latar putih; dari `lg` jadi kartu melayang di latar abu-abu dengan panel kiri berisi
ilustrasi dan stepper. Stepper hanya muncul di desktop — di mobile kartu progres sudah
menyampaikan hal yang sama, menampilkan keduanya cuma mengulang.

**`ChipGroup` dibangun dari radio, bukan tombol.** Keyboard bisa berpindah pakai panah
seperti radio group biasa dan pembaca layar mengumumkan "1 dari 10" — perilaku yang
harus ditulis manual kalau memakai `<button>`.

**Baris ReviewCard menumpuk di mobile, dua kolom dari `lg`** — mengikuti desain, karena
kartunya jauh lebih lebar di desktop.

**Daftar "Terpopuler" di combobox masih konstanta di kode**, bukan dari data pemakaian.
Begitu ada cukup user, ganti dengan hitungan dari `profiles.study_program_id`.

**`/onboarding` masuk daftar rute chromeless di `Navbar.tsx`** — desainnya tidak punya
navigasi aplikasi, dan ini alur yang harus diselesaikan, bukan halaman yang boleh
ditinggalkan lewat menu.

### Verifikasi

`tsc`, `eslint`, dan `next build` bersih. Dirender sungguhan dengan Playwright di
390 / 834 / 1440 px, seluruh alur Start → Step 3 dijalankan otomatis. Tiga bug ketemu
dan diperbaiki lewat cara ini, bukan lewat pembacaan kode:

1. Navbar lama "CareerPath AI" masih muncul di atas onboarding.
2. Fallback ilustrasi tanpa `aspect-ratio` — dipanggil dengan `h-auto`, jadi tingginya
   nol dan slot ilustrasi hilang begitu saja alih-alih terlihat kosong.
3. Debounce pencarian prodi memicu `setState` langsung di dalam efek.

### Aset yang masih dibutuhkan

Lima ilustrasi ke `public/onboarding/`: `start.png`, `step-1.png`, `step-2.png`,
`step-3.png`, `done.png`. Selama belum ada, slotnya tampil sebagai kotak ungu pucat —
onboarding tetap bisa dipakai dan dites.

### Terbuka

- Tombol terakhir mengarah ke `/dashboard` yang belum ada.
- Nama langkah 3 dikonfirmasi tim: **"Review dan selesai!"** (varian "Memilih profesi
  impian" di `STEP01-02A` diabaikan).
- Layar Start belum menyimpan apa pun; kalau user menutup tab di tengah jalan,
  progresnya hilang. Baru tersimpan saat menekan Simpan di Step 3.

### Tambahan setelah desain desktop & tablet masuk

Layar **Start (A-01)** ditambahkan — sebelumnya tidak ada di paket mobile. Panel kiri
desktop berisi ilustrasi + stepper 3 langkah dengan tiga keadaan: centang hijau untuk
selesai, bulatan ungu untuk aktif, nomor bergaris untuk berikutnya.

Pemilih program studi diganti dari autocomplete inline menjadi **combobox** sesuai
desain: pemicu + panel berisi pencarian, grup "Terpopuler", dan hasil dikelompokkan per
rumpun. Muncul sebagai popover dari `sm` ke atas, bottom sheet berlatar gelap di mobile.

Dua perilaku yang baru ketahuan dari `STEP03-01B`, dan sebelumnya saya salah:

1. **Baris review selalu ditampilkan, tidak dihilangkan saat kosong.** SMA menampilkan
   "Jurusan / Program Studi: Umum", lulusan menampilkan "Kelas saat ini: -". Versi
   sebelumnya menghapus barisnya — itu membuat grid dua kolom di desktop jadi timpang
   dan user tidak melihat semua yang tersimpan tentang dirinya.
2. **Layar Done di desktop memakai kartu sempit terpusat**, sama seperti Start, bukan
   kolom lebar seperti langkah 1-3.

Label baris kedua kartu status mengikuti jenjang: "Kelas saat ini" untuk SMP/SMA/SMK,
"Semester saat ini" untuk D1-S3.

## Aset ilustrasi onboarding masuk (30 Agustus)

Kelima ilustrasi dari tim desain sudah ada di `frontend/public/onboarding/`.
Nama ekspornya diubah ke nama yang dipakai kode:

| Nama ekspor        | Nama di repo | Ukuran asli | Dipakai di            |
|--------------------|--------------|-------------|-----------------------|
| `Image.png`        | `start.png`  | 283x360     | layar pembuka (A-01)  |
| `left-top (1).png` | `step-1.png` | 472x237     | panel kiri langkah 1  |
| `left-top (2).png` | `step-2.png` | 472x237     | panel kiri langkah 2  |
| `left-top (3).png` | `step-3.png` | 472x237     | panel kiri langkah 3  |
| `section.png`      | `done.png`   | 320x320     | layar selesai (C-01)  |

### Rasio per aset, bukan satu angka seragam

`OnboardingIllustration` sebelumnya mengirim `width={640} height={480}` untuk
semua gambar. Angka itu cuma penampung waktu asetnya belum ada, tapi begitu file
aslinya masuk ia jadi bug: semua pemanggil memakai `h-auto`, jadi tinggi elemen
dihitung dari rasio `width/height` yang kita berikan — bukan dari isi file.
Akibatnya `start.png` yang potret (283x360) ditarik jadi lanskap 4:3.

Sekarang `ILLUSTRATIONS` menyimpan `{ src, width, height }` per aset dan
placeholder-nya memakai `aspectRatio` yang sama, sehingga tata letak tidak
bergeser kalau salah satu file hilang.

### Penyesuaian ukuran mengikuti mockup

Diukur ulang dari mockup, lalu dicocokkan:

- **Panel kiri desktop 368px -> 420px.** Di `Desktop B-01` panel kiri 472 dari
  kartu 1216 (38.8%); dengan kartu kita 1120, 420 memberi 37.5%.
- **Padding panel kiri `p-6` -> `p-3` + `px-5` untuk daftar langkah.** Di mockup
  ilustrasinya nyaris penuh selebar panel (sisa ~12px) sementara teksnya menjorok
  ~36px. Satu padding seragam tidak bisa memenuhi keduanya.
- **Ilustrasi pembuka `max-w-[420px]` -> `max-w-[300px]`.** Di `A-01` gambarnya
  ~54% lebar isi kartu. Kalau selebar kartu, tingginya ~700px dan tombol
  "Ayo Mulai!" terdorong ke bawah layar.
- **Ilustrasi selesai `w-[280px]` -> `lg:w-[320px]`,** sesuai 322px di `C-01`.
- **Tombol "Lanjut ke Dashboard" tidak lagi penuh di desktop.** `C-01` desktop
  memakai pil ~328px terpusat, sedangkan `Mobile C-01` tetap penuh di dalam bilah
  lilac — jadi `lg:mx-auto lg:w-auto lg:min-w-[320px]`.

### Catatan resolusi

Semua aset diekspor 1x. Di layar 2x (Retina, dan semua HP) gambarnya akan sedikit
lembut, paling terasa pada `start.png` yang dirender 300px dari sumber 283px.
Kalau tim desain bisa mengekspor ulang di 2x (`start@2x` 566x720, `step-*` 944x474,
`done` 640x640), tidak ada perubahan kode yang diperlukan — Next.js `Image` akan
memakainya begitu file diganti, asal `width`/`height` di `ILLUSTRATIONS`
disesuaikan ke ukuran baru.

## Fase 1e — roadmap Stage → Milestone → Activity (selesai)

Bagian yang selama ini kosong: knowledge base sudah tahu profesi apa yang cocok
untuk seorang siswa, tapi belum bisa menjawab "lalu saya harus apa".

`0006_roadmap.sql` membuat strukturnya, `0007_roadmap_data.sql` mengisinya untuk
seluruh 477 profesi aktif: **2.676 fase, 8.508 capaian, 18.596 aktivitas**,
semuanya berbahasa Indonesia dan diturunkan dari data, tanpa LLM.

### Menerjemahkan kosakata, bukan kalimatnya

O*NET menyusun pekerjaan berlapis: GWA (41) → IWA (332) → DWA (2.087) → Task
Statement (18.796). Godaannya adalah memakai task statement — itu yang paling
konkret. Tapi task statement tidak dipakai ulang antar profesi, jadi memakainya
berarti menerjemahkan 18.796 kalimat dan tidak ada satu pun yang bisa dipakai
dua kali.

Lapisan IWA seukuran "capaian" dan dipakai ulang: 464 profesi kita hanya
menyentuh **311 IWA**. Menerjemahkan 311 kalimat sekali memberi milestone
Indonesia untuk seluruh knowledge base. Hasilnya di `supabase/roadmap/iwa_id.py`,
tersimpan di tabel `roadmap_skill_areas` lengkap dengan `name_en` supaya tiap
terjemahan bisa diaudit.

### Bentuk roadmap

| Fase | Isi | Hilang kalau |
|---|---|---|
| SEKOLAH | kenali profesi, pilih jurusan | sudah lulus SMA/SMK |
| KULIAH | pilih prodi, selesaikan studi | jenjang target sudah dicapai |
| FONDASI | 4 kemampuan inti teratas | — |
| PENGALAMAN | alat kerja, 2 kemampuan, magang pertama | — |
| PROFESIONAL | izin praktik, rekrutmen, 3 kemampuan | — |
| LANJUT | profesi lanjutan yang serumpun | — |

Satu template per profesi, bukan satu per (profesi, jenjang). Fase yang sudah
dilewati disaring saat dibaca lewat `skip_if_rank_at_least`. Anak SMP melihat 44
aktivitas untuk Backend Developer, fresh graduate S1 melihat 33 — template yang
sama.

### Empat keputusan yang mengubah hasil

**Jenjang target diambil dari distribusi pendidikan O*NET, bukan Job Zone.**
`min_education_rank` yang lama sebenarnya hanya salinan job zone. Distribusi
"Required Level of Education" jauh lebih informatif — dan untuk 69 profesi
hasilnya lebih rendah dari baseline, yang justru benar: mekanik, machinist, dan
operator crane di Indonesia memang masuk lewat SMK, bukan D3. Dua kategori
Amerika sengaja tidak dipetakan ke D1, karena D1 nyaris tidak dipakai pasar
kerja Indonesia. Selisihnya ada di `supabase/roadmap/review_education.csv`.

**Kemampuan memimpin didorong ke fase belakang.** O*NET mensurvei pemegang
jabatan di semua tingkat senioritas, jadi "menyupervisi personel" muncul di
peringkat 3 untuk Software Developer. Menaruhnya di FONDASI berarti menyuruh
anak SMA berlatih memimpin tim sebelum bisa membuat program.

**Alat kerja diurutkan dari yang paling khas, bukan alfabetis.** Urutan
alfabetis memberi Backend Developer "C" dan "C#"; diurutkan dari yang paling
sedikit disebut profesi lain, hasilnya TypeScript, Terraform, RESTful API,
Jenkins, Spring Boot. Alat serba-guna seperti Excel turun sendiri.

**Angka pengalaman O*NET tidak dipakai apa adanya.** "Related Work Experience"
adalah pengalaman yang DIMILIKI pemegang jabatan sekarang, bukan yang
dibutuhkan untuk masuk. Untuk Software Developer nilainya 84 bulan; ditampilkan
apa adanya ia terbaca "butuh 7 tahun pengalaman sebelum bisa mulai". Fase
pengalaman dibatasi 24 bulan, angka aslinya disebut di deskripsi sebagai
gambaran jangka panjang.

### Izin praktik

Tidak ada di O*NET — yang dipetakan di sana lisensi Amerika. Roadmap perawat
yang berhenti di kelulusan berhenti tepat sebelum syarat yang paling
menentukan. `supabase/roadmap/licenses.py` menandai **143 profesi** yang butuh
STR/SIP, PPG, NIDN, atau izin profesi lain; fase PROFESIONAL-nya dimulai dengan
mengurus izin itu. Daftarnya disusun manual dari peraturan Indonesia dan
**wajib diperiksa ulang** — aturannya berubah.

### Dua celah keamanan yang ketahuan saat diuji

Keduanya lolos policy RLS dan baru ketahuan saat ditembak langsung:

1. **Menyisipkan progres ke roadmap orang lain.** Policy pemilik baris hanya
   memeriksa `user_id`. Pengguna A bisa menulis baris ber-`user_id` miliknya
   sendiri tapi menunjuk `user_roadmap_id` milik B — lolos policy, lalu ikut
   terhitung di progres B. Diperbaiki dengan foreign key gabungan
   `(user_roadmap_id, user_id)` → `user_roadmaps (id, user_id)`, sehingga
   kombinasinya mustahil di level basis data, bukan bergantung pada policy.

2. **Mencentang aktivitas dari profesi lain untuk mengumpulkan XP.** 18.596
   aktivitas tersedia dan semuanya public-read. Relasinya lewat tiga tabel jadi
   tidak bisa jadi foreign key; ditutup dengan trigger BEFORE INSERT yang
   memastikan aktivitasnya benar-benar milik template roadmap itu.

XP sendiri tidak pernah ditulis client: `xp_ledger` menolak INSERT dari
`authenticated`, dan satu-satunya penulisnya adalah trigger `grant_activity_xp`.
Indeks unik parsial mencegah centang-batal-centang menggandakan poin.

### Verifikasi

Rantai `0000` → `0007` dijalankan dari DB kosong di PostgreSQL 16 lokal, lalu
dijalankan ulang seluruhnya untuk menguji idempotensi — bersih dua-duanya.
Uji fungsional: dua pengguna (SMP dan fresh graduate S1) memulai roadmap yang
sama, penyaringan fase benar, `start_roadmap` idempoten, XP tidak dobel.
Empat bentuk serangan diuji satu per satu; tiga ditolak, satu (yang sah)
berhasil. `tsc` dan `eslint` bersih untuk `lib/roadmap.ts`.

### Yang masih kurang

- **Aktivitas masih pola, belum spesifik.** "Pelajari dasar merancang sistem
  atau aplikasi komputer" benar tapi tidak menyebut kursus, buku, atau kanal
  mana. Sumber belajar Indonesia belum ada di knowledge base.
- **311 terjemahan IWA belum diverifikasi manusia** (`is_verified = false`).
- **`0007` menghapus lalu membangun ulang.** Aman sekarang, tapi begitu ada
  pengguna sungguhan, centang mereka ikut terhapus. Catatan cara menggantinya
  ada di bagian 5 file itu.
- **Estimasi waktu kasar.** Diturunkan dari titik tengah kategori O*NET, bukan
  data Indonesia.

## Fase 1f — slug stabil dan perbaikan link email (selesai)

Dua utang dari fase sebelumnya dilunasi.

### `0007` tidak lagi menghapus progres pengguna

Sebelumnya generate ulang berarti `delete from roadmap_templates` lalu tulis
ulang semuanya. Id aktivitas berubah tiap kali, dan `user_roadmap_activities`
menunjuk id itu — jadi memperbaiki satu kalimat berarti mengorbankan seluruh
centang pengguna. Aman selama belum ada pengguna, dan menjadi mahal persis di
hari pertama ada.

Sekarang tiap baris punya `slug` yang tidak bergantung urutan insert:

| Tabel | Slug | Contoh |
|---|---|---|
| stage | kind fase | `FONDASI` |
| milestone | kode IWA, atau slug struktural | `4.A.2.b.2.b`, `REKRUTMEN` |
| activity | perannya di dalam capaian | `PRAKTIK`, `TOOL:Docker` |

Generate ulang jadi UPSERT lewat tiga helper (`_rm_stage`, `_rm_milestone`,
`_rm_activity`) yang mencatat id terpakai ke tabel sementara; yang tidak
tercatat dibersihkan di akhir. Baris yang slug-nya sama dipertahankan berikut
id-nya.

Dua hal yang perlu ada supaya ini bekerja:

- **Constraint urutan jadi DEFERRABLE.** Saat generate ulang, milestone bisa
  bertukar posisi, dan pemeriksaan langsung gagal di tengah jalan ketika dua
  baris sesaat memegang nomor yang sama. Ditunda sampai commit.
- **Parameter helper bertipe `integer`, bukan `smallint`.** Literal `1` di
  PL/pgSQL bertipe integer, dan integer ke smallint bukan cast implisit — jadi
  resolusi fungsinya gagal dengan `function ... does not exist` yang
  menyesatkan.

Diuji: centang tiga aktivitas, jalankan ulang `0007`, id-nya (56, 57, 58) tetap
sama, centang tetap tiga, XP tetap 50. Menonaktifkan satu profesi lalu generate
ulang menghapus template beserta turunannya tanpa meninggalkan baris yatim, dan
mengaktifkannya kembali memulihkannya — centang pengguna lain tidak tersentuh.

### Link verifikasi email tidak lagi menunjuk localhost

`emailRedirectTo` diisi `window.location.origin`, yang dibekukan ke dalam email
pada detik pengguna menekan daftar. Kalau ia mendaftar dari `localhost:3000`,
link verifikasinya selamanya ke sana — dan email itu biasanya dibuka beberapa
menit kemudian saat dev server sudah mati, atau dibuka di HP, di mana
`localhost` berarti HP itu sendiri. Dua-duanya ERR_CONNECTION_REFUSED.

`lib/siteUrl.ts` memisahkan "di mana aku dibuka sekarang" dari "ke mana orang
harus kembali nanti", dibaca dari `NEXT_PUBLIC_SITE_URL` dengan fallback ke
origin. Dipakai di tiga tempat: daftar, kirim ulang verifikasi, dan reset sandi.
Tujuan setelah verifikasi juga diubah dari `/` ke `/onboarding`.

Perlu diiringi setelan di Supabase Dashboard -> Authentication -> URL
Configuration: alamat yang dihasilkan harus terdaftar di **Redirect URLs**,
kalau tidak Supabase mengabaikannya dan diam-diam memakai **Site URL**.

### Yang masih tersisa

- Sumber belajar Indonesia (`learning_resources`) belum ada — aktivitas masih
  berupa pola tanpa menyebut kursus atau kanal.
- 311 terjemahan IWA masih `is_verified = false`.
- Pemetaan ke SKKNI/BNSP belum diselidiki; itu yang akan membuat kalimat capaian
  dan jalur sertifikasi punya dasar resmi Indonesia, bukan terjemahan O*NET.

### Koreksi: jalur upgrade tidak ikut teruji

Slug di atas diuji hanya dari database kosong, dan itu melewatkan justru jalur
yang dipakai orang: instalasi yang sudah menjalankan 0006 versi lama.
`create table if not exists` diam saja kalau tabelnya sudah ada, jadi kolom
`slug` tidak pernah ditambahkan dan seluruh migrasi gagal dengan
`column "slug" does not exist`.

Perbaikannya: `alter table ... add column if not exists slug text` terpisah,
plus blok yang menukar foreign key satu kolom di `user_roadmap_activities`
dengan yang menyertakan `user_id` — dua-duanya hal yang CREATE TABLE lewati
di tabel yang sudah ada.

Menguji jalur itu memunculkan bug kedua yang lebih serius, dan sudah ada sejak
versi pertama: `user_roadmaps.template_id` memakai ON DELETE SET NULL, jadi
begitu template terhapus, roadmap pengguna kehilangan tautannya dan tampil
kosong **selamanya** — tidak ada yang menyambungkannya kembali. Sekarang 0007
menyambung ulang di bagian 4b; aman karena `roadmap_templates` unik per profesi.

Sekali upgrade ini, centang yang sudah ada tetap hilang: baris lama tidak punya
slug, jadi semuanya dibangun ulang. Setelah itu generate ulang mempertahankan
id — diverifikasi dengan mencentang tiga aktivitas, menjalankan ulang 0007, dan
memastikan id serta XP-nya tidak berubah.
