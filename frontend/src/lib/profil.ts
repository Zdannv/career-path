/**
 * Akses data layar Profile.
 *
 *   profil_state()              isi tab Profile dan Pendidikan
 *   simpan_profil(nama, avatar) tombol Simpan Perubahan di tab Profile
 *   simpan_pendidikan(...)      tombol Simpan Perubahan di tab Pendidikan
 *   notifikasi_state()          isi tab Notifikasi + jumlah yang belum dibaca
 *   tandai_notifikasi_dibaca()  dipanggil saat tab Notifikasi dibuka
 *
 * Avatar tidak lewat RPC: berkasnya diunggah ke Supabase Storage (bucket
 * "avatars"), dan yang disimpan ke profil hanya URL-nya. Nama berkas wajib
 * diawali id pengguna — policy storage memakai folder pertama sebagai penanda
 * pemilik, jadi tanpa itu unggahan ditolak.
 */

import { supabase } from "@/lib/supabaseClient";

export type ProfilState = {
  /** Nama yang benar-benar tersimpan. NULL berarti pengguna belum mengisinya. */
  full_name: string | null;
  /** Nama yang dipakai menyapa: hasil isian, metadata akun, atau tebakan email. */
  nama_tampil: string;
  avatar_url: string | null;
  email: string;
  level_code: string | null;
  level_label: string | null;
  study_label: string | null;
  graduation_status: "sedang_studi" | "sudah_lulus" | null;
  grade_level: number | null;
  semester: number | null;
  is_final_semester: boolean;
  /** true untuk SMP/SMA/SMK (memakai kelas), false untuk jenjang tinggi (semester). */
  pakai_kelas: boolean;
  n_notifikasi_baru: number;
};

export type JenisNotifikasi = "QUEST_MINGGUAN" | "BADGE" | "LEVEL" | "TAHAP";

export type Notifikasi = {
  id: number;
  kind: JenisNotifikasi;
  judul: string;
  isi: string;
  link: string | null;
  waktu: string;
  dibaca: boolean;
  n_baru: number;
};

export async function ambilProfil(): Promise<ProfilState | null> {
  const { data, error } = await supabase.rpc("profil_state").maybeSingle();
  if (error) throw error;
  return (data as ProfilState) ?? null;
}

export async function simpanProfil(nama: string, avatarUrl: string | null): Promise<void> {
  const { error } = await supabase.rpc("simpan_profil", {
    p_nama: nama,
    p_avatar_url: avatarUrl,
  });
  if (error) throw error;
}

export async function simpanPendidikan(v: {
  status: "sedang_studi" | "sudah_lulus";
  kelas: number | null;
  semester: number | null;
  semesterAkhir: boolean;
}): Promise<void> {
  const { error } = await supabase.rpc("simpan_pendidikan", {
    p_status: v.status,
    p_grade: v.kelas,
    p_semester: v.semester,
    p_akhir: v.semesterAkhir,
  });
  if (error) throw error;
}

export async function ambilNotifikasi(): Promise<Notifikasi[]> {
  const { data, error } = await supabase.rpc("notifikasi_state");
  if (error) throw error;
  return (data as Notifikasi[]) ?? [];
}

export async function tandaiNotifikasiDibaca(): Promise<void> {
  await supabase.rpc("tandai_notifikasi_dibaca");
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

/** Batas ukuran berkas. Di atas ini unggahannya lama dan tidak ada gunanya. */
export const MAKS_AVATAR_BYTE = 2 * 1024 * 1024;

const TIPE_AVATAR = ["image/png", "image/jpeg"];

export function periksaAvatar(file: File): string | null {
  if (!TIPE_AVATAR.includes(file.type)) return "Format gambar harus PNG atau JPEG.";
  if (file.size > MAKS_AVATAR_BYTE) return "Ukuran gambar maksimal 2 MB.";
  return null;
}

/**
 * Unggah avatar, kembalikan URL publiknya.
 *
 * Nama berkasnya diberi cap waktu, bukan ditimpa dengan nama tetap: URL lama
 * sudah tersimpan di cache peramban dan CDN Supabase, jadi mengganti isi berkas
 * dengan nama yang sama membuat avatar lama bertahan berjam-jam di layar.
 */
export async function unggahAvatar(file: File): Promise<string> {
  const { data: auth } = await supabase.auth.getUser();
  const uid = auth.user?.id;
  if (!uid) throw new Error("Sesi berakhir. Masuk lagi lalu coba ulang.");

  const ext = file.type === "image/png" ? "png" : "jpg";
  const path = `${uid}/${Date.now()}.${ext}`;

  const { error } = await supabase.storage.from("avatars").upload(path, file, {
    contentType: file.type,
    upsert: false,
  });
  if (error) throw error;

  return supabase.storage.from("avatars").getPublicUrl(path).data.publicUrl;
}

/** Hapus berkas avatar lama. Gagal pun tidak apa-apa — profil sudah tidak menunjuknya. */
export async function hapusAvatarLama(url: string | null): Promise<void> {
  if (!url) return;
  const tanda = "/storage/v1/object/public/avatars/";
  const i = url.indexOf(tanda);
  if (i < 0) return;
  await supabase.storage.from("avatars").remove([url.slice(i + tanda.length)]);
}

/**
 * Avatar bawaan dari tim desain, dipakai selama pengguna belum mengunggah
 * gambarnya sendiri. Sebelumnya dipakai lingkaran berinisial — itu tebakan
 * saya, bukan desain, dan tidak pernah muncul di mockup mana pun.
 */
export const AVATAR_BAWAAN = "/avatar-default.webp";

/** "Reina Putri" → "RP". Masih dipakai sebagai alt text dan cadangan terakhir. */
export function inisial(nama: string | null): string {
  if (!nama) return "N";
  const p = nama.trim().split(/\s+/);
  return ((p[0]?.[0] ?? "") + (p.length > 1 ? (p[p.length - 1][0] ?? "") : "")).toUpperCase() || "N";
}
