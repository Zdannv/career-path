"""Generator 0047_profesi_baru_sub_industri_tipis.sql.

Semua angka turunan memakai aturan migrasi lama supaya profesi baru tidak
berbeda perlakuan dari 477 profesi yang sudah ada:
  DNA               supabase/dna/career_dna_raw.csv (pipeline 0004b)
  hard skill item   8 DWA teratas, importance = maks Importance task (0026)
  kemampuan domain  per rumpun SOC 2 digit; kemampuan alat dari Software Skills (0015)
  tools             _soc_tool di 0028
  gaji, demand      supabase/roadmap/market_model.py (0012)
  ketahanan AI      _ai_soc di 0027 + geser Job Zone
  pita senioritas   rumus 0027
"""
import collections, csv, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from onet_cache import O, top_dwa, rows as onet_rows
from terjemah import DWA, IWA
import profesi_baru as PB

REPO = "/Users/macbook/Documents/Kuliah/My Project/sub1_career_path"
MIG = REPO + "/supabase/migrations/"
# Snapshot tabel live (JSON dari REST API, baca saja) disimpan di luar repo.
# Isi folder ini dengan ekspor careers, sub_industries, hard_skill_items,
# roadmap_skill_areas, dan hard_skill_tools sebelum menjalankan ulang.
LIVE = os.environ.get("NAVIKA_SNAPSHOT", os.path.join(HERE, "snapshot"))
sys.path.insert(0, REPO + "/supabase/roadmap")


def live(nama):
    return json.load(open(os.path.join(LIVE, nama + ".json")))


def q(s):
    return "null" if s is None else "'" + str(s).replace("'", "''") + "'"


careers = live("careers")
aktif = [c for c in careers if c["is_active"]]
hs_items = {h["code"]: h for h in live("hard_skill_items")}
iwa_ada = {r["code"] for r in live("roadmap_skill_areas")}
hs_tools = collections.defaultdict(set)
for r in live("hard_skill_tools"):
    hs_tools[r["tool_name"]].add(r["hard_skill_code"])
sub_ind = {s["code"]: s for s in live("sub_industries")}
sub_ind.update({k: {"code": k, "industry_code": ind} for k, ind, _, _ in PB.SUB_BARU})
nama_ada = {c["career_name"] for c in careers}

# ── data dari migrasi lama ──────────────────────────────────────────────────
src15 = open(MIG + "0015_hard_skills.sql").read()
domain_lama = collections.defaultdict(list)
for pre, code, urut in re.findall(r"\('(\d\d)', '([A-Z0-9_]+)', (\d+), 'domain_soc'\)", src15):
    domain_lama[pre].append((int(urut), code))
src27 = open(MIG + "0027_gaji_senioritas_ketahanan_ai.sql").read()
ai_soc = {s: int(v) for s, v in re.findall(r"\('(\d\d-\d{4}\.\d\d)',(\d+)\)", src27)}
src28 = open(MIG + "0028_tools_dan_lisensi.sql").read()
soc_tool = collections.defaultdict(list)
for s, code, contoh, urut in re.findall(r"\('(\d\d-\d{4}\.\d\d)', '([\d.A-Za-z]+)', ('(?:[^']|'')*'|null), (\d+)\)", src28):
    soc_tool[s].append((code, None if contoh == "null" else contoh[1:-1].replace("''", "'"), int(urut)))

jz = {r["O*NET-SOC Code"]: int(r["Job Zone"]) for r in onet_rows("Job Zones.xlsx")}

dna_raw = collections.defaultdict(list)
for r in csv.DictReader(open(REPO + "/supabase/dna/career_dna_raw.csv")):
    dna_raw[r["soc_code"]].append(r)

