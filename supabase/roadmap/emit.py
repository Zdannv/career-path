# -*- coding: utf-8 -*-
"""
Menulis 0007_roadmap_data.sql.

Isi file: kosakata capaian (311 IWA) + satu baris masukan per profesi, lalu
sebuah fungsi PL/pgSQL yang merakit stage/milestone/activity dari masukan itu.

Kenapa dirakit di dalam database, bukan di Python: teks roadmap yang jadi
berjumlah ~35.000 baris. Kalau ditulis apa adanya, file SQL-nya belasan
megabyte — tidak bisa ditempel ke SQL Editor Supabase, dan setiap kali satu
pola kalimat diperbaiki seluruh file harus di-generate ulang. Dengan merakitnya
di database, file ini tinggal ~150 KB dan pola kalimatnya ada di satu tempat
yang bisa dibaca reviewer.
"""
import json, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from iwa_id import IWA_ID, GWA_ID
from overrides import EDUCATION_OVERRIDES

careers = json.load(open(f"{HERE}/career_inputs.json"))

# nama profesi per soc, untuk menerapkan override berbasis nama
import csv
soc_names = {}
for row in csv.reader(open(f"{HERE}/careers_id.csv"), delimiter="|"):
    if len(row) >= 2:
        soc_names.setdefault(row[0], []).append(row[1])


def q(s):
    """Kutip literal SQL."""
    return "'" + str(s).replace("'", "''") + "'"


def arr(xs, cast="text"):
    if not xs:
        return f"array[]::{cast}[]"
    return "array[" + ",".join(q(x) for x in xs) + f"]::{cast}[]"


def narr(xs):
    if not xs:
        return "array[]::numeric[]"
    return "array[" + ",".join(str(x) for x in xs) + "]::numeric[]"


out = []
W = out.append

W("""-- ============================================================================
-- 0007_roadmap_data.sql
--
-- Mengisi roadmap untuk seluruh profesi aktif.
--
-- Sumber:
--   * Intermediate Work Activities O*NET 30.3  -> nama capaian (milestone)
--   * Task Ratings (Importance)                -> urutan capaian
--   * Education (Required Level of Education)  -> jenjang target
--   * Training and Experience (RW, OJ)         -> lama fase pengalaman
--   * Software Skills (In Demand)              -> alat kerja yang dipelajari
--   * Related Occupations (Primary-Short)      -> fase pengembangan karier
--   O*NET 30.3, CC BY 4.0.
--
-- Teks Indonesianya dirakit di sini, bukan disimpan baris per baris: yang
-- tersimpan hanya kosakata capaian dan masukan per profesi, sisanya dibentuk
-- oleh fungsi _rm_generate() di bawah. Itu sebabnya file ini ratusan kilobyte,
-- bukan belasan megabyte, dan kenapa memperbaiki satu pola kalimat cukup
-- disunting di satu tempat lalu dijalankan ulang.
--
-- Jalankan setelah 0006. Aman diulang: seluruh isi roadmap dihapus dan
-- dibangun ulang setiap kali. Progres pengguna tidak ikut terhapus selama
-- id aktivitas tidak berubah — lihat catatan di bagian 5.
-- ============================================================================

begin;

set local statement_timeout = '10min';

-- ---------------------------------------------------------------------------
-- 1. Kosakata capaian (311 IWA yang dipakai profesi kita)
-- ---------------------------------------------------------------------------
insert into public.roadmap_skill_areas (code, gwa_code, name_id, name_en) values""")

# --- kosakata --------------------------------------------------------------
import pandas as pd

iwa_df = pd.read_csv(f"{HERE}/iwa_used.csv")
rows = []
for _, r in iwa_df.sort_values("IWA Element ID").iterrows():
    code = r["IWA Element ID"]
    rows.append(
        f"  ({q(code)},{q(r['GWA Element ID'])},{q(IWA_ID[code])},{q(r['IWA Element Name'])})"
    )
W(",\n".join(rows))
W("""on conflict (code) do update
  set gwa_code = excluded.gwa_code,
      name_id  = excluded.name_id,
      name_en  = excluded.name_en;
""")

# --- masukan per profesi ---------------------------------------------------
W("""-- ---------------------------------------------------------------------------
-- 2. Masukan per profesi
--
--   iwa_codes  : capaian terurut dari yang paling penting (maksimal 9)
--   tools      : perangkat lunak bertanda "In Demand" di O*NET, maksimal 5
--   next_socs  : profesi lanjutan, hanya yang ada di knowledge base kita
--   note       : terisi kalau jenjang targetnya dikoreksi manual
-- ---------------------------------------------------------------------------
create temporary table _rm_in (
  soc_code    text primary key,
  target_rank smallint,
  job_zone    smallint,
  exp_months  integer,
  ojt_months  integer,
  iwa_codes   text[],
  iwa_w       numeric[],
  tools       text[],
  next_socs   text[],
  note        text
) on commit drop;

insert into _rm_in values""")

