# Menjalankan migration

Semua file di `supabase/migrations/` sudah diuji berurutan di PostgreSQL 16 dari
database kosong, dan aman dijalankan ulang (idempoten).

## ⚠️ Sebelum menjalankan apa pun

**Rotasi dulu key Supabase.** Service-role key lama sudah bocor (ter-commit ke git
dan terkirim ke browser). Selama belum dirotasi, mengaktifkan RLS tidak melindungi
apa pun — key itu mem-bypass semua policy.

1. Dashboard → Project Settings → API → rotate **service_role key**
2. Isi `frontend/.env.local` dengan **anon key** (bukan service_role)
3. Isi `backend/.env`: `SUPABASE_SERVICE_ROLE_KEY` dan `SUPABASE_JWT_SECRET`

Panduan lengkap ada di `frontend/.env.example` dan `backend/.env.example`.

## Urutan dan cara menjalankan

Jalankan **berurutan**, jangan dilompati — tiap file bergantung pada yang sebelumnya.

| # | File | Ukuran | Isi |
|---|---|---:|---|
| 1 | `0000_legacy_knowledge_base.sql` | 20 KB | education_levels, skills, careers (35), career_skills |
| 2 | `0000b_legacy_education_majors.sql` | 8 KB | 60 jurusan → skill |
| 3 | `0001_enable_rls.sql` | 5 KB | RLS + helper `apply_owner_rls()` |
| 4 | `0002_riasec.sql` | 139 KB | 923 okupasi O*NET + RIASEC, bank soal, profil user |
| 5 | `0003_careers_expansion.sql` | 244 KB | 533 profesi baru, 9 industri, relasi many-to-many |
| 6 | `0004_career_dna.sql` | 21 KB | Skema Career DNA, 54 atribut, fungsi matching |
| 7 | `0004b_onet_dna_data.sql` | 238 KB | Skor DNA 522 okupasi |

### Opsi A — Supabase SQL Editor (paling gampang)

Semua file muat. Buka SQL Editor, tempel isi satu file, Run, tunggu selesai,
lanjut ke file berikutnya.

Dua catatan:
- File 5 dan 7 (±240 KB) butuh beberapa detik dan editornya agak berat saat
  menempel. Itu normal. Tunggu sampai selesai sebelum lanjut.
- Kalau kena statement timeout, pakai Opsi B.

### Opsi B — Supabase CLI

```bash
supabase link --project-ref <project-ref>
supabase db push
```

### Opsi C — psql langsung

```bash
# Connection string: Dashboard → Project Settings → Database → Connection string
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f supabase/migrations/0000_legacy_knowledge_base.sql \
  -f supabase/migrations/0000b_legacy_education_majors.sql \
  -f supabase/migrations/0001_enable_rls.sql \
  -f supabase/migrations/0002_riasec.sql \
  -f supabase/migrations/0003_careers_expansion.sql \
  -f supabase/migrations/0004_career_dna.sql \
  -f supabase/migrations/0004b_onet_dna_data.sql
```

## Verifikasi setelah selesai

```sql
-- Isi knowledge base
select 'careers aktif' k, count(*) v from careers where is_active
union all select 'profesi punya RIASEC', count(*) from career_riasec
union all select 'profesi punya DNA', count(distinct career_id) from career_dna
union all select 'atribut DNA', count(*) from dna_attributes
union all select 'relasi industri', count(*) from career_industries;
```
Harapannya: 477 · 535 · 535 · 54 · 636.

```sql
-- Tidak boleh ada profesi aktif tanpa DNA
select count(*) from careers c where c.is_active
  and not exists (select 1 from career_dna d where d.career_id = c.id);
```
Harus 0.

```sql
-- RLS aktif di semua tabel
select relname, relrowsecurity from pg_class
where relnamespace = 'public'::regnamespace and relkind = 'r'
order by relrowsecurity, relname;
```
Semua harus `true`.

## Uji Career Match Score

```sql
-- Ganti dengan user id sungguhan dari auth.users
insert into user_dna (user_id, attribute_code)
select '<user-uuid>', x from unnest(array[
  'INT_KREATIVITAS','INT_TEKNOLOGI','INT_BISNIS',
  'ACT_DESAIN','ACT_PROBLEM','ACT_ANALISA','ACT_MEMBANGUN',
  'SKL_KREATIVITAS','SKL_EMPATI','SKL_KOMUNIKASI','SKL_ADAPTABILITAS','SKL_LOGIKA',
  'ENV_HYBRID','ENV_KANTOR','ENV_REMOTE','WSY_DINAMIS','WSY_KOLABORATIF']) x;

select career_name, match_score, layers from career_match_scores('<user-uuid>') limit 10;
```

