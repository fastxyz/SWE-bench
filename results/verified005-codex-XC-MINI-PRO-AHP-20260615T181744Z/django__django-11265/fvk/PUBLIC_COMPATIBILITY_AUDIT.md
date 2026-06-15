# Public Compatibility Audit

Status: constructed from source inspection only. No tests or code were run.

## Changed public symbols

None.

The V1 patch changes only internals of `Query.split_exclude()` and
`Query.trim_start()` in `repo/django/db/models/sql/query.py`.

## Signature compatibility

- `Query.split_exclude(self, filter_expr, can_reuse, names_with_path)`:
  unchanged.
- `Query.trim_start(self, names_with_path)`: unchanged.
- No virtual dispatch calls gained new arguments.
- No return shape changed: `split_exclude()` still returns
  `(condition, needed_inner)` and `trim_start()` still returns
  `(trimmed_prefix, contains_louter)`.

## Public behavior compatibility

- Existing unfiltered `exclude()` subquery behavior is framed by PO-4.
- Existing unsupported `FilteredRelation` condition shapes remain governed by
  `add_filtered_relation()` and docs; V1 does not change that validation.
- Test files were not modified.

Compatibility status: pass.

