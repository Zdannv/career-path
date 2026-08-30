-- ============================================================================
-- 0004_career_dna.sql   (skema + 54 atribut + view + fungsi matching)
--
-- Career DNA sesuai spesifikasi Navika: 54 atribut dalam 5 layer.
--   Interest 10 (pilih 3) · Activity 12 (pilih 4) · Skill 16 (pilih 5)
--   Environment 8 (pilih 3) · Work Style 8 (pilih 2)
--
-- Spesifikasi menyebut skor DNA per profesi berasal dari "AI Mapping".
-- Di sini TIDAK memakai AI: seluruh 54 atribut DITURUNKAN SECARA DETERMINISTIK
-- dari elemen O*NET yang bisa ditunjuk satu per satu. Pemetaannya tersimpan di
-- kolom `onet_mapping`, jadi setiap angka bisa ditelusuri asalnya dan hasilnya
-- bisa direproduksi kapan saja lewat supabase/dna/derive_dna.py.
--
-- Dua pengecualian yang jujur ditandai:
--   * ENV_REMOTE dan ENV_HYBRID -> aturan turunan. O*NET tidak punya data kerja
--     remote sama sekali (datanya mendahului pola kerja pascapandemi).
--   * 61 okupasi baru yang belum disurvei O*NET mewarisi sebagian layer dari
--     profesi terkait terdekat. Ditandai di kolom `dna_source`.
--
-- Data DNA-nya ada di 0004b (dipisah karena besar).
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Layer
-- ---------------------------------------------------------------------------
create table if not exists public.dna_layers (
  code            text primary key,
  name_en         text     not null,
  name_id         text     not null,
  description_id  text     not null,
  role            text     not null check (role in ('main','supporting')),
  selection_count smallint not null,
  display_order   smallint not null
);
comment on column public.dna_layers.selection_count is
  'Berapa atribut yang dipilih user di layer ini saat Career Discovery.';

insert into public.dna_layers (code, name_en, name_id, description_id, role, selection_count, display_order) values
  ('INTEREST', 'Interest DNA', 'Minat', 'Bidang yang membuatmu tertarik untuk mempelajari atau bekerja di dalamnya.', 'main', 3, 1),
  ('ACTIVITY', 'Activity DNA', 'Aktivitas', 'Aktivitas yang paling kamu nikmati saat bekerja.', 'main', 4, 2),
  ('SKILL', 'Skill DNA', 'Kemampuan Alami', 'Kemampuan yang biasanya lebih mudah kamu lakukan dibanding orang lain.', 'supporting', 5, 3),
  ('ENVIRONMENT', 'Environment DNA', 'Lingkungan Kerja', 'Kondisi kerja yang paling nyaman bagimu.', 'supporting', 3, 4),
  ('WORKSTYLE', 'Work Style DNA', 'Cara Kerja', 'Cara bekerja yang paling kamu sukai.', 'supporting', 2, 5)
on conflict (code) do update set name_id=excluded.name_id, description_id=excluded.description_id,
  selection_count=excluded.selection_count;

-- ---------------------------------------------------------------------------
-- 2. 54 atribut
-- ---------------------------------------------------------------------------
create table if not exists public.dna_attributes (
  code           text primary key,
  layer_code     text     not null references public.dna_layers(code),
  name_id        text     not null,
  description_id text     not null,
  display_order  smallint not null,
  onet_mapping   text,
  is_active      boolean  not null default true
);
comment on column public.dna_attributes.onet_mapping is
  'Elemen O*NET sumber atribut ini. Inilah yang membuat skornya bisa diaudit.';

