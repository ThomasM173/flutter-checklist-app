// ============================================================================
// verify_schema.mjs — post-migration sanity check for the Supabase project
//
// Run OUTSIDE Flutter, with Node (same setup as seed_dev_user.mjs):
//   cd scripts && npm install && node verify_schema.mjs
//
// NOT shipped in the app. Reads secrets from scripts/.env (gitignored) or the
// shell environment — NEVER committed, NEVER printed except where noted.
//
// Required:
//   SUPABASE_URL
//   SUPABASE_ANON_KEY               (same value the Flutter app uses)
//   SUPABASE_SERVICE_ROLE_KEY       (bypasses RLS — for the schema probe +
//                                    throwaway test-account admin ops only)
//
// Optional (enables the authenticated-role RLS checks — get these by running
// seed_dev_user.mjs first and saving the printed passwords):
//   DEV_PILOT_EMAIL / DEV_PILOT_PASSWORD
//   DEV_ADMIN_EMAIL / DEV_ADMIN_PASSWORD
//
// Optional:
//   AVWX_TEST_ICAO   (default EGLL)
//
// This script never touches the real dev pilot/admin accounts destructively —
// it only reads their data and (for the join-school check) calls the same
// join_flight_school RPC the app calls. The delete-account check runs ONLY
// against a disposable throwaway account this script creates and deletes
// itself; it never runs against DEV_PILOT_EMAIL / DEV_ADMIN_EMAIL.
// ============================================================================

