-- ===========================================================================
-- 0039_profil_dan_notifikasi.sql
--
-- Layar Profile: tiga tab (Profile, Pendidikan, Notifikasi).
--
-- ---------------------------------------------------------------------------
-- Nama pengguna akhirnya punya tempat mengisi
-- ---------------------------------------------------------------------------
-- Sejak 0023 nama hanya ditebak: kolom profiles.full_name ada, tapi tidak ada
-- satu layar pun yang menanyakannya, jadi sapaan Explore jatuh ke tebakan dari
-- alamat email atau ke "Sobat". Tab Profile adalah layar pertama yang benar-
-- benar menyimpannya.
--
-- ---------------------------------------------------------------------------
-- Avatar
-- ---------------------------------------------------------------------------
-- Gambarnya disimpan di Supabase Storage (bucket "avatars"), bukan di tabel:
-- satu kolom bytea berarti setiap pembacaan profil ikut menarik gambarnya.
-- Yang disimpan di profiles hanya URL-nya.
--
-- Nama berkas wajib diawali id pengguna (`<uid>/avatar.jpg`) karena policy
-- storage memakai folder pertama sebagai penanda pemilik. Tanpa itu, siapa pun
-- yang punya sesi bisa menimpa avatar orang lain.
--
-- ---------------------------------------------------------------------------
-- Notifikasi
-- ---------------------------------------------------------------------------
-- Tidak ada pengirim notifikasi di aplikasi ini; yang ada adalah kejadian yang
-- sudah tercatat -- badge terbuka, level naik, tahap terbuka, quest menunggu.
-- sinkron_notifikasi() menurunkan baris notifikasi dari kejadian itu dan
-- menandainya dengan `ref` supaya satu kejadian tidak pernah jadi dua baris.
--
-- Cara ini punya satu sifat yang disengaja: pengguna yang sudah memakai
-- aplikasi sebelum migrasi ini tetap menerima notifikasi badge dan levelnya,
-- karena dasarnya data, bukan pemicu yang harus keburu terpasang.
--
-- Jalankan setelah 0038. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Avatar di profil
-- ---------------------------------------------------------------------------
alter table public.profiles add column if not exists avatar_url text;

comment on column public.profiles.avatar_url is
  'URL publik avatar di bucket "avatars". NULL berarti dipakai inisial nama.';

-- Bucket dan policy-nya hanya ada di Supabase. Di Postgres polos (uji lokal
-- migrasi) skema storage tidak ada, jadi bagian ini dilewati -- bukan digagalkan.
do $$
begin
  if not exists (select 1 from information_schema.schemata where schema_name = 'storage') then
    raise notice '0039: skema storage tidak ada, bucket avatars dilewati';
    return;
  end if;

  insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do update set public = true;

  execute 'drop policy if exists "avatar_baca_semua" on storage.objects';
  execute $p$
    create policy "avatar_baca_semua" on storage.objects
      for select to anon, authenticated
      using (bucket_id = 'avatars')
  $p$;

  -- Tulis, ganti, dan hapus hanya di folder bernama id sendiri.
  execute 'drop policy if exists "avatar_pemilik_tulis" on storage.objects';
  execute $p$
    create policy "avatar_pemilik_tulis" on storage.objects
      for insert to authenticated
      with check (bucket_id = 'avatars'
                  and (storage.foldername(name))[1] = auth.uid()::text)
  $p$;

  execute 'drop policy if exists "avatar_pemilik_ubah" on storage.objects';
  execute $p$
    create policy "avatar_pemilik_ubah" on storage.objects
      for update to authenticated
      using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
      with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  $p$;

  execute 'drop policy if exists "avatar_pemilik_hapus" on storage.objects';
  execute $p$
    create policy "avatar_pemilik_hapus" on storage.objects
      for delete to authenticated
      using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  $p$;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Notifikasi
