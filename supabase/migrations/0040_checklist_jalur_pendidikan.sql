-- ===========================================================================
-- 0040_checklist_jalur_pendidikan.sql
--
-- Langkah di tab "Jalur Pendidikan" sekarang bisa dicentang pengguna.
--
-- ---------------------------------------------------------------------------
-- Kenapa
-- ---------------------------------------------------------------------------
-- Sejak 0034 status tiap langkah hanya diturunkan dari jenjang di profil:
-- langkah pendidikan hijau kalau jenjangnya sudah tuntas, sedangkan langkah
-- lain -- uji kompetensi, STR, mulai bekerja -- selamanya "Belum Mulai" karena
-- tidak ada yang menandainya. Hasil pengujian (TC_RDM_07) meminta aturannya:
-- satu langkah baru bisa dicentang kalau langkah sebelumnya sudah selesai.
--
-- ---------------------------------------------------------------------------
-- Aturannya
-- ---------------------------------------------------------------------------
--   * Langkah yang selesai menurut profil tetap otomatis dan tidak bisa
--     dilepas di sini -- sumbernya profil, jadi yang diubah profilnya.
--   * Langkah lain bisa dicentang kalau langkah sebelumnya selesai, baik
--     otomatis maupun dicentang. Langkah pertama selalu bisa.
--   * Centang hanya bisa dilepas dari yang paling akhir: melepas langkah di
--     tengah akan meninggalkan langkah sesudahnya "selesai" tanpa pendahulu.
--
-- Aturan ini diperiksa di database. Kotak centang yang mati di layar hanya
-- petunjuk; tanpa pemeriksaan di sini, urutannya bisa dilompati lewat REST.
--
-- Jalankan setelah 0039. Aman diulang.
-- ===========================================================================

begin;

create table if not exists public.user_education_path_steps (
  user_id    uuid not null references auth.users(id) on delete cascade,
  path_id    integer not null,
  step_order smallint not null,
  done_at    timestamptz not null default now(),
  primary key (user_id, path_id, step_order),
  foreign key (path_id, step_order)
    references public.career_education_path_steps (path_id, step_order) on delete cascade
);

comment on table public.user_education_path_steps is
  'Langkah jalur pendidikan yang dicentang pengguna sendiri. Langkah yang selesai menurut profil tidak dicatat di sini.';

alter table public.user_education_path_steps enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
                 and tablename = 'user_education_path_steps' and policyname = 'ueps_owner_select') then
    create policy ueps_owner_select on public.user_education_path_steps
      for select to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Status tiap langkah satu jalur untuk pengguna yang sedang masuk
-- ---------------------------------------------------------------------------
create or replace function public.langkah_jalur(p_path_id integer)
returns table (step_order smallint, title_id text, note_id text, step_kind text,
               status text, otomatis boolean, dicentang boolean, bisa boolean)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with o as (select * from public.posisi_studi()),
  d as (
    select s.step_order, s.title_id, s.note_id, s.step_kind,
           public.status_langkah_jalur(s.step_rank, o.rank_tercapai, o.rank_sedang) as oto,
           exists (select 1 from public.user_education_path_steps u
                    where u.user_id = auth.uid()
                      and u.path_id = s.path_id and u.step_order = s.step_order) as centang
    from public.career_education_path_steps s, o
    where s.path_id = p_path_id
  ),
  g as (select d.*, (d.oto = 'SELESAI' or d.centang) as selesai from d),
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
$$;

comment on function public.langkah_jalur(integer) is
  'Langkah satu jalur pendidikan: status gabungan (profil + centang), dan apakah kotaknya boleh diubah sekarang.';

