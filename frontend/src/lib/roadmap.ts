/**
 * Roadmap karier: baca template, mulai roadmap, centang aktivitas.
 *
 * Template (roadmap_*) berstatus public-read lewat RLS, jadi bisa diintip
 * tanpa login — berguna untuk halaman detail profesi. Roadmap dan progres
 * pengguna (user_roadmaps, user_roadmap_activities, xp_ledger) hanya terlihat
 * oleh pemiliknya; RLS yang mengurus, jadi tidak ada filter user_id di sini.
 *
 * Yang sengaja TIDAK ada di file ini: penambahan XP. XP ditulis oleh trigger
 * database saat aktivitas dicentang, bukan oleh client — supaya angkanya tidak
 * bisa dikarang dari browser.
 */

import { supabase } from "@/lib/supabaseClient";

export type StageKind =
  | "SEKOLAH"
  | "KULIAH"
  | "FONDASI"
  | "PENGALAMAN"
  | "PROFESIONAL"
  | "LANJUT";

export type ActivityKind = "RISET" | "BELAJAR" | "PRAKTIK" | "BUKTI" | "ADMIN";

export type RoadmapActivity = {
  activity_id: number;
  activity_order: number;
  kind: ActivityKind;
  name: string;
  description: string | null;
  xp: number;
  est_hours: number | null;
  /** null = belum disentuh. */
  status: "SELESAI" | "DILEWATI" | null;
  completed_at: string | null;
};

export type RoadmapMilestone = {
  milestone_id: number;
  milestone_order: number;
  name: string;
  description: string | null;
  skill_area_code: string | null;
  activities: RoadmapActivity[];
};

export type RoadmapStage = {
  stage_id: number;
  stage_order: number;
  kind: StageKind;
  name: string;
  description: string | null;
  est_months: number | null;
  milestones: RoadmapMilestone[];
};

export type RoadmapProgress = {
  user_roadmap_id: number;
  career_id: number;
  status: "AKTIF" | "JEDA" | "SELESAI" | "DITINGGALKAN";
  total_activities: number;
  done_activities: number;
  percent_done: number;
  xp_earned: number;
};

/** Satu baris datar dari view roadmap_full / user_roadmap_stages. */
type FlatRow = {
  stage_id: number;
  stage_order: number;
  stage_kind: StageKind;
  stage_name: string;
  stage_description: string | null;
  stage_est_months: number | null;
  milestone_id: number;
  milestone_order: number;
  milestone_name: string;
  milestone_description: string | null;
  skill_area_code: string | null;
  activity_id: number;
  activity_order: number;
  activity_kind: ActivityKind;
  activity_name: string;
  activity_description: string | null;
  xp: number;
  est_hours: number | null;
  activity_status?: "SELESAI" | "DILEWATI" | null;
  completed_at?: string | null;
};

/**
 * Kedua view mengembalikan satu baris per aktivitas. Merakitnya jadi pohon di
 * sini, bukan dengan tiga query bersarang, supaya satu roadmap = satu
 * round-trip.
 */
function nest(rows: FlatRow[]): RoadmapStage[] {
  const stages = new Map<number, RoadmapStage>();
  const milestones = new Map<number, RoadmapMilestone>();

  for (const r of rows) {
    let stage = stages.get(r.stage_id);
    if (!stage) {
      stage = {
        stage_id: r.stage_id,
        stage_order: r.stage_order,
        kind: r.stage_kind,
        name: r.stage_name,
        description: r.stage_description,
        est_months: r.stage_est_months,
        milestones: [],
      };
      stages.set(r.stage_id, stage);
    }

    let ms = milestones.get(r.milestone_id);
    if (!ms) {
      ms = {
        milestone_id: r.milestone_id,
        milestone_order: r.milestone_order,
        name: r.milestone_name,
        description: r.milestone_description,
        skill_area_code: r.skill_area_code,
        activities: [],
      };
      milestones.set(r.milestone_id, ms);
      stage.milestones.push(ms);
    }

    ms.activities.push({
      activity_id: r.activity_id,
      activity_order: r.activity_order,
      kind: r.activity_kind,
      name: r.activity_name,
      description: r.activity_description,
      xp: r.xp,
      est_hours: r.est_hours,
      status: r.activity_status ?? null,
      completed_at: r.completed_at ?? null,
    });
  }

  const out = [...stages.values()].sort((a, b) => a.stage_order - b.stage_order);
  for (const s of out) {
    s.milestones.sort((a, b) => a.milestone_order - b.milestone_order);
    for (const m of s.milestones) {
      m.activities.sort((a, b) => a.activity_order - b.activity_order);
    }
  }
  return out;
}