-- ---------------------------------------------------------------------------
create table if not exists public.user_notifications (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  kind       text not null,
  -- Penanda kejadian: kode badge, nomor level, kode tahap, atau nomor pekan.
  ref        text not null,
  title_id   text not null,
  body_id    text not null,
  -- Path internal tujuan tombolnya. NULL berarti kartu tanpa tautan.
  link       text,
  created_at timestamptz not null default now(),
  read_at    timestamptz,
  unique (user_id, kind, ref),
  constraint chk_notif_kind check (kind in ('QUEST_MINGGUAN','BADGE','LEVEL','TAHAP'))
);

create index if not exists idx_notif_user on public.user_notifications (user_id, created_at desc);

alter table public.user_notifications enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
                 and tablename = 'user_notifications' and policyname = 'notif_owner_select') then
    create policy notif_owner_select on public.user_notifications
      for select to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Menurunkan notifikasi dari kejadian yang sudah tercatat
-- ---------------------------------------------------------------------------
create or replace function public.sinkron_notifikasi()
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user  uuid := auth.uid();
  v_cid   integer;
  v_level smallint;
  v_pekan text := to_char(now() at time zone 'Asia/Jakarta', 'IYYY-"W"IW');
begin
  if v_user is null then return; end if;
  v_cid := public.profesi_pilihan();

  -- Badge yang sudah terbuka.
  insert into public.user_notifications (user_id, kind, ref, title_id, body_id, link, created_at)
  select v_user, 'BADGE', a.code, 'Badge Baru Berhasil Dibuka!',
         'Selamat! Kamu berhasil mendapatkan badge ' || a.name_id || '.',
         '/progress/pencapaian', u.unlocked_at
  from public.user_achievements u
  join public.achievements a on a.code = u.code
  where u.user_id = v_user
  on conflict (user_id, kind, ref) do nothing;

  -- Level sekarang. Hanya level terakhir yang diberitahukan: pengguna baru
  -- yang menuntaskan onboarding dan Career DNA langsung melompat ke level 5,
  -- dan empat kartu "Level Naik!" sekaligus lebih terasa seperti banjir
  -- daripada kabar baik.
  select x.level into v_level from public.xp_pengguna() x;
  if v_level is not null and v_level >= 2 then
    insert into public.user_notifications (user_id, kind, ref, title_id, body_id, link)
    values (v_user, 'LEVEL', v_level::text, 'Level Naik!',
            'Setiap quest membawamu lebih dekat ke tujuan kariermu. Lanjutkan perjalanan dan kumpulkan lebih banyak XP.',
            '/progress')
    on conflict (user_id, kind, ref) do nothing;
  end if;

  if v_cid is not null then
    -- Tahap Journey yang sudah terbuka, selain tahap pertama yang memang
    -- terbuka sejak awal dan tidak pantas disebut "baru terbuka".
    insert into public.user_notifications (user_id, kind, ref, title_id, body_id, link)
    select distinct v_user, 'TAHAP', k.stage_code, 'Stage Baru Terbuka!',
           'Selamat! Kamu telah membuka tahap berikutnya dalam perjalanan kariermu.',
           '/journey?tahap=' || k.stage_code
    from public.quest_status(v_cid) s
    join public.quest_group_kinds k on k.code = s.group_kind
    join public.journey_stages j on j.code = k.stage_code
    where s.grup_terbuka and j.stage_order > 1
    on conflict (user_id, kind, ref) do nothing;

    -- Pengingat mingguan, satu kali per pekan, dan hanya kalau memang ada
    -- yang bisa dikerjakan. Mengingatkan orang tentang daftar kosong itu
    -- gangguan, bukan pengingat.
    if exists (select 1 from public.quest_status(v_cid) s where s.bisa or s.status = 'DIAMBIL') then
      insert into public.user_notifications (user_id, kind, ref, title_id, body_id, link)
      values (v_user, 'QUEST_MINGGUAN', v_pekan, 'Quest Mingguan Menunggumu',
              'Selesaikan quest minggu ini untuk terus melangkah menuju karier impianmu.',
              '/quest')
      on conflict (user_id, kind, ref) do nothing;
    end if;
  end if;
end $$;

