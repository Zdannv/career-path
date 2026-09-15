"use client";

/**
 * Penjaga rute untuk layar yang menuntut sesi masuk.
 *
 * Sebelum ini tiap halaman menulis pemeriksaannya sendiri — enam salinan
 * `supabase.auth.getSession()` yang hampir sama tapi tidak persis: sebagian
 * memulangkan ke /login, sebagian tidak memeriksa onboarding sama sekali,
 * sehingga pengguna yang belum onboarding bisa mendarat di Explore dan melihat
 * layar yang datanya setengah.
 *
 * Dua pemeriksaan, berurutan:
 *   1. Tidak ada sesi          -> /login?next=<halaman yang tadi dituju>
 *   2. Onboarding belum tuntas -> /onboarding
 *
 * Keduanya memakai `replace`, bukan `push`: halaman yang ditolak tidak pantas
 * masuk riwayat peramban — tombol "kembali" akan memantulkan pengguna ke sana
 * lagi dan lagi.
 */

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import { sudahOnboarding } from "@/lib/postAuth";
import { ROUTES } from "@/lib/routes";

type Keadaan = "memeriksa" | "boleh";

export default function RequireAuth({
  children,
  /** Career DNA butuh sesi tapi tidak menuntut onboarding tuntas. */
  perluOnboarding = true,
  pesan = "Memeriksa akun…",
}: {
  children: React.ReactNode;
  perluOnboarding?: boolean;
  pesan?: string;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [keadaan, setKeadaan] = useState<Keadaan>("memeriksa");

  useEffect(() => {
    let hidup = true;
    void (async () => {
      const { data } = await supabase.auth.getSession();
      if (!hidup) return;

      const user = data.session?.user;
      if (!user) {
        router.replace(`${ROUTES.login}?next=${encodeURIComponent(pathname)}`);
        return;
      }

      if (perluOnboarding && !(await sudahOnboarding(user.id))) {
        if (!hidup) return;
        router.replace(ROUTES.onboarding);
        return;
      }

      if (hidup) setKeadaan("boleh");
    })();
    return () => {
      hidup = false;
    };
  }, [router, pathname, perluOnboarding]);

  if (keadaan === "memeriksa") {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-3">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
        <p className="text-[12px] font-semibold text-slate-500">{pesan}</p>
      </div>
    );
  }

  return <>{children}</>;
}
