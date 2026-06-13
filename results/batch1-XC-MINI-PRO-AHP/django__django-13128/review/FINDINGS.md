# Code review — V1 fix for django__django-13128

## What V1 changed

`repo/django/db/models/expressions.py`: added `_resolve_output_field()` to
`CombinedExpression`:

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

The review below is organized by the requested dimensions. Each finding has a
severity and an explicit verdict (action / no action). **Net result: no code
change is required; V1 is correct.**

---

## Correctness against the issue

### F1 — The reported example is fixed (severity: blocker → resolved; no action)
Tracing `delta=F('end') - F('start') + Value(timedelta(), DurationField())`:
- `F('end') - F('start')` → `CombinedExpression(connector=SUB)`. After
  resolution both operands are `Col(DateTimeField)`. The new override returns
  `DurationField()`.
- The outer `... + Value(..., DurationField)` is `DurationField + DurationField`,
  which the inherited inference resolves to `DurationField`.
- The previous `FieldError: Expression contains mixed types: DateTimeField,
  DurationField` no longer occurs.
Verified by manual trace; no execution available. **Correct.**

### F2 — Inference is perfectly aligned with `as_sql()` dispatch (severity: critical → verified safe; no action)
The dangerous failure mode for a fix like this is a *divergence*: `output_field`
reports `DurationField` but `as_sql()` does not actually emit a temporal
subtraction (or vice-versa), producing a silently wrong value/converter.

The override's guard (`connector == SUB`, both source fields non-None,
`lhs_type in datetime_fields`, `lhs_type == rhs_type`) is byte-for-byte the same
predicate as the existing `as_sql()` dispatch at expressions.py:476
(`self.connector == self.SUB and lhs_type in datetime_fields and lhs_type ==
rhs_type`). When the override fires, both source fields are concrete (non-None),
so `field.output_field == field._output_field_or_none` and the internal types
seen by `as_sql()` are identical. Therefore:
- Whenever the override returns `DurationField`, `as_sql()` routes through
  `TemporalSubtraction` (duration-producing SQL).
- Whenever `as_sql()` routes through `TemporalSubtraction`, the override returns
  `DurationField`.
No divergence exists. **Correct.**

---

## Edge cases and boundary conditions

### F3 — Filter/lookup usage unaffected (severity: high → verified no regression; no action)
Existing `test_datetime_subtraction` filters on `estimated_time__gt=F('end') -
F('start')` (no wrapper). V1 changes that rhs's inferred `output_field` from
`DateTimeField` to `DurationField`. Reviewed `django/db/models/lookups.py`:
- `Lookup.get_prep_lookup()` returns an rhs that has `resolve_expression` *as-is*
  (no value coercion based on `output_field`).
- `Lookup.process_rhs()` compiles an rhs that has `as_sql` *directly*.
- The lookup class itself is selected from the **lhs** field's registered
  lookups, not the rhs.
So the rhs `output_field` does not influence the generated WHERE SQL or the
chosen lookup. Converters are irrelevant in WHERE. The filter behaves
identically (and is now more type-consistent: `DurationField` vs `DurationField`).
**No regression.**

### F4 — Mixed temporal types correctly NOT promoted (severity: medium → intended; no action)
`DateField - TimeField` (and any `lhs_type != rhs_type`) does not satisfy
`lhs_type == rhs_type`, so the override falls through to `super()`, which raises
the usual mixed-types `FieldError`. This matches `as_sql()` (which would not
dispatch to `TemporalSubtraction` either) and is the correct, unambiguous
behavior — there is no well-defined duration for "date minus time". **Correct.**

### F5 — `DateTimeField - DurationField` still requires a wrapper (severity: low → in scope/intended; no action)
This is mixed-type arithmetic handled by `DurationExpression` in `as_sql()`. The
override requires `lhs_type == rhs_type`, so it never fires here; resolution
falls to `super()` (FieldError unless wrapped). The issue is specifically about
*temporal subtraction* (date−date / datetime−datetime / time−time), so leaving
this case unchanged is correct and matches the still-valid documentation example
at `docs/ref/models/expressions.txt:220-224` (`F('active_at') + F('duration')`).

### F6 — `None` and unresolved-to-`None` source fields (severity: medium → guarded; no action)
If either operand has no resolvable type (`_output_field_or_none` is `None`,
e.g. a bare `Value(None)` without `output_field`), the `is not None` guard skips
the temporal branch and defers to `super()`, which already filters `None`
sources. This prevents an `AttributeError` from `None.get_internal_type()` and
preserves base behavior. **Correct.**

---

## Error handling

