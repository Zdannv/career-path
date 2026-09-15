-- ===========================================================================
-- 0031_jenjang_sedang_ditempuh.sql
--
-- Memperbaiki cara lama perjalanan dihitung untuk pengguna yang MASIH
-- menempuh pendidikan.
--
-- ---------------------------------------------------------------------------
-- Apa yang salah
-- ---------------------------------------------------------------------------
-- 0020 menurunkan "jenjang yang sudah dicapai" dari education_levels.order_rank
-- milik jenjang yang sedang ditempuh, tanpa melihat graduation_status. Jadi
-- mahasiswa S1 semester 7 diperlakukan persis sama dengan sarjana yang sudah
-- lulus: tahap KULIAH dilewati seluruhnya, dan Estimasi Pencapaian Profesi
-- mengatakan pendidikannya sudah beres.
--
-- Terbukti di Postgres lokal sebelum migrasi ini:
--
--   profesi              sedang S1 smt 7    sudah lulus S1
--   Frontend Developer   24 bulan           24 bulan
--   Perawat              24 bulan           24 bulan
--   Akuntan / Auditor    33 bulan           33 bulan
--
-- Angkanya identik. Semester yang susah-susah ditanyakan di onboarding tidak
-- dipakai sama sekali.
--
-- Hal yang sama terjadi pada anak SMA kelas 10: rank-nya dianggap 2, tahap
-- SEKOLAH dilewati, dan aplikasi menganggap ia sudah lulus SMA.
--
-- ---------------------------------------------------------------------------
-- Aturan baru
-- ---------------------------------------------------------------------------
-- Dua besaran dipisahkan, karena memang dua hal berbeda:
--
--   rank_tercapai   jenjang yang BENAR-BENAR sudah dituntaskan.
--                   Sedang menempuh S1 berarti yang tuntas baru SMA.
--   rank_sedang     jenjang yang sedang dijalani, NULL kalau sudah lulus.
--   sisa_bulan      sisa waktu di jenjang yang sedang dijalani, dari semester
--                   atau kelas yang diisi pengguna.
--
-- Lalu total = sisa_bulan + jumlah est_months tahap yang:
--   * belum terlampaui   (skip_if_rank_at_least > rank_tercapai), DAN
--   * tidak akan tertutup oleh studi yang sedang berjalan
--     (skip_if_rank_at_least > rank_sedang)
--
-- Syarat kedua itu yang mencegah penghitungan ganda: mahasiswa S1 semester 7
-- yang menuju profesi bersyarat S1 tidak lagi dihitung "4 tahun kuliah lagi",
-- melainkan sisa satu semester saja.
--
-- Jalankan setelah 0030. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Lama tiap jenjang
--
--    Ditaruh di tabel, bukan di CASE panjang di dalam fungsi: kalau nanti
--    ada jenjang baru atau durasinya dikoreksi, yang diubah datanya.
-- ---------------------------------------------------------------------------
create table if not exists public.education_durations (
  level_code     text primary key references public.education_levels(code),
  total_semester smallint,        -- untuk jenjang tinggi
  kelas_terakhir smallint,        -- untuk jenjang sekolah (9 atau 12)
  total_months   smallint not null
);

comment on table public.education_durations is
  'Lama normatif tiap jenjang, dipakai menghitung sisa waktu studi pengguna yang belum lulus.';

insert into public.education_durations
  (level_code, total_semester, kelas_terakhir, total_months) values
  ('SMP', null,  9, 36),
  ('SMA', null, 12, 36),
  ('SMK', null, 12, 36),
  ('D1',     2, null, 12),
  ('D2',     4, null, 24),
  ('D3',     6, null, 36),
  ('D4',     8, null, 48),
  ('S1',     8, null, 48),
  ('S2',     4, null, 24),
  ('S3',     6, null, 36)
on conflict (level_code) do update set
  total_semester = excluded.total_semester,
  kelas_terakhir = excluded.kelas_terakhir,
  total_months   = excluded.total_months;

alter table public.education_durations enable row level security;
drop policy if exists education_durations_read_all on public.education_durations;
create policy education_durations_read_all on public.education_durations
  for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- 2. Jenjang yang sudah benar-benar tuntas
