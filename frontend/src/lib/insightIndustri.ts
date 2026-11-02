/**
 * Isi halaman Insight Pertumbuhan Industri (desain Explore A-E01 .. A-E05).
 *
 * Teks dan angkanya dari tim desain, ditranskripsi dari ekspor Figma
 * 2 November 2026. Tiga kesalahan salin di desain diperbaiki di sini:
 *   - Teknologi: deskripsi Software Engineer sama persis dengan Data Center
 *     Engineer, dan isi "Keamanan dan perlindungan data" sama persis dengan
 *     "Kebutuhan analisis data". Keduanya ditulis ulang sesuai judulnya.
 *   - Hospitality: seksi "Travel & Tour Services" muncul dua kali; cukup sekali.
 *
 * Statistik dan sumbernya ditulis apa adanya dari desain. Kalau angkanya
 * diperbarui, cukup ubah file ini.
 */

export type IkonInsight =
  | "pembayaran" | "bank" | "hotel" | "wisata" | "makanan" | "acara" | "bangunan"
  | "kawasan" | "properti" | "rute" | "katalog" | "operasional" | "data" | "proyek"
  | "grafik" | "tim" | "rekrut" | "awan" | "ai" | "dokumen" | "perisai" | "transformasi";

export type ProfesiInsight = {
  nama: string;
  deskripsi: string;
  /** Kisaran gaji dari desain; diganti data Navika kalau profesinya ditemukan. */
  gaji: string;
  /** Nama profesi Navika yang setara, kalau namanya berbeda dari desain. */
  navika?: string;
};

export type StatistikInsight =
  | { jenis: "batang"; judul: string; catatan?: string; items: { nilai: number; label: string }[]; sumber: string }
  | { jenis: "angka"; judul: string; items: { nilai: string; label: string }[]; sumber: string };

export type SeksiInsight = {
  ikon: IkonInsight;
  nama: string;
  cakupan: string;
  isi: string;
  profesi: ProfesiInsight[];
};

export type Insight = {
  slug: string;
  industri: string;
  gambar: string;
  judul: string;
  lead: string;
  statistik: StatistikInsight;
  peluang?: { pengantar: string[]; alasan: { ikon: IkonInsight; judul: string; isi?: string }[] };
  seksi: SeksiInsight[];
  /** Untuk halaman yang daftar profesinya tidak dibagi per seksi. */
  profesi?: ProfesiInsight[];
};

const P = (nama: string, deskripsi: string, gaji: string, navika?: string): ProfesiInsight => ({ nama, deskripsi, gaji, navika });

