-- ===========================================================================
-- reset_akun.sql — mengembalikan akun ke keadaan seperti baru daftar
--
-- BUKAN migrasi. Jalankan manual di Supabase Dashboard -> SQL Editor.
-- TIDAK BISA DIBATALKAN setelah blok 2 di-commit: seluruh progres akun sasaran
-- (Career DNA, profesi pilihan, roadmap, jalur pendidikan, quest, XP, badge,
-- notifikasi, dan isian onboarding) dihapus. Akun login, email, dan sandinya
-- tetap ada, jadi pengguna cukup masuk lagi dan mengulang dari onboarding.
--
-- Cara pakai:
--   1. Isi daftar sasaran di blok 1. Dua pilihan:
--        - daftar email tertentu (disarankan untuk akun uji), ATAU
--        - semua akun: ganti `false` pada v_semua menjadi `true`.
--   2. Jalankan blok 1 saja dulu. Hasilnya daftar akun yang akan direset
--      beserta jumlah data yang akan terhapus. Periksa.
--   3. Kalau sudah benar, jalankan blok 1 + blok 2 sekaligus.
--
-- Urutan hapus disengaja: quest dan item Journey dihapus sebelum roadmap,
-- karena trigger jaga_ganti_profesi menolak menghapus roadmap yang masih
-- berprogres.
-- ===========================================================================

-- ---------------------------------------------------------------- blok 1 --
drop table if exists pg_temp.sasaran;
create temporary table sasaran as
select u.id as user_id, u.email
from auth.users u
where (select false)                     -- v_semua: ganti false -> true untuk SEMUA akun
   or u.email in (
        'navika.baru1@zdann.me',          -- isi email akun yang mau direset
        'navika.baru2@zdann.me'
      );

select s.email,
       (select count(*) from public.user_dna d where d.user_id = s.user_id)          as pilihan_dna,
       (select count(*) from public.user_roadmaps r where r.user_id = s.user_id)     as roadmap,
       (select count(*) from public.user_quests q where q.user_id = s.user_id)       as quest,
       (select coalesce(sum(x.xp), 0) from public.xp_ledger x where x.user_id = s.user_id) as xp,
       (select count(*) from public.user_achievements a where a.user_id = s.user_id) as badge
from sasaran s
order by s.email;

-- ---------------------------------------------------------------- blok 2 --
begin;

delete from public.user_quests                where user_id in (select user_id from sasaran);
delete from public.user_journey_items         where user_id in (select user_id from sasaran);
delete from public.user_journey_progress      where user_id in (select user_id from sasaran);
delete from public.user_education_path_steps  where user_id in (select user_id from sasaran);
delete from public.user_education_path        where user_id in (select user_id from sasaran);
delete from public.user_roadmap_activities    where user_id in (select user_id from sasaran);
delete from public.user_roadmaps              where user_id in (select user_id from sasaran);
delete from public.user_career_goals          where user_id in (select user_id from sasaran);
delete from public.user_dna                   where user_id in (select user_id from sasaran);
delete from public.user_dna_progress          where user_id in (select user_id from sasaran);
delete from public.user_riasec_profile        where user_id in (select user_id from sasaran);
delete from public.user_assessment_responses  where user_id in (select user_id from sasaran);
delete from public.user_achievements          where user_id in (select user_id from sasaran);
delete from public.user_notifications         where user_id in (select user_id from sasaran);
delete from public.xp_ledger                  where user_id in (select user_id from sasaran);

-- Profil dikosongkan seperti akun yang baru dibuat trigger handle_new_user:
-- onboarding belum selesai, data pendidikan dan nama kosong, avatar dilepas.
update public.profiles p
set full_name = null, date_of_birth = null, city = null,
    education_level_code = null, graduation_status = null, grade_level = null,
    semester = null, is_final_semester = false, smk_concentration_id = null,
    study_program_id = null, study_program_custom = null, target_graduation_year = null,
    weekly_hours = null, monthly_budget = null, onboarding_completed_at = null,
    avatar_url = null
where p.user_id in (select user_id from sasaran);

select count(*) as akun_direset from sasaran;

commit;
