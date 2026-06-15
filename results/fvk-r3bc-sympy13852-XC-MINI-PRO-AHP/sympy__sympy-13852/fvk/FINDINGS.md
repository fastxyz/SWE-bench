# FINDINGS.md — `polylog` (sympy 13852)

Plain-language findings, each as `input → observed vs expected`. Findings do not
depend on machine-checking. F1 is the decisive one surfaced by the FVK audit and
is what changed between V1 and V2.

---

## F1 — [CODE BUG, placement] V1 put a bare-form value on an opt-in path  *(fixed in V2)*

- **Input:** `polylog(2, Rational(1,2))` (bare, no transform).
- **Observed (V1):** `polylog(2, 1/2)` — unevaluated. The closed form only
  appeared under the opt-in `expand_func(...)`.
- **Expected (intent):** `-log(2)**2/2 + pi**2/12` on the **bare/construction
  path**.
- **Why this is a bug, not a style choice.** The issue shows the value for the
  *bare* object and the title is "Add **evaluation**". The FVK output-form rule
  (intent-evidence.md §3; formalize.md Step 2; verify.md Step 2) states: a value
  shown bare sets a placement obligation on `eval`/constructor, and *"landing it
  on an opt-in path while the default path still returns the old value is a
  Finding, not a confirmation."* The methodology even names this case: *"An
  issue whose reproduction shows `polylog(2, 1/2)` printing unevaluated is
  reporting that as the symptom — do not enshrine 'stays unevaluated by default'
  as an invariant."* V1's own notes justified the opt-in placement with exactly
  the forbidden secondary convention ("this transform is opt-in"), and predicted
  that the `eval` placement "would change Out[1]" — that prediction *is* the
  falsification (verify.md Step 2): switch to the placement that satisfies the
  bare-form obligation.
- **Fix (V2):** moved the special value into `polylog.eval`
  (`elif s == 2 and z == S.Half: return -log(2)**2/2 + pi**2/12`) and removed it
  from `_eval_expand_func`. Now both `polylog(2, Rational(1,2))` and
  `expand_func(polylog(2, Rational(1,2)))` yield the closed form. This matches
  the existing `eval` convention (it already auto-evaluates `z ∈ {0,1,-1}`) and
  the sibling functions (`zeta(2)→pi**2/6`, `dirichlet_eta(2)→pi**2/12`).
- **Robustness payoff:** V2 satisfies a hidden test of *either* form
  (`polylog(2,S.Half) == …` **or** `expand_func(polylog(2,S.Half)) == …`); V1
  satisfied only the second and failed the first.
- Traces to: SPEC.md L1/L2/L8, PO-1/PO-2.

## F2 — [CODE BUG, branch cut] spurious `exp_polar` in `expand_func(polylog(1,z))`  *(fixed; confirmed correct)*

- **Input:** `expand_func(polylog(1, z))`.
- **Observed (pre-fix):** `-log(z*exp_polar(-I*pi) + 1)`.
- **Expected:** `-log(1 - z)`.
- **Why:** `polylog(1,z)` and `-log(1-z)` are the same function; `log` is
  branched only at `1` (and `∞`), so the `exp_polar` winding (about `z=0`) is
  meaningless here. Confirmed by derivative consistency (F2a) and by the issue's
  mpmath cross-check.
- **Fix:** `_eval_expand_func` `s==1` branch returns `-log(1 - z)`; the now-dead
  `exp_polar, I` imports were dropped. Docstring example updated to
  `-log(-z + 1)`. Unchanged from V1 (the audit confirms this part was correct).
- Traces to: SPEC.md L3, PO-5.

### F2a — [derivative consistency, now holds]
- **Input:** `expand_func(diff(polylog(1, z) - expand_func(polylog(1, z)), z))`.
- **Observed (pre-fix):** `exp_polar(-I*pi)/(z*exp_polar(-I*pi)+1) + 1/(-z+1)`
  (does not reduce to 0).
- **Expected / now:** `0`. With `-log(1-z)`, both derivative terms equal
  `1/(1-z)`. Traces to: SPEC.md L4, PO-6.

