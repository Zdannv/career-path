-- ===========================================================================
-- 0038_progress_dan_pencapaian.sql
--
-- Layar Progress: total progress, level XP, statistik, dan pencapaian (badge).
--
-- ---------------------------------------------------------------------------
-- Sumber aturannya
-- ---------------------------------------------------------------------------
-- Sheet "Level progression" dan "Title Achievement" di workbook tim, plus
-- layar 10 Progress A01/A02. Tiga hal diputuskan di sini karena sumbernya
-- berbeda satu sama lain:
--
--   * Deskripsi badge memakai layar A02, bukan sheet. Keduanya berbeda untuk
--     dua badge (sheet: Foundation Builder = quest soft skill, DNA Eksplorer =
--     Career DNA; layar: kebalikannya) dan gambar badge-nya mengikuti layar --
--     Foundation Builder bergambar untai DNA.
--   * Badge "Co-op Socializer" (Join Discord Community, 500 XP) dilewati:
--     belum ada fitur Discord di aplikasi dan gambarnya tidak ada.
--   * Badge "Achiever" di sheet tidak punya gambar; perannya diambil
--     Experience Hunter (Asah Pengalaman) dan Career Ready (seluruh roadmap).
--
-- ---------------------------------------------------------------------------
-- Level
-- ---------------------------------------------------------------------------
-- Menggantikan lima level 0033 (Explorer..Professional) dengan sepuluh level
-- plus "10+" dari sheet. Ambangnya kumulatif: kolom "XP untuk naik ke level
-- berikutnya" di sheet adalah selisih antar-ambang, dan angka itulah yang
-- dipakai di sini.
--
-- Nama besar di kartu Progress bukan nama level, melainkan Title: Explorer,
-- Pathfinder, Builder, Achiever, Challenger. Title didapat kalau seluruh badge
-- di kategorinya sudah terkumpul -- itu aturan dari sheet. Sebelum satu pun
-- kategori lengkap, title-nya "Rookie" (ini istilah dari sini, bukan sheet).
--
-- ---------------------------------------------------------------------------
-- XP dan badge dari kejadian
-- ---------------------------------------------------------------------------
-- XP tidak hanya dari quest. Membuat akun, menyelesaikan onboarding, Career
-- DNA, dan memilih profesi juga memberi XP -- masing-masing sekali seumur akun.
--
-- Semuanya dihitung ulang dari data oleh sinkron_pencapaian(), bukan dipancing
-- trigger di tiap alur. Alasannya: pengguna yang sudah selesai onboarding
-- sebelum migrasi ini tetap mendapat XP-nya, dan tidak ada satu pun alur yang
-- bisa lupa memanggil. Idempoten lewat index unik di xp_ledger.
--
-- Jalankan setelah 0037. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Level XP
-- ---------------------------------------------------------------------------
delete from public.xp_levels where level > 11;

insert into public.xp_levels (level, name_id, min_xp, next_xp) values
  (1,  '1',    0,   100),
  (2,  '2',    100,  350),
  (3,  '3',    350,  650),
  (4,  '4',    650,  950),
  (5,  '5',    950,  1300),
  (6,  '6',    1300, 1650),
  (7,  '7',    1650, 2050),
  (8,  '8',    2050, 2550),
  (9,  '9',    2550, 3350),
  (10, '10',   3350, 4350),
  (11, '10+',  4350, null)
on conflict (level) do update set
  name_id = excluded.name_id, min_xp = excluded.min_xp, next_xp = excluded.next_xp;

comment on column public.xp_levels.name_id is
  'Label level yang tampil ("1".."10", lalu "10+" sebagai level tertinggi).';

-- ---------------------------------------------------------------------------
-- 2. Title
-- ---------------------------------------------------------------------------
create table if not exists public.achievement_titles (
  code    text primary key,
  name_id text not null,
  urutan  smallint not null unique
);

insert into public.achievement_titles (code, name_id, urutan) values
  ('EXPLORER',   'Explorer',   1),
  ('PATHFINDER', 'Pathfinder', 2),
  ('BUILDER',    'Builder',    3),
  ('ACHIEVER',   'Achiever',   4),
  ('CHALLENGER', 'Challenger', 5)
on conflict (code) do update set name_id = excluded.name_id, urutan = excluded.urutan;

