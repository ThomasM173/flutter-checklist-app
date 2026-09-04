// ============================================================================
// verify_entitlement.mjs — end-to-end check of has_premium_access()
//
// Run OUTSIDE Flutter, with Node (same setup as verify_schema.mjs):
//   cd scripts && npm install && node verify_entitlement.mjs
//
// NOT shipped in the app. Reads secrets from scripts/.env (gitignored) or the
// shell environment — NEVER committed.
//
// Required:
//   SUPABASE_URL
//   SUPABASE_ANON_KEY               (same value the Flutter app uses)
//   SUPABASE_SERVICE_ROLE_KEY       (bypasses RLS — admin setup + cleanup)
//
// Unlike verify_schema.mjs, this script never touches the real dev pilot/
// admin accounts — every account and flight school it uses is created here
// and deleted again at the end (best-effort, even on failure), so it's safe
// to run repeatedly against a live project.
// ============================================================================

import { createClient } from "@supabase/supabase-js";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// --- tiny .env loader (same as seed_dev_user.mjs / verify_schema.mjs) ------
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

if (!SUPABASE_URL || !ANON_KEY || !SERVICE_ROLE_KEY) {
  console.error(
    "ERROR: set SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY " +
      "(scripts/.env or shell env).",
  );
  process.exit(1);
}

const results = []; // { name, status: 'PASS'|'FAIL', detail }
function record(name, status, detail = "") {
  results.push({ name, status, detail });
  const icon = status === "PASS" ? "✅" : "❌";
  console.log(`${icon} ${name}${detail ? " — " + detail : ""}`);
}

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function genPassword() {
  return randomBytes(14).toString("base64url") + "9!aA";
}
function genInviteCode() {
  return randomBytes(8).toString("hex").slice(0, 8).toUpperCase();
}

// Everything created here gets torn down in `cleanup()`, however the script exits.
const created = { userIds: [], schoolIds: [] };

async function createThrowawayPilot(label) {
  const email = `verify-ent-${label}-${Date.now()}-${randomBytes(3).toString("hex")}@clearedtogo.test`;
  const password = genPassword();
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error) throw new Error(`create throwaway account (${label}): ${error.message}`);
  created.userIds.push(data.user.id);

  const client = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: signIn, error: signInErr } = await client.auth.signInWithPassword({ email, password });
  if (signInErr || !signIn.user) {
    throw new Error(`sign in as throwaway account (${label}): ${signInErr?.message ?? "no user"}`);
  }
  return { id: data.user.id, email, client };
}

async function createThrowawaySchool(label, { comped }) {
  const { data, error } = await admin
    .from("flight_schools")
    .insert({
      name: `Verify Entitlement ${label} ${Date.now()}`,
      invite_code: genInviteCode(),
      ...(comped ? { plan_type: "comped", comped_reason: "verify_entitlement.mjs test" } : {}),
    })
    .select()
    .single();
  if (error) throw new Error(`create throwaway school (${label}): ${error.message}`);
  created.schoolIds.push(data.id);
  return data;
}

async function hasPremium(client) {
  const { data, error } = await client.rpc("has_premium_access");
  if (error) throw new Error(`has_premium_access RPC: ${error.message}`);
  return data === true;
}

// ============================================================================
// 1. Comped school -> immediate access, no trial/payment involved
// ============================================================================
async function checkCompedSchool() {
  const school = await createThrowawaySchool("comped", { comped: true });
  const pilot = await createThrowawayPilot("comped-pilot");

  const { error: joinErr } = await pilot.client.rpc("join_flight_school", {
    p_invite_code: school.invite_code,
  });
  if (joinErr) {
    record("Comped-school pilot: join_flight_school", "FAIL", joinErr.message);
    return;
  }
  record("Comped-school pilot: join_flight_school", "PASS");

  // Belt-and-braces: confirm this pilot's OWN trial (independent of the
  // school) hasn't quietly been made to look expired — the comped path
  // should carry access on its own regardless.
  await admin.from("profiles").update({
    trial_ends_at: new Date(Date.now() - 24 * 3600 * 1000).toISOString(),
  }).eq("id", pilot.id);

  const premium = await hasPremium(pilot.client);
  if (premium) {
    record("Comped-school pilot: has_premium_access = true", "PASS", "granted via comped school alone, trial already expired");
  } else {
    record("Comped-school pilot: has_premium_access = true", "FAIL", "expected true (comped school), got false");
  }
}

