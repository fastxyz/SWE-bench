# FVK Notes

## Decision Summary

No additional source changes were made during the FVK pass. The V1 edit in `repo/django/db/migrations/autodetector.py` stands unchanged.

## Trace From Findings And Obligations

F-001 identifies the actual pre-V1 bug: a relational field can have `field.remote_field.model` while its deconstructed kwargs omit `"to"`, causing `KeyError`. PO-001 and PO-003 require the helper to treat that missing-key relation case as valid. V1's `deconstruction[2].pop('to', None)` discharges both obligations because dictionary `pop()` with a default is total for absent keys.

F-002 confirms that V1 preserves the intended relation-target erasure for normal relation fields whose deconstruction includes `"to"`. PO-002 requires exactly that behavior, and `pop('to', None)` still removes the key when present.

F-003 confirms that non-relation fields remain unchanged. PO-004 requires that the helper strip only related-field targets; V1 keeps the original branch condition, so the new `pop()` operation is not applied to non-relational fields.

F-004 explains why no adjacent autodetector edit is needed. PO-006 covers public compatibility and nearby call paths, and the other direct `['to']` read in `generate_renamed_fields()` is already guarded with `'to' in old_field_dec[2]`.

F-005 explains why I did not add generic validation for malformed deconstruction tuples. PO-007 relies on Django's `Field.deconstruct()` contract that kwargs are a dict, and `deep_deconstruct()` already depends on `kwargs.items()` before the changed line.

F-006 and PO-008 record the execution limits. No tests, Python, or K tooling were run, and no test files were modified. The proof is constructed, not machine-checked.

## Alternatives Considered

I considered replacing the line with an explicit membership guard before deletion. That would satisfy the missing-key case, but it is not better than `pop('to', None)` for the stated obligations and would be a larger expression for the same semantics.

I considered broadening the patch to other migration autodetector code that reads `"to"`. F-004 and PO-006 rejected that because the adjacent code already checks membership and the public issue points to model-rename relation-agnostic comparison.

I considered adding defensive handling for invalid custom `deconstruct()` return shapes. F-005 and PO-007 rejected that as outside the issue and outside Django's documented field deconstruction contract.
