/**
 * Kotak biru "Yang Akan Kamu Dapatkan" di kaki tiap tahap Journey.
 *
 * Isinya janji hasil belajar tahap ini — ditulis di journey_outcomes dan
 * disesuaikan nama profesinya di database, bukan dirakit di sini.
 */

import { Check } from "lucide-react";

export default function HasilBox({ hasil }: { hasil: string[] }) {
  if (!hasil.length) return null;
  return (
    <section className="rounded-2xl bg-blue-600 px-5 py-5 text-white">
      <h2 className="text-[17px] font-bold tracking-tight">Yang Akan Kamu Dapatkan</h2>
      <ul className="mt-3.5 space-y-3">
        {hasil.map((h) => (
          <li key={h} className="flex items-start gap-2.5">
            <Check className="mt-0.5 size-4 shrink-0 text-white" aria-hidden />
            <span className="text-[13.5px] leading-relaxed text-blue-50">{h}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