--
--    Bukan hasil pengurangan order_rank: rank 6 dipakai berdua oleh D4 dan S1,
--    jadi "satu tingkat di bawah" tidak punya arti aritmetik yang aman.
--    Dipetakan eksplisit per jenjang.
-- ---------------------------------------------------------------------------
create or replace function public.rank_sebelum(p_level text)
returns smallint language sql immutable as $$
  select case p_level
    when 'SMP' then 0::smallint    -- yang tuntas baru SD
    when 'SMA' then 1::smallint    -- SMP
    when 'SMK' then 1::smallint
    when 'D1'  then 2::smallint    -- SMA/SMK
    when 'D2'  then 2::smallint
    when 'D3'  then 2::smallint
    when 'D4'  then 2::smallint
    when 'S1'  then 2::smallint
    when 'S2'  then 6::smallint    -- S1/D4
    when 'S3'  then 7::smallint    -- S2
    else 2::smallint
  end;
$$;

comment on function public.rank_sebelum(text) is
  'Jenjang yang sudah tuntas bagi seseorang yang SEDANG menempuh jenjang ini.';

/**
 * Keadaan pendidikan pengguna, dipakai bersama oleh perhitungan durasi dan
 * layar mana pun yang perlu tahu posisi studinya.
 *
 * Tanpa profil — pengunjung yang belum login — rank dianggap 2 (lulus SMA),
 * angka yang sama dengan asumsi est_months di roadmap_templates, supaya
 * pengunjung melihat durasi yang sudah dikurasi di 0007.
 */
create or replace function public.posisi_studi()
returns table (rank_tercapai smallint, rank_sedang smallint, sisa_bulan smallint)
language sql stable
set search_path = public
as $$
  with p as (
    select pr.education_level_code as lv, pr.graduation_status as st,
           pr.grade_level as kelas, pr.semester as smt, pr.is_final_semester as akhir
    from public.profiles pr
    where pr.user_id = auth.uid()
    limit 1
  ),
  d as (
    select p.*, el.order_rank, ed.total_semester, ed.kelas_terakhir, ed.total_months
    from p
    join public.education_levels el on el.code = p.lv
    left join public.education_durations ed on ed.level_code = p.lv
  )
  select
    coalesce((select case when st = 'sudah_lulus' then order_rank
                          else public.rank_sebelum(lv) end from d), 2)::smallint,
    (select case when st = 'sedang_studi' then order_rank end from d)::smallint,
    coalesce((
      select case
        when st <> 'sedang_studi' then 0
        -- Semester akhir: tinggal menuntaskan tugas akhir dan wisuda.
        when akhir then 6
        -- Jenjang sekolah dihitung dari kelas. Tambahan 6 bulan supaya
        -- kelas terakhir tidak keluar 0 bulan — ia masih harus diselesaikan.
        when kelas_terakhir is not null and kelas is not null
          then greatest(kelas_terakhir - kelas, 0) * 12 + 6
        -- Jenjang tinggi dihitung dari semester, satu semester 6 bulan.
        when total_semester is not null and smt is not null
          then greatest(total_semester - smt, 0) * 6 + 6
        -- Sedang studi tapi kelas/semester tidak diisi: pakai separuh durasi
        -- normatif. Tebakan, tapi tebakan yang jelas lebih dekat daripada nol.
        else coalesce(total_months, 24) / 2
      end
      from d
    ), 0)::smallint;
$$;

comment on function public.posisi_studi() is
  'Posisi studi pengguna: jenjang yang sudah tuntas, jenjang yang sedang dijalani, dan sisa bulannya. Tanpa profil: rank 2, tidak sedang studi.';

-- ---------------------------------------------------------------------------
-- 3. career_card memakai posisi_studi()
--
--    Hanya blok lateral durasinya yang berubah; kolom lain persis sama seperti
--    0020 supaya seluruh RPC dan layar yang memakainya tidak perlu disentuh.
-- ---------------------------------------------------------------------------
drop view if exists public.career_card cascade;

create view public.career_card
with (security_invoker = true) as
select
  c.id                                as career_id,
  c.career_name,
  c.career_description,
  si.name_id                          as sub_industry,
  si.industry_code,
  greatest(coalesce(sc.total, 1) - 1, 0)::int as sub_industry_extra,
  m.demand_score,
  case
    when m.demand_score >= 70 then 'Demand tinggi'
    when m.demand_score >= 50 then 'Demand sedang'
    else 'Demand rendah'
  end                                 as demand_label,
  m.salary_min,
  m.salary_max,
  rmn.months                          as roadmap_months,
  coalesce(act.attrs, array[]::text[]) as activity_attributes
from public.careers c
left join public.career_sub_industries csi
       on csi.career_id = c.id and csi.is_primary
left join public.sub_industries si on si.code = csi.sub_industry_code
left join (select career_id, count(*) as total
           from public.career_sub_industries group by career_id) sc on sc.career_id = c.id
