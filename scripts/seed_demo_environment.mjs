// ============================================================================
// seed_demo_environment.mjs — business_admin account + Demo Flight School
//
// Run OUTSIDE Flutter, with Node (same setup as the other seed scripts):
//   cd scripts && npm install && node seed_demo_environment.mjs
//
// Requires (from scripts/.env or the shell environment — NEVER committed):
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY    (bypasses RLS)
//
// Creates:
//   * one business_admin account (ClearedToGo team) — weareclearedtogo@gmail.com
//     unless SEED_BUSINESS_ADMIN_EMAIL overrides it
//   * one "Demo Flight School" (comped, separate from the real Devon &
//     Somerset design-partner school — demo activity never touches real data)
//   * two demo pilots under it, with obviously-fake names
//   * one flight_school_admin for the Demo Flight School —
//     thomasmalins@proton.me unless SEED_DEMO_SCHOOL_ADMIN_EMAIL overrides
//     it. If a flight_school_admin already exists for this school with a
//     different email, that email is updated via the Supabase Admin API
//     (auth.admin.updateUserById) rather than left alone or edited directly
//     on auth.users.
//   * a handful of checklist_completions rows across both pilots, spread
//     over the last couple of weeks so Phase 10/11 dashboards have
//     something real-looking to display
//
// Safe to re-run: without --reset it finds existing rows and leaves them
// untouched (just reprints credentials/invite code). --reset deletes and
// recreates the two demo pilots + their completions (NOT the business_admin
// account or the school itself, so re-running doesn't invalidate the invite
// code already shown to anyone, or require re-promoting the admin).
// ============================================================================

import { createClient } from "@supabase/supabase-js";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

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
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  console.error(
    "ERROR: set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (scripts/.env or shell env).",
  );
  process.exit(1);
}

const RESET = process.argv.includes("--reset");

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const BUSINESS_ADMIN_EMAIL =
  process.env.SEED_BUSINESS_ADMIN_EMAIL || "weareclearedtogo@gmail.com";
const DEMO_SCHOOL_ADMIN_EMAIL =
  process.env.SEED_DEMO_SCHOOL_ADMIN_EMAIL || "thomasmalins@proton.me";
const DEMO_SCHOOL_NAME = "Demo Flight School";
const DEMO_PILOT_1 = { email: "demo.pilot1@clearedtogo.test", fullName: "Alex Morgan" };
const DEMO_PILOT_2 = { email: "demo.pilot2@clearedtogo.test", fullName: "Jamie Chen" };

function genPassword() {
  return randomBytes(14).toString("base64url") + "9!aA";
}
function genInviteCode() {
  return randomBytes(8).toString("hex").slice(0, 8).toUpperCase();
}
function daysAgo(n) {
  return new Date(Date.now() - n * 24 * 3600 * 1000).toISOString();
}

async function findUserByEmail(email) {
  const { data, error } = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (error) throw error;
  return data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
}

async function ensureUser(email, fullName) {
  const existing = await findUserByEmail(email);
  if (existing) {
    if (!RESET) return { user: existing, password: null, created: false };
    await admin.auth.admin.deleteUser(existing.id);
    console.log(`  (reset) deleted existing ${email}`);
  }
  const password = genPassword();
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
  if (error) throw error;
  return { user: data.user, password, created: true };
}

