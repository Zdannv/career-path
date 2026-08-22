/**
 * Seluruh pertanyaan onboarding CareerPath, dalam satu tempat.
 *
 * Dibagi per langkah sesuai IA. Tiap langkah menandai ke mana jawabannya pergi:
 *
 *   profile   -> tabel profiles, dipakai untuk membentuk roadmap
 *   sector    -> filter bidang, bukan RIASEC
 *   riasec    -> tes minat, satu-satunya input matching berbasis minat
 *   skills    -> CBF dan skill gap
 *   context   -> intensitas dan biaya roadmap
 *   goal      -> percabangan: sudah punya cita-cita atau belum
 *
 * Skor RIASEC untuk sisi profesi TIDAK diukur di sini — sudah tersedia dari
 * O*NET lewat view `career_riasec`. Yang diukur cuma sisi user.
 */

export type StepPurpose =
  | "profile" | "sector" | "riasec" | "subjects" | "skills" | "experience" | "context" | "goal";

export type Question =
  | { kind: "text"; id: string; label: string; placeholder?: string; required?: boolean }
  | { kind: "date"; id: string; label: string; required?: boolean }
  | { kind: "single"; id: string; label: string; hint?: string; options: Option[]; required?: boolean }
  | { kind: "multi"; id: string; label: string; hint?: string; options: Option[]; max?: number; allowCustom?: boolean }
  | { kind: "likert"; id: string; label: string; riasec: RiasecCode; interestArea?: string; tier: "core" | "extended" };

export type Option = { value: string; label: string; sublabel?: string };
export type RiasecCode = "R" | "I" | "A" | "S" | "E" | "C";

export type Step = {
  id: string;
  title: string;
  subtitle?: string;
  purpose: StepPurpose;
  questions: Question[];
};

// ─────────────────────────────────────────────────────────────────────────────
// Skala Likert untuk tes minat
// ─────────────────────────────────────────────────────────────────────────────

export const LIKERT_PROMPT = "Seberapa tertarik kamu melakukan hal ini?";

export const LIKERT_SCALE: { value: number; label: string }[] = [
  { value: 1, label: "Sangat tidak tertarik" },
  { value: 2, label: "Tidak tertarik" },
  { value: 3, label: "Biasa saja" },
  { value: 4, label: "Tertarik" },
  { value: 5, label: "Sangat tertarik" },
];

// ─────────────────────────────────────────────────────────────────────────────
// Bank soal minat — 18 item, 3 per tipe
//
// 6 item `core` (nomor 1 tiap tipe) ditanyakan di onboarding.
// 12 item `extended` menyusul lewat "Lengkapi profilmu" di dashboard.
//
// `interestArea` mencatat area minat O*NET yang diwakili item. Itu yang
// menjaga pemetaannya tetap sah — kalimatnya boleh diubah, areanya jangan.
//
// Catatan: item C1 soal coding sengaja masuk Conventional, bukan Investigative.
// O*NET mengklasifikasikan Information Technology di bawah Conventional, dan
// vektor user harus memakai definisi yang sama dengan vektor profesi.
// ─────────────────────────────────────────────────────────────────────────────

