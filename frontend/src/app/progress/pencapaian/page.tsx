import RequireAuth from "@/components/RequireAuth";
import PencapaianView from "@/components/progress/PencapaianView";

export default function Page() {
  return (
    <RequireAuth pesan="Membuka pencapaian…">
      <PencapaianView />
    </RequireAuth>
  );
}
