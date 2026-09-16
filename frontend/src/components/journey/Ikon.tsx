/**
 * Ikon yang namanya datang dari database.
 *
 * journey_stage_items dan dna_attribute_visual menyimpan nama ikon lucide
 * sebagai teks. Memakai `import * as lucide` lalu mengindeksnya akan menarik
 * seluruh pustaka ikon ke dalam bundel, jadi yang dipakai didaftarkan satu per
 * satu di sini. Nama yang tidak terdaftar jatuh ke Sparkles, bukan kosong.
 */

import {
  BookOpenCheck,
  Brain,
  BriefcaseBusiness,
  Building2,
  Calculator,
  CalendarClock,
  CalendarRange,
  ClipboardList,
  Crown,
  FileBadge,
  FlaskConical,
  GitBranch,
  GraduationCap,
  Hammer,
  Handshake,
  HeartHandshake,
  Lightbulb,
  Megaphone,
  MessageCircle,
  MessagesSquare,
  Palette,
  Presentation,
  Puzzle,
  ScanEye,
  ScanSearch,
  Search,
  Shuffle,
  Sigma,
  Sparkles,
  Timer,
  TrendingUp,
  ShieldAlert,
  UserRoundCog,
  Users,
  type LucideIcon,
} from "lucide-react";

const PETA: Record<string, LucideIcon> = {
  BookOpenCheck,
  Brain,
  BriefcaseBusiness,
  Building2,
  Calculator,
  CalendarClock,
  CalendarRange,
  ClipboardList,
  Crown,
  FileBadge,
  FlaskConical,
  GitBranch,
  GraduationCap,
  Hammer,
  Handshake,
  HeartHandshake,
  Lightbulb,
  Megaphone,
  MessageCircle,
  MessagesSquare,
  Palette,
  Presentation,
  Puzzle,
  ScanEye,
  ScanSearch,
  Search,
  ShieldAlert,
  Shuffle,
  Sigma,
  Sparkles,
  Timer,
  TrendingUp,
  UserRoundCog,
  Users,
};

export default function Ikon({ nama, className }: { nama: string; className?: string }) {
  const Komponen = PETA[nama] ?? Sparkles;
  return <Komponen className={className} aria-hidden />;
}
