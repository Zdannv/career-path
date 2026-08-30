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
--   PROFESIONAL  izin praktik + rekrutmen + 3 kemampuan berikutnya
--   LANJUT       profesi lanjutan yang serumpun
--
-- Empat capaian teratas ditaruh di FONDASI dan sisanya didorong ke fase
-- berikutnya bukan karena yang belakangan kurang penting, melainkan karena
-- urutan bobot O*NET adalah urutan seberapa sering kemampuan itu dipakai di
-- pekerjaan — dan yang paling sering dipakai adalah yang paling masuk akal
-- dilatih lebih dulu.
--
-- Semua penulisan lewat UPSERT ber-slug, bukan hapus-lalu-tulis-ulang. Tiap
-- baris punya slug yang tidak bergantung urutan insert, jadi menjalankan file
-- ini lagi mempertahankan id yang sudah ada — dan centang pengguna yang
-- menunjuk id itu ikut selamat. Baris yang hilang dari sumber dibersihkan di
-- bagian 4.
-- ---------------------------------------------------------------------------

create temporary table _rm_seen_tpl   (id bigint primary key) on commit drop;
create temporary table _rm_seen_stage (id bigint primary key) on commit drop;
create temporary table _rm_seen_ms    (id bigint primary key) on commit drop;
create temporary table _rm_seen_act   (id bigint primary key) on commit drop;

create or replace function _rm_lower(s text) returns text
language sql immutable as $$
  select case when s is null or s = '' then s
              else lower(left(s, 1)) || right(s, -1) end
$$;

