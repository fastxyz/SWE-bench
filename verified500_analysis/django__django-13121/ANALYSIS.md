# django__django-13121 — FVK analysis

- **Verdict:** B_COMPLETENESS — fvk added a reachable branch that correctly evaluates `duration + (datetime − datetime)` expressions (with explicit `output_field=DurationField()`) that **both baseline AND the official gold patch get wrong** on SQLite/MySQL.
- **Pitch-worthiness (1-5):** 4

## The issue
On backends without native duration columns (SQLite/MySQL), `DurationField` is stored as integer microseconds. `CombinedExpression.as_sql()` routes any duration-containing expression through `DurationExpression`, which historically formatted every duration operand as a date/time *interval*. Correct for `datetime + duration`, but wrong when the whole expression is a duration: SQLite fed the operands to `django_format_dtdelta(...)`, which returns a formatted timedelta *string*, and the `DurationField` converter then chokes. Reported failure: `F('estimated_time') + timedelta(1)` raised a conversion error.

## What baseline did
Added a `duration_only` fast-path: if connector is `+`/`-` and **both operands' `output_field` is literally `DurationField`**, compile operands as stored microseconds and combine with numeric `combine_expression()`. Fixes the reported case, passes the hidden test. Its operand check is narrow: `has_duration_output(e) → e.output_field.get_internal_type()=='DurationField'`.

## What fvk changed and why
fvk kept baseline's machinery but **widened `has_duration_output()`**: it also treats a same-type temporal subtraction (`CombinedExpression`, connector `-`, both sides `Date/DateTime/TimeField`) as duration-producing. Rationale: `DateTime − DateTime` compiles via `TemporalSubtraction` to an integer-microsecond value, so an outer `+`/`-` over it is duration-only and must use the numeric path. Baseline missed this because the inner subtraction's *inferred* `output_field` is `DateTimeField` (per `_resolve_output_field`), not `DurationField`.

## Concrete demonstration (empirically executed, not reasoned)
Ran all three variants against the staged Django 3.2a repo on in-memory **SQLite** (row: `estimated_time=253000µs`, `end−start=1 day`), swapping `expressions.py` (+ gold's backend files) per variant.

Query: `annotate(val=ExpressionWrapper(F('estimated_time') + (F('end') - F('start')), output_field=DurationField()))`

| variant | generated SQL (`val` column) | result |
|---|---|---|
| **baseline** | `django_format_dtdelta('+', estimated_time, django_timestamp_diff(end, start))` | **`TypeError: unsupported type for timedelta microseconds component: str`** |
| **gold** | `django_format_dtdelta('+', estimated_time, django_timestamp_diff(end, start))` | **`TypeError: … str`** (same bug) |
| **fvk** | `(estimated_time + django_timestamp_diff(end, start))` | **`timedelta(days=1, microseconds=253000)`** ✅ |

Mechanism: `django_format_dtdelta` (`django/db/backends/sqlite3/base.py:547-564`) takes the two integer-microsecond inputs, computes `timedelta+timedelta`, and `return str(out)` → `"1 day, 0:00:00.253000"`. `convert_durationfield_value` (`django/db/backends/base/operations.py:581-583`) then runs `datetime.timedelta(0, 0, value)` on that string → `TypeError`. fvk skips `django_format_dtdelta` and emits plain numeric microsecond addition.

Second confirmed case, same outcome: `ExpressionWrapper((F('end') - F('start')) + timedelta(days=1), DurationField())` → baseline/gold `TypeError`; fvk → `timedelta(days=2)`.

**Reachability caveat (honest):** without an explicit `output_field`, the outer annotation raises `FieldError: Expression contains mixed types` during output-field resolution *before* `DurationExpression` runs — verified identical across all three variants. The branch matters specifically when wrapped with `output_field=DurationField()`, which is the documented idiom (the gold test itself uses `ExpressionWrapper(F('completed') - F('assigned'), output_field=DurationField())`).

**No regressions:** for direct cases — `F('estimated_time') + timedelta` (the FAIL_TO_PASS shape), `dur+dur`, `dur−timedelta`, mixed `datetime+dur` — baseline/fvk/gold produced identical SQL and identical correct results.

## Why the tests missed it
`tests.json` has one FAIL_TO_PASS: `test_duration_expressions`. `gold_test.patch` adds only:
```python
for delta in self.deltas:
    qs = Experiment.objects.annotate(duration=F('estimated_time') + delta)
    for obj in qs:
        self.assertEqual(obj.duration, obj.estimated_time + delta)
```
Every `delta` is a plain `timedelta` literal — only the *direct* `DurationField + literal` shape. The suite never nests a temporal subtraction inside a duration expression. baseline's narrower check is fully exercised and passes; the nested-subtraction gap is untested — which is exactly why **gold** ships with the same latent bug.

## Gold comparison
Gold routes through `DurationExpression` only when types **differ** (`'DurationField' in {lhs_type, rhs_type} and lhs_type != rhs_type`). For `DurationField + (DateTime−DateTime)`: `lhs_type='DurationField'`, `rhs_type='DateTimeField'` → treated as *mixed* → interval path → same `django_format_dtdelta` string bug. So gold **confirms fvk's direct-case fix** but **not** the nested-subtraction branch; on that case fvk is the only correct one. **GOLD_MATCH: partial** (fvk is *more* correct than the official human fix here).

## Confidence & caveats
- **High confidence:** SQL strings and results were captured by actually executing all three variants on SQLite. baseline≡gold buggy SQL vs fvk correct SQL shown verbatim.
- **Caveat 1:** the win requires explicit `output_field=DurationField()` — idiomatic/documented, but not the exact issue/test shape, so this is a completeness/edge improvement, not a fix to the reported bug (baseline already fixes that).
- **Caveat 2:** fvk is *more* correct than gold here, so this behavior was never maintainer-validated; no fvk regression vs gold was found, but the branch is strictly beyond the project-blessed fix.
- **Caveat 3:** verified on SQLite only; MySQL uses `INTERVAL … MICROSECOND` on the same path, so the identical bug class is expected by inspection but not run.
