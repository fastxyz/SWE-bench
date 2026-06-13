# ITERATION GUIDANCE — next-pass feedback

Distilled from `FINDINGS.md` + `PROOF_OBLIGATIONS.md`. The audit found **no
correctness defect** in V1: PO1-PO7 all discharge, PO4/CONSISTENCY closes cleanly.
**Decision: V1 stands** (see `reports/fvk_notes.md`). Items below are optional
hardening, not corrections.

## G1 — (optional, from F6) DRY the temporal-subtraction predicate

- **Evidence:** the set `{'DateField','DateTimeField','TimeField'}` and the
  `connector == SUB ∧ lhs_type in datetime_fields ∧ lhs_type == rhs_type` test now
  live in **two** places — `_resolve_output_field` (V1) and `as_sql` (lines
  460-462). PO4 proves they agree *today*; nothing keeps them in sync tomorrow.
- **Classification:** maintainability / latent-regression risk (not a current bug).
- **Recommended change (only if a refactor pass is wanted):** extract a private
  helper, e.g.

  ```python
  def _is_temporal_subtraction(self, lhs_type, rhs_type):
      return (
          self.connector == self.SUB and
          lhs_type in {'DateField', 'DateTimeField', 'TimeField'} and
          lhs_type == rhs_type
      )
  ```

  and call it from both sites so they cannot drift.
- **Why deferred in V1:** the task brief favours a minimal, targeted change;
  introducing a shared helper touches `as_sql` (working, unchanged code) and
  widens the diff. The duplication is low-risk while PO4 holds. **Left for a
  dedicated refactor, not this fix.**
- **UltimatePowers question:** "Prefer a minimal fix, or fold in a small DRY
  refactor of the duplicated temporal predicate now?"

## G2 — (optional, from F7) consider `datetime ± duration` inference

- **Evidence:** `F('start') + Value(timedelta(), DurationField())` (no wrapper)
  still raises `FieldError`; only `as_sql`'s `DurationExpression` path handles the
  SQL, with no matching inference rule.
- **Classification:** scope extension — **explicitly outside PROBLEM.md** (which
  asks for temporal *subtraction*).
- **Recommended change:** none for this task. If later requested, extend
  `_resolve_output_field` so `datetime ± duration ⟹ datetime` and
  `duration ± duration ⟹ duration`, again mirroring `as_sql`'s `DurationExpression`
  gate to keep PO4-style consistency.
- **UltimatePowers question:** "Should bare `datetime + duration` also infer its
  output field, or remain wrapper-only?"

## G3 — (from F4) document the base `isinstance` subclass asymmetry

- **Evidence:** `DateTimeField - DateField` resolves (to `DateTimeField`) while
  `DateField - DateTimeField` raises — a pre-existing asymmetry V1 neither uses nor
  worsens.
- **Classification:** pre-existing quirk / documentation gap.
- **Recommended change:** none in V1. Optionally a code comment or test pinning the
  asymmetry so a future refactor does not silently change it.

## Tests — add / keep / remove

- **Keep (all):** every existing temporal-subtraction test — they cover the SQL/DB
  layer this unit proof does not (PROOF.md §6).
- **Add (suggested, behavioural — the bug this fix targets):**
  - `annotate(delta=F('end') - F('start'))` → `delta` is a `DurationField` and
    equals `end - start` (no `ExpressionWrapper`). *(PO1)*
  - The full PROBLEM.md expression
    `F('end') - F('start') + Value(timedelta(), DurationField())` → no `FieldError`,
    correct `timedelta`. *(PO1 + DEFER for the `Duration + Duration` outer add)*
  - Regression guards: `F('a') - F('b')` for `IntegerField` still infers
    `IntegerField`; `DateField - DateTimeField` still raises. *(PO3)*
  - (These are integration tests; the project's hidden suite is expected to add
    equivalents. Do not edit test files here.)
- **Remove:** none (a unit type-inference proof subsumes no integration test).

## Status for the next generator

`generate → formalize → verify` converged: **no code change required**. The
evidence package (`SPEC.md`, `PROOF_OBLIGATIONS.md`, `FINDINGS.md`, `PROOF.md`,
the two `.k` files) certifies V1 as correct-by-construction modulo the
*constructed, not machine-checked* caveat and the named out-of-scope obligations
(OB-SQL, OB-ISINSTANCE). The only backlog item is the optional G1 DRY refactor.
