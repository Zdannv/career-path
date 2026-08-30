# -*- coding: utf-8 -*-
"""
Menyiapkan masukan generator roadmap dari O*NET.

Keluarannya bukan teks roadmap jadi, melainkan bahan mentah per profesi:
jenjang target, job zone, lama pengalaman, daftar IWA terurut, alat kerja, dan
profesi lanjutan. Teks Indonesianya dirakit di dalam database oleh 0007 supaya
file migrasinya tetap kecil dan pola kalimatnya bisa diperbaiki di satu tempat.
"""
import os, sys, json, warnings
import pandas as pd

warnings.filterwarnings("ignore")
S = "/mnt/user-data/uploads/Downloads/_onet_tmp/db_30_3_excel"
R = lambda f: pd.read_excel(os.path.join(S, f))

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from iwa_id import IWA_ID, GWA_ID

socs = set(open("/home/claude/rm/socs.txt").read().split())

# --- 1. Jenjang target ------------------------------------------------------
# Kategori "Required Level of Education" O*NET (1-12) -> order_rank Indonesia
# (SMP 1 · SMA/SMK 2 · D1 3 · D2 4 · D3 5 · D4/S1 6 · S2 7 · S3 8).
#
# Associate's degree dipetakan ke D3, bukan D2: keduanya program dua-tiga tahun,
# tapi di Indonesia D3-lah yang jadi jalur vokasi arus utama, dan lowongan yang
# di AS minta associate's di sini praktis selalu minta D3.
#
# Dua kategori Amerika tidak punya padanan langsung dan sengaja TIDAK dipetakan
# ke D1 (rank 3):
#   3 Post-Secondary Certificate -> SMA/SMK (rank 2). Padanan Indonesianya bukan
#     satu tahun kuliah, melainkan SMK plus sertifikat kompetensi — dan sertifikat
#     itu muncul sebagai milestone di roadmap, bukan sebagai jenjang.
#   4 Some College Courses       -> D3 (rank 5). "Kuliah tapi tidak selesai"
#     tidak bisa jadi target roadmap; yang paling dekat dari sisi kualifikasi
#     yang benar-benar diminta pemberi kerja Indonesia adalah D3.
# D1 nyaris tidak dipakai di pasar kerja Indonesia, jadi memilihnya justru
# mengarahkan siswa ke jenjang yang tidak menambah peluang.
RL_TO_RANK = {1: 1, 2: 2, 3: 2, 4: 5, 5: 5, 6: 6, 7: 6, 8: 7, 9: 7, 10: 7, 11: 8, 12: 8}
JZ_TO_RANK = {1: 2, 2: 2, 3: 5, 4: 6, 5: 7}

# Titik tengah tiap kategori, dalam bulan.
RW_MONTHS = {1: 0, 2: 1, 3: 2, 4: 4, 5: 9, 6: 18, 7: 36, 8: 60, 9: 84, 10: 108, 11: 132}
OJ_MONTHS = {1: 0, 2: 1, 3: 2, 4: 4, 5: 9, 6: 18, 7: 36, 8: 84, 9: 132}


def median_category(df):
    """Kategori tempat distribusi kumulatif melewati 50%.

    Dipakai alih-alih modus karena distribusi pendidikan sering bimodal
    (mis. 40% SMA, 45% S1); modus akan melompat liar antar profesi serupa,
    median tidak.
    """
    d = df.sort_values("Category")
    tot = d["Data Value"].sum()
    if tot <= 0:
        return None
    run = 0.0
    for _, r in d.iterrows():
        run += r["Data Value"]
        if run >= tot / 2:
            return int(r["Category"])
    return int(d["Category"].iloc[-1])


print("membaca O*NET ...")
edu = R("Education.xlsx")
te = R("Training and Experience.xlsx")
jz = R("Job Zones.xlsx")
sw = R("Software Skills.xlsx")
rel = R("Related Occupations.xlsx")
tr = R("Task Ratings.xlsx")
t2d = R("Tasks to DWAs.xlsx")
hier = R("GWAs to IWAs to DWAs.xlsx")

imp = tr[tr["Scale ID"] == "IM"][["O*NET-SOC Code", "Task ID", "Data Value"]].rename(
    columns={"Data Value": "imp"}
)
d2i = hier[["DWA Element ID", "IWA Element ID", "GWA Element ID"]].drop_duplicates(
    "DWA Element ID"
)

# Berapa banyak profesi (dari 923 di O*NET) yang menyebut tiap alat.
TOOL_SPREAD = sw.groupby("Workplace Example")["O*NET-SOC Code"].nunique().to_dict()

# GWA yang isinya memimpin/mengelola orang dan sumber daya. Bukan berarti tidak
# penting — hanya bukan pintu masuk profesi.
LEADERSHIP_GWA = {
    "4.A.2.b.4",  # Developing Objectives and Strategies
    "4.A.4.b.1",  # Coordinating the Work and Activities of Others
    "4.A.4.b.2",  # Developing and Building Teams
    "4.A.4.b.4",  # Guiding, Directing, and Motivating Subordinates
    "4.A.4.b.5",  # Coaching and Developing Others
    "4.A.4.c.2",  # Staffing Organizational Units
    "4.A.4.c.3",  # Monitoring and Controlling Resources
}
GWA_OF = dict(zip(hier["IWA Element ID"], hier["GWA Element ID"]))

