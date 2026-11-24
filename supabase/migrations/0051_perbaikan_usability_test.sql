-- ===========================================================================
-- 0051_perbaikan_usability_test.sql
--
-- Perbaikan dari usability test November 2026 (5 partisipan: SMA, mahasiswa
-- semester 3, 5, 7, dan fresh graduate). Temuan dan perbaikannya:
--
--   1. Prodi tidak ada di daftar (Kecerdasan Buatan, Sains Data, dst.).
--      -> 18 prodi baru beserta rumpun dan relevansi profesinya.
--
--   2. Prodi yang diketik sendiri tidak dipakai di mana pun. Rekomendasi
--      pengguna itu tidak mendapat penyesuaian jurusan sama sekali, sehingga
--      anak IT yang mengetik "Teknik Informatika dan Komputer" mendapat
--      Petroleum Engineer dan Automotive Engineer di sepuluh besar, dan
--      Explore menyuruhnya "melengkapi program studi" yang sudah diisinya.
--      -> Isian bebas dicocokkan ke prodi terdekat (prodi_terdekat()), disimpan
--         di profiles.study_program_terdekat_id, dan dipakai pencocokan profesi,
--         baris "Relevan dengan Program Studi", dan label prodi di Explore.
--
--   3. Mahasiswa D4/S1 melihat dua langkah "sedang berlangsung" sekaligus di
--      Jalur Pendidikan (D3 dan S1). -> hanya langkah yang jenjangnya paling
--      dekat dengan jenjang pengguna yang berlangsung.
--
--   4. Quest "cuma copy teks": tidak ada tempat menulis jawaban.
--      -> user_quests.jawaban; quest berjenis AMBIL wajib dijawab (minimal 20
--         karakter) sebelum selesai, dan jawabannya bisa dibaca lagi.
--
--   5. Gamifikasi kurang mengikat ("seperti Duolingo, ada api beruntun").
--      -> quest_streak(): hari beruntun menyelesaikan quest.
--
--   6. "Kenapa nilainya kecil sekali?" -> peringkat_match(): peringkat profesi
--      di antara semua profesi untuk pengguna itu, supaya 55% yang ternyata
--      peringkat pertama terbaca sebagai pilihan terbaik, bukan nilai jelek.
--
-- Jalankan setelah 0050. Aman dijalankan ulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Prodi baru
--
--    Semuanya prodi yang benar-benar ada di PDDikti dan dicari partisipan
--    (atau satu rumpun dengannya). Beberapa sengaja TIDAK ditambahkan karena
--    pencarian sudah menemukannya lewat nama lain: "Teknik Komputer" ada di
--    "Sistem Komputer (Teknik Komputer)", "Manajemen Informatika" di
--    "Sistem Informasi (Manajemen Informatika)".
-- ---------------------------------------------------------------------------
insert into public.study_programs (name_id, source) values
  ('Kecerdasan Buatan',                      'usability_test_0051'),
  ('Sains Data',                             'usability_test_0051'),
  ('Sains Data Terapan',                     'usability_test_0051'),
  ('Teknologi Informasi',                    'usability_test_0051'),
  ('Rekayasa Perangkat Lunak',               'usability_test_0051'),
  ('Teknik Elektronika',                     'usability_test_0051'),
  ('Teknik Elektro Industri',                'usability_test_0051'),
  ('Teknik Mekatronika',                     'usability_test_0051'),
  ('Teknologi Rekayasa Multimedia',          'usability_test_0051'),
  ('Teknologi Rekayasa Internet',            'usability_test_0051'),
  ('Teknik Robotika dan Kecerdasan Buatan',  'usability_test_0051'),
  ('Bisnis Digital',                         'usability_test_0051'),
  ('Desain Komunikasi Visual',               'usability_test_0051'),
  ('Manajemen',                              'usability_test_0051'),
  ('Ilmu Ekonomi',                           'usability_test_0051'),
  ('Kewirausahaan',                          'usability_test_0051'),
  ('Ekonomi Syariah',                        'usability_test_0051'),
  ('Perbankan Syariah',                      'usability_test_0051')
on conflict (name_id) do nothing;

insert into public.study_program_rumpun (program_id, rumpun_code)
select sp.id, v.rumpun
from (values
  ('Kecerdasan Buatan',                     'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sains Data',                            'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sains Data',                            'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Sains Data Terapan',                    'KOMPUTER_DAN_TEKNOLOGI'),
  ('Sains Data Terapan',                    'ILMU_MATEMATIKA_DAN_IPA_MIPA'),
  ('Teknologi Informasi',                   'KOMPUTER_DAN_TEKNOLOGI'),
  ('Rekayasa Perangkat Lunak',              'KOMPUTER_DAN_TEKNOLOGI'),
  ('Teknik Elektronika',                    'ILMU_TEKNIK'),
  ('Teknik Elektro Industri',               'ILMU_TEKNIK'),
  ('Teknik Mekatronika',                    'ILMU_TEKNIK'),
  ('Teknologi Rekayasa Multimedia',         'KOMPUTER_DAN_TEKNOLOGI'),
  ('Teknologi Rekayasa Multimedia',         'ILMU_SENI'),
  ('Teknologi Rekayasa Internet',           'KOMPUTER_DAN_TEKNOLOGI'),
  ('Teknik Robotika dan Kecerdasan Buatan', 'ILMU_TEKNIK'),
  ('Teknik Robotika dan Kecerdasan Buatan', 'KOMPUTER_DAN_TEKNOLOGI'),
  ('Bisnis Digital',                        'ILMU_EKONOMI_DAN_BISNIS'),
  ('Bisnis Digital',                        'KOMPUTER_DAN_TEKNOLOGI'),
  ('Desain Komunikasi Visual',              'ILMU_SENI'),
  ('Manajemen',                             'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ilmu Ekonomi',                          'ILMU_EKONOMI_DAN_BISNIS'),
  ('Kewirausahaan',                         'ILMU_EKONOMI_DAN_BISNIS'),
  ('Ekonomi Syariah',                       'ILMU_EKONOMI_DAN_BISNIS'),
  ('Perbankan Syariah',                     'ILMU_EKONOMI_DAN_BISNIS')
) as v(prodi, rumpun)
join public.study_programs sp on sp.name_id = v.prodi
on conflict do nothing;