comment on function _rm_lower(text) is
  'Menurunkan huruf pertama saja, supaya nama capaian bisa disisipkan ke tengah kalimat tanpa merusak nama diri di dalamnya (lower() penuh menulis "excel" dan "autocad").';

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
    on conflict (career_id) do update set
      target_rank = excluded.target_rank, job_zone = excluded.job_zone,
      est_months = excluded.est_months, source = excluded.source,
      is_curated = excluded.is_curated, curation_note = excluded.curation_note
    returning id into v_tpl;
    insert into _rm_seen_tpl values (v_tpl) on conflict do nothing;
    n_tpl := n_tpl + 1;

    v_order := 0;

    -- ---- SEKOLAH ----------------------------------------------------------
    v_order := v_order + 1;
    v_stage := _rm_stage(v_tpl, v_order, 'SEKOLAH', 'SEKOLAH',
      'Selesaikan pendidikan menengah',
      'Sambil sekolah, kenali profesi ini dari dekat dan pilih jurusan yang mendukung.',
      36, 2::smallint);
    n_stage := n_stage + 1;

    v_ms := _rm_milestone(v_stage, 1, 'KENALI_PROFESI',
      'Kenali profesi ' || r.career_name,
      'Cari tahu isi pekerjaannya sebelum memilih jalur pendidikan.', null::text, null::numeric);
    n_ms := n_ms + 1;
    perform _rm_activity(v_ms, 1, 'CARI_TAHU', 'RISET', 'Cari tahu keseharian seorang ' || r.career_name, 10, 2);
    perform _rm_activity(v_ms, 2, 'NGOBROL',   'RISET', 'Ngobrol dengan satu orang yang bekerja sebagai ' || r.career_name, 25, 2);
    perform _rm_activity(v_ms, 3, 'ALASAN',    'BUKTI', 'Tulis alasanmu tertarik pada profesi ini', 10, 1);
    n_act := n_act + 3;

    v_ms := _rm_milestone(v_stage, 2, 'PILIH_JURUSAN',
      'Pilih jurusan sekolah yang mendukung',
      'Jurusan di SMA/SMK menentukan pintu mana saja yang terbuka setelah lulus.', null::text, null::numeric);
    n_ms := n_ms + 1;
    perform _rm_activity(v_ms, 1, 'BANDINGKAN', 'RISET', 'Bandingkan jurusan SMA/SMK yang mengarah ke profesi ini', 15, 3);
    perform _rm_activity(v_ms, 2, 'TETAPKAN',   'ADMIN', 'Tetapkan pilihan jurusanmu', 15, 1);
    n_act := n_act + 2;

    -- ---- KULIAH -----------------------------------------------------------
    if r.target_rank >= 3 then
      v_order := v_order + 1;
      v_stage := _rm_stage(v_tpl, v_order, 'KULIAH', 'KULIAH',
        'Tempuh pendidikan ' || v_level,
        'Jenjang yang paling umum diminta untuk masuk ke profesi ini.',
        v_kuliah_m, r.target_rank::smallint);
      n_stage := n_stage + 1;

      v_ms := _rm_milestone(v_stage, 1, 'PILIH_PRODI',
        'Pilih program studi yang relevan',
        'Program studi yang tepat memangkas jarak antara bangku kuliah dan pekerjaan.', null::text, null::numeric);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'DAFTAR_PRODI',      'RISET', 'Susun daftar program studi yang mengarah ke profesi ini', 15, 3);
      perform _rm_activity(v_ms, 2, 'BANDINGKAN_KAMPUS', 'RISET', 'Bandingkan kampus, biaya, dan jalur masuknya', 15, 4);
      perform _rm_activity(v_ms, 3, 'DAFTAR',            'ADMIN', 'Daftar ke program studi pilihanmu', 25, 5);
      n_act := n_act + 3;

      v_ms := _rm_milestone(v_stage, 2, 'SELESAI_STUDI',
        'Selesaikan ' || v_level,
        'Kelulusan adalah syarat administratif yang tidak bisa dilewati untuk profesi ini.', null::text, null::numeric);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'AKADEMIK',    'BELAJAR', 'Jaga capaian akademik tiap semester', 20, null::integer);
      perform _rm_activity(v_ms, 2, 'TUGAS_AKHIR', 'PRAKTIK', 'Ambil tugas akhir yang berhubungan dengan profesi ini', 40, null::integer);
      perform _rm_activity(v_ms, 3, 'LULUS',       'ADMIN',   'Selesaikan kelulusan dan urus ijazah', 30, null::integer);
      n_act := n_act + 3;
    end if;

    -- ---- FONDASI ----------------------------------------------------------
    v_order := v_order + 1;
    v_stage := _rm_stage(v_tpl, v_order, 'FONDASI', 'FONDASI',
      'Kuasai kemampuan inti',
      'Kemampuan yang paling sering dipakai seorang ' || r.career_name
      || ' dalam pekerjaannya. Fase ini berjalan berbarengan dengan sekolah '
      || 'atau kuliah, bukan setelahnya.',
      null::integer, null::integer);
    n_stage := n_stage + 1;

    v_msorder := 0;
    for v_i in 1 .. least(4, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      v_ms := _rm_milestone(v_stage, v_msorder, v_area, v_name, null::text, v_area, r.iwa_w[v_i]);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'BELAJAR', 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8);
      perform _rm_activity(v_ms, 2, 'PRAKTIK', 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16);
      perform _rm_activity(v_ms, 3, 'BUKTI',   'BUKTI',   'Simpan bukti kemampuan ' || _rm_lower(v_name), 15, 2);
      n_act := n_act + 3;
    end loop;

    -- ---- PENGALAMAN -------------------------------------------------------
    v_order := v_order + 1;
    v_stage := _rm_stage(v_tpl, v_order, 'PENGALAMAN', 'PENGALAMAN',
      'Kumpulkan pengalaman nyata',
      case when r.exp_months >= 36
           then 'Mulai dari magang dan proyek kecil. Sebagai gambaran, pekerja di '
                || 'profesi ini rata-rata sudah mengumpulkan sekitar '
                || round(r.exp_months / 12.0) || ' tahun pengalaman terkait.'
           else 'Pengalaman nyata, sekecil apa pun, yang membedakanmu dari pelamar lain.'
      end,
      v_exp_m, null::integer);
    n_stage := n_stage + 1;

    v_msorder := 0;

    if coalesce(array_length(r.tools, 1), 0) > 0 then
      v_msorder := v_msorder + 1;
      v_ms := _rm_milestone(v_stage, v_msorder, 'ALAT_KERJA',
        'Kuasai alat kerja yang dipakai di lapangan',
        'Perangkat yang paling sering diminta di lowongan profesi ini.', null::text, null::numeric);
      n_ms := n_ms + 1;
      for v_i in 1 .. array_length(r.tools, 1) loop
        v_tool := r.tools[v_i];
        perform _rm_activity(v_ms, v_i::smallint, 'TOOL:' || v_tool, 'BELAJAR', 'Pelajari ' || v_tool, 20, 12);
        n_act := n_act + 1;
      end loop;
    end if;

    for v_i in 5 .. least(6, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      v_ms := _rm_milestone(v_stage, v_msorder, v_area, v_name, null::text, v_area, r.iwa_w[v_i]);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'BELAJAR', 'BELAJAR', 'Pelajari dasar ' || _rm_lower(v_name), 10, 8);
      perform _rm_activity(v_ms, 2, 'PRAKTIK', 'PRAKTIK', 'Latih langsung: ' || v_name, 25, 16);
      n_act := n_act + 2;
    end loop;

    v_msorder := v_msorder + 1;
    v_ms := _rm_milestone(v_stage, v_msorder, 'PENGALAMAN_PERTAMA',
      'Dapatkan pengalaman pertama',
      'Magang, proyek nyata, atau pekerjaan lepas — apa pun yang bisa ditunjukkan.', null::text, null::numeric);
    n_ms := n_ms + 1;
    perform _rm_activity(v_ms, 1, 'DATA_TEMPAT', 'RISET',   'Data tempat magang atau proyek yang menerima pemula', 15, 4);
    perform _rm_activity(v_ms, 2, 'JALANI',      'PRAKTIK', 'Jalani satu magang atau proyek nyata', 60, null::integer);
    perform _rm_activity(v_ms, 3, 'RANGKUM',     'BUKTI',   'Rangkum hasilnya jadi satu portofolio', 30, 6);
    n_act := n_act + 3;

    -- ---- PROFESIONAL ------------------------------------------------------
    v_order := v_order + 1;
    v_stage := _rm_stage(v_tpl, v_order, 'PROFESIONAL', 'PROFESIONAL',
      'Mulai berkarier sebagai ' || r.career_name,
      'Masuk ke peran pertama dan bertahan di dalamnya.',
      greatest(r.ojt_months, 6), null::integer);
    n_stage := n_stage + 1;

    -- Izin praktik untuk profesi yang diatur negara.
    --
    -- Tanpa ini roadmap tenaga kesehatan dan guru salah secara faktual: ijazah
    -- saja tidak cukup untuk bekerja, dan siswa yang mengikuti roadmap sampai
    -- habis akan berhenti tepat sebelum syarat yang paling menentukan.
    v_msorder := 0;
    if v_license is not null then
      v_msorder := v_msorder + 1;
      v_ms := _rm_milestone(v_stage, v_msorder, 'IZIN',
        'Urus ' || v_license,
        'Syarat hukum untuk bekerja di profesi ini, diurus setelah lulus.', null::text, null::numeric);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'SYARAT',  'RISET', 'Cari tahu syarat dan alur pengurusan ' || v_license, 20, 3);
      perform _rm_activity(v_ms, 2, 'AJUKAN',  'ADMIN', 'Lengkapi berkas dan ajukan ' || v_license, 40, null::integer);
      n_act := n_act + 2;
    end if;

    v_msorder := v_msorder + 1;
    v_ms := _rm_milestone(v_stage, v_msorder, 'REKRUTMEN',
      'Lolos proses rekrutmen',
      'Berkas dan wawancara adalah keterampilan tersendiri, terpisah dari kemampuan teknis.', null::text, null::numeric);
    n_ms := n_ms + 1;
    perform _rm_activity(v_ms, 1, 'CV',        'BUKTI',   'Susun CV yang menonjolkan pengalamanmu', 20, 4);
    perform _rm_activity(v_ms, 2, 'WAWANCARA', 'BELAJAR', 'Latih wawancara kerja untuk posisi ini', 20, 4);
    perform _rm_activity(v_ms, 3, 'LAMAR',     'ADMIN',   'Lamar ke minimal lima lowongan', 30, 6);
    n_act := n_act + 3;

    for v_i in 7 .. least(9, coalesce(array_length(r.iwa_codes, 1), 0)) loop
      v_area := r.iwa_codes[v_i];
      select name_id into v_name from public.roadmap_skill_areas where code = v_area;
      continue when v_name is null;
      v_msorder := v_msorder + 1;
      v_ms := _rm_milestone(v_stage, v_msorder, v_area, v_name, null::text, v_area, r.iwa_w[v_i]);
      n_ms := n_ms + 1;
      perform _rm_activity(v_ms, 1, 'TERAPKAN', 'PRAKTIK', 'Terapkan di pekerjaan: ' || _rm_lower(v_name), 25, null::integer);
      n_act := n_act + 1;
    end loop;

    -- ---- LANJUT -----------------------------------------------------------
    if coalesce(array_length(r.next_socs, 1), 0) > 0 then
      v_msorder := 0;
      v_order := v_order + 1;
      v_stage := _rm_stage(v_tpl, v_order, 'LANJUT', 'LANJUT',
        'Kembangkan karier',
        'Arah lanjutan yang paling dekat dengan kemampuan yang sudah kamu bangun.',
        null, null);
      n_stage := n_stage + 1;

      for v_i in 1 .. array_length(r.next_socs, 1) loop
        select career_name into v_next
        from public.careers
        where soc_code = r.next_socs[v_i] and is_active
        order by id limit 1;
        continue when v_next is null;
        v_msorder := v_msorder + 1;
        v_ms := _rm_milestone(v_stage, v_msorder, 'NEXT:' || r.next_socs[v_i],
          'Jajaki jalur ke ' || v_next,
          'Profesi yang sebagian besar kemampuannya sudah kamu miliki.', null::text, null::numeric);
        n_ms := n_ms + 1;
        perform _rm_activity(v_ms, 1, 'CARI_TAHU', 'RISET',
          'Cari tahu apa yang membedakan ' || v_next || ' dari peranmu sekarang', 15, 2);
        n_act := n_act + 1;
      end loop;

      -- Semua profesi lanjutannya ternyata tidak aktif: fase ini tidak jadi
      -- dicatat sebagai terpakai, jadi ikut terbuang di pembersihan bagian 4.
      if v_msorder = 0 then
        delete from _rm_seen_stage where id = v_stage;
        n_stage := n_stage - 1;
      end if;
    end if;
  end loop;

  return format('template=%s stage=%s milestone=%s activity=%s', n_tpl, n_stage, n_ms, n_act);
