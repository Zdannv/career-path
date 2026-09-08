-- ===========================================================================
-- 0030_kategori_dan_pencarian_api.sql
--
-- Dua layar terakhir dari alur Detail Profesi:
--   * Detail Kategori  -- dua tab: Ringkasan dan Profesi di kategori ini
--   * Pencarian & Filter
--
-- ---------------------------------------------------------------------------
-- Apa yang dipakai sebagai "kategori"
-- ---------------------------------------------------------------------------
-- Desain menyebutnya kategori profesi: satu payung untuk profesi yang punya
-- banyak spesialisasi atau banyak nama lain tetapi fungsinya sama, dan tiap
-- anggotanya tetap bisa berdiri sendiri di pencarian.
--
-- Struktur itu sudah ada di career_families sejak 0013 dan diberi nama layak
-- di 0014: 61 rumpun berbasis SOC minor group, tiap profesi aktif menunjuk
-- tepat satu. Jadi layar ini dibangun di atas career_families, bukan taksonomi
-- baru.
--
-- Yang perlu diketahui: rumpun kita lebih lebar daripada contoh di desain.
-- Desain memakai "Perawat (Ners)" berisi sembilan varian perawat; rumpun kita
-- "Perawat, Bidan & Terapis Klinis" berisi 17 profesi termasuk bidan dan
-- terapis. Layarnya bekerja sama saja, tapi kalau tim ingin persis seperti
-- mockup, yang perlu dikerjakan adalah mengkurasi career_families lebih halus
-- -- bukan mengubah RPC ini.
--
-- ---------------------------------------------------------------------------
-- Angka agregat kategori
-- ---------------------------------------------------------------------------
-- Kartu ringkasan kategori memakai gabungan anggotanya, bukan angka baru:
--   gaji            min(salary_min) .. max(salary_max) seluruh anggota
--   sub-industri    jumlah sub-industri berbeda yang dipakai anggota
--   pertumbuhan     yang tertinggi di antara anggota
--   skor kecocokan  yang tertinggi di antara anggota -- kategori dianggap
--                   cocok kalau ada satu jalur di dalamnya yang cocok
--   atribut         atribut yang paling sering muncul di anggota
--
-- Jalankan setelah 0029. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Ringkasan kategori
-- ---------------------------------------------------------------------------
create or replace function public.family_detail(p_family_code text)
returns table (
  family_code    text,
  family_name    text,
  description_id text,
  n_profesi      integer,
  match_score    numeric,
  band_code      text,
  band_label     text,
  salary_min     bigint,
  salary_max     bigint,
  n_sub_industri integer,
  growth_pct     numeric,
  demand_label   text,
  atribut        jsonb,
  pendidikan     jsonb
)
language sql stable
set search_path = public
as $$
  with anggota as (
    select c.id, c.min_education_rank, c.career_name
    from public.careers c
    where c.is_active and c.family_code = p_family_code
  ),
  pasar as (
    select min(m.salary_min) as smin, max(m.salary_max) as smax,
           max(m.growth_pct) as growth, max(m.demand_score) as demand
    from public.career_market m join anggota a on a.id = m.career_id
  ),
  subind as (
    select count(distinct csi.sub_industry_code)::int as n
    from public.career_sub_industries csi join anggota a on a.id = csi.career_id
  ),
  skor as (
    select s.match_score, s.band_code, s.band_label
    from public.career_match_scores(auth.uid()) s
    join anggota a on a.id = s.career_id
    order by s.match_score desc
    limit 1
  ),
  atr as (
    -- Atribut yang paling sering muncul di anggota rumpun. Batas empat per
    -- lapisan mengikuti desain, yang menampilkan chip dalam dua baris.
    select l.code as layer_code, l.name_id as layer_name, l.display_order,
           jsonb_agg(x.name_id order by x.n desc, x.name_id) as isi
    from (
      select a2.layer_code, a2.name_id, count(*) as n,
             row_number() over (partition by a2.layer_code
                                order by count(*) desc, a2.name_id) as rn
      from anggota an
      join public.careers c on c.id = an.id
      join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
      join public.dna_attributes a2 on a2.code = d.attribute_code
      group by a2.layer_code, a2.name_id
    ) x
    join public.dna_layers l on l.code = x.layer_code
    where x.rn <= 6
    group by l.code, l.name_id, l.display_order
  ),
  pend as (
    -- Satu baris per jenjang minimum yang dipakai anggota, dengan contoh
    -- profesinya -- itulah isi kolom kanan tabel "Minimum Pendidikan".
    select a.min_education_rank as rank,
           public.label_jenjang(a.min_education_rank) as jenjang,
           count(*)::int as n,
           string_agg(a.career_name, ', ' order by a.career_name) as contoh
    from anggota a
    group by a.min_education_rank
  )
  select
    f.code, f.name_id, f.description_id,
    (select count(*)::int from anggota),
    (select match_score from skor), (select band_code from skor),
    (select band_label from skor),
    p.smin, p.smax, (select n from subind), p.growth,
    case when p.demand >= 70 then 'Demand tinggi'
         when p.demand >= 50 then 'Demand sedang'
         else 'Demand rendah' end,
    (select coalesce(jsonb_agg(jsonb_build_object(
       'layer', layer_code, 'judul', 'Atribut ' || layer_name, 'isi', isi)
       order by display_order), '[]'::jsonb) from atr),
    (select coalesce(jsonb_agg(jsonb_build_object(
       'jenjang', jenjang,
       'catatan', case
         when n = (select count(*) from anggota)
           then 'Standar minimum untuk seluruh profesi di kategori ini.'
         when n = 1
           then contoh || ' memerlukan minimal ' || jenjang || '.'
         else n || ' profesi di kategori ini memerlukan minimal ' || jenjang ||
              ', antara lain ' || split_part(contoh, ', ', 1) || '.'
       end) order by rank), '[]'::jsonb) from pend)
  from public.career_families f, pasar p
  where f.code = p_family_code;
