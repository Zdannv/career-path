\pset footer off
\set QUIET on


-- ---------- helper: label jenjang pendidikan per rank ----------
create temp view v_edu as
select * from (values
 (1,'SMP / MTs'),(2,'SMA / SMK sederajat'),(3,'Diploma 1 (D1)'),(4,'Diploma 2 (D2)'),
 (5,'Diploma 3 (D3)'),(6,'Sarjana (S1) / Diploma 4 (D4)'),(7,'Magister (S2)'),(8,'Doktor (S3)')
) as t(rank, label);

-- ---------- helper: industri per profesi ----------
create temp view v_ind as
select ci.career_id, string_agg(i.name_id, '; ' order by i.display_order) as industri
from career_industries ci join industries i on i.code = ci.industry_code
group by ci.career_id;

-- ---------- helper: DNA dominan per profesi per layer ----------
create temp view v_dna as
select c.id as career_id, a.layer_code,
       string_agg(a.name_id, '; ' order by d.rank_in_layer) as attrs
from careers c
join onet_dna d on d.soc_code = c.soc_code and d.is_dominant
join dna_attributes a on a.code = d.attribute_code
group by c.id, a.layer_code;

-- ---------- helper: ringkas roadmap ----------
create temp view v_rm as
select t.career_id, t.est_months,
       count(distinct s.id) as n_tahap,
       count(distinct m.id) as n_milestone,
       count(a.id)          as n_aktivitas,
       sum(a.xp)            as total_xp
from roadmap_templates t
left join roadmap_stages s     on s.template_id = t.id
left join roadmap_milestones m on m.stage_id = s.id
left join roadmap_activities a on a.milestone_id = m.id
group by t.career_id, t.est_months;

-- =========== 01 TOP MARKET DEMAND ===========
\copy (with r as (select m.career_id, row_number() over (order by m.demand_score desc, m.salary_max desc, c.career_name) as peringkat from career_market m join careers c on c.id=m.career_id) select r.peringkat as "Peringkat", c.career_name as "Nama Profesi", c.name_en as "Nama (EN)", c.soc_code as "Kode SOC", f.name_id as "Rumpun", el.label as "Pendidikan Minimal", c.job_zone as "Job Zone", m.demand_score as "Skor Demand (0-100)", mv.demand_label as "Label Demand", m.growth_pct as "Pertumbuhan (%/th)", m.ai_resilience as "Ketahanan thd AI (0-100)", mv.ai_label as "Label Ketahanan AI", m.salary_min as "Gaji Min (Rp/bln)", m.salary_max as "Gaji Maks (Rp/bln)", vi.industri as "Industri", dI.attrs as "Interest DNA", dA.attrs as "Activity DNA", dS.attrs as "Skill DNA", rm.est_months as "Estimasi Roadmap (bln)", rm.n_aktivitas as "Jumlah Aktivitas Roadmap", m.source as "Sumber Data", m.confidence as "Tingkat Keyakinan", m.as_of_year as "Tahun Acuan" from r join career_market m on m.career_id=r.career_id join career_market_view mv on mv.career_id=r.career_id join careers c on c.id=r.career_id left join career_families f on f.code=c.family_code left join v_edu el on el.rank=c.min_education_rank left join v_ind vi on vi.career_id=c.id left join v_dna dI on dI.career_id=c.id and dI.layer_code='INTEREST' left join v_dna dA on dA.career_id=c.id and dA.layer_code='ACTIVITY' left join v_dna dS on dS.career_id=c.id and dS.layer_code='SKILL' left join v_rm rm on rm.career_id=c.id where r.peringkat<=250 order by r.peringkat) to '/home/claude/kb/csv/01_top250.csv' csv header;