n_over = 0
rows = []
for c in careers:
    soc = c["soc"]
    target = c["target_rank"]
    note = None
    for nm in soc_names.get(soc, []):
        if nm in EDUCATION_OVERRIDES:
            target, note = EDUCATION_OVERRIDES[nm]
            n_over += 1
            break
    codes = [k for k, _ in c["iwas"]]
    ws = [w for _, w in c["iwas"]]
    rows.append(
        "  ("
        + ",".join(
            [
                q(soc),
                str(target),
                str(c["job_zone"]),
                str(c["exp_months"]),
                str(c["ojt_months"]),
                arr(codes),
                narr(ws),
                arr(c["tools"]),
                arr(c["nexts"]),
                q(note) if note else "null",
            ]
        )
        + ")"
    )
W(",\n".join(rows) + ";\n")

# --- izin praktik per profesi ----------------------------------------------
from licenses import license_for

lic_rows = []
for line in open(f"{HERE}/career_ind.csv"):
    line = line.rstrip("\n")
    if not line:
        continue
    name, _, inds = line.partition("|")
    lic = license_for(name, set(x for x in inds.split(",") if x))
    if lic:
        lic_rows.append(f"  ({q(name)},{q(lic)})")

W("""-- ---------------------------------------------------------------------------
-- 2b. Izin praktik
--
-- Tidak ada di O*NET (yang memetakan lisensi Amerika). Disusun manual dari
-- peraturan Indonesia; lihat supabase/roadmap/licenses.py untuk dasarnya.
-- ---------------------------------------------------------------------------
create temporary table _rm_license (
  career_name text primary key,
  license     text not null
) on commit drop;

insert into _rm_license values""")
W(",\n".join(lic_rows) + ";\n")
print(f"   profesi berizin: {len(lic_rows)}")

