# ITERATION_GUIDANCE.md — sphinx-doc__sphinx-7590

Feedback package for the next generate → formalize → verify pass. The audit found
**no correctness defect**, so the headline recommendation is **confirm V1**. The
items below are clarifications, optional polish, escalation boundaries, and the
test map — none block shipping.

---

## A. UltimatePowers questions (intent the spec could not settle from the issue alone)

1. **Ill-formed numeric tokens** (FINDING 4). For `123f` (an `f` suffix on an
   integer — illegal in C++) should the C++ domain (a) treat it as a UDL
   `123`+`f` *[V1 behavior]*, (b) keep the old greedy reading `123f` as one number,
   or (c) emit a parse warning? V1 picked (a) because it is the grammar-faithful
   reading and never crashes. Same question for `1e`, `0789`, `1.0LL`. *Low stakes:
   all are ill-formed input; any deterministic answer is acceptable.*

2. **Reserved vs library ud-suffixes.** C++ reserves ud-suffixes that do not begin
   with `_` for the standard library. Should the parser *warn* on a non-`_` suffix
   (e.g. `1q_s` is fine, but `1bogus` is technically reserved)? V1 is deliberately
   lenient (a documentation tool should render, not police). Recommend keeping
   lenient unless users ask for diagnostics.

3. **Encoding-prefixed and raw strings** (FINDING 10). `L"x"_s`, `u8"x"_s`,
   `R"(x)"_s` are not parsed today because `_parse_string` only handles a bare `"`.
   Is prefixed/raw-string support in scope for a follow-up? It is **orthogonal** to
   UDLs (the gap pre-dates this fix) but would complete UDL coverage for strings.

## B. Recommended next code/spec changes (all optional)

- **Optional simplification (FINDING 9):** drop the redundant `(?![uUlL])`
  look-aheads from `integers_literal_suffix_re`; the trailing `\b` already enforces
  "complete suffix" (LEM-\b). *Not done in this pass* — it touches a verified regex
  for zero behavioral gain, against the minimal-change principle. If done, re-run
  PO-2/PO-6 against `5u/5ul/5ull/5LL/5llu/1u_s/1ull` to confirm no classification
  change.
- **No change to `get_id`** — the v1 `NoOldIdError` guard is intentionally *not*
  added (PO-9 / FINDING 5: unreachable, and sibling literal classes never raise).
- **Follow-up issue (out of scope):** prefixed/raw string literals in
  `_parse_string` (FINDING 10), which would then flow through `_udl` for free.

## C. Escalation boundaries (capability gaps, NOT code bugs)

- **Full pp-number tokenization.** The C++ lexer first forms a maximal *pp-number*
  and only then interprets it. V1 (like the original code) approximates this with
  per-form regexes. This is adequate for every well-formed literal and for the
  issue, but a *fully* faithful model of the ill-formed cases in FINDING 4 would
  need the pp-number grammar. Marked `[ESCALATION BOUNDARY]`: not required for
  correctness on the verified (well-formed) domain; route to the C++ lexical grammar
  if exhaustive ill-formed-input behavior is ever specified.
- **`re`-in-K.** The proof trusts Python's `re` engine (PROOF §R). Machine-checking
  the regex disambiguation (LEM-\b, SC-ORDER) would need a regex semantics in K —
  the roadmap "real per-language semantics" item.

## D. Test map — keep / add / redundant

**Recommendation-only; never auto-delete. All redundancy is conditioned on
machine-checking (`kprove` ⇒ `#Top`), which has not been run (MVP).**

**Keep (out-of-contract or integration — the proof does not cover these):**
- Any test asserting the *rendered HTML / xref* of a UDL signature (DESC is about
  node construction; end-to-end rendering is integration). Keep.
- Tests pinning behavior on **ill-formed** input (`123f`, `1e`, `0789`) if any exist
  — these live exactly where FINDING 4's judgement call sits, outside the
  well-formed domain the proof covers. Keep.
- Tests for `c.py` (C domain) literals — untouched scope (PO-13). Keep.
- Parser-integration tests that a UDL *inside a larger declaration* round-trips
  (the proof covers `_parse_literal`'s unit contract, PO-12, not the whole grammar
  wiring). Keep.

**Subsumed-once-machine-checked (in-domain input/output points entailed by the
contract):** if the suite contains point tests like
- `1q_s` parses & `str()=="1q_s"` & id `clL_Zli3q_sEL1EE` → entailed by PO-3/7/8;
- `1.0_w` / `"a"s` / `'a'_c` round-trip → entailed by CASE F2/S/C + PO-7;
- `1ull`/`1.0f` still parse as plain numbers → entailed by PO-2/PO-6,
each is a single in-domain point the universal contract already covers; flag as
*candidate redundant after machine-checking*, **but keep at least one representative
of each CASE (F1/F2/F3, I1/I2, S, C, B, N) as a guard against semantics drift**.
Estimated CI saving is negligible here (a handful of microsecond parse asserts), so
the conservative call is **keep them all** until `kprove` is run — the value of this
fix is benefit #2 (the audit), not benefit #1 (test pruning).

**Add (gaps the audit suggests pinning):**
- `1u_s` ⇒ UDL with suffix `u_s` (guards LEM-\b / FINDING 3 — the subtle case).
- `true_x` / `nullptr_t` ⇒ *names*, not UDLs (guards PC-NOBOOLUDL / FINDING 1).
- `1 q_s` (with space) ⇒ number `1` then separate token (guards PC-NOWS / FINDING 2).
- `6.62607015e-34q_J * 1q_s` ⇒ parses (the issue regression test, PO-1).

## E. Decision

**Confirm V1 unchanged.** Every proof obligation PO-1…PO-14 is discharged (modulo
the trusted regex base) or vacuous by domain (PO-9). No `[BUG]` finding exists; the
only judgement calls are on ill-formed input where any deterministic answer is
acceptable. The two candidate edits (regex look-ahead simplification; v1 id guard)
were both **rejected** with reasons traced to FINDING 9 and FINDING 5 / PO-9
respectively. Rationale recorded in `reports/fvk_notes.md`.