# Parameter model pasar 0012. Filenya langsung menghitung saat diimpor, jadi
# hanya bagian parameternya (sebelum loop data) yang dijalankan.
import types  # noqa: E402
MM = types.SimpleNamespace()
_src = open(REPO + "/supabase/roadmap/market_model.py").read()
_ns = {}
exec(_src.split("dna = defaultdict")[0], _ns)
exec("def bulat(x, ke=100_000):\n    return int(round(x / ke) * ke)", _ns)
MM.__dict__.update({k: v for k, v in _ns.items() if k.isupper() or k == "bulat"})

# ── hitung per profesi ──────────────────────────────────────────────────────
socs_baru = sorted({p["soc"] for p in PB.PROFESI})
sudah_onet = set()
minor_n = collections.Counter(c["soc_code"][:5] for c in aktif if c["soc_code"])
for p in PB.PROFESI:
    minor_n[p["soc"][:5]] += 1

hasil = []
dwa_dipakai, iwa_baru = set(), set()
for p in PB.PROFESI:
    assert p["nama"] not in nama_ada, f"sudah ada: {p['nama']}"
    soc, rank, j = p["soc"], p["rank"], jz[p["soc"]]
    sumber = "onet" if soc not in sudah_onet else "kurasi"
    sudah_onet.add(soc)
    inds = []
    for code, _ in p["sub"]:
        ind = sub_ind[code]["industry_code"]
        if ind not in inds:
            inds.append(ind)
    prem = max(MM.IND_PREMIUM.get(i, 1.0) for i in inds)
    lo, hi = MM.RANK_MULT[rank]
    jzm = MM.JZ_MULT.get(j, 1.0)
    smin, smax = MM.bulat(MM.UMP * lo * jzm * prem), MM.bulat(MM.UMP * hi * jzm * prem)
    growth = max(MM.IND_GROWTH.get(i, 4.0) for i in inds)
    luas = min(30, minor_n[soc[:5]] * 2.5)
    akses = {1: 30, 2: 30, 3: 25, 4: 22, 5: 20, 6: 16, 7: 10, 8: 6}[rank]
    demand = max(5, min(99, round(luas + min(35, growth * 3.0) + akses)))
    ai = max(5, min(99, ai_soc[soc] + {1: -12, 2: -6, 4: 4, 5: 8}.get(j, 0)))
    r100 = lambda x: int(round(x / 100_000) * 100_000)
    rentang = smax - smin
    pita = [("JUNIOR", r100(0.82 * smin), r100(smin + 0.25 * rentang)),
            ("MID", r100(smin + 0.25 * rentang), r100(1.10 * smax)),
            ("SENIOR", r100(1.10 * smax), r100(1.72 * smax))]

    peringkat = {d: imp for imp, d in top_dwa(soc, 200)}
    if p.get("dwa"):
        items = [(peringkat.get(d, 3.5), d) for d in p["dwa"]]
    else:
        items = top_dwa(soc, 8)
    for _, d in items:
        if d not in hs_items:
            assert d in DWA, f"terjemahan DWA belum ada: {d} {O['dwa_name'].get(d)}"
            dwa_dipakai.add(d)
            if O["dwa_iwa"][d] not in iwa_ada:
                assert O["dwa_iwa"][d] in IWA, f"terjemahan IWA belum ada: {O['dwa_iwa'][d]}"
                iwa_baru.add(O["dwa_iwa"][d])

    # Kemampuan domain (rumpun SOC 2 digit) + kemampuan alat (Software Skills)
    pre = soc[:2]
    hs = [(u, c) for u, c in sorted(domain_lama.get(pre, []))]
    if not hs:
        hs = [(11 + i, code) for i, (code, _, _) in enumerate(PB.HARD_SKILL_DOMAIN[pre])]
    alat = collections.Counter()
    for contoh, _, hot in O["sw"].get(soc, []):
        for kode in hs_tools.get(contoh, ()):
            alat[kode] += 2 if hot else 1
    for i, (kode, _) in enumerate(sorted(alat.items(), key=lambda x: (-x[1], x[0]))):
        hs.append((41 + i, kode))
    tools = soc_tool.get(soc) or [("2.E.4.d", None, 1), ("2.E.4.i", None, 2)]

    hasil.append(dict(p, sumber=sumber, jz=j, inds=inds, smin=smin, smax=smax, demand=demand,
                      growth=growth, ai=ai, pita=pita, items=items, hs=hs, tools=tools))

