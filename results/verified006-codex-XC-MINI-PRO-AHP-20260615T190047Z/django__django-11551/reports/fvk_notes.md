# FVK Notes

## Decision Summary

The FVK audit did not leave V1 fully unchanged. V1 correctly fixed the reported
false `admin.E108` for metadata-visible fields whose model class descriptor is
not accessible, but it still checked `ModelAdmin` attributes before same-named
model fields. The public admin docs and runtime `lookup_field()` behavior both
put model fields first, so V2 moves `_meta.get_field(item)` before
`hasattr(obj, item)`.

## Source Change

Changed `repo/django/contrib/admin/checks.py`.

The helper now:

1. accepts callables immediately;
2. tries `obj.model._meta.get_field(item)` before admin/model attribute
   fallback;
3. checks resolved values for `models.ManyToManyField`;
4. accepts `ModelAdmin` attributes only after metadata lookup raises
   `FieldDoesNotExist`;
5. falls back to `getattr(obj.model, item)`;
6. returns `admin.E108` only if metadata lookup, admin lookup, and model
   attribute fallback all fail.

Trace to FVK artifacts:

- Finding F1 and PO2 justify keeping the core V1 fix: metadata-visible fields
  must not be rejected because class-level descriptor access fails.
- Finding F2 and PO3 justify the V2 improvement: model field validation must
  occur before a same-named `ModelAdmin` attribute can short-circuit.
- Finding F3 and PO6 justify the shared `ManyToManyField` check after fallback
  resolution.
- PO7 justifies preserving `admin.E108` only for complete lookup failure.
- PO8 and PO9 justify preserving the public error IDs, message families,
  helper signature, and direct caller protocol.

## Decisions To Keep V1 Behavior

The audit kept V1's model attribute fallback after `FieldDoesNotExist` because
the issue explicitly rejects using a `None` field value as a lookup-failure
sentinel. This is covered by Finding F1, Finding F3, PO5, and PO6.

The audit kept callable acceptance as the first branch. Although the docs list
model fields before callables, callable objects and string field names are
disjoint in the documented contract, and PO1 preserves the existing successful
callable behavior without weakening field-name validation.

## Verification Status

The formal proof is constructed, not machine-checked. Per the task constraints,
I did not run tests, Python, `kompile`, `kast`, or `kprove`. The exact K commands
to run later are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

