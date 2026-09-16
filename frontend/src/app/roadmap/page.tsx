import RequireAuth from "@/components/RequireAuth";
import RoadmapView from "@/components/roadmap/RoadmapView";

export default function Page() {
  return (
    <RequireAuth>
      <RoadmapView />
    </RequireAuth>
  );
}
