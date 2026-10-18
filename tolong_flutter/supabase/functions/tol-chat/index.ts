// tol-chat: Tol's online brain. Keeps the AI provider key server-side, applies TolongApp's
// safety rules, and lets the provider change without an app release.
//
// Deploy:  supabase functions deploy tol-chat
// Secrets: supabase secrets set TOL_PROVIDER=anthropic TOL_MODEL=claude-haiku-5-5 ANTHROPIC_API_KEY=...
//          (or TOL_PROVIDER=gemini + GEMINI_API_KEY, or TOL_PROVIDER=openai + OPENAI_API_KEY)
//          TOL_SHARE_CONTEXT=false  -> ignore household context (use on providers that train on free-tier data)
//
// JWT verification stays ON (default): only signed-in users can call Tol online.

type Role = "user" | "assistant";
type Msg = { role: Role; content: string };

const MAX_MESSAGES = 12;
const MAX_CHARS_PER_MESSAGE = 1000;
const MAX_TOTAL_CHARS = 6000;
const MAX_OUTPUT_TOKENS = 500;

// Best-effort per-user limit (instances are short-lived); provider quotas are the hard cap.
const WINDOW_MS = 10 * 60_000;
const MAX_PER_WINDOW = 20;
const hits = new Map<string, number[]>();

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
const fail = (status: number, code: string) => json(status, { error: code });

function userIdFrom(req: Request): string {
  // The platform has already verified this JWT; we only read its subject for rate limiting.
  try {
    const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
    const payload = JSON.parse(atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof payload.sub === "string" ? payload.sub : "anon";
  } catch {
    return "anon";
  }
}

function rateLimited(key: string): boolean {
  const now = Date.now();
  const recent = (hits.get(key) ?? []).filter((t) => now - t < WINDOW_MS);
  recent.push(now);
  hits.set(key, recent);
  return recent.length > MAX_PER_WINDOW;
}

type AppFacts = {
  alertsConnected?: boolean;
  centersVerified?: boolean;
  guidebookHasContent?: boolean;
};

type HouseholdContext = {
  householdSize?: number;
  hasChildren?: boolean;
  hasSeniors?: boolean;
  hasPets?: boolean;
  hasAssistanceNeeds?: boolean;
  barangay?: string;
  readinessScore?: number;
  missingSupplies?: string[];
  waterDays?: number;
  checklistDone?: number;
  checklistTotal?: number;
};

function systemPrompt(language: string, facts: AppFacts, ctx: HouseholdContext | null): string {
  const lang = language === "fil"
    ? "Reply in natural, everyday Filipino (Taglish is fine where Filipinos would use English words). If the user writes in English, reply in English."
    : "Reply in clear, simple English. If the user writes in Filipino or Taglish, reply in Filipino.";

  const known = [
    `- Live hazard alerts connected to the app: ${facts.alertsConnected ? "yes" : "NO. You have no current alerts, weather or flood data."}`,
    `- Evacuation centers in the app: ${facts.centersVerified ? "verified official data" : "UNVERIFIED development samples, not real centers. Never present them as real."}`,
    `- Disaster guidebook content: ${facts.guidebookHasContent ? "available in the app" : "not written yet"}`,
  ].join("\n");

  const household = ctx
    ? `The user agreed to share this household summary (use it to personalise advice; do not repeat it back unprompted):\n${JSON.stringify(ctx)}`
    : "No household details were shared. Ask a short question if personal details would change your advice.";

  return `You are Tol, the friendly preparedness companion in TolongApp, a disaster-preparedness app for households in Quezon City, Philippines.

Your job: help people prepare. Go-bags, supplies, household plans, understanding the app's readiness score and supply coverage, how to use TolongApp's features (Home, Prepare checklist, Supply coverage, Safe places map, Offline readiness, Settings), and general, widely accepted preparedness education.

Hard rules:
1. You are NOT an official emergency authority. For current conditions and evacuation orders, point to official sources: Quezon City DRRMO, PAGASA (weather), PHIVOLCS (earthquakes/volcanoes), NDRRMC, and barangay officials.
2. Never invent or guess: active hazards, flood levels, weather forecasts, rescue operations, shelter locations/availability/capacity, road conditions, or phone numbers. If you don't have the data, say so plainly.
3. The only phone number you may give is 911 (the Philippines' national emergency hotline), and only for immediate danger.
4. Never claim a route or place is safe. You may say a route has "lower known risk based on available data" only if the app has given you such data. It currently has not.
5. If someone describes an emergency happening now (trapped, injured, rising water around them), tell them first to call 911 or alert people nearby, move to higher ground if it is safe to do so, and follow officials. Keep it short.
6. Medical topics: basic first aid awareness only; urge professional help for anything serious.
7. Stay on preparedness and the app. Politely decline unrelated requests.
8. Be warm, calm and brief: short paragraphs or 3–6 bullet points. No markdown tables.

What the app actually has right now:
${known}

${household}

${lang}`;
}

// Removes phone-number-like sequences (7+ digits) so an invented hotline can never reach the user.
function guardOutput(text: string, language: string): string {
  const note = language === "fil" ? "[tinanggal ang numero, tingnan ang opisyal na pinagkunan]" : "[number removed, check official sources]";
  return text.replace(/(\+?\d[\d\s().-]{5,}\d)/g, (m) => (m.replace(/\D/g, "").length >= 7 ? note : m));
}

async function callProvider(system: string, messages: Msg[]): Promise<string> {
  const provider = Deno.env.get("TOL_PROVIDER") ?? "anthropic";
  const model = Deno.env.get("TOL_MODEL");
  const signal = AbortSignal.timeout(25_000);

  if (provider === "anthropic") {
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      signal,
      headers: {
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({ model: model ?? "claude-haiku-5-5", max_tokens: MAX_OUTPUT_TOKENS, system, messages }),
    });
    if (res.status === 429) throw new Error("quota");
    if (!res.ok) throw new Error(`upstream ${res.status}`);
    const data = await res.json();
    return (data.content ?? []).filter((c: { type: string }) => c.type === "text").map((c: { text: string }) => c.text).join("\n");
  }

  if (provider === "gemini") {
    const m = model ?? "gemini-2.5-flash-lite";
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent`, {
      method: "POST",
      signal,
      headers: { "x-goog-api-key": Deno.env.get("GEMINI_API_KEY") ?? "", "content-type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: messages.map((x) => ({ role: x.role === "assistant" ? "model" : "user", parts: [{ text: x.content }] })),
        generationConfig: { maxOutputTokens: MAX_OUTPUT_TOKENS },
      }),
    });
    if (res.status === 429) throw new Error("quota");
    if (!res.ok) throw new Error(`upstream ${res.status}`);
    const data = await res.json();
    return (data.candidates?.[0]?.content?.parts ?? []).map((p: { text?: string }) => p.text ?? "").join("");
  }

  if (provider === "openai") {
    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      signal,
      headers: { "authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY") ?? ""}`, "content-type": "application/json" },
      body: JSON.stringify({
        model: model ?? "gpt-5.4-nano",
        max_completion_tokens: MAX_OUTPUT_TOKENS,
        messages: [{ role: "system", content: system }, ...messages],
      }),
    });
    if (res.status === 429) throw new Error("quota");
    if (!res.ok) throw new Error(`upstream ${res.status}`);
    const data = await res.json();
    return data.choices?.[0]?.message?.content ?? "";
  }

  throw new Error("not_configured");
}

