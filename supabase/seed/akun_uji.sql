-- ===========================================================================
-- akun_uji.sql — delapan akun untuk pengujian tim
--
-- BUKAN migrasi. Jalankan manual sekali di Supabase Dashboard -> SQL Editor.
-- Aman dijalankan ulang: akun yang sudah ada dipakai lagi, quest yang sudah
-- selesai dilewati.
--
-- Sebelum menjalankan: ganti nilai v_sandi di blok paling bawah. Skrip ini
-- menolak berjalan selama nilainya masih bawaan, supaya tidak ada akun yang
-- tercipta dengan sandi yang tertulis di repo.
--
-- Akun yang dibuat (semua sudah terverifikasi, bisa langsung login):
--
--   navika.baru1@zdann.me .. navika.baru5@zdann.me
--       Baru daftar. Belum onboarding, belum Career DNA, belum memilih
--       profesi — penguji mengalami alurnya dari awal.
--
--   navika.keahlian@zdann.me
--       Tahap Eksplorasi, Bangun Pondasi, dan Kembangkan Keahlian tuntas.
--       Eksplorasi ikut dituntaskan karena tahap Pondasi tidak bisa terbuka
--       tanpanya.
--
--   navika.pengalaman@zdann.me
--       Tahap 1 sampai 4 tuntas, sampai Asah Pengalaman.
--
--   navika.lengkap@zdann.me
--       Kelima tahap tuntas dan kedua belas badge terbuka.
--
-- Semua progres dikerjakan lewat RPC yang sama dengan aplikasi (ambil_quest,
-- selesaikan_quest), bukan ditulis langsung ke tabel. Jadi XP, badge, persen
-- tahap, dan notifikasinya persis seperti kalau penguji mengerjakannya sendiri,
-- dan aturan buka-kunci ikut teruji.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- Buat atau ambil akun, sudah terverifikasi
--
-- Kolom token GoTrue wajib string kosong, bukan NULL: kalau NULL, login gagal
-- dengan "converting NULL to string is unsupported".
-- ---------------------------------------------------------------------------
create or replace function pg_temp.buat_akun(p_email text, p_nama text, p_sandi text)
returns uuid language plpgsql as $$
declare v_id uuid;
begin
  select id into v_id from auth.users where email = p_email;
  if v_id is not null then
    return v_id;
  end if;

  v_id := gen_random_uuid();

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token)
  values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
    p_email, extensions.crypt(p_sandi, extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', p_nama), now(), now(),
    '', '', '', '');

  insert into auth.identities (user_id, provider_id, identity_data, provider,
                               last_sign_in_at, created_at, updated_at)
  values (v_id, v_id::text,
          jsonb_build_object('sub', v_id::text, 'email', p_email, 'email_verified', true),
          'email', now(), now(), now());

  -- Baris profil dibuat trigger handle_new_user; jaga-jaga kalau belum.
  insert into public.profiles (user_id) values (v_id) on conflict do nothing;
  return v_id;
end $$;