/**
 * Roadmap sebuah profesi apa adanya, tanpa konteks pengguna.
 *
 * Semua fase ikut terbawa, termasuk yang mungkin sudah dilewati pengguna —
 * ini untuk halaman "seperti apa jalannya", bukan untuk halaman progres.
 */
export async function getCareerRoadmap(careerId: number): Promise<RoadmapStage[]> {
  const { data, error } = await supabase
    .from("roadmap_full")
    .select("*")
    .eq("career_id", careerId)
    .order("stage_order")
    .order("milestone_order")
    .order("activity_order");

  if (error) throw error;
  return nest((data ?? []) as FlatRow[]);
}

/**
 * Roadmap pengguna: fase yang sudah dilewati jenjang pendidikannya sudah
 * disaring oleh view, dan tiap aktivitas membawa status centangnya.
 */
export async function getMyRoadmap(userRoadmapId: number): Promise<RoadmapStage[]> {
  const { data, error } = await supabase
    .from("user_roadmap_stages")
    .select("*")
    .eq("user_roadmap_id", userRoadmapId)
    .order("stage_order")
    .order("milestone_order")
    .order("activity_order");

  if (error) throw error;
  return nest((data ?? []) as FlatRow[]);
}

/**
 * Membuat roadmap untuk profesi ini, atau mengembalikan yang sudah ada.
 *
 * Lewat RPC, bukan insert langsung: pemilihan template dan pembekuan jenjang
 * awal pengguna adalah aturan domain yang harus sama untuk semua pemanggil.
 */
export async function startRoadmap(careerId: number): Promise<number> {
  const { data, error } = await supabase.rpc("start_roadmap", { p_career_id: careerId });
  if (error) throw error;
  return data as number;
}

export async function getMyRoadmapList(): Promise<RoadmapProgress[]> {
  const { data, error } = await supabase
    .from("user_roadmap_progress")
    .select("user_roadmap_id, career_id, status, total_activities, done_activities, percent_done, xp_earned");
  if (error) throw error;
  return (data ?? []) as RoadmapProgress[];
}

export async function getRoadmapProgress(userRoadmapId: number): Promise<RoadmapProgress | null> {
  const { data, error } = await supabase
    .from("user_roadmap_progress")
    .select("user_roadmap_id, career_id, status, total_activities, done_activities, percent_done, xp_earned")
    .eq("user_roadmap_id", userRoadmapId)
    .maybeSingle();
  if (error) throw error;
  return (data as RoadmapProgress) ?? null;
}

/**
 * Mencentang aktivitas. `status` 'DILEWATI' untuk yang sengaja dilompati —
 * dihitung sebagai sudah ditangani tapi tidak memberi XP.
 */
export async function completeActivity(
  userRoadmapId: number,
  activityId: number,
  status: "SELESAI" | "DILEWATI" = "SELESAI",
  note?: string,
): Promise<void> {
  const { data: auth } = await supabase.auth.getUser();
  const userId = auth.user?.id;
  if (!userId) throw new Error("completeActivity: butuh pengguna yang login");

  const { error } = await supabase.from("user_roadmap_activities").upsert(
    {
      user_id: userId,
      user_roadmap_id: userRoadmapId,
      activity_id: activityId,
      status,
      note: note ?? null,
    },
    { onConflict: "user_roadmap_id,activity_id" },
  );
  if (error) throw error;
}

/**
 * Membatalkan centang.
 *
 * XP yang sudah diberikan TIDAK ditarik: xp_ledger adalah buku besar, dan
 * baris yang sudah tercatat tidak dihapus. Mencentang ulang aktivitas yang
 * sama juga tidak menambah XP lagi (dijaga indeks unik parsial di database),
 * jadi tidak ada celah centang-batal-centang untuk menggandakan poin.
 */
export async function uncompleteActivity(
  userRoadmapId: number,
  activityId: number,
): Promise<void> {
  const { error } = await supabase
    .from("user_roadmap_activities")
    .delete()
    .eq("user_roadmap_id", userRoadmapId)
    .eq("activity_id", activityId);
  if (error) throw error;
}

export async function getTotalXp(): Promise<number> {
  const { data, error } = await supabase.from("xp_ledger").select("xp");
  if (error) throw error;
  return (data ?? []).reduce((sum, r) => sum + (r.xp as number), 0);
}