comment on function public.sinkron_notifikasi() is
  'Menurunkan notifikasi dari kejadian yang sudah tercatat (badge, level, tahap terbuka, quest pekan ini).';

create or replace function public.notifikasi_state()
returns table (id bigint, kind text, judul text, isi text, link text,
               waktu timestamptz, dibaca boolean, n_baru integer)
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then return; end if;
  perform public.sinkron_notifikasi();

  return query
  select n.id, n.kind, n.title_id, n.body_id, n.link, n.created_at, n.read_at is not null,
         (select count(*)::integer from public.user_notifications
           where user_id = v_user and read_at is null)
  from public.user_notifications n
  where n.user_id = v_user
  order by n.created_at desc, n.id desc
  limit 30;
end $$;

comment on function public.notifikasi_state() is
  'Tiga puluh notifikasi terbaru beserta jumlah yang belum dibaca.';

create or replace function public.tandai_notifikasi_dibaca()
returns integer
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare v_n integer;
begin
  if auth.uid() is null then return 0; end if;
  update public.user_notifications
     set read_at = now()
   where user_id = auth.uid() and read_at is null;
  get diagnostics v_n = row_count;
  return v_n;
end $$;

comment on function public.tandai_notifikasi_dibaca() is
  'Tandai semua notifikasi pengguna sudah dibaca; mengembalikan berapa yang berubah.';

-- ---------------------------------------------------------------------------
-- 4. Isi layar Profile
-- ---------------------------------------------------------------------------
create or replace function public.profil_state()
returns table (
  full_name text, nama_tampil text, avatar_url text, email text,
  level_code text, level_label text, study_label text,
  graduation_status text, grade_level smallint, semester smallint,
  is_final_semester boolean, pakai_kelas boolean, n_notifikasi_baru integer
)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with me as (select auth.uid() as uid),
  akun as (select u.email, u.raw_user_meta_data from auth.users u, me where u.id = me.uid),
  prof as (select p.* from public.profiles p, me where p.user_id = me.uid)
  select
    (select full_name from prof),
    -- Sapaan di layar lain memakai aturan yang sama dengan explore_state.
    coalesce(
      nullif(btrim((select full_name from prof)), ''),
      nullif(btrim((select raw_user_meta_data->>'full_name' from akun)), ''),
      nullif(btrim((select raw_user_meta_data->>'name' from akun)), ''),
      public.nama_dari_email((select email from akun))
    ),
    (select avatar_url from prof),
    (select email from akun),
    (select education_level_code from prof),
    (select el.level_name from public.education_levels el
      where el.code = (select education_level_code from prof)),
    coalesce(
      (select sp.name_id from public.study_programs sp
        where sp.id = (select study_program_id from prof)),
      (select sk.name_id from public.smk_concentrations sk
        where sk.id = (select smk_concentration_id from prof)),
      (select study_program_custom from prof)
    ),
    (select graduation_status from prof),
    (select grade_level from prof),
    (select semester from prof),
    (select is_final_semester from prof),
    -- SMP/SMA/SMK memakai kelas; jenjang tinggi memakai semester. Ini yang
    -- menentukan kolom mana yang digambar tab Pendidikan.
    (select education_level_code from prof) in ('SMP','SMA','SMK'),
    (select count(*)::integer from public.user_notifications
      where user_id = (select uid from me) and read_at is null);
$$;

comment on function public.profil_state() is
  'Isi tab Profile dan Pendidikan, plus jumlah notifikasi yang belum dibaca untuk lencana tab.';

