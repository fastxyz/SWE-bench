# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level problem that
requires another edit to `repo/sphinx/ext/autodoc/mock.py`.

## Decision Trace

- The reported crash is captured as `fvk/FINDINGS.md` F1. It is discharged by
  `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, PO4, and PO5: V1 normalizes generic
  keys to strings before `_make_subclass()` performs display-name concatenation
  or calls `type()`, and `_MockObject.__getitem__()` reaches that safe path.
- Existing mock behavior is captured as F2 and discharged by PO3: string names
  still pass through unchanged, so dotted repr behavior such as
  `mocked_module.some_attr` is preserved.
- The only additional audit concern was F3: a mocked object can fabricate a
  non-string `__name__` attribute through `__getattr__`. V1 already handles this,
  and PO6 records the relevant proof obligation: use `__name__` only when it is
  actually a string; otherwise fall back to `repr(name)`.
- Public compatibility is captured as F4 and discharged by PO7: the changed
  annotations widen accepted runtime values but do not change arity, dispatch
  shape, or return shape.

## Artifact Choices

The requested five FVK artifacts were written under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

Because the FVK docs require a formal core, I also wrote
`mini-python-mock.k` and `autodoc-mock-spec.k`, plus the adequacy and
compatibility files used by the FVK gate:

- `INTENT_SPEC.md`
- `PUBLIC_EVIDENCE_LEDGER.md`
- `FORMAL_SPEC_ENGLISH.md`
- `SPEC_AUDIT.md`
- `PUBLIC_COMPATIBILITY_AUDIT.md`

All proof claims are labeled constructed, not machine-checked. Per the task
instructions, I did not run tests, Python code, `kompile`, `kast`, or `kprove`.
