-- ===========================================================================
-- 0029_detail_profesi_api.sql
--
-- RPC untuk layar Detail Profesi (tiga tab) dan lembar Skill Gap Analysis
-- (tiga tab). Semua fungsi stable dan hanya membaca; yang bergantung pengguna
-- memakai auth.uid() sehingga pengunjung yang belum login tetap dapat isi,
-- hanya tanpa skor kecocokan.
--
-- Satu fungsi per tab, bukan satu fungsi raksasa. Tab kedua dan ketiga baru
-- diminta saat pengguna menyentuhnya, jadi membuka satu profesi tidak menarik
-- 8 hard skill + 10 tools + 6 lisensi yang belum tentu dilihat.
--
-- Jalankan setelah 0028. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Mesin alasan versi panjang
--
-- Kartu Explore memakai match_reason() yang mengembalikan satu kalimat.
-- Layar detail menampilkan daftar bercentang dan bertanda seru, jadi butuh
-- semua alasan sekaligus beserta nadanya. Urutan mengikuti desain: yang cocok
-- dulu (hijau), lalu yang perlu dikembangkan (oranye).
-- ---------------------------------------------------------------------------
create or replace function public.match_reasons(p_detail jsonb)
returns jsonb
language sql immutable
set search_path = public
as $$
  with baris as (
    select 1 as urut, 'cocok' as nada,
           'Bidang industri <b>' || (p_detail->'INTEREST'->'cocok'->>0) ||
           '</b> sesuai dengan minat preferensi bidang industri pilihan Kamu' as teks
    where jsonb_array_length(coalesce(p_detail->'INTEREST'->'cocok','[]'::jsonb)) > 0
    union all
    select 2, 'cocok',
           'Rutinitas aktivitas <b>' || (p_detail->'ACTIVITY'->'cocok'->>0) ||
           '</b> profesi ini sesuai dengan preferensi Kamu'
    where jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'cocok','[]'::jsonb)) > 0
    union all
    select 3, 'cocok',
           'Keahlian <b>' || (p_detail->'SKILL'->'cocok'->>0) ||
           '</b> Kamu mendukung kebutuhan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'SKILL'->'cocok','[]'::jsonb)) > 0
    union all
    select 4, 'cocok',
           'Cara kerja <b>' || (p_detail->'WORKSTYLE'->'cocok'->>0) ||
           '</b> Kamu sejalan dengan tuntutan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'WORKSTYLE'->'cocok','[]'::jsonb)) > 0
    union all
    select 5, 'belum',
           'Kamu perlu mengembangkan Keahlian <b>' || (p_detail->'SKILL'->'belum'->>0) ||
           '</b> untuk mendukung kebutuhan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'SKILL'->'belum','[]'::jsonb)) > 0
    union all
    select 6, 'belum',
           'Kamu perlu mengembangkan cara kerja <b>' || (p_detail->'WORKSTYLE'->'belum'->>0) ||
           '</b> yang dibutuhkan profesi ini'
    where jsonb_array_length(coalesce(p_detail->'WORKSTYLE'->'belum','[]'::jsonb)) > 0
    union all
    select 7, 'belum',
           'Rutinitas aktivitas <b>' || (p_detail->'ACTIVITY'->'belum'->>0) ||
           '</b> masih perlu Kamu biasakan di profesi ini'
    where jsonb_array_length(coalesce(p_detail->'ACTIVITY'->'belum','[]'::jsonb)) > 0
      and jsonb_array_length(coalesce(p_detail->'SKILL'->'belum','[]'::jsonb)) = 0
  )
  select coalesce(
    jsonb_agg(jsonb_build_object('nada', nada, 'teks', teks) order by urut),
    '[]'::jsonb)
  from baris;
$$;

comment on function public.match_reasons(jsonb) is
  'Daftar alasan kecocokan untuk layar detail. <b> menandai bagian yang ditebalkan desain; frontend yang memutuskan cara merendernya.';

