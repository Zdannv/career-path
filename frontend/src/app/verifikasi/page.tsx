import React from "react";
import VerifikasiContent from "./VerifikasiContent";

export default async function VerifikasiPage({
  searchParams,
}: {
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}) {
  const raw = (await searchParams).email;
  const email = Array.isArray(raw) ? (raw[0] ?? "") : (raw ?? "");

  return <VerifikasiContent email={email} />;
}
