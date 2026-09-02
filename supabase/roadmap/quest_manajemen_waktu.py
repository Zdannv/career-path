# -*- coding: utf-8 -*-
"""
Template quest untuk satu atribut Skill DNA: "Manajemen Waktu".

Dibuat sebagai contoh untuk 16 Skill DNA + 12 Activity DNA lainnya. Bentuknya
12 minggu (3 bulan), satu tema per minggu, dan tiap minggu punya empat versi
menurut jenjang penggunanya — karena "atur waktumu" berarti hal yang berbeda
untuk anak SMP dan untuk pekerja.

Kenapa tidak satu teks untuk semua: target pengguna Navika membentang dari SMP
sampai pekerja. Quest yang menyuruh anak SMP "blokir kalender kerjamu" tidak
bisa dikerjakan, dan quest yang menyuruh pekerja "susun jadwal belajar untuk
ulangan" terasa merendahkan. Yang dipertahankan sama di semua jenjang adalah
KETERAMPILAN yang dilatih dan BUKTI yang dikumpulkan; yang berubah konteksnya.

Tipe quest mengikuti daftar tim desain: Learn · Research · Practice · Create ·
Do · Attend.
"""

SKILL = "Manajemen Waktu"
LAYER = "SKILL"
ATTR_CODE = "SKL_WAKTU"          # menyesuaikan dna_attributes.code
DURASI_MINGGU = 12

# Empat jenjang, memakai order_rank education_levels
TIERS = [
    ("SMP", 1, "anak SMP"),
    ("SMA_SMK", 2, "siswa SMA/SMK"),
    ("KAMPUS", 5, "mahasiswa D3-S1"),
    ("PEKERJA", 9, "yang sudah bekerja"),   # 9 = di luar skala, artinya pasca-pendidikan
]

