// tol-route: proxies walking/wheelchair route requests to OpenRouteService so the ORS API key
// never ships in the app. Deploy: supabase functions deploy tol-route
// Secret:  supabase secrets set ORS_API_KEY=<your key from openrouteservice.org>

const ORS_URL = "https://api.openrouteservice.org/v2/directions";
const PROFILES = new Set(["foot-walking", "wheelchair"]);

// Metro Manila box around Quezon City. Requests outside it are refused; TolongApp only
// supports Quezon City and this also protects the shared free ORS quota.
const BOUNDS = { minLat: 14.45, maxLat: 14.9, minLng: 120.85, maxLng: 121.25 };

// Best-effort per-IP limit. Edge instances are short-lived, so this only stops bursts;
// the ORS daily quota (2,000 directions/day on the free plan) is the hard limit.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 10;
const hits = new Map<string, number[]>();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
}

function fail(status: number, code: string): Response {
  return json(status, { error: code });
}

type Point = { lat: number; lng: number };

function validPoint(p: unknown): p is Point {
  if (typeof p !== "object" || p === null) return false;
  const { lat, lng } = p as Record<string, unknown>;
  return typeof lat === "number" && typeof lng === "number" &&
    lat >= BOUNDS.minLat && lat <= BOUNDS.maxLat && lng >= BOUNDS.minLng && lng <= BOUNDS.maxLng;
}

function rateLimited(ip: string): boolean {
  const now = Date.now();
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
  recent.push(now);
  hits.set(ip, recent);
  return recent.length > MAX_PER_WINDOW;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  const key = Deno.env.get("ORS_API_KEY");
  if (!key) return fail(503, "not_configured");

  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  if (rateLimited(ip)) return fail(429, "rate_limited");

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return fail(400, "invalid_request");
  }
  const { from, to } = body;
  const profile = typeof body.profile === "string" ? body.profile : "foot-walking";
  if (!PROFILES.has(profile)) return fail(400, "invalid_profile");
  if (!validPoint(from) || !validPoint(to)) return fail(400, "outside_area");

  let upstream: Response;
  try {
    upstream = await fetch(`${ORS_URL}/${profile}/geojson`, {
      method: "POST",
      headers: { "Authorization": key, "Content-Type": "application/json", "Accept": "application/geo+json" },
      body: JSON.stringify({
        coordinates: [[from.lng, from.lat], [to.lng, to.lat]],
        instructions: false,
        // Snap start/end points up to 350 m to the nearest walkable way.
        radiuses: [350, 350],
      }),
      signal: AbortSignal.timeout(15_000),
    });
  } catch {
    return fail(502, "upstream_unreachable");
  }

  if (upstream.status === 429) return fail(429, "quota_exceeded");
  const data = await upstream.json().catch(() => null);
  if (!upstream.ok) {
    // ORS 2004/2009/2010/2099: no routable point nearby or no route between the points.
    const orsCode = data?.error?.code;
    if ([2004, 2009, 2010, 2099].includes(orsCode)) return fail(404, "no_route");
    return fail(502, "upstream_error");
  }

  const feature = data?.features?.[0];
  const summary = feature?.properties?.summary;
  const coords: unknown = feature?.geometry?.coordinates;
  if (!summary || !Array.isArray(coords)) return fail(404, "no_route");

  return json(200, {
    profile,
    distance_m: summary.distance ?? 0,
    duration_s: summary.duration ?? 0,
    // [lat, lng] pairs, ready for the app's map.
    points: (coords as [number, number][]).map(([lng, lat]) => [lat, lng]),
    provider: "openrouteservice",
    attribution: "Routing © openrouteservice.org by HeiGIT | Map data © OpenStreetMap contributors",
  });
});