# --- generator -------------------------------------------------------------
W(r"""-- ---------------------------------------------------------------------------
-- 3. Perakit
--
-- Bentuk roadmap tiap profesi:
--
--   SEKOLAH      selesaikan pendidikan menengah      (hilang kalau sudah lulus)
--   KULIAH       tempuh jenjang yang dibutuhkan      (hilang kalau sudah dicapai)
--   FONDASI      kuasai 4 kemampuan inti teratas
--   PENGALAMAN   alat kerja + 2 kemampuan + pengalaman pertama
--   PROFESIONAL  rekrutmen + 3 kemampuan berikutnya
--   LANJUT       profesi lanjutan yang serumpun
--
-- Empat capaian teratas ditaruh di FONDASI dan sisanya didorong ke fase
-- berikutnya bukan karena yang belakangan kurang penting, melainkan karena
-- urutan bobot O*NET adalah urutan seberapa sering kemampuan itu dipakai di
-- pekerjaan — dan yang paling sering dipakai adalah yang paling masuk akal
-- dilatih lebih dulu.
-- ---------------------------------------------------------------------------
create or replace function _rm_generate() returns text
language plpgsql as $fn$
declare
  r            record;
  v_tpl        bigint;
  v_stage      bigint;
  v_ms         bigint;
  v_order      smallint;
  v_msorder    smallint;
  v_level      text;
  v_kuliah_m   integer;
  v_name       text;
  v_area       text;
  v_i          integer;
  v_tool       text;
  v_next       text;
  v_total      integer;
  v_exp_m      integer;
  v_license    text;
  n_tpl        integer := 0;
  n_stage      integer := 0;
  n_ms         integer := 0;
  n_act        integer := 0;
begin
  for r in
    select c.id as career_id, c.career_name, i.*
    from public.careers c
    join _rm_in i on i.soc_code = c.soc_code
    where c.is_active
    order by c.id
  loop
    -- Nama jenjang target, apa adanya dari tabel pendidikan supaya sebutan di
    -- roadmap sama persis dengan yang dipilih pengguna saat onboarding.
    -- Rank 6 ditempati dua jenjang sekaligus (D4 dan S1) dan datanya tidak
    -- bisa membedakan mana yang diminta, jadi keduanya disebut. Rank lain
    -- hanya punya satu nama.
    if r.target_rank = 6 then
      v_level := 'Sarjana (S1) atau Diploma 4 (D4)';
    else
      select level_name into v_level
      from public.education_levels
      where order_rank = r.target_rank
      order by id limit 1;
      v_level := coalesce(v_level, 'pendidikan tinggi');
    end if;

    v_kuliah_m := case r.target_rank
                    when 3 then 12 when 4 then 24 when 5 then 36
                    when 6 then 48 when 7 then 24 when 8 then 48 else 0 end;

    -- Fase pengalaman dibatasi 24 bulan.
    --
    -- Angka "Related Work Experience" O*NET adalah pengalaman yang DIMILIKI
    -- pemegang jabatan sekarang, bukan yang dibutuhkan untuk masuk. Untuk
    -- Software Developer nilainya 84 bulan; menampilkannya sebagai lama fase
    -- akan terbaca "kamu perlu 7 tahun pengalaman sebelum bisa mulai". Nilai
    -- aslinya tetap disebut di deskripsi fase sebagai gambaran jangka panjang.
    v_exp_m := least(greatest(r.exp_months, 6), 24);

    -- Total sengaja tidak menjumlahkan semua fase: FONDASI berjalan bersamaan
    -- dengan sekolah dan kuliah, jadi menjumlahkannya menghitung tahun yang
    -- sama dua kali. Yang dijumlahkan hanya tulang punggung yang benar-benar
    -- berurutan, dihitung dari lulus pendidikan menengah.
    v_total := v_kuliah_m + v_exp_m + greatest(r.ojt_months, 6);
    select license into v_license from _rm_license where career_name = r.career_name;

    insert into public.roadmap_templates
      (career_id, target_rank, job_zone, est_months, source, is_curated, curation_note)
    values
      (r.career_id, r.target_rank, r.job_zone, v_total, 'onet', r.note is not null, r.note)
    returning id into v_tpl;
    n_tpl := n_tpl + 1;

    v_order := 0;

    -- ---- SEKOLAH ----------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'SEKOLAH', 'Selesaikan pendidikan menengah',
            'Sambil sekolah, kenali profesi ini dari dekat dan pilih jurusan yang mendukung.',
            36, 2)
    returning id into v_stage;
    n_stage := n_stage + 1;

    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, 1, 'Kenali profesi ' || r.career_name,
            'Cari tahu isi pekerjaannya sebelum memilih jalur pendidikan.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET', 'Cari tahu keseharian seorang ' || r.career_name, 10, 2),
      (v_ms, 2, 'RISET', 'Ngobrol dengan satu orang yang bekerja sebagai ' || r.career_name, 25, 2),
      (v_ms, 3, 'BUKTI', 'Tulis alasanmu tertarik pada profesi ini', 10, 1);
    n_act := n_act + 3;

    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, 2, 'Pilih jurusan sekolah yang mendukung',
            'Jurusan di SMA/SMK menentukan pintu mana saja yang terbuka setelah lulus.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET', 'Bandingkan jurusan SMA/SMK yang mengarah ke profesi ini', 15, 3),
      (v_ms, 2, 'ADMIN', 'Tetapkan pilihan jurusanmu', 15, 1);
    n_act := n_act + 2;

    -- ---- KULIAH -----------------------------------------------------------
    if r.target_rank >= 3 then
      v_order := v_order + 1;
      insert into public.roadmap_stages
        (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
      values (v_tpl, v_order, 'KULIAH', 'Tempuh pendidikan ' || v_level,
              'Jenjang yang paling umum diminta untuk masuk ke profesi ini.',
              v_kuliah_m, r.target_rank)
      returning id into v_stage;
      n_stage := n_stage + 1;

      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, 1, 'Pilih program studi yang relevan',
              'Program studi yang tepat memangkas jarak antara bangku kuliah dan pekerjaan.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'RISET', 'Susun daftar program studi yang mengarah ke profesi ini', 15, 3),
        (v_ms, 2, 'RISET', 'Bandingkan kampus, biaya, dan jalur masuknya', 15, 4),
        (v_ms, 3, 'ADMIN', 'Daftar ke program studi pilihanmu', 25, 5);
      n_act := n_act + 3;

      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, 2, 'Selesaikan ' || v_level,
              'Kelulusan adalah syarat administratif yang tidak bisa dilewati untuk profesi ini.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Jaga capaian akademik tiap semester', 20, null),
        (v_ms, 2, 'PRAKTIK', 'Ambil tugas akhir yang berhubungan dengan profesi ini', 40, null),
        (v_ms, 3, 'ADMIN', 'Selesaikan kelulusan dan urus ijazah', 30, null);
      n_act := n_act + 3;
    end if;

    -- ---- FONDASI ----------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'FONDASI', 'Kuasai kemampuan inti',
            'Kemampuan yang paling sering dipakai seorang ' || r.career_name
            || ' dalam pekerjaannya. Fase ini berjalan berbarengan dengan sekolah '
            || 'atau kuliah, bukan setelahnya.',
            null, null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    v_msorder := 0;
    for v_i in 1 .. least(4, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8),
        (v_ms, 2, 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16),
        (v_ms, 3, 'BUKTI',   'Simpan bukti kemampuan ' || _rm_lower(v_name), 15, 2);
      n_act := n_act + 3;
    end loop;

    -- ---- PENGALAMAN -------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'PENGALAMAN', 'Kumpulkan pengalaman nyata',
            case when r.exp_months >= 36
                 then 'Mulai dari magang dan proyek kecil. Sebagai gambaran, pekerja di '
                      || 'profesi ini rata-rata sudah mengumpulkan sekitar '
                      || round(r.exp_months / 12.0) || ' tahun pengalaman terkait.'
                 else 'Pengalaman nyata, sekecil apa pun, yang membedakanmu dari pelamar lain.'
            end,
            v_exp_m, null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    v_msorder := 0;

    if coalesce(array_length(r.tools, 1), 0) > 0 then
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, v_msorder, 'Kuasai alat kerja yang dipakai di lapangan',
              'Perangkat yang paling sering diminta di lowongan profesi ini.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      for v_i in 1 .. array_length(r.tools, 1) loop
        v_tool := r.tools[v_i];
        insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours)
        values (v_ms, v_i, 'BELAJAR', 'Pelajari ' || v_tool, 20, 12);
        n_act := n_act + 1;
      end loop;
    end if;

    for v_i in 5 .. least(6, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8),
        (v_ms, 2, 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16);
      n_act := n_act + 2;
    end loop;

    v_msorder := v_msorder + 1;
    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, v_msorder, 'Dapatkan pengalaman pertama',
            'Magang, proyek nyata, atau pekerjaan lepas — apa pun yang bisa ditunjukkan.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'RISET',   'Data tempat magang atau proyek yang menerima pemula', 15, 4),
      (v_ms, 2, 'PRAKTIK', 'Jalani satu magang atau proyek nyata', 60, null),
      (v_ms, 3, 'BUKTI',   'Rangkum hasilnya jadi satu portofolio', 30, 6);
    n_act := n_act + 3;

    -- ---- PROFESIONAL ------------------------------------------------------
    v_order := v_order + 1;
    insert into public.roadmap_stages
      (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
    values (v_tpl, v_order, 'PROFESIONAL', 'Mulai berkarier sebagai ' || r.career_name,
            'Masuk ke peran pertama dan bertahan di dalamnya.',
            greatest(r.ojt_months, 6), null)
    returning id into v_stage;
    n_stage := n_stage + 1;

    -- Izin praktik untuk profesi yang diatur negara.
    --
    -- Tanpa ini roadmap tenaga kesehatan dan guru salah secara faktual: ijazah
    -- saja tidak cukup untuk bekerja, dan siswa yang mengikuti roadmap sampai
    -- habis akan berhenti tepat sebelum syarat yang paling menentukan.
    v_msorder := 0;
    if v_license is not null then
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
      values (v_stage, v_msorder, 'Urus ' || v_license,
              'Syarat hukum untuk bekerja di profesi ini, diurus setelah lulus.')
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'RISET', 'Cari tahu syarat dan alur pengurusan ' || v_license, 20, 3),
        (v_ms, 2, 'ADMIN', 'Lengkapi berkas dan ajukan ' || v_license, 40, null);
      n_act := n_act + 2;
    end if;

    v_msorder := v_msorder + 1;
    insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
    values (v_stage, v_msorder, 'Lolos proses rekrutmen',
            'Berkas dan wawancara adalah keterampilan tersendiri, terpisah dari kemampuan teknis.')
    returning id into v_ms;
    n_ms := n_ms + 1;
    insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
      (v_ms, 1, 'BUKTI',   'Susun CV yang menonjolkan pengalamanmu', 20, 4),
      (v_ms, 2, 'BELAJAR', 'Latih wawancara kerja untuk posisi ini', 20, 4),
      (v_ms, 3, 'ADMIN',   'Lamar ke minimal lima lowongan', 30, 6);
    n_act := n_act + 3;

    for v_i in 7 .. least(9, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      insert into public.roadmap_milestones
        (stage_id, milestone_order, name_id, skill_area_code, weight)
      values (v_stage, v_msorder, v_name, v_area, r.iwa_w[v_i])
      returning id into v_ms;
      n_ms := n_ms + 1;
      insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours) values
        (v_ms, 1, 'PRAKTIK', 'Terapkan di pekerjaan: ' || _rm_lower(v_name), 25, null);
      n_act := n_act + 1;
    end loop;

    -- ---- LANJUT -----------------------------------------------------------
    if coalesce(array_length(r.next_socs, 1), 0) > 0 then
      v_order := v_order + 1;
      insert into public.roadmap_stages
        (template_id, stage_order, kind, name_id, description_id, est_months, skip_if_rank_at_least)
      values (v_tpl, v_order, 'LANJUT', 'Kembangkan karier',
              'Arah lanjutan yang paling dekat dengan kemampuan yang sudah kamu bangun.',
              null, null)
      returning id into v_stage;
      n_stage := n_stage + 1;

      v_msorder := 0;
      for v_i in 1 .. array_length(r.next_socs, 1) loop
        select career_name into v_next
        from public.careers
        where soc_code = r.next_socs[v_i] and is_active
        order by id limit 1;
        continue when v_next is null;
        v_msorder := v_msorder + 1;
        insert into public.roadmap_milestones (stage_id, milestone_order, name_id, description_id)
        values (v_stage, v_msorder, 'Jajaki jalur ke ' || v_next,
                'Profesi yang sebagian besar kemampuannya sudah kamu miliki.')
        returning id into v_ms;
        n_ms := n_ms + 1;
        insert into public.roadmap_activities (milestone_id, activity_order, kind, name_id, xp, est_hours)
        values (v_ms, 1, 'RISET', 'Cari tahu apa yang membedakan ' || v_next || ' dari peranmu sekarang', 15, 2);
        n_act := n_act + 1;
      end loop;

      -- Semua profesi lanjutannya ternyata tidak aktif: buang stage kosongnya
      -- daripada menampilkan fase tanpa isi.
      if v_msorder = 0 then
        delete from public.roadmap_stages where id = v_stage;
        n_stage := n_stage - 1;
      end if;
    end if;
  end loop;

  return format('template=%s stage=%s milestone=%s activity=%s', n_tpl, n_stage, n_ms, n_act);
end $fn$;

-- Menurunkan huruf pertama saja, supaya nama capaian bisa disisipkan ke tengah
-- kalimat ("Pelajari dasar merancang sistem ...") tanpa merusak nama diri di
-- dalamnya (lower() penuh akan menulis "excel" dan "autocad").
create or replace function _rm_lower(s text) returns text
language sql immutable as $$
  select case when s is null or s = '' then s
              else lower(left(s, 1)) || right(s, -1) end
$$;

-- ---------------------------------------------------------------------------
-- 4. Bangun ulang
--
-- Menghapus dulu, bukan menambal: template lama dan baru bisa berbeda jumlah
-- fasenya, jadi UPSERT per baris akan meninggalkan sisa yang tidak pernah
-- kelihatan. ON DELETE CASCADE menurun sampai ke aktivitas.
-- ---------------------------------------------------------------------------
delete from public.roadmap_templates;

select _rm_generate() as hasil;

drop function if exists _rm_generate();

commit;

-- ============================================================================
-- 5. Catatan untuk yang menjalankan ulang
--
-- `delete from roadmap_templates` ikut menghapus roadmap_activities, dan
-- user_roadmap_activities.activity_id punya ON DELETE CASCADE — artinya
-- menjalankan ulang file ini SETELAH ada pengguna yang mencentang aktivitas
-- akan menghapus centangnya (XP di xp_ledger tetap, karena tidak ikut cascade).
--
-- Selama masih tahap pengembangan itu tidak masalah. Begitu ada pengguna
-- sungguhan, ganti pola ini dengan generate ke tabel bayangan lalu tukar,
-- atau cocokkan aktivitas lama-baru lewat (career_id, stage_order,
-- milestone_order, activity_order) sebelum menghapus.
--
-- Verifikasi:
--
--   select count(*) from roadmap_templates;                     -- 477
--   select stage_kind, count(*) from roadmap_full
--     group by 1 order by 1;
--   select target_rank, count(*) from roadmap_templates
--     group by 1 order by 1;
-- ============================================================================
""")

sql = "\n".join(out)
path = f"{HERE}/0007_roadmap_data.sql"
open(path, "w").write(sql)
print(f"-> {path}  {len(sql)/1024:.0f} KB")
print(f"   profesi: {len(careers)}  override jenjang: {n_over}")