// ============================================================================
// 2. Fresh trial -> access; expired trial (no school, no sub) -> no access
// ============================================================================
async function checkTrial() {
  const pilot = await createThrowawayPilot("trial-pilot");

  const freshPremium = await hasPremium(pilot.client);
  if (freshPremium) {
    record("Fresh trial: has_premium_access = true", "PASS");
  } else {
    record("Fresh trial: has_premium_access = true", "FAIL", "expected true for a brand-new trial");
  }

  await admin.from("profiles").update({
    trial_ends_at: new Date(Date.now() - 24 * 3600 * 1000).toISOString(),
  }).eq("id", pilot.id);

  const expiredPremium = await hasPremium(pilot.client);
  if (!expiredPremium) {
    record("Expired trial (no school/sub): has_premium_access = false", "PASS");
  } else {
    record("Expired trial (no school/sub): has_premium_access = false", "FAIL", "expected false once trial_ends_at is in the past");
  }

  return pilot; // reused as the cross-tenant "outsider" in section 4
}

// ============================================================================
// 3. Simulated paid subscriber -> access via path (c) ALONE
//    (no school, expired trial) — proves real subscribers will work later
//    with zero code changes once kIapEnabled flips on.
// ============================================================================
async function checkPaidSubscriber() {
  const pilot = await createThrowawayPilot("paid-pilot");

  const { error } = await admin.from("profiles").update({
    trial_ends_at: new Date(Date.now() - 24 * 3600 * 1000).toISOString(),
    subscription_status: "premium",
    subscription_expires_at: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString(),
  }).eq("id", pilot.id);
  if (error) {
    record("Simulated paid subscriber: set up row", "FAIL", error.message);
    return;
  }

  const premium = await hasPremium(pilot.client);
  if (premium) {
    record(
      "Simulated paid subscriber: has_premium_access = true via path (c) alone",
      "PASS",
      "no school, expired trial, subscription_status=premium + future subscription_expires_at",
    );
  } else {
    record("Simulated paid subscriber: has_premium_access = true via path (c) alone", "FAIL", "expected true");
  }
}