-- =========== 02 PROFESI LENGKAP ===========
\copy (select c.id as "ID", c.career_name as "Nama Profesi", c.name_en as "Nama (EN)", c.name_alt as "Nama Lain", c.soc_code as "Kode SOC", oo.title as "Judul O*NET", c.job_zone as "Job Zone", c.min_education_rank as "Rank Pendidikan", ed.label as "Pendidikan Minimal", c.family_code as "Kode Rumpun", f.name_id as "Rumpun", c.career_description as "Deskripsi", c.description_source as "Sumber Deskripsi", c.location_bias as "Bias Lokasi", c.relevance as "Relevansi", c.source as "Sumber", c.is_active as "Aktif", vi.industri as "Industri", dI.attrs as "Interest DNA", dA.attrs as "Activity DNA", dS.attrs as "Skill DNA", dE.attrs as "Environment DNA", dW.attrs as "Work Style DNA", cr.holland_code as "Kode Holland", m.demand_score as "Skor Demand", m.salary_min as "Gaji Min", m.salary_max as "Gaji Maks", rm.est_months as "Roadmap (bln)", rm.n_aktivitas as "Aktivitas Roadmap" from careers c left join v_edu ed on ed.rank=c.min_education_rank left join career_families f on f.code=c.family_code left join onet_occupations oo on oo.soc_code=c.soc_code left join v_ind vi on vi.career_id=c.id left join v_dna dI on dI.career_id=c.id and dI.layer_code='INTEREST' left join v_dna dA on dA.career_id=c.id and dA.layer_code='ACTIVITY' left join v_dna dS on dS.career_id=c.id and dS.layer_code='SKILL' left join v_dna dE on dE.career_id=c.id and dE.layer_code='ENVIRONMENT' left join v_dna dW on dW.career_id=c.id and dW.layer_code='WORKSTYLE' left join career_riasec cr on cr.career_id=c.id left join career_market m on m.career_id=c.id left join v_rm rm on rm.career_id=c.id order by c.career_name) to '/home/claude/kb/csv/02_profesi.csv' csv header;

-- =========== 03 MARKET INTELLIGENCE (477) ===========
\copy (select mv.career_id as "ID Profesi", mv.career_name as "Nama Profesi", f.name_id as "Rumpun", mv.salary_min as "Gaji Min", mv.salary_max as "Gaji Maks", mv.salary_period as "Periode", mv.currency as "Mata Uang", mv.demand_score as "Skor Demand", mv.demand_label as "Label Demand", mv.growth_pct as "Pertumbuhan (%)", mv.ai_resilience as "Ketahanan AI", mv.ai_label as "Label AI", mv.source as "Sumber", mv.confidence as "Keyakinan", mv.as_of_year as "Tahun", mv.is_estimasi as "Estimasi?", cm.note as "Catatan" from career_market_view mv join career_market cm on cm.career_id=mv.career_id left join career_families f on f.code=mv.family_code order by mv.demand_score desc, mv.career_name) to '/home/claude/kb/csv/03_market.csv' csv header;

-- =========== 04 DNA PROFESI (dominan) ===========
\copy (select c.id as "ID Profesi", c.career_name as "Nama Profesi", c.soc_code as "Kode SOC", l.name_id as "Kategori DNA", l.display_order as "Urutan Kategori", a.code as "Kode Atribut", a.name_id as "Atribut", d.score as "Skor O*NET", d.rank_in_layer as "Peringkat dlm Kategori", d.dna_source as "Sumber" from careers c join onet_dna d on d.soc_code=c.soc_code and d.is_dominant join dna_attributes a on a.code=d.attribute_code join dna_layers l on l.code=a.layer_code where c.is_active order by c.career_name, l.display_order, d.rank_in_layer) to '/home/claude/kb/csv/04_dna_profesi.csv' csv header;

-- =========== 05 ATRIBUT DNA ===========
\copy (select l.display_order as "Urutan Kategori", l.name_id as "Kategori", l.name_en as "Kategori (EN)", l.role as "Peran", l.selection_count as "Jumlah Pilihan User", w.weight as "Bobot", a.display_order as "Urutan Atribut", a.code as "Kode Atribut", a.name_id as "Nama Atribut", a.description_id as "Deskripsi", a.onet_mapping as "Pemetaan O*NET", a.is_active as "Aktif" from dna_attributes a join dna_layers l on l.code=a.layer_code left join dna_layer_weights w on w.layer_code=l.code order by l.display_order, a.display_order) to '/home/claude/kb/csv/05_atribut_dna.csv' csv header;

-- =========== 06 RUMPUN ===========
\copy (select f.display_order as "Urutan", f.code as "Kode", f.name_id as "Nama Rumpun", f.description_id as "Deskripsi", (select count(*) from careers c where c.family_code=f.code) as "Jumlah Profesi", f.target_rank_min as "Rank Pendidikan Min", f.target_rank_max as "Rank Pendidikan Maks", f.needs_license as "Butuh Lisensi", f.dna_cohesion as "Kohesi DNA", f.cohesion_note as "Catatan Kohesi", f.is_curated as "Dikurasi Manusia", f.is_active as "Aktif" from career_families f order by f.is_curated desc, f.display_order, f.code) to '/home/claude/kb/csv/06_rumpun.csv' csv header;

