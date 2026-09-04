// ============================================================================
// seed_dev_user.mjs — create local/dev test accounts in Supabase
//
// Run OUTSIDE Flutter, with Node:
//   cd scripts && npm install && node seed_dev_user.mjs
//
// Requires (from scripts/.env or the shell environment — NEVER committed):
//   SUPABASE_URL                 = https://<ref>.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY    = <service_role key>   (bypasses RLS)
//
// Creates:
//   * one flight school (random invite code)
//   * one dev PILOT account
//   * one dev FLIGHT SCHOOL ADMIN account (role elevated + attached to the school)
//
// Passwords are generated at run time and printed to stdout. Nothing is
// hardcoded. Re-running with the same emails will report they already exist
// and leave them untouched (pass --reset to delete + recreate).
// ============================================================================

import { createClient } from "@supabase/supabase-js";
import { randomBytes } from "node:crypto";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// --- tiny .env loader (avoids requiring dotenv to be installed) -------------
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

const PILOT_EMAIL = process.env.SEED_PILOT_EMAIL || "dev.pilot@clearedtogo.test";
const ADMIN_EMAIL = process.env.SEED_ADMIN_EMAIL || "dev.admin@clearedtogo.test";
const SCHOOL_NAME = process.env.SEED_SCHOOL_NAME || "Dev Flight School";

function genPassword() {
  // 18 url-safe chars + guaranteed symbol/number so it passes any policy.
  return randomBytes(14).toString("base64url") + "9!aA";
}
function genInviteCode() {
  return randomBytes(8).toString("hex").slice(0, 8).toUpperCase();
}

async function findUserByEmail(email) {
  // admin.listUsers is paginated; 1 page of 1000 is plenty for dev.
  const { data, error } = await admin.auth.admin.listUsers({ perPage: 1000 });
  if (error) throw error;
  return data.users.find((u) => u.email?.toLowerCase() === email.toLowerCase());
}

async function ensureUser(email, { fullName }) {
  const existing = await findUserByEmail(email);
  if (existing) {
    if (!RESET) {
      return { user: existing, password: null, created: false };
    }
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
  console.log(`Seeding dev accounts into ${SUPABASE_URL}\n`);

  // 1. Flight school -------------------------------------------------------
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
    } else {
      if (existing && RESET) {
        await admin.from("flight_schools").delete().eq("id", existing.id);
      }
      const invite_code = genInviteCode();
      const { data, error } = await admin
        .from("flight_schools")
        .insert({ name: SCHOOL_NAME, email: ADMIN_EMAIL, invite_code })
        .select()
        .single();
      if (error) throw error;
      school = data;
      console.log(`Created flight school "${SCHOOL_NAME}" (${school.id}).`);
    }
  }

  // 2. Pilot -------------------------------------------------------------
  const pilot = await ensureUser(PILOT_EMAIL, { fullName: "Dev Pilot" });

  // 3. Admin -----------------------------------------------------------
  const adminAcc = await ensureUser(ADMIN_EMAIL, { fullName: "Dev School Admin" });
  // Elevate role + attach to the school (service role bypasses the column locks).
  {
    const { error } = await admin
      .from("profiles")
      .update({ role: "flight_school_admin", flight_school_id: school.id })
      .eq("id", adminAcc.user.id);
    if (error) throw error;
  }

  // --- Output ---------------------------------------------------------
  const line = "-".repeat(64);
  console.log(`\n${line}`);
  console.log("DEV CREDENTIALS (store securely; not persisted anywhere else)");
  console.log(line);
  console.log(`Flight school : ${SCHOOL_NAME}`);
  console.log(`  id          : ${school.id}`);
  console.log(`  invite code : ${school.invite_code}`);
  console.log("");
  console.log("PILOT");
  console.log(`  email       : ${PILOT_EMAIL}`);
  console.log(
    `  password    : ${pilot.password ?? "(unchanged — account already existed; re-run with --reset)"}`,
  );
  console.log("");
  console.log("FLIGHT SCHOOL ADMIN");
  console.log(`  email       : ${ADMIN_EMAIL}`);
  console.log(
    `  password    : ${adminAcc.password ?? "(unchanged — account already existed; re-run with --reset)"}`,
  );
  console.log(`  role        : flight_school_admin`);
  console.log(`  school      : ${school.id}`);
  console.log(line);
}

main().catch((e) => {
  console.error("\nSeed failed:", e.message ?? e);
  process.exit(1);
});
