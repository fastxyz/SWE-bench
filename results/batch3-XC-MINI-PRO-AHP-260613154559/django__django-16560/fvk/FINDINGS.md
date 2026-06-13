# FINDINGS.md — django__django-16560 (V1 fix audit)

Plain-language findings from formalizing the V1 fix, each as
`input → observed vs expected`. Findings are **non-blocking**: they record what the
spec exercise surfaced. Classification tags: [positive] confirms correct behavior;
[design] a deliberate, defensible choice; [assumption] a documented precondition;
[no-regression] preserved legacy behavior. **No finding indicates a bug in V1.**

---

## Findings from `/formalize`

### F1 — Deprecated `*args` path does not (and must not) accept a positional code  [design][no-regression]
- input: `BaseConstraint("the_name", "a message")` (legacy positional usage).
- observed: still maps positionally to `["name", "violation_error_message"]`; the
  new `violation_error_code` is **keyword-only** and untouched.
- expected: exactly this. `violation_error_code` is a brand-new parameter and was
  never a historical positional, so adding it to the deprecation `zip(...)` list
  would invent a new deprecated positional. V1 correctly leaves the list as
  `["name", "violation_error_message"]`.
- This guard is a **no-op on the verified (keyword-only) domain**: per the
  `/formalize` input-validation-guard rule, the in-domain reduction has empty
  `args`, so the `if args:` block never runs. Modeled as such; raise/`warnings.warn`
  control flow not modeled.

### F2 — `validate()` prefix loops are unchanged by the fix  [no-regression]
- input: any constraint instance reaching the violation check.
- observed: the field/expression/constraint iteration that *decides* whether a
  violation occurred is identical to baseline; the fix only adds `code=...` to the
  `ValidationError(...)` constructor at the raise site.
- expected: this. Therefore the proof needs no loop invariant for the changed
  behavior — the loops are opaque framing on the path *before* the raise (C4).

### F3 — `__eq__`/`deconstruct` consistency is the load-bearing obligation  [positive]
- input: `c = CheckConstraint(check=Q(...), name="n", violation_error_code="x")`,
  then `c.clone()`.
- observed: `c.clone() == c` is **True**, because V1 emits `violation_error_code`
  from `deconstruct()` (so `clone` re-supplies it) *and* compares it in `__eq__`.
- expected: equality. **Counterfactual bug caught by the spec:** had V1 added the
  `__eq__` conjunct but forgotten the `deconstruct` emission (a very easy omission),
  then `c.clone()` would drop the code → `clone(c) != c`, and migrations would
  silently lose the custom code. The round-trip claim `(ROUNDTRIP-CODE)` is exactly
  the check that flushes this out; V1 passes it.

### F4 — `__init__` code postcondition is clean and universal  [positive]
- input: `violation_error_code = C` for any `C` (including `None`).
- observed: effective code after construction `= C` in **both** the `None` and
  non-`None` cases (None → class default `None`; non-None → instance attr). No
  awkward case split leaks into the contract; no precondition is needed.
- expected: a clean universal postcondition. A clean spec was *easy* to write here —
  the inverse of the "spec-difficulty = bug signal" heuristic — corroborating that
  the `__init__` change is correct.

### F5 — `UniqueConstraint(fields=..., condition=None)` ignores the custom code  [design][no-regression]
- input: `UniqueConstraint(fields=["a"], name="u", violation_error_code="myc")`, then
  a duplicate row triggers `validate()`.
- observed: the raised `ValidationError.code` is `"unique"` (from
  `instance.unique_error_message(...)`), **not** `"myc"`.
- expected (per the documented contract): exactly this. The fields-without-condition
  branch has *always* bypassed `get_violation_error_message()` for backward
  compatibility, and `docs/ref/models/constraints.txt` already states the *message*
  is "not used" there. V1 keeps the new *code* consistent with that established
  *message* behavior and documents the same exclusion for the code. Changing it would
  (a) break the existing field-based-unique message/code tests and (b) require
  threading a code into `Model.unique_error_message`, an out-of-scope behavior change
  affecting `Field.unique`/`unique_together`. **Non-universal postcondition by
  design**, scoped out of C4. (See ITERATION_GUIDANCE.md for the UltimatePowers
  question to confirm intent.)

### F6 — Custom code should be migration-serializable  [assumption]
- input: `violation_error_code = SomeNonSerializableObject()`.
- observed: `deconstruct()` would place that object in `kwargs`; Django's migration
  writer would then fail to serialize it.
- expected: callers pass a string (or `None`), exactly as for `violation_error_code`
  on validators and for `violation_error_message`. This is a pre-existing, identical
  assumption — not introduced by the fix — and is the user's responsibility. No code
  guard added (would be inconsistent with `violation_error_message`).

### F7 — `__eq__` without `__hash__` (pre-existing, not a regression)  [no-regression]
- Constraints define `__eq__` and are therefore unhashable; the fix does not change
  this. Adding a conjunct to an already-present `__eq__` introduces no new behavior
  here. Out of scope.

---

## Proof-derived findings from `/verify`

### PV1 — No circularity required; all VCs are propositional/equality  [positive]
- Evidence: every claim in `constraints-spec.k` is discharged by symbolic execution
  + a single guard case-split (`C is null` vs `C ≠ null`) + `#Equals`/`==K`
  reductions. No `[simplification]` arithmetic lemma and no loop circularity is
  needed (contrast the `sum` example).
- Classification: positive — the fix adds no new control-flow or arithmetic
  complexity, so the proof obligations are shallow and fully within the bundled tier.

### PV2 — Round-trip discharges only because emission ∧ comparison agree  [positive / test gap]
- Evidence: `(ROUNDTRIP-CODE)` = Transitivity of `(DECON-CODE)` then `(INIT-CODE)`.
  The composition closes *iff* the key string used to emit (`"violation_error_code"`)
  equals the key consumed by `__init__` and the `__eq__` conjunct uses the same
  attribute. All three agree in V1.
- Classification: test gap (recommendation) — add/keep a test asserting
  `clone()`/deconstruct round-trip *and* `==` for a constraint with a custom
  `violation_error_code` (and for postgres `ExclusionConstraint`). See
  PROOF.md §Test-redundancy.

### PV3 — `validate` raise abstracts real exception control flow  [proof capability gap / ESCALATION BOUNDARY]
- Evidence: `(VALIDATE-CODE)` models `raise` as writing an `errpair(message, code)`
  cell and halting; it does **not** model Python exception propagation, `try/except
  FieldError`, or the surrounding query. The obligation actually proved is local:
  "the constructed error object binds `code` to the effective code."
- Classification: capability gap, **honestly bounded** — full exception semantics is
  outside the mini-X fragment. This is sufficient for the property under audit
  (code propagation) but is the trusted boundary; it is NOT admitted as `[trusted]`
  silently — it is stated here. See PROOF.md §Residual risk.
