# FINDINGS — V1 audit of `CombinedExpression._resolve_output_field`

Plain-language `input → observed vs expected`. Findings drive the
keep/revise decision in `reports/fvk_notes.md`.

---

## F1 — (root cause, **fixed**) base inference typed `datetime − datetime` as a datetime

- **input:** `Experiment.objects.annotate(delta=F('end') - F('start') + Value(timedelta(), DurationField()))`
- **observed (pre-fix):** the inner `F('end') - F('start')` inferred
  `DateTimeField` (the base method returns the common source type); combined with
  the `DurationField` value it raised
  `FieldError: Expression contains mixed types: DateTimeField, DurationField`.
- **expected:** `datetime − datetime` is a **duration**; the whole expression is a
  `DurationField`.
- **status:** V1 fixes exactly this. `_resolve_output_field` now returns
  `DurationField` on the temporal-subtraction set (PO1 / claim FIX-TEMPORAL).
  Spec-difficulty signal confirmed: the base method could **not** give a clean
  type for `datetime − datetime`, which is precisely the bug.

## F2 — (positive) the fix's domain exactly matches `as_sql`'s dispatch domain

- **observed:** `_resolve_output_field` (V1) and `as_sql` (unchanged) both gate on
  `connector == SUB ∧ lhs_type in {DateField,DateTimeField,TimeField} ∧ lhs_type == rhs_type`.
- **checked:** PO4 / CONSISTENCY proves the two predicates are *equal for every
  input*. The only textual difference — V1's explicit `lhs_field is not None and
  rhs_field is not None` vs `as_sql`'s `except FieldError: None` then
  `None in datetime_fields` — collapses: `(L≠none) ∧ (L==R) ⟹ (R≠none)`, so V1's
  extra `rhs is not None` conjunct is **redundant**, leaving the predicates
  identical.
- **why it matters:** if they ever diverged, a row could be *typed* `DurationField`
  while *emitting* datetime-subtraction SQL (or vice-versa) — a silent data-type
  corruption. They do not diverge. **No action.**

## F3 — (corner case, **harmless**) a SUB whose operand *itself* re-raises `FieldError`

- **input:** `(IntegerField_expr + FloatField_expr) - F('start')` — the left
  operand is itself a mixed-type expression whose `_output_field_or_none`
  *re-raises* `FieldError` (it did **not** resolve to `None`).
- **observed (V1):** inside the `connector == SUB` branch, `self.get_source_fields()`
  triggers that re-raise, so `_resolve_output_field` raises `FieldError` **before**
  reaching `super()`.
- **observed (base, i.e. without the fix):** the base method's very first line is
  also `self.get_source_fields()`, which raises the **identical** `FieldError`.
- **expected:** the expression's type is genuinely unresolvable ⟹ `FieldError` is
  correct.
- **status:** no behavioural difference (PO5). The error type, message, and
  propagation are identical with and without the fix. Excluded from the
  closed-form domain as SC3; **no action**.

## F4 — (pre-existing quirk, **out of scope**, untouched) `isinstance` subclass asymmetry in the base method

- **input:** `F('a_datetime') - F('a_date')` vs `F('a_date') - F('a_datetime')`.
- **observed (base, unchanged):** because `DateTimeField` subclasses `DateField`,
  the base method's `isinstance(output_field, source.__class__)` is **asymmetric**:
  `DateTimeField - DateField` resolves to `DateTimeField` (no error) while
  `DateField - DateTimeField` raises `FieldError`.
- **interaction with V1:** none. V1's predicate uses **exact internal-type-string
  equality** `lhs_type == rhs_type` (`'DateField' == 'DateTimeField'` is `False`),
  so the fix never fires on mixed temporal types and defers both orderings to the
  unchanged base. The asymmetry is **preserved, not introduced or worsened**.
- **status:** pre-existing; outside this fix's mandate (OB-ISINSTANCE). Noted only
  so the next iteration knows it exists. **No action in V1.**

## F5 — (degenerate input, **consistent**) one source resolves to `None`

- **input:** `F('start') - Value(None)` where `Value(None)` has no `output_field`
  (so `_output_field_or_none` is `None`).
- **observed (V1):** `rhs_field is None` ⟹ temporal branch skipped ⟹
  `super()._resolve_output_field()` returns the lone non-`None` source type
  (`DateTimeField`). `as_sql` likewise treats it as non-temporal
  (`None in datetime_fields` is `False`).
- **expected:** with one operand's type unknown, falling back to the base
  inference is the established behaviour.
- **status:** unchanged by V1 and consistent between inference and SQL (covered by
  PO3 + PO4). The existing tests `test_*_subtraction` exercise the typed-`None`
  variants (`Value(None, output_field=DateTimeField())`). **No action.**

## F6 — (maintainability, **minor**) the `datetime_fields` literal and the SUB
predicate are duplicated in `_resolve_output_field` and `as_sql`

- **observed:** the set `{'DateField','DateTimeField','TimeField'}` and the
  `connector == SUB … lhs_type == rhs_type` test now appear **twice** in the file.
  PO4 proves they currently agree; nothing *enforces* they stay in sync.
- **risk:** a future edit to one and not the other would re-introduce an
  inference/SQL mismatch (the F2 hazard).
- **recommendation:** *optional* refactor to a single private predicate
  (e.g. `_is_temporal_subtraction()` reused by both). **Deliberately NOT done in
  V1** — it would enlarge the change surface beyond the minimal fix and the task
  brief favours minimality. Logged for the next iteration
  (ITERATION_GUIDANCE.md G1).

## F7 — (scope, **kept as-is**) the fix does not cover `datetime ± duration`

- **input:** `F('start') + Value(timedelta(), DurationField())` *without* a wrapper.
- **observed:** still requires an `ExpressionWrapper` (mixed `DateTimeField` +
  `DurationField` ⟹ base `FieldError`); the `DurationExpression` path in `as_sql`
  builds the SQL but inference has no rule for it.
- **expected per PROBLEM.md:** the issue asks only for temporal **subtraction**
  without a wrapper; `datetime ± duration` is **not** in scope.
- **status:** intentionally untouched. The example in PROBLEM.md combines the
  subtraction with `+ Value(…, DurationField())`, which V1 *does* make work because
  by then the left side is already `DurationField` (so it is `Duration + Duration`,
  not `datetime + duration`). **No action.**

---

## Proof-derived findings from `/verify`

- The proof needed **no invented precondition** and **no circularity**: the new
  code is straight-line and the base loop is bounded at arity 2 (PO6/PO7). A clean
  spec *was* writable — the FVK "spec-difficulty = bug signal" heuristic comes back
  **negative** for V1 (a good sign), and **positive** for the pre-fix base (F1),
  confirming V1 addresses a real defect.
- The single non-obvious obligation, **PO4/CONSISTENCY**, discharged cleanly via
  the redundancy `(L≠none) ∧ (L==R) ⟹ (R≠none)`. That it discharged is the main
  evidence V1 is safe; that it had to be *stated at all* is the basis for the F6
  maintainability recommendation.
- **Conclusion: V1 stands.** No correctness obligation failed; the only open item
  is the optional, non-behavioural DRY refactor F6/G1.