end $fn$;
""")

W(r"""
-- Tiga helper UPSERT. Dipisah supaya pola "insert, kalau slug sudah ada
-- perbarui saja, lalu catat id-nya sebagai terpakai" tidak ditulis ulang
-- belasan kali di dalam _rm_generate().
create or replace function _rm_stage(
  p_tpl bigint, p_order integer, p_slug text, p_kind text,
  p_name text, p_desc text, p_months integer, p_skip integer
) returns bigint language plpgsql as $fn$
declare v_id bigint;
begin
  insert into public.roadmap_stages
    (template_id, stage_order, kind, name_id, description_id, est_months,
     skip_if_rank_at_least, slug)
  values (p_tpl, p_order, p_kind, p_name, p_desc, p_months, p_skip, p_slug)
  on conflict (template_id, slug) do update set
    stage_order = excluded.stage_order, kind = excluded.kind,
    name_id = excluded.name_id, description_id = excluded.description_id,
    est_months = excluded.est_months,
    skip_if_rank_at_least = excluded.skip_if_rank_at_least
  returning id into v_id;
  insert into _rm_seen_stage values (v_id) on conflict do nothing;
  return v_id;
end $fn$;

create or replace function _rm_milestone(
  p_stage bigint, p_order integer, p_slug text,
  p_name text, p_desc text, p_area text, p_weight numeric
) returns bigint language plpgsql as $fn$
declare v_id bigint;
begin
  insert into public.roadmap_milestones
    (stage_id, milestone_order, name_id, description_id, skill_area_code, weight, slug)
  values (p_stage, p_order, p_name, p_desc, p_area, p_weight, p_slug)
  on conflict (stage_id, slug) do update set
    milestone_order = excluded.milestone_order, name_id = excluded.name_id,
    description_id = excluded.description_id,
    skill_area_code = excluded.skill_area_code, weight = excluded.weight
  returning id into v_id;
  insert into _rm_seen_ms values (v_id) on conflict do nothing;
  return v_id;
