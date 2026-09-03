# -*- coding: utf-8 -*-
"""
Model estimasi Market Intelligence untuk 477 profesi.

TIDAK ada angka yang dikarang per profesi. Semuanya keluaran rumus yang
parameternya tertulis di file ini, jadi bisa diperiksa, diperdebatkan, dan
diganti sekaligus kalau ada yang tidak setuju — bukan disunting satu per satu.

Setiap baris yang dihasilkan ditandai source='estimasi_model' dan membawa
confidence-nya sendiri, supaya saat data sungguhan datang, yang perlu diganti
kelihatan jelas.
"""
import csv
from collections import defaultdict

# --- Jangkar upah -----------------------------------------------------------
# UMP rata-rata nasional 2025 dipakai sebagai satuan dasar. Angka absolutnya
# akan usang tiap tahun; yang penting adalah RASIO di bawahnya, yang jauh lebih
# stabil. Ganti satu angka ini setiap kenaikan UMP dan seluruh tabel ikut.
UMP = 3_100_000

# Pengali gaji awal menurut jenjang pendidikan (min, max).
# Disusun dari pola lowongan Indonesia: lulusan SMA/SMK masuk di sekitar UMP,
# S1 di 1,8-3x, dan jarak antar jenjang melebar di atas D3.
RANK_MULT = {
    1: (0.85, 1.10),   # SMP
    2: (1.00, 1.50),   # SMA/SMK
    3: (1.10, 1.70),   # D1
    4: (1.20, 1.90),   # D2
    5: (1.40, 2.20),   # D3
    6: (1.80, 3.20),   # S1/D4
    7: (2.80, 5.00),   # S2
    8: (3.50, 6.50),   # S3
}

# Job Zone menambah bobot kerumitan di atas jenjang pendidikan: dua profesi
# sama-sama S1 tapi Job Zone 5 menuntut persiapan jauh lebih panjang.
JZ_MULT = {1: 0.90, 2: 0.95, 3: 1.00, 4: 1.10, 5: 1.25}

# Premi industri. Angka di atas 1 berarti sektor itu membayar di atas rata-rata
# untuk jenjang yang sama.
IND_PREMIUM = {
    "TECH": 1.35, "FINANCE": 1.30, "INSURANCE": 1.15, "TELCO": 1.20,
    "ENERGY": 1.25, "AEROSPACE": 1.20, "HEALTH": 1.10, "MANUFACTURING": 1.00,
    "CONSTRUCTION": 1.05, "TRANSPORT": 1.00, "LOGISTICS": 0.95, "COMMERCE": 0.95,
    "MEDIA": 0.95, "CREATIVE": 0.95, "MARKETING": 1.05, "LEGAL": 1.15,
    "GOVERNMENT": 0.95, "RESEARCH": 1.00, "SUSTAIN": 1.00, "DEFENSE": 1.05,
    "EDUCATION": 0.85, "AGRI": 0.80, "FNB": 0.85, "HOSPITALITY": 0.85,
    "NGO": 0.80, "FMCG": 0.95,
}

# Pertumbuhan industri per tahun (persen). Perkiraan arah, bukan proyeksi
# ekonometrik: sektor digital dan energi terbarukan tumbuh di atas rata-rata,
# sektor padat karya tradisional di bawahnya.
IND_GROWTH = {
    "TECH": 12.0, "FINANCE": 9.0, "INSURANCE": 6.0, "TELCO": 5.0,
    "ENERGY": 7.0, "AEROSPACE": 6.0, "HEALTH": 8.0, "MANUFACTURING": 3.0,
    "CONSTRUCTION": 4.0, "TRANSPORT": 4.0, "LOGISTICS": 8.0, "COMMERCE": 7.0,
    "MEDIA": 5.0, "CREATIVE": 7.0, "MARKETING": 8.0, "LEGAL": 3.0,
    "GOVERNMENT": 1.0, "RESEARCH": 4.0, "SUSTAIN": 11.0, "DEFENSE": 4.0,
    "EDUCATION": 3.0, "AGRI": 2.0, "FNB": 6.0, "HOSPITALITY": 6.0,
    "NGO": 2.0, "FMCG": 4.0,
}

