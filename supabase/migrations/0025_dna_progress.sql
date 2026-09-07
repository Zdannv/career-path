-- ============================================================================
-- 0025_dna_progress.sql
--
-- Tempat menyimpan progres Career DNA, dan pintu masuknya dari frontend.
--
-- Layar Discovery punya tombol "Simpan" di setiap langkah — "Progres Kamu akan
-- otomatis tersimpan, kamu dapat melanjutkannya di lain waktu." Artinya DNA
-- bisa berada dalam keadaan setengah terisi, dan itu memunculkan satu
-- kekeliruan yang harus diperbaiki di sini:
--
--   explore_state() sebelum ini menganggap has_dna = ada baris di user_dna.
--   Dengan simpan-sebagian, user yang baru mengisi 2 dari 5 kategori akan
--   membuat layar Explore berpindah ke tampilan ber-DNA dan menghitung skor
--   kecocokan dari data yang belum lengkap — angka yang salah, tampil percaya
--   diri. Sesudah ini has_dna berarti SELESAI, dan progres sebagian punya
--   penandanya sendiri supaya banner bisa berbunyi "Career DNA (3/6)".
--
-- Semua fungsi memakai auth.uid() dan tidak menerima user id, sama seperti
-- 0020. Batas maksimal pilihan divalidasi di sini, bukan hanya di layar:
-- tombol yang dinonaktifkan bukan aturan, hanya kenyamanan.
--
-- Jalankan setelah 0024. Aman diulang.
-- ============================================================================

begin;

create table if not exists public.user_dna_progress (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  current_step smallint not null default 1,
  completed_at timestamptz,
  updated_at   timestamptz not null default now(),
  constraint chk_dna_step check (current_step between 1 and 6)
);

comment on table public.user_dna_progress is
  'Sampai langkah ke berapa Career DNA seseorang terisi, dan kapan ia diselesaikan. Pilihan atributnya sendiri tetap di user_dna.';
comment on column public.user_dna_progress.completed_at is
  'NULL berarti masih setengah jalan. Kolom inilah yang menentukan apakah skor kecocokan boleh dihitung — bukan ada-tidaknya baris di user_dna.';

select public.apply_owner_rls('user_dna_progress');

-- ---------------------------------------------------------------------------
-- Pilihan untuk seluruh enam langkah, satu panggilan
--
-- Layar butuh semuanya sekaligus: langkah aktif menampilkan daftarnya, sidebar
-- menampilkan judul dan pertanyaan tiap langkah, dan layar Review menampilkan
-- nama atribut yang dipilih. Mengambilnya per langkah berarti lima kali
-- perjalanan jaringan untuk data yang tidak pernah berubah.
-- ---------------------------------------------------------------------------
create or replace function public.dna_options()
returns table (
  layer_code      text,
  layer_order     smallint,
  layer_name      text,
  layer_question  text,
  max_pick        smallint,
  attribute_code  text,
  attribute_order smallint,
  attribute_name  text,
  attribute_hint  text
)
language sql stable
set search_path = public
as $$
  select l.code, l.display_order, l.name_id, l.question_id, l.selection_count,
         a.code, a.display_order, a.name_id, a.description_id
  from dna_layers l
  join dna_attributes a on a.layer_code = l.code and a.is_active
  order by l.display_order, a.display_order;
$$;

-- ---------------------------------------------------------------------------
-- Progres dan pilihan pengguna saat ini
-- ---------------------------------------------------------------------------
create or replace function public.dna_progress()
returns table (
  current_step smallint,
  completed_at timestamptz,
  picks        jsonb
)
language sql stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  p as (select pr.current_step, pr.completed_at from user_dna_progress pr, me where pr.user_id = me.uid),
  pilihan as (
    select a.layer_code, jsonb_agg(ud.attribute_code order by a.display_order) as kode
    from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code, me
    where ud.user_id = me.uid
    group by a.layer_code
  )
  select coalesce((select current_step from p), 1)::smallint,
         (select completed_at from p),
         coalesce((select jsonb_object_agg(layer_code, kode) from pilihan), '{}'::jsonb);
$$;

