import { createClient } from "@supabase/supabase-js";

/**
 * Supabase browser client.
 *
 * Both values MUST come from the environment. There are deliberately no
 * fallbacks: a hardcoded fallback key ships to every visitor's browser and
 * ends up committed to git.
 */

function readEnv(name: string, value: string | undefined): string {
  if (!value || !value.trim()) {
    throw new Error(
      `[supabase] ${name} is not set. Copy .env.example to .env.local and fill it in.`
    );
  }
  return value.trim();
}

/** Reads the `role` claim out of a Supabase API key without verifying it. */
function readKeyRole(key: string): string | null {
  const parts = key.split(".");
  if (parts.length !== 3) return null; // publishable (sb_publishable_...) keys are not JWTs
  try {
    const payload = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = payload + "=".repeat((4 - (payload.length % 4)) % 4);
    const json = typeof atob === "function"
      ? atob(padded)
      : Buffer.from(padded, "base64").toString("utf8");
    return (JSON.parse(json) as { role?: string }).role ?? null;
  } catch {
    return null;
  }
}

const supabaseUrl = readEnv(
  "NEXT_PUBLIC_SUPABASE_URL",
  process.env.NEXT_PUBLIC_SUPABASE_URL
)
  .replace(/\/rest\/v1\/?$/, "")
  .replace(/\/$/, "");

const supabaseAnonKey = readEnv(
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
);

const role = readKeyRole(supabaseAnonKey);
if (role && role !== "anon") {
  console.error(
    `[supabase] SECURITY WARNING: NEXT_PUBLIC_SUPABASE_ANON_KEY carries role="${role}". ` +
      `Anything prefixed NEXT_PUBLIC_ is shipped to the browser, and a ` +
      `service_role key bypasses every RLS policy. Use the anon/publishable key.`
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
