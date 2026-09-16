-- 0035_roadmap_journey_api.sql
-- RPC untuk layar Roadmap dan Journey.
--
-- Roadmap punya dua tab: "Persiapan" (lima tahap dari 0033) dan "Jalur
-- Pendidikan" (dari 0034). Journey adalah isi satu tahap: hero, penjelasan,
-- konten yang bentuknya berbeda tiap tahap, dan kotak hasil di bawah.
--
-- Semua fungsi memakai auth.uid() langsung, mengikuti pola RPC sebelumnya,
-- supaya frontend tidak perlu mengirim user_id yang bisa dipalsukan.

begin;

-- ------------------------------------------------- 1. tampilan atribut DNA --

-- Kartu soft skill di tahap Pondasi butuh ikon dan warna. Disimpan terpisah
-- dari dna_attributes supaya tabel data tidak tercampur urusan tampilan.
create table if not exists public.dna_attribute_visual (
  code text primary key references public.dna_attributes(code) on delete cascade,
  icon text not null,
  tone text not null,
  constraint chk_dna_visual_tone check (tone in ('biru','hijau','ungu','oranye','kuning','merah'))
);

alter table public.dna_attribute_visual enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public'
                 and tablename='dna_attribute_visual' and policyname='dna_attribute_visual_read_all') then
    create policy dna_attribute_visual_read_all on public.dna_attribute_visual
      for select to anon, authenticated using (true);
  end if;
end $$;

insert into public.dna_attribute_visual (code, icon, tone) values
  ('ACT_ANALISA',      'Search',            'biru'),
  ('ACT_DESAIN',       'Palette',           'ungu'),
  ('ACT_KOMUNIKASI',   'MessagesSquare',    'biru'),
  ('ACT_MEMBANGUN',    'Hammer',            'oranye'),
  ('ACT_MEMBANTU',     'HeartHandshake',    'merah'),
  ('ACT_MEMIMPIN',     'Crown',             'kuning'),
  ('ACT_MENGAJAR',     'GraduationCap',     'hijau'),
  ('ACT_MENJUAL',      'Megaphone',         'oranye'),
  ('ACT_OPERASIONAL',  'ClipboardList',     'hijau'),
  ('ACT_PROBLEM',      'Puzzle',            'ungu'),
  ('ACT_QC',           'ScanSearch',        'biru'),
  ('ACT_RISET',        'FlaskConical',      'hijau'),
  ('SKL_ADAPTABILITAS','Shuffle',           'kuning'),
  ('SKL_BELAJAR',      'BookOpenCheck',     'hijau'),
  ('SKL_CRITICAL',     'Brain',             'ungu'),
  ('SKL_EMPATI',       'Handshake',         'biru'),
  ('SKL_KEPEMIMPINAN', 'Crown',             'kuning'),
  ('SKL_KEPUTUSAN',    'GitBranch',         'ungu'),
  ('SKL_KETELITIAN',   'ScanEye',           'biru'),
  ('SKL_KOLABORASI',   'Users',             'hijau'),
  ('SKL_KOMUNIKASI',   'MessageCircle',     'biru'),
  ('SKL_KREATIVITAS',  'Lightbulb',         'kuning'),
  ('SKL_LOGIKA',       'Sigma',             'ungu'),
  ('SKL_NEGOSIASI',    'Handshake',         'oranye'),
  ('SKL_NUMERIK',      'Calculator',        'biru'),
  ('SKL_PERENCANAAN',  'CalendarRange',     'hijau'),
  ('SKL_PRESENTASI',   'Presentation',      'oranye'),
  ('SKL_WAKTU',        'Timer',             'kuning')
on conflict (code) do update set icon = excluded.icon, tone = excluded.tone;

-- -------------------------------------------- 2. progres item dalam journey --

-- Satu tabel untuk semua jenis item yang bisa ditandai pengguna di Journey:
-- topik eksplorasi, soft skill, hard skill, tools, dan kegiatan. Statusnya
-- yang dipakai untuk pil "Selesai / Berlangsung / Belum Mulai" di desain.
create table if not exists public.user_journey_items (
  user_id    uuid not null references auth.users(id) on delete cascade,
  career_id  integer not null references public.careers(id) on delete cascade,
  item_kind  text not null,
  item_code  text not null,
  status     text not null default 'BELUM_MULAI',
  updated_at timestamptz not null default now(),
  primary key (user_id, career_id, item_kind, item_code),
  constraint chk_uji_kind check (item_kind in
    ('TOPIK','SOFT_SKILL','HARD_SKILL','TOOL','KEGIATAN')),
  constraint chk_uji_status check (status in
    ('BELUM_MULAI','BERLANGSUNG','SELESAI'))
);