# (minggu, tema, tipe, xp, est_menit, {tier: judul}, {tier: instruksi})
WEEKS = [
    (1, "Sadari ke mana waktumu pergi", "Research", 20, 30,
     {"SMP": "Catat kegiatanmu selama 3 hari",
      "SMA_SMK": "Catat kegiatanmu selama 3 hari",
      "KAMPUS": "Lacak pemakaian waktumu selama 3 hari",
      "PEKERJA": "Lacak pemakaian waktumu selama 3 hari kerja"},
     {"SMP": "Tulis di buku atau HP: jam berapa kamu bangun, sekolah, main HP, belajar, tidur. Cukup tiga hari. Jangan diubah kebiasaannya dulu — cuma dicatat apa adanya.",
      "SMA_SMK": "Catat kegiatanmu per jam selama tiga hari, termasuk waktu main HP dan nongkrong. Belum perlu diperbaiki; tujuannya melihat kenyataannya dulu.",
      "KAMPUS": "Catat pemakaian waktumu per jam selama tiga hari kuliah: kelas, tugas, organisasi, hiburan, tidur. Catat apa adanya, jangan yang seharusnya.",
      "PEKERJA": "Catat pemakaian waktumu per jam selama tiga hari kerja: rapat, kerja fokus, notifikasi, istirahat. Catat apa adanya."}),

    (2, "Kenali pencuri waktu terbesarmu", "Research", 20, 25,
     {"SMP": "Temukan 3 hal yang paling banyak makan waktumu",
      "SMA_SMK": "Temukan 3 hal yang paling banyak makan waktumu",
      "KAMPUS": "Identifikasi 3 sumber kebocoran waktu terbesarmu",
      "PEKERJA": "Identifikasi 3 sumber kebocoran waktu terbesarmu"},
     {"SMP": "Lihat catatan minggu lalu. Tulis tiga kegiatan yang ternyata paling lama padahal tidak penting. Tulis juga kira-kira berapa jam seminggu.",
      "SMA_SMK": "Dari catatan minggu lalu, tandai tiga kegiatan yang paling banyak makan waktu tanpa memberi hasil. Hitung total jamnya per minggu.",
      "KAMPUS": "Dari catatan minggu lalu, tandai tiga kebocoran terbesar dan hitung jam per minggunya. Bedakan mana yang kamu pilih sendiri dan mana yang datang dari luar.",
      "PEKERJA": "Dari catatan minggu lalu, tandai tiga kebocoran terbesar. Pisahkan yang bisa kamu kendalikan sendiri dari yang butuh kesepakatan dengan orang lain."}),

    (3, "Pelajari satu metode, jangan lima", "Learn", 20, 40,
     {"SMP": "Pelajari cara membagi waktu belajar dan istirahat",
      "SMA_SMK": "Pelajari satu metode mengatur waktu",
      "KAMPUS": "Pelajari satu metode manajemen waktu",
      "PEKERJA": "Pelajari satu metode manajemen waktu"},
     {"SMP": "Cari tahu tentang teknik Pomodoro: belajar 25 menit, istirahat 5 menit. Tonton satu video atau baca satu artikel, lalu tulis tiga baris ringkasannya dengan bahasamu sendiri.",
      "SMA_SMK": "Pilih SATU dari Pomodoro, Time Blocking, atau Eat the Frog. Pelajari satu sumber saja, lalu tulis tiga baris ringkasan. Jangan pelajari ketiganya — itu justru membuang waktu.",
      "KAMPUS": "Pilih SATU metode (Pomodoro, Time Blocking, Eisenhower Matrix, Getting Things Done). Baca satu sumber utuh, lalu tulis ringkasan tiga baris beserta alasan memilihnya.",
      "PEKERJA": "Pilih SATU metode yang cocok dengan ritme pekerjaanmu (Time Blocking, Eisenhower Matrix, GTD). Baca satu sumber utuh dan tulis ringkasan tiga baris."}),

    (4, "Coba metodenya seminggu", "Practice", 30, 0,
     {"SMP": "Pakai teknik itu selama 5 hari",
      "SMA_SMK": "Terapkan metode pilihanmu selama 5 hari",
      "KAMPUS": "Terapkan metode pilihanmu selama 5 hari",
      "PEKERJA": "Terapkan metode pilihanmu selama 5 hari kerja"},
     {"SMP": "Pakai Pomodoro tiap kali belajar, lima hari berturut-turut. Beri tanda centang di kalender tiap hari kamu berhasil. Kalau bolong satu hari, lanjutkan saja.",
      "SMA_SMK": "Terapkan metode pilihanmu lima hari berturut-turut. Catat tiap hari: berhasil atau tidak, dan apa yang mengganggu.",
      "KAMPUS": "Terapkan metode pilihanmu lima hari berturut-turut. Catat harian: berapa lama fokus bertahan, dan apa yang memutusnya.",
      "PEKERJA": "Terapkan metode pilihanmu lima hari kerja. Catat harian: berapa blok fokus yang selamat, dan apa yang membatalkannya."}),

    (5, "Pisahkan penting dari mendesak", "Learn", 20, 30,
     {"SMP": "Belajar memilih mana yang dikerjakan dulu",
      "SMA_SMK": "Belajar memilah tugas berdasarkan prioritas",
      "KAMPUS": "Kuasai pemilahan penting vs mendesak",
      "PEKERJA": "Kuasai pemilahan penting vs mendesak"},
     {"SMP": "Tulis semua tugas dan kegiatanmu minggu ini. Beri tanda: mana yang kalau tidak dikerjakan akan bermasalah, dan mana yang cuma terasa mendesak. Kerjakan yang pertama dulu.",
      "SMA_SMK": "Daftar semua tugas minggu ini, lalu bagi ke empat kotak: penting-mendesak, penting-tidak mendesak, tidak penting-mendesak, tidak penting-tidak mendesak.",
      "KAMPUS": "Susun semua kewajiban minggu ini ke dalam Eisenhower Matrix. Perhatikan kotak 'penting tapi tidak mendesak' — biasanya di situlah hal yang paling menentukan masa depan terabaikan.",
      "PEKERJA": "Susun semua pekerjaan minggu ini ke dalam Eisenhower Matrix. Perhatikan kotak 'penting tapi tidak mendesak' — di situ letak pengembangan diri yang selalu tergeser rapat."}),

    (6, "Buat rencana mingguanmu sendiri", "Create", 40, 45,
     {"SMP": "Bikin jadwal mingguan versimu",
      "SMA_SMK": "Bikin jadwal mingguan versimu",
      "KAMPUS": "Susun rencana mingguan dengan blok waktu",
      "PEKERJA": "Susun rencana mingguan dengan blok waktu"},
     {"SMP": "Gambar jadwal satu minggu di kertas atau HP: kapan sekolah, belajar, main, tidur. Sisakan waktu kosong — jadwal yang penuh sesak selalu gagal.",
      "SMA_SMK": "Susun jadwal satu minggu yang memuat sekolah, belajar mandiri, kegiatan, dan istirahat. Sisakan minimal 20% waktu kosong sebagai cadangan.",
      "KAMPUS": "Susun rencana mingguan berbasis blok waktu: kelas, kerja tugas, organisasi, istirahat. Sisakan minimal 20% sebagai cadangan untuk hal tak terduga.",
      "PEKERJA": "Susun rencana mingguan berbasis blok waktu, termasuk blok kerja fokus tanpa gangguan. Sisakan minimal 20% sebagai cadangan."}),

    (7, "Jalankan rencananya", "Do", 40, 0,
     {"SMP": "Ikuti jadwalmu selama seminggu",
      "SMA_SMK": "Jalankan jadwalmu selama seminggu",
      "KAMPUS": "Jalankan rencana mingguanmu",
      "PEKERJA": "Jalankan rencana mingguanmu"},
     {"SMP": "Ikuti jadwal yang kamu buat selama tujuh hari. Tiap malam beri nilai 1-5: seberapa cocok hari ini dengan rencananya.",
      "SMA_SMK": "Jalankan jadwalmu tujuh hari. Tiap malam beri nilai 1-5 kesesuaiannya, dan tulis satu baris penyebab kalau meleset.",
      "KAMPUS": "Jalankan rencanamu tujuh hari. Nilai kesesuaian harian 1-5 dan catat penyebab tiap penyimpangan.",
      "PEKERJA": "Jalankan rencanamu tujuh hari. Nilai kesesuaian harian 1-5 dan catat penyebab tiap penyimpangan."}),

    (8, "Belajar mengatakan tidak", "Practice", 30, 20,
     {"SMP": "Latihan menolak ajakan yang mengganggu jadwalmu",
      "SMA_SMK": "Latihan menolak dengan sopan",
      "KAMPUS": "Latih menolak permintaan yang menabrak prioritasmu",
      "PEKERJA": "Latih menolak permintaan yang menabrak prioritasmu"},
     {"SMP": "Minggu ini, tolak satu ajakan yang tabrakan dengan waktu belajarmu. Boleh dengan bilang 'nanti setelah aku selesai'. Tulis bagaimana rasanya.",
      "SMA_SMK": "Tolak satu permintaan yang tabrakan dengan prioritasmu, dengan sopan dan tanpa berbohong. Tulis kalimat yang kamu pakai dan reaksi orangnya.",
      "KAMPUS": "Tolak satu permintaan yang menabrak prioritasmu. Latih menawarkan alternatif, bukan sekadar menolak. Catat kalimat dan hasilnya.",
      "PEKERJA": "Tolak atau negosiasikan ulang satu permintaan yang menabrak prioritasmu. Tawarkan alternatif waktu atau cakupan. Catat kalimat dan hasilnya."}),

    (9, "Pecah pekerjaan besar", "Practice", 30, 40,
     {"SMP": "Pecah satu tugas besar jadi langkah kecil",
      "SMA_SMK": "Pecah satu tugas besar jadi langkah kecil",
      "KAMPUS": "Pecah satu proyek jadi langkah dengan tenggat sendiri",
      "PEKERJA": "Pecah satu pekerjaan besar jadi langkah dengan tenggat sendiri"},
     {"SMP": "Ambil satu tugas yang terasa berat. Tulis jadi langkah-langkah kecil yang tiap langkahnya selesai dalam 30 menit. Kerjakan satu langkah hari ini.",
      "SMA_SMK": "Ambil satu tugas besar. Pecah jadi langkah yang masing-masing selesai dalam satu jam, beri tenggat tiap langkah, lalu kerjakan yang pertama.",
      "KAMPUS": "Ambil satu proyek atau tugas akhir. Pecah jadi langkah dengan tenggat masing-masing, lalu kerjakan langkah pertama minggu ini.",
      "PEKERJA": "Ambil satu pekerjaan besar yang tertunda. Pecah jadi langkah dengan tenggat masing-masing, lalu kerjakan langkah pertama minggu ini."}),

    (10, "Belajar dari yang sudah jalan", "Attend", 30, 60,
     {"SMP": "Tanya orang yang kamu lihat rapi mengatur waktu",
      "SMA_SMK": "Ikuti satu sesi atau tanya orang yang jam terbangnya lebih tinggi",
      "KAMPUS": "Ikuti satu workshop atau wawancarai seorang praktisi",
      "PEKERJA": "Ikuti satu sesi atau minta masukan dari rekan yang lebih senior"},
     {"SMP": "Tanya satu orang — kakak, guru, atau saudara — bagaimana dia mengatur waktunya. Tulis dua hal yang mau kamu coba.",
      "SMA_SMK": "Ikuti satu sesi (webinar, kelas, video panjang) atau tanya langsung satu orang yang kamu anggap teratur. Tulis dua hal yang mau kamu coba.",
      "KAMPUS": "Ikuti satu workshop manajemen waktu, atau wawancarai seorang praktisi di bidang yang kamu incar soal cara ia mengatur harinya. Tulis dua hal yang mau kamu adopsi.",
      "PEKERJA": "Ikuti satu sesi pelatihan, atau minta 20 menit dari rekan yang kamu anggap paling teratur untuk bertanya caranya. Tulis dua hal yang mau kamu adopsi."}),

    (11, "Perbaiki sistemmu", "Create", 40, 45,
     {"SMP": "Perbaiki jadwalmu berdasarkan pengalaman 10 minggu",
      "SMA_SMK": "Revisi sistemmu berdasarkan yang sudah terbukti",
      "KAMPUS": "Revisi sistemmu berdasarkan data 10 minggu",
      "PEKERJA": "Revisi sistemmu berdasarkan data 10 minggu"},
     {"SMP": "Lihat catatan sepuluh minggu ini. Buat jadwal versi kedua: buang yang tidak pernah jalan, pertahankan yang berhasil.",
      "SMA_SMK": "Susun versi kedua sistemmu. Buang aturan yang tidak pernah kamu ikuti — sistem yang jujur lebih berguna daripada sistem yang ideal.",
      "KAMPUS": "Susun versi kedua sistemmu berdasarkan catatan kesesuaian harian. Buang aturan yang kepatuhannya di bawah separuh.",
      "PEKERJA": "Susun versi kedua sistemmu berdasarkan catatan kesesuaian harian. Buang aturan yang kepatuhannya di bawah separuh."}),

    (12, "Tunjukkan hasilnya", "Create", 50, 60,
     {"SMP": "Buat rangkuman perubahanmu",
      "SMA_SMK": "Buat rangkuman perubahanmu",
      "KAMPUS": "Dokumentasikan hasilnya sebagai bukti kemampuan",
      "PEKERJA": "Dokumentasikan hasilnya sebagai bukti kemampuan"},
     {"SMP": "Bandingkan catatan minggu 1 dengan minggu 11. Tulis apa yang berubah dan satu kebiasaan yang mau kamu pertahankan.",
      "SMA_SMK": "Bandingkan catatan minggu 1 dan minggu 11. Tulis satu halaman: apa yang berubah, apa yang gagal, dan apa yang kamu pertahankan.",
      "KAMPUS": "Susun satu halaman ringkas: kondisi awal, metode yang dipakai, hasil terukur, dan pelajarannya. Ini bisa langsung dipakai saat wawancara kerja.",
      "PEKERJA": "Susun satu halaman ringkas: kondisi awal, metode, hasil terukur, dan pelajarannya. Bisa dipakai untuk penilaian kinerja atau wawancara."}),
]


def rows():
    """Satu baris per (minggu, jenjang) — 12 x 4 = 48 baris."""
    for wk, tema, tipe, xp, menit, judul, instr in WEEKS:
        for tier, rank, _label in TIERS:
            yield dict(minggu=wk, tema=tema, tipe=tipe, xp=xp, est_menit=menit,
                       tier=tier, rank=rank, judul=judul[tier], instruksi=instr[tier])


if __name__ == "__main__":
    rs = list(rows())
    print(f"{SKILL}: {DURASI_MINGGU} minggu x {len(TIERS)} jenjang = {len(rs)} baris quest")
    print(f"total XP per jenjang: {sum(w[3] for w in WEEKS)}")
    from collections import Counter
    print("sebaran tipe:", dict(Counter(w[2] for w in WEEKS)))