-- ---------------------------------------------------------------------------
-- 2. Posisi pengguna saat ini
--
-- Kartu "Estimasi Pencapaian Profesi" menampilkan satu baris posisi, mis.
-- "SMU (kelas 10)". Ditulis sebagai fungsi tersendiri supaya layar Roadmap
-- nanti memakai kalimat yang sama persis.
-- ---------------------------------------------------------------------------
create or replace function public.posisi_pengguna()
returns text
language sql stable
set search_path = public
as $$
  select case
    when p.education_level_code is null then null
    when p.grade_level is not null
      then el.level_name || ' (kelas ' || p.grade_level || ')'
    when p.semester is not null
      then el.level_name || ' (semester ' || p.semester || ')'
    when p.graduation_status = 'lulus'
      then 'Lulusan ' || el.level_name
    else el.level_name
  end
  from public.profiles p
  join public.education_levels el on el.code = p.education_level_code
  where p.user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- 3. Label jenjang
--
-- education_levels punya dua baris di rank 6 (D4 dan S1), jadi lookup polos
-- mengembalikan salah satu secara acak. Peta eksplisit ini dipakai di mana pun
-- jenjang minimum ditampilkan.
-- ---------------------------------------------------------------------------
create or replace function public.label_jenjang(p_rank integer)
returns text
language sql immutable
as $$
  select case p_rank
    when 1 then 'SMP / MTs'
    when 2 then 'SMA / SMK'
    when 3 then 'Diploma 1 (D1)'
    when 4 then 'Diploma 2 (D2)'
    when 5 then 'Diploma 3 (D3)'
    when 6 then 'Sarjana (S1) / D4'
    when 7 then 'Magister (S2)'
    when 8 then 'Doktor (S3)'
  end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Tab 1 — Analisa
-- ---------------------------------------------------------------------------
create or replace function public.career_detail(p_career_id integer)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  family_code         text,
  family_name         text,
  match_score         numeric,
  band_code           text,
  band_label          text,
  reasons             jsonb,
  demand_score        smallint,
  demand_label        text,
  growth_pct          numeric,
  salary_min          bigint,
  salary_max          bigint,
  sub_industries      jsonb,
  n_sub_industri      integer,
  roadmap_months      smallint,
  posisi_sekarang     text,
  percent_done        numeric,
  min_education_rank  integer,
  min_education_label text,
  ai_resilience       smallint,
  ai_label            text,
  ai_penjelasan       text,
  is_pilihan          boolean
)
language sql stable
set search_path = public
as $$
  select
    c.id, c.career_name, c.career_description,
    c.family_code, f.name_id,
    s.match_score, s.band_code, s.band_label,
    coalesce(public.match_reasons(s.detail), '[]'::jsonb),
    m.demand_score,
    case when m.demand_score >= 70 then 'Demand tinggi'
         when m.demand_score >= 50 then 'Demand sedang'
         else 'Demand rendah' end,
    m.growth_pct, m.salary_min, m.salary_max,
    coalesce(si.list, '[]'::jsonb),
    coalesce(si.n, 0),
    cc.roadmap_months,
    public.posisi_pengguna(),
    coalesce(rp.percent_done, 0),
    c.min_education_rank,
    public.label_jenjang(c.min_education_rank),
    m.ai_resilience,
    public.ai_label(m.ai_resilience),
    public.ai_penjelasan(m.ai_resilience),
    rp.career_id is not null
  from public.careers c
  left join public.career_families f on f.code = c.family_code
  left join public.career_market m   on m.career_id = c.id
  left join public.career_card cc    on cc.career_id = c.id
  left join public.career_match_scores(auth.uid()) s on s.career_id = c.id
  left join lateral (
    select jsonb_agg(jsonb_build_object(
             'code', su.code, 'nama', su.name_id,
             'industry_code', su.industry_code)
             order by csi.is_primary desc, su.name_id) as list,
           count(*)::int as n
    from public.career_sub_industries csi
    join public.sub_industries su on su.code = csi.sub_industry_code
    where csi.career_id = c.id
  ) si on true
  left join public.user_roadmap_progress rp
         on rp.career_id = c.id and rp.user_id = auth.uid()
            and rp.status <> 'dibatalkan'
  where c.id = p_career_id and c.is_active;
