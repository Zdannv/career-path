import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen title="Career Insights" note="Layar Career Insights belum dibangun." />
    </RequireAuth>
  );
}