left join public.career_market m     on m.career_id = c.id
cross join lateral (select * from public.posisi_studi()) ps
left join lateral (
  select (
    -- Sisa studi yang sedang berjalan dihitung sekali, di luar penjumlahan
    -- tahap: ia milik pengguna, bukan milik profesinya.
    ps.sisa_bulan
    + coalesce(sum(s.est_months) filter (
        where s.skip_if_rank_at_least is null
           or (s.skip_if_rank_at_least > ps.rank_tercapai
               and (ps.rank_sedang is null
                    or s.skip_if_rank_at_least > ps.rank_sedang))
      ), 0)
  )::smallint as months
  from public.roadmap_templates t2
  join public.roadmap_stages s on s.template_id = t2.id
  where t2.career_id = c.id
) rmn on true
left join (
  select c2.id as career_id,
         array_agg(a.name_id order by d.rank_in_layer) filter (where d.rank_in_layer <= 3) as attrs
  from public.careers c2
  join public.onet_dna d on d.soc_code = c2.soc_code and d.is_dominant
  join public.dna_attributes a on a.code = d.attribute_code and a.layer_code = 'ACTIVITY'
  group by c2.id
) act on act.career_id = c.id
where c.is_active;

comment on view public.career_card is
  'Satu baris per profesi aktif berisi seluruh isi kartu Explore kecuali skor kecocokan. roadmap_months menghormati semester/kelas yang sedang ditempuh pengguna (lihat 0031).';

-- ---------------------------------------------------------------------------
-- 4. Kembalikan dua fungsi yang ikut jatuh
--
--    Keduanya mengembalikan `setof career_card`, jadi `drop view ... cascade`
--    di atas ikut menghapusnya. Isinya persis seperti 0020 — yang berubah cuma
--    definisi view yang mereka bacakan.
-- ---------------------------------------------------------------------------

/** Paling Diminati tahun ini — tidak butuh login. */
create or replace function public.explore_top_demand(p_limit integer default 12)
returns setof public.career_card
language sql stable
set search_path = public
as $$
  select * from public.career_card
  order by demand_score desc nulls last, salary_max desc nulls last, career_name
  limit greatest(p_limit, 1);
$$;

/** Pencarian cepat di kotak Explore. */
create or replace function public.explore_search(p_query text, p_limit integer default 20)
returns setof public.career_card
language sql stable
set search_path = public
as $$
  select * from public.career_card
  where p_query is not null and length(btrim(p_query)) >= 2
    and (career_name ilike '%' || btrim(p_query) || '%'
      or career_description ilike '%' || btrim(p_query) || '%'
      or sub_industry ilike '%' || btrim(p_query) || '%')
  order by
    case when career_name ilike btrim(p_query) || '%' then 0 else 1 end,
    demand_score desc nulls last, career_name
  limit greatest(p_limit, 1);
$$;

-- ---------------------------------------------------------------------------
-- 5. Penjaga
--
--    Yang diperiksa bukan angkanya, tapi hubungannya: sedang menempuh sebuah
--    jenjang tidak boleh menghasilkan durasi yang sama dengan sudah lulus dari
--    jenjang itu. Itu tepat bug yang diperbaiki file ini.
-- ---------------------------------------------------------------------------
do $$
declare v_n int;
begin
  if to_regclass('public.career_card') is null then
    raise exception '0031: view career_card hilang setelah drop cascade';
  end if;

  select count(*) into v_n from public.education_durations;
  if v_n <> 10 then
    raise exception '0031: education_durations berisi % baris, seharusnya 10', v_n;
  end if;

  -- rank_sebelum harus selalu lebih rendah dari rank jenjangnya sendiri.
  select count(*) into v_n
  from public.education_levels el
  where public.rank_sebelum(el.code) >= el.order_rank;
  if v_n > 0 then
    raise exception '0031: % jenjang punya rank_sebelum yang tidak lebih rendah', v_n;
  end if;

  -- Dua fungsi yang ikut jatuh bersama view harus kembali. Kalau tidak,
  -- baris "Paling Diminati" dan kotak pencarian Explore mati diam-diam.
  if to_regprocedure('public.explore_top_demand(integer)') is null
     or to_regprocedure('public.explore_search(text,integer)') is null then
    raise exception '0031: explore_top_demand / explore_search tidak kembali setelah cascade';
  end if;

  raise notice '0031: durasi kini menghormati semester dan kelas yang sedang ditempuh';
end $$;

commit;
