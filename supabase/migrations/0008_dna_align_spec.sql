-- ============================================================================
-- 0008_dna_align_spec.sql
--
-- Menyelaraskan Career DNA di database dengan spesifikasi tim desain & PO
-- (workbook "Career path 1.xlsx", sheet Career DNA dan Career Matching Score).
--
-- Dua hal yang berbeda dan tidak perlu diperdebatkan — spek adalah keputusan
-- tim, database yang mengikuti:
--
--   1. Bobot layer.  Database 30/30/20/10/10, spek 35/30/15/10/10.
--      Efeknya: Core DNA (Interest + Activity) naik dari 60% ke 65%, dan
--      Skill turun dari 20% ke 15%. Sejalan dengan premis produk bahwa
--      "apa yang membuat kamu menyukai profesi ini" lebih menentukan
--      daripada "keahlian yang kebetulan kamu punya sekarang".
--
--   2. Empat nama atribut. Sebelumnya memakai penamaan dari poster arsitektur;
--      sheet Career DNA memakai istilah yang berbeda untuk hal yang sama.
--      Sheet yang lebih baru, jadi sheet yang dipakai.
--
-- Yang SENGAJA tidak diubah: batas pilihan Work Style tetap 2. Workbook-nya
-- sendiri belum sepakat — sheet "Career DNA" menulis 2, sheet "Career Matching
-- Score" dan diagram rumus menulis 3 — dan menaikkannya ke 3 tanpa ikut
-- menaikkan jumlah atribut Work Style pada DNA profesi akan membuat kategori
-- itu mentok di 66,7% selamanya. Menunggu keputusan tim.
--
-- Jalankan setelah 0007. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Bobot layer sesuai spek
-- ---------------------------------------------------------------------------
update public.dna_layer_weights set weight = 0.350 where layer_code = 'INTEREST';
update public.dna_layer_weights set weight = 0.300 where layer_code = 'ACTIVITY';
update public.dna_layer_weights set weight = 0.150 where layer_code = 'SKILL';
update public.dna_layer_weights set weight = 0.100 where layer_code = 'ENVIRONMENT';
update public.dna_layer_weights set weight = 0.100 where layer_code = 'WORKSTYLE';

-- Bobot harus berjumlah tepat 1,0. Kalau tidak, career_match_scores membagi
-- dengan total yang salah dan seluruh skor bergeser tanpa ada yang sadar.
do $$
declare
  total numeric;
begin
  select sum(weight) into total from public.dna_layer_weights;
  if total is null or abs(total - 1.0) > 0.0001 then
    raise exception 'bobot layer berjumlah %, seharusnya 1,0', total;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Empat nama atribut mengikuti sheet Career DNA
--
-- Hanya name_id yang berubah. Kode atributnya tetap, jadi tidak ada data
-- pengguna maupun onet_dna yang perlu ikut dipindahkan.
-- ---------------------------------------------------------------------------
update public.dna_attributes set name_id = 'Pelayanan Kesehatan'
  where name_id = 'Rumah Sakit / Klinik';
update public.dna_attributes set name_id = 'Institusi Pendidikan'
  where name_id = 'Sekolah / Kampus';
update public.dna_attributes set name_id = 'Pabrik'
  where name_id = 'Industri / Pabrik';
update public.dna_attributes set name_id = 'Adaptif'
  where name_id = 'Cepat Berubah';

-- ---------------------------------------------------------------------------
-- 3. Label rekomendasi
--
-- Band-nya ada di spek tapi belum pernah ada di database, jadi tiap pemanggil
-- berpotensi menuliskan ambangnya sendiri. Ditaruh di satu tabel supaya UI,
-- backend, dan analitik memakai batas yang sama.
-- ---------------------------------------------------------------------------
create table if not exists public.match_score_bands (
  code        text primary key,
  min_score   numeric(5,2) not null,
  max_score   numeric(5,2) not null,
  label_id    text not null,
  description_id text not null,
  display_order smallint not null,
  constraint chk_band_range check (min_score >= 0 and max_score <= 100 and min_score < max_score)
);

insert into public.match_score_bands
  (code, min_score, max_score, label_id, description_id, display_order) values
  ('HIGHLY_RECOMMENDED', 80, 100, 'Highly Recommended',
   'Sangat cocok, sangat disarankan untuk profesi ini.', 1),
  ('RECOMMENDED', 50, 79.99, 'Recommended',
   'Cocok, namun masih ada beberapa aspek yang dapat ditingkatkan.', 2),
  ('EXPLORE', 0, 49.99, 'Explore',
   'Belum cukup cocok, eksplorasi profesi lain bisa lebih baik.', 3)
on conflict (code) do update set
  min_score = excluded.min_score, max_score = excluded.max_score,
  label_id = excluded.label_id, description_id = excluded.description_id,
  display_order = excluded.display_order;

alter table public.match_score_bands enable row level security;
drop policy if exists match_score_bands_read_all on public.match_score_bands;
create policy match_score_bands_read_all on public.match_score_bands
  for select to anon, authenticated using (true);

commit;

-- ============================================================================
-- Verifikasi:
--
--   select layer_code, weight from dna_layer_weights order by weight desc;
--   -- INTEREST .35 · ACTIVITY .30 · SKILL .15 · ENVIRONMENT .10 · WORKSTYLE .10
--
--   select code, label_id, min_score, max_score from match_score_bands
--   order by display_order;
-- ============================================================================
