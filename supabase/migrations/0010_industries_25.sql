-- ============================================================================
-- 0010_industries_25.sql
--
-- Memperluas daftar industri dari 9 menjadi 25, sesuai sheet "Mapping
-- (Industri)" di workbook tim desain & PO, dan menambahkan relasi
-- industri <-> Interest DNA yang selama ini belum ada.
--
-- Isi tabel industri dan relasinya adalah transkripsi langsung dari sheet —
-- tidak ada yang saya karang. Yang TIDAK ikut dikerjakan di sini adalah
-- memetakan ulang 477 profesi ke 25 industri; alasannya ada di bagian 4.
--
-- Jalankan setelah 0009. Aman diulang.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Kolom tambahan
-- ---------------------------------------------------------------------------
alter table public.industries add column if not exists sub_industries text;
alter table public.industries add column if not exists display_order  smallint;
alter table public.industries add column if not exists is_active      boolean not null default true;

comment on column public.industries.sub_industries is
  'Contoh sub-industri, apa adanya dari sheet Mapping (Industri). Dipakai untuk membantu user mengenali industrinya, bukan sebagai taksonomi tersendiri.';

-- ---------------------------------------------------------------------------
-- 2. 25 industri
--
-- Sembilan kode lama dipertahankan supaya 636 tautan profesi-industri yang
-- sudah dikurasi di 0003 tidak putus. Yang berubah hanya namanya, mengikuti
-- penyebutan di sheet.
-- ---------------------------------------------------------------------------
insert into public.industries (code, name_id, sub_industries, display_order) values
  ('TECH',          'Teknologi Informasi & AI',   'Software, SaaS, AI, Data Science, Cybersecurity, Cloud', 1),
  ('FINANCE',       'Perbankan & Fintech',        'Bank Digital, Payment Gateway, Lending, WealthTech', 2),
  ('INSURANCE',     'Keuangan & Asuransi',        'Accounting, Audit, Tax, Insurance, Financial Advisory', 3),
  ('HEALTH',        'Healthcare & Life Sciences', 'Rumah Sakit, Klinik, Farmasi, Bioteknologi, MedTech', 4),
  ('EDUCATION',     'Pendidikan',                 'Sekolah, Universitas, EdTech, Training Center', 5),
  ('COMMERCE',      'Retail & E-Commerce',        'Marketplace, Retail Modern, Wholesale, D2C Brand', 6),
  ('LOGISTICS',     'Supply Chain & Logistics',   'Warehousing, Freight Forwarding, Shipping, Last Mile', 7),
  ('MANUFACTURING', 'Manufaktur',                 'Elektronik, Otomotif, Textile, Packaging', 8),
  ('ENERGY',        'Energi & Pertambangan',      'Oil & Gas, Renewable Energy, Mining', 9),
  ('AGRI',          'Agrikultur & Pangan',        'Pertanian, Perkebunan, Perikanan, Food Production', 10),
  ('CONSTRUCTION',  'Konstruksi & Properti',      'Real Estate, Architecture, Civil Engineering', 11),
  ('TRANSPORT',     'Transportasi & Mobilitas',   'Aviation, Railway, Automotive, Mobility Tech', 12),
  ('TELCO',         'Telekomunikasi',             'ISP, Mobile Network, Fiber Optic, Satellite', 13),
  ('MEDIA',         'Media & Entertainment',      'TV, Film, Musik, Streaming, Gaming', 14),
  ('CREATIVE',      'Creative & Design',          'UI/UX, Graphic Design, Animation, Industrial Design', 15),
  ('MARKETING',     'Marketing & Advertising',    'Digital Marketing, Branding, PR, Agency', 16),
  ('LEGAL',         'Hukum & Kebijakan',          'Law Firm, Compliance, Public Policy', 17),
  ('GOVERNMENT',    'Pemerintahan & BUMN',        'Kementerian, Pemda, BUMN, Lembaga Negara', 18),
  ('SUSTAIN',       'Lingkungan & Keberlanjutan', 'ESG, Sustainability, Waste Management', 19),
  ('AEROSPACE',     'Aerospace & Drone',          'Aerospace, UAV, Drone Technology', 20),
  ('DEFENSE',       'Keamanan & Pertahanan',      'Military, Defense Industry, Security Services', 21),
  ('NGO',           'NGO & Sosial',               'NGO, Humanitarian, Community Development', 22),
  ('HOSPITALITY',   'Hospitality & Pariwisata',   'Hotel, Travel, Resort, Event Organizer', 23),
  ('FNB',           'Food & Beverage',            'Restoran, Cafe, Catering, Food Service', 24),
  ('RESEARCH',      'Riset & Laboratorium',       'Research Institute, Testing Lab, Scientific Services', 25)
on conflict (code) do update set
  name_id        = excluded.name_id,
  sub_industries = excluded.sub_industries,
  display_order  = excluded.display_order;

-- FMCG tidak ada di daftar 25. Ia bukan industri dalam pengertian sheet ini
-- melainkan kategori barang yang membentang di Manufaktur, Retail, dan F&B.
-- Dinonaktifkan, bukan dihapus, supaya 41 tautan profesi yang menunjuk ke sana
-- tidak hilang sebelum sempat dipindahkan.
update public.industries set is_active = false where code = 'FMCG';