alter table public.user_journey_items enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public'
                 and tablename='user_journey_items' and policyname='user_journey_items_owner') then
    create policy user_journey_items_owner on public.user_journey_items
      for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;
end $$;

-- --------------------------------------------------------- 3. level dan XP --

create or replace function public.xp_pengguna()
returns table (total_xp integer, level smallint, level_name text,
               min_xp integer, next_xp integer, persen smallint)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with t as (
    select coalesce(sum(x.xp), 0)::integer as xp
    from public.xp_ledger x where x.user_id = auth.uid()
  ),
  l as (
    select v.level, v.name_id, v.min_xp, v.next_xp
    from public.xp_levels v, t
    where t.xp >= v.min_xp
    order by v.min_xp desc
    limit 1
  )
  select t.xp, l.level, l.name_id, l.min_xp, l.next_xp,
         case
           when l.next_xp is null then 100
           else greatest(0, least(100,
             round((t.xp - l.min_xp)::numeric * 100 / nullif(l.next_xp - l.min_xp, 0))))
         end::smallint
  from t, l;
$$;

comment on function public.xp_pengguna() is
  'Total XP pengguna beserta level, ambang berikutnya, dan persen menuju level itu.';

-- -------------------------------------------------- 4. profesi yang dipilih --

-- Profesi yang sedang dijalani: roadmap aktif terakhir. Kalau pengguna belum
-- memulai roadmap apa pun, kembalikan NULL supaya layar bisa menampilkan
-- ajakan memilih profesi, bukan kartu kosong.
create or replace function public.profesi_pilihan()
returns integer
language sql stable security definer set search_path to 'public', 'auth' as $$
  select ur.career_id
  from public.user_roadmaps ur
  where ur.user_id = auth.uid() and ur.status in ('AKTIF','JEDA')
  order by ur.started_at desc
  limit 1;
$$;

comment on function public.profesi_pilihan() is
  'ID profesi pada roadmap aktif pengguna, NULL kalau belum ada.';

-- ---------------------------------------------------- 5. tab "Persiapan" ----

-- Tahap dianggap SELESAI kalau sudah dicatat completed_at. Tahap AKTIF adalah
-- tahap pertama yang belum selesai; sisanya TERKUNCI. Tombol "Tampilkan
-- Journey" hanya muncul di tahap aktif, sesuai desain.
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
  prog as (
    select s.code, s.stage_order, s.name_id, s.summary_id,
           coalesce(p.percent, 0)::smallint as persen,
           p.completed_at is not null as selesai
    from public.journey_stages s
    left join public.user_journey_progress p
           on p.stage_code = s.code
          and p.user_id = auth.uid()
          and p.career_id = (select cid from pilih)
  ),
  aktif as (
    select min(stage_order) as urutan from prog where not selesai
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
                         when g.stage_order = a.urutan then 'AKTIF'
                         else 'TERKUNCI' end,
       'cta',       g.stage_order = a.urutan
     ) order by g.stage_order)
     from prog g, aktif a);
$$;

comment on function public.roadmap_state() is
  'Kartu profesi, level XP, dan lima tahap persiapan untuk tab Persiapan.';

-- --------------------------------------------- 6. tab "Jalur Pendidikan" ----

create or replace function public.roadmap_jalur(p_career_id integer)
returns table (path_id integer, kind_code text, kind_label text, level_code text,
               title_id text, tagline_id text, years_min smallint, years_max smallint,
               cta_label_id text, table_label_id text, display_order smallint,
               dipilih boolean, keunggulan jsonb, langkah jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with posisi as (select * from public.posisi_studi()),
  terpilih as (
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
                   'urutan',  s.step_order,
                   'judul',   s.title_id,
                   'catatan', s.note_id,
                   'jenis',   s.step_kind,
                   'status',  public.status_langkah_jalur(
                                s.step_rank, o.rank_tercapai, o.rank_sedang)
                 ) order by s.step_order), '[]'::jsonb)
            from public.career_education_path_steps s, posisi o
           where s.path_id = p.id)
  from public.career_education_paths p
  join public.education_path_kinds k on k.code = p.kind_code
  where p.career_id = p_career_id
  order by p.display_order;
$$;

comment on function public.roadmap_jalur(integer) is
  'Pilihan jalur pendidikan satu profesi, lengkap dengan status tiap langkah.';

create or replace function public.pilih_jalur(p_career_id integer, p_path_id integer)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'pilih_jalur: tidak ada pengguna terautentikasi';
  end if;
  if not exists (select 1 from public.career_education_paths
                  where id = p_path_id and career_id = p_career_id) then
    raise exception 'pilih_jalur: jalur % bukan milik profesi %', p_path_id, p_career_id;
  end if;
  insert into public.user_education_path (user_id, career_id, path_id)
  values (v_user, p_career_id, p_path_id)
  on conflict (user_id, career_id)
  do update set path_id = excluded.path_id, chosen_at = now();
