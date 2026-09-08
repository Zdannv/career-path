"use client";

/** Pencarian profesi beserta lembar Filters. */

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabaseClient";
import PencarianView from "@/components/profesi/PencarianView";

export default function Page() {
  const router = useRouter();
  const [siap, setSiap] = useState(false);

  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => {
      if (!data.session?.user) {
        router.replace("/login");
        return;
      }
      setSiap(true);
    });
  }, [router]);

  if (!siap) {
    return (
      <div className="flex min-h-[70vh] items-center justify-center">
        <Loader2 className="size-7 animate-spin text-violet-600" aria-hidden />
      </div>
    );
  }

  return <PencarianView />;
}