comment on table public.industries is
  '25 industri sesuai sheet Mapping (Industri). FMCG disimpan dengan is_active=false: ia kategori barang, bukan industri, dan tautannya masih menunggu dipindahkan.';

-- ---------------------------------------------------------------------------
-- 3. Industri <-> Interest DNA
--
-- Relasi ini yang membuat "user suka Teknologi" bisa diterjemahkan jadi
-- "industri ini mungkin cocok", tanpa harus lewat profesi satu per satu.
-- Satu industri boleh punya lebih dari satu minat dominan.
-- ---------------------------------------------------------------------------
create table if not exists public.industry_interest_dna (
  industry_code  text not null references public.industries(code) on delete cascade,
  attribute_code text not null references public.dna_attributes(code) on delete cascade,
  primary key (industry_code, attribute_code)
);

insert into public.industry_interest_dna (industry_code, attribute_code)
select v.industry_code, a.code
from (values
  ('TECH','Teknologi'),
  ('FINANCE','Keuangan'), ('FINANCE','Bisnis'),
  ('INSURANCE','Keuangan'),
  ('HEALTH','Kesehatan'),
  ('EDUCATION','Pendidikan'),
  ('COMMERCE','Bisnis'),
  ('LOGISTICS','Bisnis'),
  ('MANUFACTURING','Teknologi'),
  ('ENERGY','Teknologi'), ('ENERGY','Lingkungan & Keberlanjutan'),
  ('AGRI','Lingkungan & Keberlanjutan'),
  ('CONSTRUCTION','Teknologi'),
  ('TRANSPORT','Teknologi'),
  ('TELCO','Teknologi'),
  ('MEDIA','Kreativitas'),
  ('CREATIVE','Kreativitas'),
  ('MARKETING','Kreativitas'), ('MARKETING','Bisnis'),
  ('LEGAL','Hukum & Kebijakan'),
  ('GOVERNMENT','Hukum & Kebijakan'),
  ('SUSTAIN','Lingkungan & Keberlanjutan'),
  ('AEROSPACE','Teknologi'),
  ('DEFENSE','Teknologi'),
  ('NGO','Sosial & Pelayanan'),
  ('HOSPITALITY','Sosial & Pelayanan'),
  ('FNB','Bisnis'),
  ('RESEARCH','Riset & Sains')
) as v(industry_code, interest_name)
join public.dna_attributes a
  on a.name_id = v.interest_name and a.layer_code = 'INTEREST'
on conflict do nothing;

-- Tiap industri wajib punya minimal satu minat dominan. Kalau ada nama minat
-- yang tidak cocok dengan dna_attributes, join di atas diam-diam membuangnya —
-- guard ini yang membuatnya berisik.
do $$
declare
  n_kosong int;
begin
  select count(*) into n_kosong
  from public.industries i
  where i.is_active
    and not exists (select 1 from public.industry_interest_dna x where x.industry_code = i.code);
  if n_kosong > 0 then
    raise exception '% industri aktif tidak punya Interest DNA dominan', n_kosong;
  end if;
end $$;

alter table public.industry_interest_dna enable row level security;
drop policy if exists industry_interest_dna_read_all on public.industry_interest_dna;
create policy industry_interest_dna_read_all on public.industry_interest_dna
  for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- 4. Yang sengaja BELUM dikerjakan: memetakan 477 profesi ke 25 industri
--
-- Sembilan industri lama sudah punya 636 tautan hasil kurasi manual di 0003,
-- termasuk 68 profesi lintas sektor. Enam belas industri baru belum punya satu
-- tautan pun.
--
-- Godaannya adalah mengisinya otomatis dari kode SOC. Itu keliru: SOC
-- menggambarkan JENIS PEKERJAAN, bukan industri tempat orang mengerjakannya.
-- Seorang Software Engineer (SOC 15) bekerja di perbankan, rumah sakit, dan
-- ritel; memetakannya ke "Teknologi Informasi & AI" saja justru menghapus
-- kenyataan yang ingin ditangkap sheet itu — kalimatnya sendiri berbunyi
-- "menghubungkan satu profesi ke satu ATAU LEBIH industri".
--
-- Kolom `source` di bawah disiapkan supaya saat pemetaan itu dikerjakan,
-- setiap tautan membawa asal-usulnya dan yang otomatis bisa dibedakan dari
-- yang diperiksa manusia.
-- ---------------------------------------------------------------------------
alter table public.career_industries add column if not exists source text not null default 'curated';
alter table public.career_industries add column if not exists is_verified boolean not null default false;

comment on column public.career_industries.source is
  'curated = hasil kurasi manual di 0003. Nilai lain menandai tautan yang diturunkan otomatis dan masih perlu diperiksa.';

commit;

-- ============================================================================
-- Verifikasi:
--
--   select count(*) from industries where is_active;          -- 25
--   select count(*) from industry_interest_dna;               -- 28
--
--   select i.name_id, count(ci.career_id) as jumlah_profesi
--   from industries i
--   left join career_industries ci on ci.industry_code = i.code
--   where i.is_active group by 1 order by 2 desc;
--   -- 16 industri baru akan menunjukkan 0; itu memang keadaannya sekarang.
-- ============================================================================