async function main() {
  console.log(`Seeding demo environment into ${SUPABASE_URL}\n`);

  // 1. Business admin ---------------------------------------------------
  const bizAdmin = await ensureUser(BUSINESS_ADMIN_EMAIL, "ClearedToGo Team");
  {
    const { error } = await admin
      .from("profiles")
      .update({ role: "business_admin" })
      .eq("id", bizAdmin.user.id);
    if (error) throw error;
  }
  console.log(`Business admin ready: ${BUSINESS_ADMIN_EMAIL} (role=business_admin)`);

  // 2. Demo Flight School (comped) --------------------------------------
  let school;
  {
    const { data: existing } = await admin
      .from("flight_schools")
      .select("*")
      .eq("name", DEMO_SCHOOL_NAME)
      .maybeSingle();
    if (existing) {
      school = existing;
      console.log(`"${DEMO_SCHOOL_NAME}" already exists (${school.id}).`);
    } else {
      const { data, error } = await admin
        .from("flight_schools")
        .insert({
          name: DEMO_SCHOOL_NAME,
          invite_code: genInviteCode(),
          plan_type: "comped",
          comped_reason: "internal demo environment",
        })
        .select()
        .single();
      if (error) throw error;
      school = data;
      console.log(`Created "${DEMO_SCHOOL_NAME}" (${school.id}), plan_type=comped.`);
    }
  }

  // 3. Two demo pilots, attached to the demo school ----------------------
  const pilots = [];
  for (const p of [DEMO_PILOT_1, DEMO_PILOT_2]) {
    const result = await ensureUser(p.email, p.fullName);
    const { error } = await admin
      .from("profiles")
      .update({ flight_school_id: school.id })
      .eq("id", result.user.id);
    if (error) throw error;
    pilots.push({ ...result, email: p.email, fullName: p.fullName });
  }

  // 4. Flight school admin for the Demo Flight School ---------------------
  let schoolAdmin;
  {
    const { data: members, error: membersErr } = await admin
      .from("profiles")
      .select("id, full_name, role")
      .eq("flight_school_id", school.id)
      .eq("role", "flight_school_admin");
    if (membersErr) throw membersErr;

    if (members.length > 0) {
      const existingAdminId = members[0].id;
      const { data: authUser, error: getErr } =
        await admin.auth.admin.getUserById(existingAdminId);
      if (getErr) throw getErr;
      const currentEmail = authUser.user.email;

      if (currentEmail?.toLowerCase() === DEMO_SCHOOL_ADMIN_EMAIL.toLowerCase()) {
        schoolAdmin = { user: authUser.user, password: null, created: false };
        console.log(`Demo Flight School admin already correct: ${DEMO_SCHOOL_ADMIN_EMAIL}`);
      } else {
        // Update via the Admin API, not a raw auth.users edit.
        const { data: updated, error: updateErr } =
          await admin.auth.admin.updateUserById(existingAdminId, {
            email: DEMO_SCHOOL_ADMIN_EMAIL,
            email_confirm: true,
          });
        if (updateErr) throw updateErr;
        schoolAdmin = { user: updated.user, password: null, created: false };
        console.log(`Updated existing Demo Flight School admin email: ${currentEmail} -> ${DEMO_SCHOOL_ADMIN_EMAIL}`);
      }
    } else {
      const result = await ensureUser(DEMO_SCHOOL_ADMIN_EMAIL, "Demo Flight School Admin");
      const { error } = await admin
        .from("profiles")
        .update({ role: "flight_school_admin", flight_school_id: school.id })
        .eq("id", result.user.id);
      if (error) throw error;
      schoolAdmin = result;
      console.log(`Created Demo Flight School admin: ${DEMO_SCHOOL_ADMIN_EMAIL}`);
    }
  }

  // 5. Seed checklist_completions (idempotent-ish: only insert if --reset
  //    or none exist yet for these pilots, so a plain re-run doesn't pile
  //    up duplicates) ------------------------------------------------------
  const [pilot1, pilot2] = pilots;
  const { count: existingCount } = await admin
    .from("checklist_completions")
    .select("id", { count: "exact", head: true })
    .in("user_id", [pilot1.user.id, pilot2.user.id]);

  if (RESET && existingCount > 0) {
    await admin
      .from("checklist_completions")
      .delete()
      .in("user_id", [pilot1.user.id, pilot2.user.id]);
    console.log(`  (reset) deleted ${existingCount} existing demo completion row(s)`);
  }

  if (RESET || existingCount === 0) {
    const rows = [
      {
        user_id: pilot1.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 152",
        checklist_name: "Pre-boarding Checklist",
        completion_type: "checklist",
        completed_at: daysAgo(2),
      },
      {
        user_id: pilot1.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 152",
        checklist_name: "Tech Log",
        completion_type: "tech_log",
        completed_at: daysAgo(6),
      },
      {
        user_id: pilot1.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 152",
        checklist_name: "PAVE Assessment",
        completion_type: "pave_assessment",
        completed_at: daysAgo(9),
      },
      {
        user_id: pilot2.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 172",
        checklist_name: "Pre-boarding Checklist",
        completion_type: "checklist",
        completed_at: daysAgo(1),
      },
      {
        user_id: pilot2.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 172",
        checklist_name: "Fuel Uplift",
        completion_type: "fuel_uplift",
        completed_at: daysAgo(4),
      },
      {
        user_id: pilot2.user.id,
        flight_school_id: school.id,
        aircraft_type: "Cessna 172",
        checklist_name: "Weight & Balance Loadsheet",
        completion_type: "weight_balance",
        completed_at: daysAgo(11),
      },
    ];
    const { error } = await admin.from("checklist_completions").insert(rows);
    if (error) throw error;
    console.log(`Seeded ${rows.length} checklist_completions rows across the two demo pilots.`);
  } else {
    console.log(`${existingCount} completion row(s) already exist for the demo pilots — left untouched (use --reset to replace).`);
  }

  // --- Output -----------------------------------------------------------
  const line = "-".repeat(64);
  console.log(`\n${line}`);
  console.log("DEMO ENVIRONMENT CREDENTIALS (terminal only — not in any committed file)");
  console.log(line);
  console.log(`Business admin : ${BUSINESS_ADMIN_EMAIL}`);
  console.log(`  password     : ${bizAdmin.password ?? "(unchanged — already existed; re-run with --reset for a fresh one)"}`);
  console.log("");
  console.log(`Demo school    : ${DEMO_SCHOOL_NAME} (${school.id})`);
  console.log(`  invite code  : ${school.invite_code}`);
  console.log("");
  for (const p of pilots) {
    console.log(`Demo pilot     : ${p.fullName} <${p.email}>`);
    console.log(`  password     : ${p.password ?? "(unchanged — already existed; re-run with --reset for a fresh one)"}`);
  }
  console.log("");
  console.log(`School admin   : ${DEMO_SCHOOL_ADMIN_EMAIL}`);
  console.log(`  password     : ${schoolAdmin.password ?? "(unchanged — already existed with this email; no new password)"}`);
  console.log(line);
}

main().catch((e) => {
  console.error("\nSeed failed:", e.message ?? e);
  process.exit(1);
});