export const RIASEC_ITEMS: Extract<Question, { kind: "likert" }>[] = [
  // --- core: satu per tipe, ditanyakan saat onboarding
  { kind: "likert", id: "R1", riasec: "R", tier: "core", interestArea: "Mechanics/Electronics",
    label: "Merakit atau memperbaiki perangkat elektronik — komputer, robot, atau alat listrik." },
  { kind: "likert", id: "I1", riasec: "I", tier: "core",
    label: "Menelusuri penyebab sebuah masalah sampai ketemu akarnya." },
  { kind: "likert", id: "A1", riasec: "A", tier: "core", interestArea: "Applied Arts and Design",
    label: "Merancang tampilan visual — poster, ilustrasi, atau antarmuka aplikasi." },
  { kind: "likert", id: "S1", riasec: "S", tier: "core", interestArea: "Teaching/Education",
    label: "Menjelaskan sesuatu ke teman sampai dia benar-benar paham." },
  { kind: "likert", id: "E1", riasec: "E", tier: "core", interestArea: "Management/Administration",
    label: "Memimpin sebuah tim atau kegiatan." },
  { kind: "likert", id: "C1", riasec: "C", tier: "core", interestArea: "Information Technology",
    label: "Menulis atau merapikan kode program supaya jalan sesuai aturan." },

  // --- extended: pendalaman
  { kind: "likert", id: "R2", riasec: "R", tier: "extended", interestArea: "Engineering",
    label: "Menguji apakah sebuah alat atau mesin benar-benar bekerja seperti yang dirancang." },
  { kind: "likert", id: "I2", riasec: "I", tier: "extended", interestArea: "Mathematics/Statistics",
    label: "Mengolah data atau angka untuk menemukan pola yang tersembunyi." },
  { kind: "likert", id: "A2", riasec: "A", tier: "extended", interestArea: "Media / Creative Writing",
    label: "Membuat konten kreatif seperti video, tulisan, atau musik." },
  { kind: "likert", id: "S2", riasec: "S", tier: "extended", interestArea: "Social Service",
    label: "Menemani atau membantu orang yang sedang kesulitan." },
  { kind: "likert", id: "E2", riasec: "E", tier: "extended", interestArea: "Public Speaking / Sales",
    label: "Meyakinkan orang lain supaya setuju dengan ideku." },
  { kind: "likert", id: "C2", riasec: "C", tier: "extended", interestArea: "Office Work / Accounting",
    label: "Menyusun data atau catatan supaya rapi dan mudah dicari." },
  { kind: "likert", id: "R3", riasec: "R", tier: "extended", interestArea: "Physical/Manual Labor",
    label: "Mengerjakan sesuatu dengan tangan sampai jadi barang yang bisa dipegang." },
  { kind: "likert", id: "I3", riasec: "I", tier: "extended", interestArea: "Physical / Life Science",
    label: "Mencari tahu cara kerja sesuatu, walaupun tidak ada yang menyuruh." },
  { kind: "likert", id: "A3", riasec: "A", tier: "extended",
    label: "Mengerjakan tugas dengan caraku sendiri daripada mengikuti contoh yang sudah ada." },
  { kind: "likert", id: "S3", riasec: "S", tier: "extended",
    label: "Bekerja dalam kelompok dan memastikan semua anggotanya nyaman." },
  { kind: "likert", id: "E3", riasec: "E", tier: "extended", interestArea: "Business Initiatives",
    label: "Memikirkan ide usaha atau produk yang bisa dijual." },
  { kind: "likert", id: "C3", riasec: "C", tier: "extended",
    label: "Mengecek pekerjaan berulang kali supaya tidak ada yang terlewat." },
];

export const CORE_ITEMS = RIASEC_ITEMS.filter((i) => i.tier === "core");
export const EXTENDED_ITEMS = RIASEC_ITEMS.filter((i) => i.tier === "extended");

// ─────────────────────────────────────────────────────────────────────────────
// Alur onboarding
// ─────────────────────────────────────────────────────────────────────────────

