-- ============================================================================
-- 0024_career_dna_discovery.sql
--
-- Menyiapkan database untuk layar Career DNA (Discovery).
--
-- Lima puluh empat atribut DNA sudah cocok persis dengan desain — nama,
-- urutan, dan sub-labelnya sama, jadi tidak ada yang perlu diisi ulang. Yang
-- perlu diselaraskan tinggal empat hal, ditambah tempat menyimpan progres.
--
--   1. Nama kategori.  Desain menulis "Minat Industri" dan "Keahlian";
--      database menulis "Minat" dan "Kemampuan Alami".
--
--   2. Urutan langkah.  Desain: Minat, Aktivitas, Keahlian, Cara Kerja,
--      Lingkungan Kerja. Database menaruh Lingkungan Kerja di urutan 4 dan
--      Cara Kerja di 5. Bobot keduanya sama (10%), jadi skornya tidak
--      berubah — hanya nomor langkahnya yang harus benar.
--
--   3. Batas pilihan Cara Kerja: 2 menjadi 3.
--
--      Ini keputusan yang di 0008 saya tunda karena workbook tim sendiri
--      belum sepakat (sheet "Career DNA" menulis 2, sheet "Career Matching
--      Score" menulis 3). Desain layar ini memutuskannya: Maks 3.
--
--      Menaikkan batasnya saja TIDAK CUKUP dan itu yang saya peringatkan
--      dulu: seluruh 477 profesi hanya punya 2 atribut Cara Kerja dominan,
--      jadi kalau user memilih 3, Jaccard-nya mentok di 2/(3+2-2) = 66,7% dan
--      tidak seorang pun bisa mencapai 100% pada kategori itu. Maka DNA
--      profesinya ikut dinaikkan ke 3 atribut dominan — datanya sudah ada di
--      onet_dna sampai peringkat 8, hanya belum ditandai. Sesudah ini kelima
--      kategori simetris: user memilih n, profesi punya n.
--
--   4. Tiga sub-label Lingkungan Kerja disesuaikan dengan kalimat di desain.
--
-- Jalankan setelah 0023. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Nama, urutan, dan pertanyaan per kategori
--
-- Pertanyaannya ("Kamu tertarik kerja di industri apa?") sebelumnya tidak ada
-- di mana pun. Ditaruh di database, bukan di kode, supaya layar langkah dan
-- layar review menampilkan kalimat yang sama tanpa ada yang menyalin ulang.
-- ---------------------------------------------------------------------------
alter table public.dna_layers add column if not exists question_id text;

comment on column public.dna_layers.question_id is
  'Pertanyaan yang ditampilkan di bawah judul langkah, dan dipakai ulang sebagai keterangan kartu di layar Review.';

update public.dna_layers set
  name_id       = v.nama,
  question_id   = v.tanya,
  display_order = v.urutan
from (values
  ('INTEREST',    'Minat Industri',   'Kamu tertarik kerja di industri apa?',        1::smallint),
  ('ACTIVITY',    'Aktivitas',        'Aktivitas apa yang paling Kamu sukai?',       2::smallint),
  ('SKILL',       'Keahlian',         'Apa keahlian kamu yang paling menonjol?',     3::smallint),
  ('WORKSTYLE',   'Cara Kerja',       'Seperti apa cara kerja yang Kamu suka?',      4::smallint),
  ('ENVIRONMENT', 'Lingkungan Kerja', 'Lingkungan kerja apa yang Kamu minati?',      5::smallint)
) as v(kode, nama, tanya, urutan)
where public.dna_layers.code = v.kode;

-- ---------------------------------------------------------------------------
-- 2. Batas Cara Kerja, di kedua sisi sekaligus
-- ---------------------------------------------------------------------------
update public.dna_layers set selection_count = 3 where code = 'WORKSTYLE';

update public.onet_dna d set is_dominant = true
from public.dna_attributes a
where a.code = d.attribute_code
  and a.layer_code = 'WORKSTYLE'
  and d.rank_in_layer <= 3
  and not d.is_dominant;

-- ---------------------------------------------------------------------------
-- 3. Sub-label Lingkungan Kerja mengikuti kalimat desain
-- ---------------------------------------------------------------------------
update public.dna_attributes set description_id = v.teks
from (values
  ('Pelayanan Kesehatan',  'Lingkungan layanan kesehatan seperti Rumah Sakit atau Klinik'),
  ('Institusi Pendidikan', 'Sekolah, kampus, dan lembaga akademik'),
  ('Pabrik',               'Industri seperti pabrik manufaktur, operasional')
) as v(nama, teks)
where public.dna_attributes.name_id = v.nama
  and public.dna_attributes.layer_code = 'ENVIRONMENT';

-- ---------------------------------------------------------------------------
-- 4. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int; kosong text;
begin
  select string_agg(code, ', ') into kosong from public.dna_layers where question_id is null;
  if kosong is not null then raise exception 'kategori tanpa pertanyaan: %', kosong; end if;

  -- Urutan langkah harus 1..5 tanpa bolong; nomor langkah di layar dihitung
  -- dari sini.
  select count(*) into n from public.dna_layers;
  if n <> 5 or exists (
    select 1 from generate_series(1, 5) g
    where not exists (select 1 from public.dna_layers l where l.display_order = g)
  ) then
    raise exception 'urutan kategori tidak 1..5';
  end if;

  -- Inti perbaikan nomor 3: tiap kategori harus punya jumlah atribut dominan
  -- yang sama dengan jumlah pilihan user, kalau tidak kategori itu tidak
  -- pernah bisa mencapai 100%.
  select count(*) into n from (
    select a.layer_code, l.selection_count, count(*) as dominan
    from public.careers c
    join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join public.dna_attributes a on a.code = d.attribute_code
    join public.dna_layers l on l.code = a.layer_code
    where c.is_active
    group by c.id, a.layer_code, l.selection_count
    having count(*) <> l.selection_count
  ) x;
  if n > 0 then
    raise exception '% pasangan profesi-kategori punya jumlah atribut dominan yang tidak sama dengan batas pilihan user', n;
  end if;
end $$;

commit;

-- ============================================================================
-- Verifikasi:
--   select display_order, code, name_id, question_id, selection_count
--   from dna_layers order by display_order;
--
--   select a.layer_code, count(*) / 477 as dominan_per_profesi
--   from careers c
--   join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
--   join dna_attributes a on a.code = d.attribute_code
--   where c.is_active group by 1;
--   -- 3 / 4 / 5 / 3 / 3
-- ============================================================================
