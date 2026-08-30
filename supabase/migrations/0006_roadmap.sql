-- ============================================================================
-- 0006_roadmap.sql
--
-- Struktur roadmap: Stage -> Milestone -> Activity, plus state pengguna
-- (tujuan karier, roadmap yang sedang dijalani, centang aktivitas, XP).
--
-- Prinsipnya tetap "Database First, AI Second": isi roadmap diturunkan dari
-- knowledge base yang sudah ada (O*NET + data pendidikan Indonesia), bukan
-- dikarang LLM saat runtime. Migrasi ini hanya membuat wadahnya; isinya
-- di-generate oleh 0007.
--
-- Bentuk datanya:
--
--   roadmap_templates   satu per (karier, jenjang awal pengguna)
--     roadmap_stages      fase waktu: sekolah -> kuliah -> fondasi -> ...
--       roadmap_milestones  capaian di dalam fase
--         roadmap_activities  langkah konkret yang bisa dicentang
--
-- Template dipakai bersama, tidak disalin per pengguna. Progres pengguna
-- disimpan sebagai centang di `user_roadmap_activities` yang menunjuk ke
-- `roadmap_activities`. Konsekuensinya: memperbaiki teks template langsung
-- terlihat oleh semua pengguna, dan tidak ada ribuan baris duplikat.
--
-- Jalankan setelah 0005. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Kosakata capaian (IWA O*NET)
--
--    O*NET menyusun pekerjaan sebagai GWA (41) -> IWA (332) -> DWA (2.087).
--    Lapisan IWA-lah yang seukuran "capaian": cukup spesifik untuk berarti
--    ("Merancang sistem atau aplikasi komputer"), cukup umum untuk dipakai
--    ulang lintas profesi. 464 profesi kita memakai 311 IWA — jadi menerjemahkan
--    311 kalimat sekali memberi milestone berbahasa Indonesia untuk semuanya,
--    alih-alih menerjemahkan 18.796 task statement.
-- ---------------------------------------------------------------------------
create table if not exists public.roadmap_skill_areas (
  code        text primary key,                 -- IWA Element ID, mis. '4.A.3.b.1.a'
  gwa_code    text        not null,             -- GWA induk, untuk pengelompokan
  name_id     text        not null,             -- yang dilihat pengguna
  name_en     text        not null,             -- teks O*NET asli, jejak sumber
  is_verified boolean     not null default false,
  created_at  timestamptz not null default now()
);

comment on table public.roadmap_skill_areas is
  'Kosakata capaian, dipetakan 1:1 ke Intermediate Work Activity O*NET. name_en disimpan supaya terjemahan bisa diaudit.';
comment on column public.roadmap_skill_areas.is_verified is
  'true kalau terjemahan Indonesianya sudah diperiksa manusia.';

-- ---------------------------------------------------------------------------
-- 2. Template
--
--    Satu template per profesi, bukan satu per (profesi, jenjang awal).
--
--    Godaannya adalah membuat template terpisah untuk anak SMP, anak SMA, dan
--    fresh graduate yang menuju profesi yang sama. Tapi fase yang membedakan
--    mereka hanya fase pendidikan di awal; fase fondasi, pengalaman, dan
--    profesional identik. Menyalinnya per jenjang berarti 8x baris yang sama
--    dan 8 tempat yang harus disunting setiap kali satu kalimat diperbaiki.
--
--    Sebagai gantinya, tiap stage membawa `skip_if_rank_at_least`: fase yang
--    sudah dilewati pengguna disaring saat dibaca (lihat user_roadmap_stages).
-- ---------------------------------------------------------------------------
create table if not exists public.roadmap_templates (
  id           bigint generated always as identity primary key,
  career_id    integer     not null references public.careers(id) on delete cascade,
  target_rank  smallint    not null,   -- jenjang yang dibutuhkan profesi ini
  job_zone     smallint,
  est_months   integer,                -- estimasi total, dari Training & Experience O*NET
  source       text        not null default 'onet',
  is_curated   boolean     not null default false,
  curation_note text,
  created_at   timestamptz not null default now(),
  constraint uq_roadmap_template unique (career_id),
  constraint chk_template_ranks check (target_rank between 1 and 8),
  constraint chk_template_job_zone check (job_zone is null or job_zone between 1 and 5)
);

comment on column public.roadmap_templates.is_curated is
  'false = hasil generate murni dari data. true = sudah disunting/diverifikasi manusia.';
comment on column public.roadmap_templates.est_months is
  'Estimasi kasar, dijumlahkan dari est_months tiap stage. Bukan janji, dipakai untuk menampilkan skala waktu.';