-- ---------------------------------------------------------------------------
-- 3. Katalog badge
--
--    achievements sudah ada sejak 0036 (satu baris, Quest Starter). Di sini ia
--    dilengkapi kategori dan urutan tampil, lalu diisi dua belas badge desain.
-- ---------------------------------------------------------------------------
alter table public.achievements add column if not exists kategori text;
alter table public.achievements add column if not exists urutan smallint;

insert into public.achievements (code, name_id, description_id, image, kategori, urutan) values
  ('FIRST_STEP',        'First Step',        'Menyelesaikan Onboarding',
   '/progress/badge/first-step.webp',        'EXPLORER',   1),
  ('FOUNDATION_BUILDER','Foundation Builder','Menyelesaikan Career DNA Discovery',
   '/progress/badge/foundation-builder.webp','EXPLORER',   2),
  ('QUEST_STARTER',     'Quest Starter',     'Menyelesaikan Quest Pertama kali',
   '/progress/badge/quest-starter.webp',     'PATHFINDER', 3),
  ('PATH_FINDER',       'Path Finder',       'Menemukan arah karier dan memilih profesi',
   '/progress/badge/path-finder.webp',       'PATHFINDER', 4),
  ('DNA_EXPLORER',      'DNA Eksplorer',     'Menyelesaikan Quest Soft Skill Pertama kali',
   '/progress/badge/dna-explorer.webp',      'BUILDER',    5),
  ('SKILL_BUILDER',     'Skill Builder',     'Menyelesaikan Quest Hard Skill Pertama kali',
   '/progress/badge/skill-builder.webp',     'BUILDER',    6),
  ('TOOL_MASTER',       'Tool Master',       'Menyelesaikan Quest Tools Pertama kali',
   '/progress/badge/tool-master.webp',       'BUILDER',    7),
  ('EXPERIENCE_HUNTER', 'Experience Hunter', 'Menyelesaikan Proyek/Magang pertama kali',
   '/progress/badge/experience-hunter.webp', 'ACHIEVER',   8),
  ('CAREER_READY',      'Career Ready',      'Menyelesaikan seluruh Roadmap',
   '/progress/badge/career-ready.webp',      'CHALLENGER', 9),
  ('NOVICE_RANK',       'Novice Rank',       'Mencapai Progress Level 2',
   '/progress/badge/novice-rank.webp',       'RANK',       10),
  ('SKILLED',           'Skilled',           'Mencapai Progress Level 6',
   '/progress/badge/skilled.webp',           'RANK',       11),
  ('HIGH_RANK',         'High Rank',         'Mencapai Progress Level Max',
   '/progress/badge/high-rank.webp',         'RANK',       12)
on conflict (code) do update set
  name_id = excluded.name_id, description_id = excluded.description_id,
  image = excluded.image, kategori = excluded.kategori, urutan = excluded.urutan;

-- ---------------------------------------------------------------------------
-- 4. Aturan hadiah
--
--    Satu baris = satu kejadian yang berbuah XP, badge, atau keduanya.
--    reward_id dipakai sebagai source_id di xp_ledger; angkanya tidak boleh
--    berubah, karena itu yang menjaga satu hadiah dibayar sekali saja.
-- ---------------------------------------------------------------------------
create table if not exists public.progress_rules (
  code       text primary key,
  reward_id  smallint not null unique,
  xp         smallint not null default 0,
  badge_code text references public.achievements(code),
  label_id   text not null,
  urutan     smallint not null
);

insert into public.progress_rules (code, reward_id, xp, badge_code, label_id, urutan) values
  ('AKUN',               1, 150, null,                'Membuat akun',                        1),
  ('ONBOARDING',         2, 250, 'FIRST_STEP',        'Menyelesaikan onboarding',            2),
  ('CAREER_DNA',         3, 300, 'FOUNDATION_BUILDER','Menyelesaikan Career DNA',            3),
  ('PILIH_PROFESI',      4, 300, 'PATH_FINDER',       'Memilih profesi impian',              4),
  ('QUEST_PERTAMA',      5, 100, 'QUEST_STARTER',     'Menyelesaikan quest pertama',         5),
  ('SOFT_PERTAMA',       6, 100, 'DNA_EXPLORER',      'Menyelesaikan quest soft skill',      6),
  ('HARD_PERTAMA',       7, 100, 'SKILL_BUILDER',     'Menyelesaikan quest hard skill',      7),
  ('TOOL_PERTAMA',       8, 100, 'TOOL_MASTER',       'Menyelesaikan quest tools',           8),
  ('PENGALAMAN_PERTAMA', 9, 250, 'EXPERIENCE_HUNTER', 'Menyelesaikan quest Asah Pengalaman', 9),
  ('ROADMAP_SELESAI',   10, 500, 'CAREER_READY',      'Menyelesaikan seluruh roadmap',      10),
  -- Badge peringkat dinilai setelah XP di atas ditambahkan, jadi urutannya
  -- paling belakang: naik level karena hadiah barusan tetap terhitung.
  ('LEVEL_2',           11,   0, 'NOVICE_RANK',       'Mencapai level 2',                   11),
  ('LEVEL_6',           12,   0, 'SKILLED',           'Mencapai level 6',                   12),
  ('LEVEL_MAX',         13,   0, 'HIGH_RANK',         'Mencapai level tertinggi',           13)
