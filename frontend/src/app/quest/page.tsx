import RequireAuth from "@/components/RequireAuth";
import QuestView from "@/components/quest/QuestView";

export default function Page() {
  return (
    <RequireAuth>
      <QuestView />
    </RequireAuth>
  );
}
