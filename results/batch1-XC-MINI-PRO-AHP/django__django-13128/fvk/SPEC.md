# SPEC — `CombinedExpression._resolve_output_field` (V1 fix)

**Target.** `django/db/models/expressions.py`, the V1 fix:

```python
def _resolve_output_field(self):
    datetime_fields = {'DateField', 'DateTimeField', 'TimeField'}
    if self.connector == self.SUB:
        lhs_field, rhs_field = self.get_source_fields()
        if lhs_field is not None and rhs_field is not None:
            lhs_type = lhs_field.get_internal_type()
            rhs_type = rhs_field.get_internal_type()
            if lhs_type in datetime_fields and lhs_type == rhs_type:
                return fields.DurationField()
    return super()._resolve_output_field()
```

It cooperates with the **unchanged** sibling logic in `CombinedExpression.as_sql`
(lines 460-462), which dispatches the very same shape of expression to
`TemporalSubtraction`:

```python
datetime_fields = {'DateField', 'DateTimeField', 'TimeField'}
if self.connector == self.SUB and lhs_type in datetime_fields and lhs_type == rhs_type:
    return TemporalSubtraction(self.lhs, self.rhs).as_sql(compiler, connection)
```

and with the **unchanged** base method (lines 287-312), which infers the common
source type and raises `FieldError` on mixed types.

This is a **pure, total type-inference dispatcher**: no loops, no mutation, no
I/O. The only loop in the call graph is the base method's nested generator loop,
which — because a `CombinedExpression` always has **exactly two** source
expressions (`lhs`, `rhs`) — degenerates to a bounded 2-element case analysis
(see PROOF.md PO6/PO7). There is therefore **no genuine circularity to
discharge**; termination is immediate.

## Intent (from PROBLEM.md and the surrounding code)

Subtracting two temporal values of the *same* kind (`DateField - DateField`,
`DateTimeField - DateTimeField`, `TimeField - TimeField`) yields a **duration**.
The output-field inference must reflect that, so `F('end') - F('start')` (and the
larger `… + Value(timedelta(), DurationField())` from PROBLEM.md) type-checks as
a `DurationField` **without** an explicit `ExpressionWrapper`.

## Domain abstraction

A `Field` instance is abstracted to the string `get_internal_type()` returns —
the only property the method reads. The modelled values (`fvk/mini_combined.k`):

| token | meaning |
|---|---|
| `DateField`, `DateTimeField`, `TimeField` | the three temporal internal types |
| `DurationField` | the duration internal type |
| `Other` | any other single resolvable type (e.g. `IntegerField`) |
| `none` | a source whose `_output_field_or_none` is Python `None` |
| `mixed` | *result* sentinel: base resolution raised `FieldError` (see FINDINGS F3) |

Inputs `L = get_source_fields()[0]`, `R = get_source_fields()[1]` range over the
six resolvable values (a source that itself *re-raises* `FieldError` is **not** in
this domain — that is FINDINGS F3, handled separately and shown harmless).

## Contract

Let `isTempSub(C, L, R) ≜ C = SUB ∧ L ≠ none ∧ R ≠ none ∧ isTemporal(L) ∧ L = R`,
where `isTemporal(T) ≜ T ∈ {DateField, DateTimeField, TimeField}`.

**Precondition.** `self` is a resolved `CombinedExpression` with exactly two
source fields `L, R` drawn from the six resolvable values above; `C = self.connector`.

**Postcondition.**

- If `isTempSub(C, L, R)` then `_resolve_output_field()` **returns
  `DurationField`**.  *(claim `FIX-TEMPORAL`)*
- Otherwise it **returns `baseVal(L, R)`** — bit-for-bit the result of the
  *unchanged* `BaseExpression._resolve_output_field()` (a concrete field, or a
  raised `FieldError` for genuinely mixed/unresolvable sources).  *(claim
  `DEFER`)*

**Cross-component invariant (CONSISTENCY).** For all `C, L, R`:
`isTempSub(C, L, R) = asSqlTempSub(C, L, R)`, the predicate `as_sql` uses to
dispatch to `TemporalSubtraction`. Hence inference and SQL generation never
disagree about which expressions are temporal subtractions. *(PO4)*

## What is **not** specified here (residual risk, by design)

- **SQL string generation and DB round-trip.** `as_sql`, `subtract_temporals`,
  and `convert_durationfield_value` (microseconds ↔ `timedelta`) are *not*
  modelled; they are unchanged by V1 and are exercised by the existing
  integration tests, which this unit spec does **not** subsume (see PROOF.md §6).
- **The base method's `isinstance` subclass asymmetry** (`DateTimeField`
  subclasses `DateField`): folded into the black-box `baseVal` and recorded as
  FINDINGS F4 — preserved, not introduced, by V1.
- **Termination/performance** beyond the trivial bounded case analysis.

Claims live in `fvk/mini_combined-spec.k`; obligations in
`fvk/PROOF_OBLIGATIONS.md`; the constructed proof in `fvk/PROOF.md`.