end $fn$;

create or replace function _rm_activity(
  p_ms bigint, p_order integer, p_slug text, p_kind text,
  p_name text, p_xp integer, p_hours integer
) returns bigint language plpgsql as $fn$
declare v_id bigint;
begin
  insert into public.roadmap_activities
    (milestone_id, activity_order, kind, name_id, xp, est_hours, slug)
  values (p_ms, p_order, p_kind, p_name, p_xp, p_hours, p_slug)
  on conflict (milestone_id, slug) do update set
    activity_order = excluded.activity_order, kind = excluded.kind,
    name_id = excluded.name_id, xp = excluded.xp, est_hours = excluded.est_hours
  returning id into v_id;
  insert into _rm_seen_act values (v_id) on conflict do nothing;
  return v_id;
end $fn$;

select _rm_generate() as hasil;

-- ---------------------------------------------------------------------------
-- 4. Bersihkan yang sudah tidak ada di sumber
--
-- Dihapus dari bawah ke atas supaya tidak ada baris yang lenyap lebih dulu
-- karena cascade induknya, dan hitungannya tetap terbaca.
-- ---------------------------------------------------------------------------
delete from public.roadmap_activities a
  where not exists (select 1 from _rm_seen_act s where s.id = a.id);
delete from public.roadmap_milestones m
  where not exists (select 1 from _rm_seen_ms s where s.id = m.id);