$$;

comment on function public.career_detail(integer) is
  'Tab Analisa layar Detail Profesi. Skor kecocokan null kalau pengguna belum mengisi Career DNA.';

-- ---------------------------------------------------------------------------
-- 5. Tab 2 — Skill & Kompetensi
--
-- Satu panggilan mengembalikan keempat blok sebagai jsonb, bukan empat
-- panggilan: keempatnya tampil bersamaan begitu tab dibuka, dan memisahnya
-- hanya menambah bolak-balik jaringan di koneksi seluler.
-- ---------------------------------------------------------------------------
create or replace function public.career_competency(p_career_id integer)
returns table (
  pendidikan  jsonb,
  soft_skill  jsonb,
  hard_skill  jsonb,
  tools       jsonb,
  lisensi     jsonb
)
language sql stable
set search_path = public
as $$
  select
    -- Pendidikan: satu baris untuk profesi tunggal.
    (select jsonb_build_array(jsonb_build_object(
       'jenjang', public.label_jenjang(c.min_education_rank),
       'catatan', 'Standar kelulusan minimum untuk ' || lower(c.career_name) || '.'))
     from public.careers c where c.id = p_career_id),

    -- Soft skill: atribut DNA dominan profesi, lapis aktivitas dan keahlian.
    (select coalesce(jsonb_agg(jsonb_build_object(
       'layer',     a.layer_code,
       'nama',      a.name_id,
       'deskripsi', a.description_id) order by a.layer_code, d.rank_in_layer), '[]'::jsonb)
     from public.careers c
     join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
     join public.dna_attributes a on a.code = d.attribute_code
     where c.id = p_career_id and a.layer_code in ('ACTIVITY','SKILL')),

    (select coalesce(jsonb_agg(jsonb_build_object(
       'kode', v.skill_code, 'nama', v.nama, 'deskripsi', v.deskripsi)
       order by v.display_order), '[]'::jsonb)
     from public.career_hard_skill_view v where v.career_id = p_career_id),

    (select coalesce(jsonb_agg(jsonb_build_object(
       'kode', v.tool_code, 'nama', v.nama, 'deskripsi', v.deskripsi,
       'contoh', v.contoh_produk, 'fase', v.fase_code)
       order by v.fase_order, v.display_order), '[]'::jsonb)
     from public.career_tool_view v where v.career_id = p_career_id),

    (select coalesce(jsonb_agg(jsonb_build_object(
       'kode', v.license_code, 'nama', v.nama, 'penerbit', v.penerbit,
       'sifat', v.sifat, 'deskripsi', v.deskripsi)
       order by v.display_order), '[]'::jsonb)
     from public.career_license_view v where v.career_id = p_career_id);
$$;

-- ---------------------------------------------------------------------------
-- 6. Tab 3 — Insight
-- ---------------------------------------------------------------------------
create or replace function public.career_insight(p_career_id integer)
returns table (
  gaji           jsonb,
  ai_resilience  smallint,
  ai_label       text,
  ai_penjelasan  text,
  sumber_gaji    text
)
language sql stable
set search_path = public
as $$
  select
    (select coalesce(jsonb_agg(jsonb_build_object(
       'kode', v.level_code, 'tingkat', v.tingkat, 'pengalaman', v.pengalaman,
       'salary_min', v.salary_min, 'salary_max', v.salary_max)
       order by v.sort_order), '[]'::jsonb)
     from public.career_salary_band_view v where v.career_id = p_career_id),
    m.ai_resilience,
    public.ai_label(m.ai_resilience),
    public.ai_penjelasan(m.ai_resilience),
    'Estimasi model dari berbagai sumber situs kerja, bukan survei resmi.'
  from public.career_market m
  where m.career_id = p_career_id;
