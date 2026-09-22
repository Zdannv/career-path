-- ===========================================================================
-- 0037_kunci_profesi_dan_tahap.sql
--
-- Tiga penyesuaian setelah layar Quest (0036) dipakai:
--
-- 1. Tahap Journey terbuka bersamaan dengan quest-nya.
--    Sebelumnya roadmap_state() membuka satu tahap saja: tahap pertama yang
--    belum selesai. Tahap Pondasi baru selesai kalau kedua belas quest soft
--    skill tuntas, padahal quest hard skill dan tools (tahap Keahlian) sudah
--    terbuka setelah satu quest soft skill. Akibatnya pengguna bisa
--    mengerjakan quest tahap 3 sementara tahap 3 di Journey masih bergembok.
--    Sekarang satu tahap terbuka begitu salah satu jenis quest di dalamnya
--    terbuka -- aturan yang sama dengan layar Quest, dari fungsi yang sama.
--
-- 2. Profesi terkunci setelah ada progres.
--    Keputusan produk untuk MVP: sekali pengguna memilih profesi dan sudah
--    mengerjakan sesuatu di dalamnya, ia tidak bisa berganti profesi.
--    Sebelum ada progres, memilih profesi lain tetap boleh; roadmap lama
--    ditandai DITINGGALKAN supaya tidak ada dua roadmap aktif.
--
--    Dijaga dengan trigger di user_roadmaps, bukan hanya di start_roadmap():
--    tabel itu punya policy INSERT/UPDATE/DELETE untuk pemiliknya, jadi tanpa
--    trigger, pengguna bisa berganti profesi lewat REST langsung.
--
-- 3. quest_beranda() juga mengirim jenis quest yang masih terkunci, supaya
--    layar Quest bisa memperlihatkan apa yang menunggu -- di awal hanya ada
--    dua quest Eksplorasi, dan tanpa pratinjau itu terlihat seperti isinya
--    memang cuma dua.
--
-- Jalankan setelah 0036. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Progres dan kunci profesi
-- ---------------------------------------------------------------------------

-- "Progres" = ada jejak pengerjaan: quest diambil/selesai, item Journey
-- ditandai, atau aktivitas roadmap lama dicentang. Memilih jalur pendidikan
-- tidak dihitung; itu masih bagian dari menimbang profesi.
create or replace function public.punya_progres(p_user uuid, p_career_id integer)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_quests
                  where user_id = p_user and career_id = p_career_id)
      or exists (select 1 from public.user_journey_items
                  where user_id = p_user and career_id = p_career_id)
      or exists (select 1 from public.user_roadmap_activities a
                   join public.user_roadmaps r on r.id = a.user_roadmap_id
                  where a.user_id = p_user and r.career_id = p_career_id);
$$;

revoke all on function public.punya_progres(uuid, integer) from public, anon, authenticated;

-- Dipakai layar detail profesi untuk mengganti tombol "Pilih Profesi ini".
create or replace function public.profesi_terkunci()
returns table (career_id integer, career_name text, terkunci boolean)
language sql stable security definer set search_path to 'public', 'auth' as $$
  select c.id, c.career_name, public.punya_progres(auth.uid(), c.id)
  from public.careers c
  where c.id = public.profesi_pilihan();
$$;

comment on function public.profesi_terkunci() is
  'Profesi pilihan pengguna dan apakah sudah terkunci karena ada progres. Kosong kalau belum memilih.';