on conflict (code) do update set
  reward_id = excluded.reward_id, xp = excluded.xp, badge_code = excluded.badge_code,
  label_id = excluded.label_id, urutan = excluded.urutan;

create unique index if not exists uq_xp_achievement_once
  on public.xp_ledger (user_id, source_id) where source_kind = 'ACHIEVEMENT';

do $$
declare t text;
begin
  foreach t in array array['achievement_titles','progress_rules']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_read_all', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t||'_read_all', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 5. Apakah sebuah aturan sudah terpenuhi
-- ---------------------------------------------------------------------------
create or replace function public.aturan_terpenuhi(p_user uuid, p_code text)
returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  v_cid integer;
  v_xp  integer;
begin
  case p_code
    when 'AKUN' then
      return true;

    when 'ONBOARDING' then
      return exists (select 1 from public.profiles
                      where user_id = p_user and onboarding_completed_at is not null);

    when 'CAREER_DNA' then
      return exists (select 1 from public.user_dna_progress
                      where user_id = p_user and completed_at is not null);

    when 'PILIH_PROFESI' then
      return exists (select 1 from public.user_roadmaps
                      where user_id = p_user and status in ('AKTIF','JEDA'));

    when 'QUEST_PERTAMA' then
      return exists (select 1 from public.user_quests
                      where user_id = p_user and status = 'SELESAI');

    when 'SOFT_PERTAMA' then
      return exists (select 1 from public.user_quests
                      where user_id = p_user and status = 'SELESAI'
                        and quest_key like 'SOFT_SKILL:%');

    when 'HARD_PERTAMA' then
      return exists (select 1 from public.user_quests
                      where user_id = p_user and status = 'SELESAI'
                        and quest_key like 'HARD_SKILL:%');

    when 'TOOL_PERTAMA' then
      return exists (select 1 from public.user_quests
                      where user_id = p_user and status = 'SELESAI'
                        and quest_key like 'TOOL:%');

    when 'PENGALAMAN_PERTAMA' then
      return exists (select 1 from public.user_quests
                      where user_id = p_user and status = 'SELESAI'
                        and quest_key like 'PENGALAMAN:%');

    when 'ROADMAP_SELESAI' then
      -- Seluruh quest profesi yang sedang dijalani selesai.
      select ur.career_id into v_cid
      from public.user_roadmaps ur
      where ur.user_id = p_user and ur.status in ('AKTIF','JEDA')
      order by ur.started_at desc limit 1;
      if v_cid is null then return false; end if;
      return (select count(*) from public.quest_katalog(v_cid)) > 0
         and (select count(*) from public.quest_katalog(v_cid))
           = (select count(*) from public.user_quests u
               where u.user_id = p_user and u.career_id = v_cid and u.status = 'SELESAI');

    when 'LEVEL_2' then
      select coalesce(sum(xp), 0) into v_xp from public.xp_ledger where user_id = p_user;
      return v_xp >= (select min_xp from public.xp_levels where level = 2);

    when 'LEVEL_6' then
      select coalesce(sum(xp), 0) into v_xp from public.xp_ledger where user_id = p_user;
      return v_xp >= (select min_xp from public.xp_levels where level = 6);

    when 'LEVEL_MAX' then
      select coalesce(sum(xp), 0) into v_xp from public.xp_ledger where user_id = p_user;
      return v_xp >= (select min_xp from public.xp_levels where next_xp is null);

    else
      return false;
  end case;
end $$;