-- Relevansi profesi. Dua sumber:
--   a. salinan prodi induk yang cakupannya sama (Teknologi Informasi dari
--      Teknik Informatika, Manajemen dari empat prodi manajemen, dst.);
--   b. kurasi tangan untuk prodi yang tidak punya induk yang pas.
-- Kalau keduanya menyebut profesi yang sama, relevansi tertinggi yang dipakai.
create temporary table _rel_0051 (
  prodi text, career_id integer, relevance smallint
) on commit drop;

insert into _rel_0051
select v.prodi, e.career_id, e.relevance
from (values
  ('Teknologi Informasi',       'Teknik Informatika'),
  ('Rekayasa Perangkat Lunak',  'Software Engineering'),
  ('Rekayasa Perangkat Lunak',  'Teknik Informatika'),
  ('Teknik Elektro Industri',   'Teknik Elektro'),
  ('Teknik Mekatronika',        'Teknik Otomasi Manufaktur dan Mekatronika'),
  ('Desain Komunikasi Visual',  'DKV New Media'),
  ('Desain Komunikasi Visual',  'DKV Creative Advertising'),
  ('Ilmu Ekonomi',              'Ekonomi Pembangunan'),
  ('Manajemen',                 'Manajemen Pemasaran'),
  ('Manajemen',                 'Manajemen Keuangan'),
  ('Manajemen',                 'Manajemen Sumber Daya Manusia'),
  ('Manajemen',                 'Manajemen Operasional'),
  ('Kewirausahaan',             'Administrasi Bisnis'),
  ('Ekonomi Syariah',           'Ekonomi Pembangunan'),
  ('Perbankan Syariah',         'Manajemen Keuangan')
) as v(prodi, induk)
join public.study_programs ind on ind.name_id = v.induk
join public.education_career e on e.source_kind = 'PRODI' and e.source_id = ind.id;

insert into _rel_0051
select v.prodi, c.id, v.rel
from (values
  ('Kecerdasan Buatan', 'AI Engineer', 100),
  ('Kecerdasan Buatan', 'Machine Learning Engineer', 100),
  ('Kecerdasan Buatan', 'Computer Vision Engineer', 100),
  ('Kecerdasan Buatan', 'NLP Engineer', 100),
  ('Kecerdasan Buatan', 'Data Scientist', 90),
  ('Kecerdasan Buatan', 'Data Engineer', 80),
  ('Kecerdasan Buatan', 'Robotics Engineer', 80),
  ('Kecerdasan Buatan', 'Data Analyst', 70),
  ('Kecerdasan Buatan', 'Backend Developer', 60),
  ('Kecerdasan Buatan', 'Programmer', 60),
  ('Kecerdasan Buatan', 'Solutions Architect', 50),

  ('Sains Data', 'Data Scientist', 100),
  ('Sains Data', 'Data Analyst', 100),
  ('Sains Data', 'Data Engineer', 90),
  ('Sains Data', 'Business Intelligence Developer', 90),
  ('Sains Data', 'Machine Learning Engineer', 90),
  ('Sains Data', 'Statistician', 80),
  ('Sains Data', 'AI Engineer', 80),
  ('Sains Data', 'Operations Research Analyst', 70),
  ('Sains Data', 'Database Administrator', 60),
  ('Sains Data', 'Analis Risiko Keuangan', 60),
  ('Sains Data', 'Digital Marketing Analyst', 50),

  ('Sains Data Terapan', 'Data Scientist', 100),
  ('Sains Data Terapan', 'Data Analyst', 100),
  ('Sains Data Terapan', 'Data Engineer', 100),
  ('Sains Data Terapan', 'Business Intelligence Developer', 90),
  ('Sains Data Terapan', 'Machine Learning Engineer', 90),
  ('Sains Data Terapan', 'AI Engineer', 80),
  ('Sains Data Terapan', 'Database Administrator', 70),
  ('Sains Data Terapan', 'Statistician', 60),
  ('Sains Data Terapan', 'Backend Developer', 50),

  ('Teknologi Informasi', 'IT Support / Helpdesk', 90),
  ('Teknologi Informasi', 'Network Engineer', 90),
  ('Teknologi Informasi', 'System Administrator', 90),
  ('Teknologi Informasi', 'Cybersecurity Analyst', 80),
  ('Teknologi Informasi', 'IT Project Manager', 70),

  ('Rekayasa Perangkat Lunak', 'Backend Developer', 100),
  ('Rekayasa Perangkat Lunak', 'Frontend Developer', 100),
  ('Rekayasa Perangkat Lunak', 'Fullstack Developer', 100),
  ('Rekayasa Perangkat Lunak', 'Mobile Developer', 100),
  ('Rekayasa Perangkat Lunak', 'QA Engineer', 90),
  ('Rekayasa Perangkat Lunak', 'DevOps Engineer', 90),

  ('Teknik Elektronika', 'IoT Engineer', 100),
  ('Teknik Elektronika', 'Operator Perakitan Elektronik', 90),
  ('Teknik Elektronika', 'Teknisi Audio Video', 80),
  ('Teknik Elektronika', 'Telecommunications Engineer', 80),
  ('Teknik Elektronika', 'Mechatronics Engineer', 80),
  ('Teknik Elektronika', 'Robotics Engineer', 80),
  ('Teknik Elektronika', 'Teknisi Robotika', 80),
  ('Teknik Elektronika', 'Validation Engineer', 60),
  ('Teknik Elektronika', 'Sales Engineer', 60),
  ('Teknik Elektronika', 'Operator Pembangkit Listrik', 60),

  ('Teknik Mekatronika', 'Mechatronics Engineer', 100),
  ('Teknik Mekatronika', 'Robotics Engineer', 90),
  ('Teknik Mekatronika', 'Teknisi Robotika', 90),
  ('Teknik Mekatronika', 'IoT Engineer', 70),

  ('Teknologi Rekayasa Multimedia', 'Video Editor', 100),
  ('Teknologi Rekayasa Multimedia', 'Cameraman / Videographer', 90),
  ('Teknologi Rekayasa Multimedia', 'Animator / VFX Artist', 90),
  ('Teknologi Rekayasa Multimedia', 'Graphic Designer', 90),
  ('Teknologi Rekayasa Multimedia', 'UI/UX Designer', 80),
  ('Teknologi Rekayasa Multimedia', 'Game Developer', 70),
  ('Teknologi Rekayasa Multimedia', 'Teknisi Broadcast', 70),
  ('Teknologi Rekayasa Multimedia', 'Sound Engineer', 60),
  ('Teknologi Rekayasa Multimedia', 'Frontend Developer', 60),

  ('Teknologi Rekayasa Internet', 'Network Engineer', 100),
  ('Teknologi Rekayasa Internet', 'Network Support Specialist', 90),
  ('Teknologi Rekayasa Internet', 'Cloud Engineer', 90),
  ('Teknologi Rekayasa Internet', 'IoT Engineer', 90),
  ('Teknologi Rekayasa Internet', 'Cybersecurity Analyst', 80),
  ('Teknologi Rekayasa Internet', 'Web Administrator', 80),
  ('Teknologi Rekayasa Internet', 'System Administrator', 80),
  ('Teknologi Rekayasa Internet', 'Telecommunications Engineer', 70),
  ('Teknologi Rekayasa Internet', 'DevOps Engineer', 70),
  ('Teknologi Rekayasa Internet', 'Backend Developer', 60),

  ('Teknik Robotika dan Kecerdasan Buatan', 'Robotics Engineer', 100),
  ('Teknik Robotika dan Kecerdasan Buatan', 'AI Engineer', 100),
  ('Teknik Robotika dan Kecerdasan Buatan', 'Teknisi Robotika', 90),
  ('Teknik Robotika dan Kecerdasan Buatan', 'Mechatronics Engineer', 90),
  ('Teknik Robotika dan Kecerdasan Buatan', 'Computer Vision Engineer', 90),
  ('Teknik Robotika dan Kecerdasan Buatan', 'Machine Learning Engineer', 90),
  ('Teknik Robotika dan Kecerdasan Buatan', 'IoT Engineer', 80),

  ('Bisnis Digital', 'Digital Marketing Analyst', 100),
  ('Bisnis Digital', 'Product Manager', 90),
  ('Bisnis Digital', 'Marketing Specialist', 90),
  ('Bisnis Digital', 'IT Business Analyst', 80),
  ('Bisnis Digital', 'Data Analyst', 70),
  ('Bisnis Digital', 'UI/UX Designer', 60),
  ('Bisnis Digital', 'Scrum Master / Agile Coach', 50),

  ('Desain Komunikasi Visual', 'Graphic Designer', 100),
  ('Desain Komunikasi Visual', 'UI/UX Designer', 80),
  ('Desain Komunikasi Visual', 'Video Editor', 70),

  ('Kewirausahaan', 'Product Manager', 70),
  ('Kewirausahaan', 'Marketing Specialist', 70),

  ('Ekonomi Syariah', 'Dosen Ilmu Ekonomi', 70),
  ('Perbankan Syariah', 'Analis Kredit', 90),
  ('Perbankan Syariah', 'Pemeriksa Lembaga Keuangan', 80),
  ('Perbankan Syariah', 'Analis Risiko Keuangan', 80)
) as v(prodi, profesi, rel)
join public.careers c on c.career_name = v.profesi;