## Kalau perlu mengulang dari nol

Semua migration idempoten, jadi cukup jalankan ulang dari file 1. Yang perlu
diperhatikan: `0000_legacy_knowledge_base.sql` diawali `DROP TABLE IF EXISTS
career_skills, careers, skills, education_levels CASCADE` — **ini menghapus tabel
`careers` beserta seluruh turunannya**, termasuk data user yang mereferensikannya.
Aman saat setup awal, berbahaya setelah ada user sungguhan.

---

## Setelah migration: apa yang sudah terisi, apa yang belum

Cek dengan query ini:

```sql
select table_name as tabel,
  (xpath('/row/c/text()', query_to_xml(format('select count(*) c from public.%I', table_name), false,true,'')))[1]::text::int as baris
from information_schema.tables
where table_schema='public' and table_type='BASE TABLE' order by 2 desc, 1;
```

**Sudah terisi — knowledge base, tidak perlu diapa-apakan lagi:**

| Tabel | Baris |
|---|---:|
| `onet_dna` | 28.044 |
| `onet_occupations` | 923 |
| `career_industries` | 636 |
| `careers` | 568 (477 aktif) |
| `career_skills` | 307 |
| `skills` | 113 |
| `education_majors` | 60 |
| `dna_attributes` | 54 |
| `career_onet_map` | 35 |
| `assessment_items` | 18 |
| `industries` | 9 |
| `education_levels`, `riasec_types` | 6 |
| `dna_layers`, `dna_layer_weights` | 5 |

**Kosong dan memang seharusnya kosong** — diisi user saat aplikasi jalan:
`user_dna`, `user_assessment_responses`, `user_riasec_profile`.

**Sisa lama yang bisa dibuang:** `classes` (sistem kode kelas, sudah dicabut di
Fase 0) dan `user_journeys` (alur chat lama). Tabelnya masih ada karena dibuat
sebelum refactor. Kalau sudah yakin tidak dipakai:

```sql
drop table if exists public.classes cascade;
-- user_journeys: cek dulu isinya, ini menyimpan share link lama
-- select count(*) from user_journeys;
-- drop table if exists public.user_journeys cascade;
```

## Cara mengambil datanya dari aplikasi

Semua sudah dibungkus di `frontend/src/lib/knowledgeBase.ts`. Tabel referensi
public-read, jadi bisa dibaca dengan anon key tanpa login. `user_dna` dijaga RLS —
tidak perlu filter manual, Postgres yang mengurus.

```ts
import {
  getDnaLayers, getDnaAttributes, saveUserDna,
  getCareerMatches, getCareerDetail, getSimilarCareers, searchCareers,
} from "@/lib/knowledgeBase";

// 1. Layar Career Discovery — render chip pilihan
const layers = await getDnaLayers();       // 5 layer + selection_count
const attrs  = await getDnaAttributes();   // 54 atribut

// 2. Simpan pilihan user (3 minat + 4 aktivitas + 5 skill + 3 lingkungan + 2 cara kerja)
await saveUserDna(userId, ["INT_TEKNOLOGI", "INT_KREATIVITAS", /* ... */]);

// 3. Rekomendasi profesi
const matches = await getCareerMatches(userId, 10);
// [{ career_id, career_name, match_score, layers: { INTEREST: 92.1, ... } }]

// 4. Halaman detail profesi
const detail = await getCareerDetail(matches[0].career_id);
// { career, dnaByLayer, dominantDna, riasec, industries, showSalary }

// 5. "Profesi yang mirip"
const similar = await getSimilarCareers(careerId);

// 6. Pencarian & filter industri
const hasil = await searchCareers("designer", "CREATIVE");
```

Dua hal yang perlu diperhatikan saat merender:

- **`detail.showSalary`** — jangan tampilkan rentang gaji kalau `false`. Itu
  berarti `salary_confidence = 'none'`, alias belum ada data pasar Indonesia.
  Jangan diisi angka O*NET; itu pasar Amerika.
- **`matches[].layers`** — pakai untuk menjelaskan *alasan* kecocokannya
  ("minatmu cocok 92%, tapi lingkungan kerjanya cuma 40%"), bukan cuma
  menampilkan satu angka besar tanpa konteks.
