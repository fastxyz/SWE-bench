# Iteration Guidance

## Decision

V1 stands unchanged.

The audit found that the V1 edit directly discharges the public intent:

```python
latex_expr = self.parenthesize(expr, PRECEDENCE["Mul"], strict=True)
```

This is better than an `Add`-only check because the public defect is a
precedence problem and the existing printer helper already states that rule.
It is also narrower than changing `Subs` precedence or `_print_Mul`, both of
which would risk outer parentheses that do not match the expected output.

## Next Code Step

No source change is recommended.

## Next Test Step

Do not modify tests in this benchmark task. In normal project work, add a
regression asserting the exact issue string for:

```python
latex(3*Subs(-x + y, (x,), (1,)))
```

Also keep coverage for `Subs(x*y, ...)` as the frame case.

## Verification Step

When a K environment exists, run:

```sh
cd fvk
kompile mini-python-printing.k --backend haskell
kast --backend haskell latex-subs-spec.k
kprove latex-subs-spec.k
```

Until then, the proof is constructed, not machine-checked.