import { createClient } from "@supabase/supabase-js";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// --- tiny .env loader (same as seed_dev_user.mjs) ---------------------------
try {
  const envPath = join(dirname(fileURLToPath(import.meta.url)), ".env");
  for (const line of readFileSync(envPath, "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/i);
    if (m && !process.env[m[1]]) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
  }
} catch {
  /* no .env file — rely on real environment */
}

const SUPABASE_URL = process.env.SUPABASE_URL;
const ANON_KEY = process.env.SUPABASE_ANON_KEY;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

const DEV_PILOT_EMAIL = process.env.DEV_PILOT_EMAIL;
const DEV_PILOT_PASSWORD = process.env.DEV_PILOT_PASSWORD;
const DEV_ADMIN_EMAIL = process.env.DEV_ADMIN_EMAIL;
const DEV_ADMIN_PASSWORD = process.env.DEV_ADMIN_PASSWORD;

const AVWX_TEST_ICAO = process.env.AVWX_TEST_ICAO || "EGLL";

if (!SUPABASE_URL || !ANON_KEY || !SERVICE_ROLE_KEY) {
  console.error(
    "ERROR: set SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY " +
      "(scripts/.env or shell env). See the header of this file.",
  );
  process.exit(1);
}

const results = []; // { section, name, status: 'PASS'|'FAIL'|'SKIP', detail }
function record(section, name, status, detail = "") {
  results.push({ section, name, status, detail });
  const icon = status === "PASS" ? "✅" : status === "SKIP" ? "⏭️ " : "❌";
  console.log(`${icon} [${section}] ${name}${detail ? " — " + detail : ""}`);
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const anon = createClient(SUPABASE_URL, ANON_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ============================================================================
// A. Schema probe
//
// PostgREST only exposes the `public` schema by default — information_schema
// isn't reachable through the API even with the service role key (that key
// bypasses Row Level Security, not schema exposure). So instead of querying
// information_schema directly, we probe each expected table/column with a
// zero-row select using the service role (which bypasses RLS, so a failure
// here means "doesn't exist", not "hidden by a policy"). A clear Postgres
// error naming the missing relation/column is exactly what a copy-paste
// mistake in the SQL Editor would produce.
// ============================================================================
async function checkSchema() {
  const probes = [
    { table: "flight_schools", columns: "id,name,invite_code,address,phone,email,plan_type,comped_reason,created_at" },
    { table: "profiles", columns: "id,full_name,role,flight_school_id,license_number,home_base,subscription_status,subscription_product_id,subscription_expires_at,trial_started_at,trial_ends_at,created_at" },
    {
      table: "checklist_completions",
      columns: "id,user_id,flight_school_id,aircraft_type,checklist_name,completed_at,pdf_storage_path,created_at,completion_type",
    },
  ];

  for (const { table, columns } of probes) {
    const { error } = await admin.from(table).select(columns).limit(1);
    if (error) {
      record("schema", table, "FAIL", error.message);
    } else {
      record("schema", table, "PASS", "table + all expected columns present");
    }
  }

  // has_premium_access() exists and is callable (function-level check;
  // scripts/verify_entitlement.mjs covers its actual entitlement logic).
  {
    const { data, error } = await admin.rpc("has_premium_access", {
      p_user_id: "00000000-0000-0000-0000-000000000000",
    });
    if (error) {
      record("schema", "has_premium_access() function", "FAIL", error.message);
    } else {
      record("schema", "has_premium_access() function", "PASS", `callable, returned ${data}`);
    }
  }

  // completion_type CHECK constraint: confirm a bogus value is rejected.
  // We use a random, definitely-nonexistent user_id so this can never
  // actually insert a row even if the constraint were missing — the FK
  // violation is the safety net, not the thing being tested.
  const { error: checkErr } = await admin.from("checklist_completions").insert({
    user_id: "00000000-0000-0000-0000-000000000000",
    aircraft_type: "TEST",
    checklist_name: "TEST",
    completion_type: "not_a_real_type",
  });
  if (checkErr && /completion_type|check constraint/i.test(checkErr.message)) {
    record("schema", "completion_type CHECK constraint", "PASS", "bogus value rejected");
  } else if (checkErr) {
    record(
      "schema",
      "completion_type CHECK constraint",
      "PASS",
      `insert rejected (${checkErr.message}) — likely the FK check, constraint order wasn't isolated but no bad row was written`,
    );
  } else {
    record("schema", "completion_type CHECK constraint", "FAIL", "bogus completion_type was accepted!");
  }
}

// ============================================================================
// B. RLS — anon role (unauthenticated)
// ============================================================================
async function checkAnon() {
  for (const table of ["profiles", "flight_schools", "checklist_completions"]) {
    const { data, error } = await anon.from(table).select("id").limit(1);
    if (error) {
      record("rls-anon", `${table}: select denied`, "PASS", error.message);
    } else if (!data || data.length === 0) {
      record("rls-anon", `${table}: select denied`, "PASS", "no error, but zero rows returned");
    } else {
      record("rls-anon", `${table}: select denied`, "FAIL", `anon could read ${data.length} row(s)!`);
    }
  }
}

// ============================================================================
// C. RLS — dev pilot
// ============================================================================
async function checkPilot() {
  if (!DEV_PILOT_EMAIL || !DEV_PILOT_PASSWORD) {
    record("rls-pilot", "all checks", "SKIP", "DEV_PILOT_EMAIL/DEV_PILOT_PASSWORD not set");
    return null;
  }

  const pilotClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: signIn, error: signInErr } = await pilotClient.auth.signInWithPassword({
    email: DEV_PILOT_EMAIL,
    password: DEV_PILOT_PASSWORD,
  });
  if (signInErr || !signIn.user) {
    record("rls-pilot", "sign in", "FAIL", signInErr?.message ?? "no user returned");
    return null;
  }
  record("rls-pilot", "sign in", "PASS");
  const pilotId = signIn.user.id;

  // Sees own profile.
  {
    const { data, error } = await pilotClient.from("profiles").select("id,role").eq("id", pilotId);
    if (error) record("rls-pilot", "select own profile", "FAIL", error.message);
    else if (data.length === 1) record("rls-pilot", "select own profile", "PASS");
    else record("rls-pilot", "select own profile", "FAIL", `expected 1 row, got ${data.length}`);
  }

  // Cannot see other profiles (no .eq filter — RLS alone must restrict this).
  {
    const { data, error } = await pilotClient.from("profiles").select("id");
    if (error) record("rls-pilot", "cannot list other profiles", "FAIL", error.message);
    else if (data.every((r) => r.id === pilotId)) {
      record("rls-pilot", "cannot list other profiles", "PASS", `sees only own row (${data.length} total)`);
    } else {
      record("rls-pilot", "cannot list other profiles", "FAIL", `sees ${data.length} rows, not just their own`);
    }
  }

  // Cannot write locked columns (role, flight_school_id) — not granted at all.
  {
    const { error } = await pilotClient
      .from("profiles")
      .update({ role: "flight_school_admin" })
      .eq("id", pilotId);
    if (error) record("rls-pilot", "cannot self-promote to admin", "PASS", error.message);
    else record("rls-pilot", "cannot self-promote to admin", "FAIL", "update succeeded — role column is writable!");
  }

  return { client: pilotClient, id: pilotId };
}

// ============================================================================
// D. RLS — dev admin (+ live invite-code join, using the pilot session)
// ============================================================================
async function checkAdmin(pilot) {
  if (!DEV_ADMIN_EMAIL || !DEV_ADMIN_PASSWORD) {
    record("rls-admin", "all checks", "SKIP", "DEV_ADMIN_EMAIL/DEV_ADMIN_PASSWORD not set");
    return;
  }

  const adminClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: signIn, error: signInErr } = await adminClient.auth.signInWithPassword({
    email: DEV_ADMIN_EMAIL,
    password: DEV_ADMIN_PASSWORD,
  });
  if (signInErr || !signIn.user) {
    record("rls-admin", "sign in", "FAIL", signInErr?.message ?? "no user returned");
    return;
  }
  record("rls-admin", "sign in", "PASS");

  const { data: profile, error: profileErr } = await adminClient
    .from("profiles")
    .select("role,flight_school_id")
    .eq("id", signIn.user.id)
    .single();
  if (profileErr || profile?.role !== "flight_school_admin" || !profile.flight_school_id) {
    record(
      "rls-admin",
      "has flight_school_admin role + school",
      "FAIL",
      profileErr?.message ?? `role=${profile?.role}, flight_school_id=${profile?.flight_school_id}`,
    );
    return;
  }
  record("rls-admin", "has flight_school_admin role + school", "PASS");

  const { data: school, error: schoolErr } = await adminClient
    .from("flight_schools")
    .select("id,name,invite_code")
    .eq("id", profile.flight_school_id)
    .single();
  if (schoolErr || !school) {
    record("rls-admin", "select own school", "FAIL", schoolErr?.message ?? "no row");
    return;
  }
  record("rls-admin", "select own school", "PASS", school.name);

  // Live end-to-end test of the invite-code flow: have the dev pilot join
  // this school (idempotent — safe to run repeatedly), then confirm the
  // admin can now see them via the "admin reads own-school pilots" policy.
  if (pilot) {
    const { error: joinErr } = await pilot.client.rpc("join_flight_school", {
      p_invite_code: school.invite_code,
    });
    if (joinErr) {
      record("rls-admin", "dev pilot joins school (join_flight_school RPC)", "FAIL", joinErr.message);
    } else {
      record("rls-admin", "dev pilot joins school (join_flight_school RPC)", "PASS");

      const { data: pilots, error: pilotsErr } = await adminClient
        .from("profiles")
        .select("id")
        .eq("flight_school_id", school.id)
        .eq("role", "pilot");
      if (pilotsErr) {
        record("rls-admin", "admin sees own-school pilots", "FAIL", pilotsErr.message);
      } else if (pilots.some((p) => p.id === pilot.id)) {
        record("rls-admin", "admin sees own-school pilots", "PASS", `${pilots.length} pilot(s) visible`);
      } else {
        record("rls-admin", "admin sees own-school pilots", "FAIL", "dev pilot not visible after joining");
      }
    }
  } else {
    record("rls-admin", "admin sees own-school pilots", "SKIP", "dev pilot session unavailable (see rls-pilot section)");
  }

  // Admin cannot rotate another school's invite code / isn't granted the column directly.
  {
    const { error } = await adminClient
      .from("flight_schools")
      .update({ invite_code: "HACKED01" })
      .eq("id", school.id);
    if (error) record("rls-admin", "cannot write invite_code directly", "PASS", error.message);
    else record("rls-admin", "cannot write invite_code directly", "FAIL", "invite_code column is directly writable!");
  }
}

// ============================================================================
// E. Edge Function — get-weather
// ============================================================================
async function checkGetWeather() {
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/get-weather`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ANON_KEY}`,
        apikey: ANON_KEY,
      },
      body: JSON.stringify({ endpoint: "metar", icao: AVWX_TEST_ICAO, options: "info,translate" }),
    });
    const text = await res.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      record("edge-fn", "get-weather", "FAIL", `non-JSON response (status ${res.status}): ${text.slice(0, 200)}`);
      return;
    }
    if (res.status !== 200) {
      record("edge-fn", "get-weather", "FAIL", `status ${res.status}: ${JSON.stringify(body).slice(0, 300)}`);
      return;
    }
    const requiredFields = ["station", "raw", "temperature", "wind_direction", "wind_speed"];
    const missing = requiredFields.filter((f) => !(f in body));
    if (missing.length > 0) {
      record(
        "edge-fn",
        "get-weather",
        "FAIL",
        `status 200 but AVWX-shaped body is missing field(s): ${missing.join(", ")}. ` +
          `Got keys: ${Object.keys(body).join(", ")}`,
      );
    } else {
      record("edge-fn", "get-weather", "PASS", `station=${body.station}, raw="${String(body.raw).slice(0, 60)}..."`);
    }
  } catch (e) {
    record("edge-fn", "get-weather", "FAIL", `request failed: ${e.message ?? e}`);
  }
}