$$;

comment on function public.family_detail(text) is
  'Tab Ringkasan layar Detail Kategori. Seluruh angka adalah agregat anggota rumpun, bukan data terpisah.';

-- ---------------------------------------------------------------------------
-- 2. Daftar profesi di dalam kategori
--
-- Dropdown "Berdasarkan Bidang Sub Industri" menyaring daftar ini. NULL berarti
-- "Semua Sub Industri".
-- ---------------------------------------------------------------------------
create or replace function public.family_careers(
  p_family_code   text,
  p_sub_industry  text default null,
  p_limit         integer default 50
)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          bigint,
  salary_max          bigint,
  match_score         numeric,
  band_code           text
)
language sql stable
set search_path = public
as $$
  select cc.career_id, cc.career_name, cc.career_description,
         cc.sub_industry, cc.industry_code, cc.sub_industry_extra,
         cc.demand_score, cc.demand_label, cc.salary_min, cc.salary_max,
         s.match_score, s.band_code
  from public.career_card cc
  join public.careers c on c.id = cc.career_id
  left join public.career_match_scores(auth.uid()) s on s.career_id = cc.career_id
  where c.family_code = p_family_code
    and (p_sub_industry is null or exists (
          select 1 from public.career_sub_industries csi
          where csi.career_id = cc.career_id
            and csi.sub_industry_code = p_sub_industry))
  order by s.match_score desc nulls last, cc.demand_score desc nulls last, cc.career_name
  limit greatest(p_limit, 1);
$$;

/** Isi dropdown sub-industri pada layar kategori. */
create or replace function public.family_sub_industries(p_family_code text)
returns table (code text, nama text, n_profesi integer)
language sql stable
set search_path = public
as $$
  select su.code, su.name_id, count(distinct c.id)::int
  from public.careers c
  join public.career_sub_industries csi on csi.career_id = c.id
  join public.sub_industries su on su.code = csi.sub_industry_code
  where c.is_active and c.family_code = p_family_code
  group by su.code, su.name_id
  order by 3 desc, 2;
$$;