# ── tulis SQL ───────────────────────────────────────────────────────────────
L = []
w = L.append
w("""-- ============================================================================
-- 0047_profesi_baru_sub_industri_tipis.sql
--
-- Permintaan Nico (28 Oktober 2026): sub-industri seperti Firma Hukum,
-- Kepatuhan, Pertahanan & Militer, Jasa Keamanan, Hotel & Resort, Travel &
-- Wisata, Lembaga Sosial, Pengembangan Masyarakat, Pengelolaan Limbah, dan ISP &
-- Jaringan isinya terlalu sedikit (beberapa kosong). Hakim, pengacara, notaris,
-- dan jaksa wajib ada di Hukum & Kebijakan.
--
-- Isi:
--   1. Sub-industri baru LEG_PERADILAN (Peradilan & Kejaksaan) di bawah Hukum &
--      Kebijakan, supaya hakim, jaksa, dan panitera berada di industri hukum
--      dan bukan hanya di Pemerintahan.
--   2. %d profesi baru, lengkap seperti profesi lama: DNA, sub-industri,
--      industri, rumpun, relevansi prodi/jurusan SMK, jalur pendidikan,
--      lisensi, data pasar, pita gaji senioritas, hard skill, dan tools.
--   3. Katalog pendukung: 10 lisensi dan 7 penerbit baru, 12 rumpun, 3 domain
--      hard skill dan 21 kemampuan domain untuk rumpun SOC 21/23/33/35/37,
--      %d hard skill item dan %d area skill O*NET yang belum diterjemahkan.
--
-- Tidak ada angka yang dikarang per profesi. Dihasilkan oleh
-- supabase/roadmap/profesi_0047/buat_0047.py dengan aturan migrasi lama:
--   DNA               supabase/dna/career_dna_raw.csv (pipeline 0004b), dominan
--                     = peringkat <= selection_count layer (aturan sesudah 0024)
--   hard skill item   8 DWA teratas per SOC, importance = maks Importance task (0026)
--   kemampuan alat    contoh produk Software Skills x hard_skill_tools (0015)
--   tools             _soc_tool 0028
--   gaji & demand     supabase/roadmap/market_model.py (0012), source estimasi_model
--   ketahanan AI      _ai_soc 0027 + geser Job Zone
--   pita senioritas   rumus 0027
-- Notaris, Jaksa, Legal Officer, dan Prajurit TNI meminjam SOC profesi lain
-- (O*NET tidak punya okupasi notaris civil law maupun militer); hard skill
-- mereka dipilih tangan dari daftar SOC tersebut dan dicatat di curation_note.
--
-- URUTAN: jalankan SETELAH 0046. 0046 menonaktifkan semua profesi lalu hanya
-- mengaktifkan 338 nama di daftarnya, dan menghapus ulang pemetaan
-- sub-industri profesi aktif; kalau 0046 dijalankan sesudah file ini, profesi
-- baru ikut nonaktif.
--
-- Aman diulang.
-- ============================================================================

begin;
""" % (len(hasil), len(dwa_dipakai), len(iwa_baru)))

w("-- 1. Sub-industri baru")
for code, ind, nama, urut in PB.SUB_BARU:
    w(f"insert into public.sub_industries (code, industry_code, name_id, display_order) values "
      f"({q(code)}, {q(ind)}, {q(nama)}, {urut}) on conflict (code) do update set name_id = excluded.name_id;")

