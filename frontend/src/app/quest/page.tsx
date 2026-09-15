import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen title="Quest" note="Layar quest belum dibangun. Daftar quest mingguanmu sudah bisa dilihat di Explore." />
    </RequireAuth>
  );
}