insert into public.dna_attributes (code, layer_code, name_id, description_id, display_order, onet_mapping) values
  ('INT_TEKNOLOGI', 'INTEREST', 'Teknologi', 'Software, AI, komputer, engineering', 1, 'Specific Interest Areas: Information Technology; Specific Interest Areas: Engineering; Specific Interest Areas: Mechanics/Electronics; Specific Interest Areas: Construction/Woodwork; Specific Interest Areas: Transportation/Machine Operation; Specific Interest Areas: Physical/Manual Labor'),
  ('INT_KESEHATAN', 'INTEREST', 'Kesehatan', 'Medis, kesehatan, kesejahteraan', 2, 'Specific Interest Areas: Health Care Service; Specific Interest Areas: Medical Science; Specific Interest Areas: Athletics'),
  ('INT_BISNIS', 'INTEREST', 'Bisnis', 'Strategi, manajemen, kewirausahaan', 3, 'Specific Interest Areas: Business Initiatives; Specific Interest Areas: Management/Administration; Specific Interest Areas: Sales; Specific Interest Areas: Marketing/Advertising; Specific Interest Areas: Public Speaking; Specific Interest Areas: Office Work'),
  ('INT_PENDIDIKAN', 'INTEREST', 'Pendidikan', 'Mengajar, pembelajaran, pengembangan manusia', 4, 'Specific Interest Areas: Teaching/Education'),
  ('INT_KREATIVITAS', 'INTEREST', 'Kreativitas', 'Desain, seni, inovasi, konten', 5, 'Specific Interest Areas: Visual Arts; Specific Interest Areas: Applied Arts and Design; Specific Interest Areas: Performing Arts; Specific Interest Areas: Music; Specific Interest Areas: Creative Writing; Specific Interest Areas: Media; Specific Interest Areas: Culinary Art'),
  ('INT_KEUANGAN', 'INTEREST', 'Keuangan', 'Investasi, akuntansi, ekonomi', 6, 'Specific Interest Areas: Finance; Specific Interest Areas: Accounting'),
  ('INT_RISET', 'INTEREST', 'Riset & Sains', 'Penelitian, eksperimen, penemuan', 7, 'Specific Interest Areas: Physical Science; Specific Interest Areas: Life Science; Specific Interest Areas: Mathematics/Statistics; Specific Interest Areas: Social Science; Specific Interest Areas: Humanities'),
  ('INT_SOSIAL', 'INTEREST', 'Sosial & Pelayanan', 'Membantu dan melayani masyarakat', 8, 'Specific Interest Areas: Social Service; Specific Interest Areas: Personal Service; Specific Interest Areas: Professional Advising; Specific Interest Areas: Human Resources; Specific Interest Areas: Religious Activities'),
  ('INT_HUKUM', 'INTEREST', 'Hukum & Kebijakan', 'Regulasi, kepatuhan, advokasi', 9, 'Specific Interest Areas: Law; Specific Interest Areas: Politics; Specific Interest Areas: Protective Service'),
  ('INT_LINGKUNGAN', 'INTEREST', 'Lingkungan & Keberlanjutan', 'Alam, energi, sustainability', 10, 'Specific Interest Areas: Nature/Outdoors; Specific Interest Areas: Agriculture; Specific Interest Areas: Animal Service'),
  ('ACT_ANALISA', 'ACTIVITY', 'Analisa & Investigasi', 'Mengolah informasi dan mencari pola', 1, 'Work Activities: Analyzing Data or Information; Work Activities: Getting Information; Work Activities: Identifying Objects, Actions, and Events'),
  ('ACT_PROBLEM', 'ACTIVITY', 'Problem Solving', 'Menyelesaikan masalah kompleks', 2, 'Work Activities: Making Decisions and Solving Problems; Work Activities: Judging the Qualities of Objects, Services, or People'),
  ('ACT_DESAIN', 'ACTIVITY', 'Menciptakan & Mendesain', 'Membuat ide, desain, konsep', 3, 'Work Activities: Thinking Creatively; Work Activities: Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment'),
  ('ACT_MEMBANGUN', 'ACTIVITY', 'Membangun & Mengembangkan', 'Membuat produk, sistem, teknologi', 4, 'Work Activities: Working with Computers; Work Activities: Drafting, Laying Out, and Specifying Technical Devices, Parts, and Equipment; Work Activities: Repairing and Maintaining Electronic Equipment; Work Activities: Repairing and Maintaining Mechanical Equipment; Work Activities: Controlling Machines and Processes'),
  ('ACT_MEMBANTU', 'ACTIVITY', 'Membantu & Melayani', 'Memberikan bantuan dan perawatan ke orang lain', 5, 'Work Activities: Assisting and Caring for Others; Work Activities: Performing for or Working Directly with the Public'),
  ('ACT_MENGAJAR', 'ACTIVITY', 'Mengajar & Membimbing', 'Berbagi ilmu dan mengarahkan', 6, 'Work Activities: Training and Teaching Others; Work Activities: Coaching and Developing Others'),
  ('ACT_KOMUNIKASI', 'ACTIVITY', 'Berkomunikasi & Berinteraksi', 'Berkomunikasi dan berinteraksi dengan orang lain', 7, 'Work Activities: Communicating with Supervisors, Peers, or Subordinates; Work Activities: Communicating with People Outside the Organization; Work Activities: Establishing and Maintaining Interpersonal Relationships; Work Activities: Interpreting the Meaning of Information for Others'),
  ('ACT_MEMIMPIN', 'ACTIVITY', 'Memimpin & Mengelola', 'Mengarahkan tim dan mengambil keputusan', 8, 'Work Activities: Coordinating the Work and Activities of Others; Work Activities: Developing and Building Teams; Work Activities: Guiding, Directing, and Motivating Subordinates; Work Activities: Staffing Organizational Units; Work Activities: Monitoring and Controlling Resources; Work Activities: Developing Objectives and Strategies'),
  ('ACT_MENJUAL', 'ACTIVITY', 'Menjual & Mempengaruhi', 'Marketing, persuasi, merekomendasikan produk atau layanan', 9, 'Work Activities: Selling or Influencing Others; Work Activities: Resolving Conflicts and Negotiating with Others; Work Activities: Providing Consultation and Advice to Others'),
  ('ACT_OPERASIONAL', 'ACTIVITY', 'Operasional & Administrasi', 'Menjalankan dan mengatur proses informasi', 10, 'Work Activities: Processing Information; Work Activities: Documenting/Recording Information; Work Activities: Performing Administrative Activities; Work Activities: Scheduling Work and Activities; Work Activities: Organizing, Planning, and Prioritizing Work'),
  ('ACT_RISET', 'ACTIVITY', 'Eksperimen & Penelitian', 'Menguji, mengevaluasi, meneliti', 11, 'Work Activities: Updating and Using Relevant Knowledge; Work Activities: Estimating the Quantifiable Characteristics of Products, Events, or Information'),
  ('ACT_QC', 'ACTIVITY', 'Inspeksi & Quality Control', 'Memonitor, audit, dan memvalidasi kualitas', 12, 'Work Activities: Inspecting Equipment, Structures, or Materials; Work Activities: Monitoring Processes, Materials, or Surroundings; Work Activities: Evaluating Information to Determine Compliance with Standards'),
  ('SKL_KOMUNIKASI', 'SKILL', 'Komunikasi', 'Menyampaikan ide secara efektif', 1, 'Essential Skills: Speaking; Essential Skills: Active Listening; Essential Skills: Writing; Abilities: Oral Expression'),
  ('SKL_LOGIKA', 'SKILL', 'Logika & Analisa', 'Berpikir sistematis dan kritis', 2, 'Transferable Skills: Systems Analysis; Transferable Skills: Operations Analysis; Abilities: Deductive Reasoning; Abilities: Inductive Reasoning'),
  ('SKL_KREATIVITAS', 'SKILL', 'Kreativitas', 'Menghasilkan ide dan solusi baru', 3, 'Abilities: Fluency of Ideas; Abilities: Originality; Transferable Skills: Technology Design; Work Styles: Innovation'),
  ('SKL_EMPATI', 'SKILL', 'Empati', 'Memahami perasaan dan kebutuhan orang lain', 4, 'Transferable Skills: Social Perceptiveness; Transferable Skills: Service Orientation; Work Styles: Empathy'),
  ('SKL_PERENCANAAN', 'SKILL', 'Perencanaan & Organisasi', 'Mengatur pekerjaan dan prioritas', 5, 'Transferable Skills: Time Management; Transferable Skills: Management of Material Resources; Transferable Skills: Management of Personnel Resources'),
  ('SKL_KEPEMIMPINAN', 'SKILL', 'Kepemimpinan', 'Mengarahkan dan memotivasi orang', 6, 'Transferable Skills: Management of Personnel Resources; Transferable Skills: Coordination; Work Styles: Leadership Orientation'),
  ('SKL_KETELITIAN', 'SKILL', 'Ketelitian', 'Fokus pada detail dan akurasi', 7, 'Work Styles: Attention to Detail; Transferable Skills: Quality Control Analysis; Abilities: Perceptual Speed'),
  ('SKL_NUMERIK', 'SKILL', 'Kemampuan Numerik', 'Bekerja dengan angka dan perhitungan', 8, 'Essential Skills: Mathematics; Abilities: Mathematical Reasoning; Abilities: Number Facility'),
  ('SKL_KOLABORASI', 'SKILL', 'Kolaborasi', 'Bekerja efektif bersama tim', 9, 'Transferable Skills: Coordination; Work Styles: Cooperation; Work Styles: Social Orientation'),
  ('SKL_ADAPTABILITAS', 'SKILL', 'Adaptabilitas', 'Cepat beradaptasi dengan perubahan', 10, 'Work Styles: Adaptability; Abilities: Category Flexibility; Work Styles: Tolerance for Ambiguity'),
  ('SKL_KEPUTUSAN', 'SKILL', 'Pengambilan Keputusan', 'Menentukan pilihan secara tepat', 11, 'Transferable Skills: Judgment and Decision Making; Abilities: Deductive Reasoning'),
  ('SKL_CRITICAL', 'SKILL', 'Critical Thinking', 'Berpikir logis dan analitis', 12, 'Essential Skills: Critical Thinking; Transferable Skills: Complex Problem Solving'),
  ('SKL_BELAJAR', 'SKILL', 'Belajar Cepat', 'Cepat memahami hal baru', 13, 'Essential Skills: Active Learning; Essential Skills: Learning Strategies; Work Styles: Intellectual Curiosity'),
  ('SKL_NEGOSIASI', 'SKILL', 'Negosiasi', 'Mencapai kesepakatan yang saling menguntungkan', 14, 'Transferable Skills: Negotiation; Transferable Skills: Persuasion'),
  ('SKL_PRESENTASI', 'SKILL', 'Presentasi', 'Menyampaikan ide dengan jelas dan meyakinkan', 15, 'Essential Skills: Speaking; Work Context: Public Speaking; Abilities: Oral Expression'),
  ('SKL_WAKTU', 'SKILL', 'Manajemen Waktu', 'Mengatur waktu dan prioritas secara efektif', 16, 'Transferable Skills: Time Management; Work Styles: Dependability'),
  ('ENV_KANTOR', 'ENVIRONMENT', 'Kantor', 'Bekerja di lingkungan perkantoran', 1, 'Work Context: Indoors, Environmentally Controlled; Work Context: Spend Time Sitting; Work Context: E-Mail'),
  ('ENV_REMOTE', 'ENVIRONMENT', 'Remote', 'Bekerja dari mana saja', 2, 'aturan turunan (O*NET tidak punya data kerja remote)'),
  ('ENV_HYBRID', 'ENVIRONMENT', 'Hybrid', 'Kombinasi kantor dan remote', 3, 'aturan turunan (O*NET tidak punya data kerja remote)'),
  ('ENV_ONSITE', 'ENVIRONMENT', 'Onsite', 'Bekerja langsung di lokasi', 4, 'Work Context: Outdoors, Exposed to All Weather Conditions; Work Context: Indoors, Not Environmentally Controlled; Work Context: Spend Time Standing; Work Context: Spend Time Walking or Running'),
  ('ENV_LAB', 'ENVIRONMENT', 'Laboratorium', 'Lingkungan penelitian dan eksperimen', 5, 'Essential Skills: Science; Work Context: Exposed to Radiation; Work Context: Exposed to Contaminants'),
  ('ENV_RS', 'ENVIRONMENT', 'Rumah Sakit / Klinik', 'Lingkungan layanan kesehatan', 6, 'Work Context: Exposed to Disease or Infections; Work Activities: Assisting and Caring for Others'),
  ('ENV_SEKOLAH', 'ENVIRONMENT', 'Sekolah / Kampus', 'Dunia pendidikan dan akademik', 7, 'Work Activities: Training and Teaching Others; Work Context: Public Speaking'),
  ('ENV_PABRIK', 'ENVIRONMENT', 'Industri / Pabrik', 'Produksi, manufaktur, operasional', 8, 'Work Context: Exposed to Hazardous Equipment; Work Context: Exposed to Sounds, Noise Levels that are Distracting or Uncomfortable; Work Activities: Controlling Machines and Processes; Work Context: Pace Determined by Speed of Equipment; Work Context: Spend Time Making Repetitive Motions'),
  ('WSY_MANDIRI', 'WORKSTYLE', 'Mandiri', 'Nyaman bekerja sendiri', 1, 'Work Styles: Initiative; Work Styles: Self-Confidence'),
  ('WSY_KOLABORATIF', 'WORKSTYLE', 'Kolaboratif', 'Suka bekerja dalam tim', 2, 'Work Styles: Cooperation; Work Styles: Social Orientation'),
  ('WSY_TERSTRUKTUR', 'WORKSTYLE', 'Terstruktur', 'Menyukai proses yang rapi dan jelas', 3, 'Work Styles: Dependability; Work Styles: Attention to Detail; Work Styles: Cautiousness'),
  ('WSY_DINAMIS', 'WORKSTYLE', 'Dinamis', 'Menyukai variasi dan tantangan baru', 4, 'Work Styles: Innovation; Work Styles: Tolerance for Ambiguity'),
  ('WSY_BERUBAH', 'WORKSTYLE', 'Cepat Berubah', 'Nyaman menghadapi perubahan', 5, 'Work Styles: Adaptability; Work Styles: Stress Tolerance'),
  ('WSY_DETAIL', 'WORKSTYLE', 'Berorientasi Detail', 'Teliti dan memperhatikan detail', 6, 'Work Styles: Attention to Detail'),
  ('WSY_TARGET', 'WORKSTYLE', 'Berorientasi Target', 'Termotivasi mencapai tujuan', 7, 'Work Styles: Achievement Orientation; Work Styles: Perseverance'),
  ('WSY_PELAYANAN', 'WORKSTYLE', 'Berorientasi Pelayanan', 'Senang membantu orang lain', 8, 'Work Styles: Empathy; Work Styles: Sincerity')
