# FVK notes — audit of the V1 fix for django__django-13128

## Outcome

**V1 stands, unchanged.** The formal audit discharged every correctness proof
obligation (PO1-PO7) and surfaced no defect in the fix. The one actionable finding
(F6, a maintainability duplication) is optional, non-behavioural, and deliberately
deferred for minimality. No source files were edited in this pass.

This conclusion is the one the task permits — "if V1 is already correct according
to your spec and proof obligations, it may stand unchanged … justified by the FVK
artifacts" — and every part of it is traced to a specific artifact entry below.

## What was audited

The V1 change is a single added method,
`CombinedExpression._resolve_output_field` (`django/db/models/expressions.py`),
that promotes the inferred output field of a same-typed temporal subtraction
(`DateField/DateTimeField/TimeField − same`) to `DurationField`, and otherwise
defers to the unchanged base method. It is a pure, loop-free, total type-inference
dispatcher (`fvk/SPEC.md`).

## Decision log — each traced to FINDINGS + PROOF_OBLIGATIONS

### Decision 1 — keep the core promotion exactly as written (no edit)

- **Traces to:** F1 (root cause), PO1 / claim `FIX-TEMPORAL`.
- **Reasoning:** PO1 is discharged by straight-line symbolic execution
  (`PROOF.md` PO1): on the temporal-subtraction set the method returns
  `DurationField`, which is exactly what PROBLEM.md needs. The "spec-difficulty =
  bug signal" heuristic fired **positive on the pre-fix base** (it cannot type
  `datetime − datetime` cleanly) and **negative on V1** (a clean closed-form spec
  exists) — strong evidence the fix targets a real defect and resolves it. Nothing
  to change.

### Decision 2 — keep the `is not None` guards and the `lhs_type == rhs_type` test as written (no edit)

- **Traces to:** F2, PO4 / claim `CONSISTENCY`.
- **Reasoning:** the central risk for this kind of fix is that output-field
  inference and SQL generation disagree about *which* expressions are temporal
  subtractions — that would type a row `DurationField` while emitting datetime
  SQL. PO4 proves the two predicates are **equal for all inputs**, the proof
  hinging on `(L≠none) ∧ (L=R) ⟹ (R≠none)` so V1's explicit None-guards are
  exactly equivalent to `as_sql`'s `except FieldError: None` handling
  (`PROOF.md` PO4). Because the predicate is provably consistent as written,
  rewriting it would add risk without benefit.

### Decision 3 — do **not** add defensive handling for the "operand re-raises" corner case (no edit)

- **Traces to:** F3, PO5, side condition SC3.
- **Reasoning:** when a SUB operand is itself a mixed-type expression,
  `get_source_fields()` re-raises `FieldError` inside the new branch. PO5 shows the
  base method's first action is the same `get_source_fields()` call, so the error
  is byte-for-byte identical with and without the fix (`PROOF.md` PO5). Adding a
  `try/except` would *change* behaviour (swallow or relocate a legitimate error)
  and is therefore wrong. Correctly left alone.

### Decision 4 — do **not** touch the base method's `isinstance` asymmetry (no edit)

- **Traces to:** F4, out-of-scope obligation OB-ISINSTANCE.
- **Reasoning:** `DateTimeField − DateField` resolves while `DateField −
  DateTimeField` raises, because `DateTimeField` subclasses `DateField`. V1's
  predicate uses exact internal-type **string** equality, so it never fires on
  mixed temporal types and defers both orderings to the unchanged base (PO3). The
  asymmetry is pre-existing, outside PROBLEM.md's mandate, and neither used nor
  worsened. Changing it would exceed scope.

### Decision 5 — do **not** extend the fix to `datetime ± duration` (no edit)

- **Traces to:** F7, obligation OB-TYPING / guidance G2.
- **Reasoning:** PROBLEM.md asks only for temporal **subtraction** without a
  wrapper. The example's `… + Value(timedelta(), DurationField())` already works
  under V1 because, after the subtraction is promoted, the outer node is
  `Duration + Duration` (DEFER → `baseVal(Duration,Duration) = Duration`,
  `PROOF.md` PO2/PO3), not `datetime + duration`. Extending inference to
  `datetime ± duration` is a separate scope item, intentionally not in V1.

### Decision 6 — defer the DRY refactor of the duplicated predicate (no edit, logged)

- **Traces to:** F6, guidance G1.
- **Reasoning:** the `datetime_fields` set and the SUB predicate now appear in both
  `_resolve_output_field` and `as_sql`. PO4 proves they agree today, but nothing
  enforces future sync. A shared `_is_temporal_subtraction()` helper would remove
  the latent risk — **but** it would modify the working, unchanged `as_sql`
  (widening the diff and adding regression surface to a method the proof currently
  certifies as consistent), against the task's minimality directive. The
  duplication is low-risk while PO4 holds, so the refactor is logged in
  `fvk/ITERATION_GUIDANCE.md` G1 for a dedicated pass rather than applied here.

### Decision 7 — recommend keeping all existing temporal-subtraction tests; remove none

- **Traces to:** `PROOF.md` §6 (test-redundancy), F5.
- **Reasoning:** the verified contract is a unit-level *type-inference* property;
  the existing tests assert end-to-end SQL/DB behaviour (`subtract_temporals`,
  microsecond ↔ `timedelta` conversion, subquery/`None`/microsecond boundaries)
  that lies outside the spec's domain and is therefore **not subsumed**. A unit
  proof cannot retire integration tests, so CI savings are zero by design and
  nothing is recommended for removal. (Per the honesty gate, the proof is
  *constructed, not machine-checked* anyway.)

## Adversarial cross-checks performed (beyond the claims)

- **Arity-2 invariant (PO7/SC1):** confirmed only `DurationExpression` and
  `TemporalSubtraction` subclass `CombinedExpression`, and neither overrides
  `get_source_expressions`, so `lhs_field, rhs_field = self.get_source_fields()`
  never mis-unpacks.
- **`TemporalSubtraction` short-circuit:** confirmed its class attribute
  `output_field = fields.DurationField()` shadows the `output_field`
  cached-property, so the new `_resolve_output_field` is never invoked on it
  (no double-promotion, no recursion surprise).
- **Mixed-type messages preserved:** hand-traced `DateField − DurationField`,
  `DurationField − DateField`, and `DateTimeField + DurationField` — all defer to
  the base and raise the identical `FieldError("… mixed types …")` as pre-fix
  (PO3/PO5).
- **No new failure modes:** `conditional`, `select_format`, converters, and
  caching all behave identically with a `DurationField` output (V1 analysis +
  PROOF.md §7 trusted base).

## Residual risk (honesty gate)

The K artifacts (`fvk/mini_combined.k`, `fvk/mini_combined-spec.k`) are
**constructed, not machine-checked** — no toolchain runs in this environment. The
`kompile`/`kprove` commands that would upgrade the result to machine-verified are
in `PROOF.md` §7. The trusted base is the mini-X abstraction (fields ↦
`get_internal_type()` strings; base method ↦ black-box `baseVal`), the reachability
metatheory/`kprove`/Z3, and the named out-of-scope obligations (OB-SQL,
OB-ISINSTANCE) which remain covered by the project's integration tests. The
Findings (Benefit 2) do not depend on machine-checking and are reported with full
confidence.