w("\n-- 2. Penerbit dan lisensi")
w("insert into public.license_issuers (code, name_id) values")
w(",\n".join(f"  ({q(k)}, {q(v)})" for k, v in PB.ISSUER_BARU.items()) + "\non conflict (code) do update set name_id = excluded.name_id;")
w("insert into public.licenses (code, name_id, issuer_code, kind, description_id, step_title_id) values")
w(",\n".join(f"  ({q(a)}, {q(b)}, {q(c)}, {q(d)}, {q(e)}, {q(f)})" for a, b, c, d, e, f in PB.LISENSI_BARU))
w("on conflict (code) do update set name_id = excluded.name_id, issuer_code = excluded.issuer_code,\n"
  "  kind = excluded.kind, description_id = excluded.description_id, step_title_id = excluded.step_title_id;")

w("\n-- 3. Rumpun")
w("insert into public.career_families (code, name_id, description_id, target_rank_min, target_rank_max,\n"
  "  needs_license, dna_cohesion, cohesion_note, display_order, is_active, is_curated) values")
w(",\n".join(f"  ({q(k)}, {q(n)}, {q(d)}, {a}, {b}, {str(l).lower()}, null, 'Ditambahkan 0047 untuk profesi baru.', {300 + i}, true, true)"
             for i, (k, (n, d, a, b, l)) in enumerate(PB.RUMPUN_BARU.items())))
w("on conflict (code) do nothing;")

w("\n-- 4. Kemampuan domain untuk rumpun SOC yang belum punya")
w("insert into public.hard_skill_domains (code, name_id) values")
w(",\n".join(f"  ({q(k)}, {q(v)})" for k, v in PB.DOMAIN_BARU.items()) + "\non conflict (code) do nothing;")
baru_hs = [(c, n, d) for lst in PB.HARD_SKILL_DOMAIN.values() for c, n, d in lst if n]
w("insert into public.hard_skills (code, name_id, domain_code, source) values")
w(",\n".join(f"  ({q(c)}, {q(n)}, {q(d)}, 'domain_soc')" for c, n, d in baru_hs) + "\non conflict (code) do nothing;")

w("\n-- 5. Area skill dan hard skill item O*NET yang baru diterjemahkan")
if iwa_baru:
    w("insert into public.roadmap_skill_areas (code, gwa_code, name_id, name_en, is_verified) values")
    w(",\n".join(f"  ({q(i)}, {q(O['iwa_gwa'][i])}, {q(IWA[i])}, {q(O['iwa_name'][i])}, false)" for i in sorted(iwa_baru)))
    w("on conflict (code) do nothing;")
w("insert into public.hard_skill_items (code, iwa_code, name_id, name_en, is_curated) values")
w(",\n".join(f"  ({q(d)}, {q(O['dwa_iwa'][d])}, {q(DWA[d])}, {q(O['dwa_name'][d].rstrip('.'))}, false)" for d in sorted(dwa_dipakai)))
w("on conflict (code) do nothing;")

w("\n-- 6. DNA O*NET untuk SOC baru (sebelumnya hanya SOC yang dipakai profesi yang dimuat)")
w("create temporary table _dna (soc_code text, attribute_code text, score numeric, rank_in_layer smallint, dna_source text) on commit drop;")
w("insert into _dna values")
vals = []
for s in socs_baru:
    assert dna_raw[s], f"DNA tidak ada di CSV: {s}"
    for r in dna_raw[s]:
        vals.append(f"  ({q(s)}, {q(r['attribute_code'])}, {r['score']}, {r['rank_in_layer']}, {q(r['dna_source'])})")
w(",\n".join(vals) + ";")
w("""insert into public.onet_dna (soc_code, attribute_code, score, rank_in_layer, is_dominant, dna_source)
select d.soc_code, d.attribute_code, d.score, d.rank_in_layer, d.rank_in_layer <= l.selection_count, d.dna_source
from _dna d
join public.dna_attributes a on a.code = d.attribute_code
join public.dna_layers l on l.code = a.layer_code
on conflict (soc_code, attribute_code) do nothing;""")

