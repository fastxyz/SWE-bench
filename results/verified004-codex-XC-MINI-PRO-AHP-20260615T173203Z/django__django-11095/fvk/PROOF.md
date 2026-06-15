# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims

The formal claims are written in `fvk/modeladmin-inlines-spec.k` against the
fragment semantics in `fvk/mini-django-admin.k`.

- GET-INLINES-DEFAULT discharges PO-001.
- GET-INLINE-INSTANCES-HOOK discharges PO-002.
- GET-INLINE-INSTANCES-PRESERVE-FILTER discharges PO-003.
- TO-FIELD-ALLOWED-FRAME discharges PO-004.
- CHECKS-FRAME discharges PO-006.

## Constructed Proof Sketch

1. `get_inlines()` has no branches or loops. Symbolic execution of the method
   body returns the `inlines` attribute of the receiver. This proves PO-001 for
   the default implementation.

2. `get_inline_instances()` initializes an empty result list and enters one
   loop over the selected inline classes. The only V2 edit is the loop source:
   `self.get_inlines(request, obj)`. Symbolic dispatch therefore makes the
   selected class list equal to the hook result, proving PO-002.

3. The loop body is unchanged from the pre-fix implementation. A list-induction
   circularity over the remaining inline classes proves that each class selected
   by the hook is instantiated and either skipped or appended according to the
   same permission predicates as before. This proves PO-003.

4. F-001 showed that V1's `to_field_allowed()` edit had no clean object-aware
   proof obligation: the method lacks an `obj` parameter, so calling
   `get_inlines(request)` can under-approximate object-dependent inline classes.
   V2 restores static `admin.inlines`, making the related-object validation
   frame identical to the pre-fix code. This proves PO-004 as a frame
   condition.

5. `django.contrib.admin.checks` was not edited. Since the check path has no
   request/object context, PO-006 is discharged by unchanged source.

## Machine Check Commands

These commands are recorded for a future environment. They were not run here.

```sh
kompile fvk/mini-django-admin.k --backend haskell
kast --backend haskell fvk/modeladmin-inlines-spec.k
kprove fvk/modeladmin-inlines-spec.k
```

Expected machine-check result after any syntax/tooling adjustments required by
the local K installation: all claims discharge to `#Top`.

## Residual Risk

The proof is partial correctness and constructed only. It does not prove
termination beyond the finite-list loop assumption for `inlines`, and it does
not cover all of Django admin.

No test removal is recommended because the proof was not machine-checked and
the task forbids modifying tests.