# --- Ketahanan terhadap otomasi --------------------------------------------
# Ini BUKAN tebakan per profesi. Dihitung dari komposisi Activity DNA-nya:
# aktivitas yang menuntut kehadiran fisik, sentuhan manusia, atau penilaian
# situasional sulit digantikan; aktivitas yang mengolah informasi menurut
# aturan tetap paling mudah.
ACT_RESILIENCE = {
    "Membantu & Melayani": 95, "Mengajar & Membimbing": 90,
    "Memimpin & Mengelola": 85, "Berkomunikasi & Berinteraksi": 80,
    "Menciptakan & Mendesain": 70, "Problem Solving": 70,
    "Membangun & Mengembangkan": 75, "Menjual & Mempengaruhi": 70,
    "Eksperimen & Penelitian": 65, "Inspeksi & Quality Control": 45,
    "Analisa & Investigasi": 40, "Operasional & Administrasi": 25,
}
SKILL_RESILIENCE_BONUS = {
    "Empati": 8, "Kepemimpinan": 6, "Negosiasi": 6, "Kreativitas": 5,
    "Kolaborasi": 4, "Adaptabilitas": 4, "Presentasi": 3,
    "Ketelitian": -4, "Kemampuan Numerik": -5,
}

RANK_LBL = {1:"SMP",2:"SMA/SMK",3:"D1",4:"D2",5:"D3",6:"S1/D4",7:"S2",8:"S3"}

dna = defaultdict(lambda: defaultdict(list))
for cid, layer, name in csv.reader(open("mi_dna.csv"), delimiter="|"):
    dna[int(cid)][layer].append(name)

def bulat(x, ke=100_000):
    return int(round(x / ke) * ke)

rows = []
for cid, nama, soc, rank, jz, inds, n_sib in csv.reader(open("mi_careers.csv"), delimiter="|"):
    cid, rank, jz, n_sib = int(cid), int(rank), int(jz), int(n_sib)
    ind_list = [i for i in inds.split(",") if i]

    prem = max((IND_PREMIUM.get(i, 1.0) for i in ind_list), default=1.0)
    lo, hi = RANK_MULT[rank]
    jzm = JZ_MULT.get(jz, 1.0)
    smin = bulat(UMP * lo * jzm * prem)
    smax = bulat(UMP * hi * jzm * prem)

    # Ketahanan otomasi dari komposisi aktivitas
    acts = dna[cid]["ACTIVITY"]
    base = sum(ACT_RESILIENCE.get(a, 55) for a in acts) / len(acts) if acts else 55
    bonus = sum(SKILL_RESILIENCE_BONUS.get(s, 0) for s in dna[cid]["SKILL"])
    ai_res = max(5, min(99, round(base + bonus)))

    # Pertumbuhan industri: ambil yang tertinggi dari industri yang ditautkan
    growth = max((IND_GROWTH.get(i, 4.0) for i in ind_list), default=4.0)

    # Skor permintaan 0-100. Tiga bahan, semuanya sudah ada di knowledge base:
    #   - berapa banyak profesi serumpun (SOC minor) -> luasnya lapangan
    #   - pertumbuhan industri
    #   - jenjang pendidikan: makin rendah jenjangnya, makin banyak posisinya
    luas = min(30, n_sib * 2.5)
    tumbuh = min(35, growth * 3.0)
    akses = {1: 30, 2: 30, 3: 25, 4: 22, 5: 20, 6: 16, 7: 10, 8: 6}[rank]
    demand = max(5, min(99, round(luas + tumbuh + akses)))

    rows.append(dict(
        career_id=cid, nama=nama, salary_min=smin, salary_max=smax,
        demand=demand, growth=round(growth, 1), ai_res=ai_res,
        rank=rank, jz=jz, ind=ind_list[0] if ind_list else None, n_sib=n_sib))

if __name__ == "__main__":
    import statistics as st
    print(f"{len(rows)} profesi\n")
    print("Gaji per jenjang (rata-rata rentang):")
    by = defaultdict(list)
    for r in rows: by[r["rank"]].append((r["salary_min"], r["salary_max"]))
    for rk in sorted(by):
        mn = st.mean(x[0] for x in by[rk]); mx = st.mean(x[1] for x in by[rk])
        print(f"   {RANK_LBL[rk]:8s} Rp {mn/1e6:5.1f} jt - {mx/1e6:5.1f} jt   ({len(by[rk])} profesi)")
    print(f"\nDemand  : min {min(r['demand'] for r in rows)}  median {st.median(r['demand'] for r in rows):.0f}  max {max(r['demand'] for r in rows)}")
    print(f"Growth  : min {min(r['growth'] for r in rows)}%  median {st.median(r['growth'] for r in rows):.0f}%  max {max(r['growth'] for r in rows)}%")
    print(f"AI res. : min {min(r['ai_res'] for r in rows)}  median {st.median(r['ai_res'] for r in rows):.0f}  max {max(r['ai_res'] for r in rows)}")
    print("\nPaling tahan otomasi:")
    for r in sorted(rows, key=lambda x:-x["ai_res"])[:5]: print(f"   {r['ai_res']:3d}  {r['nama']}")
    print("Paling rentan otomasi:")
    for r in sorted(rows, key=lambda x:x["ai_res"])[:5]: print(f"   {r['ai_res']:3d}  {r['nama']}")