delete from public.education_career e
using public.study_programs sp
where e.source_kind = 'PRODI' and e.source_id = sp.id and sp.source = 'usability_test_0051';

insert into public.education_career (source_kind, source_id, career_id, relevance, display_order, source, is_verified)
select 'PRODI', sp.id, r.career_id, r.rel,
       row_number() over (partition by sp.id order by r.rel desc, r.career_id)::smallint,
       'kurasi_0051', false
from (select prodi, career_id, max(relevance)::smallint as rel from _rel_0051 group by 1, 2) r
join public.study_programs sp on sp.name_id = r.prodi;

-- ---------------------------------------------------------------------------
-- 2. Prodi yang diketik sendiri -> prodi terdekat
--
--    Daftar kita 261 nama, PDDikti ~29.000. Isian bebas pasti terjadi, dan
--    sebelum ini isian itu tidak dipakai sama sekali. Pencocokan bertingkat:
--
--      nama    sama persis setelah dinormalkan ("S1 Teknik Informatika" ->
--              "teknik informatika")
--      alias   singkatan dan nama Inggris ("TI", "Data Science", "DKV")
--      kata    kata-kata prodi daftar terkandung di isian ("Teknik Informatika
--              dan Komputer" -> Teknik Informatika). Kata umum seperti
--              "teknik" atau "ilmu" saja tidak cukup: "Teknik Sipil Terapan"
--              tidak boleh jatuh ke Teknik Kimia hanya karena sama-sama
--              "teknik".
--
--    Tidak ketemu = NULL, dan rekomendasinya berjalan seperti pengguna tanpa
--    jurusan. Itu lebih jujur daripada menebak.
-- ---------------------------------------------------------------------------
create table if not exists public.study_program_aliases (
  alias      text    primary key,
  program_id integer not null references public.study_programs(id) on delete cascade
);
comment on table public.study_program_aliases is
  'Singkatan dan nama lain program studi (sudah dinormalkan: huruf kecil, tanpa tanda baca) untuk prodi_terdekat().';

alter table public.study_program_aliases enable row level security;
drop policy if exists study_program_aliases_read_all on public.study_program_aliases;
create policy study_program_aliases_read_all on public.study_program_aliases
  for select to anon, authenticated using (true);

create or replace function public.normalisasi_prodi(p text)
returns text
language sql immutable
as $$
  -- huruf kecil, tanda baca jadi spasi, buang awalan jenjang/kata "prodi"
  select btrim(regexp_replace(
           btrim(regexp_replace(lower(coalesce(p, '')), '[^a-z0-9]+', ' ', 'g')),
           '^((s1|s2|s3|d1|d2|d3|d4|prodi|program|studi|jurusan|sarjana|diploma|terapan)\s+)+',
           ''));
$$;

insert into public.study_program_aliases (alias, program_id)
select v.alias, sp.id
from (values
  ('ti',                           'Teknik Informatika'),
  ('informatika',                  'Teknik Informatika'),
  ('teknik informatika komputer',  'Teknik Informatika'),
  ('it',                           'Teknologi Informasi'),
  ('information technology',       'Teknologi Informasi'),
  ('computer science',             'Ilmu Komputer'),
  ('cs',                           'Ilmu Komputer'),
  ('si',                           'Sistem Informasi'),
  ('information system',           'Sistem Informasi'),
  ('information systems',          'Sistem Informasi'),
  ('mi',                           'Sistem Informasi (Manajemen Informatika)'),
  ('manajemen informatika',        'Sistem Informasi (Manajemen Informatika)'),
  ('teknik komputer',              'Sistem Komputer (Teknik Komputer)'),
  ('tekkom',                       'Sistem Komputer (Teknik Komputer)'),
  ('computer engineering',         'Sistem Komputer (Teknik Komputer)'),
  ('rpl',                          'Rekayasa Perangkat Lunak'),
  ('ai',                           'Kecerdasan Buatan'),
  ('artificial intelligence',      'Kecerdasan Buatan'),
  ('kecerdasan artifisial',        'Kecerdasan Buatan'),
  ('data science',                 'Sains Data'),
  ('data sains',                   'Sains Data'),
  ('ilmu data',                    'Sains Data'),
  ('sdt',                          'Sains Data Terapan'),
  ('elektronika',                  'Teknik Elektronika'),
  ('mekatronika',                  'Teknik Mekatronika'),
  ('multimedia',                   'Teknologi Rekayasa Multimedia'),
  ('robotika',                     'Teknik Robotika dan Kecerdasan Buatan'),
  ('dkv',                          'Desain Komunikasi Visual'),
  ('visual communication design',  'Desain Komunikasi Visual'),
  ('e commerce',                   'Bisnis Digital'),
  ('digital business',             'Bisnis Digital'),
  ('management',                   'Manajemen'),
  ('manajemen bisnis',             'Manajemen'),
  ('bisnis manajemen',             'Manajemen'),
  ('administrasi niaga',           'Administrasi Bisnis'),
  ('ekonomi',                      'Ilmu Ekonomi'),
  ('economics',                    'Ilmu Ekonomi'),
  ('accounting',                   'Akuntansi'),
  ('akutansi',                     'Akuntansi'),
  ('hukum',                        'Ilmu Hukum'),
  ('law',                          'Ilmu Hukum'),
  ('keperawatan',                  'Ilmu Keperawatan'),
  ('nursing',                      'Ilmu Keperawatan'),
  ('ners',                         'Ilmu Keperawatan'),
  ('gizi',                         'Ilmu Gizi'),
  ('komunikasi',                   'Ilmu Komunikasi'),
  ('psychology',                   'Psikologi'),
  ('perhotelan',                   'Pariwisata'),
  ('hospitality',                  'Pariwisata'),
  ('bahasa inggris',               'Sastra Inggris'),
  ('english',                      'Sastra Inggris')
) as v(alias, prodi)
join public.study_programs sp on sp.name_id = v.prodi
on conflict (alias) do update set program_id = excluded.program_id;

create or replace function public.prodi_terdekat(p_teks text)
returns table (id integer, name_id text, cara text)
language sql stable
set search_path = public
as $$
  with n as (select public.normalisasi_prodi(p_teks) as t),
  umum as (
    select array['teknik','ilmu','pendidikan','manajemen','sistem','teknologi','sains',
                 'rekayasa','terapan','bisnis','administrasi','desain','kesehatan'] as kata
  ),
  isian as (
    select array(select distinct x from unnest(regexp_split_to_array(n.t, '\s+')) x
                 where x <> '' and x not in ('dan','and','of','the','in')) as kata
    from n
  ),
  calon as (
    -- 1. nama sama persis
    select sp.id, sp.name_id, 'nama'::text as cara, 1 as prio, 100::numeric as skor, 0 as n_kata
    from public.study_programs sp, n
    where n.t <> '' and public.normalisasi_prodi(sp.name_id) = n.t
    union all
    -- 2. alias, utuh atau sebagai frasa di dalam isian; alias terpanjang menang
    select sp.id, sp.name_id, 'alias', 2, length(a.alias)::numeric, 0
    from public.study_program_aliases a
    join public.study_programs sp on sp.id = a.program_id, n
    where n.t <> '' and (' ' || n.t || ' ') like ('% ' || a.alias || ' %')
    union all
    -- 3. kata yang sama
    select sp.id, sp.name_id, 'kata', 3,
           cardinality(i.irisan)::numeric / cardinality(p.kata)
             + 0.5 * cardinality(i.irisan)::numeric / greatest(cardinality(isian.kata), 1),
           cardinality(p.kata)
    from public.study_programs sp
    cross join isian
    cross join umum
    cross join lateral (
      select array(select distinct x
                   from unnest(regexp_split_to_array(public.normalisasi_prodi(sp.name_id), '\s+')) x
                   where x <> '' and x not in ('dan','and','of','the','in')) as kata
    ) p
    cross join lateral (
      select array(select unnest(p.kata) intersect select unnest(isian.kata)) as irisan
    ) i
    where cardinality(p.kata) > 0
      and cardinality(i.irisan)::numeric / cardinality(p.kata) >= 0.5
      and exists (select 1 from unnest(i.irisan) w where w <> all (umum.kata))
  )
  select c.id, c.name_id, c.cara
  from calon c
  order by c.prio, c.skor desc, c.n_kata, length(c.name_id), c.id
  limit 1;
$$;

comment on function public.prodi_terdekat(text) is
  'Prodi daftar yang paling dekat dengan isian bebas pengguna: nama persis, alias, lalu kata yang sama. Kosong kalau tidak ada yang cukup dekat.';

alter table public.profiles
  add column if not exists study_program_terdekat_id integer
    references public.study_programs(id) on delete set null;
comment on column public.profiles.study_program_terdekat_id is
  'Prodi daftar terdekat untuk study_program_custom (0051). Diisi trigger, dipakai rekomendasi; NULL kalau pengguna memilih dari daftar atau tidak ada yang cukup dekat.';

create or replace function public.isi_prodi_terdekat()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.study_program_id is not null or nullif(btrim(coalesce(new.study_program_custom, '')), '') is null then
    new.study_program_terdekat_id := null;
  elsif tg_op = 'INSERT'
     or new.study_program_custom is distinct from old.study_program_custom
     or new.study_program_terdekat_id is null then
    new.study_program_terdekat_id := (select t.id from public.prodi_terdekat(new.study_program_custom) t);
  end if;
  return new;
end $$;

drop trigger if exists trg_profiles_prodi_terdekat on public.profiles;
create trigger trg_profiles_prodi_terdekat
  before insert or update of study_program_id, study_program_custom on public.profiles
  for each row execute function public.isi_prodi_terdekat();

-- Isian lama, termasuk partisipan usability test.
update public.profiles
   set study_program_terdekat_id = (select t.id from public.prodi_terdekat(study_program_custom) t)
 where study_program_id is null and study_program_custom is not null;

-- ---------------------------------------------------------------------------
-- 3. Tiga pembaca prodi memakai prodi terdekat
--
--    Isi fungsinya sama dengan versi terakhir (0044, 0020, 0039); yang berubah
--    hanya sumber prodinya: coalesce(study_program_id, study_program_terdekat_id).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.career_match_scores(p_user_id uuid)
 RETURNS TABLE(career_id integer, career_name text, match_score numeric, base_score numeric, band_code text, band_label text, detail jsonb)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with
  dinilai as (
    select exists (
      select 1 from user_dna_progress dp
      where dp.user_id = p_user_id and dp.completed_at is not null
    ) as ok
  ),
  user_pick as (
    select a.layer_code, ud.attribute_code
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = p_user_id
  ),
  user_n as (
    select layer_code, count(*)::int as n_user
    from user_pick group by layer_code
  ),
  -- Seluruh atribut profesi sampai peringkat N + 2 di tiap kategori.
  prof as (
    select c.id as career_id, c.career_name, a.layer_code, d.attribute_code,
           a.name_id, d.rank_in_layer,
           d.rank_in_layer <= l.selection_count as dominan
    from careers c
    join onet_dna d       on d.soc_code = c.soc_code
    join dna_attributes a on a.code = d.attribute_code
    join dna_layers l     on l.code = a.layer_code
    where c.is_active
      and d.rank_in_layer <= l.selection_count + 2
  ),
  -- Kategori profesi diambil dari bobot, supaya kategori yang tidak dipilih
  -- pengguna tetap muncul dengan kecocokan 0.
  kerangka as (
    select distinct p.career_id, p.career_name, p.layer_code from prof p
  ),
  per_layer as (
    select k.career_id, k.career_name, k.layer_code,
           count(*) filter (where p.dominan)::int                          as n_prof,
           coalesce(max(u.n_user), 0)                                     as n_user,
           count(*) filter (where p.dominan and up.attribute_code is not null)::int     as n_hit,
           count(*) filter (where not p.dominan and up.attribute_code is not null)::int as n_hampir,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where p.dominan and up.attribute_code is not null)   as cocok,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where p.dominan and up.attribute_code is null)       as belum,
           jsonb_agg(p.name_id order by p.rank_in_layer)
             filter (where not p.dominan and up.attribute_code is not null) as hampir
    from kerangka k
    join prof p on p.career_id = k.career_id and p.layer_code = k.layer_code
    left join user_pick up on up.attribute_code = p.attribute_code
    left join user_n u on u.layer_code = k.layer_code
    group by k.career_id, k.career_name, k.layer_code
  ),
  sim as (
    select pl.*,
           case when pl.n_user = 0 then 0
                -- Dibagi jumlah slot kategori (selection_count), bukan jumlah pilihan
                -- pengguna: memilih 3 dari 5 slot tidak lagi bisa bernilai 100%.
                else least(1, (pl.n_hit + 0.5 * pl.n_hampir)::numeric
                     / greatest(pl.n_user, (select l.selection_count from dna_layers l where l.code = pl.layer_code)))
           end as kecocokan
    from per_layer pl
  ),
  agg as (
    select s.career_id, s.career_name,
           sum(s.kecocokan * w.weight) * 100                         as base,
           max(s.n_hit) filter (where s.layer_code = 'INTEREST')     as hit_interest,
           max(s.n_hit) filter (where s.layer_code = 'ACTIVITY')     as hit_activity,
           jsonb_object_agg(s.layer_code, jsonb_build_object(
             'similarity', round(s.kecocokan * 100, 2),
             'n_user',     s.n_user,
             'n_profesi',  s.n_prof,
             'n_cocok',    s.n_hit,
             'n_hampir',   s.n_hampir,
             'cocok',      coalesce(s.cocok, '[]'::jsonb),
             'belum',      coalesce(s.belum, '[]'::jsonb),
             'hampir',     coalesce(s.hampir, '[]'::jsonb)
           ))                                                        as detail
    from sim s
    join dna_layer_weights w on w.layer_code = s.layer_code
    group by s.career_id, s.career_name
  ),
  -- Jurusan pengguna: program studi dari daftar, lalu prodi terdekat dari
  -- isian bebas (0051), lalu konsentrasi SMK. Nama yang ditampilkan tetap
  -- yang diketik pengguna, bukan nama prodi hasil pencocokan.
  jurusan as (
    select case when coalesce(p.study_program_id, p.study_program_terdekat_id) is not null
                then 'PRODI' else 'SMK' end                                    as kind,
           coalesce(p.study_program_id, p.study_program_terdekat_id,
                    p.smk_concentration_id)                                    as sid,
           coalesce(sp.name_id, p.study_program_custom, sk.name_id)            as nama
    from profiles p
    left join study_programs sp     on sp.id = p.study_program_id
    left join smk_concentrations sk on sk.id = p.smk_concentration_id
    where p.user_id = p_user_id
      and coalesce(p.study_program_id, p.study_program_terdekat_id,
                   p.smk_concentration_id) is not null
  ),
  relevan as (
    select e.career_id, max(e.relevance) as relevansi, max(j.nama) as nama
    from jurusan j
    join education_career e on e.source_kind = j.kind and e.source_id = j.sid
    group by e.career_id
  ),
  gated as (
    select a.*, r.nama as jurusan_nama, r.relevansi,
           case when r.relevansi >= 80 then 10
                when r.relevansi >= 50 then 5
                -- Pengguna yang punya jurusan: profesi di luar jurusannya turun 10 poin.
                -- Tetap bisa direkomendasikan (untuk yang ingin pindah bidang), tetapi
                -- tidak lagi mengalahkan profesi sejurusan hanya karena DNA-nya umum.
                when exists (select 1 from jurusan) then -10
                else 0 end as bonus_jurusan,
           case when coalesce(a.hit_interest, 0) >= 1
                 and coalesce(a.hit_activity, 0) >= 2
                then 5 else 0 end
           +
           (case when coalesce(a.hit_activity, 0) = 0 then 0.8 else 1.0 end)
           *
           (case when coalesce(a.hit_interest, 0) = 0
                 then least(a.base, 49) else a.base end) as setelah_gate
    from agg a
    left join relevan r on r.career_id = a.career_id
  ),
  akhir as (
    select g.*,
           greatest(least(g.setelah_gate + g.bonus_jurusan, 100), 0) as final,
           case when g.bonus_jurusan <> 0
                then g.detail || jsonb_build_object('JURUSAN', jsonb_build_object(
                       'nama', g.jurusan_nama, 'relevansi', g.relevansi, 'bonus', g.bonus_jurusan))
                else g.detail end as detail_lengkap
    from gated g
  )
  select k.career_id, k.career_name,
         case when d.ok then round(k.final, 2) end,
         case when d.ok then round(k.base, 2) end,
         case when d.ok then b.code end,
         case when d.ok then b.label_id end,
         case when d.ok then k.detail_lengkap end
  from akhir k
  cross join dinilai d
  left join match_score_bands b
         on d.ok and round(k.final, 2) between b.min_score and b.max_score
  order by 3 desc nulls last, k.career_name;