w("\n-- 7. Profesi")
w("""insert into public.careers
  (career_name, career_description, description_source, min_education_rank, salary_min, salary_max,
   soc_code, name_en, name_alt, job_zone, relevance, source, is_active, salary_source,
   salary_confidence, curation_note, family_code)
select v.* from (values""")
w(",\n".join(
    f"  ({q(h['nama'])}, {q(h['desk'])}, 'kurasi', {h['rank']}, {h['smin']}::numeric, {h['smax']}::numeric, "
    f"{q(h['soc'])}, {q(h['en'])}, {q(h['alt'])}, {h['jz']}::smallint, 'umum', {q(h['sumber'])}, true, 'estimasi_model', 'low', "
    f"{q(h.get('catatan'))}, {q(h['rumpun'])})" for h in hasil))
w(""") as v(career_name, career_description, description_source, min_education_rank, salary_min, salary_max,
         soc_code, name_en, name_alt, job_zone, relevance, source, is_active, salary_source,
         salary_confidence, curation_note, family_code)
where not exists (select 1 from public.careers c where c.career_name = v.career_name);

-- Kalau file diulang, pastikan profesi baru tetap aktif dan isinya terbaru.
update public.careers c set is_active = true, career_description = v.d, family_code = v.f
from (values""")
w(",\n".join(f"  ({q(h['nama'])}, {q(h['desk'])}, {q(h['rumpun'])})" for h in hasil))
w(") as v(n, d, f) where c.career_name = v.n;")

w("""
create temporary table _baru on commit drop as
select c.id, c.career_name from public.careers c where c.career_name in (""")
w(",\n".join(f"  {q(h['nama'])}" for h in hasil) + ");")
w("""
-- Turunan dihapus dulu lalu diisi ulang, supaya file ini aman diulang.
delete from public.career_sub_industries  where career_id in (select id from _baru);
delete from public.career_industries      where career_id in (select id from _baru);
delete from public.education_career       where career_id in (select id from _baru);
delete from public.career_education_paths where career_id in (select id from _baru);
delete from public.career_licenses        where career_id in (select id from _baru);
delete from public.career_salary_bands    where career_id in (select id from _baru);
delete from public.career_hard_skill_items where career_id in (select id from _baru);
delete from public.career_hard_skills     where career_id in (select id from _baru);
delete from public.career_tools           where career_id in (select id from _baru);""")


def blok(judul, kolom, baris, tabel, kolom_tabel, select):
    w(f"\n-- {judul}")
    w(f"insert into public.{tabel} ({kolom_tabel})")
    w(f"select {select} from (values")
    w(",\n".join(baris))
    w(f") as v({kolom}) join _baru b on b.career_name = v.nama;")


blok("8. Sub-industri", "nama, kode, utama, urut",
     [f"  ({q(h['nama'])}, {q(c)}, {str(u).lower()}, {i + 1})" for h in hasil for i, (c, u) in enumerate(h["sub"])],
     "career_sub_industries", "career_id, sub_industry_code, is_primary, display_order, source, is_verified",
     "b.id, v.kode, v.utama, v.urut, 'kurasi_0047', true")
blok("9. Industri", "nama, kode",
     [f"  ({q(h['nama'])}, {q(i)})" for h in hasil for i in h["inds"]],
     "career_industries", "career_id, industry_code", "b.id, v.kode")
blok("10. Relevansi prodi dan jurusan SMK", "nama, jenis, sid, rel, urut",
     [f"  ({q(h['nama'])}, {q(k)}, {sid}, {rel}, {i + 1})" for h in hasil for i, (k, sid, rel) in enumerate(h["edu"])],
     "education_career", "source_kind, source_id, career_id, relevance, display_order, source, is_verified",
     "v.jenis, v.sid, b.id, v.rel, v.urut, 'kurasi_0047', true")

