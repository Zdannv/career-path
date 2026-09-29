import RequireAuth from "@/components/RequireAuth";
import ProfilView from "@/components/profil/ProfilView";

export default function Page() {
  return (
    <RequireAuth pesan="Membuka profil…">
      <ProfilView />
    </RequireAuth>
  );
}
