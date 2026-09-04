-- ============================================================================
-- 0017_roadmap_quests.sql
--
-- Mengganti isi roadmap: dari 18.596 baris aktivitas datar jadi quest yang
-- dirender dari template 0016.
--
-- Apa yang berubah bagi pengguna:
--
--   sebelum  milestone "Mengolah data digital atau daring" berisi tiga baris
--            "Pelajari dasar ...", "Latih langsung: ...", "Simpan bukti ..."
--            dan tahap PENGALAMAN berisi lima baris "Pelajari <nama software>"
--
--   sesudah  milestone yang sama berisi satu quest 🟢 "Kenali cara mengolah
--            data digital atau daring" dengan enam langkah konkret, dan lima
--            baris software itu diganti quest hard skill bertingkat
--            PEMULA -> MENENGAH -> MAHIR
--
-- Milestone hard skill baru ditambahkan di tiga tahap sekaligus supaya satu
-- kemampuan dipelajari bertahap, bukan sekali sebut lalu hilang.
--
-- CATATAN PENTING: file ini MENGHAPUS seluruh isi roadmap_activities lalu
-- menulisnya ulang. Progres pengguna yang menunjuk ke aktivitas lama ikut
-- terhapus lewat ON DELETE CASCADE. Aman dijalankan sekarang karena tabel
-- profiles masih kosong; kalau sudah ada pengguna sungguhan, jalankan hanya
-- setelah memutuskan bagaimana progres lama dipetakan ke quest baru.
--
-- Jalankan setelah 0016. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Kolom quest pada aktivitas
-- ---------------------------------------------------------------------------
alter table public.roadmap_activities add column if not exists quest_template_code text;
alter table public.roadmap_activities add column if not exists context     jsonb;
alter table public.roadmap_activities add column if not exists tier_code   text;
alter table public.roadmap_activities add column if not exists rotate_seed smallint;

do $$ begin
  if not exists (select 1 from pg_constraint where conname='fk_activity_quest_template') then
    alter table public.roadmap_activities
      add constraint fk_activity_quest_template
      foreign key (quest_template_code) references public.quest_templates(code);
  end if;
  if not exists (select 1 from pg_constraint where conname='fk_activity_tier') then
    alter table public.roadmap_activities
      add constraint fk_activity_tier
      foreign key (tier_code) references public.quest_tiers(code);
  end if;
end $$;

-- kind aktivitas dulu berisi jenis langkah (RISET/BELAJAR/...). Sekarang jenis
-- langkah pindah ke template, dan kind menampung jenis quest-nya.
alter table public.roadmap_activities drop constraint if exists chk_activity_kind;
alter table public.roadmap_activities add constraint chk_activity_kind
  check (kind in ('RISET','BELAJAR','PRAKTIK','BUKTI','ADMIN',
                  'HARD_SKILL','AKTIVITAS','EDUKASI','PENGALAMAN','KARIER','LANJUT'));

alter table public.roadmap_activities drop constraint if exists chk_activity_xp;
alter table public.roadmap_activities add constraint chk_activity_xp
  check (xp >= 0 and xp <= 2000);

-- ---------------------------------------------------------------------------
-- 2. Milestone hard skill
--
-- Tiga tahap, tiga tingkat kedalaman:
--   FONDASI      3 kemampuan inti, tingkat PEMULA    (kenali)
--   PENGALAMAN   3 kemampuan inti tingkat MENENGAH   (terapkan)
--                + 2 kemampuan pendukung tingkat PEMULA
--   PROFESIONAL  1 kemampuan inti tingkat MAHIR      (kuasai)
--
-- Tingkatnya ditentukan peringkat kemampuan, bukan urutan milestone. Kalau
-- ditentukan urutan, satu kemampuan bisa muncul dua kali di tingkat PEMULA —
-- dan itu justru pengulangan yang mau dihilangkan.
--
-- Milestone "Kuasai alat kerja yang dipakai di lapangan" yang lama dihapus:
-- isinya persis daftar software mentah yang dikeluhkan.
-- ---------------------------------------------------------------------------
delete from public.roadmap_milestones where slug = 'ALAT_KERJA';
delete from public.roadmap_milestones where slug ~ '^HS[1-4]:';
delete from public.roadmap_milestones where slug like 'HS:%';   -- penamaan versi sebelumnya

create temp table _hs_plan (
  stage_id  bigint,
  slug      text,
  name_id   text,
  hs_code   text,
  urut      smallint
) on commit drop;

insert into _hs_plan (stage_id, slug, name_id, hs_code, urut)
select p.stage_id, p.prefix || p.hard_skill_code, 'Kuasai ' || p.nama, p.hard_skill_code,
       (row_number() over (partition by p.stage_id order by p.rn))::smallint
