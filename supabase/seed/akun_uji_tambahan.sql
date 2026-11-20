-- ===========================================================================
-- akun_uji_tambahan.sql — dua akun uji baru, sudah terverifikasi
--
-- BUKAN migrasi. Jalankan manual di Supabase Dashboard -> SQL Editor.
-- Aman dijalankan ulang: akun yang sudah ada tidak dibuat dua kali.
--
-- Sebelum menjalankan: ganti nilai v_sandi di bawah. Skrip menolak berjalan
-- selama nilainya masih bawaan, supaya sandi tidak tertulis di repo.
--
-- Akun yang dibuat, keadaan baru daftar (belum onboarding, belum Career DNA,
-- belum memilih profesi), bisa langsung login tanpa verifikasi email:
--   navika.baru6@zdann.me   Penguji Baru 6
--   navika.baru7@zdann.me   Penguji Baru 7
-- ===========================================================================

begin;

-- Sama dengan akun_uji.sql. Kolom token GoTrue wajib string kosong, bukan
-- NULL: kalau NULL, login gagal dengan "converting NULL to string is unsupported".
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

do $$
declare
  v_sandi constant text := 'GANTI_DENGAN_SANDI_UJI';   -- <<< ganti dulu
  i integer;
begin
  if v_sandi = 'GANTI_DENGAN_SANDI_UJI' or length(v_sandi) < 8 then
    raise exception 'akun_uji_tambahan: ganti v_sandi dulu (minimal 8 karakter).';
  end if;

  for i in 6..7 loop
    perform pg_temp.buat_akun(format('navika.baru%s@zdann.me', i), format('Penguji Baru %s', i), v_sandi);
  end loop;

  if (select count(*) from auth.users
       where email in ('navika.baru6@zdann.me', 'navika.baru7@zdann.me')
         and email_confirmed_at is not null) <> 2 then
    raise exception 'akun_uji_tambahan: akun belum terbentuk atau belum terverifikasi';
  end if;
  raise notice 'akun_uji_tambahan: navika.baru6 dan navika.baru7 siap dipakai';
end $$;

commit;
