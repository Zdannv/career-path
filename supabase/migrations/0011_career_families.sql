-- ============================================================================
-- 0011_career_families.sql
--
-- Menambahkan lapisan RUMPUN di atas profesi.
--
-- Alasannya datang dari tim desain: 21 profesi rumpun marketing terlalu banyak
-- untuk ditelusuri siswa, dan sebagian sebutannya cuma beda nama untuk
-- pekerjaan yang sama (Account Executive dan Sales Executive tidak berbeda dari
-- Sales Representative). Tapi menggabungkannya jadi satu baris berarti memutus
-- tautan ke O*NET — dan bersamanya DNA, roadmap, tools, serta skor pencocokan
-- yang semuanya diturunkan dari sana.
--
-- Jadi dua lapis, bukan penggabungan:
--
--   career_families  yang dilihat dan dipilih siswa      (7 untuk marketing)
--   careers          yang menyimpan DNA & roadmap asli   (21 untuk marketing)
--
-- Seluruh knowledge base: 477 profesi mengelompok jadi sekitar 65 rumpun.
-- Migrasi ini mengisi 7 rumpun marketing secara terkurasi, dan menyiapkan
-- pandangan bantu untuk mengurasi sisanya. Yang belum punya rumpun tetap bisa
-- ditampilkan sebagai dirinya sendiri, jadi tidak ada yang hilang di tengah.
--
-- Jalankan setelah 0010. Aman diulang.
-- ============================================================================

begin;

create table if not exists public.career_families (
  code            text primary key,
  name_id         text        not null,
  description_id  text        not null,
  target_rank_min smallint,
  target_rank_max smallint,
  needs_license   boolean     not null default false,
  -- Kekuatan dukungan data untuk pengelompokan ini, diukur dari kemiripan DNA
  -- antar anggotanya. Disimpan supaya rumpun yang dibentuk atas dasar penilaian
  -- manusia bisa dibedakan dari yang memang mirip menurut data.
  dna_cohesion    numeric(5,2),
  cohesion_note   text,
  display_order   smallint,
  is_active       boolean     not null default true,
  created_at      timestamptz not null default now(),
  constraint chk_family_ranks check (
    target_rank_min is null or target_rank_max is null
    or target_rank_min <= target_rank_max)
);

comment on table public.career_families is
  'Rumpun profesi: lapisan yang dilihat siswa. Satu rumpun memuat beberapa profesi yang roadmap-nya tetap terpisah.';
comment on column public.career_families.dna_cohesion is
  'Rata-rata kemiripan DNA antar anggota, dalam persen. Di bawah 55 berarti rumpun ini dibentuk atas dasar fungsi kerja, bukan kemiripan data.';

alter table public.careers add column if not exists family_code text
  references public.career_families(code) on delete set null;

create index if not exists idx_careers_family on public.careers (family_code) where family_code is not null;

-- ---------------------------------------------------------------------------
-- Tujuh rumpun marketing
--
-- Angka dna_cohesion dihitung dari kemiripan DNA antar anggota memakai rumus
-- yang sama dengan mesin pencocokan. Dua di antaranya rendah dan sengaja
-- dibiarkan rendah: dikelompokkan karena fungsi kerjanya sama, bukan karena
-- datanya mirip. Catatannya ikut disimpan supaya keputusan itu tidak hilang.
-- ---------------------------------------------------------------------------
insert into public.career_families
  (code, name_id, description_id, target_rank_min, target_rank_max,
   needs_license, dna_cohesion, cohesion_note, display_order) values
 ('SALES_RITEL','Penjualan Ritel & Layanan Pelanggan',
  'Melayani pembeli akhir secara langsung — di toko, di pameran, atau lewat telepon. Menjelaskan produk, meyakinkan calon pembeli, memproses transaksi, dan menjaga stok tetap rapi.',
  2,2,false,56.0,'Cukup kohesif. Aktivitas yang dimiliki semua anggota: Berkomunikasi & Berinteraksi.',1),
 ('SALES_LAPANGAN','Penjualan Lapangan Bergerak',
  'Menjual sambil mengantar barang menyusuri rute tetap. Menggabungkan penjualan dengan pengemudian, penagihan, dan penataan stok di titik penjualan.',
  2,2,true,null,'Profesi tunggal. Dipisah karena separuh pekerjaannya mengemudi dan butuh SIM B1.',2),
 ('SALES_SUPERVISI','Supervisi Penjualan & Toko',
  'Memimpin tim penjual, bukan menjual sendiri. Menetapkan target dan wilayah, membina anggota tim, serta mengurus anggaran dan laporan penjualan.',
  2,6,false,73.0,'Paling kohesif di rumpun marketing. Aktivitas bersama: Memimpin & Mengelola, Mengajar & Membimbing.',3),
 ('SALES_B2B','Penjualan B2B & Teknis',
  'Menjual ke perusahaan, bukan ke perorangan. Menuntut penguasaan produk yang mendalam karena pembelinya menanyakan spesifikasi, bukan sekadar harga.',
  5,6,false,46.0,'Kohesi rendah (terendah 34%). Dikelompokkan karena fungsi kerjanya sama; perlu ditinjau kalau UI-nya terasa campur.',4),
 ('SALES_LISENSI','Penjualan Berlisensi',
  'Menjual produk yang diatur negara — asuransi, properti, atau efek. Pekerjaannya mirip penjualan lain, tapi tidak boleh dimulai sebelum izin resminya keluar.',
  5,6,true,64.0,'Kohesif, dan pemisahnya jelas: ketiganya tidak boleh dikerjakan tanpa izin.',5),
 ('MARKETING','Marketing & Periklanan',
  'Merancang kampanye dan menganalisis pasar, bukan menjual satu per satu. Bekerja pada tingkat audiens dan segmen, dengan data sebagai bahan utamanya.',
  5,6,false,39.0,'Kohesi paling rendah (terendah 19%, Digital Marketing Analyst vs Sales Iklan). Murni keputusan produk; kandidat pertama untuk dipecah.',6),
 ('VISUAL_MERCH','Visual Merchandising',
  'Menata display, etalase, dan stan pameran supaya barang menarik dilihat dan dibeli. Lebih dekat ke pekerjaan desain daripada penjualan.',
  5,5,false,null,'Profesi tunggal. Interest DNA utamanya Kreativitas, bukan Bisnis — beda dari seluruh rumpun marketing lain.',7)