-- =========== 07 INDUSTRI ===========
\copy (select i.display_order as "Urutan", i.code as "Kode", i.name_id as "Nama Industri", i.sub_industries as "Contoh Sub-Industri", i.is_active as "Aktif", (select string_agg(a.name_id,'; ' order by a.name_id) from industry_interest_dna x join dna_attributes a on a.code=x.attribute_code where x.industry_code=i.code) as "Interest DNA Dominan", (select count(*) from career_industries ci where ci.industry_code=i.code) as "Jumlah Profesi Tertaut" from industries i order by i.is_active desc, i.display_order) to '/home/claude/kb/csv/07_industri.csv' csv header;

-- =========== 08 PROFESI x INDUSTRI ===========
\copy (select c.id as "ID Profesi", c.career_name as "Nama Profesi", i.code as "Kode Industri", i.name_id as "Industri", ci.source as "Sumber Tautan", ci.is_verified as "Terverifikasi" from career_industries ci join careers c on c.id=ci.career_id join industries i on i.code=ci.industry_code order by c.career_name, i.display_order) to '/home/claude/kb/csv/08_profesi_industri.csv' csv header;

-- =========== 09 ROADMAP RINGKAS ===========
\copy (select t.id as "ID Template", c.career_name as "Nama Profesi", f.name_id as "Rumpun", t.target_rank as "Target Rank Pendidikan", t.job_zone as "Job Zone", t.est_months as "Estimasi Total (bln)", rm.n_tahap as "Jumlah Tahap", rm.n_milestone as "Jumlah Milestone", rm.n_aktivitas as "Jumlah Aktivitas", rm.total_xp as "Total XP", t.source as "Sumber", t.is_curated as "Dikurasi", t.curation_note as "Catatan" from roadmap_templates t join careers c on c.id=t.career_id left join career_families f on f.code=c.family_code left join v_rm rm on rm.career_id=t.career_id order by c.career_name) to '/home/claude/kb/csv/09_roadmap_ringkas.csv' csv header;

-- =========== 10 ROADMAP TAHAP ===========
\copy (select c.career_name as "Nama Profesi", s.id as "ID Tahap", s.stage_order as "Urutan", s.kind as "Jenis Tahap", s.name_id as "Nama Tahap", s.description_id as "Deskripsi", s.est_months as "Estimasi (bln)", s.skip_if_rank_at_least as "Dilewati jika Rank >=", s.slug as "Slug" from roadmap_stages s join roadmap_templates t on t.id=s.template_id join careers c on c.id=t.career_id order by c.career_name, s.stage_order) to '/home/claude/kb/csv/10_roadmap_tahap.csv' csv header;

-- =========== 11 ROADMAP MILESTONE ===========
\copy (select c.career_name as "Nama Profesi", s.name_id as "Tahap", m.id as "ID Milestone", m.milestone_order as "Urutan", m.name_id as "Nama Milestone", m.description_id as "Deskripsi", sa.name_id as "Area Keahlian", m.weight as "Bobot", m.slug as "Slug" from roadmap_milestones m join roadmap_stages s on s.id=m.stage_id join roadmap_templates t on t.id=s.template_id join careers c on c.id=t.career_id left join roadmap_skill_areas sa on sa.code=m.skill_area_code order by c.career_name, s.stage_order, m.milestone_order) to '/home/claude/kb/csv/11_roadmap_milestone.csv' csv header;

-- =========== 12 ROADMAP AKTIVITAS ===========
\copy (select c.career_name as "Nama Profesi", s.name_id as "Tahap", m.name_id as "Milestone", a.id as "ID Aktivitas", a.activity_order as "Urutan", a.kind as "Jenis", a.name_id as "Nama Aktivitas", a.description_id as "Deskripsi", a.xp as "XP", a.est_hours as "Estimasi (jam)", a.slug as "Slug" from roadmap_activities a join roadmap_milestones m on m.id=a.milestone_id join roadmap_stages s on s.id=m.stage_id join roadmap_templates t on t.id=s.template_id join careers c on c.id=t.career_id order by c.career_name, s.stage_order, m.milestone_order, a.activity_order) to '/home/claude/kb/csv/12_roadmap_aktivitas.csv' csv header;

-- =========== 13 AREA KEAHLIAN (IWA) ===========
\copy (select sa.code as "Kode IWA", sa.gwa_code as "Kode GWA", sa.name_id as "Nama (ID)", sa.name_en as "Nama (EN)", sa.is_verified as "Terjemahan Terverifikasi", (select count(*) from roadmap_milestones m where m.skill_area_code=sa.code) as "Dipakai di Milestone" from roadmap_skill_areas sa order by sa.gwa_code, sa.code) to '/home/claude/kb/csv/13_skill_area.csv' csv header;