$$;

-- ---------------------------------------------------------------------------
-- 7. Skill Gap Analysis
--
-- Yang membedakan lembar ini dari tab Skill & Kompetensi adalah pembandingnya:
-- di sini soft skill dipecah menjadi yang sudah dimiliki pengguna dan yang
-- belum, memakai jawaban Career DNA-nya. Kalau DNA belum diisi, semuanya
-- masuk kelompok "perlu dikembangkan" -- itu jujur, karena memang belum ada
-- yang bisa diklaim.
-- ---------------------------------------------------------------------------
create or replace function public.career_skill_gap(p_career_id integer)
returns table (
  hard_skill      jsonb,
  soft_sesuai     jsonb,
  soft_kembangkan jsonb,
  tools           jsonb,
  has_dna         boolean
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  punya as (
    select ud.attribute_code from public.user_dna ud, me where ud.user_id = me.uid
  ),
  atribut as (
    select a.layer_code, a.name_id, d.rank_in_layer,
           (p.attribute_code is not null) as dimiliki
    from public.careers c
    join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join public.dna_attributes a on a.code = d.attribute_code
    left join punya p on p.attribute_code = a.code
    where c.id = p_career_id and a.layer_code in ('ACTIVITY','SKILL')
  )
  select
    (select coalesce(jsonb_agg(jsonb_build_object(
       'nama', v.nama, 'deskripsi', v.deskripsi) order by v.display_order), '[]'::jsonb)
     from public.career_hard_skill_view v where v.career_id = p_career_id),
    (select coalesce(jsonb_object_agg(layer_code, arr), '{}'::jsonb) from (
       select layer_code, jsonb_agg(name_id order by rank_in_layer) as arr
       from atribut where dimiliki group by layer_code) x),
    (select coalesce(jsonb_object_agg(layer_code, arr), '{}'::jsonb) from (
       select layer_code, jsonb_agg(name_id order by rank_in_layer) as arr
       from atribut where not dimiliki group by layer_code) x),
    (select coalesce(jsonb_agg(jsonb_build_object(
       'fase', f.code, 'fase_nama', f.name_id, 'fase_subtitle', f.subtitle,
       'isi', f.isi) order by f.sort_order), '[]'::jsonb)
     from (
       select p.code, p.name_id, p.subtitle, p.sort_order,
              jsonb_agg(jsonb_build_object(
                'nama', v.nama, 'deskripsi', v.deskripsi, 'contoh', v.contoh_produk)
                order by v.display_order) as isi
       from public.career_tool_view v
       join public.tool_phases p on p.code = v.fase_code
       where v.career_id = p_career_id
       group by p.code, p.name_id, p.subtitle, p.sort_order
     ) f),
    (select count(*) > 0 from punya);
$$;

comment on function public.career_skill_gap(integer) is
  'Lembar Skill Gap Analysis. soft_sesuai dan soft_kembangkan dikelompokkan per lapisan DNA supaya tampilan bisa memberi judul "Atribut Aktivitas" dan "Atribut Keahlian".';

-- ---------------------------------------------------------------------------
-- 8. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_n int; r record;
begin
  select count(*) into v_n from public.career_detail(267);
  if v_n <> 1 then
    raise exception '0029: career_detail tidak mengembalikan tepat satu baris (dapat %)', v_n;
  end if;

  select jsonb_array_length(hard_skill) as nh,
         jsonb_array_length(tools)      as nt,
         jsonb_array_length(lisensi)    as nl
    into r
  from public.career_competency(267);
  if r.nh < 4 or r.nt < 3 or r.nl < 3 then
    raise exception '0029: career_competency kurang isi (hard %, tools %, lisensi %)',
      r.nh, r.nt, r.nl;
  end if;

  raise notice '0029: RPC detail profesi siap';
end $$;

commit;