export const ONBOARDING_STEPS: Step[] = [
  {
    id: "identitas",
    title: "Kenalan dulu",
    subtitle: "Biar kami bisa menyapamu dengan benar.",
    purpose: "profile",
    questions: [
      { kind: "text", id: "full_name", label: "Nama kamu", placeholder: "Nama panggilan juga boleh", required: true },
      { kind: "date", id: "date_of_birth", label: "Tanggal lahir", required: true },
      { kind: "text", id: "city", label: "Kota tempat tinggal", placeholder: "Contoh: Surabaya", required: true },
    ],
  },

  {
    id: "pendidikan",
    title: "Pendidikan kamu sekarang",
    subtitle: "Ini menentukan bentuk roadmap yang akan kamu jalani.",
    purpose: "profile",
    questions: [
      {
        kind: "single", id: "education_level", label: "Jenjang pendidikan saat ini", required: true,
        options: [
          { value: "SMP", label: "SMP / MTs", sublabel: "Sekolah menengah pertama" },
          { value: "SMA", label: "SMA / MA", sublabel: "Sekolah menengah atas" },
          { value: "SMK", label: "SMK / MAK", sublabel: "Sekolah menengah kejuruan" },
          { value: "KULIAH", label: "Kuliah", sublabel: "D3, D4, atau S1" },
          { value: "FRESH_GRAD", label: "Fresh graduate", sublabel: "Baru lulus, belum bekerja" },
        ],
      },
      {
        kind: "single", id: "grade", label: "Kelas atau semester", required: true,
        hint: "Pilihannya menyesuaikan jenjang yang kamu pilih.",
        options: [], // diisi runtime dari education_level
      },
      {
        kind: "single", id: "target_graduation_year", label: "Perkiraan tahun lulus", required: true,
        hint: "Kami hitungkan otomatis, ubah kalau tidak sesuai.",
        options: [], // diisi runtime: tahun sekarang + sisa jenjang
      },
    ],
  },

  {
    id: "bidang",
    title: "Bidang apa yang menarik buat kamu?",
    subtitle: "Pilih maksimal 3. Ini bukan keputusan akhir — cuma titik awal.",
    purpose: "sector",
    questions: [
      {
        kind: "multi", id: "sectors", label: "Bidang yang menarik", max: 3,
        options: [
          { value: "TECH", label: "Teknologi" },
          { value: "DESIGN", label: "Desain & Kreatif" },
          { value: "BUSINESS", label: "Bisnis & Wirausaha" },
          { value: "HEALTH", label: "Kesehatan" },
          { value: "EDUCATION", label: "Pendidikan" },
          { value: "SCIENCE", label: "Sains & Riset" },
        ],
      },
    ],
  },

  {
    id: "minat",
    title: "Hal-hal yang kamu suka",
    subtitle:
      "Enam pertanyaan, tidak ada jawaban benar atau salah. Jawab sesuai yang kamu rasakan sekarang — " +
      "nanti bisa diubah kapan saja.",
    purpose: "riasec",
    questions: CORE_ITEMS,
  },

  {
    id: "pelajaran",
    title: "Pelajaran yang kamu kuasai",
    subtitle: "Pilih maksimal 3 yang menurutmu paling kamu bisa.",
    purpose: "subjects",
    questions: [
      {
        kind: "multi", id: "subjects", label: "Mata pelajaran", max: 3, allowCustom: true,
        options: [
          { value: "MTK", label: "Matematika" },
          { value: "FISIKA", label: "Fisika" },
          { value: "KIMIA", label: "Kimia" },
          { value: "BIOLOGI", label: "Biologi" },
          { value: "TIK", label: "Informatika / TIK" },
          { value: "BINGGRIS", label: "Bahasa Inggris" },
          { value: "BINDO", label: "Bahasa Indonesia" },
          { value: "SENI", label: "Seni & Desain" },
          { value: "EKONOMI", label: "Ekonomi" },
          { value: "SOSIAL", label: "IPS / Sosiologi" },
        ],
      },
    ],
  },

  {
    id: "skill",
    title: "Skill yang sudah kamu punya",
    subtitle: "Boleh dilewati kalau belum ada. Ini normal, apalagi kalau kamu masih SMP atau SMA.",
    purpose: "skills",
    questions: [
      {
        kind: "multi", id: "skills", label: "Skill atau tools yang pernah kamu pakai", allowCustom: true,
        hint: "Ketik sendiri kalau tidak ada di daftar.",
        options: [], // diisi runtime dari tabel skills, difilter oleh `sectors`
      },
    ],
  },

  {
    id: "pengalaman",
    title: "Pengalaman yang pernah kamu jalani",
    subtitle: "Pilih semua yang pernah kamu lakukan.",
    purpose: "experience",
    questions: [
      {
        kind: "multi", id: "experiences", label: "Pengalaman",
        options: [
          { value: "PROJECT", label: "Membuat karya atau proyek sendiri" },
          { value: "ORG", label: "Aktif di organisasi atau ekstrakurikuler" },
          { value: "COMPETITION", label: "Ikut atau menang lomba" },
          { value: "INTERNSHIP", label: "Magang / PKL" },
          { value: "FREELANCE", label: "Kerja lepas atau dibayar orang" },
          { value: "NONE", label: "Belum ada" },
        ],
      },
    ],
  },

  {
    id: "konteks",
    title: "Seberapa besar yang bisa kamu investasikan?",
    subtitle: "Ini yang menentukan seberapa padat roadmap kamu nanti.",
    purpose: "context",
    questions: [
      {
        kind: "single", id: "weekly_hours", label: "Waktu belajar per minggu", required: true,
        options: [
          { value: "LT2", label: "Kurang dari 2 jam" },
          { value: "2_5", label: "2 – 5 jam" },
          { value: "5_10", label: "5 – 10 jam" },
          { value: "GT10", label: "Lebih dari 10 jam" },
        ],
      },
      {
        kind: "single", id: "monthly_budget", label: "Budget belajar per bulan", required: true,
        hint: "Banyak jalur bisa ditempuh tanpa biaya. Jawaban ini tidak membatasi pilihan profesimu.",
        options: [
          { value: "FREE", label: "Gratis saja" },
          { value: "LT100K", label: "Di bawah Rp100.000" },
          { value: "100K_500K", label: "Rp100.000 – Rp500.000" },
          { value: "GT500K", label: "Di atas Rp500.000" },
        ],
      },
    ],
  },

  {
    id: "goal",
    title: "Sudah punya cita-cita profesi?",
    purpose: "goal",
    questions: [
      {
        kind: "single", id: "has_career_goal", label: "Pilih salah satu", required: true,
        options: [
          { value: "YES", label: "Sudah, aku tahu mau jadi apa", sublabel: "Kami langsung buatkan roadmapnya" },
          { value: "NO", label: "Belum, bantu aku cari", sublabel: "Kami tunjukkan profesi yang cocok dengan minatmu" },
        ],
      },
    ],
  },
];

export const CORE_STEP_COUNT = ONBOARDING_STEPS.length;
