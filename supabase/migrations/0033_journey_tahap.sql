-- ===========================================================================
-- 0033_journey_tahap.sql
--
-- Lima tahap persiapan profesi yang dipakai layar Roadmap dan Journey, plus
-- tingkat XP untuk kartu "Level Explorer".
--
-- ---------------------------------------------------------------------------
-- Hubungannya dengan roadmap yang sudah ada
-- ---------------------------------------------------------------------------
-- roadmap_stages (0006/0007) memodelkan perjalanan sebagai enam fase yang
-- mencakup pendidikan: SEKOLAH, KULIAH, FONDASI, PENGALAMAN, PROFESIONAL,
-- LANJUT. Itu tetap dipakai untuk menghitung durasi dan membangkitkan quest.
--
-- Yang dibangun di sini lapisan yang berbeda: lima tahap PERSIAPAN yang
-- dilihat pengguna di layar Roadmap. Pendidikan formal sengaja tidak ada di
-- dalamnya — ia punya tabnya sendiri, "Jalur Pendidikan" (0034). Pemisahan itu
-- keputusan desain dan masuk akal: menunggu lulus kuliah bukan hal yang bisa
-- dikerjakan minggu ini, sedangkan lima tahap ini bisa.
--
-- Isinya sama untuk semua profesi; yang berbeda cuma nama profesi yang
-- disisipkan ke kalimatnya. Karena itu tabelnya kecil — lima baris tahap,
-- bukan 477 x 5.
--
-- Jalankan setelah 0032. Aman diulang.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Lima tahap
-- ---------------------------------------------------------------------------
create table if not exists public.journey_stages (
  code           text primary key,
  stage_order    smallint not null unique,
  name_id        text not null,
  -- Kalimat pendek di daftar Roadmap.
  summary_id     text not null,
  -- Kalimat di bawah judul tahap pada hero Journey. [profesi] disisipkan.
  hero_id        text not null,
  -- Paragraf "Apa yang akan kamu pelajari?".
  learn_intro_id text not null,
  -- Bentuk isi tahap ini: TOPIK, SOFT_SKILL, SKILL_TOOLS, KEGIATAN, atau NONE.
  content_kind   text not null,
  constraint chk_journey_content check (
    content_kind in ('TOPIK','SOFT_SKILL','SKILL_TOOLS','KEGIATAN','NONE'))
);

comment on table public.journey_stages is
  'Lima tahap persiapan profesi. Isinya seragam lintas profesi; nama profesi disisipkan lewat slot [profesi].';
comment on column public.journey_stages.content_kind is
  'Menentukan komponen mana yang dipakai layar Journey untuk menggambar isi tahap.';

insert into public.journey_stages
  (code, stage_order, name_id, summary_id, hero_id, learn_intro_id, content_kind) values
  ('EKSPLORASI', 1, 'Eksplorasi Karier',
   'Kenali profesi, aktivitas kerja, dan prospek kariernya.',
   'Kenali lebih dekat dunia [profesi]',
   'Melalui Quest mingguan, kamu akan mengenal peran, aktivitas, dan peluang karier dari profesi ini.',
   'TOPIK'),
  ('PONDASI', 2, 'Bangun Pondasi',
   'Kembangkan kemampuan dasar yang mendukung profesi ini.',
   'Kembangkan kemampuan dasar yang mendukung profesi ini.',
   'Melalui Quest mingguan, Navika akan memberikan panduan mengembangkan soft skill yang diperlukan profesi ini.',
   'SOFT_SKILL'),
  ('KEAHLIAN', 3, 'Kembangkan Keahlian',
   'Pelajari skill dan tools yang umum digunakan.',
   'Pelajari skill dan tools yang umum digunakan.',
   'Melalui Quest mingguan, Navika akan memberikan panduan dalam penggunaan ketrampilan teknis dasar dan aplikasi kerja.',
   'SKILL_TOOLS'),
  ('PENGALAMAN', 4, 'Asah Pengalaman',
   'Latih kemampuanmu melalui proyek mandiri dan praktik magang.',
   'Latih kemampuanmu melalui proyek mandiri dan praktik magang.',
   'Melalui Quest mingguan, Navika akan memberikan panduan apa yang harus dilakukan di tahap ini.',
   'KEGIATAN'),
  ('BERKARIER', 5, 'Siap Berkarier!',
   'Persiapkan langkah mendapatkan pekerjaan pertama Kamu.',
   'Persiapkan langkah mendapatkan pekerjaan pertama Kamu.',
   'Melalui Quest mingguan, Navika akan memberikan panduan apa yang harus dilakukan untuk mendapatkan pekerjaan.',
   'NONE')
on conflict (code) do update set
  stage_order = excluded.stage_order, name_id = excluded.name_id,
  summary_id = excluded.summary_id, hero_id = excluded.hero_id,
  learn_intro_id = excluded.learn_intro_id, content_kind = excluded.content_kind;

