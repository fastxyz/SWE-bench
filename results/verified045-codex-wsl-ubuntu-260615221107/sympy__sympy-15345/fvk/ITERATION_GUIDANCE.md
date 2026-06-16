# ITERATION_GUIDANCE

## Decision

V1 stands unchanged.

## Rationale

The FVK audit found the original defect and the homogeneous `Min` sibling both
discharged by V1:

- F1 / PO1: `Max` now has class-specific dispatch to `_print_Function`.
- F2 / PO2: `Min` now has class-specific dispatch to `_print_Function`.
- PO3: `_print_Function` is the existing bracket-call formatter.
- PO4 and PO6: ordinary function printing and generic fallback behavior are
  preserved.
- PO7: the added methods are compatible with the existing printer dispatch API.

No proof obligation required a source edit beyond V1.

## Recommended Tests For A Future Test-Editing Pass

Do not edit tests in this benchmark task. For maintainers, the focused tests are:

```python
assert mathematica_code(Max(x, 2)) == "Max[2, x]"
assert mathematica_code(Min(x, 2)) == "Min[2, x]"
```

If exact source argument order is desired instead, that is a separate product
requirement because SymPy canonicalizes `Max`/`Min` arguments before printing.

## Future Machine Check

In an environment with K installed, run:

```sh
cd fvk
kompile mini-python-printer.k --backend haskell
kast --backend haskell mathematica-printer-spec.k
kprove mathematica-printer-spec.k
```

Expected successful result: `#Top`.
