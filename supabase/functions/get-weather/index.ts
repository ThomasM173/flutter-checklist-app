// ============================================================================
// get-weather — server-side proxy for the AVWX API
//
// The AVWX token is a paid third-party API key and must never ship in the
// client bundle. The app sends the same logical request it used to send
// straight to avwx.rest; this function forwards it with the secret token and
// returns AVWX's response body unchanged.
//
// Request (POST JSON):
//   {
//     "endpoint": "metar" | "taf" | "station" | "pirep" | "airsigmet",
//     "icao":     "EGLL",            // required for metar/taf/station/pirep
//     "coords":   "51.47,-0.4543",   // required for airsigmet ("lat,lon")
//     "options":  "info,translate"   // optional, passed through as ?options=
//   }
//
// Response: exactly AVWX's JSON body, with AVWX's HTTP status code.
//
// Secret (set by the project owner, never in code/migrations):
//   supabase secrets set AVWX_TOKEN=xxxxxxxx
// ============================================================================

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const AVWX_TOKEN = Deno.env.get("AVWX_TOKEN");
const AVWX_BASE = "https://avwx.rest/api";

const ICAO_ENDPOINTS = new Set(["metar", "taf", "station", "pirep"]);
const ICAO_RE = /^[A-Za-z0-9]{3,4}$/;
const COORDS_RE = /^-?\d{1,3}(\.\d+)?,-?\d{1,3}(\.\d+)?$/;
const OPTIONS_RE = /^[A-Za-z0-9,_-]{0,64}$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }
  if (!AVWX_TOKEN) {
    console.error("get-weather: AVWX_TOKEN secret is not set");
    return jsonResponse({ error: "Weather service not configured" }, 500);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Body must be JSON" }, 400);
  }

  const endpoint = String(payload.endpoint ?? "").toLowerCase();
  const icao = payload.icao ? String(payload.icao) : "";
  const coords = payload.coords ? String(payload.coords) : "";
  const options = payload.options ? String(payload.options) : "";

  if (options && !OPTIONS_RE.test(options)) {
    return jsonResponse({ error: "Invalid options" }, 400);
  }

  let path: string;
  if (ICAO_ENDPOINTS.has(endpoint)) {
    if (!ICAO_RE.test(icao)) {
      return jsonResponse({ error: "Invalid or missing icao" }, 400);
    }
    path = `${endpoint}/${icao.toUpperCase()}`;
  } else if (endpoint === "airsigmet") {
    if (!COORDS_RE.test(coords)) {
      return jsonResponse({ error: "Invalid or missing coords" }, 400);
    }
    path = `airsigmet/${coords}`;
  } else {
    return jsonResponse({ error: `Unsupported endpoint: ${endpoint}` }, 400);
  }

  const url = `${AVWX_BASE}/${path}${options ? `?options=${options}` : ""}`;

  let avwxResp: Response;
  try {
    avwxResp = await fetch(url, {
      headers: { Authorization: `Token ${AVWX_TOKEN}` },
    });
  } catch (e) {
    console.error("get-weather: upstream fetch failed:", e);
    return jsonResponse({ error: "Weather upstream unreachable" }, 502);
  }

  const bodyText = await avwxResp.text();
  // Pass AVWX's body + status straight through; the Flutter parser is unchanged.
  return new Response(bodyText, {
    status: avwxResp.status,
    headers: {
      ...corsHeaders,
      "Content-Type": avwxResp.headers.get("Content-Type") ?? "application/json",
    },
  });
});