-- ---------------------------------------------------------------------------
-- 3. Stage — fase waktu
-- ---------------------------------------------------------------------------
create table if not exists public.roadmap_stages (
  id             bigint   generated always as identity primary key,
  template_id    bigint   not null references public.roadmap_templates(id) on delete cascade,
  stage_order    smallint not null,
  kind           text     not null,
  name_id        text     not null,
  description_id text,
  est_months     integer,
  -- Fase ini tidak relevan lagi kalau jenjang pengguna sudah mencapai angka
  -- ini. NULL = selalu relevan. Contoh: fase SEKOLAH punya nilai 2, jadi
  -- hilang begitu pengguna lulus SMA/SMK.
  skip_if_rank_at_least smallint,
  constraint uq_roadmap_stage_order unique (template_id, stage_order),
  constraint chk_stage_skip_rank check (skip_if_rank_at_least is null or skip_if_rank_at_least between 1 and 8),
  constraint chk_stage_kind check (kind in (
    'SEKOLAH',      -- selesaikan jenjang sekolah yang sedang dijalani
    'KULIAH',       -- tempuh pendidikan tinggi yang dibutuhkan
    'FONDASI',      -- kuasai kemampuan inti profesi
    'PENGALAMAN',   -- magang, proyek nyata, portofolio
    'PROFESIONAL',  -- masuk dan bertahan di peran entry-level
    'LANJUT'        -- pengembangan karier setelah mapan
  ))
);

-- ---------------------------------------------------------------------------
-- 4. Milestone — capaian di dalam sebuah fase
-- ---------------------------------------------------------------------------
create table if not exists public.roadmap_milestones (
  id              bigint   generated always as identity primary key,
  stage_id        bigint   not null references public.roadmap_stages(id) on delete cascade,
  milestone_order smallint not null,
  name_id         text     not null,
  description_id  text,
  skill_area_code text     references public.roadmap_skill_areas(code),
  weight          numeric(6,2),   -- bobot kepentingan dari O*NET, untuk urutan
  constraint uq_roadmap_milestone_order unique (stage_id, milestone_order)
);

comment on column public.roadmap_milestones.skill_area_code is
  'Terisi kalau milestone ini berasal dari IWA O*NET. NULL untuk milestone struktural (pilih jurusan, lulus, dsb).';

-- ---------------------------------------------------------------------------
-- 5. Activity — langkah konkret yang dicentang pengguna
-- ---------------------------------------------------------------------------
create table if not exists public.roadmap_activities (
  id             bigint   generated always as identity primary key,
  milestone_id   bigint   not null references public.roadmap_milestones(id) on delete cascade,
  activity_order smallint not null,
  kind           text     not null,
  name_id        text     not null,
  description_id text,
  xp             integer  not null default 10,
  est_hours      integer,
  constraint uq_roadmap_activity_order unique (milestone_id, activity_order),
  constraint chk_activity_xp check (xp between 0 and 1000),
  constraint chk_activity_kind check (kind in (
    'RISET',    -- cari tahu, baca, tanya orang
    'BELAJAR',  -- kursus, materi, latihan terarah
    'PRAKTIK',  -- kerjakan sesuatu yang nyata
    'BUKTI',    -- portofolio, sertifikat, dokumentasi
    'ADMIN'     -- daftar, urus berkas, ambil ujian
  ))
);

create index if not exists idx_roadmap_stages_template   on public.roadmap_stages (template_id, stage_order);
create index if not exists idx_roadmap_milestones_stage  on public.roadmap_milestones (stage_id, milestone_order);
create index if not exists idx_roadmap_activities_ms     on public.roadmap_activities (milestone_id, activity_order);

-- ---------------------------------------------------------------------------
-- 6. State pengguna
-- ---------------------------------------------------------------------------

-- Profesi yang diincar. Boleh lebih dari satu, tepat satu boleh jadi utama.
create table if not exists public.user_career_goals (
  id         bigint      generated always as identity primary key,
  user_id    uuid        not null references auth.users(id) on delete cascade,
  career_id  integer     not null references public.careers(id) on delete cascade,
  is_primary boolean     not null default false,
  created_at timestamptz not null default now(),
  constraint uq_user_career_goal unique (user_id, career_id)
);

-- Tepat satu tujuan utama per pengguna. Partial unique index, bukan CHECK,
-- karena aturannya lintas-baris.
create unique index if not exists uq_user_primary_goal
  on public.user_career_goals (user_id) where is_primary;

