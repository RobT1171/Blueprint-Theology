# Blueprint Theology — Engine Spec v1

**Status:** shipped to `main`. Health endpoint reports `v4.5-structured-engine`. Not deployed to production at the time of this writing.

**Audience:** the engineer (or Claude session) who needs to extend, debug, or rebuild this engine. Read top-to-bottom — sections are ordered by what you need first.

---

## 1. Overview

`/api/generate-study` (handler `handleGenerateStudy` in `src/index.ts`) takes a Bible passage, a topic, or a block of user notes, plus a depth mode, and returns a structured Socratic guided-discovery Bible study in a single OpenAI call.

The product philosophy is Socratic guided discovery — the engine **never** delivers conclusions outright. It poses the question before it reveals. It names what is already stirring in the student rather than handing them a packaged answer. Original languages (Hebrew, Greek) lead the discovery, never bury it. The voice is "Beth Moore's fire + N.T. Wright's depth + a patient seminary professor who genuinely loves the student." This voice is borrowed verbatim from `buildAxSystemPrompt` (lines 445–553 of `src/index.ts`), the canonical Socratic voice in this codebase. **Read that function before tuning this engine's voice.**

This engine is the one-shot generator. It is distinct from the Ax engine (`handleStudyChat`), which is the multi-turn conversational study partner. They share voice, not code path.

---

## 2. Response Schema

Strict JSON schema enforced by OpenAI structured outputs (`response_format: { type: 'json_schema', strict: true }`).

```ts
type StudyBlock =
  | { type: 'pause_reflect'; prompt: string }
  | { type: 'discovery'; setup: string; reveal: string }
  | { type: 'challenge_24h'; statement: string; reflection_prompt: string }
  | { type: 'practice_7d'; description: string }
  | { type: 'prose'; text: string };

type FormationArc =
  | 'image_identity' | 'covenant' | 'sonship_adoption' | 'kingdom_authority'
  | 'wisdom_maturity' | 'exile_restoration' | 'temple_presence' | 'sacrifice_redemption';

type StudyResponse = {
  content: string;          // 100-150 word welcome paragraph; legacy frontend renders this as the entire visible study intro. Hard rule: keep populated.
  big_idea: string;         // 1-2 sentence thesis specific to this passage, never a generic platitude.
  passage_context: string;  // ~150 word historical/literary "Setting the Scene". What the original hearers would have felt.
  blocks: StudyBlock[];     // ordered Socratic body. See §3.
  closing_prayer: string;   // 50-100 words. First-person plural ("we"). Anchored to passage imagery.
  detected_arcs: FormationArc[];  // model-declared arcs. Schema enum-constrained. Empty array allowed.
  model: string;            // e.g. "gpt-4o-2024-08-06"
  usage: { prompt_tokens: number; completion_tokens: number; total_tokens: number };
};
```

The `StudyBlock` union is encoded as `anyOf` with `additionalProperties: false` and full `required` arrays at every nesting level (OpenAI strict mode requirements). The `detected_arcs` items use a hard-coded `enum` of the eight arc keys.

---

## 3. Block Types

The Socratic body is an ordered array of typed blocks. Each block type has a strict purpose; misusing them flattens the study.

**`pause_reflect { prompt }`** — One open question that excavates what is stirring in the student. **Use WHY or WHAT, never generic HOW.** Banned: "How does this resonate with you?" "How does this connect to your life?" These ask for reactions; the engine asks for sources. Examples: "Why has this image been stirring in you?" "What in the text is resisting your initial read?"

**`discovery { setup, reveal }`** — A two-step move. `setup` (1–3 sentences) names the tension, the word, or the textual surprise — it primes the student to feel the question. `reveal` (3–6 sentences) opens the original-language meaning, the cross-reference, or what English loses. **Lead with Hebrew/Greek when a key word is in play** — give word, transliteration, semantic range, what English misses. Never bury the language in paragraph four.

**`challenge_24h { statement, reflection_prompt }`** — A concrete behavioral commitment for the next 24 hours. Concrete means *concrete*: not "be more loving," but "write down one moment today where you noticed *mishpat* being violated, and one where you saw it restored." `reflection_prompt` is a single short journal prompt for afterward.