-- =========== 14 PENDIDIKAN ===========
\copy (select el.order_rank as "Rank", el.code as "Kode", el.level_name as "Jenjang", el.description_id as "Deskripsi", (select count(*) from careers c where c.min_education_rank=el.order_rank and c.is_active) as "Profesi dgn Syarat Minimal Ini" from education_levels el order by el.order_rank, el.code) to '/home/claude/kb/csv/14_jenjang.csv' csv header;
\copy (select r.display_order as "Urutan Rumpun", r.name_id as "Rumpun Studi", p.name_id as "Program Studi", p.source as "Sumber", p.is_verified as "Terverifikasi" from study_programs p left join study_program_rumpun pr on pr.program_id=p.id left join study_rumpun r on r.code=pr.rumpun_code order by r.display_order nulls last, p.name_id) to '/home/claude/kb/csv/15_prodi.csv' csv header;
\copy (select ep.display_order as "Urutan", ep.code as "Kode Program", ep.name_id as "Program Keahlian SMK", sc.name_id as "Konsentrasi Keahlian" from smk_expertise_programs ep left join smk_concentrations sc on sc.program_code=ep.code order by ep.display_order, sc.display_order) to '/home/claude/kb/csv/16_smk.csv' csv header;
\copy (select level_code as "Kode Jenjang", graduation_status as "Status Kelulusan", major_kind as "Jenis Jurusan", needs_grade as "Perlu Kelas", needs_semester as "Perlu Semester" from education_step_rules order by level_code, graduation_status) to '/home/claude/kb/csv/17_aturan_edu.csv' csv header;
\copy (select education_level as "Jenjang", major_name as "Jurusan", suggested_skills as "Skill Disarankan" from education_majors order by education_level, major_name) to '/home/claude/kb/csv/18_jurusan.csv' csv header;

-- =========== 19 SKILLS ===========
\copy (select s.id as "ID", s.skill_name as "Nama Skill", s.category as "Kategori", s.skill_type as "Tipe", (select count(*) from career_skills cs where cs.skill_id=s.id) as "Dipakai di Profesi" from skills s order by s.category, s.skill_name) to '/home/claude/kb/csv/19_skills.csv' csv header;
\copy (select c.career_name as "Nama Profesi", s.skill_name as "Skill", s.category as "Kategori", cs.weight_pct as "Bobot (%)", cs.is_required as "Wajib" from career_skills cs join careers c on c.id=cs.career_id join skills s on s.id=cs.skill_id order by c.career_name, cs.weight_pct desc nulls last) to '/home/claude/kb/csv/20_career_skills.csv' csv header;

-- =========== 21 RIASEC ===========
\copy (select display_order as "Urutan", code as "Kode", name_id as "Nama (ID)", name_en as "Nama (EN)", description_id as "Deskripsi", keywords_action as "Kata Kunci Aksi", keywords_object as "Kata Kunci Objek" from riasec_types order by display_order) to '/home/claude/kb/csv/21_riasec.csv' csv header;
\copy (select career_name as "Nama Profesi", soc_code as "Kode SOC", onet_title as "Judul O*NET", holland_code as "Kode Holland", r_pct as "R (%)", i_pct as "I (%)", a_pct as "A (%)", s_pct as "S (%)", e_pct as "E (%)", c_pct as "C (%)", confidence as "Keyakinan" from career_riasec order by career_name) to '/home/claude/kb/csv/22_career_riasec.csv' csv header;
\copy (select ai.display_order as "Urutan", ai.code as "Kode", ai.riasec_code as "Tipe RIASEC", ai.interest_area as "Area Minat", ai.question_id as "Pertanyaan", ai.tier as "Tingkat", ai.item_version as "Versi", ai.is_active as "Aktif" from assessment_items ai order by ai.display_order) to '/home/claude/kb/csv/23_asesmen.csv' csv header;

-- =========== 24 BAND SKOR ===========
\copy (select display_order as "Urutan", code as "Kode", label_id as "Label", min_score as "Skor Min", max_score as "Skor Maks", description_id as "Deskripsi" from match_score_bands order by display_order) to '/home/claude/kb/csv/24_band.csv' csv header;

-- =========== 25 O*NET OCCUPATIONS ===========
\copy (select soc_code as "Kode SOC", title as "Judul", holland_code as "Kode Holland", r_pct as "R (%)", i_pct as "I (%)", a_pct as "A (%)", s_pct as "S (%)", e_pct as "E (%)", c_pct as "C (%)", onet_version as "Versi O*NET" from onet_occupations order by soc_code) to '/home/claude/kb/csv/25_onet.csv' csv header;
