// ============================================================================
// seed_devon_somerset_school.mjs — comp the Devon & Somerset launch partner
//
// Run OUTSIDE Flutter, with Node (same setup as seed_dev_user.mjs):
//   cd scripts && npm install && node seed_devon_somerset_school.mjs
//
// Requires (from scripts/.env or the shell environment — NEVER committed):
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY    (bypasses RLS)
//
// Creates:
//   * one flight_schools row, plan_type = 'comped' — every pilot who joins
//     via the invite code gets has_premium_access() = true permanently, no
//     trial/payment involved (see has_premium_access() in
//     supabase/migrations/20260904100000_entitlement.sql).
//   * one flight-school-admin account for the school, at a PLACEHOLDER email
//     (search for TODO_REPLACE below) — swap it for the real admin's email
//     before handing over credentials.
//
// Does NOT create pilot accounts. The ~30 Devon & Somerset pilots self-join
// with the printed invite code via the app's existing invite-code UI
// (FlightSchoolMembershipScreen) — bulk-creating fake accounts here would
// bypass that flow and isn't the point of this script.
//
// Safe to re-run: without --reset it finds the existing school/admin and
// leaves them untouched (just reprints the invite code). --reset deletes and
// recreates both — only do this if you intend to redistribute a fresh invite
// code, since the old one stops working immediately.
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

const SCHOOL_NAME = "Devon & Somerset Flying School";
const COMPED_REASON = "launch design partner";
// TODO_REPLACE: swap for the real admin's email before handing over
// credentials. Left as an obvious placeholder so it can't be mistaken for a
// real account (mirrors the TODO_REPLACE_ convention in lib/config/config.dart).
const ADMIN_EMAIL =
  process.env.SEED_DEVON_ADMIN_EMAIL ||
  "TODO_REPLACE_devon_somerset_admin@clearedtogo.test";

function genPassword() {
  return randomBytes(14).toString("base64url") + "9!aA";
}
function genInviteCode() {
  return randomBytes(8).toString("hex").slice(0, 8).toUpperCase();
}

async function findUserByEmail(email) {
  const { data, error } = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (error) throw error;
  return data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
}

async function main() {
  console.log(`Seeding Devon & Somerset Flying School into ${SUPABASE_URL}\n`);

  // 1. Flight school (comped) ----------------------------------------------
  let school;
  {
    const { data: existing } = await admin
      .from("flight_schools")
      .select("*")
      .eq("name", SCHOOL_NAME)
      .maybeSingle();

    if (existing && !RESET) {
      school = existing;
      console.log(`Flight school "${SCHOOL_NAME}" already exists (${school.id}).`);
      if (school.plan_type !== "comped") {
        // Shouldn't happen outside manual DB edits, but don't silently seed
        // credentials against a school that isn't actually comped.
        console.warn(
          `  WARNING: plan_type is "${school.plan_type}", not "comped". ` +
            `Fix this row before handing out the invite code, or re-run with --reset.`,
        );
      }
    } else {
      if (existing && RESET) {
        await admin.from("flight_schools").delete().eq("id", existing.id);
        console.log(`  (reset) deleted existing "${SCHOOL_NAME}"`);
      }
      const invite_code = genInviteCode();
      const { data, error } = await admin
        .from("flight_schools")
        .insert({
          name: SCHOOL_NAME,
          email: ADMIN_EMAIL,
          invite_code,
          plan_type: "comped",
          comped_reason: COMPED_REASON,
        })
        .select()
        .single();
      if (error) throw error;
      school = data;
      console.log(`Created flight school "${SCHOOL_NAME}" (${school.id}), plan_type=comped.`);
    }
  }

  // 2. Admin account ---------------------------------------------------------
  let adminAccount;
  {
    const existing = await findUserByEmail(ADMIN_EMAIL);
    if (existing) {
      if (!RESET) {
        adminAccount = { user: existing, password: null, created: false };
      } else {
        await admin.auth.admin.deleteUser(existing.id);
        console.log(`  (reset) deleted existing admin account ${ADMIN_EMAIL}`);
        const password = genPassword();
        const { data, error } = await admin.auth.admin.createUser({
          email: ADMIN_EMAIL,
          password,
          email_confirm: true,
          user_metadata: { full_name: "Devon & Somerset Admin" },
        });
        if (error) throw error;
        adminAccount = { user: data.user, password, created: true };
      }
    } else {
      const password = genPassword();
      const { data, error } = await admin.auth.admin.createUser({
        email: ADMIN_EMAIL,
        password,
        email_confirm: true,
        user_metadata: { full_name: "Devon & Somerset Admin" },
      });
      if (error) throw error;
      adminAccount = { user: data.user, password, created: true };
    }
  }

  // Elevate role + attach to the school (service role bypasses column locks).
  {
    const { error } = await admin
      .from("profiles")
      .update({ role: "flight_school_admin", flight_school_id: school.id })
      .eq("id", adminAccount.user.id);
    if (error) throw error;
  }

  // --- Output ---------------------------------------------------------
  const line = "-".repeat(64);
  console.log(`\n${line}`);
  console.log("DEVON & SOMERSET FLYING SCHOOL");
  console.log(line);
  console.log(`School id     : ${school.id}`);
  console.log(`Plan          : comped (${COMPED_REASON})`);
  console.log(`INVITE CODE   : ${school.invite_code}`);
  console.log("  -> hand this to the school; pilots self-join via");
  console.log("     Account Details -> Flight School in the app.");
  console.log("");
  console.log("ADMIN ACCOUNT");
  console.log(`  email       : ${ADMIN_EMAIL}`);
  if (ADMIN_EMAIL.startsWith("TODO_REPLACE")) {
    console.log("  *** PLACEHOLDER EMAIL — replace with the real admin's ***");
    console.log("  *** address (set SEED_DEVON_ADMIN_EMAIL and re-run     ***");
    console.log("  *** with --reset) before handing over credentials.    ***");
  }
  console.log(
    `  password    : ${adminAccount.password ?? "(unchanged — account already existed; re-run with --reset for a fresh one)"}`,
  );
  console.log(`  role        : flight_school_admin`);
  console.log(line);
}

main().catch((e) => {
  console.error("\nSeed failed:", e.message ?? e);
  process.exit(1);
});