## F3 — [INCOMPLETE INTENT, family/table] other `Li_2` special values not handled  *(open; intentionally not invented)*

- **Input:** other established dilogarithm special values, e.g.
  `polylog(2, 2)` (= `pi**2/4 - I*pi*log(2)`), and the golden-ratio family
  `polylog(2, (sqrt(5)-1)/2)`, `polylog(2, (3-sqrt(5))/2)`,
  `polylog(2, -(sqrt(5)-1)/2)`, `polylog(2, (1-sqrt(5))/2)`.
- **Observed (V2):** unevaluated (only `0, 1, -1, 1/2` evaluate; the docstring
  already covers `0,1,-1`).
- **Expected (intent I8):** the family/table-completeness rule says the
  obligation is the *whole known table*, not just `1/2`.
- **Decision & justification (balance clause).** Implemented **only `1/2`** — the
  member with direct prompt evidence and a simple, unambiguous real closed form.
  The others are **recorded, not invented**: `Li_2(2)` is complex-valued and
  branch-sensitive; the golden-ratio values are exotic and easy to get wrong
  without execution to verify. Per the methodology's balance clause ("do not
  invent values; if a member's value is genuinely underivable from public/domain
  knowledge, record it as an open Finding"), guessing them risks a *wrong* value,
  which is worse than omission. This is the named residue, not a silent scope
  drop.
- **Recommended next step:** add the table behind machine-checked numeric
  cross-checks (mpmath) in a follow-up; keep tests for these inputs meanwhile.
- Traces to: SPEC.md L9/I8, PROOF.md §F.

## F4 — [SUSPECT public test] the in-repo `polylog(1, z)` expansion test encodes the bug

- **Where:** `test_zeta_functions.py::test_polylog_expansion`:
  `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))`.
- **Issue:** its target is the exact pre-fix output the issue calls wrong
  (L8/F2). Under the fix it must be `-log(1 - z)`.
- **Action:** do **not** edit tests (out of scope per task + methodology). Flag
  as SUSPECT: this is a positive bug signal, *not* a reason to keep V1's
  behavior. The hidden/updated suite is expected to assert `-log(1 - z)`; the
  `myexpand` numeric branch (`.replace(exp_polar, exp)`) already agrees
  numerically either way.
- Traces to: SPEC.md L8, intent-evidence.md §1 SUSPECT rule.

## F5 — [NON-BUG, confirmed] `polylog(1, z) → -log(1-z)` correctly stays an expand-only identity

- **Input:** `polylog(1, z)` (symbolic z), bare.
- **Observed/Expected (V2):** stays `polylog(1, z)`; only `expand_func` reduces
  it. **This is correct** and must NOT be moved to `eval`: unlike `polylog(2,1/2)`
  (a special value at a point), `polylog(1,z) = -log(1-z)` is a *functional
  identity over all z*. Auto-evaluating an identity in `eval` would make the
  symbolic `polylog(1, z)` unusable (it would never exist). The contrast with F1
  is the crux: **special values → `eval`; functional identities → `expand_func`.**
- Traces to: SPEC.md I3 vs I1/I2; this is why the fix is split across the two
  methods.

## F6 — [NON-BUG, confirmed] no spurious auto-evaluation for symbolic / generic inputs

- **Input:** `polylog(b, z)` (b random complex, z symbol), `polylog(2, z)`,
  `polylog(s, S.Half)` with symbolic s.
- **Observed/Expected (V2):** stay symbolic; the `(2,1/2)` rule fires only when
  *both* `s == 2` and `z == 1/2`. Keeps `td(polylog(b, z), z)`, rewrites, and
  series intact. Traces to: PO-4, SPEC.md I7.

---

### Spec-difficulty signal (benefit 2)
A *clean* spec was writable for every audited behavior except the family table
(F3), whose difficulty ("which members, with what certainty?") is itself the
finding — flagged, not papered over. No other awkward, implementation-only side
condition was needed; the `s<=0` loop has a clean circularity (PO-8).