-- Roadmap yang sedang dijalani. template_id boleh NULL sesaat kalau template
-- untuk kombinasi (karier, jenjang) itu belum di-generate — lebih baik menyimpan
-- niat pengguna daripada menolaknya.
create table if not exists public.user_roadmaps (
  id           bigint      generated always as identity primary key,
  user_id      uuid        not null references auth.users(id) on delete cascade,
  career_id    integer     not null references public.careers(id) on delete cascade,
  template_id  bigint      references public.roadmap_templates(id) on delete set null,
  start_rank   smallint    not null,
  status       text        not null default 'AKTIF',
  started_at   timestamptz not null default now(),
  completed_at timestamptz,
  constraint chk_user_roadmap_status check (status in ('AKTIF','JEDA','SELESAI','DITINGGALKAN')),
  constraint chk_user_roadmap_completed check (
    (status = 'SELESAI') = (completed_at is not null)
  )
);

-- Satu roadmap aktif per (pengguna, karier). Yang sudah selesai atau
-- ditinggalkan tetap tersimpan sebagai riwayat.
create unique index if not exists uq_user_roadmap_active
  on public.user_roadmaps (user_id, career_id) where status in ('AKTIF','JEDA');

-- Dibutuhkan sebagai sasaran foreign key gabungan di bawah.
create unique index if not exists uq_user_roadmaps_id_user
  on public.user_roadmaps (id, user_id);

create table if not exists public.user_roadmap_activities (
  id              bigint      generated always as identity primary key,
  user_id         uuid        not null references auth.users(id) on delete cascade,
  user_roadmap_id bigint      not null,
  activity_id     bigint      not null references public.roadmap_activities(id) on delete cascade,
  status          text        not null default 'SELESAI',
  note            text,
  completed_at    timestamptz not null default now(),
  constraint uq_user_roadmap_activity unique (user_roadmap_id, activity_id),
  constraint chk_ura_status check (status in ('SELESAI','DILEWATI')),
  -- Foreign key gabungan, bukan hanya ke user_roadmaps(id).
  --
  -- Policy RLS pemilik baris cuma memeriksa user_id. Dengan FK tunggal,
  -- pengguna A bisa menyisipkan baris ber-user_id miliknya sendiri tapi
  -- menunjuk user_roadmap_id milik pengguna B — lolos policy, lalu ikut
  -- terhitung di progres B (view menggabungkan lewat user_roadmap_id) dan
  -- memberi A XP untuk aktivitas yang bukan bagian roadmap-nya. Menyertakan
  -- user_id di dalam FK membuat kombinasi itu mustahil di level basis data,
  -- bukan bergantung pada policy yang benar.
  constraint fk_ura_roadmap_owner
    foreign key (user_roadmap_id, user_id)
    references public.user_roadmaps (id, user_id) on delete cascade
);

create index if not exists idx_ura_user on public.user_roadmap_activities (user_id, user_roadmap_id);

-- Buku besar XP. Aktivitas roadmap menulis ke sini lewat trigger; quest dan
-- achievement nanti menulis ke tabel yang sama dengan source_kind berbeda,
-- sehingga total XP selalu satu penjumlahan sederhana.
create table if not exists public.xp_ledger (
  id          bigint      generated always as identity primary key,
  user_id     uuid        not null references auth.users(id) on delete cascade,
  source_kind text        not null,
  source_id   bigint,
  xp          integer     not null,
  reason      text,
  created_at  timestamptz not null default now(),
  constraint chk_xp_source_kind check (source_kind in ('AKTIVITAS','QUEST','ACHIEVEMENT','MANUAL'))
);

create index if not exists idx_xp_ledger_user on public.xp_ledger (user_id, created_at desc);

-- Idempotensi: satu aktivitas roadmap hanya boleh menghasilkan XP sekali,
-- walau dicentang, dibatalkan, lalu dicentang lagi.
create unique index if not exists uq_xp_activity_once
  on public.xp_ledger (user_id, source_id) where source_kind = 'AKTIVITAS';

