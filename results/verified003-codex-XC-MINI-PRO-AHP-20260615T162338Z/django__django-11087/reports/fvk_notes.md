# FVK Notes

## Decisions and changes

### Kept V1's core collector projection

Decision: Keep the V1 approach of applying `QuerySet.only()` inside the
deletion collector rather than changing SQL compiler behavior.

Trace:

- `fvk/SPEC.md` E1-E4 define the public requirement: delete collection should
  fetch only required concrete model fields, including nested related querysets.
- `fvk/PROOF_OBLIGATIONS.md` PO1-PO4 show that V1's core projection point is
  correct: compute required fields, use Django's deferred-loading machinery, and
  apply it before queryset evaluation.
- `fvk/PROOF.md` Lemmas L1-L4 construct the proof for this behavior.

### Kept V1's signal-listener opt-out

Decision: Keep the shared signal-listener predicate and skip projection when
listeners are present.

Trace:

- `fvk/SPEC.md` E6 requires disabling optimization when receivers may inspect
  arbitrary fields.
- `fvk/PROOF_OBLIGATIONS.md` PO5 discharges that `_can_optimize_delete_queryset()`
  returns false for signal-visible models.

### Added a collector optimization hook

Decision: Add `Collector._can_optimize_delete_queryset()` and have
`_optimize_delete_queryset()` call it.

Trace:

- `fvk/FINDINGS.md` F1 found that V1 incorrectly optimized the admin display
  collector.
- `fvk/PROOF_OBLIGATIONS.md` PO8 requires dynamic-dispatch opt-out for
  collectors that need full objects.

### Disabled projection for admin `NestedObjects`

Decision: Override `_can_optimize_delete_queryset()` in
`django.contrib.admin.utils.NestedObjects` to return `False`.

Trace:

- `fvk/SPEC.md` E7 records the admin code comment that deletion confirmation
  needs loaded objects for display.
- `fvk/FINDINGS.md` F1 describes the V1 failure mode: `NestedObjects` called
  `super().related_objects()` and then `select_related()`, which is unsafe on a
  queryset that may have deferred the relation connector field.
- `fvk/PROOF_OBLIGATIONS.md` PO8 proves the override restores full querysets for
  this subclass.

### Made required-field ordering deterministic

Decision: Change `_delete_fields()` to return attnames in `opts.concrete_fields`
order instead of expanding an unordered set into `only()`.

Trace:

- `fvk/FINDINGS.md` F2 identifies unordered set expansion as unnecessary
  nondeterminism.
- `fvk/PROOF_OBLIGATIONS.md` PO7 requires stable model concrete field order.

### Kept generic relation hooks unchanged

Decision: Do not inject projection into `bulk_related_objects()` paths.

Trace:

- `fvk/FINDINGS.md` F3 classifies this as a residual boundary.
- `fvk/PROOF_OBLIGATIONS.md` PO9 frames generic/private relation hooks as
  unchanged because arbitrary hook implementations do not expose a generic safe
  projection contract.

### Did not alter annotation or extra-select behavior

Decision: Do not clear query annotations or `extra(select=...)` output in this
patch.

Trace:

- `fvk/FINDINGS.md` F4 records this as outside the public issue's concrete model
  field projection evidence.
- `fvk/PROOF_OBLIGATIONS.md` PO9 frames it as unchanged.

### Accepted deferred-field behavior for custom `on_delete`

Decision: Keep the V1/V2 behavior where custom `on_delete` callables may receive
objects with unrelated fields deferred.

Trace:

- `fvk/FINDINGS.md` F5 records that arbitrary custom callables can still access
  values through Django's deferred loading, but query-count preservation for
  those callables is not part of the issue intent.
- `fvk/PROOF_OBLIGATIONS.md` PO6 discharges the built-in handler behavior and
  records the custom-callable boundary.

## Verification status

All FVK artifacts are constructed, not machine-checked. The benchmark forbids
running tests, Python, or K tooling, so no runtime verification was attempted.