revoke all on function public.aturan_terpenuhi(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 6. Bagikan hadiah yang sudah pantas didapat
--
--    Mengembalikan badge yang baru terbuka pada panggilan ini -- itu yang
--    dipakai layar sukses quest untuk menampilkan "New Badge Unlocked!".
-- ---------------------------------------------------------------------------
create or replace function public.sinkron_pencapaian()
returns jsonb
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  v_baru jsonb := '[]'::jsonb;
  r record;
begin
  if v_user is null then
    return v_baru;
  end if;

  for r in select * from public.progress_rules order by urutan loop
    -- Sudah pernah dibayar?
    continue when exists (
      select 1 from public.xp_ledger x
      where x.user_id = v_user and x.source_kind = 'ACHIEVEMENT' and x.source_id = r.reward_id
    ) or (r.badge_code is not null and exists (
      select 1 from public.user_achievements a
      where a.user_id = v_user and a.code = r.badge_code
    ));

    continue when not public.aturan_terpenuhi(v_user, r.code);

    if r.xp > 0 then
      insert into public.xp_ledger (user_id, source_kind, source_id, xp, reason)
      values (v_user, 'ACHIEVEMENT', r.reward_id, r.xp, r.label_id)
      on conflict do nothing;
    end if;

    if r.badge_code is not null then
      insert into public.user_achievements (user_id, code)
      values (v_user, r.badge_code)
      on conflict do nothing;

      v_baru := v_baru || (
        select jsonb_build_array(jsonb_build_object(
          'kode', a.code, 'nama', a.name_id,
          'deskripsi', a.description_id, 'gambar', a.image))
        from public.achievements a where a.code = r.badge_code);
    end if;
  end loop;

  return v_baru;
end $$;

comment on function public.sinkron_pencapaian() is
  'Hitung ulang hadiah XP dan badge dari data pengguna, lalu kembalikan badge yang baru terbuka.';

-- ---------------------------------------------------------------------------
-- 7. Title yang sedang disandang
-- ---------------------------------------------------------------------------
create or replace function public.title_pengguna()
returns text
language sql stable security definer set search_path to 'public', 'auth' as $$
  select coalesce((
    select t.name_id
    from public.achievement_titles t
    where not exists (
      select 1 from public.achievements a
      where a.kategori = t.code
        and not exists (select 1 from public.user_achievements u
                         where u.user_id = auth.uid() and u.code = a.code)
    )
    order by t.urutan desc
    limit 1
  ), 'Rookie');
$$;

comment on function public.title_pengguna() is
  'Title tertinggi yang seluruh badge kategorinya sudah terkumpul. "Rookie" kalau belum ada.';

-- ---------------------------------------------------------------------------
-- 8. Layar Progress
-- ---------------------------------------------------------------------------
create or replace function public.progress_state()
returns table (
  career_id integer, career_name text, has_career boolean,
  total_persen smallint, n_quest_total integer, n_quest_selesai integer,
  n_achievement integer, n_achievement_total integer,
  level smallint, level_label text, title text,
  total_xp integer, xp_di_level integer, xp_level_berikutnya integer, persen_level smallint,
  terbaru jsonb
)
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
  v_cid  integer := public.profesi_pilihan();
  v_tot  integer := 0;
  v_done integer := 0;
begin
  -- Tanpa pengguna (mis. saat penjaga migrasi memanggilnya) tidak ada yang
  -- bisa dihitung; kembalikan kosong, bukan galat.
  if v_user is null then
    return;
  end if;

  -- Dibagikan lebih dulu supaya angka di layar ini sudah termasuk hadiah yang
  -- baru pantas didapat -- misalnya XP onboarding untuk akun lama.
  perform public.sinkron_pencapaian();

  if v_cid is not null then
    select count(*) into v_tot from public.quest_katalog(v_cid);
    select count(*) into v_done from public.user_quests u
     where u.user_id = v_user and u.career_id = v_cid and u.status = 'SELESAI';
  end if;

  return query
  with xp as (select * from public.xp_pengguna())
  select
    v_cid,
    (select c.career_name from public.careers c where c.id = v_cid),
    v_cid is not null,
    case when v_tot > 0 then round(100.0 * v_done / v_tot) else 0 end::smallint,
    v_tot,
    v_done,
    (select count(*)::integer from public.user_achievements where user_id = v_user),
    (select count(*)::integer from public.achievements),
    xp.level,
    xp.level_name,
    public.title_pengguna(),
    xp.total_xp,
    xp.total_xp - xp.min_xp,
    case when xp.next_xp is null then null else xp.next_xp - xp.min_xp end,
    xp.persen,
    coalesce((
      select jsonb_agg(jsonb_build_object(
               'kode', a.code, 'nama', a.name_id,
               'deskripsi', a.description_id, 'gambar', a.image,
               'waktu', u.unlocked_at) order by u.unlocked_at desc)
      from (select * from public.user_achievements
             where user_id = v_user order by unlocked_at desc limit 3) u
      join public.achievements a on a.code = u.code
    ), '[]'::jsonb)
  from xp;
end $$;

comment on function public.progress_state() is
  'Isi layar Progress: total progress quest, level dan title, statistik, dan tiga pencapaian terbaru.';

create or replace function public.progress_pencapaian()
returns table (code text, nama text, deskripsi text, gambar text,
               kategori text, urutan smallint, waktu timestamptz)
language sql stable security definer set search_path to 'public', 'auth' as $$
  select a.code, a.name_id, a.description_id, a.image, a.kategori, a.urutan, u.unlocked_at
  from public.achievements a
  left join public.user_achievements u on u.code = a.code and u.user_id = auth.uid()
  order by a.urutan;
$$;

comment on function public.progress_pencapaian() is
  'Seluruh badge beserta waktu terbukanya. waktu NULL berarti masih terkunci.';

-- ---------------------------------------------------------------------------
-- 9. selesaikan_quest memakai mesin pencapaian
--
--    Sebelumnya fungsi ini memberi badge Quest Starter sendiri. Sekarang badge
--    dan XP kejadian keduanya datang dari sinkron_pencapaian(), jadi quest
--    soft skill pertama juga membuka DNA Eksplorer, dan seterusnya.
-- ---------------------------------------------------------------------------
create or replace function public.selesaikan_quest(p_quest_key text)
returns table (xp integer, total_xp integer, level_name text, badge jsonb)
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user  uuid := auth.uid();
  v_cid   integer := public.profesi_pilihan();
  v_id    bigint;
  v_baru  jsonb;
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

  if q.mode = 'AMBIL' then
    if q.status <> 'DIAMBIL' then
      raise exception 'selesaikan_quest: ambil quest % dulu', p_quest_key;
    end if;
    update public.user_quests
       set status = 'SELESAI', completed_at = now()
     where user_id = v_user and career_id = v_cid and quest_key = p_quest_key
    returning id into v_id;
  else
    if not q.bisa then
      raise exception 'selesaikan_quest: %', coalesce(q.alasan, 'quest belum terbuka');
    end if;
    insert into public.user_quests (user_id, career_id, quest_key, status, xp, completed_at)
    values (v_user, v_cid, p_quest_key, 'SELESAI', q.xp, now())
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

comment on function public.selesaikan_quest(text) is
  'Selesaikan satu quest: tulis XP sekali, bagikan badge yang pantas lewat sinkron_pencapaian(), dan perbarui kemajuan Journey.';

-- ---------------------------------------------------------------------------
-- 10. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  select count(*) into n from public.xp_levels;
  if n <> 11 then raise exception '0038: xp_levels harus 11 baris, dapat %', n; end if;

  select count(*) into n from public.xp_levels a join public.xp_levels b on b.level = a.level + 1
   where a.next_xp is distinct from b.min_xp;
  if n > 0 then raise exception '0038: % ambang level tidak menyambung', n; end if;

  select count(*) into n from public.achievements;
  if n <> 12 then raise exception '0038: achievements harus 12 badge, dapat %', n; end if;

  -- Tiap badge non-RANK harus masuk salah satu title, dan tiap title harus
  -- punya badge -- kalau tidak, title itu mustahil (atau gratis) didapat.
  select count(*) into n from public.achievements a
   where a.kategori <> 'RANK'
     and not exists (select 1 from public.achievement_titles t where t.code = a.kategori);
  if n > 0 then raise exception '0038: % badge berkategori yang bukan title', n; end if;

  select count(*) into n from public.achievement_titles t
   where not exists (select 1 from public.achievements a where a.kategori = t.code);
  if n > 0 then raise exception '0038: % title tanpa badge', n; end if;

  -- Tiap badge harus bisa terbuka lewat sebuah aturan.
  select count(*) into n from public.achievements a
   where not exists (select 1 from public.progress_rules r where r.badge_code = a.code);
  if n > 0 then raise exception '0038: % badge tanpa aturan pembuka', n; end if;

  perform public.progress_state();
  perform public.progress_pencapaian();

  raise notice '0038: 11 level, % badge, % aturan hadiah, % title',
    (select count(*) from public.achievements),
    (select count(*) from public.progress_rules),
    (select count(*) from public.achievement_titles);
end $$;

commit;
