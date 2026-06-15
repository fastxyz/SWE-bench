# Baseline Notes

## Root cause

`Model._check_ordering()` walks each `Meta.ordering` string containing `__` by resolving field names manually. When a path segment can't be resolved as a field, the check only accepts it if it is a registered transform on the previous field. The ORM also accepts registered lookups in ordering strings, such as a nullable foreign key path ending in `__isnull`, but the system check rejected those final lookup segments with `models.E015`.

## Files changed

- `repo/django/db/models/base.py`: Updated `_check_ordering()` so that an unresolved path segment is valid when it is either a registered transform or, if it is the last segment, a registered lookup on the previously resolved field. This keeps invalid intermediate lookup-like segments rejected while allowing valid final lookups such as `supply__product__parent__isnull`.

## Assumptions and alternatives

- I assumed the intended behavior is for the model check to accept the same final registered lookup forms that `order_by()` accepts, without relaxing checks for missing related fields in the middle of a path.
- I considered replacing the manual validation with `Query.add_ordering()` or `names_to_path()`, but rejected that because their validation is broader and would allow some trailing unresolved names that existing model checks intentionally report as `models.E015`.
- I did not run tests or execute Django code because the task explicitly forbids running tests or code in this workspace.