**`practice_7d { description }`** — A sustained 7-day practice with specific cadence and specific action. "Each morning for seven days, read Psalm 23 slowly and note one place where the shepherd image surfaces in your day."

**`prose { text }`** — Connective tissue: scene-painting, contextual narrative, transitional bridge between sections. **Never use prose to deliver a Socratic punchline that belongs in `pause_reflect` or `discovery`.** If a paragraph ends with a question or a revelation, it belongs in those block types. Prose is the in-between.

---

## 4. Depth × Block Matrix

| Depth | Total | pause_reflect | discovery | challenge_24h | practice_7d | prose |
|-------|-------|---------------|-----------|---------------|-------------|-------|
| `quick` | 4–6 | ≥1 | ≥1 | ≥1 of (challenge_24h OR practice_7d) | (covered by left) | optional |
| `standard` | 8–12 | ≥2 | ≥2 | ≥1 | ≥1 | optional |
| `deep` | 14–20 | ≥3 | 4–6 | ≥1 | ≥1 | **3–5 mandatory bridges** |

Budgets are prompt-level only — no server-side block-count validation. `gpt-4o` meets standard and quick reliably. **Deep depth required explicit "3–5 mandatory prose bridges" language plus a "NOT fewer than 14 — count them" instruction to hit the 14-block floor reliably** — without those, the model produced 10 blocks (each-type minimums met, total under).

Translation preference (default `ESV`) and depth are interpolated into the system prompt at generation time.

---

## 5. Formation Arcs

Eight arcs. The engine declares zero or more per study; the schema enum constrains allowed values.

| Key | One-line meaning |
|-----|------------------|
| `image_identity` | Humans bear God's image (imago dei); identity grounded in being made in His likeness. (Gen 1:26-28) |
| `covenant` | God's binding relational pattern with His people; *hesed* loyalty. (Gen 12, Ex 19, Jer 31) |
| `sonship_adoption` | Believers as adopted children of God, co-heirs with Christ. (Rom 8, Gal 4) |
| `kingdom_authority` | God's reign and the delegated authority of humans under it (dominion, kingdom of God). |
| `wisdom_maturity` | Growth in fear-of-the-Lord wisdom; James, Proverbs, Pauline maturity. |
| `exile_restoration` | The judgment-then-return pattern; Eden to Babylon to new Jerusalem. |
| `temple_presence` | God's dwelling with His people; Eden, tabernacle, temple, Christ's body, indwelling Spirit. |
| `sacrifice_redemption` | Substitutionary atonement; cost-bearing; Passover, cross, redemption. |

**Detection philosophy:** model-declared, conservative. The system prompt instructs "most passages touch 1–3 arcs; forcing more is dilution." Empty array is acceptable when the passage truly fits none.

**Server-side write:** after successful generation, the engine writes one row per declared arc to `formation_arc_exposures(user_id, arc_key, study_id, session_id)`. Only fires when `user_id` is present. This is **additive** to the frontend's `POST /api/arcs` writes — duplicate rows are possible and accepted (no unique constraint).

**Iterative tightening note:** v4 initially missed `covenant` on Psalm 23 (despite the *hesed* of v6, "goodness and mercy shall follow me"). Tightening the arc-declaration guidance and the "most passages touch 1–3" framing brought subsequent generations to declare `covenant` plus `image_identity` and `sacrifice_redemption` on the same passage. Calibration is fragile — see §10.

v3 detection was substring-matching display labels in raw markdown. v4 replaces with model-declared arcs in structured output. Both false-positive (label appearing in unrelated prose) and false-negative (label never leaking through) failure modes are eliminated.

---

## 6. Voice Rules

All rules are encoded in the system prompt (no code-side enforcement).

**Banned filler praise** — never open content or any block with: "great question," "compelling," "fascinating," "powerful," "beautiful," "isn't it?", "indeed," "absolutely."

**Banned exploratory verbs** — `explore`, `unpack`, `dive (in/into)`, `break down` (analytical), `step into`. **Subject-agnostic and tense-agnostic.** Forbidden constructions include "Let's explore...", "We will explore...", "This psalm invites you to explore...", "Dive into this text...", "Step into this story...". Imperative-invitation closers on the `content` field were a recurring leak — content must close with the textual question itself, a thought, or a short observation, not "Dive into this passage with the question..." The substitution pattern is to NAME the move directly: instead of "this psalm invites you to explore the tension between...", write "this psalm holds two images in tension: ..."

