import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Supabase browser client.
 *
 * Both values MUST come from the environment. There are deliberately no
 * fallbacks: a hardcoded fallback key ships to every visitor's browser and
 * ends up committed to git.
 *
 * The client is created on first use rather than at import time. Navbar sits in
 * the root layout, so importing this module eagerly meant a missing env var
 * failed the prerender of every static page — including /_not-found — and took
 * the whole build down. Auth only ever runs in the browser, so nothing needs a
 * client while pages are being generated.
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

/**
 * Where the "Ingatkan saya" choice itself is recorded. Not a secret — it only
 * says which store the session belongs in.
 */
const REMEMBER_ME_KEY = "navika.remember-me";

/** Call before signing in so the session lands in the right store. */
export function setRememberMe(remember: boolean): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(REMEMBER_ME_KEY, remember ? "true" : "false");
}

function shouldRemember(): boolean {
  if (typeof window === "undefined") return true;
  // Default to remembering, matching the checkbox's default state.
  return window.localStorage.getItem(REMEMBER_ME_KEY) !== "false";
}

/**
 * Session storage that honours "Ingatkan saya":
 * - checked   → localStorage, so the session survives closing the browser
 * - unchecked → sessionStorage, so it dies with the tab
 *
 * Reads check both stores because the choice can change between visits, and
 * writes clear the other store so a session never lives in two places.
 */
const rememberMeStorage = {
  getItem: (key: string): string | null => {
    if (typeof window === "undefined") return null;
    return window.sessionStorage.getItem(key) ?? window.localStorage.getItem(key);
  },
  setItem: (key: string, value: string): void => {
    if (typeof window === "undefined") return;
    if (shouldRemember()) {
      window.localStorage.setItem(key, value);
      window.sessionStorage.removeItem(key);
    } else {
      window.sessionStorage.setItem(key, value);
      window.localStorage.removeItem(key);
    }
  },
  removeItem: (key: string): void => {
    if (typeof window === "undefined") return;
    window.localStorage.removeItem(key);
    window.sessionStorage.removeItem(key);
  },
};

let client: SupabaseClient | null = null;

function getClient(): SupabaseClient {
  if (client) return client;

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

  client = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      storage: rememberMeStorage,
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  });
  return client;
}

/**
 * Behaves like a normal Supabase client, but defers construction (and the env
 * var check) to the first property access. Missing config still throws loudly —
 * just when auth is actually used, not while pages are being built.
 */
export const supabase = new Proxy({} as SupabaseClient, {
  get(_target, prop) {
    const value = Reflect.get(getClient() as object, prop);
    return typeof value === "function" ? value.bind(getClient()) : value;
  },
});