TAG = {"SMK": ("Buat Kamu yang ingin paling cepat masuk dunia kerja setelah lulus sekolah.", 3, 4, "Pilih Jalur SMK"),
       "SMA": ("Buat Kamu yang ingin langsung mengikuti seleksi dan pendidikan pembentukan setelah lulus sekolah.", 3, 4, "Pilih Jalur Sekolah Menengah"),
       "D3": ("Buat Kamu yang ingin cepat masuk dunia kerja, sambil kuliah alih jenjang S1.", 5, 6, "Pilih Jalur Diploma (D3)"),
       "D4": ("Buat Kamu yang ingin porsi praktik lebih banyak dengan gelar setara Sarjana.", 5, 6, "Pilih Jalur Sarjana Terapan (D4)"),
       "S1": ("Buat Kamu yang ingin mendalami materi lebih luas dan mendalam.", 5, 6, "Pilih Jalur Sarjana (S1)"),
       "S2": ("Setelah S1 Ilmu Hukum, lanjut Magister Kenotariatan lalu magang di kantor notaris.", 7, 9, "Pilih Jalur Magister (S2)")}
baris = []
for h in hasil:
    dipakai = set()
    for i, (jenis, lvl, judul) in enumerate(h["jalur"]):
        # Satu jalur per jenis. Pasangan SMK + D3 mengikuti profesi lama:
        # SMK sebagai VOKASI, D3 sebagai AKADEMIK.
        if jenis in dipakai:
            jenis = "AKADEMIK" if jenis == "VOKASI" else "VOKASI"
        dipakai.add(jenis)
        tag, a, b, cta = TAG[lvl]
        if lvl == "D3" and len(h["jalur"]) > 1 and i > 0:
            tag = "Buat Kamu yang ingin bekal keahlian lebih dalam dan jenjang karier lebih panjang."
        label = "Jalur Akademik" if jenis == "AKADEMIK" and lvl in ("S1", "S2") else f"Jalur {judul}"
        baris.append(f"  ({q(h['nama'])}, {q(jenis)}, {q(lvl)}, {q(judul)}, {q(tag)}, {a}, {b}, {q(cta)}, {q(label)}, {i + 1})")
blok("11. Jalur pendidikan", "nama, jenis, lvl, judul, tag, a, b, cta, label, urut", baris,
     "career_education_paths", "career_id, kind_code, level_code, title_id, tagline_id, years_min, years_max, cta_label_id, table_label_id, display_order",
     "b.id, v.jenis, v.lvl, v.judul, v.tag, v.a, v.b, v.cta, v.label, v.urut")
blok("12. Lisensi", "nama, kode, urut",
     [f"  ({q(h['nama'])}, {q(k)}, {i + 1})" for h in hasil for i, k in enumerate(h["lisensi"])],
     "career_licenses", "career_id, license_code, display_order", "b.id, v.kode, v.urut")

def catatan_pasar(h):
    return (f"jenjang {h['rank']}, job zone {h['jz']}, industri {h['inds'][0]}; "
            "model 0012, ketahanan AI 0027; ditambahkan 0047")


w("\n-- 13. Data pasar (model 0012, ketahanan AI 0027)")
w("insert into public.career_market (career_id, salary_min, salary_max, demand_score, growth_pct, ai_resilience,\n"
  "  source, confidence, as_of_year, note)")
w("select b.id, v.smin, v.smax, v.dem, v.gr, v.ai, 'estimasi_model', 'low', 2025, v.note from (values")
w(",\n".join(
    f"  ({q(h['nama'])}, {h['smin']}, {h['smax']}, {h['demand']}, {h['growth']}, {h['ai']}, "
    f"{q(catatan_pasar(h))})"
    for h in hasil))
w(") as v(nama, smin, smax, dem, gr, ai, note) join _baru b on b.career_name = v.nama")
w("on conflict (career_id) do update set salary_min = excluded.salary_min, salary_max = excluded.salary_max,\n"
  "  demand_score = excluded.demand_score, growth_pct = excluded.growth_pct, ai_resilience = excluded.ai_resilience,\n"
  "  note = excluded.note, updated_at = now();")