-- ---------------------------------------------------------------------------
-- Simpan satu langkah
--
-- Menggantikan seluruh pilihan pada kategori itu, bukan menambah: kalau user
-- mundur ke langkah 2 dan mengganti pilihannya, yang lama harus hilang.
-- ---------------------------------------------------------------------------
create or replace function public.save_dna_step(
  p_layer_code text,
  p_codes      text[],
  p_next_step  smallint default null
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user  uuid := auth.uid();
  v_maks  smallint;
  v_asing text;
begin
  if v_user is null then
    raise exception 'save_dna_step: tidak ada pengguna terautentikasi';
  end if;

  select selection_count into v_maks from dna_layers where code = p_layer_code;
  if v_maks is null then
    raise exception 'save_dna_step: kategori DNA "%" tidak dikenal', p_layer_code;
  end if;

  if coalesce(array_length(p_codes, 1), 0) > v_maks then
    raise exception 'save_dna_step: % pilihan untuk % melebihi batas %',
      array_length(p_codes, 1), p_layer_code, v_maks;
  end if;

  -- Atribut yang dikirim harus benar-benar milik kategori itu. Tanpa ini,
  -- frontend yang keliru bisa menaruh atribut Keahlian di langkah Aktivitas
  -- dan skornya jadi tidak masuk akal tanpa ada error di mana pun.
  select string_agg(k, ', ') into v_asing
  from unnest(coalesce(p_codes, array[]::text[])) as k
  where not exists (
    select 1 from dna_attributes a
    where a.code = k and a.layer_code = p_layer_code and a.is_active
  );
  if v_asing is not null then
    raise exception 'save_dna_step: atribut % bukan bagian dari kategori %', v_asing, p_layer_code;
  end if;

  delete from user_dna ud
  using dna_attributes a
  where ud.user_id = v_user
    and a.code = ud.attribute_code
    and a.layer_code = p_layer_code;

  if coalesce(array_length(p_codes, 1), 0) > 0 then
    insert into user_dna (user_id, attribute_code)
    select v_user, k from unnest(p_codes) as k
    on conflict do nothing;
  end if;

  insert into user_dna_progress (user_id, current_step, updated_at)
  values (v_user, coalesce(p_next_step, 1), now())
  on conflict (user_id) do update set
    -- Progres hanya boleh maju. Kalau user mundur untuk mengubah langkah 2,
    -- langkah tertinggi yang pernah ia capai tidak boleh ikut turun.
    current_step = greatest(user_dna_progress.current_step, coalesce(p_next_step, user_dna_progress.current_step)),
    updated_at   = now();
end $$;

comment on function public.save_dna_step(text, text[], smallint) is
  'Menyimpan pilihan satu kategori DNA milik pengguna yang sedang masuk. Batas maksimal dan keanggotaan atribut divalidasi di sini, bukan hanya di layar.';

-- ---------------------------------------------------------------------------
-- Tandai selesai
--
-- Menolak kalau ada kategori yang belum terisi. Skor kecocokan memberi
-- similarity 0 pada kategori kosong, jadi DNA yang bolong menghasilkan angka
-- rendah yang terlihat seperti hasil sungguhan.
-- ---------------------------------------------------------------------------
create or replace function public.complete_dna()
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user  uuid := auth.uid();
  v_belum text;
begin
  if v_user is null then
    raise exception 'complete_dna: tidak ada pengguna terautentikasi';
  end if;

  select string_agg(l.name_id, ', ' order by l.display_order) into v_belum
  from dna_layers l
  where not exists (
    select 1 from user_dna ud
    join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = v_user and a.layer_code = l.code
  );
  if v_belum is not null then
    raise exception 'complete_dna: kategori berikut belum diisi: %', v_belum;
  end if;

  insert into user_dna_progress (user_id, current_step, completed_at, updated_at)
  values (v_user, 6, now(), now())
  on conflict (user_id) do update set
    current_step = 6, completed_at = now(), updated_at = now();
end $$;

-- ---------------------------------------------------------------------------
-- explore_state: has_dna kini berarti SELESAI
--
-- Dijatuhkan dulu karena bentuk balikannya bertambah dua kolom, dan Postgres
-- tidak mengizinkan CREATE OR REPLACE mengubah itu. Tidak ada data yang hilang:
-- fungsi ini hanya membaca.
-- ---------------------------------------------------------------------------
drop function if exists public.explore_state();

create function public.explore_state()
returns table (
  full_name          text,
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
    select p.full_name, p.study_program_id, p.smk_concentration_id
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
    (select count(*) from rm) > 0,
    (select completed_at from dna) is not null,
    coalesce((select current_step from dna), 1)::smallint,
    -- "Sudah mulai" ditandai adanya pilihan tersimpan, bukan adanya baris
    -- progres: baris progres juga terbentuk saat user menyimpan nol pilihan.
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

commit;
