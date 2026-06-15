# Public Compatibility Audit

Changed public symbol: `Model.pk` property setter via `Model._set_pk_val()`.

## Signature compatibility

- Before: `_set_pk_val(self, value)`.
- After V1: `_set_pk_val(self, value)`.
- Status: compatible; no public callsite signature changes.

## Return value compatibility

- Before: returned the result of `setattr()`, which is `None`.
- After V1: falls off the function body, returning `None`.
- Status: compatible.

## Observable assignment behavior

- Normal model with non-parent primary key: still assigns only
  `self._meta.pk.attname`.
- Primary key that is a non-parent relation: still assigns only that relation's
  attname because `remote_field.parent_link` is false.
- Multi-table child whose primary key is a parent link: now also assigns the
  parent PK chain. This is intentional and required by the issue.
- Parent links outside the active primary-key chain: unchanged.

## Overrides and virtual dispatch

No new virtual method calls or keyword arguments were introduced. The edit only
uses existing field attributes (`attname`, `remote_field.parent_link`, and
`target_field`) already used elsewhere in Django's model field machinery.