-- ---------------------------------------------------------------------------
-- 7. XP otomatis saat aktivitas dicentang
--
--    Ditaruh di trigger, bukan di kode aplikasi, supaya XP tidak bisa dikarang
--    dari client: `xp_ledger` tidak menerima INSERT dari pengguna (lihat policy
--    di bawah), dan satu-satunya jalan menambah XP adalah menyelesaikan
--    aktivitas yang benar-benar ada di template.
-- ---------------------------------------------------------------------------
create or replace function public.grant_activity_xp()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_xp integer;
begin
  -- Aktivitas harus benar-benar milik template roadmap ini.
  --
  -- Tanpa pemeriksaan ini, pengguna bisa mencentang aktivitas dari roadmap
  -- profesi mana pun — 18.596 aktivitas tersedia — dan mengumpulkan XP tanpa
  -- menyentuh roadmap-nya sendiri. Relasinya lewat tiga tabel, jadi tidak bisa
  -- dinyatakan sebagai foreign key; trigger adalah tempat terdekat berikutnya.
  if not exists (
    select 1
    from public.user_roadmaps ur
    join public.roadmap_stages     s on s.template_id  = ur.template_id
    join public.roadmap_milestones m on m.stage_id     = s.id
    join public.roadmap_activities a on a.milestone_id = m.id
    where ur.id = new.user_roadmap_id
      and a.id  = new.activity_id
  ) then
    raise exception 'aktivitas % bukan bagian dari roadmap %', new.activity_id, new.user_roadmap_id
      using errcode = 'check_violation';
  end if;

  if new.status <> 'SELESAI' then
    return new;
  end if;

  select xp into v_xp from public.roadmap_activities where id = new.activity_id;
  if v_xp is null or v_xp = 0 then
    return new;
  end if;

  insert into public.xp_ledger (user_id, source_kind, source_id, xp, reason)
  values (new.user_id, 'AKTIVITAS', new.activity_id, v_xp, 'Menyelesaikan aktivitas roadmap')
  on conflict do nothing;

  return new;
end $$;

-- BEFORE, bukan AFTER: pemeriksaan kepemilikan aktivitas di atas harus
-- menggagalkan INSERT-nya, bukan berjalan setelah barisnya terlanjur masuk.
drop trigger if exists trg_grant_activity_xp on public.user_roadmap_activities;
create trigger trg_grant_activity_xp
  before insert or update of status on public.user_roadmap_activities
  for each row execute function public.grant_activity_xp();

-- ---------------------------------------------------------------------------
-- 8. Pembacaan
-- ---------------------------------------------------------------------------

-- Roadmap datar: satu baris per aktivitas, lengkap dengan induknya.
-- security_invoker supaya RLS pemanggil tetap berlaku.
create or replace view public.roadmap_full
with (security_invoker = true) as
select
  t.id                as template_id,
  t.career_id,
  t.target_rank,
  t.job_zone,
  s.id                as stage_id,
  s.stage_order,
  s.kind              as stage_kind,
  s.name_id           as stage_name,
  s.description_id    as stage_description,
  s.est_months        as stage_est_months,
  s.skip_if_rank_at_least,
  m.id                as milestone_id,
  m.milestone_order,
  m.name_id           as milestone_name,
  m.description_id    as milestone_description,
  m.skill_area_code,
  a.id                as activity_id,
  a.activity_order,
  a.kind              as activity_kind,
  a.name_id           as activity_name,
  a.description_id    as activity_description,
  a.xp,
  a.est_hours
from public.roadmap_templates t
join public.roadmap_stages     s on s.template_id = t.id
join public.roadmap_milestones m on m.stage_id    = s.id
join public.roadmap_activities a on a.milestone_id = m.id;

-- Roadmap seorang pengguna: sama seperti roadmap_full, tapi fase yang sudah
-- dilewati jenjang pendidikannya sudah disaring, dan tiap aktivitas membawa
-- status centangnya.
create or replace view public.user_roadmap_stages
with (security_invoker = true) as
select
  r.id            as user_roadmap_id,
  r.user_id,
  f.*,   -- sudah membawa career_id, jadi tidak diulang dari r
  ua.status       as activity_status,
  ua.completed_at
from public.user_roadmaps r
join public.roadmap_full f on f.template_id = r.template_id
left join public.user_roadmap_activities ua
       on ua.activity_id = f.activity_id and ua.user_roadmap_id = r.id
where f.skip_if_rank_at_least is null
   or r.start_rank < f.skip_if_rank_at_least;

-- Ringkasan progres. Penyebutnya hanya aktivitas yang benar-benar berlaku
-- untuk pengguna ini — kalau fase sekolah ikut dihitung, seorang fresh
-- graduate akan mulai dari 0% padahal fase itu memang bukan urusannya lagi.
create or replace view public.user_roadmap_progress
with (security_invoker = true) as
select
  r.id                                                       as user_roadmap_id,
  r.user_id,
  r.career_id,
  r.status,
  count(a.id)                                                as total_activities,
  count(ua.id) filter (where ua.status = 'SELESAI')           as done_activities,
  case when count(a.id) = 0 then 0
       else round(100.0 * count(ua.id) filter (where ua.status = 'SELESAI') / count(a.id), 1)
  end                                                        as percent_done,
  coalesce(sum(a.xp) filter (where ua.status = 'SELESAI'), 0) as xp_earned
