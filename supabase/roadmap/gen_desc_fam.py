# -*- coding: utf-8 -*-
"""
Deskripsi profesi berbahasa Indonesia untuk 443 profesi yang masih berteks
O*NET, plus rumpun untuk 456 profesi yang belum punya.

Deskripsinya dirakit dari data yang sudah berbahasa Indonesia — capaian inti
(IWA yang sudah diterjemahkan), Activity DNA, Environment DNA, dan jenjang
pendidikan — bukan diterjemahkan kalimat per kalimat. Hasilnya lebih seragam
daripada terjemahan bebas, dan yang lebih penting: bisa dibuat untuk semua 477
sekaligus, dan bisa diperbaiki serentak kalau polanya kurang enak dibaca.

34 profesi yang deskripsinya sudah bahasa Indonesia tidak disentuh.
"""
import csv
from collections import defaultdict

RANK_FRASE = {
    1: "Umumnya terbuka untuk lulusan SMP",
    2: "Umumnya terbuka untuk lulusan SMA/SMK",
    3: "Umumnya menuntut pendidikan D1",
    4: "Umumnya menuntut pendidikan D2",
    5: "Umumnya menuntut pendidikan D3",
    6: "Umumnya menuntut pendidikan S1 atau D4",
    7: "Umumnya menuntut pendidikan S2",
    8: "Umumnya menuntut pendidikan S3",
}
ENV_FRASE = {
    "Kantor": "di lingkungan kantor", "Remote": "secara jarak jauh",
    "Hybrid": "dengan pola hybrid", "Onsite": "langsung di lokasi kerja",
    "Laboratorium": "di laboratorium", "Pelayanan Kesehatan": "di fasilitas layanan kesehatan",
    "Institusi Pendidikan": "di lingkungan sekolah atau kampus", "Pabrik": "di lingkungan pabrik",
}

def lower1(s):
    """Turunkan huruf awal tiap penggalan, dan ganti '&' jadi 'dan'.

    Nama atribut DNA ditulis Judul Kapital ("Membangun & Mengembangkan").
    Menurunkan huruf pertama saja meninggalkan "membangun & Mengembangkan"
    yang janggal di tengah kalimat.
    """
    if not s: return s
    out=[]
    for bagian in s.split(" & "):
        out.append(bagian[0].lower()+bagian[1:] if bagian else bagian)
    return " dan ".join(out)

def rangkai(items, akhiran="dan"):
    items=[x for x in items if x]
    if not items: return ""
    if len(items)==1: return items[0]
    if len(items)==2: return f"{items[0]} {akhiran} {items[1]}"
    return ", ".join(items[:-1]) + f", {akhiran} " + items[-1]

def deskripsi(nama, rank, acts, envs, iwas):
    inti = [lower1(x) for x in iwas[:3]]
    k1 = f"Pekerjaan yang berfokus pada {rangkai(inti)}." if inti else \
         f"Pekerjaan di bidang {rangkai([lower1(a) for a in acts[:2]])}."
    k2 = ""
    if acts:
        k2 = f" Kesehariannya banyak diisi kegiatan {rangkai([lower1(a) for a in acts[:3]], 'serta')}."
    k3 = ""
    if envs:
        lokasi = rangkai([ENV_FRASE.get(e, f"di {lower1(e)}") for e in envs[:2]], "maupun")
        k3 = f" Biasanya dijalankan {lokasi}."
    k4 = f" {RANK_FRASE.get(rank,'')}."
    return (k1+k2+k3+k4).replace("..",".").strip()

rows=[]; per_soc=defaultdict(list)
for cid, nama, socmin, rank, acts, envs, ints, iwas, is_en in csv.reader(open("desc_in.csv"),delimiter="|"):
    rec=dict(id=int(cid), nama=nama, socmin=socmin, rank=int(rank),
             acts=[x for x in acts.split(";") if x], envs=[x for x in envs.split(";") if x],
             ints=[x for x in ints.split(";") if x], iwas=[x for x in iwas.split(";") if x],
             is_en=is_en=="1")
    rows.append(rec); per_soc[socmin].append(rec)

if __name__=="__main__":
    n=sum(1 for r in rows if r["is_en"])
    print(f"{n} deskripsi akan diganti, {len(rows)-n} dibiarkan\n")
    for r in rows[:3]:
        if r["is_en"]:
            print(f"### {r['nama']}\n  {deskripsi(r['nama'],r['rank'],r['acts'],r['envs'],r['iwas'])}\n")
    print(f"kandidat rumpun dari SOC minor: {len([s for s,v in per_soc.items() if len(v)>1])} grup "
          f"berisi {sum(len(v) for v in per_soc.values() if len(v)>1)} profesi, "
          f"{len([s for s,v in per_soc.items() if len(v)==1])} profesi tunggal")