jz_map = dict(zip(jz["O*NET-SOC Code"], jz["Job Zone"]))
edu_rl = edu[edu["Scale ID"] == "RL"]

rows = []
for soc in sorted(socs):
    z = int(jz_map.get(soc, 3))

    e = edu_rl[edu_rl["O*NET-SOC Code"] == soc]
    cat = median_category(e) if len(e) else None
    target_rank = RL_TO_RANK[cat] if cat else JZ_TO_RANK[z]
    edu_src = "onet_education" if cat else "job_zone"

    def te_months(scale, table):
        x = te[(te["O*NET-SOC Code"] == soc) & (te["Scale ID"] == scale)]
        c = median_category(x) if len(x) else None
        return table[c] if c else None

    exp_m = te_months("RW", RW_MONTHS)
    ojt_m = te_months("OJ", OJ_MONTHS)
    if exp_m is None:  # tanpa data survei: pakai tebakan konservatif dari job zone
        exp_m = {1: 0, 2: 2, 3: 9, 4: 24, 5: 48}[z]
    if ojt_m is None:
        ojt_m = {1: 1, 2: 2, 3: 9, 4: 9, 5: 4}[z]

    # IWA terurut menurut jumlah bobot kepentingan task yang memetakannya.
    td = t2d[t2d["O*NET-SOC Code"] == soc].merge(
        imp[imp["O*NET-SOC Code"] == soc][["Task ID", "imp"]], on="Task ID", how="left"
    )
    td["imp"] = td["imp"].fillna(3.0)
    td = td.merge(d2i, on="DWA Element ID", how="left")
    agg = td.groupby("IWA Element ID")["imp"].sum().sort_values(ascending=False)
    ranked = [(k, round(float(v), 2)) for k, v in agg.items() if k in IWA_ID]

    # Kemampuan memimpin didorong ke belakang, apa pun bobotnya.
    #
    # O*NET mensurvei pemegang jabatan di semua tingkat senioritas, jadi
    # "menyupervisi personel" bisa muncul di peringkat atas untuk profesi yang
    # tidak pernah menyupervisi siapa pun di lima tahun pertama. Menaruhnya di
    # fase FONDASI berarti menyuruh anak SMA berlatih memimpin tim sebelum ia
    # bisa mengerjakan pekerjaannya sendiri.
    lead = [x for x in ranked if GWA_OF.get(x[0]) in LEADERSHIP_GWA]
    rest = [x for x in ranked if GWA_OF.get(x[0]) not in LEADERSHIP_GWA]
    iwas = (rest + lead)[:9]

    # Alat kerja: yang ditandai In Demand, diurutkan dari yang paling khas.
    #
    # Urutan alfabetis tidak berguna di sini — untuk Backend Developer ia
    # memunculkan "C" dan "C#" sebelum AWS dan Kafka. Yang dipakai: makin
    # sedikit profesi lain yang menyebut sebuah alat, makin khas alat itu bagi
    # profesi ini. Alat serba-guna seperti Microsoft Excel otomatis turun
    # karena muncul di ratusan profesi.
    s = sw[(sw["O*NET-SOC Code"] == soc) & (sw["In Demand"] == "Y")]
    cand = list(dict.fromkeys(s["Workplace Example"].dropna()))
    cand.sort(key=lambda t: (TOOL_SPREAD.get(t, 999), t))
    tools = cand[:5]

    # Profesi lanjutan: tier terdekat, hanya yang ada di knowledge base kita.
    rr = rel[
        (rel["O*NET-SOC Code"] == soc)
        & (rel["Relatedness Tier"] == "Primary-Short")
        & (rel["Related O*NET-SOC Code"].isin(socs))
        & (rel["Related O*NET-SOC Code"] != soc)
    ].sort_values("Index")
    nexts = list(dict.fromkeys(rr["Related O*NET-SOC Code"]))[:3]

    rows.append(
        dict(
            soc=soc,
            target_rank=target_rank,
            edu_src=edu_src,
            job_zone=z,
            exp_months=int(exp_m),
            ojt_months=int(ojt_m),
            iwas=iwas,
            tools=tools,
            nexts=nexts,
        )
    )

df = pd.DataFrame(rows)
print("profesi:", len(df))
print("\nsebaran jenjang target:")
print(df["target_rank"].value_counts().sort_index().to_string())
print("\nsumber jenjang:", df["edu_src"].value_counts().to_dict())
print("job zone:", df["job_zone"].value_counts().sort_index().to_dict())
print("\nIWA per profesi: min %d  median %.0f  max %d" % (
    df["iwas"].str.len().min(), df["iwas"].str.len().median(), df["iwas"].str.len().max()))
print("alat kerja: %d profesi punya >=1 (%.0f%%)" % (
    (df["tools"].str.len() > 0).sum(), (df["tools"].str.len() > 0).mean() * 100))
print("profesi lanjutan: %d punya >=1 (%.0f%%)" % (
    (df["nexts"].str.len() > 0).sum(), (df["nexts"].str.len() > 0).mean() * 100))
print("\nlama pengalaman (bulan): median %.0f  p90 %.0f" % (
    df["exp_months"].median(), df["exp_months"].quantile(.9)))

df.to_json("/home/claude/rm/career_inputs.json", orient="records")
print("\n-> career_inputs.json")
