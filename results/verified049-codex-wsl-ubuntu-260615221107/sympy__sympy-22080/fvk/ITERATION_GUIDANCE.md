# FVK Iteration Guidance

Status: V2 source change applied; proof constructed, not machine-checked.

## Code Decision

Keep the V1 design of fixing Python code printer parenthesization rather than changing `lambdify` module behavior or the global precedence table.

Apply the V2 refinement from F-002: the helper now recognizes inherited `_print_Mod` dispatch by checking the class MRO, while excluding objects with a custom `_pythoncode` method.

No additional source files need changes according to the current proof obligations.

## Suggested Tests For A Future Test-Enabled Environment

Add or confirm tests for these public behaviors:

```python
assert pycode(-Mod(x, y)) == '-(x % y)'
assert pycode(2*Mod(x, y)) in ('2*(x % y)', '(x % y)*2')
assert pycode(Mod(x, y*z)) == 'x % (y*z)'  # exact spacing may follow printer style
```

For `lambdify`, inspect generated source or compare values:

```python
g = lambdify([x, y], -Mod(x, y), modules=[])
assert g(3, 7) == -3
```

Add a small inherited-`Mod` printer test if the project accepts such a custom class in tests.

## Machine Verification

Run these commands in an environment with K installed:

```sh
kompile fvk/mini-python-precedence.k --backend haskell
kast --backend haskell fvk/pycode-mod-precedence-spec.k
kprove fvk/pycode-mod-precedence-spec.k
```

Expected result: `#Top`.

## Open Questions

No user clarification is needed for the reported issue. The public intent identifies Python `%` precedence as the fault and gives the direct `pycode` reproduction.

The only residual policy question is style-level: whether exact string tests should require the minimal parenthesized output `-(x % y)` or accept semantically equivalent extra parentheses. The source change targets correct grouping and keeps existing operand-parentheses behavior.
