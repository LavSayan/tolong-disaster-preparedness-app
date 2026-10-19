# Phase 5 — AI provider for Tol

Researched 2026-10-18 from the providers' pricing pages (and secondary sources where an official page couldn't be fetched). Prices change; re-check before you add a card.

## Comparison (cheapest suitable model of each)

| | Google Gemini | Anthropic Claude | OpenAI |
|---|---|---|---|
| Model | Gemini 2.5 Flash-Lite / 3.1 Flash-Lite | Claude Haiku 5.5 | GPT-5.4 nano |
| Price per 1M tokens (in / out) | $0.10 / $0.40 (2.5 Flash-Lite); $0.25 / $1.50 (3.1 Flash-Lite) | $0.10 / $0.50 | ~$0.20 / $1.25 *(secondary sources; openai.com returned 403)* |
| Free tier | **Yes** (limits shown in AI Studio) | No free API tier | No free API tier |
| Training on your data | **Free tier: content is used to improve Google products.** Paid tier: no | API: not used for training by default under Anthropic's commercial terms *(pricing page doesn't state it; confirm in the Commercial Terms)* | API: not used for training by default (opt-in only); up to 30-day retention for abuse monitoring *(secondary summary of OpenAI's policy)* |
| Filipino | All three handle Tagalog/Taglish. No independent benchmark for our use case was found, so **test with your own Filipino prompts** (e.g. "Ano ang dapat ilagay sa go-bag ng pamilyang may sanggol?") before choosing | | |
| Integration | REST `generateContent`; system instruction supported | REST `messages`; system prompt supported | REST `chat/completions`; system message supported |

**Cost of one Tol exchange** (≈1,500 input tokens for safety rules + context + recent history, ≈300 output tokens):
- Haiku 5.5: 1,500 × $0.10/M + 300 × $0.50/M ≈ **$0.0003** → $5 of credit ≈ 16,000 replies
- Gemini 2.5 Flash-Lite (paid): ≈ $0.00027 · free tier: $0 within limits
- GPT-5.4 nano: ≈ $0.0007

## Recommendation

1. **Production / defense demo: Claude Haiku 5.5.** It's among the cheapest per reply, API data isn't used for training by default (important because Tol can see household details with consent), and it follows strict instructions well, which matters for the safety rules. A $5 prepaid credit covers a class demo and pilot many times over.
2. **Zero-cost development: Gemini Flash-Lite free tier**, with **household context switched off** (`TOL_SHARE_CONTEXT=false`), because free-tier content is used to improve Google's products. Tell testers not to type personal details.
3. OpenAI works too, but costs more per reply for this use and has no free tier.

*Disclosure: this comparison was prepared with an Anthropic model. It relies on published prices and terms; please verify the privacy terms yourselves and pick what fits your budget.*

## Architecture (provider-independent)

```
App (Tol chat) ──► Supabase Edge Function `tol-chat` ──► Gemini | Claude | OpenAI
   │                    • holds the API key (never in the APK)
   │                    • safety system prompt + output guard
   │                    • per-user rate limit, input size limits
   └──► offline guide (rule-based, on device) when there's no account, no connection, or an error
```

Switching provider is a secret change, not an app release:

```bash
supabase secrets set TOL_PROVIDER=anthropic TOL_MODEL=claude-haiku-5-5 ANTHROPIC_API_KEY=...
supabase secrets set TOL_PROVIDER=gemini TOL_MODEL=gemini-2.5-flash-lite GEMINI_API_KEY=... TOL_SHARE_CONTEXT=false
```

## Safety design (what makes Tol defensible)
- Tol is told it is **not an official authority**; it must not invent hazards, rescue operations, shelter availability, weather, or phone numbers, and must say when the app lacks data.
- The function tells the model **what the app actually knows**: alerts connected = no; evacuation centers = unverified sample; guidebook = no reviewed content yet. So it can't present demo data as fact.
- **Output guard:** phone-number-looking sequences are removed from replies (except the national emergency number 911), so a hallucinated hotline can't reach the user.
- Every online reply is labelled "AI-generated · may be wrong · not an official advisory"; offline replies are labelled "Offline guidance".
- Household context is sent **only with the user's consent** (off by default), and only as a summary: household size, whether there are children/seniors/pets, barangay, readiness score and missing supply categories. No names, phone numbers or contacts.

## Sources
- Gemini pricing and free-tier data use: https://ai.google.dev/gemini-api/docs/pricing
- Gemini rate limits: https://ai.google.dev/gemini-api/docs/rate-limits
- Claude pricing: https://claude.com/pricing
- OpenAI pricing (secondary): https://morphllm.com/openai-api-pricing · https://curlscape.com/blog/openai-api-pricing-guide-2026
- OpenAI API data-use summary (secondary): https://conductatlas.com/platform/openai/openai-api-data-usage-policies/provision/CA-P-061188/no-default-model-training-on-business-data/
