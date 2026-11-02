import RequireAuth from "@/components/RequireAuth";
import { InsightHub } from "@/components/insight/InsightView";

export default function Page() {
  return (
    <RequireAuth>
      <InsightHub />
    </RequireAuth>
  );
}
