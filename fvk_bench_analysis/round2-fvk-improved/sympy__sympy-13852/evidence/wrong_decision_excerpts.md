# The wrong decision — key artifact + transcript excerpts (round 2)

The round-1 failure was a refusal to ACT (verdict STATED): the agent read the
issue's pre-fix display `Out[1]: polylog(2, 1/2)` as a binding "stays-unevaluated"
invariant and made NO behavioral edit. In round 2 the hardened materials
(submodule 275cd44, "harden audit posture against rejecting a named correct fix")
**fixed that specific refusal** — the agent explicitly *rejected* the
stays-unevaluated symptom (S1) and *did* act. But it reached the SAME wrong
placement by a NEW route: it manufactured a fresh positive-evidence tie-breaker.

---

## A. The hardened rule the agent was following (submodule 275cd44)

`third_party/formal-verification-kit/commands/verify.md` (the "Forced choices" rule):

> **"Forced" choices are hypotheses to falsify, not premises.** … name the
> concrete alternative; write its predicted output explicitly; re-derive the
> legacy/backward-compat trace under **both candidates side by side** … If both
> candidates satisfy the public obligations the choice is **under-determined, not
> forced** — record it as open, **never as CONFIRM**. Never … predict a hidden
> test's value from such an argument …

`knowledge/intent-evidence.md` §4.7 (mirror) and AGENTS.md §3/§6 say the same, and
AGENTS.md §6 (new): "Audit against the **full intent** — the whole problem
statement plus the docstring/API contract — not just the issue sentence."

The agent obeyed the *letter* of all of this. The gap is what happens AFTER
"under-determined": the rule forbids CONFIRM **on the forcing argument**, but is
silent on resolving the now-"open" point via a *second* heuristic and then keeping V1.

---

## B. The agent DID drop the round-1 symptom argument (hardening worked here)

`fvk/INTENT_SPEC.md:45-51` (S1 marked SUSPECT, not an obligation):

> **S1 — "`polylog(2, 1/2)` prints unevaluated."** … that display is the
> **symptom being reported**, not a required invariant. We must NOT add an
> obligation "stays unevaluated by default", and must NOT use it to justify a no-op.

Transcript `transcripts/fvk.jsonl.gz` (assistant, early): the agent cites the
hardened warning by name:

> `intent-evidence.md` contains a pointed warning about *this exact issue*: an
> issue showing `polylog(2, 1/2)` printing unevaluated is reporting that as the
> symptom — I must not enshrine "stays unevaluated" as an invariant.

So the round-1 fatal step is gone. The agent acted (46-line patch).

---

## C. The NEW fatal step — a fabricated positive-evidence tie-breaker (the heart)

The agent ran the required side-by-side derivation, found both placements satisfy
the *explicit* `.expand(func=True)` obligation, correctly labelled it
"under-determined" — and then chose the WRONG branch (A = `_eval_expand_func`)
using a constructed reading of an UNRELATED test's pattern.

`fvk/SPEC_AUDIT.md:22-54` (Design decision D1), the decisive table + verdict:

> | Obligation | A: value in `_eval_expand_func` (V2) | B: value in `eval` (auto) |
> | `polylog(2,1/2) == answer` (auto, if tested) | ❌ stays a `polylog` object | ✅ |
> | Public-test *pattern* (universal-`z` → `==`; specific-`(s,z)` → `myexpand`) | ✅ `(2,1/2)` is specific ⇒ `myexpand`/`expand_func` group | ➖ would be the only specific value tested by `==` |
> …
> **Verdict: A (V2) is the better-justified choice — but NOT because it preserves
> the unevaluated symptom.** It is chosen on *positive* grounds: (1) the public-test
> structure in `test_polylog_expansion` tests every **specific-`(s,z)`** reduction
> … through `myexpand`/`expand_func` and reserves bare `==` for **universal-`z`**
> reductions … `(2, 1/2)` is specific, so the expand-func path matches the
> established intent encoding.

TWO compounding errors are visible in this single table:

1. **The agent foresaw the exact failure and bet against it.** Row 2 literally
   records that under placement A, `polylog(2,1/2) == answer` is "❌ stays a
   `polylog` object" — and it qualifies the row "(auto, **if tested**)". The hidden
   test `test_polylog_values` tests *precisely* the bare `==` form (and on
   `polylog(2, 2)` first). The agent treated "is the bare form tested?" as an
   open hypothetical and resolved it toward "probably not" — the one thing the
   verify.md rule warns against ("never predict a hidden test's value").

2. **The tie-breaker generalises the WRONG sibling.** It reads
   `test_polylog_expansion`'s "specific-(s,z) → expand_func / universal-z → ==" as
   a *project convention*. But that test is the LEGACY expansion test; the issue's
   own desired form is a closed-form VALUE ("The answer should be
   -log(2)**2/2 + pi**2/12"), and gold makes it a construction-time value. The
   agent let an implementation/test-shape heuristic override the issue's explicit
   desired output — exactly the "implementation facts are not the desired
   semantics" failure the kit warns about, but laundered through "positive grounds".

`fvk/INTENT_SPEC.md:64-70` shows where the convention was crystallised into
D-dom2 and used to *place* I1:

> **D-dom2 — `expand_func` is opt-in expansion.** … automatic `eval` is reserved
> for universal reductions … This convention is what places I1 in
> `_eval_expand_func` rather than `eval` …

---

## D. Coverage was still dismissed by name (unchanged from round 1)

`fvk/INTENT_SPEC.md:72-76` (Out of scope) and `fvk/FINDINGS.md:55-60` (F5):

> Other special dilogarithm arguments (e.g. `2`, golden-ratio values). The issue
> names only `1/2`.
> … The fix adds exactly one special value (the only one the issue names). Other
> dilog special arguments … are **not** added …

These six golden-ratio/Landen args are exactly the hidden test's continuity sweep.
But coverage is the *secondary* gap here: even the one value it added (z=1/2) is
in the wrong method, and the test's first assertion (`polylog(2, 2)`) fails on
placement+coverage together.

---

## E. The agent's own honest hedge it then overrode

`fvk/FINDINGS.md:50-54` (F4 UltimatePowers question):

> **UltimatePowers question for the maintainer:** "Should `polylog(2, 1/2)`
> evaluate automatically (like `zeta(2)→π²/6`), or only under `expand_func` …?"
> **Either is defensible**; the codebase convention says `expand_func`.

The agent correctly identified the decision as genuinely open ("either is
defensible") and even named the *correct* analogy (`zeta(2)` auto-evaluates in
`eval`). Then it broke the tie toward the wrong side and CONFIRMED V1, instead of
either (a) producing the auto-eval form, or (b) leaving the obligation genuinely
open / hedging toward the construction-time value that the desired-output evidence
points at. "Record it as open" had no pipeline exit other than "keep V1".
