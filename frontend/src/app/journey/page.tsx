import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen title="Journey" note="Layar journey belum dibangun." />
    </RequireAuth>
  );
}