$function$;

CREATE OR REPLACE FUNCTION public.explore_by_study(p_limit integer DEFAULT 12)
 RETURNS TABLE(career_id integer, career_name text, career_description text, sub_industry text, industry_code text, sub_industry_extra integer, demand_score smallint, demand_label text, salary_min integer, salary_max integer, roadmap_months smallint, activity_attributes text[], relevance smallint)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  with me as (select auth.uid() as uid),
  src as (
    select case when coalesce(p.study_program_id, p.study_program_terdekat_id) is not null
                then 'PRODI' else 'SMK' end as kind,
           coalesce(p.study_program_id, p.study_program_terdekat_id, p.smk_concentration_id) as sid
    from profiles p, me where p.user_id = me.uid
  )
  select cc.career_id, cc.career_name, cc.career_description, cc.sub_industry,
         cc.industry_code, cc.sub_industry_extra, cc.demand_score, cc.demand_label,
         cc.salary_min, cc.salary_max, cc.roadmap_months, cc.activity_attributes, e.relevance
  from education_career e
  join src on src.kind = e.source_kind and src.sid = e.source_id
  join public.career_card cc on cc.career_id = e.career_id
  order by e.display_order
  limit greatest(p_limit, 1);
$function$;

CREATE OR REPLACE FUNCTION public.explore_state()
 RETURNS TABLE(full_name text, avatar_url text, has_career boolean, has_dna boolean, dna_step smallint, dna_started boolean, career_id integer, career_name text, percent_done numeric, study_label text, top_activity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  with me as (select auth.uid() as uid),
  akun as (
    select u.email, u.raw_user_meta_data
    from auth.users u, me
    where u.id = me.uid
  ),
  prof as (
    select p.full_name, p.avatar_url, p.study_program_id, p.smk_concentration_id,
           p.study_program_custom
    from profiles p, me where p.user_id = me.uid
  ),
  rm as (
    select ur.career_id, c.career_name, coalesce(pr.percent_done, 0) as percent_done
    from user_roadmaps ur
    join careers c on c.id = ur.career_id
    left join user_roadmap_progress pr on pr.user_roadmap_id = ur.id, me
    where ur.user_id = me.uid and ur.status <> 'dibatalkan'
    order by ur.started_at desc
    limit 1
  ),
  dna as (
    select dp.current_step, dp.completed_at from user_dna_progress dp, me where dp.user_id = me.uid
  ),
  npick as (select count(*) as n from user_dna ud, me where ud.user_id = me.uid),
  act as (
    select a.name_id
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code, me
    where ud.user_id = me.uid and a.layer_code = 'ACTIVITY'
    order by a.display_order
    limit 1
  )
  select
    coalesce(
      nullif(btrim((select full_name from prof)), ''),
      nullif(btrim((select raw_user_meta_data->>'full_name' from akun)), ''),
      nullif(btrim((select raw_user_meta_data->>'name'      from akun)), ''),
      public.nama_dari_email((select email from akun))
    ),
    (select avatar_url from prof),
    (select count(*) from rm) > 0,
    (select completed_at from dna) is not null,
    coalesce((select current_step from dna), 1)::smallint,
    coalesce((select n from npick), 0) > 0,
    (select career_id from rm),
    (select career_name from rm),
    (select percent_done from rm),
    coalesce(
      (select sp.name_id from prof join study_programs sp on sp.id = prof.study_program_id),
      (select sk.name_id from prof join smk_concentrations sk on sk.id = prof.smk_concentration_id),
      -- Prodi yang diketik sendiri. Sebelum 0051 nilainya NULL di sini, dan
      -- Explore menyuruh pengguna "melengkapi program studi" yang sudah diisinya.
      (select nullif(btrim(study_program_custom), '') from prof)
    ),
    (select name_id from act);
$function$;

-- ---------------------------------------------------------------------------
-- 4. Jalur Pendidikan: satu langkah berlangsung
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.langkah_jalur(p_path_id integer)
 RETURNS TABLE(step_order smallint, title_id text, note_id text, step_kind text, status text, otomatis boolean, dicentang boolean, bisa boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
  with o as (select * from public.posisi_studi()),
  d as (
    select s.step_order, s.title_id, s.note_id, s.step_kind, s.step_rank,
           public.status_langkah_jalur(s.step_rank, o.rank_tercapai, o.rank_sedang) as oto,
           exists (select 1 from public.user_education_path_steps u
                    where u.user_id = auth.uid()
                      and u.path_id = s.path_id and u.step_order = s.step_order) as centang
    from public.career_education_path_steps s, o
    where s.path_id = p_path_id
  ),
  -- Hanya satu langkah yang "sedang berlangsung": yang jenjangnya paling
  -- dekat dengan jenjang pengguna. Sebelum 0051 mahasiswa D4 dan S1 melihat
  -- langkah D3 DAN langkah S1 sama-sama berlangsung, karena aturan
  -- status_langkah_jalur menandai semua langkah di bawah jenjangnya.
  d2 as (
    select d.step_order, d.title_id, d.note_id, d.step_kind, d.centang,
           case when d.oto = 'BERLANGSUNG'
                 and d.step_rank < max(d.step_rank) filter (where d.oto = 'BERLANGSUNG') over ()
                then 'BELUM_MULAI' else d.oto end as oto
    from d
  ),
  g as (select d2.*, (d2.oto = 'SELESAI' or d2.centang) as selesai from d2),
  w as (
    select g.*,
           coalesce(lag(g.selesai)  over (order by g.step_order), true)  as sebelum_selesai,
           coalesce(lead(g.centang) over (order by g.step_order), false) as sesudah_dicentang
    from g
  )
  select w.step_order, w.title_id, w.note_id, w.step_kind,
         case when w.selesai then 'SELESAI' else w.oto end,
         w.oto = 'SELESAI',
         w.centang,
         -- bisa diubah: bukan otomatis, pendahulunya selesai, dan kalau sedang
         -- dicentang, langkah sesudahnya belum dicentang
         w.oto <> 'SELESAI' and w.sebelum_selesai and not (w.centang and w.sesudah_dicentang)
  from w
  order by w.step_order;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Jawaban quest
--
--    Partisipan: "Questnya kenapa hanya copy teks? Kenapa tidak ditambahkan
--    jawaban?" Quest berjenis AMBIL (pertanyaan yang dicari jawabannya) kini
--    ditutup dengan menulis jawaban; quest LANGSUNG (magang, melamar) boleh
--    diberi catatan, tidak wajib.
-- ---------------------------------------------------------------------------
alter table public.user_quests add column if not exists jawaban text;
alter table public.user_quests drop constraint if exists chk_uq_jawaban;
alter table public.user_quests add constraint chk_uq_jawaban
  check (jawaban is null or char_length(jawaban) <= 2000);

drop function if exists public.selesaikan_quest(text);

create or replace function public.selesaikan_quest(p_quest_key text, p_jawaban text default null)
returns table (xp integer, total_xp integer, level_name text, badge jsonb)
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user    uuid := auth.uid();
  v_cid     integer := public.profesi_pilihan();
  v_id      bigint;
  v_baru    jsonb;
  v_jawaban text := nullif(btrim(coalesce(p_jawaban, '')), '');
  q record;
begin
  if v_user is null then
    raise exception 'selesaikan_quest: tidak ada pengguna terautentikasi';
  end if;
  if v_cid is null then
    raise exception 'selesaikan_quest: belum ada profesi pilihan';
  end if;

  select s.*, k.mode into q
  from public.quest_status(v_cid) s
  join public.quest_group_kinds k on k.code = s.group_kind
  where s.quest_key = p_quest_key;

  if not found then
    raise exception 'selesaikan_quest: quest % bukan milik profesi pilihanmu', p_quest_key;
  end if;
  if q.status = 'SELESAI' then
    raise exception 'selesaikan_quest: quest % sudah selesai', p_quest_key;
  end if;
  if v_jawaban is not null and char_length(v_jawaban) > 2000 then
    raise exception 'selesaikan_quest: jawaban terlalu panjang, maksimal 2000 karakter.';
  end if;

  if q.mode = 'AMBIL' then
    if q.status <> 'DIAMBIL' then
      raise exception 'selesaikan_quest: ambil quest % dulu', p_quest_key;
    end if;
    if v_jawaban is null or char_length(v_jawaban) < 20 then
      raise exception 'selesaikan_quest: tulis jawabanmu dulu, minimal 20 karakter.';
    end if;
    update public.user_quests
       set status = 'SELESAI', completed_at = now(), jawaban = v_jawaban
     where user_id = v_user and career_id = v_cid and quest_key = p_quest_key
    returning id into v_id;
  else
    if not q.bisa then
      raise exception 'selesaikan_quest: %', coalesce(q.alasan, 'quest belum terbuka');
    end if;
    insert into public.user_quests (user_id, career_id, quest_key, status, xp, completed_at, jawaban)
    values (v_user, v_cid, p_quest_key, 'SELESAI', q.xp, now(), v_jawaban)
    returning id into v_id;
  end if;

  insert into public.xp_ledger (user_id, source_kind, source_id, xp, reason)
  values (v_user, 'QUEST', v_id, q.xp, 'Menyelesaikan quest: ' || q.label)
  on conflict do nothing;

  perform public.quest_sinkron_journey(v_user, v_cid);
  v_baru := public.sinkron_pencapaian();

  return query
    select q.xp::integer, x.total_xp, x.level_name,
           case when jsonb_array_length(v_baru) > 0 then v_baru -> 0 end
    from public.xp_pengguna() x;
end $$;

comment on function public.selesaikan_quest(text, text) is
  'Selesaikan satu quest (0051: quest AMBIL wajib dijawab, minimal 20 karakter). Tulis XP sekali, bagikan badge lewat sinkron_pencapaian(), perbarui Journey.';

revoke all on function public.selesaikan_quest(text, text) from public, anon;
grant execute on function public.selesaikan_quest(text, text) to authenticated;

-- quest_grup: tambah career_id (tautan "Baca detail profesi" di banner
-- sumber) dan jawaban tiap quest. Bentuk kembaliannya berubah, jadi
-- fungsinya dibuat ulang.
drop function if exists public.quest_grup(text, text);

create function public.quest_grup(p_slug text, p_group_code text)
returns table (
  jenis text, kode text, label text, judul text, subjudul text, mode text,
  berurutan boolean, terbuka boolean, alasan_kunci text,
  tips jsonb, tujuan jsonb, catatan text, quest jsonb, career_id integer
)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with k as (select * from public.quest_group_kinds where slug = p_slug),
  pilih as (select public.profesi_pilihan() as cid),
  st as (
    select s.* from pilih, k, public.quest_status(pilih.cid) s
    where pilih.cid is not null and s.group_kind = k.code and s.group_code = p_group_code
  ),
  jwb as (
    select uq.quest_key, uq.jawaban
    from public.user_quests uq, pilih
    where uq.user_id = auth.uid() and uq.career_id = pilih.cid
  )
  select
    k.code, p_group_code, k.label_id,
    (select group_title from st limit 1),
    (select group_subtitle from st limit 1),
    k.mode, k.berurutan,
    coalesce((select bool_and(grup_terbuka) from st), false),
    k.alasan_kunci,
    jsonb_build_object(
      'gambar', k.tips_gambar, 'label', k.tips_label,
      'judul', k.tips_judul, 'isi', nullif(k.tips_isi, ''), 'sumber', k.tips_sumber),
    case k.code
      when 'EKSPLORASI' then
        '["Kenali profesi impian","Rutinitas kerja profesi","Mantapkan pilihan karier"]'::jsonb
      when 'SOFT_SKILL' then
        (select f.tujuan from public.soft_skill_focus f where f.attr_code = p_group_code)
    end,
    k.catatan_id,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'key',       s.quest_key,
        'label',     s.label,
        'teks',      s.teks,
        'min_menit', s.min_menit,
        'max_menit', s.max_menit,
        'xp',        s.xp,
        'status',    s.status,
        'bisa',      s.bisa,
        'alasan',    s.alasan,
        'jawaban',   (select j.jawaban from jwb j where j.quest_key = s.quest_key)
      ) order by s.item_order)
      from st s
    ), '[]'::jsonb),
    (select cid from pilih)
  from k
  where exists (select 1 from st);