create or replace function public.jaga_ganti_profesi()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_nama text;
begin
  if tg_op = 'INSERT' then
    -- Ada progres di profesi lain yang masih dijalani? Tolak.
    select c.career_name into v_nama
    from public.user_roadmaps r
    join public.careers c on c.id = r.career_id
    where r.user_id = new.user_id
      and r.career_id <> new.career_id
      and r.status in ('AKTIF','JEDA')
      and public.punya_progres(new.user_id, r.career_id)
    limit 1;

    if v_nama is not null then
      raise exception 'start_roadmap: Profesi tidak bisa diganti karena kamu sudah punya progres sebagai %.', v_nama
        using errcode = 'check_violation';
    end if;
    return new;
  end if;

  -- UPDATE / DELETE: roadmap yang sudah berprogres tidak boleh ditinggalkan,
  -- dipindah ke profesi lain, atau dihapus. Menandainya SELESAI tetap boleh.
  if public.punya_progres(old.user_id, old.career_id) then
    if tg_op = 'DELETE'
       or new.career_id <> old.career_id
       or new.status = 'DITINGGALKAN' then
      raise exception 'start_roadmap: Profesi yang sudah berprogres tidak bisa diganti atau dihapus.'
        using errcode = 'check_violation';
    end if;
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end $$;

drop trigger if exists trg_jaga_ganti_profesi on public.user_roadmaps;
create trigger trg_jaga_ganti_profesi
  before insert or update or delete on public.user_roadmaps
  for each row execute function public.jaga_ganti_profesi();

-- Ganti profesi sebelum ada progres: roadmap lama ditinggalkan, bukan
-- dibiarkan aktif berdampingan. profesi_pilihan() memang mengambil yang
-- terbaru, tapi dua roadmap aktif membingungkan layar lain yang membaca
-- user_roadmaps langsung.
create or replace function public.tinggalkan_roadmap_lain()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.user_roadmaps
     set status = 'DITINGGALKAN'
   where user_id = new.user_id
     and id <> new.id
     and status in ('AKTIF','JEDA');
  return null;
end $$;

drop trigger if exists trg_tinggalkan_roadmap_lain on public.user_roadmaps;
create trigger trg_tinggalkan_roadmap_lain
  after insert on public.user_roadmaps
  for each row execute function public.tinggalkan_roadmap_lain();

