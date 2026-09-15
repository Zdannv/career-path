import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen title="Progress" note="Layar progress belum dibangun." />
    </RequireAuth>
  );
}