on conflict (code) do update set
  name_id=excluded.name_id, description_id=excluded.description_id,
  target_rank_min=excluded.target_rank_min, target_rank_max=excluded.target_rank_max,
  needs_license=excluded.needs_license, dna_cohesion=excluded.dna_cohesion,
  cohesion_note=excluded.cohesion_note, display_order=excluded.display_order;

-- Tautan profesi -> rumpun
update public.careers set family_code = v.fam
from (values
 ('Pramuniaga','SALES_RITEL'), ('SPG/SPB','SALES_RITEL'),
 ('Sales Spare Part','SALES_RITEL'), ('Telemarketing','SALES_RITEL'),
 ('Sales Door-to-Door','SALES_RITEL'),
 ('Sales Kanvas','SALES_LAPANGAN'),
 ('Kepala Toko','SALES_SUPERVISI'), ('Sales Supervisor','SALES_SUPERVISI'),
 ('Sales Manager','SALES_SUPERVISI'),
 ('Sales Representative','SALES_B2B'), ('Technical Sales Representative','SALES_B2B'),
 ('Sales Engineer','SALES_B2B'), ('Sales Solar Panel','SALES_B2B'),
 ('Agen Asuransi','SALES_LISENSI'), ('Agen Properti','SALES_LISENSI'),
 ('Sales Sekuritas / Marketing Investasi','SALES_LISENSI'),
 ('Marketing Specialist','MARKETING'), ('Digital Marketing Analyst','MARKETING'),
 ('Manajer Periklanan dan Promosi','MARKETING'), ('Sales Iklan','MARKETING'),
 ('Penata Etalase / Visual Merchandiser','VISUAL_MERCH')
) as v(nama, fam)
where public.careers.career_name = v.nama;

do $$
declare n int;
begin
  select count(*) into n from public.careers where family_code is not null;
  if n <> 21 then
    raise exception 'seharusnya 21 profesi marketing tertaut ke rumpun, yang tertaut %', n;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Kandidat rumpun untuk 456 profesi lain
--
-- SOC minor group (empat digit pertama, mis. 41-30) adalah pengelompokan
-- resmi O*NET berdasarkan kesamaan pekerjaan, jadi ia titik awal yang jujur —
-- tapi hanya titik awal. Rumpun marketing di atas membuktikan kenapa: SOC
-- menaruh Sales Kanvas di 53-30 (transportasi) padahal ia pekerjaan penjualan,
-- dan menaruh Pramuniaga serta Sales Spare Part di grup berbeda padahal
-- keduanya serumpun.
--
-- Pandangan ini memberi bahan untuk dikurasi, bukan hasil yang siap pakai.
-- ---------------------------------------------------------------------------
create or replace view public.career_family_candidates
with (security_invoker = true) as
select
  left(c.soc_code, 5)                              as soc_minor,
  count(*)                                         as jumlah_profesi,
  min(c.min_education_rank)                        as rank_min,
  max(c.min_education_rank)                        as rank_max,
  array_agg(c.career_name order by c.career_name)  as profesi,
  bool_or(c.family_code is not null)               as sudah_ada_yang_terkurasi
from public.careers c
where c.is_active and c.soc_code is not null
group by 1
having count(*) > 1
order by 2 desc;

comment on view public.career_family_candidates is
  'Kandidat rumpun dari SOC minor group. Titik awal kurasi, bukan hasil final: SOC mengelompokkan berdasarkan jenis pekerjaan dan kadang memisahkan yang serumpun.';

alter table public.career_families enable row level security;
drop policy if exists career_families_read_all on public.career_families;
create policy career_families_read_all on public.career_families
  for select to anon, authenticated using (true);

commit;

-- ============================================================================
-- Verifikasi:
--
--   select code, name_id, dna_cohesion,
--          (select count(*) from careers c where c.family_code = f.code) as profesi
--   from career_families f order by display_order;
--
--   select count(*) from careers where is_active and family_code is null;  -- 456
--   select * from career_family_candidates limit 10;
-- ============================================================================