on conflict (code) do update set name_id=excluded.name_id, description_id=excluded.description_id,
  onet_mapping=excluded.onet_mapping;

-- ---------------------------------------------------------------------------
-- 3. DNA per okupasi O*NET (data diisi di 0004b)
--
--    Disimpan terhadap soc_code, bukan career_id. Beberapa profesi berbagi SOC
--    yang sama (Frontend / Backend / Fullstack Developer -> 15-1252.00), jadi
--    menyimpannya di sini menghindari duplikasi dan membuat perbaikan cukup
--    dilakukan sekali.
--
--    `score`         0-100, sudah dinormalisasi lintas okupasi sehingga
--                    antar atribut bisa dibandingkan langsung.
--    `is_dominant`   masuk N teratas di layernya (N = selection_count).
--    `dna_source`    'onet' | 'rule' | 'inherited:<soc>'
-- ---------------------------------------------------------------------------
create table if not exists public.onet_dna (
  soc_code       text     not null references public.onet_occupations(soc_code) on delete cascade,
  attribute_code text     not null references public.dna_attributes(code) on delete cascade,
  score          numeric(5,2) not null check (score between 0 and 100),
  rank_in_layer  smallint not null,
  is_dominant    boolean  not null,
  dna_source     text     not null,
  primary key (soc_code, attribute_code)
);
create index if not exists idx_onet_dna_attr on public.onet_dna(attribute_code);
create index if not exists idx_onet_dna_dom  on public.onet_dna(soc_code) where is_dominant;

