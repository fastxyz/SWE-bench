# INTENT_SPEC.md

Status: constructed, not machine-checked.

## Intent-Only Obligations

1. `Meta.ordering` must not raise `models.E015` for a relation path ending in a final lookup that Django recognizes, specifically the reported nullable foreign key path `supply__product__parent__isnull`.
2. The same acceptance must hold when the ordering string has a leading `-`, because the issue shows both ascending and descending `order_by()` forms as valid.
3. Existing accepted transform ordering must remain accepted.
4. Existing invalid ordering paths must remain invalid when they refer to missing fields, missing related fields, or lookup-like names that are not valid final lookups.
5. The fix must preserve the check framework's interface: `_check_ordering()` still returns a list of check errors and still uses `models.E015` for invalid ordering entries.

The current implementation is treated only as the candidate behavior to audit, not as the source of expected behavior.