export const INSIGHT: Insight[] = [
  {
    slug: "hospitality-pariwisata",
    industri: "Hospitality & Pariwisata",
    gambar: "/insight/hospitality-pariwisata.webp",
    judul: "Berdampak dalam kebutuhan tenaga kerja di banyak sektor bisnis",
    lead:
      "Pertumbuhan sektor ini dapat menciptakan kebutuhan tenaga kerja di banyak jenis bisnis, mulai dari hotel, restoran, dan agen perjalanan hingga event, transportasi wisata, dan pengelolaan destinasi.",
    statistik: {
      jenis: "angka",
      judul: "Seberapa besar pertumbuhan industrinya?",
      items: [
        { nilai: "+5,71%", label: "Kunjungan wisatawan mancanegara" },
        { nilai: "Rp39,68 T", label: "Investasi pariwisata (Semester I - 2026)" },
        { nilai: "25,91 juta", label: "Tenaga kerja pariwisata (Sepanjang 2025)" },
        { nilai: "1.858", label: "Tenaga kerja baru" },
      ],
      sumber: "Kementerian Koordinator Bidang Perekonomian dan Kementerian Pariwisata.",
    },
    seksi: [
      {
        ikon: "hotel",
        nama: "Hotel & Accommodation",
        cakupan: "Hotel, resort, villa, serviced apartment",
        isi:
          "Ketika jumlah tamu dan tingkat hunian meningkat, hotel perlu memastikan kapasitas layanan, kebersihan kamar, makanan, reservasi, dan pengalaman tamu tetap terjaga. Pembukaan hotel baru juga bisa menciptakan kebutuhan tenaga kerja tambahan.",
        profesi: [
          P("Housekeeping Supervisor", "Bertanggung jawab atas kebersihan, kerapian, dan estetika seluruh kamar.", "Rp 3,5-5 Juta"),
          P("Front Desk Agent", "Menyambut tamu, melayani proses check-in/check-out, dan memberi informasi.", "Rp 4-6 Juta", "Front Office / Resepsionis Hotel"),
          P("Concierge", "Membantu tamu memesan tiket, transportasi, dan memberikan rekomendasi wisata.", "Rp 4-7 Juta"),
        ],
      },
      {
        ikon: "wisata",
        nama: "Travel & Tour Services",
        cakupan: "Travel agency, tour operator, travel platform",
        isi:
          "Pertumbuhan perjalanan mendorong kebutuhan untuk merancang paket wisata, mengatur reservasi, mengelola itinerary, serta membantu pelanggan menangani perubahan jadwal dan kebutuhan perjalanan.",
        profesi: [
          P("Tour Planner", "Merancang rute, jadwal, dan menyusun anggaran paket wisata secara detail.", "Rp 3,5-5 Juta"),
          P("Travel Operations", "Mengurus logistik, transportasi, dan memastikan jadwal tur berjalan lancar.", "Rp 4-6 Juta"),
          P("Tour Guide", "Memandu wisatawan secara langsung serta menjelaskan sejarah dan budaya lokal.", "Rp 4-7 Juta"),
        ],
      },
      {
        ikon: "makanan",
        nama: "Food & Beverage",
        cakupan: "Restoran, kafe, katering, Hotel food service",
        isi:
          "Peningkatan aktivitas restoran, hotel, dan destinasi wisata dapat menambah kebutuhan tenaga dapur, pelayanan, pengadaan bahan, dan pengawasan operasional. Namun, pertumbuhan bisnis makanan dan minuman tidak selalu berasal dari pariwisata saja.",
        profesi: [
          P("Chef", "Memimpin dapur, menciptakan resep, dan memasak hidangan berkualitas tinggi.", "Rp 3,5-5 Juta"),
          P("Pastry Chef", "Spesialis yang membuat roti, kue, cokelat, dan hidangan penutup manis.", "Rp 4-6 Juta"),
          P("Food Service Operations Specialist", "Mengoptimalkan sistem distribusi, alur kerja dapur, dan efisiensi kuliner.", "Rp 4-7 Juta"),
        ],
      },
      {
        ikon: "acara",
        nama: "Event & MICE",
        cakupan: "Meeting, Incentive, Convention, Exhibition, Seminar, podcast off-air.",
        isi:
          "Konferensi, pameran, pertemuan perusahaan, dan acara berskala besar membutuhkan pengelolaan venue, vendor, logistik, peserta, serta pelaksanaan acara. Kebutuhan biasanya mengikuti jadwal proyek dan musim acara.",
        profesi: [
          P("Exhibition Organizer", "Merancang, memasarkan, dan mengelola jalannya pameran atau konvensi.", "Rp 3,5-5 Juta"),
          P("Event Marketing Specialist", "Mempromosikan acara untuk menarik sponsor, peserta, dan pengunjung.", "Rp 4-6 Juta"),
          P("Event Coordinator", "Mengatur logistik, jadwal, dan vendor teknis demi kelancaran acara.", "Rp 4-7 Juta"),
        ],
      },
    ],
  },
  {
    slug: "konstruksi-properti",
    industri: "Konstruksi & Properti",
    gambar: "/insight/konstruksi-properti.webp",
    judul: "Pertumbuhan Konstruksi Didukung Ekspansi Infrastruktur dan Kawasan Industri",
    lead:
      "Data BPS menunjukkan sektor konstruksi tumbuh 6,68% secara tahunan pada Q2 2026, didukung aktivitas pembangunan infrastruktur, belanja modal, dan pengembangan kawasan industri. Sementara itu, sektor real estat tumbuh 3,64% pada kuartal yang sama. Pertumbuhan ini membuka potensi kebutuhan talenta di bidang teknik sipil, manajemen proyek, serta teknologi konstruksi.",
    statistik: {
      jenis: "batang",
      judul: "Growth YoY indikator industri",
      catatan: "Q2 2026 dibandingkan Q2 2025",
      items: [
        { nilai: 6.68, label: "Konstruksi" },
        { nilai: 3.64, label: "Properti" },
      ],
      sumber: "BPS, data PDB sektoral Q2 2026.",
    },
    peluang: {
      pengantar: [
        "Hubungannya tidak hanya satu langkah. Satu proyek pembangunan dapat membutuhkan beberapa kelompok tenaga kerja sekaligus.",
        "Hal di bawah ini menjelaskan mekanisme potensial penciptaan kerja, bukan bukti bahwa seluruh profesi mengalami pertumbuhan lowongan.",
      ],
      alasan: [
        { ikon: "proyek", judul: "Proyek dan investasi bertambah", isi: "Pengembangan infrastruktur, kawasan industri, dan bangunan" },
        { ikon: "grafik", judul: "Kebutuhan pelaksanaan meningkat", isi: "Perencanaan, desain, pengadaan material, dan pekerjaan lapangan." },
        { ikon: "tim", judul: "Banyak fungsi terlibat", isi: "Engineer, drafter, estimator, pengawas, HSE, dan manajer proyek." },
        { ikon: "rekrut", judul: "Muncul kebutuhan perekrutan", isi: "Kontraktor, konsultan, pengembang, dan pemasok merekrut sesuai kebutuhan proyek." },
      ],
    },
    seksi: [
      {
        ikon: "bangunan",
        nama: "Infrastruktur & Konstruksi Sipil",
        cakupan: "General Contractor, Konsultan, dan Developer.",
        isi:
          "Pembangunan jalan, jembatan, irigasi, gedung, dan fasilitas publik membutuhkan tenaga untuk merencanakan, mengawasi, serta memastikan pekerjaan memenuhi standar teknis dan target waktu.",
        profesi: [
          P("Civil Engineer", "Merancang, menghitung struktur, dan mengawasi pembangunan infrastruktur.", "Rp 3,5-5 Juta"),
          P("Site Engineer", "Mengawasi teknis pelaksanaan, jadwal, dan operasional harian di proyek.", "Rp 4-6 Juta"),
          P("HSE Officer", "Memastikan keselamatan kerja, kesehatan karyawan, dan kepatuhan lingkungan.", "Rp 4-7 Juta", "HSE Engineer"),
        ],
      },
      {
        ikon: "kawasan",
        nama: "Kawasan Industri & Bangunan Komersial",
        cakupan: "Building Contractor, Commercial Developers, Kontraktor Fit-Out & Interior, Facility Management.",
        isi:
          "Pengembangan kawasan industri, gudang, pabrik, dan gedung komersial membutuhkan pembangunan fasilitas, instalasi utilitas, serta pemeliharaan aset. Ekspansi kawasan industri menjadi salah satu pendorong pertumbuhan konstruksi pada Q2 2026.",
        profesi: [
          P("Project Engineer", "Menjembatani aspek teknis, manajemen, dan koordinasi harian tim proyek.", "Rp 3,5-5 Juta"),
          P("MEP Engineer", "Merancang dan mengawasi sistem listrik, AC, pipa air, serta proteksi gedung.", "Rp 4-6 Juta"),
          P("Construction Planner", "Menyusun jadwal kerja, metode pelaksanaan, dan alokasi durasi proyek.", "Rp 4-7 Juta"),
        ],
      },
      {
        ikon: "properti",
        nama: "Penjualan Properti",
        cakupan: "Property Developer, Brokerage, Property Marketplace & PropTech.",
        isi:
          "Meski penjualan rumah belum sepenuhnya pulih, perusahaan tetap membutuhkan tenaga untuk memasarkan unit, mengelola calon pembeli, menyewakan properti, dan mengembangkan hubungan dengan investor.",
        profesi: [
          P("Broker Properti", "Menjembatani transaksi, negosiasi, dan legalitas antara penjual dan pembeli.", "Rp 3,5-5 Juta"),
          P("Agen Properti", "Membantu pemilik atau pengembang memasarkan, menyewakan, dan menjual properti.", "Rp 4-6 Juta"),
          P("Penilai Properti", "Menaksir nilai pasar wajar suatu properti secara independen dan legal.", "Rp 4-7 Juta"),
        ],
      },
    ],
  },
  {
    slug: "perbankan-fintech",
    industri: "Perbankan & Fintech",
    gambar: "/insight/perbankan-fintech.webp",
    judul: "Transformasi layanan keuangan membuka peluang karier baru",
    lead:
      "Digitalisasi transaksi, pembayaran elektronik, pembiayaan digital, dan pemanfaatan data mendorong perubahan kebutuhan tenaga kerja di sektor keuangan.",
    statistik: {
      jenis: "batang",
      judul: "Growth YoY indikator industri",
      items: [
        { nilai: 36.88, label: "Pembayaran Digital" },
        { nilai: 31.39, label: "Digital Banking" },
        { nilai: 25.88, label: "Digital Lending" },
      ],
      sumber: "Bank Indonesia & OJK",
    },
    seksi: [
      {
        ikon: "pembayaran",
        nama: "Pembayaran Digital",
        cakupan: "E-wallet, payment gateway, QRIS, payment infrastructure",
        isi:
          "Perluasan transaksi nontunai dan penerimaan pembayaran digital membuka ruang inovasi bagi penyedia layanan pembayaran. Bank Indonesia juga melaporkan peningkatan aktivitas pembayaran digital sepanjang 2025.",
        profesi: [
          P("Payment Operations", "Memastikan transaksi pembayaran digital berjalan lancar dan akurat.", "Rp 15-20 Juta"),
          P("Fraud Analyst", "Mendeteksi pola transaksi mencurigakan untuk mencegah penipuan.", "Rp 15-20 Juta", "Fraud Investigator"),
          P("Product Manager", "Merencanakan dan mengembangkan produk sesuai kebutuhan pengguna.", "Rp 15-20 Juta"),
        ],
      },
      {
        ikon: "bank",
        nama: "Digital Banking",
        cakupan: "Mobile banking, neobanking, layanan bank berbasis digital",
        isi:
          "Perpindahan layanan ke kanal digital mendorong kebutuhan akan pengalaman pengguna yang baik, infrastruktur yang andal, keamanan, dan analisis perilaku nasabah.",
        profesi: [
          P("Digital Banking Analyst", "Menganalisis layanan perbankan digital untuk meningkatkan kinerja.", "Rp 15-20 Juta"),
          P("Cybersecurity Analyst", "Melindungi sistem dan data dari ancaman serta serangan siber.", "Rp 15-20 Juta"),
        ],
      },
      {
        ikon: "bank",
        nama: "Digital Lending",
        cakupan: "P2P lending, pembiayaan UMKM, kredit digital",
        isi:
          "OJK melaporkan outstanding pembiayaan fintech P2P lending mencapai Rp96,62 triliun pada Desember 2025, tumbuh 25,44% secara tahunan.",
        profesi: [
          P("Credit Risk Analyst", "Menganalisis risiko kredit untuk membantu keputusan pemberian pinjaman.", "Rp 15-20 Juta", "Analis Kredit"),
          P("Data Analyst", "Mengolah dan menganalisis data untuk mendukung keputusan bisnis.", "Rp 15-20 Juta"),
        ],
      },
    ],
  },
  {
    slug: "retail-ecommerce",
    industri: "Retail & E-Commerce",
    gambar: "/insight/retail-ecommerce.webp",
    judul: "Ekspansi bisnis digital membuka kebutuhan talenta baru",
    lead:
      "Jumlah usaha e-commerce di Indonesia meningkat, dan semakin banyak bisnis memanfaatkan kanal digital untuk menjangkau pelanggan, mengelola penjualan, dan bersaing di pasar online.",
    statistik: {
      jenis: "batang",
      judul: "Growth YoY indikator industri",
      items: [
        { nilai: 29.4, label: "e-commerce" },
        { nilai: 1.1, label: "Retail" },
      ],
      sumber: "Bank Indonesia & kompas.co.id",
    },
    peluang: {
      pengantar: [],
      alasan: [
        { ikon: "rute", judul: "Persaingan mendapatkan pelanggan: kebutuhan marketing, campaign, dan analisis performa penjualan meningkat." },
        { ikon: "katalog", judul: "Katalog dan kanal penjualan bertambah: bisnis membutuhkan pengelolaan produk, marketplace, harga, dan promosi." },
        { ikon: "operasional", judul: "Operasional semakin kompleks: pengelolaan stok, pesanan, distribusi, dan retur memerlukan koordinasi yang baik." },
        { ikon: "data", judul: "Keputusan berbasis data: perusahaan membutuhkan analisis perilaku konsumen dan performa penjualan untuk menentukan strategi." },
      ],
    },
    seksi: [],
    profesi: [
      P("Digital Marketing Specialist", "Menjalankan kampanye digital untuk meningkatkan jangkauan, kunjungan, dan konversi penjualan.", "Rp 15-20 Juta", "Digital Marketing Analyst"),
      P("E-Commerce Analyst", "Menganalisis penjualan, perilaku pelanggan, dan performa marketplace untuk mendukung keputusan bisnis.", "Rp 15-20 Juta"),
      P("Supply Chain Analyst", "Mengoptimalkan stok, alur distribusi, dan ketersediaan produk agar operasional lebih efisien.", "Rp 15-20 Juta"),
      P("Product Manager", "Mengembangkan fitur dan pengalaman belanja digital berdasarkan kebutuhan pengguna dan target bisnis.", "Rp 15-20 Juta"),
    ],
  },
  {
    slug: "teknologi-ai",
    industri: "Teknologi Informasi & AI",
    gambar: "/insight/teknologi-ai.webp",
    judul: "Adopsi AI dan ekspansi layanan digital meningkatkan kebutuhan keterampilan teknologi",
    lead:
      "Perusahaan tidak hanya membutuhkan pengembang aplikasi, tetapi juga talenta yang mampu mengelola data, mengintegrasikan AI, menjaga infrastruktur, dan melindungi sistem digital.",
    statistik: {
      jenis: "angka",
      judul: "Seberapa besar pertumbuhan industrinya?",
      items: [
        { nilai: "+6,97%", label: "Industri growth Q2 2026" },
        { nilai: "69%", label: "AI Skill Demand secara global" },
      ],
      sumber: "Kementerian Keuangan dan PwC AI Jobs Barometer 2026",
    },
    peluang: {
      pengantar: [
        "Terdapat lima faktor pendukung yang bisa dijadikan pendorong industri, yang sejalan dengan arah pengembangan ekosistem digital pemerintah Indonesia, termasuk investasi data center, cloud, AI, dan pengembangan talenta digital.",
      ],
      alasan: [
        { ikon: "awan", judul: "Investasi infrastruktur digital", isi: "Indonesia terus mengembangkan data center, cloud computing, jaringan, dan infrastruktur komputasi. Infrastruktur ini diperlukan untuk menjalankan aplikasi digital dan layanan AI dalam skala besar." },
        { ikon: "ai", judul: "Adopsi AI dalam proses bisnis", isi: "Perusahaan mulai memanfaatkan AI untuk layanan pelanggan, pemrosesan dokumen, analisis data, pencarian informasi, dan otomatisasi tugas." },
        { ikon: "dokumen", judul: "Kebutuhan analisis data", isi: "Perusahaan membutuhkan data yang akurat untuk memahami pelanggan, mengukur kinerja, memprediksi permintaan, dan menentukan strategi. Sistem AI pun memerlukan data yang terkelola dengan baik." },
        { ikon: "perisai", judul: "Keamanan dan perlindungan data", isi: "Makin banyak layanan dan data yang berpindah ke sistem digital, makin besar pula risiko serangan siber. Perusahaan membutuhkan talenta yang mampu menjaga keamanan sistem dan mematuhi aturan perlindungan data pribadi." },
        { ikon: "transformasi", judul: "Transformasi digital lintas industri", isi: "Perbankan, kesehatan, manufaktur, retail, dan logistik membutuhkan solusi digital untuk memperbaiki proses bisnis. Artinya, peluang teknologi tidak hanya berada di perusahaan teknologi, tetapi juga di perusahaan dari sektor lain." },
      ],
    },
    seksi: [],
    profesi: [
      P("Software Engineer", "Merancang, membangun, dan memelihara aplikasi serta sistem perangkat lunak.", "Rp 15-20 Juta"),
      P("Business Analyst", "Menganalisis data bisnis untuk memberikan solusi dan strategi perusahaan.", "Rp 15-20 Juta", "IT Business Analyst"),
      P("AI Security Specialist", "Melindungi sistem kecerdasan buatan dari ancaman siber dan manipulasi data.", "Rp 15-20 Juta"),
      P("Data Center Engineer", "Merawat, mengawasi, dan menjaga keandalan infrastruktur fisik server data.", "Rp 15-20 Juta"),
    ],
  },
];

export const insightDari = (slug: string) => INSIGHT.find((i) => i.slug === slug) ?? null;