end $$;

comment on function public.pilih_jalur(integer, integer) is
  'Simpan jalur pendidikan yang dipilih pengguna untuk satu profesi.';

-- Tombol "Ubah jalur lain" mengosongkan pilihan supaya kartu pilihan muncul
-- lagi, bukan menghapus riwayat apa pun.
create or replace function public.batal_jalur(p_career_id integer)
returns void
language sql security definer set search_path to 'public', 'auth' as $$
  delete from public.user_education_path
   where user_id = auth.uid() and career_id = p_career_id;
$$;

comment on function public.batal_jalur(integer) is
  'Batalkan pilihan jalur pendidikan supaya pengguna bisa memilih ulang.';

-- --------------------------------------------------------- 7. layar Journey --

-- Tiga baris checklist yang muncul di bottom sheet detail soft skill. Bentuknya
-- sama untuk semua soft skill, hanya namanya yang berganti — jadi dirakit di
-- sini, bukan disimpan 28 kali di tabel.
create or replace function public.soft_skill_quest(p_nama text)
returns jsonb
language sql immutable as $$
  select jsonb_build_array(
    'Memahami apa itu ' || lower(p_nama),
    'Memahami bagaimana ' || lower(p_nama) || ' digunakan oleh berbagai profesi',
    'Memahami masalah atau kebutuhan yang dapat dipenuhi melalui ' || lower(p_nama));
$$;

comment on function public.soft_skill_quest(text) is
  'Tiga hasil belajar dari tiga quest satu soft skill.';

create or replace function public.journey_stage(
  p_career_id integer, p_stage_code text default null)
returns table (stage_code text, stage_order smallint, nama text, hero text,
               ringkasan text, learn_intro text, content_kind text,
               persen smallint, konten jsonb, hasil jsonb)
language sql stable security definer set search_path to 'public', 'auth' as $$
  with prof as (select c.id, c.career_name from public.careers c where c.id = p_career_id),
  progres as (
    select p.stage_code, p.percent, p.completed_at
    from public.user_journey_progress p
    where p.user_id = auth.uid() and p.career_id = p_career_id
  ),
  -- Tanpa p_stage_code, ambil tahap aktif: tahap pertama yang belum selesai.
  pilih as (
    select s.*
    from public.journey_stages s
    left join progres g on g.stage_code = s.code
    where case when p_stage_code is not null then s.code = p_stage_code
               else g.completed_at is null end
    order by s.stage_order
    limit 1
  ),
  item as (
    select coalesce(jsonb_object_agg(i.item_kind || '|' || i.item_code, i.status), '{}'::jsonb) as peta
    from public.user_journey_items i
    where i.user_id = auth.uid() and i.career_id = p_career_id
  )
  select
    p.code, p.stage_order, p.name_id,
    public.isi_profesi(p.hero_id, f.career_name),
    p.summary_id,
    p.learn_intro_id,
    p.content_kind,
    coalesce((select percent from progres where stage_code = p.code), 0)::smallint,
    case p.content_kind

      -- Tahap 1: lima topik tetap, isinya disesuaikan nama profesi.
      when 'TOPIK' then
        (select coalesce(jsonb_agg(jsonb_build_object(
           'kode',   'TOPIK_' || t.item_order,
           'ikon',   t.icon,
           'judul',  t.title_id,
           'isi',    public.isi_profesi(t.body_id, f.career_name),
           'status', coalesce(item.peta ->> ('TOPIK|TOPIK_' || t.item_order), 'BELUM_MULAI')
         ) order by t.item_order), '[]'::jsonb)
         from public.journey_stage_items t where t.stage_code = p.code)

      -- Tahap 2: soft skill dominan profesi dari Career DNA.
      -- Empat teratas saja: kartunya besar, dan soft skill dominan profesi
      -- biasanya sembilan -- terlalu panjang untuk satu layar.
      when 'SOFT_SKILL' then
        (select coalesce(jsonb_agg(jsonb_build_object(
           'kode',      t.code,
           'ikon',      coalesce(t.icon, 'Sparkles'),
           'tone',      coalesce(t.tone, 'ungu'),
           'judul',     t.name_id,
           'isi',       t.description_id,
           'n_quest',   3,
           'quest',     public.soft_skill_quest(t.name_id),
           'status',    coalesce(item.peta ->> ('SOFT_SKILL|' || t.code), 'BELUM_MULAI')
         ) order by t.urutan), '[]'::jsonb)
         from (
           select a.code, a.name_id, a.description_id, v.icon, v.tone,
                  row_number() over (order by d.rank_in_layer, a.code) as urutan
           from public.careers c
           join public.onet_dna d on d.soc_code = c.soc_code and d.is_dominant
           join public.dna_attributes a on a.code = d.attribute_code
           left join public.dna_attribute_visual v on v.code = a.code
           where c.id = p_career_id and a.layer_code in ('ACTIVITY','SKILL')
           order by d.rank_in_layer, a.code
           limit 4
         ) t)

      -- Tahap 3: dua tab, hard skill dan tools.
      when 'SKILL_TOOLS' then
        jsonb_build_object(
          'hard_skill',
            (select coalesce(jsonb_agg(jsonb_build_object(
               'kode',   h.skill_code,
               'judul',  h.nama,
               'isi',    h.deskripsi,
               'status', coalesce(item.peta ->> ('HARD_SKILL|' || h.skill_code), 'BELUM_MULAI')
             ) order by h.display_order), '[]'::jsonb)
             from public.career_hard_skill_view h where h.career_id = p_career_id),
          'tools',
            (select coalesce(jsonb_agg(jsonb_build_object(
               'kode',   o.tool_code,
               'judul',  coalesce(o.contoh_produk, o.nama),
               'isi',    o.deskripsi,
               'fase',   o.fase_code,
               'status', coalesce(item.peta ->> ('TOOL|' || o.tool_code), 'BELUM_MULAI')
             ) order by o.fase_order, o.display_order), '[]'::jsonb)
             from public.career_tool_view o where o.career_id = p_career_id))

      -- Tahap 4: tiga kegiatan tetap.
      when 'KEGIATAN' then
        (select coalesce(jsonb_agg(jsonb_build_object(
           'kode',   'KEGIATAN_' || t.item_order,
           'ikon',   t.icon,
           'judul',  t.title_id,
           'isi',    public.isi_profesi(t.body_id, f.career_name),
           'status', coalesce(item.peta ->> ('KEGIATAN|KEGIATAN_' || t.item_order), 'BELUM_MULAI')
         ) order by t.item_order), '[]'::jsonb)
         from public.journey_stage_items t where t.stage_code = p.code)

      else '[]'::jsonb
    end,
    (select coalesce(jsonb_agg(public.isi_profesi(o.text_id, f.career_name)
                               order by o.item_order), '[]'::jsonb)
       from public.journey_outcomes o where o.stage_code = p.code)
  from pilih p, prof f, item;