function validMessages(raw: unknown): Msg[] | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const msgs = raw.slice(-MAX_MESSAGES).map((m) => ({
    role: (m?.role === "assistant" ? "assistant" : "user") as Role,
    content: String(m?.content ?? "").slice(0, MAX_CHARS_PER_MESSAGE),
  })).filter((m) => m.content.trim().length > 0);
  if (msgs.length === 0 || msgs[msgs.length - 1].role !== "user") return null;
  // Providers require the conversation to start with the user.
  while (msgs.length && msgs[0].role !== "user") msgs.shift();
  let total = 0;
  for (let i = msgs.length - 1; i >= 0; i--) {
    total += msgs[i].content.length;
    if (total > MAX_TOTAL_CHARS) return msgs.slice(i + 1);
  }
  return msgs;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return fail(405, "method_not_allowed");

  const provider = Deno.env.get("TOL_PROVIDER") ?? "anthropic";
  const keyName = { anthropic: "ANTHROPIC_API_KEY", gemini: "GEMINI_API_KEY", openai: "OPENAI_API_KEY" }[provider];
  if (!keyName || !Deno.env.get(keyName)) return fail(503, "not_configured");

  if (rateLimited(userIdFrom(req))) return fail(429, "rate_limited");

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return fail(400, "invalid_request");
  }
  const messages = validMessages(body.messages);
  if (!messages) return fail(400, "invalid_request");
  const language = body.language === "fil" ? "fil" : "en";
  const facts = (typeof body.facts === "object" && body.facts) ? body.facts as AppFacts : {};
  const shareContext = Deno.env.get("TOL_SHARE_CONTEXT") !== "false";
  const ctx = shareContext && typeof body.context === "object" && body.context ? body.context as HouseholdContext : null;

  try {
    const reply = (await callProvider(systemPrompt(language, facts, ctx), messages)).trim();
    if (!reply) return fail(502, "empty_reply");
    return json(200, { reply: guardOutput(reply, language), provider, model: Deno.env.get("TOL_MODEL") ?? null });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "";
    if (msg === "quota") return fail(429, "quota_exceeded");
    if (msg === "not_configured") return fail(503, "not_configured");
    return fail(502, "upstream_error");
  }
});
