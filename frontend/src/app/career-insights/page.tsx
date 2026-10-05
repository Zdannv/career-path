import RequireAuth from "@/components/RequireAuth";
import SoonScreen from "@/components/explore/SoonScreen";

export default function Page() {
  return (
    <RequireAuth>
      <SoonScreen
        title="Artikel & Tips"
        note="Isi artikelnya sedang disiapkan tim Navika. Banner di Explore sudah mengarah ke sini, jadi begitu artikelnya siap, tidak ada tautan yang perlu diubah."
      />
    </RequireAuth>
  );
}
