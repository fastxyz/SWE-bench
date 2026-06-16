# Public Compatibility Audit

Status: constructed from source inspection, not machine-checked.

## Changed public symbols

No public function, method, class, constructor, or import signature was changed.

## Changed implementation behavior

`Aggregate.resolve_expression()` still returns the same expression families as before:

- no `default`: the resolved aggregate `c`;
- with `default`: a `Coalesce(c, default, output_field=...)` wrapper.

The only behavioral change is that the generated wrapper now carries the resolved aggregate's `is_summary` state.

## Callsite and override impact

- `QuerySet.aggregate()` passes `is_summary=True` through `Query.add_annotation()` for terminal aggregate expressions.
- Ordinary annotations use the default `is_summary=False`.
- `Coalesce` has no signature change.
- `Aggregate` subclasses (`Avg`, `Max`, `Min`, `StdDev`, `Sum`, `Variance`) inherit the same constructor and `resolve_expression()` behavior.
- `Count` still rejects `default` through `empty_result_set_value`, so the changed branch is not reached for `Count(default=...)`.

Compatibility result: pass. No public callsite or subclass override requires a source change.
