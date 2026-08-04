import { createClient } from "@supabase/supabase-js";

let supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://zeouypcqrdsuohqchvbd.supabase.co";
// Clean trailing slashes or rest/v1 paths to ensure correct auth request path routing
supabaseUrl = supabaseUrl.replace(/\/rest\/v1\/?$/, "").replace(/\/$/, "");

const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inplb3V5cGNxcmRzdW9ocWNodmJkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTU4ODg4MiwiZXhwIjoyMTAxMTY0ODgyfQ.SFYITglZqnGYIS29EuzhAJtGUksTRl0sCrj33_br7Ho";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
