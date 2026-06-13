# Control notes — django__django-13128 (V2 review outcome)

## Decision: keep V1 unchanged

After a systematic, skeptical re-review (recorded in `review/FINDINGS.md`), the V1
fix is confirmed correct and complete, and **no source edits were made**. The fix
remains the single method added to `repo/django/db/models/expressions.py`:

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

Below, every decision is traced to the numbered findings.

## Why no change was needed

### The issue is actually fixed → F1
The exact failing example from `PROBLEM.md` now resolves its `output_field` to
`DurationField` instead of raising the mixed-types `FieldError`. This was verified
by tracing the resolution of both the inner `DateTimeField - DateTimeField` and the
outer `DurationField + DurationField`. The root cause identified in V1 (inference
disagreeing with `as_sql()`) is addressed precisely at the inference layer.

### The one critical risk is provably absent → F2
The only way an inference fix like this can be *silently wrong* is if the inferred
type and the emitted SQL disagree. The override reuses the **identical predicate**
already used by `CombinedExpression.as_sql()` to dispatch to `TemporalSubtraction`
(`connector == SUB`, both temporal, same internal type). Because the override only
fires when both source fields are concrete, the internal types it sees are exactly
those `as_sql()` sees. Inference and SQL are therefore in lock-step in both
directions, so no change (e.g. switching to a `resolve_expression`-based approach)
is warranted.

### Considered alternative approaches and rejected them
- **Rewrite as a `resolve_expression()` override returning `TemporalSubtraction`**
  (the other plausible shape). Rejected because it would require resolving the
  operands and then re-wrapping/re-resolving them inside a new node; for the
  correlated `Subquery`/`OuterRef` operands exercised by the existing
  subquery-subtraction tests, re-resolving an already-resolved node is risky. The
  chosen `_resolve_output_field` override leaves the expression tree and the
  resolution flow completely untouched (F11) and still makes even the unwrapped
  `subquery - F(...)` case work via the unchanged `as_sql()` dispatch.
- **Extract the duplicated `datetime_fields` set / SUB predicate into a shared
  helper.** Rejected as a non-minimal refactor with no behavioral benefit; the
  inline set matches the existing local style in `as_sql()` and keeps the two
  predicates visibly parallel (F14).

### Regression candidates were each cleared
- **Filters** (`estimated_time__gt=F('end') - F('start')`): the rhs `output_field`
  does not affect WHERE SQL — lookups return/compile an expression rhs directly
  without `output_field`-based coercion, and the lookup class is chosen from the
  lhs. Behavior is identical and now more type-consistent → F3.
- **`ExpressionWrapper(F('end') - F('start'), DurationField())`**: at construction
  the wrapper does `getattr(expr, '_output_field_or_none', True)` on the
  *unresolved* expression; both V1 and the base hit the same `AttributeError`
  (from `F` lacking `_output_field_or_none`), which `getattr` swallows to the
  default. Byte-identical to prior behavior; `test_datetime_subtraction_microseconds`
  is unaffected → F8.
- **Cross-backend value conversion**: `DurationField` converters yield `timedelta`
  on microsecond backends and natively on interval backends; the emitted SQL is the
  same as the long-supported wrapper form and the already-passing
  `test_duration_expressions` / `test_datetime_subtraction` → F12.

### Interactions confirmed harmless
- `TemporalSubtraction` shadows `output_field` with a class attribute, so the new
  method is never invoked for it (F9).
- `DurationExpression` is the mixed-type path (`lhs_type != rhs_type`), so the
  override never fires for it (F10).
- Mixed temporal types (`DateField - TimeField`) and `DateTimeField - DurationField`
  remain (correctly) unpromoted, deferring to the existing `FieldError`/wrapper
  behavior (F4, F5). `None`/typeless operands are guarded against
  `AttributeError` and defer to `super()` (F6, F7).

### Idiom and scope
The implementation follows the established `_resolve_output_field` override pattern
used by `NumericOutputFieldMixin` and the window functions (F14). Documentation
needs no correction because no existing example becomes obsolete; a doc/release
note would be a nice-to-have but is out of scope for the code-only test suite and
adds no correctness (F15).

## Net effect
- Files changed in V2: **none** (code). Added `review/FINDINGS.md` and this report.
- V1's `reports/baseline_notes.md` remains an accurate description of the fix.
- The fix continues to make temporal subtraction (date−date, datetime−datetime,
  time−time) infer a `DurationField`, so it composes with other expressions and
  aggregates without an explicit `ExpressionWrapper`, exactly as the issue requests.
