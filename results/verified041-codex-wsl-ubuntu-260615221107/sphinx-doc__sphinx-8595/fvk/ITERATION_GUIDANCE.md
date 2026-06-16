# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional production-code edit is justified by the FVK audit. The V1 change:

```python
if self.__all__ is None:
```

is the minimal discriminator required by the public issue and by PO-1 through
PO-5.

## Why not return an immediate empty list?

F-002 and PO-6 preserve the public `autodoc-skip-member` extension point. The
existing explicit-`__all__` path marks members as forced skipped and then lets
the normal filtering/event pipeline run. Returning `[]` directly for empty
`__all__` would likely satisfy the simple reproducer, but it would be a larger
behavioral change than the intent requires.

## Suggested future test

If tests were being edited in a normal development workflow, add a regression
case equivalent to:

- module has `__all__ = []`;
- module has documented `foo`, `bar`, and `baz`;
- `automodule` uses bare `:members:`;
- output contains no `py:function:: foo`, `bar`, or `baz` entries.

This session must not modify tests, and no tests were run.

## Residual risk

The FVK proof is constructed but not machine-checked. The emitted commands in
`PROOF.md` should be run in an environment with K installed before treating the
formal claims as machine-verified.