// ============================================================================
// 4 & 5. School admin visibility + cross-tenant isolation
// ============================================================================
async function checkAdminVisibilityAndIsolation(outsider) {
  const school = await createThrowawaySchool("tenant", { comped: false });

  const adminAccount = await createThrowawayPilot("tenant-admin");
  await admin
    .from("profiles")
    .update({ role: "flight_school_admin", flight_school_id: school.id })
    .eq("id", adminAccount.id);

  const pilotA = await createThrowawayPilot("tenant-pilotA");
  const pilotB = await createThrowawayPilot("tenant-pilotB");
  for (const p of [pilotA, pilotB]) {
    const { error } = await p.client.rpc("join_flight_school", { p_invite_code: school.invite_code });
    if (error) {
      record(`Tenant setup: ${p.email} joins school`, "FAIL", error.message);
      return;
    }
  }
  record("Tenant setup: both pilots joined the school", "PASS");

  // One completion per pilot, deliberately different completion_type values,
  // to prove admin visibility isn't scoped to a single type.
  const { error: insertErr } = await admin.from("checklist_completions").insert([
    {
      user_id: pilotA.id,
      flight_school_id: school.id,
      aircraft_type: "C152",
      checklist_name: "Pre-flight",
      completion_type: "checklist",
    },
    {
      user_id: pilotB.id,
      flight_school_id: school.id,
      aircraft_type: "C152",
      checklist_name: "PAVE Assessment",
      completion_type: "pave_assessment",
    },
  ]);
  if (insertErr) {
    record("Tenant setup: seed checklist_completions", "FAIL", insertErr.message);
    return;
  }
  record("Tenant setup: seed checklist_completions", "PASS", "2 rows, 2 different completion_type values");

  // --- 4. Admin sees ALL pilots in their school ---------------------------
  {
    const { data, error } = await adminAccount.client
      .from("profiles")
      .select("id")
      .eq("flight_school_id", school.id)
      .eq("role", "pilot");
    const ids = (data ?? []).map((r) => r.id);
    if (!error && ids.includes(pilotA.id) && ids.includes(pilotB.id)) {
      record("Admin sees ALL pilots in their school", "PASS", `${ids.length} pilot(s) visible`);
    } else {
      record("Admin sees ALL pilots in their school", "FAIL", error?.message ?? `saw ${JSON.stringify(ids)}`);
    }
  }

  // --- 4. Admin sees ALL of those pilots' completions, any completion_type
  {
    const { data, error } = await adminAccount.client
      .from("checklist_completions")
      .select("user_id,completion_type")
      .eq("flight_school_id", school.id);
    const types = new Set((data ?? []).map((r) => r.completion_type));
    const userIds = new Set((data ?? []).map((r) => r.user_id));
    if (!error && userIds.has(pilotA.id) && userIds.has(pilotB.id) && types.has("checklist") && types.has("pave_assessment")) {
      record(
        "Admin sees ALL pilots' completions across every completion_type",
        "PASS",
        `${data.length} row(s), types=${[...types].join(",")}`,
      );
    } else {
      record(
        "Admin sees ALL pilots' completions across every completion_type",
        "FAIL",
        error?.message ?? `saw ${JSON.stringify(data)}`,
      );
    }
  }

  // --- 5. Cross-tenant isolation: an unrelated pilot sees none of this ----
  {
    const { data, error } = await outsider.client
      .from("profiles")
      .select("id")
      .eq("flight_school_id", school.id);
    if (!error && (data ?? []).length === 0) {
      record("Cross-tenant isolation: outsider cannot see this school's pilots", "PASS");
    } else {
      record(
        "Cross-tenant isolation: outsider cannot see this school's pilots",
        "FAIL",
        error?.message ?? `saw ${data.length} row(s)`,
      );
    }
  }
  {
    const { data, error } = await outsider.client
      .from("checklist_completions")
      .select("id")
      .eq("flight_school_id", school.id);
    if (!error && (data ?? []).length === 0) {
      record("Cross-tenant isolation: outsider cannot see this school's completions", "PASS");
    } else {
      record(
        "Cross-tenant isolation: outsider cannot see this school's completions",
        "FAIL",
        error?.message ?? `saw ${data.length} row(s)`,
      );
    }
  }
}

// ============================================================================
async function cleanup() {
  console.log("\nCleaning up throwaway accounts/schools...");
  for (const id of created.userIds) {
    await admin.auth.admin.deleteUser(id).catch((e) => console.warn(`  (cleanup) couldn't delete user ${id}: ${e.message ?? e}`));
  }
  for (const id of created.schoolIds) {
    await admin.from("flight_schools").delete().eq("id", id).then(({ error }) => {
      if (error) console.warn(`  (cleanup) couldn't delete school ${id}: ${error.message}`);
    });
  }
  console.log("Done.");
}

async function main() {
  console.log(`Verifying entitlement (has_premium_access) at ${SUPABASE_URL}\n`);

  console.log("--- 1. Comped flight school ---");
  await checkCompedSchool();

  console.log("\n--- 2. Free trial (fresh + expired) ---");
  const outsider = await checkTrial();

  console.log("\n--- 3. Simulated paid subscriber (path c alone) ---");
  await checkPaidSubscriber();

  console.log("\n--- 4 & 5. School admin visibility + cross-tenant isolation ---");
  await checkAdminVisibilityAndIsolation(outsider);

  const fails = results.filter((r) => r.status === "FAIL");
  console.log(`\n${"-".repeat(64)}`);
  console.log(`${results.length - fails.length} passed, ${fails.length} failed`);
  if (fails.length > 0) {
    console.log("\nFAILED CHECKS:");
    for (const f of fails) console.log(`  ${f.name}: ${f.detail}`);
    process.exitCode = 1;
  }
}

main()
  .catch((e) => {
    console.error("\nVerification script crashed:", e.message ?? e);
    process.exitCode = 1;
  })
  .finally(cleanup);