$$;

comment on function public.journey_stage(integer, text) is
  'Isi satu tahap Journey: hero, penjelasan, konten sesuai jenis tahap, dan hasil.';

-- Tandai satu item Journey. Dipakai tombol centang di layar dan nanti oleh
-- mesin quest ketika sebuah quest diselesaikan.
create or replace function public.set_journey_item(
  p_career_id integer, p_item_kind text, p_item_code text, p_status text)
returns void
language plpgsql security definer set search_path to 'public', 'auth' as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'set_journey_item: tidak ada pengguna terautentikasi';
  end if;
  insert into public.user_journey_items (user_id, career_id, item_kind, item_code, status)
  values (v_user, p_career_id, p_item_kind, p_item_code, p_status)
  on conflict (user_id, career_id, item_kind, item_code)
  do update set status = excluded.status, updated_at = now();
end $$;

comment on function public.set_journey_item(integer, text, text, text) is
  'Simpan status satu item Journey (topik, soft skill, hard skill, tools, kegiatan).';

-- ----------------------------------------------------------- 8. penjaga ----

do $$
declare
  n int; v_cid int;
begin
  select count(*) into n from public.dna_attribute_visual;
  if n <> 28 then
    raise exception '0035: dna_attribute_visual harus 28 baris, dapat %', n;
  end if;

  -- Tiap atribut DNA lapis ACTIVITY dan SKILL wajib punya ikon, karena kartu
  -- soft skill tahap Pondasi mengambil dari sana.
  select count(*) into n from public.dna_attributes a
   where a.layer_code in ('ACTIVITY','SKILL')
     and not exists (select 1 from public.dna_attribute_visual v where v.code = a.code);
  if n > 0 then
    raise exception '0035: % atribut soft skill belum punya ikon', n;
  end if;

  -- Fungsi harus benar-benar bisa dipanggil.
  select id into v_cid from public.careers where is_active order by id limit 1;
  perform public.roadmap_jalur(v_cid);
  perform public.journey_stage(v_cid, 'EKSPLORASI');
  perform public.journey_stage(v_cid, 'PONDASI');
  perform public.journey_stage(v_cid, 'KEAHLIAN');
  perform public.journey_stage(v_cid, 'PENGALAMAN');
  perform public.journey_stage(v_cid, 'BERKARIER');

  raise notice '0035: RPC roadmap dan journey siap';
end $$;

commit;