-- ---------------------------------------------------------------------------
-- 2. "Yang Akan Kamu Dapatkan"
-- ---------------------------------------------------------------------------
create table if not exists public.journey_outcomes (
  stage_code text not null references public.journey_stages(code) on delete cascade,
  item_order smallint not null,
  text_id    text not null,
  primary key (stage_code, item_order)
);

insert into public.journey_outcomes (stage_code, item_order, text_id) values
  ('EKSPLORASI', 1, 'Mengenal dunia kerja [profesi] lebih dekat'),
  ('EKSPLORASI', 2, 'Memahami tugas, lingkungan kerja, dan tantangannya'),
  ('EKSPLORASI', 3, 'Menilai apakah profesi ini sesuai dengan minatmu'),
  ('EKSPLORASI', 4, 'Siap melanjutkan perjalanan ke tahap pengembangan skill'),
  ('PONDASI', 1, 'Pondasi awal soft skill yang lebih kuat untuk mendukung karier impianmu.'),
  ('PONDASI', 2, 'Kebiasaan dan pola pikir yang lebih siap menghadapi tantangan di dunia kerja.'),
  ('PONDASI', 3, 'Kamu selangkah lagi lebih dekat untuk melanjutkan ke tahap berikutnya.'),
  ('KEAHLIAN', 1, 'Mengenalkan ketrampilan dasar profesi.'),
  ('KEAHLIAN', 2, 'Mengenal tools kerja yang digunakan di rutinitas kerja.'),
  ('KEAHLIAN', 3, 'Lebih mudah menemukan topik yang perlu dieksplorasi lebih mendalam.'),
  ('KEAHLIAN', 4, 'Memiliki arah belajar yang lebih jelas untuk tahap berikutnya.'),
  ('PENGALAMAN', 1, 'Memahami pengalaman yang dibutuhkan sebelum memasuki dunia kerja'),
  ('PENGALAMAN', 2, 'Mengetahui cara membangun portfolio dan bukti kompetensi'),
  ('PENGALAMAN', 3, 'Mengenal aktivitas yang dapat memperkuat kesiapan kariermu'),
  ('PENGALAMAN', 4, 'Lebih percaya diri untuk melangkah ke tahap pencarian kerja'),
  ('BERKARIER', 1, 'Mengetahui cara mempersiapkan langkah apa yang harus diambil untuk melamar pekerjaan.')
on conflict (stage_code, item_order) do update set text_id = excluded.text_id;

-- ---------------------------------------------------------------------------
-- 3. Isi tahap yang teksnya tetap
--
--    Tahap 1 (lima topik) dan tahap 4 (tiga kegiatan) isinya sama untuk semua
--    profesi. Tahap 2 dan 3 mengambil isinya dari knowledge base — soft skill
--    dari Career DNA, hard skill dan tools dari 0026/0028 — jadi tidak ada
--    barisnya di sini.
-- ---------------------------------------------------------------------------
create table if not exists public.journey_stage_items (
  stage_code text not null references public.journey_stages(code) on delete cascade,
  item_order smallint not null,
  icon       text not null,          -- nama ikon lucide yang dipakai frontend
  title_id   text not null,
  body_id    text not null,
  primary key (stage_code, item_order)
);

comment on column public.journey_stage_items.icon is
  'Nama ikon lucide-react. Disimpan sebagai teks, bukan komponen, supaya penambahan item tidak menuntut perubahan kode.';

insert into public.journey_stage_items (stage_code, item_order, icon, title_id, body_id) values
  ('EKSPLORASI', 1, 'UserRoundCog', 'Peran & Tanggung Jawab',
   'Mengenal peran utama dan tanggung jawab seorang [profesi].'),
  ('EKSPLORASI', 2, 'CalendarClock', 'Aktivitas Sehari-hari',
   'Ketahui aktivitas dan tugas yang biasa dilakukan setiap hari.'),
  ('EKSPLORASI', 3, 'Building2', 'Lingkungan Kerja',
   'Mengenal lingkungan tempat bekerja dan siapa saja rekan kerja profesi ini.'),
  ('EKSPLORASI', 4, 'TrendingUp', 'Jenjang Karier',
   'Pelajari jenjang karier dan peluang berkembang di masa depan.'),
  ('EKSPLORASI', 5, 'ShieldAlert', 'Tantangan Profesi',
   'Pahami tantangan yang sering dihadapi dan cara menghadapinya.'),
  ('PENGALAMAN', 1, 'BriefcaseBusiness', 'Praktik Kerja Magang',
   'Quest membantumu menemukan cara memperoleh praktik kerja magang yang relevan dengan profesi ini.'),
  ('PENGALAMAN', 2, 'FileBadge', 'Portfolio Kompetensi',
   'Quest membantumu menyusun bukti pengalaman dan kompetensi untuk mendukung kariermu.'),
  ('PENGALAMAN', 3, 'HeartHandshake', 'Kegiatan Relawan',
   'Quest membantumu mencari aktivitas sosial yang dapat memperkaya pengalaman dan keterampilanmu.')