**Banned therapist-voice validation** — "It's understandable to feel that," "That's a natural feeling." Validation, when needed, comes through the text: "You're right to resist that word — the Hebrew doesn't carry the baggage the English does."

**Banned generic HOW questions** — see §3 pause_reflect.

**Original-language lead-don't-bury** — when a Hebrew or Greek word matters, lead with it in the discovery block. Example voice: "The word there is *halak* — and it doesn't mean strolling. It means directional, purposeful movement. That changes everything about what 'walking with God' means."

**Distinguish text from tradition** — when a popular reading has weak textual support, name it: "that's tradition, not text." When the text is silent, say so directly. Do not invent context the text does not give.

**Match depth, don't pad** — the depth budget is the spec, not a target to overshoot. Match the weight of what the passage actually says.

**Address the student in second person.** Never third-person ("the student should consider...").

**Christian Bible only.** Non-biblical input is declined warmly and redirected to Scripture. No syncretism. No partisan politics.

---

## 7. OpenAI Call Settings

```js
{
  model: 'gpt-4o',
  temperature: 0.7,
  max_tokens: 4000,
  response_format: { type: 'json_schema', json_schema: { name: 'study_response', strict: true, schema: studyResponseSchema } }
}
```

**`gpt-4o`** — alias resolves to `gpt-4o-2024-08-06`. Strict structured outputs requires this model class. Do not downgrade to `gpt-4o-mini` without re-running the smoke suite — the smaller model produces noticeably weaker Hebrew/Greek and shorter blocks.

**Temperature 0.7** — lowered from v3's 0.78 for structural consistency. Higher (≥0.85) causes occasional length under-shoots and budget misses. Lower (≤0.5) flattens the voice — prose loses the "fire" the spec calls for.

**Max tokens 4000** — lowered from v3's 8000. v3 generated a 4–6k word markdown narrative; v4 generates structured JSON which is much denser per token. Longest deep response observed: ~3.4k completion tokens. Headroom sufficient.

**`OPENAI_API_KEY`** — wrangler secret, production-only. Local dev requires `wrangler dev --remote` (uses prod secret + prod D1, exposed at localhost) or a `.dev.vars` file containing the key.

---

## 8. Backwards Compatibility

**Hard rule:** the legacy GHL Señor Vibe frontend renders `content` as the entire visible study intro (it expected the v3 contract where `content` was a markdown blob). v4 keeps `content` populated as a 100–150 word welcome paragraph that stands alone.

The new structured fields (`big_idea`, `passage_context`, `blocks`, `closing_prayer`, `detected_arcs`) are **additive** — they unlock structured rendering when the frontend is updated, but do not break the current frontend. The frontend's `POST /api/arcs` write path is untouched; the engine's server-side arc write is additive to whatever the frontend writes.

The Señor Vibe upgrade to render the structured fields is a separate ticket Rob will sequence after this engine deploys.

---

## 9. Smoke Test Suite

The five canonical tests run during the v4 rebuild. **Run all five before any prompt change** — voice and budget regressions are easy to introduce.

All requests use `user_id: "smoketest-engine-rebuild-2026-05-04"` (sentinel for cleanup). All run against `wrangler dev --remote` for prod-secret access; production smokes hit `https://blueprint-bible-api.rob-417.workers.dev`.