$$;

comment on function public.quest_grup(text, text) is
  'Isi satu grup quest: header, banner tips, Tujuan Quest, catatan, daftar quest berstatus beserta jawaban pengguna (0051), dan profesi pilihannya.';

revoke all on function public.quest_grup(text, text) from public, anon;
grant execute on function public.quest_grup(text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Hari beruntun
--
--    Satu hari dihitung kalau ada minimal satu quest yang diselesaikan, menurut
--    tanggal WIB. Rangkaian tetap hidup sampai akhir hari berikutnya: belum
--    mengerjakan apa-apa hari ini tidak langsung memutusnya.
-- ---------------------------------------------------------------------------
create or replace function public.quest_streak()
returns table (hari integer, hari_ini boolean, total_hari integer)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with h as (
    select distinct (uq.completed_at at time zone 'Asia/Jakarta')::date as d
    from public.user_quests uq
    where uq.user_id = auth.uid() and uq.completed_at is not null
  ),
  t as (select (now() at time zone 'Asia/Jakarta')::date as hari),
  g as (select h.d, h.d + (row_number() over (order by h.d desc))::integer as k from h),
  ujung as (select max(d) as d from h)
  select
    case when (select d from ujung) >= (select hari from t) - 1
         then (select count(*)::integer from g
               where g.k = (select g2.k from g g2 where g2.d = (select d from ujung)))
         else 0 end,
    coalesce((select d from ujung) = (select hari from t), false),
    (select count(*)::integer from h);
$$;

comment on function public.quest_streak() is
  'Hari beruntun (WIB) pengguna menyelesaikan minimal satu quest, apakah hari ini sudah, dan total hari aktif.';

revoke all on function public.quest_streak() from public, anon;
grant execute on function public.quest_streak() to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Peringkat kecocokan
-- ---------------------------------------------------------------------------
create or replace function public.peringkat_match(p_career_id integer)
returns table (peringkat integer, total integer)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with s as (
    select m.career_id,
           rank() over (order by m.match_score desc) as r,
           count(*) over () as n
    from public.career_match_scores(auth.uid()) m
    where m.match_score is not null
  )
  select s.r::integer, s.n::integer from s where s.career_id = p_career_id;
$$;

comment on function public.peringkat_match(integer) is
  'Peringkat profesi ini di antara semua profesi menurut Career Match Score pengguna. Kosong kalau Career DNA belum selesai.';

revoke all on function public.peringkat_match(integer) from public, anon;
grant execute on function public.peringkat_match(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare
  n int;
  v text;
begin
  -- Tiap prodi baru punya rumpun dan profesi relevan.
  select count(*) into n from public.study_programs sp
   where sp.source = 'usability_test_0051'
     and (not exists (select 1 from public.study_program_rumpun r where r.program_id = sp.id)
          or not exists (select 1 from public.education_career e
                          where e.source_kind = 'PRODI' and e.source_id = sp.id));
  if n > 0 then raise exception '0051: % prodi baru tanpa rumpun atau profesi relevan', n; end if;

  -- Nama profesi di kurasi harus ada semua (salah ketik = baris hilang diam-diam).
  select count(*) into n from public.education_career e
    join public.study_programs sp on sp.id = e.source_id
   where e.source_kind = 'PRODI' and sp.name_id = 'Kecerdasan Buatan';
  if n < 11 then raise exception '0051: relevansi Kecerdasan Buatan hanya % baris', n; end if;

  -- Pencocokan isian bebas.
  select t.name_id into v from public.prodi_terdekat('Teknik Informatika dan Komputer') t;
  if v is distinct from 'Teknik Informatika' then
    raise exception '0051: "Teknik Informatika dan Komputer" -> %', v; end if;
  select t.name_id into v from public.prodi_terdekat('S1 - Data Science') t;
  if v is distinct from 'Sains Data' then raise exception '0051: "S1 - Data Science" -> %', v; end if;
  select t.name_id into v from public.prodi_terdekat('AI') t;
  if v is distinct from 'Kecerdasan Buatan' then raise exception '0051: "AI" -> %', v; end if;
  select t.name_id into v from public.prodi_terdekat('Akuntansi Syariah') t;
  if v is distinct from 'Akuntansi' then raise exception '0051: "Akuntansi Syariah" -> %', v; end if;
  select t.name_id into v from public.prodi_terdekat('Teknik Sipil Terapan') t;
  if v is distinct from 'Teknik Sipil' then raise exception '0051: "Teknik Sipil Terapan" -> %', v; end if;
  if exists (select 1 from public.prodi_terdekat('Teknik Antariksa Kuantum')) then
    raise exception '0051: isian tanpa padanan tidak boleh dicocokkan';
  end if;

  select count(*) into n from pg_proc where proname = 'selesaikan_quest';
  if n <> 1 then raise exception '0051: selesaikan_quest harus satu versi, ada %', n; end if;

  raise notice '0051: % prodi (% baru), % alias, % profil isian bebas tercocokkan',
    (select count(*) from public.study_programs),
    (select count(*) from public.study_programs where source = 'usability_test_0051'),
    (select count(*) from public.study_program_aliases),
    (select count(*) from public.profiles where study_program_terdekat_id is not null);
end $$;

commit;
