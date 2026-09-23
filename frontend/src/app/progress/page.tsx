import RequireAuth from "@/components/RequireAuth";
import ProgressView from "@/components/progress/ProgressView";

export default function Page() {
  return (
    <RequireAuth>
      <ProgressView />
    </RequireAuth>
  );
}