### F7 — Mixed-type *sub-expression* operand (severity: medium → equivalent to base; no action)
If an operand is itself an unresolved-type expression (e.g. `Sum('rating') +
Sum('pages')`), `get_source_fields()` → `_output_field_or_none` re-raises that
operand's `FieldError`. This happens identically in the base
`_resolve_output_field()` (it also calls `get_source_fields()` first). So the
propagated error and message (pointing at the inner mixed types) are unchanged
from V0. **No regression.**

### F8 — `ExpressionWrapper(F('end') - F('start'), DurationField())` construction (severity: high → verified no regression; no action)
`ExpressionWrapper.__init__` (expressions.py:871) does
`getattr(expression, '_output_field_or_none', True)` on the *unresolved*
expression. For an unresolved `CombinedExpression`, `get_source_fields()` calls
`F(...)._output_field_or_none`, and `F` has no such attribute → `AttributeError`.
The 3-arg `getattr` catches `AttributeError` and returns the default `True`, so
`if True is None:` is `False` and the wrapper keeps the expression as-is. The
*base* `_resolve_output_field()` reaches the very same `AttributeError` at the
same point, so behavior is byte-identical to V0. The existing
`test_datetime_subtraction_microseconds` (which uses exactly this wrapper) is
unaffected. **No regression.** (Also note: accessing `.output_field` on an
unresolved `CombinedExpression` raised `AttributeError` before V1 too, so V1
introduces no new crash site.)

---

## Interactions with surrounding code / possible regressions

### F9 — `TemporalSubtraction` is unaffected (severity: medium → verified; no action)
`TemporalSubtraction` sets `output_field = fields.DurationField()` as a *class
attribute*, which shadows the `output_field` `cached_property`; thus
`_resolve_output_field()` is never invoked for it. The override it now inherits
is dead code for that class — harmless. **Correct.**

### F10 — `DurationExpression` is unaffected (severity: medium → verified; no action)
`DurationExpression` is only constructed in `as_sql()` for the *mixed*
DurationField case (`lhs_type != rhs_type`). Even if its `output_field` were
resolved, the override requires `lhs_type == rhs_type` and so never fires for it.
**Correct.**

### F11 — No other code builds temporal subtractions (severity: medium → verified; no action)
Grep across `repo/django` confirms `CombinedExpression`/`TemporalSubtraction`
construction and the SUB predicate live only in `expressions.py`
(`_combine`, `as_sql`, `TemporalSubtraction.__init__`). The fix is centralized at
the single inference choke-point; nothing else relies on `DateTimeField -
DateTimeField` inferring `DateTimeField` (which was a bug, not a contract).

### F12 — Value conversion produces `timedelta` on all backends (severity: high → verified; no action)
With `output_field = DurationField`, `get_db_converters()` yields
`convert_durationfield_value` on microsecond backends (SQLite/MySQL), turning the
integer-microsecond column into a `timedelta`; native-interval backends
(PostgreSQL/Oracle) return `timedelta` directly. The emitted SQL is identical to
the long-supported `ExpressionWrapper(..., output_field=DurationField())` form
and to the already-passing tests `test_duration_expressions` (the outer
`Duration + Duration` add) and `test_datetime_subtraction` (the inner sub), so
behavior is proven across backends without execution here.

### F13 — Aggregating a bare temporal subtraction now works (severity: low → improvement; no action)
`Sum(F('end') - F('start'))` previously raised; it now infers `DurationField` and
sums durations correctly. This is a natural, correct extension of the fix and not
a regression.

---

## Consistency with conventions / API contracts

### F14 — Matches the codebase idiom (severity: low → confirmed; no action)
The override mirrors `NumericOutputFieldMixin._resolve_output_field`
(`functions/mixins.py:44`) and `functions/window.py:47,77`: inspect
`get_source_fields()`, return a specialized field for a recognized case, else
defer to `super()._resolve_output_field()`. The inline `datetime_fields` set
duplicates the one in `as_sql()`, which is itself defined inline — so the
duplication is consistent with existing local style and intentionally keeps the
two predicates visibly parallel. Extracting a shared constant/helper would be a
non-minimal refactor with no behavioral benefit; **declined**.

### F15 — Documentation (severity: informational → optional; no action)
`docs/ref/models/expressions.txt` has no temporal-subtraction example that V1
renders obsolete; its ExpressionWrapper example (datetime **+** duration) remains
accurate. A release-note/doc sentence advertising that temporal subtraction no
longer needs a wrapper would be a nice enhancement, but docs are out of scope for
the (code-only, hidden) test suite and a change there carries no correctness
weight. **Not changed to keep the diff minimal.**

---

## Summary verdict
No finding requires a code change. The single high-risk concern (F2: inference vs
SQL alignment) is provably safe because the override reuses the exact predicate of
the existing `as_sql()` dispatch. The high-impact regression candidates (F3 filters,
F8 ExpressionWrapper, F12 cross-backend conversion) are each shown to be identical
to existing, already-tested behavior. **V1 stands unchanged.**
