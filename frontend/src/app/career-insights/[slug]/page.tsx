"use client";

/** Insight pertumbuhan satu industri (desain Explore A-E01 .. A-E05). */

import { useParams } from "next/navigation";
import RequireAuth from "@/components/RequireAuth";
import InsightView, { InsightHub } from "@/components/insight/InsightView";
import SoonScreen from "@/components/explore/SoonScreen";
import { insightDari } from "@/lib/insightIndustri";

export default function Page() {
  const params = useParams<{ slug: string }>();
  const slug = params?.slug ?? "";
  // Kartu "Rekomendasi Karier 10 tahun ke depan" sudah ada di Explore, tetapi
  // halamannya belum didesain.
  if (slug === "karier-10-tahun") {
    return (
      <RequireAuth>
        <SoonScreen
          title="Rekomendasi Karier 10 tahun ke depan"
          note="Prediksi karier yang menjanjikan dan minim tergeser teknologi sedang disiapkan tim Navika."
        />
      </RequireAuth>
    );
  }
  const data = insightDari(slug);
  return <RequireAuth>{data ? <InsightView data={data} /> : <InsightHub />}</RequireAuth>;
}
