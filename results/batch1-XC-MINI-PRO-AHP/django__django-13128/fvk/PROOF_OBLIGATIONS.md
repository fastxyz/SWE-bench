# PROOF OBLIGATIONS — V1 fix

Each obligation is what must hold for the fix to be **correct** (solves the bug)
and **regression-free** (changes nothing else). Discharge is in `PROOF.md`.

| ID | Obligation | Why it matters | Status |
|---|---|---|---|
| **PO1** | `isTempSub(C,L,R)` ⟹ `_resolve_output_field` returns `DurationField`. | The bug fix itself: temporal subtraction now infers a duration, so `F('end') - F('start') + Value(timedelta(), DurationField())` type-checks (PROBLEM.md). | ✅ discharged (claim FIX-TEMPORAL) |
| **PO2** | `C ≠ SUB` ⟹ result `= baseVal(L,R)` (unchanged base). | No additions/other connectors change behaviour. | ✅ (subcase of DEFER) |
| **PO3** | `C = SUB ∧ ¬isTempSub` ⟹ result `= baseVal(L,R)`. Covers: a `none` source; differing types (incl. `DateField - DateTimeField`); same **non**-temporal type (`Duration - Duration`, `Integer - Integer`). | Regression-freedom on the whole SUB complement. | ✅ (subcase of DEFER) |
| **PO4** | `isTempSub(C,L,R) = asSqlTempSub(C,L,R)` for **all** `C,L,R`. | Inference (this fix) and SQL dispatch (`as_sql`, unchanged) must agree, or a row could be typed `DurationField` but emit datetime SQL (or vice-versa). | ✅ discharged (CONSISTENCY, finite case analysis) |
| **PO5** | The fix introduces **no new exception** and **suppresses none**: on every input where base raised `FieldError`, the fix also raises the *same* `FieldError`; where base returned a field, the fix returns a field. | A wrapped/combined expression must keep failing or succeeding exactly as before, except for the intended `DateTimeField→DurationField` promotion. | ✅ discharged (PO5 analysis) |
| **PO6** | **Termination.** The new code adds no loop; the only loop (base method) runs over a 2-element list and halts. | Total correctness (not just partial) for the new code. | ✅ trivial |
| **PO7** | **Totality of the unpacking** `lhs_field, rhs_field = self.get_source_fields()`: `get_source_fields()` yields exactly two elements. | A wrong arity would raise `ValueError` (unpack) — a new failure mode. | ✅ discharged (CombinedExpression invariant) |

## Side conditions / preconditions surfaced

- **SC1 (arity = 2).** `CombinedExpression.get_source_expressions() == [lhs, rhs]`
  ⟹ `get_source_fields()` has length 2. Holds for `CombinedExpression` and every
  subclass (`DurationExpression`, `TemporalSubtraction`) — none override
  `get_source_expressions`. Backs PO7.

- **SC2 (resolved sources).** `_resolve_output_field` is reached only via the
  `output_field` cached-property, i.e. **after** `resolve_expression` turned
  `F('end')`/`F('start')` into `Col`s, so `get_source_fields()` returns real
  `Field`s or `None`. Identical precondition to the *unchanged* base method —
  introduces no new assumption.

- **SC3 (input domain excludes self-raising sources).** A source whose
  `_output_field_or_none` *re-raises* `FieldError` (a nested mixed-type operand)
  is outside the modelled domain; PO5 shows both fix and base raise the same
  error there, so excluding it from the closed-form domain loses nothing
  (FINDINGS F3).

## Out of scope (named, not hidden)

- **OB-SQL** — correctness of `as_sql`/`subtract_temporals`/duration conversion
  (unchanged by V1; covered by integration tests, not this unit proof).
- **OB-ISINSTANCE** — the base method's `isinstance` subclass asymmetry
  (FINDINGS F4). Folded into black-box `baseVal`; preserved, not introduced.
- **OB-TYPING-CONVENIENCE** — whether inferring *any* output field for arithmetic
  is semantically ideal (the base docstring itself calls it "a convenience…not
  always correct"). Pre-existing design choice, not this fix's concern.
