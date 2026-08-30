# -*- coding: utf-8 -*-
"""
Profesi yang di Indonesia butuh izin/registrasi sebelum boleh bekerja.

Ijazah bukan syarat terakhir untuk sebagian profesi. Perawat yang sudah lulus
S1 Keperawatan tetap tidak boleh praktik tanpa STR; guru tanpa sertifikat
pendidik tidak bisa diangkat. Roadmap yang berhenti di kelulusan berhenti tepat
sebelum syarat yang paling menentukan, jadi fase profesional dimulai dengan
mengurus izinnya.

Data ini tidak ada di O*NET — O*NET memetakan lisensi Amerika — jadi daftarnya
disusun manual dari peraturan Indonesia dan wajib diperiksa ulang manusia
sebelum rilis. Aturannya berubah (UU 17/2023 mengubah masa berlaku STR jadi
seumur hidup, misalnya), jadi anggap ini titik awal, bukan rujukan hukum.

Pencocokan:
  * INDUSTRY_LICENSE  -> berdasarkan sektor, menangkap kelompok besar sekaligus
  * PREFIX_LICENSE    -> berdasarkan awalan nama profesi
  * NAME_LICENSE      -> per profesi, menimpa dua aturan di atas
"""

# Sektor -> nama izin. Berlaku untuk semua profesi yang tertaut ke sektor itu,
# kecuali yang disebut di NAME_EXEMPT.
INDUSTRY_LICENSE = {
    "HEALTH": "Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP)",
}

# Awalan nama profesi -> nama izin.
PREFIX_LICENSE = {
    "Guru": "sertifikat pendidik lewat Pendidikan Profesi Guru (PPG)",
    "Dosen": "Nomor Induk Dosen Nasional (NIDN) dan jabatan fungsional",
}

# Per profesi. Menimpa aturan sektor dan awalan.
NAME_LICENSE = {
    "Apoteker": "Surat Tanda Registrasi Apoteker (STRA) dan Surat Izin Praktik Apoteker (SIPA)",
    "Dokter Umum": "Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP) setelah program profesi dan internsip",
    "Dokter Gigi": "Surat Tanda Registrasi (STR) dan Surat Izin Praktik (SIP) setelah program profesi",
    "Arsitek": "Surat Tanda Registrasi Arsitek (STRA) sesuai UU 6/2017",
    "Akuntan Publik": "izin Akuntan Publik dari Kementerian Keuangan setelah ujian CPA",
    "Notaris": "Surat Keputusan pengangkatan Notaris dari Kementerian Hukum",
    "Pengacara / Advokat": "Berita Acara Sumpah Advokat dan kartu anggota organisasi advokat",
    "Pilot": "lisensi penerbang (CPL/ATPL) dari Ditjen Perhubungan Udara",
}

# Profesi di sektor kesehatan yang BUKAN tenaga kesehatan, jadi tidak butuh STR.
NAME_EXEMPT = {
    "Pekarya Kesehatan Jiwa",
    "Health Informatics Specialist",
    "Manajer Layanan Kesehatan",
    "Staf Administrasi Rumah Sakit",
    "Petugas Kebersihan Rumah Sakit",
}


def license_for(career_name: str, industries: set[str]) -> str | None:
    if career_name in NAME_LICENSE:
        return NAME_LICENSE[career_name]
    if career_name in NAME_EXEMPT:
        return None
    for prefix, lic in PREFIX_LICENSE.items():
        if career_name == prefix or career_name.startswith(prefix + " "):
            return lic
    for ind, lic in INDUSTRY_LICENSE.items():
        if ind in industries:
            return lic
    return None
