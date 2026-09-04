-- ============================================================================
-- 0023_nama_pengguna.sql
--
-- Membuat sapaan di Explore memakai nama pengguna, bukan "Halo, Sobat".
--
-- Akar masalahnya bukan di tampilan: NAMA PENGGUNA TIDAK PERNAH DISIMPAN.
-- Kolom profiles.full_name ada sejak 0005, tapi tidak ada satu layar pun yang
-- mengisinya — /daftar hanya meminta email dan sandi, dan saveEducation() di
-- onboarding cuma menulis data pendidikan. Jadi kolomnya kosong untuk semua
-- pengguna, dan layar jatuh ke kata sapaan umum.
--
-- File ini menambal dari sisi baca dengan rantai cadangan:
--
--   1. profiles.full_name                    kalau nanti ada layar yang mengisinya
--   2. metadata akun (full_name lalu name)   terisi sendiri kalau masuk lewat Google
--   3. bagian depan alamat email             hanya kalau bentuknya masih masuk akal
--   4. NULL                                  tampilan yang memutuskan sapaan umumnya
--
-- Langkah 3 sengaja pemilih: "zaidan@..." jadi "Zaidan", tapi
-- "zaidanzhafifsatrianto@..." dibiarkan kosong — "Halo, Zaidanzhafifsatrianto"
-- lebih buruk daripada "Halo, Sobat".
--
-- Ini tambalan, bukan penyelesaian. Yang benar adalah menanyakan namanya di
-- layar daftar atau onboarding lalu menyimpannya ke profiles.full_name; begitu
-- itu ada, langkah 1 langsung yang dipakai tanpa mengubah apa pun di sini.
--
-- Jalankan setelah 0022. Aman diulang.
-- ============================================================================

begin;

/**
 * Menebak nama panggilan dari alamat email — hanya kalau tebakannya layak.
 *
 * Mengembalikan NULL untuk bagian depan yang panjang tanpa pemisah, karena
 * hasil kapitalisasinya terbaca seperti kesalahan, bukan seperti nama.
 */
create or replace function public.nama_dari_email(p_email text)
returns text language sql immutable
as $$
  with lokal as (
    select btrim(split_part(coalesce(p_email, ''), '@', 1)) as v
  ),
  potong as (
    -- Angka di ujung ("zaidan99") dan bagian yang seluruhnya angka dibuang.
    select array_remove(array(
      select initcap(w)
      from unnest(regexp_split_to_array(regexp_replace(v, '[0-9]+$', ''), '[._+-]+')) as w
      where length(w) >= 2 and w !~ '^[0-9]+$'
    ), null) as kata, v
    from lokal
  )
  select case
    when array_length(kata, 1) is null then null
    -- Ada pemisah: hampir pasti "nama.belakang", aman disusun ulang.
    when array_length(kata, 1) > 1 then array_to_string(kata[1:3], ' ')
    -- Satu kata: hanya dipakai kalau pendek seperti nama panggilan.
    when length(kata[1]) between 2 and 12 then kata[1]
    else null
  end
  from potong;
$$;

comment on function public.nama_dari_email(text) is
  'Tebakan nama panggilan dari alamat email. Sengaja mengembalikan NULL kalau tebakannya tidak meyakinkan — tampilan yang memutuskan sapaan penggantinya.';

-- ---------------------------------------------------------------------------
-- explore_state dengan rantai cadangan nama
--
-- SECURITY DEFINER karena perlu membaca metadata akun di auth.users, yang tidak
-- boleh dibaca langsung oleh peran authenticated. Setiap query di dalamnya
-- disaring auth.uid(), jadi fungsi ini tidak bisa mengembalikan data orang lain
-- betapa pun ia dipanggil.
-- ---------------------------------------------------------------------------
create or replace function public.explore_state()
returns table (
  full_name          text,
  has_career         boolean,
  has_dna            boolean,
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
  dna as (select count(*) as n from user_dna ud, me where ud.user_id = me.uid),
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
    coalesce((select n from dna), 0) > 0,
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

-- ============================================================================
-- Verifikasi:
--   select nama_dari_email('zaidan@zdann.me');            -- Zaidan
--   select nama_dari_email('zaidan.zhafiz@gmail.com');    -- Zaidan Zhafiz
--   select nama_dari_email('zaidanzhafifsatrianto@x.com');-- NULL (terlalu panjang)
--   select nama_dari_email('admin123@x.com');             -- Admin
-- ============================================================================