-- ---------------------------------------------------------------------------
-- 3. Saran pencarian
--
-- Dua keadaan: kotak kosong menampilkan "Terpopuler", kotak terisi menampilkan
-- nama yang cocok. Keduanya satu fungsi supaya frontend tidak perlu memilih.
-- ---------------------------------------------------------------------------
create or replace function public.search_suggest(
  p_query text default null,
  p_limit integer default 8
)
returns table (
  career_id      integer,
  career_name    text,
  family_code    text,
  sub_industries jsonb,
  extra          integer,
  is_populer     boolean
)
language sql stable
set search_path = public
as $$
  with q as (select nullif(btrim(coalesce(p_query, '')), '') as t),
  kandidat as (
    select c.id, c.career_name, c.family_code, m.demand_score,
           case when (select t from q) is null then 1
                when c.career_name ilike (select t from q) || '%' then 0
                else 1 end as awalan
    from public.careers c
    left join public.career_market m on m.career_id = c.id
    where c.is_active
      and ((select t from q) is null
           or c.career_name ilike '%' || (select t from q) || '%'
           or coalesce(c.name_alt, '') ilike '%' || (select t from q) || '%')
  )
  select k.id, k.career_name, k.family_code,
         coalesce(si.dua, '[]'::jsonb), coalesce(si.sisa, 0),
         (select t from q) is null
  from kandidat k
  left join lateral (
    select jsonb_agg(x.name_id order by x.rn) filter (where x.rn <= 2) as dua,
           greatest(count(*)::int - 2, 0) as sisa
    from (
      select su.name_id,
             row_number() over (order by csi.is_primary desc, su.name_id) as rn
      from public.career_sub_industries csi
      join public.sub_industries su on su.code = csi.sub_industry_code
      where csi.career_id = k.id
    ) x
  ) si on true
  order by k.awalan, k.demand_score desc nulls last, k.career_name
  limit greatest(p_limit, 1);
$$;

comment on function public.search_suggest(text, integer) is
  'Saran di kotak pencarian. Query kosong mengembalikan profesi paling diminati (is_populer true).';

-- ---------------------------------------------------------------------------
-- 4. Pilihan filter
--
-- Dikirim sebagai satu panggilan supaya lembar Filters bisa dirender sekali
-- jalan, lengkap dengan batas bawah dan atas slider gaji yang sesungguhnya.
-- ---------------------------------------------------------------------------
create or replace function public.search_filter_options()
returns table (
  industri     jsonb,
  jenjang      jsonb,
  keahlian     jsonb,
  gaji_min     bigint,
  gaji_max     bigint
)
language sql stable
set search_path = public
as $$
  select
    -- "Minat Bidang Industri" di desain adalah lapisan INTEREST Career DNA
    -- (Teknologi, Kesehatan, Sosial & Pelayanan, ...), bukan tabel industries
    -- yang isinya nama sektor pasar. Memakai atribut DNA membuat filter ini
    -- berbicara bahasa yang sama dengan Career DNA dan skor kecocokan.
    (select coalesce(jsonb_agg(jsonb_build_object(
       'code', a.code, 'nama', a.name_id, 'n_profesi', coalesce(x.n, 0))
       order by a.display_order), '[]'::jsonb)
     from public.dna_attributes a
     left join (select d.attribute_code, count(distinct c.id)::int as n
                from public.careers c
                join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
                where c.is_active
                group by d.attribute_code) x on x.attribute_code = a.code
     where a.layer_code = 'INTEREST' and a.is_active),
    -- Tiga pilihan saja, seperti desain: SMU/SMK, Diploma, Sarjana ke atas.
    jsonb_build_array(
      jsonb_build_object('code', 'SMA', 'nama', 'SMU/SMK',      'rank_max', 2),
      jsonb_build_object('code', 'DIP', 'nama', 'Diploma',      'rank_max', 5),
      jsonb_build_object('code', 'S1',  'nama', 'Sarjana (S1)', 'rank_max', 6)),
    (select coalesce(jsonb_agg(jsonb_build_object(
       'code', a.code, 'nama', a.name_id) order by a.display_order), '[]'::jsonb)
     from public.dna_attributes a where a.layer_code = 'SKILL' and a.is_active),
    (select min(salary_min) from public.career_market),
    (select max(salary_max) from public.career_market);
$$;

