import { Suspense } from "react";
import RequireAuth from "@/components/RequireAuth";
import JourneyView from "@/components/journey/JourneyView";

export default function Page() {
  return (
    <RequireAuth>
      {/* useSearchParams menuntut batas Suspense saat halaman dipra-render. */}
      <Suspense fallback={<div className="min-h-screen bg-white" />}>
        <JourneyView />
      </Suspense>
    </RequireAuth>
  );
}
