# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found that V1 satisfies the public intent and the proof obligations for the reported defect:

- F1 / PO-2: Decimal `Lag` in SQLite `Window` now has the cast outside `OVER`.
- F2 / PO-3: FloatField window behavior is preserved.
- F3 / PO-4: standalone Decimal `Func` and aggregate casting is preserved.
- F4 / PO-5: source expression metadata is only changed on a clone.
- PO-6 / PO-7: backend checks and public compatibility are preserved.

## Recommended Future Tests

Do not modify test files in this task. In a normal Django development environment, add or keep tests that assert:

1. `Window(expression=Lag('decimal_field'))` on SQLite compiles/evaluates without `near "OVER"` syntax failure.
2. The generated SQL shape is `CAST(<lag over clause> AS NUMERIC)`, not `CAST(<lag> AS NUMERIC) OVER`.
3. FloatField `Lag` inside `Window` remains uncast and working.
4. A Decimal aggregate or other Decimal window-compatible expression inside `Window` receives the same outer cast.
5. Ordinary Decimal aggregate/function annotations outside `Window` keep existing SQLite Numeric casting.

## Proof Follow-Up

When an execution environment is available, run:

```sh
cd fvk
kompile mini-django-sqlite-window.k --backend haskell
kast --backend haskell django-window-sqlite-spec.k
kprove django-window-sqlite-spec.k
```

Keep all related Django tests until the K proof is machine-checked and Django's own test suite passes.

## Residual Risk

F6 / PO-9 records an underspecified extension-point risk: a custom `window_compatible=True` expression whose SQL rendering depends on its own `output_field` could render differently when V1 compiles the cloned source as `FloatField`. The public issue and hint do not justify a broader source change for that case. If this becomes a public requirement, consider a more targeted internal "suppress SQLite numeric cast for this compile" mechanism instead of changing cloned source `output_field`.