create or replace function public.simpan_profil(p_nama text, p_avatar_url text default null)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  v_nama text := nullif(btrim(coalesce(p_nama, '')), '');
begin
  if v_user is null then
    raise exception 'simpan_profil: tidak ada pengguna terautentikasi';
  end if;
  if v_nama is not null and length(v_nama) > 60 then
    raise exception 'simpan_profil: Nama terlalu panjang, maksimal 60 karakter.';
  end if;

  -- Avatar hanya boleh menunjuk bucket avatars milik pengguna sendiri. Tanpa
  -- pemeriksaan ini kolomnya bisa diisi URL mana pun lewat REST, dan gambar
  -- dari situs lain akan ditampilkan atas nama Navika.
  if p_avatar_url is not null
     and p_avatar_url not like '%/storage/v1/object/public/avatars/' || v_user::text || '/%' then
    raise exception 'simpan_profil: Alamat avatar tidak dikenali.';
  end if;

  insert into public.profiles (user_id, full_name, avatar_url)
  values (v_user, v_nama, p_avatar_url)
  on conflict (user_id) do update set
    full_name  = excluded.full_name,
    avatar_url = excluded.avatar_url,
    updated_at = now();
end $$;

comment on function public.simpan_profil(text, text) is
  'Simpan nama tampilan dan avatar. p_avatar_url NULL berarti avatar dihapus.';

create or replace function public.simpan_pendidikan(
  p_status text, p_grade smallint default null,
  p_semester smallint default null, p_akhir boolean default false)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  v_level text;
begin
  if v_user is null then
    raise exception 'simpan_pendidikan: tidak ada pengguna terautentikasi';
  end if;
  if p_status not in ('sedang_studi','sudah_lulus') then
    raise exception 'simpan_pendidikan: status % tidak dikenali', p_status;
  end if;

  select education_level_code into v_level from public.profiles where user_id = v_user;
  if v_level is null then
    raise exception 'simpan_pendidikan: Selesaikan onboarding dulu.';
  end if;

  -- Jenjang dan jurusan tidak diubah di sini: keduanya menentukan seluruh
  -- roadmap, dan menggantinya di tengah jalan bukan urusan layar profil.
  update public.profiles set
    graduation_status = p_status,
    grade_level = case when p_status = 'sedang_studi' and v_level in ('SMP','SMA','SMK')
                       then p_grade end,
    semester    = case when p_status = 'sedang_studi' and v_level not in ('SMP','SMA','SMK')
                       then p_semester end,
    is_final_semester = case when p_status = 'sedang_studi' and v_level not in ('SMP','SMA','SMK')
                             then coalesce(p_akhir, false) else false end,
    updated_at = now()
  where user_id = v_user;
end $$;

comment on function public.simpan_pendidikan(text, smallint, smallint, boolean) is
  'Simpan status studi dan kelas/semester. Jenjang dan jurusan tidak bisa diubah dari layar profil.';

-- ---------------------------------------------------------------------------
-- 5. Avatar ikut terbaca di Explore
--
--    Bentuk balikannya bertambah satu kolom, jadi fungsinya dijatuhkan dulu.
--    Isinya persis seperti 0025 kecuali tambahan avatar_url.
-- ---------------------------------------------------------------------------
drop function if exists public.explore_state();

create function public.explore_state()
returns table (
  full_name          text,
  avatar_url         text,
  has_career         boolean,
  has_dna            boolean,
  dna_step           smallint,
  dna_started        boolean,
  career_id          integer,
  career_name        text,
  percent_done       numeric,
  study_label        text,
  top_activity       text
)
language sql stable
security definer
set search_path = public, auth
as $$
  with me as (select auth.uid() as uid),
  akun as (
    select u.email, u.raw_user_meta_data
    from auth.users u, me
    where u.id = me.uid
  ),
  prof as (
    select p.full_name, p.avatar_url, p.study_program_id, p.smk_concentration_id
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
      (select sk.name_id from prof join smk_concentrations sk on sk.id = prof.smk_concentration_id)
    ),
    (select name_id from act);
$$;

-- ---------------------------------------------------------------------------
-- 6. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  perform public.profil_state();
  perform public.notifikasi_state();
  perform public.explore_state();

  select count(*) into n from information_schema.columns
   where table_schema = 'public' and table_name = 'profiles' and column_name = 'avatar_url';
  if n <> 1 then raise exception '0039: kolom profiles.avatar_url tidak terbentuk'; end if;

  raise notice '0039: profil, avatar, dan notifikasi siap';
end $$;

commit;