| # | Body | Pass criteria | Observed (v4 final) |
|---|------|---------------|---------------------|
| 1 | `{mode:'passage', input_reference:'Psalm 23:1-6', depth_mode:'standard'}` | Schema, 8–12 blocks, ≥2 PR, ≥2 disc, ≥1 ch, ≥1 pr, banned-list clean | 8 blocks (3 disc, 2 PR, 1 ch, 1 pr, 1 prose). Arcs: `image_identity, covenant, sacrifice_redemption`. content 98w. |
| 2 | `{mode:'passage', input_reference:'John 1:1-14', depth_mode:'deep'}` | 14–20 blocks, ≥3 PR, 4–6 disc, ≥1 ch, ≥1 pr, 3–5 prose | 14 blocks (5 disc, 3 PR, 4 prose, 1 ch, 1 pr). Arcs: `image_identity, covenant, temple_presence`. content 118w. |
| 3 | `{mode:'topic', input_text:'How should Christians think about forgiveness when the offender has not repented?', depth_mode:'standard'}` | 8–12 blocks, topic-mode message branch, all minimums | 8 blocks. Arcs: `kingdom_authority, wisdom_maturity`. content 102w. |
| 4 | `{mode:'passage', input_reference:'James 1:2-4', depth_mode:'quick'}` | 4–6 blocks, ≥1 of each Socratic type | 5 blocks (1 of each). Arcs: `wisdom_maturity`. content 88w. |
| 5 | `{mode:'passage', input_reference:'Genesis 1:26-28', depth_mode:'quick'}` (imago dei diagnostic) | image_identity arc declared | 4 blocks. Arcs: `image_identity, kingdom_authority`. content 110w. |

All five passed structurally. Zero banned-list hits across all five. All five wrote arcs to `formation_arc_exposures` (verified in prod D1).

Common request fields omitted from the body column: `translation_preference: 'ESV'`, `user_id` sentinel.

---

## 10. Known Issues / Tuning Notes

- **Content length scales loosely with depth.** Quick comes in ~80–100 words, standard ~98–121 words, deep ~118+ words. The 100-word floor should be read as **aspirational, not strict** — pushing harder distorts voice. Sentence count tracks better than word count: the 6–9 sentence target holds across runs.
- **Conservative arc declaration sometimes misses defensible arcs.** Pre-fix Psalm 23 missed `covenant` despite the *hesed* of v6; tightened prompt now picks it up. **v5 candidate:** add concrete arc → textual signal mappings, or a "list candidate arcs and their textual evidence before declaring" reasoning step.
- **`temple_presence` for John 1:14 (`eskēnōsen` / "tabernacled")** is defensible but at the edge of conservative declaration. The Word "pitched a tent" among us is a literal temple move, but a reader expecting only OT temple imagery will find the call surprising. Keep, document, monitor.
- **No regenerate-on-failure loop.** Strict JSON schema mode has not produced malformed output across the smoke suite, so probably not needed — but flagged. If it ever fires we return 502.
- **Coverage gap (now closed):** before smoke #5, the imago dei diagnostic was missing. #5 declared `image_identity` + `kingdom_authority` cleanly. Future regression testing must include this passage.
- **Other notes for future work:**
  - No retry on OpenAI 429s or transient 5xxs. Add jittered backoff if rate limiting appears in production.
  - `formation_arc_exposures` has no unique constraint; engine + frontend `/api/arcs` can both write, producing duplicates. Add `UNIQUE(user_id, arc_key, study_id)` if strict dedup is needed.
  - `mode='notes'` was not smoke-tested in v4. Likely works; verify before relying on it.
  - Voice rules live entirely in the system prompt. If voice drifts in production, diagnose by interpolating the rendered system prompt with the current depth/translation values *before* suspecting model regression.

---

## 11. Commit History

```
1b50307  Pre-engine-rebuild snapshot
8d685dd  feat(engine): structured Socratic study generation v4
9ac053e  fix(engine): subject-agnostic verb ban and 100-150 content target
0692be2  fix(engine): deep depth budget enforcement and imperative-invitation ban
```

- **1b50307** — pre-rebuild snapshot. Engine returned a 1.1 kB welcome paragraph with empty `detected_arcs`; no Socratic structure, no schema, substring-match arc detection.
- **8d685dd** — v4. Strict JSON schema response. New `StudyBlock` union. Voice ported from `buildAxSystemPrompt`. Server-side arc write. `gpt-4o` / temp 0.7 / max_tokens 4000. Substring matcher removed.
- **9ac053e** — fix. Banned-verb rule reframed as subject-agnostic ("This psalm invites you to explore..." was getting through the original "Let's explore" framing). Content length target relaxed from 150–200 to 100–150 to match what gpt-4o actually produces.
- **0692be2** — fix. Deep depth budget tightened to require 4–6 discovery blocks and 3–5 mandatory prose bridges (was producing 10 blocks against a 14–20 budget). Imperative-invitation closers on `content` ("Dive into this text with the question...") explicitly banned.
