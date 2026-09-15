import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen
        title="Daftar Profesi"
        note="Halaman daftar lengkap untuk baris ini belum dibangun. Sementara ini, geser kartunya langsung di Explore, atau pakai pencarian berfilter."
      />
    </RequireAuth>
  );
}
