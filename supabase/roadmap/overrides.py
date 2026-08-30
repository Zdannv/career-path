# -*- coding: utf-8 -*-
"""
Koreksi jenjang target untuk profesi yang jenjang minimumnya diatur hukum
Indonesia, atau yang jelas meleset saat diturunkan dari data survei Amerika.

Kenapa perlu: `target_rank` diturunkan dari distribusi "Required Level of
Education" O*NET, yang menggambarkan pasar kerja Amerika. Untuk sebagian besar
profesi hasilnya justru lebih akurat daripada tebakan berbasis Job Zone —
teknisi dan operator di Indonesia memang masuk lewat SMK, bukan D3. Tapi ada
dua kelompok yang selalu salah:

  1. Profesi berizin. Undang-undang Indonesia menetapkan lantai jenjangnya,
     berapa pun yang lazim di Amerika. Meleset di sini bukan sekadar kurang
     tepat — roadmap-nya mengarahkan siswa ke jalur yang tidak bisa dipakai
     mendaftar STR/izin praktik.
  2. Peran entry-level yang di Amerika sudah tersaring gelar. "IT Support"
     di sana lulusan S1; di sini SMK TKJ dan D3 adalah pintu masuk normal.

Setiap baris menyebut dasarnya. Yang tidak ada di sini dibiarkan apa adanya dan
ditandai is_curated = false.

rank: SMP 1 · SMA/SMK 2 · D1 3 · D2 4 · D3 5 · D4/S1 6 · S2 7 · S3 8
"""

# career_name -> (target_rank, alasan)
EDUCATION_OVERRIDES = {
    # --- Tenaga kesehatan: UU 17/2023 tentang Kesehatan mensyaratkan minimal
    #     D3 untuk tenaga kesehatan (kecuali asisten tenaga kesehatan). -------
    "Tenaga Teknis Kefarmasian": (5, "UU 17/2023 & PP 51/2009: tenaga teknis kefarmasian minimal D3 Farmasi."),
    "Refraksionis Optisien": (5, "Permenkes 19/2013: refraksionis optisien minimal D3 Refraksi Optisi, wajib STR."),
    "Refraksionis Optisien (Asisten Oftalmologi)": (5, "Permenkes 19/2013: minimal D3 Refraksi Optisi, wajib STR."),
    "Teknolog Oftalmik": (5, "Tenaga kesehatan berizin; jalur formalnya D3 Refraksi Optisi/Teknologi Oftalmik."),
    "Flebotomis": (5, "Praktik flebotomi masuk ranah ATLM (D3 Teknologi Laboratorium Medik), wajib STR."),
    "Paramedis Veteriner": (5, "Permentan 3/2019: paramedik veteriner minimal D3 Kesehatan Hewan."),
    "Bidan": (5, "UU 4/2019 tentang Kebidanan: bidan vokasi minimal D3 Kebidanan."),
    "Sitoteknologis": (6, "Tenaga laboratorium sitologi; jalur formalnya S1/D4 Teknologi Laboratorium Medik."),

    # --- Guru: UU 14/2005 tentang Guru dan Dosen, pasal 9 — kualifikasi
    #     akademik minimum S1/D4 untuk semua jenjang, termasuk PAUD. ----------
    "Guru PAUD": (6, "UU 14/2005 pasal 9: guru wajib berkualifikasi minimal S1/D4, termasuk jenjang PAUD."),
    "Guru Pengganti": (6, "UU 14/2005 pasal 9: kualifikasi guru minimal S1/D4, tidak dibedakan untuk guru pengganti."),

    # --- Peran manajerial yang tersaring gelar di Indonesia ------------------
    "Manajer Produksi": (6, "Lowongan manajer produksi di Indonesia praktis selalu mensyaratkan S1 Teknik/Industri."),
    "Manajer Instalasi PLTS": (5, "Peran penyelia teknis bersertifikat; jalur masuknya D3 Teknik Elektro ke atas."),
    "QC Analyst": (5, "Peran analis laboratorium QC di Indonesia lazimnya D3/S1 Kimia atau Analis Kesehatan."),
    "Auditor Energi": (5, "Sertifikasi auditor energi (SKKNI) mensyaratkan latar teknik minimal D3."),

    # --- Peran entry-level yang kelewat tinggi kalau ikut data Amerika -------
    "IT Support / Helpdesk": (5, "Di Indonesia pintu masuknya SMK TKJ atau D3 Informatika, bukan S1."),
    "Pekarya Kesehatan Jiwa": (2, "Pekarya adalah tenaga penunjang non-nakes; jenjangnya SMA/SMK."),
    "Staff Cargo": (2, "Peran operasional bandara/pelabuhan; pintu masuknya SMA/SMK."),
    "Staff Freight Forwarding": (2, "Peran operasional; SMA/SMK dengan sertifikat kepabeanan sudah cukup untuk masuk."),
}