from (
  select s.id as stage_id, s.kind,
         chs.hard_skill_code, h.name_id as nama,
         row_number() over (partition by s.id order by chs.display_order, chs.hard_skill_code) as rn,
         case
           when s.kind = 'FONDASI'                            then 'HS1:'
           when s.kind = 'PENGALAMAN'
                and row_number() over (partition by s.id
                      order by chs.display_order, chs.hard_skill_code) <= 3 then 'HS2:'
           when s.kind = 'PENGALAMAN'                         then 'HS4:'
           else 'HS3:'
         end as prefix
  from public.roadmap_stages s
  join public.roadmap_templates t on t.id = s.template_id
  join public.career_hard_skills chs on chs.career_id = t.career_id
  join public.hard_skills h on h.code = chs.hard_skill_code
  where s.kind in ('FONDASI','PENGALAMAN','PROFESIONAL')
) p
where (p.kind = 'FONDASI'     and p.rn <= 3)
   or (p.kind = 'PENGALAMAN'  and p.rn <= 5)
   or (p.kind = 'PROFESIONAL' and p.rn  = 1);

insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id, skill_area_code, weight, slug)
select p.stage_id,
       (coalesce(m.maks, 0) + p.urut)::smallint,
       p.name_id,
       null,
       null,
       1,
       p.slug
from _hs_plan p
left join (select stage_id, max(milestone_order) as maks
           from public.roadmap_milestones group by stage_id) m on m.stage_id = p.stage_id
on conflict (stage_id, slug) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Satu quest per milestone
-- ---------------------------------------------------------------------------
delete from public.roadmap_activities;

with dasar as (
  select m.id as milestone_id, m.slug, m.milestone_order, m.name_id as ms_name,
         s.kind as stage_kind, s.name_id as stage_name,
         c.career_name,
         sa.name_id as iwa_name,
         h.name_id as hs_name
  from public.roadmap_milestones m
  join public.roadmap_stages s     on s.id = m.stage_id
  join public.roadmap_templates t  on t.id = s.template_id
  join public.careers c            on c.id = t.career_id
  left join public.roadmap_skill_areas sa on sa.code = m.skill_area_code
  left join public.hard_skills h on h.code = nullif(split_part(m.slug, ':', 2), '')
                                 and m.slug ~ '^HS[1-4]:'
),
pilih as (
  select d.*,
    case
      when d.slug like 'HS1:%' then 'HS_PEMULA'    -- kemampuan inti, kenali
      when d.slug like 'HS2:%' then 'HS_MENENGAH'  -- kemampuan inti, terapkan
      when d.slug like 'HS3:%' then 'HS_MAHIR'     -- kemampuan inti, kuasai
      when d.slug like 'HS4:%' then 'HS_PEMULA'    -- kemampuan pendukung, kenali
      when d.slug = 'KENALI_PROFESI'     then 'ED_KENALI'
      when d.slug = 'PILIH_JURUSAN'      then 'ED_JURUSAN'
      when d.slug = 'PILIH_PRODI'        then 'ED_PRODI'
      when d.slug = 'SELESAI_STUDI'      then 'ED_KULIAH'
      when d.slug = 'PENGALAMAN_PERTAMA' then 'PG_MAGANG'
      when d.slug = 'REKRUTMEN'          then 'KR_REKRUT'
      when d.slug = 'IZIN'               then 'KR_LISENSI'
      when d.slug like 'NEXT:%'          then 'LJ_JALUR'
      when d.iwa_name is not null then
        case d.stage_kind
          when 'FONDASI'     then 'AK_PEMULA'
          when 'PENGALAMAN'  then 'AK_MENENGAH'
          when 'PROFESIONAL' then 'AK_MAHIR'
          else 'AK_PEMULA'
        end
    end as tcode
  from dasar d
),
konteks as (
  select p.*,
    jsonb_strip_nulls(jsonb_build_object(
      'profesi',    p.career_name,
      'hard_skill', p.hs_name,
      -- nama IWA disimpan berhuruf kecil di depan karena selalu dipakai di
      -- tengah kalimat: "Cari tahu apa yang dikerjakan saat menganalisis ..."
      'aktivitas',  case when p.iwa_name is null then null
                    else lower(left(p.iwa_name,1)) || substr(p.iwa_name,2) end,
      'jenjang',    case when p.slug = 'SELESAI_STUDI'
                    then nullif(replace(p.ms_name, 'Selesaikan ', ''), '') end,
      'lisensi',    case when p.slug = 'IZIN'
                    then nullif(replace(p.ms_name, 'Urus ', ''), '') end,
      'profesi_lanjut', case when p.slug like 'NEXT:%'
                    then nullif(replace(p.ms_name, 'Jajaki jalur ke ', ''), '') end
    )) as ctx
  from pilih p
  where p.tcode is not null
),
hitung as (
  select k.*,
    (k.milestone_order % 3 + 1)::smallint as seed,
    qt.kind as quest_kind, qt.tier_code, qt.title_template, qt.summary_template
  from konteks k
  join public.quest_templates qt on qt.code = k.tcode
)
insert into public.roadmap_activities
  (milestone_id, activity_order, kind, name_id, description_id, xp, est_hours,
   slug, quest_template_code, context, tier_code, rotate_seed)
