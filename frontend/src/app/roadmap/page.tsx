import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen title="Roadmap" note="Layar roadmap belum dibangun. Datanya sudah ada di knowledge base — 12.496 quest untuk 477 profesi — tinggal tampilannya." />
    </RequireAuth>
  );
}