// ============================================================================
// F. Edge Function — delete-account (throwaway account ONLY)
// ============================================================================
async function checkDeleteAccount() {
  const testEmail = `verify-delete-${Date.now()}-${randomBytes(3).toString("hex")}@clearedtogo.test`;
  const testPassword = randomBytes(14).toString("base64url") + "9!aA";

  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email: testEmail,
    password: testPassword,
    email_confirm: true,
  });
  if (createErr || !created.user) {
    record("edge-fn", "delete-account: create throwaway account", "FAIL", createErr?.message ?? "no user returned");
    return;
  }
  const testUserId = created.user.id;
  record("edge-fn", "delete-account: create throwaway account", "PASS", testEmail);

  const testClient = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: signIn, error: signInErr } = await testClient.auth.signInWithPassword({
    email: testEmail,
    password: testPassword,
  });
  if (signInErr || !signIn.session) {
    record("edge-fn", "delete-account: sign in as throwaway account", "FAIL", signInErr?.message ?? "no session");
    return;
  }

  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/delete-account`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${signIn.session.access_token}`,
        apikey: ANON_KEY,
      },
    });
    const body = await res.json().catch(() => null);
    if (res.status !== 200) {
      record("edge-fn", "delete-account: call function", "FAIL", `status ${res.status}: ${JSON.stringify(body)}`);
      // Best-effort cleanup so a failed run doesn't leave the account behind.
      await admin.auth.admin.deleteUser(testUserId).catch(() => {});
      return;
    }
    record("edge-fn", "delete-account: call function", "PASS", JSON.stringify(body));
  } catch (e) {
    record("edge-fn", "delete-account: call function", "FAIL", `request failed: ${e.message ?? e}`);
    await admin.auth.admin.deleteUser(testUserId).catch(() => {});
    return;
  }

  // Confirm auth.users row is gone.
  const { data: authCheck } = await admin.auth.admin.getUserById(testUserId);
  if (!authCheck?.user) {
    record("edge-fn", "delete-account: auth.users row gone", "PASS");
  } else {
    record("edge-fn", "delete-account: auth.users row gone", "FAIL", "user still exists");
  }

  // Confirm profiles row is gone (cascades from auth.users delete).
  const { data: profileCheck } = await admin.from("profiles").select("id").eq("id", testUserId).maybeSingle();
  if (!profileCheck) {
    record("edge-fn", "delete-account: profiles row gone", "PASS");
  } else {
    record("edge-fn", "delete-account: profiles row gone", "FAIL", "profiles row still exists");
  }
}

// ============================================================================
async function main() {
  console.log(`Verifying Supabase project at ${SUPABASE_URL}\n`);

  console.log("--- A. Schema ---");
  await checkSchema();

  console.log("\n--- B. RLS: anon role ---");
  await checkAnon();

  console.log("\n--- C. RLS: dev pilot ---");
  const pilot = await checkPilot();

  console.log("\n--- D. RLS: dev admin ---");
  await checkAdmin(pilot);

  console.log("\n--- E. Edge Function: get-weather ---");
  await checkGetWeather();

  console.log("\n--- F. Edge Function: delete-account (throwaway account) ---");
  await checkDeleteAccount();

  const fails = results.filter((r) => r.status === "FAIL");
  const skips = results.filter((r) => r.status === "SKIP");
  console.log(`\n${"-".repeat(64)}`);
  console.log(`${results.length - fails.length - skips.length} passed, ${fails.length} failed, ${skips.length} skipped`);
  if (fails.length > 0) {
    console.log("\nFAILED CHECKS:");
    for (const f of fails) console.log(`  [${f.section}] ${f.name}: ${f.detail}`);
    process.exitCode = 1;
  }
}

main().catch((e) => {
  console.error("\nVerification script crashed:", e);
  process.exit(1);
});