-- ---------------------------------------------------------------------------
-- 2. Tahap terbuka mengikuti quest
-- ---------------------------------------------------------------------------
create or replace function public.roadmap_state()
returns table (career_id integer, career_name text, has_career boolean,
               total_xp integer, level_name text, min_xp integer, next_xp integer,
               tahap jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with pilih as (select public.profesi_pilihan() as cid),
  prof as (
    select c.id, c.career_name from public.careers c, pilih where c.id = pilih.cid
  ),
  xp as (select * from public.xp_pengguna()),
  -- Tahap terbuka = salah satu jenis quest di dalamnya sudah terbuka.
  buka as (
    select k.stage_code, bool_or(s.grup_terbuka) as terbuka
    from pilih
    cross join lateral public.quest_status(pilih.cid) s
    join public.quest_group_kinds k on k.code = s.group_kind
    where pilih.cid is not null
    group by k.stage_code
  ),
  prog as (
    select s.code, s.stage_order, s.name_id, s.summary_id,
           coalesce(p.percent, 0)::smallint as persen,
           p.completed_at is not null as selesai,
           -- Tanpa profesi pilihan, hanya tahap pertama yang terbuka.
           coalesce(b.terbuka, s.stage_order = 1) as terbuka
    from public.journey_stages s
    left join public.user_journey_progress p
           on p.stage_code = s.code
          and p.user_id = auth.uid()
          and p.career_id = (select cid from pilih)
    left join buka b on b.stage_code = s.code
  )
  select
    (select id from prof),
    (select career_name from prof),
    (select count(*) from prof) > 0,
    (select total_xp from xp), (select level_name from xp),
    (select min_xp from xp), (select next_xp from xp),
    (select jsonb_agg(jsonb_build_object(
       'kode',      g.code,
       'urutan',    g.stage_order,
       'nama',      g.name_id,
       'ringkasan', g.summary_id,
       'persen',    g.persen,
       'status',    case when g.selesai then 'SELESAI'
                         when g.terbuka then 'AKTIF'
                         else 'TERKUNCI' end,
       'cta',       not g.selesai and g.terbuka
     ) order by g.stage_order)
     from prog g);
$$;

comment on function public.roadmap_state() is
  'Kartu profesi, level XP, dan lima tahap persiapan. Tahap terbuka kalau salah satu jenis quest-nya terbuka (0037).';

-- ---------------------------------------------------------------------------
-- 3. quest_beranda + jenis yang masih terkunci
--
--    Tipe kembaliannya bertambah satu kolom, jadi fungsi lama harus dijatuhkan
--    dulu -- create or replace tidak boleh mengubah bentuk tabel kembalian.
-- ---------------------------------------------------------------------------
drop function if exists public.quest_beranda();

create function public.quest_beranda()
returns table (career_id integer, career_name text, has_career boolean,
               eksplorasi_selesai boolean, semua_selesai boolean,
               grup jsonb, terkunci jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with pilih as (select public.profesi_pilihan() as cid),
  prof as (select c.id, c.career_name from public.careers c, pilih where c.id = pilih.cid),
  st as (select s.* from pilih, public.quest_status(pilih.cid) s where pilih.cid is not null),
  g as (
    select s.group_kind, s.kind_order, s.group_code, s.group_order,
           s.group_title, s.group_subtitle,
           bool_and(s.grup_terbuka) as buka,
           count(*) as n_quest,
           count(*) filter (where s.status = 'SELESAI') as n_selesai,
           count(*) filter (where s.status = 'DIAMBIL') as n_diambil
    from st s
    group by 1,2,3,4,5,6
  ),
  pertama as (
    select distinct on (g.group_kind) g.*
    from g
    where g.buka and g.n_selesai < g.n_quest
    order by g.group_kind, g.group_order
  ),
  kunci as (
    select s.group_kind, count(*) as n_quest, count(distinct s.group_code) as n_grup
    from st s
    where not s.grup_terbuka
    group by s.group_kind
  )
  select
    (select id from prof),
    (select career_name from prof),
    exists (select 1 from prof),
    coalesce((select bool_and(status = 'SELESAI') from st where group_kind = 'EKSPLORASI'), false),
    exists (select 1 from st) and not exists (select 1 from st where status <> 'SELESAI'),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'jenis',     p.group_kind,
        'slug',      k.slug,
        'kode',      p.group_code,
        'label',     k.label_id,
        'judul',     p.group_title,
        'subjudul',  p.group_subtitle,
        'ikon',      k.icon,
        'tone',      k.tone,
        'n_quest',   p.n_quest,
        'n_selesai', p.n_selesai,
        'n_diambil', p.n_diambil
      ) order by p.kind_order)
      from pertama p join public.quest_group_kinds k on k.code = p.group_kind
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'jenis',   x.group_kind,
        'label',   k.label_id,
        'tahap',   js.name_id,
        'ikon',    k.icon,
        'tone',    k.tone,
        'n_quest', x.n_quest,
        'n_grup',  x.n_grup,
        'alasan',  k.alasan_kunci
      ) order by k.kind_order)
      from kunci x
      join public.quest_group_kinds k on k.code = x.group_kind
      join public.journey_stages js on js.code = k.stage_code
    ), '[]'::jsonb);
$$;

comment on function public.quest_beranda() is
  'Kartu-kartu layar Quest: satu grup berjalan per jenis yang sudah terbuka, ditambah pratinjau jenis yang masih terkunci.';

-- ---------------------------------------------------------------------------
-- 4. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_cid int;
begin
  select id into v_cid from public.careers where is_active order by id limit 1;
  perform public.roadmap_state();
  perform public.quest_beranda();
  perform public.profesi_terkunci();

  if not exists (select 1 from pg_trigger where tgname = 'trg_jaga_ganti_profesi') then
    raise exception '0037: trigger penjaga ganti profesi tidak terpasang';
  end if;

  raise notice '0037: tahap Journey mengikuti quest, profesi terkunci setelah ada progres';
end $$;

commit;
