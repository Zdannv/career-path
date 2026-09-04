-- Tempel ini ke SQL Editor Supabase. Ia tidak mengubah apa pun, hanya
-- memberitahu migrasi mana yang sudah masuk dan mana yang belum.
select * from (values
  ('0006 roadmap (struktur)',      to_regclass('public.roadmap_templates')      is not null),
  ('0007 roadmap (isi)',           (select count(*) > 0 from information_schema.tables
                                    where table_name='roadmap_skill_areas')
                                   and coalesce((select count(*) from public.roadmap_templates), 0) > 0),
  ('0008 bobot DNA + band label',  to_regclass('public.match_score_bands')      is not null),
  ('0009 mesin pencocokan Jaccard',
     exists (select 1 from pg_proc where proname='career_affinity_scores')),
  ('0010 25 industri',             to_regclass('public.industry_interest_dna')  is not null),
  ('0011 rumpun profesi',          to_regclass('public.career_families')        is not null),
  ('0012 data pasar',              to_regclass('public.career_market')          is not null),
  ('0013 deskripsi + rumpun penuh',
     exists (select 1 from information_schema.columns
             where table_name='careers' and column_name='description_source')),
  ('0014 nama rumpun otomatis',
     exists (select 1 from public.career_families
             where code = 'SOC_15_12' and name_id = 'Pengembang Perangkat Lunak & Infrastruktur TI')),
  ('0015 katalog hard skill',      to_regclass('public.hard_skills')            is not null),
  ('0016 engine template quest',   to_regclass('public.quest_template_steps')   is not null),
  ('0017 roadmap jadi quest',
     exists (select 1 from information_schema.columns
             where table_name='roadmap_activities' and column_name='quest_template_code')),
  ('0018 sub-industri',            to_regclass('public.career_sub_industries') is not null),
  ('0019 prodi -> profesi',        to_regclass('public.education_career')      is not null),
  ('0020 API layar Explore',
     exists (select 1 from pg_proc where proname='explore_state')),
  ('0021 deskripsi dirapikan',
     not exists (select 1 from public.careers
                 where description_source='generate_dari_dna'
                   and career_description ~ '[a-z]+ [A-Z][a-z]+')),
  ('0022 jenjang Indonesia',
     exists (select 1 from public.careers
             where career_name='Apoteker' and min_education_rank=6))
) as t(migrasi, sudah_jalan)
order by migrasi;
