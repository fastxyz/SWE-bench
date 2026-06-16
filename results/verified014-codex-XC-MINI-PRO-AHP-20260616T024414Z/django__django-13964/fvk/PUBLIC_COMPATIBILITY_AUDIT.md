# Public Compatibility Audit

Status: source inspection only. No tests or code were run.

## Changed Symbol

`Model._prepare_related_fields_for_save(self, operation_name)`

## Signature And Dispatch

- Signature unchanged.
- Callers unchanged:
  - `Model.save()` calls `_prepare_related_fields_for_save(operation_name='save')`.
  - `QuerySet._prepare_for_bulk_create()` calls
    `_prepare_related_fields_for_save(operation_name='bulk_create')`.
- No new arguments, return values, exceptions, or public data structures were
  introduced.

## Behavior Compatibility

- Existing `obj.pk is None` `ValueError` behavior is preserved.
- Existing cache invalidation when the related target and local attname differ
  is preserved.
- Existing behavior for uncached relation fields is preserved.
- Existing behavior for non-empty local relation values is preserved.
- Changed behavior is limited to cached relation fields whose local relation
  attname is in `field.empty_values`; the public issue identifies the `""`
  member of this set as buggy legacy behavior.

## Compatibility Verdict

PASS. The change does not alter a public signature or dispatch shape. The
behavioral change is the intended correction for the public issue.
