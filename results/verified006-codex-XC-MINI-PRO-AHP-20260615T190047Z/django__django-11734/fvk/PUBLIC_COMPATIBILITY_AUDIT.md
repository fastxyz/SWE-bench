# Public Compatibility Audit

Status: constructed from source inspection; no code was executed.

## Changed symbol

`django.db.models.sql.query.Query.split_exclude(self, filter_expr, can_reuse, names_with_path)`

- Signature changed: no.
- Return shape changed: no; it still returns `(condition, needed_inner)`.
- Public API surface changed: no. `split_exclude()` is an internal ORM query-construction method.
- Call protocol changed: no. Existing callers still pass `filter_expr`, `can_reuse`, and `names_with_path`.

## Related public behavior

- `QuerySet.exclude()` and `QuerySet.filter(~Q(...))` continue to use the existing query-building path.
- Plain `F()` handling is unchanged by the new `OuterRef` branch because the `OuterRef` check is ordered before the broader `F` check and the `elif isinstance(filter_rhs, F)` branch remains intact.
- Non-`F` RHS values are unaffected.

## Result

No compatibility blocker was found. The change is behavioral and internal: it adjusts scope preservation for existing `OuterRef` values when `split_exclude()` introduces an extra nested query.