-- DNA per profesi. View, supaya perbaikan di onet_dna langsung terpakai.
create or replace view public.career_dna
  with (security_invoker = true) as
select c.id as career_id, c.career_name, c.soc_code,
       d.attribute_code, a.layer_code, a.name_id as attribute_name,
       d.score, d.rank_in_layer, d.is_dominant, d.dna_source
from public.careers c
join public.onet_dna d on d.soc_code = c.soc_code
join public.dna_attributes a on a.code = d.attribute_code;

-- ---------------------------------------------------------------------------
-- 4. Pilihan DNA user
-- ---------------------------------------------------------------------------
create table if not exists public.user_dna (
  user_id        uuid not null references auth.users(id) on delete cascade,
  attribute_code text not null references public.dna_attributes(code) on delete cascade,
  selected_at    timestamptz not null default now(),
  primary key (user_id, attribute_code)
);
create index if not exists idx_user_dna_user on public.user_dna(user_id);

-- ---------------------------------------------------------------------------
-- 5. Career Match Score
--
--    Untuk tiap layer: rata-rata skor profesi pada atribut YANG DIPILIH user.
--    Kalau user memilih 3 minat dan sebuah profesi tinggi di ketiganya, layer
--    itu mendekati 100.
--
--    Bobot mengikuti pembagian main/supporting di spesifikasi. Main DNA
--    (minat + aktivitas) menentukan arah karier; supporting DNA menyaring
--    kecocokan. Bobot ditaruh di tabel supaya bisa disetel tanpa ganti kode.
-- ---------------------------------------------------------------------------
create table if not exists public.dna_layer_weights (
  layer_code text primary key references public.dna_layers(code),
  weight     numeric(4,3) not null check (weight >= 0 and weight <= 1)
);
insert into public.dna_layer_weights (layer_code, weight) values
  ('INTEREST', 0.300), ('ACTIVITY', 0.300), ('SKILL', 0.200),
  ('ENVIRONMENT', 0.100), ('WORKSTYLE', 0.100)