-- Jalankan RPC berikutnya atas nama pengguna ini. auth.uid() Supabase membaca
-- salah satu dari dua pengaturan ini, jadi keduanya diisi.
create or replace function pg_temp.sebagai(p_uid uuid)
returns void language sql as $$
  select set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('request.jwt.claims', jsonb_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
$$;

-- Profil lulusan S1: memenuhi syarat waktu magang dan syarat jenjang untuk
-- melamar kerja, jadi semua quest Asah Pengalaman dan Siap Berkarier terbuka.
create or replace function pg_temp.lulusan_s1(p_uid uuid, p_nama text, p_career_id integer)
returns void language plpgsql as $$
declare v_prodi integer;
begin
  -- Program studi yang memang mengarah ke profesi itu, supaya baris
  -- "Relevan dengan Program Studi" di Explore berisi.
  select ec.source_id into v_prodi
  from public.education_career ec
  where ec.career_id = p_career_id and ec.source_kind = 'PRODI'
  order by ec.relevance desc, ec.display_order
  limit 1;

  update public.profiles set
    full_name = p_nama,
    education_level_code = 'S1',
    graduation_status = 'sudah_lulus',
    grade_level = null, semester = null, is_final_semester = false,
    smk_concentration_id = null,
    study_program_id = v_prodi,
    onboarding_completed_at = coalesce(onboarding_completed_at, now()),
    updated_at = now()
  where user_id = p_uid;
end $$;

-- Career DNA terisi dengan atribut dominan profesi tujuannya, sebanyak jatah
-- tiap lapisan, lalu ditandai selesai. Skor kecocokannya karena itu tinggi.
create or replace function pg_temp.isi_dna(p_uid uuid, p_career_id integer)
returns void language plpgsql as $$
declare l record;
begin
  delete from public.user_dna where user_id = p_uid;

  for l in select code, selection_count from public.dna_layers loop
    insert into public.user_dna (user_id, attribute_code)
    select p_uid, x.code
    from (
      select a.code,
             -- atribut dominan profesi dulu, sisanya pengisi kalau kurang
             row_number() over (order by (d.attribute_code is null), d.rank_in_layer, a.display_order) as n
      from public.dna_attributes a
      left join public.careers c on c.id = p_career_id
      left join public.onet_dna d
             on d.attribute_code = a.code and d.soc_code = c.soc_code and d.is_dominant
      where a.layer_code = l.code
    ) x
    where x.n <= l.selection_count
    on conflict do nothing;
  end loop;

  insert into public.user_dna_progress (user_id, current_step, completed_at, updated_at)
  values (p_uid, 6, now(), now())
  on conflict (user_id) do update set current_step = 6, completed_at = now(), updated_at = now();
end $$;

-- Kerjakan semua quest berjenis tertentu sampai habis, dengan urutan dan aturan
-- buka-kunci yang sama dengan aplikasi. Diulang sampai tidak ada lagi yang bisa
-- dikerjakan, karena tiap quest yang selesai bisa membuka quest berikutnya.
create or replace function pg_temp.kerjakan(p_uid uuid, p_career_id integer, p_jenis text[])
returns integer language plpgsql as $$
declare
  q record;
  v_n integer := 0;
begin
  perform pg_temp.sebagai(p_uid);
  loop
    select s.quest_key, s.status, k.mode into q
    from public.quest_status(p_career_id) s
    join public.quest_group_kinds k on k.code = s.group_kind
    where s.group_kind = any (p_jenis)
      and s.status <> 'SELESAI'
      and (s.bisa or s.status = 'DIAMBIL')
    order by k.kind_order, s.group_order, s.item_order
    limit 1;

    exit when not found;

    if q.mode = 'AMBIL' and q.status = 'BELUM' then
      perform public.ambil_quest(q.quest_key);
    end if;
    perform * from public.selesaikan_quest(q.quest_key);
    v_n := v_n + 1;
  end loop;
  return v_n;
end $$;

-- Pengguna berprogres lengkap: profil, Career DNA, profesi, lalu quest.
create or replace function pg_temp.siapkan(
  p_email text, p_nama text, p_sandi text, p_profesi text, p_jenis text[])
returns text language plpgsql as $$
declare
  v_uid uuid;
  v_cid integer;
  v_n integer;
  v_xp integer;
  v_badge integer;
begin
  v_uid := pg_temp.buat_akun(p_email, p_nama, p_sandi);

  select id into v_cid from public.careers
   where is_active and career_name = p_profesi and min_education_rank <= 6;
  if v_cid is null then
    -- Nama profesi berubah di katalog: pakai profesi aktif pertama yang bisa
    -- dicapai lulusan S1, daripada menggagalkan seluruh skrip.
    select id into v_cid from public.careers
     where is_active and min_education_rank <= 6 order by id limit 1;
  end if;

  perform pg_temp.lulusan_s1(v_uid, p_nama, v_cid);
  perform pg_temp.isi_dna(v_uid, v_cid);

  perform pg_temp.sebagai(v_uid);
  perform public.start_roadmap(v_cid);

  v_n := pg_temp.kerjakan(v_uid, v_cid, p_jenis);

  -- Bagikan hadiah yang belum sempat terbagi (mis. XP onboarding), lalu catat.
  perform public.sinkron_pencapaian();
  perform public.sinkron_notifikasi();

  select coalesce(sum(xp), 0) into v_xp from public.xp_ledger where user_id = v_uid;
  select count(*) into v_badge from public.user_achievements where user_id = v_uid;

  return format('%s — %s, %s quest baru selesai, %s XP, %s badge',
                p_email, (select career_name from public.careers where id = v_cid), v_n, v_xp, v_badge);
end $$;

-- ---------------------------------------------------------------------------
-- Jalankan
-- ---------------------------------------------------------------------------
do $$
declare
  v_sandi constant text := 'GANTI_DENGAN_SANDI_UJI';   -- <<< ganti dulu
  i integer;
begin
  if v_sandi = 'GANTI_DENGAN_SANDI_UJI' or length(v_sandi) < 8 then
    raise exception 'akun_uji: ganti v_sandi dulu (minimal 8 karakter, huruf dan angka).';
  end if;

  -- 5 pengguna baru, sudah terverifikasi, belum onboarding
  for i in 1..5 loop
    perform pg_temp.buat_akun(format('navika.baru%s@zdann.me', i), format('Penguji Baru %s', i), v_sandi);
  end loop;
  raise notice 'akun_uji: 5 akun baru siap (navika.baru1..5@zdann.me)';

  -- Tahap Pondasi dan Keahlian tuntas (Eksplorasi ikut, karena syarat buka)
  raise notice 'akun_uji: %', pg_temp.siapkan(
    'navika.keahlian@zdann.me', 'Penguji Keahlian', v_sandi, 'Perawat',
    array['EKSPLORASI','SOFT_SKILL','HARD_SKILL','TOOL']);

  -- Tahap 1 sampai Asah Pengalaman tuntas
  raise notice 'akun_uji: %', pg_temp.siapkan(
    'navika.pengalaman@zdann.me', 'Penguji Pengalaman', v_sandi, 'Frontend Developer',
    array['EKSPLORASI','SOFT_SKILL','HARD_SKILL','TOOL','PENGALAMAN']);

  -- Semua tahap tuntas, semua badge terbuka
  raise notice 'akun_uji: %', pg_temp.siapkan(
    'navika.lengkap@zdann.me', 'Penguji Lengkap', v_sandi, 'Akuntan / Auditor',
    array['EKSPLORASI','SOFT_SKILL','HARD_SKILL','TOOL','PENGALAMAN','BERKARIER']);
end $$;

-- ---------------------------------------------------------------------------
-- Penjaga: pastikan hasilnya sesuai yang diminta, atau batalkan semuanya
-- ---------------------------------------------------------------------------
do $$
declare
  v_uid uuid;
  v_tahap text;
  n integer;
begin
  -- navika.keahlian: tahap Pondasi dan Keahlian selesai
  select id into v_uid from auth.users where email = 'navika.keahlian@zdann.me';
  select string_agg(stage_code, ', ') into v_tahap
    from public.user_journey_progress
   where user_id = v_uid and completed_at is not null;
  if v_tahap not like '%PONDASI%' or v_tahap not like '%KEAHLIAN%' then
    raise exception 'akun_uji: navika.keahlian belum menuntaskan Pondasi dan Keahlian (selesai: %)', v_tahap;
  end if;

  -- navika.pengalaman: tahap Asah Pengalaman selesai
  select id into v_uid from auth.users where email = 'navika.pengalaman@zdann.me';
  select count(*) into n from public.user_journey_progress
   where user_id = v_uid and stage_code = 'PENGALAMAN' and completed_at is not null;
  if n <> 1 then
    raise exception 'akun_uji: navika.pengalaman belum menuntaskan Asah Pengalaman';
  end if;

  -- navika.lengkap: kelima tahap dan semua badge
  select id into v_uid from auth.users where email = 'navika.lengkap@zdann.me';
  select count(*) into n from public.user_journey_progress
   where user_id = v_uid and completed_at is not null;
  if n <> 5 then
    raise exception 'akun_uji: navika.lengkap baru menuntaskan % dari 5 tahap', n;
  end if;
  select count(*) into n from public.achievements a
   where not exists (select 1 from public.user_achievements u
                      where u.user_id = v_uid and u.code = a.code);
  if n > 0 then
    raise exception 'akun_uji: navika.lengkap masih punya % badge terkunci', n;
  end if;

  raise notice 'akun_uji: semua akun sesuai permintaan';
end $$;

commit;