-- ---------------------------------------------------------------------------
-- roadmap_jalur memakai status gabungan
--
-- Bentuk tabel kembaliannya tidak berubah; yang bertambah hanya tiga kunci di
-- dalam jsonb `langkah`, jadi create or replace cukup.
-- ---------------------------------------------------------------------------
create or replace function public.roadmap_jalur(p_career_id integer)
returns table (path_id integer, kind_code text, kind_label text, level_code text,
               title_id text, tagline_id text, years_min smallint, years_max smallint,
               cta_label_id text, table_label_id text, display_order smallint,
               dipilih boolean, keunggulan jsonb, langkah jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with terpilih as (
    select path_id from public.user_education_path
    where user_id = auth.uid() and career_id = p_career_id
  )
  select p.id, p.kind_code, k.label_id, p.level_code,
         p.title_id, p.tagline_id, p.years_min, p.years_max,
         p.cta_label_id, p.table_label_id, p.display_order,
         p.id is not distinct from (select path_id from terpilih)
           and exists (select 1 from terpilih),
         (select coalesce(jsonb_agg(b.text_id order by b.display_order), '[]'::jsonb)
            from public.career_education_path_benefits b where b.path_id = p.id),
         (select coalesce(jsonb_agg(jsonb_build_object(
                   'urutan',    l.step_order,
                   'judul',     l.title_id,
                   'catatan',   l.note_id,
                   'jenis',     l.step_kind,
                   'status',    l.status,
                   'otomatis',  l.otomatis,
                   'dicentang', l.dicentang,
                   'bisa',      l.bisa
                 ) order by l.step_order), '[]'::jsonb)
            from public.langkah_jalur(p.id) l)
  from public.career_education_paths p
  join public.education_path_kinds k on k.code = p.kind_code
  where p.career_id = p_career_id
  order by p.display_order;
$$;

-- ---------------------------------------------------------------------------
-- Centang / lepas centang
-- ---------------------------------------------------------------------------
create or replace function public.centang_langkah_jalur(
  p_path_id integer, p_step_order smallint, p_selesai boolean)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  l record;
begin
  if v_user is null then
    raise exception 'centang_langkah_jalur: tidak ada pengguna terautentikasi';
  end if;

  -- Hanya jalur yang memang sedang dipilih pengguna.
  if not exists (select 1 from public.user_education_path
                  where user_id = v_user and path_id = p_path_id) then
    raise exception 'centang_langkah_jalur: Pilih jalur pendidikannya dulu.';
  end if;

  select * into l from public.langkah_jalur(p_path_id) x where x.step_order = p_step_order;
  if not found then
    raise exception 'centang_langkah_jalur: langkah % tidak ada di jalur ini', p_step_order;
  end if;

  if l.otomatis then
    raise exception 'centang_langkah_jalur: Langkah ini mengikuti data pendidikan di profilmu.';
  end if;
  if l.dicentang = p_selesai then
    return;  -- sudah dalam keadaan yang diminta
  end if;
  if not l.bisa then
    if p_selesai then
      raise exception 'centang_langkah_jalur: Selesaikan langkah sebelumnya dulu.';
    else
      raise exception 'centang_langkah_jalur: Lepas dulu centang langkah sesudahnya.';
    end if;
  end if;

  if p_selesai then
    insert into public.user_education_path_steps (user_id, path_id, step_order)
    values (v_user, p_path_id, p_step_order)
    on conflict do nothing;
  else
    delete from public.user_education_path_steps
     where user_id = v_user and path_id = p_path_id and step_order = p_step_order;
  end if;
end $$;

comment on function public.centang_langkah_jalur(integer, smallint, boolean) is
  'Centang atau lepas satu langkah jalur pendidikan. Urutannya dijaga: langkah sebelumnya harus selesai.';

-- ---------------------------------------------------------------------------
-- Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_cid int; v_pid int;
begin
  select id into v_cid from public.careers where is_active order by id limit 1;
  perform public.roadmap_jalur(v_cid);
  select id into v_pid from public.career_education_paths order by id limit 1;
  perform public.langkah_jalur(v_pid);

  raise notice '0040: langkah jalur pendidikan bisa dicentang berurutan';
end $$;

commit;