on conflict (stage_code, item_order) do update set
  icon = excluded.icon, title_id = excluded.title_id, body_id = excluded.body_id;

-- ---------------------------------------------------------------------------
-- 4. Tingkat XP
--
--    Kartu di layar Roadmap menulis "Level Explorer  50/500 XP": nama tingkat
--    sekarang, XP terkumpul, dan ambang tingkat berikutnya. Ambangnya ditaruh
--    di tabel supaya kurvanya bisa disetel tanpa menyentuh kode.
-- ---------------------------------------------------------------------------
create table if not exists public.xp_levels (
  level      smallint primary key,
  name_id    text not null,
  min_xp     integer not null,
  next_xp    integer            -- NULL di tingkat tertinggi
);

insert into public.xp_levels (level, name_id, min_xp, next_xp) values
  (1, 'Explorer',     0,    500),
  (2, 'Builder',      500,  1500),
  (3, 'Skilled',      1500, 3000),
  (4, 'Practitioner', 3000, 5000),
  (5, 'Professional', 5000, null)
on conflict (level) do update set
  name_id = excluded.name_id, min_xp = excluded.min_xp, next_xp = excluded.next_xp;

-- ---------------------------------------------------------------------------
-- 5. Kemajuan pengguna per tahap
--
--    Satu baris per (pengguna, profesi, tahap). Tanpa baris berarti belum
--    mulai — lebih hemat daripada menulis lima baris kosong untuk tiap
--    pengguna yang baru memilih profesi.
-- ---------------------------------------------------------------------------
create table if not exists public.user_journey_progress (
  user_id      uuid not null,
  career_id    integer not null references public.careers(id) on delete cascade,
  stage_code   text not null references public.journey_stages(code),
  percent      smallint not null default 0,
  completed_at timestamptz,
  updated_at   timestamptz not null default now(),
  primary key (user_id, career_id, stage_code),
  constraint chk_journey_percent check (percent between 0 and 100)
);

select public.apply_owner_rls('user_journey_progress');

do $$
declare t text;
begin
  foreach t in array array['journey_stages','journey_outcomes','journey_stage_items','xp_levels']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_read_all', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t||'_read_all', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 6. Penyisip nama profesi
--
--    Satu slot saja, [profesi]. Ditulis sebagai fungsi supaya semua RPC
--    memakai cara yang sama dan tidak ada yang lupa menggantinya.
-- ---------------------------------------------------------------------------
create or replace function public.isi_profesi(p_text text, p_profesi text)
returns text language sql immutable as $$
  select replace(p_text, '[profesi]', coalesce(p_profesi, 'profesi ini'));
$$;

-- ---------------------------------------------------------------------------
-- 7. Penjaga
-- ---------------------------------------------------------------------------
do $$
declare v_n int;
begin
  select count(*) into v_n from public.journey_stages;
  if v_n <> 5 then raise exception '0033: journey_stages berisi % baris, seharusnya 5', v_n; end if;

  -- Tiap tahap wajib punya minimal satu bullet "Yang Akan Kamu Dapatkan";
  -- kotak birunya muncul di kelima tahap.
  select count(*) into v_n
  from public.journey_stages s
  where not exists (select 1 from public.journey_outcomes o where o.stage_code = s.code);
  if v_n > 0 then raise exception '0033: % tahap tanpa bullet hasil', v_n; end if;

  -- Tahap bertipe TOPIK dan KEGIATAN wajib punya isinya; dua tipe lain
  -- mengambil dari knowledge base dan memang kosong di sini.
  select count(*) into v_n
  from public.journey_stages s
  where s.content_kind in ('TOPIK','KEGIATAN')
    and not exists (select 1 from public.journey_stage_items i where i.stage_code = s.code);
  if v_n > 0 then raise exception '0033: % tahap berisi tetap tapi tanpa item', v_n; end if;

  -- Ambang XP harus menyambung: next_xp satu tingkat = min_xp tingkat berikut.
  select count(*) into v_n
  from public.xp_levels a join public.xp_levels b on b.level = a.level + 1
  where a.next_xp is distinct from b.min_xp;
  if v_n > 0 then raise exception '0033: % ambang XP tidak menyambung', v_n; end if;

  raise notice '0033: 5 tahap, % bullet hasil, % item isi, % tingkat XP',
    (select count(*) from public.journey_outcomes),
    (select count(*) from public.journey_stage_items),
    (select count(*) from public.xp_levels);
end $$;

commit;