from public.user_roadmaps r
left join public.roadmap_stages s
       on s.template_id = r.template_id
      and (s.skip_if_rank_at_least is null or r.start_rank < s.skip_if_rank_at_least)
left join public.roadmap_milestones m  on m.stage_id     = s.id
left join public.roadmap_activities a  on a.milestone_id = m.id
left join public.user_roadmap_activities ua
       on ua.activity_id = a.id and ua.user_roadmap_id = r.id
group by r.id, r.user_id, r.career_id, r.status;

-- ---------------------------------------------------------------------------
-- 9. Memulai roadmap
--
--    Mencatat jenjang pengguna saat ini ke `user_roadmaps.start_rank`; itulah
--    yang menentukan fase mana yang ditampilkan. Nilainya sengaja dibekukan,
--    tidak dibaca ulang dari profil setiap kali: kalau pengguna naik jenjang di
--    tengah jalan, fase yang sudah dia kerjakan tidak boleh mendadak hilang
--    dari roadmap-nya. Dipanggil dari frontend lewat RPC.
-- ---------------------------------------------------------------------------
create or replace function public.start_roadmap(p_career_id integer)
returns bigint
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user  uuid := auth.uid();
  v_rank  smallint;
  v_tpl   bigint;
  v_id    bigint;
begin
  if v_user is null then
    raise exception 'start_roadmap: tidak ada pengguna terautentikasi';
  end if;

  select el.order_rank into v_rank
  from public.profiles p
  join public.education_levels el on el.code = p.education_level_code
  where p.user_id = v_user;

  if v_rank is null then
    raise exception 'start_roadmap: profil pengguna belum punya jenjang pendidikan';
  end if;

  -- Boleh NULL: kalau template profesi ini belum di-generate, niat pengguna
  -- tetap disimpan dan roadmap-nya terisi begitu templatenya ada.
  select id into v_tpl
  from public.roadmap_templates
  where career_id = p_career_id;

  insert into public.user_roadmaps (user_id, career_id, template_id, start_rank)
  values (v_user, p_career_id, v_tpl, v_rank)
  on conflict do nothing
  returning id into v_id;

  if v_id is null then
    select id into v_id
    from public.user_roadmaps
    where user_id = v_user and career_id = p_career_id and status in ('AKTIF','JEDA');
  end if;

  return v_id;
end $$;

comment on function public.start_roadmap(integer) is
  'Membuat (atau mengembalikan) roadmap aktif pengguna untuk sebuah profesi, memakai template yang cocok dengan jenjang pendidikannya.';

-- ---------------------------------------------------------------------------
-- 10. RLS
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  -- Knowledge base: siapa pun boleh baca, tidak ada yang boleh tulis dari client.
  foreach t in array array[
    'roadmap_skill_areas',
    'roadmap_templates',
    'roadmap_stages',
    'roadmap_milestones',
    'roadmap_activities'
  ]
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_read_all', t);
    execute format(
      'create policy %I on public.%I for select to anon, authenticated using (true)',
      t || '_read_all', t
    );
  end loop;

  -- Data pengguna: hanya pemilik barisnya.
  foreach t in array array[
    'user_career_goals',
    'user_roadmaps',
    'user_roadmap_activities'
  ]
  loop
    perform public.apply_owner_rls(t);
  end loop;
end $$;

-- xp_ledger sengaja tidak lewat apply_owner_rls: pengguna boleh melihat XP-nya
-- sendiri tapi tidak boleh menulis. Satu-satunya penulis adalah trigger
-- grant_activity_xp yang berjalan security definer.
alter table public.xp_ledger enable row level security;
drop policy if exists xp_ledger_owner_select on public.xp_ledger;
create policy xp_ledger_owner_select on public.xp_ledger
  for select to authenticated using (auth.uid() = user_id);

commit;

-- ============================================================================
-- Verifikasi:
--
--   select relname, relrowsecurity from pg_class
--   where relnamespace = 'public'::regnamespace and relkind = 'r'
--     and relname like 'roadmap%' or relname like 'user_%' or relname = 'xp_ledger'
--   order by relname;
--
-- Semua harus relrowsecurity = true. Isi templatenya di-generate oleh 0007.
-- ============================================================================