select h.milestone_id, 1, h.quest_kind,
       public.quest_render(h.title_template,   h.ctx),
       public.quest_render(h.summary_template, h.ctx),
       coalesce((select sum(st.xp) from public.quest_template_steps st
                 where st.template_code = h.tcode
                   and (st.rotate_group is null or st.rotate_group = h.seed)), 0),
       greatest(1, round(coalesce((select sum(st.est_minutes) from public.quest_template_steps st
                 where st.template_code = h.tcode
                   and (st.rotate_group is null or st.rotate_group = h.seed)), 0) / 60.0)::int),
       'Q:' || h.tcode,
       h.tcode, h.ctx, h.tier_code, h.seed
from hitung h;

-- ---------------------------------------------------------------------------
-- 4. Langkah quest, dirender saat dibaca
-- ---------------------------------------------------------------------------
create or replace view public.roadmap_quest_langkah
with (security_invoker = true) as
select a.id                                              as activity_id,
       a.milestone_id,
       row_number() over (partition by a.id order by st.step_order) as urutan,
       st.step_type                                      as jenis,
       public.quest_render(st.text_template, a.context)  as langkah,
       st.xp,
       st.est_minutes
from public.roadmap_activities a
join public.quest_template_steps st on st.template_code = a.quest_template_code
where st.rotate_group is null or st.rotate_group = a.rotate_seed;

comment on view public.roadmap_quest_langkah is
  'Langkah-langkah tiap quest, hasil render template + konteks. Tidak disimpan sebagai baris: 111 baris template melayani puluhan ribu langkah yang tampil.';

-- ---------------------------------------------------------------------------
-- 5. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from public.roadmap_milestones m
  where not exists (select 1 from public.roadmap_activities a where a.milestone_id = m.id);
  if n > 0 then raise exception '% milestone tidak punya quest', n; end if;

  select count(*) into n from public.roadmap_activities where quest_template_code is null;
  if n > 0 then raise exception '% quest tidak terhubung ke template', n; end if;

  -- Slot yang tidak terisi akan menyisakan kurung siku di layar pengguna.
  select count(*) into n from public.roadmap_quest_langkah where langkah like '%[%]%';
  if n > 0 then raise exception '% langkah masih memuat slot yang belum terisi', n; end if;

  select count(*) into n from public.roadmap_activities
  where name_id like '%[%]%' or coalesce(description_id,'') like '%[%]%';
  if n > 0 then raise exception '% judul quest masih memuat slot yang belum terisi', n; end if;

  -- Satu hard skill tidak boleh muncul dua kali pada tingkat yang sama dalam
  -- satu roadmap: itu persis pengulangan yang mau dihilangkan.
  select count(*) into n from (
    select t.career_id, a.context->>'hard_skill' as hs, a.tier_code
    from public.roadmap_activities a
    join public.roadmap_milestones m on m.id = a.milestone_id
    join public.roadmap_stages s     on s.id = m.stage_id
    join public.roadmap_templates t  on t.id = s.template_id
    where a.context ? 'hard_skill'
    group by 1,2,3 having count(*) > 1
  ) d;
  if n > 0 then raise exception '% hard skill muncul lebih dari sekali pada tingkat yang sama', n; end if;
end $$;

commit;

-- ============================================================================
-- Verifikasi:
--   select count(*) from roadmap_activities;         -- jumlah quest
--   select count(*) from roadmap_quest_langkah;      -- jumlah langkah tampil
--   select count(*) from quest_template_steps;       -- baris yang benar2 disimpan
--
--   select a.name_id, l.urutan, l.jenis, l.langkah
--   from roadmap_activities a join roadmap_quest_langkah l on l.activity_id=a.id
--   where a.context->>'hard_skill' = 'Desain Antarmuka & Wireframe'
--     and a.context->>'profesi' = 'UI/UX Designer' order by l.urutan;
-- ============================================================================