delete from public.roadmap_stages g
  where not exists (select 1 from _rm_seen_stage s where s.id = g.id);
delete from public.roadmap_templates t
  where not exists (select 1 from _rm_seen_tpl s where s.id = t.id);

-- ---------------------------------------------------------------------------
-- 4b. Sambungkan ulang roadmap pengguna ke templatenya
--
-- `user_roadmaps.template_id` memakai ON DELETE SET NULL, jadi begitu sebuah
-- template terhapus — entah karena versi lama file ini menghapus semuanya,
-- atau karena pembersihan di bagian 4 — roadmap pengguna kehilangan tautannya
-- dan tampil kosong selamanya. Tidak ada yang menyambungkannya kembali sendiri.
--
-- Tautannya bisa dipulihkan tanpa ambiguitas karena `roadmap_templates` unik
-- per profesi: satu profesi, satu template.
update public.user_roadmaps ur
set template_id = t.id
from public.roadmap_templates t
where t.career_id = ur.career_id
  and ur.template_id is distinct from t.id;

drop function if exists _rm_generate();
drop function if exists _rm_stage(bigint, integer, text, text, text, text, integer, integer);
drop function if exists _rm_milestone(bigint, integer, text, text, text, text, numeric);
drop function if exists _rm_activity(bigint, integer, text, text, text, integer, integer);

commit;

-- ============================================================================
-- 5. Menjalankan ulang
--
-- Aman. Tiap baris punya slug yang tidak bergantung urutan insert:
--
--   stage      kind fase                     'FONDASI'
--   milestone  kode IWA atau slug struktural '4.A.2.b.2.b' / 'REKRUTMEN'
--   activity   peran di dalam capaiannya     'PRAKTIK' / 'TOOL:Docker'
--
-- Jadi menjalankan file ini lagi memperbarui baris yang sama di tempatnya,
-- bukan membuat baris baru. Id-nya bertahan, dan centang pengguna di
-- `user_roadmap_activities` yang menunjuk id itu ikut selamat.
--
-- Yang tetap hilang: aktivitas yang benar-benar dibuang dari sumber — misalnya
-- alat kerja yang tidak lagi bertanda In Demand di O*NET. Itu memang niatnya,
-- dan cascade akan ikut menghapus centangnya. XP yang sudah tercatat di
-- xp_ledger tidak ikut terhapus, karena buku besar tidak menghapus baris.
--
-- Verifikasi:
--
--   select count(*) from roadmap_templates;                     -- 477
--   select stage_kind, count(*) from roadmap_full group by 1 order by 1;
--   select count(*) from roadmap_activities where slug is null; -- 0
-- ============================================================================
""")

sql = "\n".join(out)
path = f"{HERE}/0007_roadmap_data.sql"
open(path, "w").write(sql)
print(f"-> {path}  {len(sql)/1024:.0f} KB")
print(f"   profesi: {len(careers)}  override jenjang: {n_over}")