-- ---------------------------------------------------------------------------
-- 5. Pencarian dengan filter
--
-- p_rank_max mengikuti pilihan "Minimum Pendidikan": pengguna mencentang
-- jenjang yang sanggup ia tempuh, jadi yang dicari adalah profesi yang syarat
-- minimumnya TIDAK LEBIH TINGGI dari itu -- bukan yang sama persis.
--
-- p_skills memakai logika ATAU, bukan DAN: mencentang tiga keahlian berarti
-- "tampilkan profesi yang butuh salah satu dari ini". Mencentang tiga dengan
-- logika DAN hampir selalu mengosongkan hasil.
-- ---------------------------------------------------------------------------
create or replace function public.search_careers(
  p_query      text    default null,
  p_industries text[]  default null,
  p_salary_min bigint  default null,
  p_salary_max bigint  default null,
  p_rank_max   integer default null,
  p_skills     text[]  default null,
  p_limit      integer default 20,
  p_offset     integer default 0
)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          bigint,
  salary_max          bigint,
  match_score         numeric,
  band_code           text,
  skill_chips         text[],
  total               bigint
)
language sql stable
set search_path = public
as $$
  with saring as (
    select c.id
    from public.careers c
    left join public.career_market m on m.career_id = c.id
    where c.is_active
      and (p_query is null or btrim(p_query) = ''
           or c.career_name ilike '%' || btrim(p_query) || '%'
           or coalesce(c.name_alt, '') ilike '%' || btrim(p_query) || '%'
           or coalesce(c.career_description, '') ilike '%' || btrim(p_query) || '%')
      and (p_rank_max is null or c.min_education_rank <= p_rank_max)
      and (p_salary_min is null or coalesce(m.salary_max, 0) >= p_salary_min)
      and (p_salary_max is null or coalesce(m.salary_min, 0) <= p_salary_max)
      -- p_industries berisi kode atribut DNA lapisan INTEREST, bukan kode
      -- industries: lihat search_filter_options di atas.
      and (p_industries is null or cardinality(p_industries) = 0 or exists (
            select 1 from public.onet_dna d
            where d.soc_code = c.soc_code and d.is_dominant
              and d.attribute_code = any (p_industries)))
      and (p_skills is null or cardinality(p_skills) = 0 or exists (
            select 1 from public.onet_dna d
            where d.soc_code = c.soc_code and d.is_dominant
              and d.attribute_code = any (p_skills)))
  ),
  n as (select count(*) as total from saring)
  select cc.career_id, cc.career_name, cc.career_description,
         cc.sub_industry, cc.industry_code, cc.sub_industry_extra,
         cc.demand_score, cc.demand_label, cc.salary_min, cc.salary_max,
         s.match_score, s.band_code,
         coalesce(sk.chips, array[]::text[]),
         n.total
  from saring f
  join public.career_card cc on cc.career_id = f.id
  left join public.career_match_scores(auth.uid()) s on s.career_id = f.id
  left join lateral (
    select array_agg(a.name_id order by d.rank_in_layer) as chips
    from public.careers c2
    join public.onet_dna d on d.soc_code = c2.soc_code and d.is_dominant
    join public.dna_attributes a on a.code = d.attribute_code and a.layer_code = 'SKILL'
    where c2.id = f.id and d.rank_in_layer <= 3
  ) sk on true, n
  order by s.match_score desc nulls last, cc.demand_score desc nulls last, cc.career_name
  limit greatest(p_limit, 1) offset greatest(p_offset, 0);
$$;

comment on function public.search_careers is
  'Hasil pencarian beserta filter lembar Filters. Kolom total sama di semua baris: jumlah profesi yang lolos filter, dipakai tombol "Tampilkan N Profesi".';

/** Jumlah hasil saja, untuk memperbarui angka di tombol saat filter diubah. */
create or replace function public.search_count(
  p_query      text    default null,
  p_industries text[]  default null,
  p_salary_min bigint  default null,
  p_salary_max bigint  default null,
  p_rank_max   integer default null,
  p_skills     text[]  default null
)
returns bigint
language sql stable
set search_path = public
as $$
  select coalesce((select total from public.search_careers(
    p_query, p_industries, p_salary_min, p_salary_max, p_rank_max, p_skills, 1, 0)), 0);
$$;

-- ---------------------------------------------------------------------------
-- 6. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_fam text; v_n int; v_tot bigint;
begin
  select c.family_code into v_fam from public.careers c where c.id = 267;

  select count(*) into v_n from public.family_detail(v_fam);
  if v_n <> 1 then
    raise exception '0030: family_detail mengembalikan % baris', v_n;
  end if;

  select count(*) into v_n from public.family_careers(v_fam);
  if v_n < 1 then
    raise exception '0030: family_careers kosong untuk rumpun %', v_fam;
  end if;

  select count(*) into v_n from public.search_suggest(null, 5);
  if v_n <> 5 then
    raise exception '0030: search_suggest tanpa query mengembalikan % baris', v_n;
  end if;

  select public.search_count() into v_tot;
  if v_tot < 400 then
    raise exception '0030: search_count tanpa filter cuma % profesi', v_tot;
  end if;

  raise notice '0030: RPC kategori & pencarian siap (% profesi tanpa filter)', v_tot;
end $$;

commit;