blok("14. Pita gaji senioritas (rumus 0027)", "nama, lvl, smin, smax",
     [f"  ({q(h['nama'])}, {q(l)}, {a}, {b})" for h in hasil for l, a, b in h["pita"]],
     "career_salary_bands", "career_id, level_code, salary_min, salary_max", "b.id, v.lvl, v.smin, v.smax")
blok("15. Hard skill item (DWA O*NET)", "nama, kode, imp, urut",
     [f"  ({q(h['nama'])}, {q(d)}, {imp:.2f}, {i + 1})" for h in hasil for i, (imp, d) in enumerate(h["items"])],
     "career_hard_skill_items", "career_id, skill_code, importance, display_order", "b.id, v.kode, v.imp, v.urut")
blok("16. Kemampuan domain dan alat", "nama, kode, urut, src",
     [f"  ({q(h['nama'])}, {q(c)}, {u}, {q('domain_soc' if u < 41 else 'alat_onet')})" for h in hasil for u, c in h["hs"]],
     "career_hard_skills", "career_id, hard_skill_code, display_order, source, is_core", "b.id, v.kode, v.urut, v.src, false")
w("""update public.career_hard_skills chs set is_core = true
from (select career_id, hard_skill_code,
             row_number() over (partition by career_id order by display_order, hard_skill_code) as n
      from public.career_hard_skills where career_id in (select id from _baru)) x
where chs.career_id = x.career_id and chs.hard_skill_code = x.hard_skill_code and x.n <= 3;""")
blok("17. Tools (0028)", "nama, kode, contoh, urut",
     [f"  ({q(h['nama'])}, {q(c)}, {q(e)}, {u})" for h in hasil for c, e, u in h["tools"]],
     "career_tools", "career_id, tool_code, contoh_produk, display_order", "b.id, v.kode, v.contoh, v.urut")

w("\n-- 18. Profesi lama yang ikut mengisi sub-industri tipis (bukan sub-industri utamanya)")
w("insert into public.career_sub_industries (career_id, sub_industry_code, is_primary, display_order, source, is_verified)")
w("select c.id, v.kode, false, 9, 'kurasi_0047', true from (values")
w(",\n".join(f"  ({q(n)}, {q(k)})" for n, k in PB.TAMBAHAN_SUB))
w(") as v(nama, kode) join public.careers c on c.career_name = v.nama and c.is_active")
w("on conflict (career_id, sub_industry_code) do nothing;")

w(f"""
-- 19. Pemeriksaan
do $$
declare n int;
begin
  select count(*) into n from _baru;
  if n <> {len(hasil)} then raise exception '0047: profesi baru % dari {len(hasil)}', n; end if;
  select count(*) into n from _baru b where not exists
    (select 1 from public.career_dna d where d.career_id = b.id and d.is_dominant);
  if n > 0 then raise exception '0047: % profesi baru tanpa DNA', n; end if;
  select count(*) into n from _baru b where not exists
    (select 1 from public.career_sub_industries s where s.career_id = b.id and s.is_primary);
  if n > 0 then raise exception '0047: % profesi baru tanpa sub-industri utama', n; end if;
  select count(*) into n from _baru b where (select count(*) from public.career_hard_skill_items i where i.career_id = b.id) <> 8;
  if n > 0 then raise exception '0047: % profesi baru tanpa 8 hard skill', n; end if;
  raise notice '0047: {len(hasil)} profesi baru siap';
end $$;

commit;""")

out = os.path.join(REPO, "supabase/migrations/0047_profesi_baru_sub_industri_tipis.sql")
open(out, "w").write("\n".join(L) + "\n")
print(out, len(L), "baris; DWA baru", len(dwa_dipakai), "IWA baru", len(iwa_baru), file=sys.stderr)
