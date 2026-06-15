# Iteration Guidance

Status: constructed for FVK audit; not machine-checked.

## Decision

V1 stands unchanged. The FVK findings are closed by the current source code:

- F1 is closed by PO1 and PO4.
- F2 is closed by PO2.
- F3 is closed by PO3.
- F4 is confirmed by PO5.
- F5 is a tooling caveat, not a code defect.

## Recommended follow-up tests

No test files were edited in this benchmark. A future normal development pass
should add or keep tests for:

- constructing the reported HIERARCH card with value `0.009125` and verifying
  the comment is not truncated;
- `_format_float` values based on `value = (1 - 2**-53) * 2**exp` for
  representative exponents `-60`, `0`, and `60`;
- lowercase exponent normalization when `str(value)` is selected;
- fallback behavior when `str(value)` exceeds 20 characters.

## Machine-check follow-up

Run the emitted commands in an environment with K installed:

```sh
kompile fvk/mini-fits-card-format.k --backend haskell
kast --backend haskell fvk/fits-card-format-spec.k
kprove fvk/fits-card-format-spec.k
```

Keep all tests until `kprove` returns `#Top` and the mini semantics has been
reviewed as adequate for the helper logic.
