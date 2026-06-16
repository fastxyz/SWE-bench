# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit found that the original one-line guard is the minimal source
change required by the public issue. No additional production-code edit is
justified by the formalized obligations.

## Trace to findings and proof obligations

Finding F1 identified the operative bug: an unbounded `CharField()` created
through `Value('test')` could carry `MaxLengthValidator(None)`. PO1 shows that
the string `Value` path reaches bare `fields.CharField()`, and PO2 shows that
V1 skips the automatic max-length validator on `max_length is None`. This is
why the V1 guard is retained.

Finding F2 required preserving bounded `CharField(max_length=L)` behavior for
non-`None` limits. PO3 shows that V1 still appends `MaxLengthValidator(L)`
whenever `max_length` is not `None`, and PO5 shows that no public constructor
signature or surrounding behavior changed. This is why I did not refactor or
move the logic elsewhere.

Finding F3 required concrete model fields without `max_length` to remain
invalid through Django's system checks. PO6 shows that
`_check_max_length_attribute()` is unchanged and still reports `fields.E120`.
This is why no change was made to checks or to `Value._resolve_output_field()`.

Finding F4 records that no unresolved proof obstacle remains in the audited
validator-state model. The proof obligations cover the reported unbounded path,
the bounded preservation path, existing validator preservation, and public API
compatibility. This supports keeping V1 unchanged.

## Artifacts

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also emitted the auxiliary formal core required by the FVK documentation:

- `fvk/mini-python-charfield.k`
- `fvk/charfield-spec.k`

These artifacts are constructed, not machine-checked. I did not run tests,
Python, `kompile`, `kast`, or `kprove`.
