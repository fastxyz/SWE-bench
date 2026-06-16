# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code defect in the
`wraps()`-based repair. The proof obligations that matter for the public issue
are discharged by source reasoning:

- PO-001 and PO-004 show that `inspect.signature()` now tracks the original
  queryset method signature generically.
- PO-002 shows that the incomplete-metadata root cause is addressed.
- PO-005 and PO-006 show that method selection and runtime forwarding remain
  unchanged.

## Recommended Next Steps

1. In an environment where running code is permitted, add or keep a public test
   that constructs a model manager and asserts that
   `inspect.signature(Model.objects.bulk_create)` matches the current
   `QuerySet.bulk_create` bound signature.
2. Include at least one copied method with a non-public name and
   `queryset_only=False` in future coverage if this area changes again, because
   PO-005 depends on preserving the existing eligibility filter.
3. Do not hard-code the historical `bulk_create(objs, batch_size=None,
   ignore_conflicts=False)` signature in tests or docs for this checkout; compare
   against the current queryset method signature instead.
4. If K tooling is available later, materialize the abstract model in
   `PROOF.md` as executable K and run the recorded `kompile`, `kast`, and
   `kprove` commands before using proof coverage to remove tests.

## No-Code-Change Rationale

No additional source edit is justified. The only candidate concerns found during
the audit were process or specification issues:

- F-002 affects how the spec should be written, not the code.
- F-004 confirms that copying more metadata is intended by the public issue.
- F-005 is a machine-checking limitation imposed by the task constraints.
