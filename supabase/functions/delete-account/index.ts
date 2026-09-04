// ============================================================================
// delete-account — self-service account deletion
//
// The Supabase client SDK cannot delete the currently signed-in user, so the
// app calls this function instead. Flow:
//   1. Verify the caller's JWT (also enforced by config.toml verify_jwt=true)
//      and resolve their user id.
//   2. Best-effort purge of their PDFs in the private 'checklist-pdfs' bucket
//      (the {user_id}/ prefix).
//   3. auth.admin.deleteUser(uid) with the service role key. The
//      profiles row and checklist_completions rows go with it via
//      `on delete cascade`.
//
// Secrets used (set with `supabase secrets set` / auto-injected on the
// hosted platform):
//   SUPABASE_URL              - project URL
//   SUPABASE_SERVICE_ROLE_KEY - service_role key (NEVER shipped in the app)
//   SUPABASE_ANON_KEY         - anon key, used only to validate the caller JWT
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const PDF_BUCKET = "checklist-pdfs";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const jwt = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!jwt) {
    return jsonResponse({ error: "Missing Authorization bearer token" }, 401);
  }

  // 1. Resolve + verify the caller.
  const authClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const { data: userData, error: userErr } = await authClient.auth.getUser();
  if (userErr || !userData?.user) {
    return jsonResponse({ error: "Invalid or expired session" }, 401);
  }
  const uid = userData.user.id;

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // 2. Best-effort: remove the user's PDFs from storage.
  try {
    const { data: files } = await admin.storage.from(PDF_BUCKET).list(uid, {
      limit: 1000,
    });
    if (files && files.length > 0) {
      const paths = files.map((f) => `${uid}/${f.name}`);
      await admin.storage.from(PDF_BUCKET).remove(paths);
    }
  } catch (e) {
    console.error("delete-account: storage cleanup failed (continuing):", e);
  }

  // 3. Delete the auth user (cascades to profiles + checklist_completions).
  const { error: delErr } = await admin.auth.admin.deleteUser(uid);
  if (delErr) {
    console.error("delete-account: deleteUser failed:", delErr);
    return jsonResponse({ error: "Failed to delete account" }, 500);
  }

  return jsonResponse({ ok: true, deleted: uid });
});