on conflict (layer_code) do nothing;

create or replace function public.career_match_scores(p_user_id uuid)
returns table (career_id integer, career_name text, match_score numeric, layers jsonb)
language sql stable
set search_path = public
as $$
  with picked as (
    select ud.attribute_code, a.layer_code
    from user_dna ud join dna_attributes a on a.code = ud.attribute_code
    where ud.user_id = p_user_id
  ),
  per_layer as (
    select c.id, c.career_name, p.layer_code,
           avg(d.score) as layer_score
    from careers c
    join onet_dna d on d.soc_code = c.soc_code
    join picked p on p.attribute_code = d.attribute_code
    where c.is_active
    group by c.id, c.career_name, p.layer_code
  )
  select pl.id, pl.career_name,
         round(sum(pl.layer_score * w.weight) / nullif(sum(w.weight), 0), 2),
         jsonb_object_agg(pl.layer_code, round(pl.layer_score, 2))
  from per_layer pl
  join dna_layer_weights w on w.layer_code = pl.layer_code
  group by pl.id, pl.career_name
  order by 3 desc;
$$;

comment on function public.career_match_scores(uuid) is
  'Career Match Score per profesi untuk satu user. Kolom layers memuat rincian per layer supaya UI bisa menjelaskan ALASAN kecocokannya, bukan cuma angkanya.';

-- Similar Career: profesi dengan DNA dominan paling banyak beririsan.
create or replace function public.similar_careers(p_career_id integer, p_limit integer default 6)
returns table (career_id integer, career_name text, shared_dna integer, similarity numeric)
language sql stable
set search_path = public
as $$
  with me as (
    select d.attribute_code from careers c
    join onet_dna d on d.soc_code = c.soc_code
    where c.id = p_career_id and d.is_dominant
  )
  select c.id, c.career_name, count(*)::integer,
         round(count(*) * 100.0 / nullif((select count(*) from me), 0), 1)
  from careers c
  join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
  join me on me.attribute_code = d.attribute_code
  where c.is_active and c.id <> p_career_id
  group by c.id, c.career_name
  order by 3 desc, c.career_name
  limit p_limit;
$$;

-- ---------------------------------------------------------------------------
-- 6. RLS
-- ---------------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['dna_layers','dna_attributes','onet_dna','dna_layer_weights']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t||'_read_all', t);
    execute format('create policy %I on public.%I for select to anon, authenticated using (true)',
                   t||'_read_all', t);
  end loop;
end $$;

select public.apply_owner_rls('user_dna');

commit;
