# ITERATION GUIDANCE — next-pass feedback for `_check_regexp_csv`

Proof-derived feedback from `/verify`. Each item: **evidence →
classification → UltimatePowers question → recommended change → tests.** Items
acted on in this iteration are marked **[DONE V2]**; deferred ones are
**[OPEN]**.

---

## G1 — Empty/whitespace CSV field → match-all regex  **[DONE V2]**
* **Evidence:** PROOF.md §4 stuck VC (`emitᵥ₁ ≠ emit`); PROOF_OBLIGATIONS PO6;
  Finding F2.
* **Classification:** code bug (regression vs. `_splitstrip`) — silent
  undefined-ish behavior (an empty pattern matches everything).
* **UltimatePowers question:** "When a CSV field is empty/whitespace, should
  pylint (a) silently drop it [legacy `_splitstrip` behavior], (b) error, or (c)
  treat `''` as a literal match-all pattern?" — Answer adopted: **(a)**, to
  preserve the long-standing `_splitstrip` contract and avoid surprise.
* **Change made:** add `if stripped:` guard before `yield` in
  `_check_regexp_csv` (`pylint/utils/utils.py`). Restores split/strip/**drop
  empty**.
* **Tests:** add a case `"a, ,b" → ["a", "b"]` and `"  " → []` (keep, see
  Benefit-1 note below).

## G2 — Comma inside an *unclosed* `{`  **[OPEN, by design]**
* **Evidence:** Finding F3; PROOF_OBLIGATIONS PO4 "else" row.
* **Classification:** underspecified intent (an explicitly accepted heuristic).
* **UltimatePowers question:** "Should an unbalanced `{` in a name regex be
  rejected with a clear error, or silently treated as a literal `{` (current
  Python + current pylint behavior)?"
* **Recommended change:** none now; if rejection is desired, validate brace
  balance in `_regex_transformer` or document the heuristic in the option help.
* **Tests:** keep any test pinning current behavior of malformed regexes (it is
  out-of-spec-domain behavior — exactly where Findings bugs hide).

## G3 — `_regexp_paths_csv_transfomer` has the same comma-in-quantifier bug  **[OPEN, out of scope]**
* **Evidence:** Finding F4.
* **Classification:** code bug (same class as F1) in a sibling transformer not
  exercised by this issue/test.
* **UltimatePowers question:** "Do `ignore-paths` / other `regexp_paths_csv`
  options need the same quantifier-aware splitting, or are path regexes with
  `{m,n}` quantifiers out of support?"
* **Recommended change:** if yes, route `_regexp_paths_csv_transfomer` through
  `_check_regexp_csv` (before the PureWindowsPath/POSIX rewrite) instead of
  `_csv_transformer`. Deferred to keep this fix minimal and targeted.
* **Tests:** add a `regexp_paths_csv` analogue only when that change is made.

## G4 — Long-term: deprecate CSV-of-regexes entirely  **[OPEN, product decision]**
* **Evidence:** the maintainer thread (DanielNoord/Pierre-Sassoulas) favored
  eventually removing comma-splitting (commas are meaningful in regexes) and
  letting users join with `|`.
* **Classification:** underspecified long-term intent / API evolution.
* **UltimatePowers question:** "For pylint 3.x, keep quantifier-aware CSV
  splitting, or deprecate it and introduce non-splitting single-regex options?"
* **Recommended change:** none in this fix; the V2 patch is the agreed
  short-term repair and is forward-compatible with a later deprecation.

## G5 — Generator return type / single-use iterator  **[OPEN, informational]**
* **Evidence:** Finding F6.
* **Classification:** interface caveat.
* **Recommended change:** none required (sole caller materializes it). If the
  helper is exposed more widely, consider returning a `list` to match the
  sibling `_check_csv` and to be re-iterable; behavior (values) is identical.
* **Tests:** if tested directly, iterate once or wrap in `list(...)`.

---

## Tests — add / keep / (conditionally) remove

**Add** (regression guards for the spec):
- `_regexp_csv_transfomer("(foo{1,3})")` → one pattern `(foo{1,3})` (F1).
- `"(foo{1,3}),(bar{1,2})"` → two patterns (F1).
- `"foo, bar"` → `["foo", "bar"]` (strip).
- `"a, ,b"` → `["a", "b"]` and `"  "`/`""` → `[]` (F2 regression guard — **the
  test that distinguishes V2 from V1**).
- an invalid regex (e.g. `"(foo"`) → `argparse.ArgumentTypeError`, not a crash.

**Keep** (out of verified domain or not about the unit):
- malformed-brace / malformed-regex behavior tests (G2) — out-of-domain.
- any end-to-end config/CLI test that loads `bad-names-rgxs` (integration).

**Conditionally remove — NOT NOW.** Benefit-1 test-redundancy is **gated twice**:
the proof is *constructed, not machine-checked* (run the §6 `kprove` commands
first) **and** PO8 (unbounded string/list induction) is still an open
[ESCALATION BOUNDARY]. Until both are closed, **keep all existing tests.** No
removal is recommended in this iteration.
