-- ============================================================================
-- 0048_profesi_disimpan_dan_rekomendasi_sub_industri.sql
--
-- Dua blok baru di Explore dari desain "In Review":
--
--   1. Profesi Disimpan. Tombol bookmark di layar detail profesi sudah ada
--      sejak 0029, tetapi belum menyimpan apa pun. Sekarang setiap pengguna
--      punya daftar profesi simpanan sendiri, terpisah dari profesi yang ia
--      PILIH untuk dijalani (user_career_goals): menyimpan berarti "ingin
--      dilihat lagi", bukan "ini tujuanku".
--
--   2. Rekomendasi Sub-Industri. Skor kecocokan Career DNA (career_match_scores,
--      0044) dikelompokkan per sub-industri: rata-rata tiga profesi teratas di
--      tiap sub-industri. Alasannya disusun dari minat dan aktivitas yang
--      dipilih pengguna DAN dominan di sebagian besar profesi sub-industri itu,
--      jadi kalimat "Mengapa direkomendasikan?" selalu bisa ditelusuri ke data.
--
--   Ditambah daftar profesi per sub-industri untuk tombol "N Profesi terkait".
--
-- Jalankan setelah 0047. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Profesi disimpan
-- ---------------------------------------------------------------------------
create table if not exists public.user_saved_careers (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  career_id  integer     not null references public.careers(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, career_id)
);

alter table public.user_saved_careers enable row level security;

drop policy if exists "simpanan sendiri: baca" on public.user_saved_careers;
create policy "simpanan sendiri: baca" on public.user_saved_careers
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "simpanan sendiri: tambah" on public.user_saved_careers;
create policy "simpanan sendiri: tambah" on public.user_saved_careers
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "simpanan sendiri: hapus" on public.user_saved_careers;
create policy "simpanan sendiri: hapus" on public.user_saved_careers
  for delete to authenticated using (user_id = auth.uid());

revoke all on public.user_saved_careers from anon;
grant select, insert, delete on public.user_saved_careers to authenticated;

-- Kartu profesi simpanan, terbaru dulu. Bentuknya sama dengan baris Explore
-- lain supaya bisa digambar oleh kartu yang sama.
create or replace function public.explore_disimpan(p_limit integer default 60)
returns setof public.career_card
language sql stable
set search_path = public
as $$
  select cc.*
  from public.user_saved_careers s
  join public.career_card cc on cc.career_id = s.career_id
  where s.user_id = auth.uid()
  order by s.created_at desc
  limit greatest(p_limit, 1);
$$;

-- ---------------------------------------------------------------------------
-- 2. Rekomendasi sub-industri
-- ---------------------------------------------------------------------------
create or replace function public.explore_sub_industri(p_limit integer default 3)
returns table (
  code          text,
  name_id       text,
  industry_code text,
  industry_name text,
  n_profesi     integer,
  skor          numeric,
  minat         text[],
  aktivitas     text[]
)
language sql stable
set search_path = public
as $$
  with skor as (
    select s.career_id, s.match_score
    from public.career_match_scores(auth.uid()) s
    where s.match_score is not null
  ),
  per_sub as (
    select csi.sub_industry_code as code, sk.career_id, sk.match_score,
           row_number() over (partition by csi.sub_industry_code order by sk.match_score desc) as urut
    from skor sk
    join public.career_sub_industries csi on csi.career_id = sk.career_id
    join public.careers c on c.id = sk.career_id and c.is_active
  ),
  agg as (
    select code,
           count(*)::integer as n_profesi,
           round(avg(match_score) filter (where urut <= 3)) as skor
    from per_sub
    group by code
    -- Satu profesi saja belum cukup untuk menyebutnya rekomendasi sub-industri.
    having count(*) >= 2
  ),
  pilihan as (
    select ud.attribute_code, a.name_id, a.layer_code
    from public.user_dna ud
    join public.dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = auth.uid() and a.layer_code in ('INTEREST', 'ACTIVITY')
  ),
  -- Pilihan pengguna yang dominan di sedikitnya separuh profesi sub-industri itu.
  sejalan as (
    select ps.code, p.layer_code, p.name_id,
           count(distinct ps.career_id)::numeric / max(ag.n_profesi) as porsi
    from per_sub ps
    join agg ag on ag.code = ps.code
    join public.careers c on c.id = ps.career_id
    join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
    join pilihan p on p.attribute_code = d.attribute_code
    group by ps.code, p.layer_code, p.name_id
    having count(distinct ps.career_id)::numeric / max(ag.n_profesi) >= 0.5
  )
  select ag.code, si.name_id, i.code, i.name_id, ag.n_profesi, ag.skor,
         coalesce((select array_agg(s.name_id order by s.porsi desc, s.name_id)
                   from sejalan s where s.code = ag.code and s.layer_code = 'INTEREST'), '{}'),
         coalesce((select array_agg(s.name_id order by s.porsi desc, s.name_id)
                   from sejalan s where s.code = ag.code and s.layer_code = 'ACTIVITY'), '{}')
  from agg ag
  join public.sub_industries si on si.code = ag.code
  join public.industries i on i.code = si.industry_code
  order by ag.skor desc nulls last, ag.n_profesi desc, si.name_id
  limit greatest(p_limit, 1);
$$;

-- ---------------------------------------------------------------------------
-- 3. Profesi dalam satu sub-industri (tombol "N Profesi terkait")
--
-- Bentuk kolomnya sama dengan explore_by_match. Pengguna yang belum mengisi
-- Career DNA tetap mendapat daftar, diurutkan menurut permintaan pasar.
-- ---------------------------------------------------------------------------
create or replace function public.explore_by_sub_industri(p_code text, p_limit integer default 60)
returns table (
  career_id           integer,
  career_name         text,
  career_description  text,
  sub_industry        text,
  industry_code       text,
  sub_industry_extra  integer,
  demand_score        smallint,
  demand_label        text,
  salary_min          integer,
  salary_max          integer,
  roadmap_months      smallint,
  activity_attributes text[],
  match_score         numeric,
  band_code           text,
  band_label          text,
  reason              text
)
language sql stable
set search_path = public
as $$
  select cc.career_id, cc.career_name, cc.career_description, cc.sub_industry,
         cc.industry_code, cc.sub_industry_extra, cc.demand_score, cc.demand_label,
         cc.salary_min::integer, cc.salary_max::integer, cc.roadmap_months,
         cc.activity_attributes,
         s.match_score, s.band_code, s.band_label,
         case when s.detail is null then null
              else public.match_reason(s.detail, i.name_id) end
  from public.career_sub_industries csi
  join public.career_card cc on cc.career_id = csi.career_id
  left join public.career_match_scores(auth.uid()) s on s.career_id = cc.career_id
  left join public.industries i on i.code = cc.industry_code
  where csi.sub_industry_code = p_code
  order by s.match_score desc nulls last, cc.demand_score desc nulls last, cc.career_name
  limit greatest(p_limit, 1);
$$;

grant execute on function public.explore_disimpan(integer) to authenticated;
grant execute on function public.explore_sub_industri(integer) to authenticated;
grant execute on function public.explore_by_sub_industri(text, integer) to authenticated;

commit;
