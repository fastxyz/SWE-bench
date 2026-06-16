# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged. The FVK audit found that the one-line source change
discharges the public intent and the table-family completeness obligation.

Trace:

- F-001 and PO-003 show the reported Decimal/Integer MOD bug is fixed.
- F-002 and PO-005 show the broader mixed numeric table family is consistently
  handled.
- F-003 and PO-006 show why POW and Decimal/Float combinations should remain
  unchanged.
- F-004 and PO-008 show no compatibility follow-up is needed.

## Recommended Tests for Maintainers

Do not add or modify tests in this task. If maintainers add tests later, the most
targeted cases are:

- `DecimalField % IntegerField` resolves to `DecimalField`.
- `IntegerField % DecimalField` resolves to `DecimalField`.
- An `IntegerField` subclass paired with `DecimalField` under MOD resolves to
  `DecimalField`.
- `IntegerField % FloatField` and `FloatField % IntegerField` resolve to
  `FloatField`, reflecting the whole mixed numeric family.
- Mixed numeric POW remains unsupported unless a separate public requirement
  changes that contract.

## Machine-Check Follow-Up

In an environment with K installed, run:

```sh
kompile fvk/mini-combined-expression.k --backend haskell
kast --backend haskell fvk/combined-expression-spec.k
kprove fvk/combined-expression-spec.k
```

Until `kprove` returns `#Top`, no test-removal recommendation should be acted on.

## Residual Risks

- The proof is partial and table-focused; it does not prove database backend SQL
  arithmetic semantics.
- The mini-K model abstracts Python's full class system into field-family
  predicates. This is adequate for the issue because Django's resolver uses
  `issubclass()` against those families.
- No tests or project code were executed, per task constraints.
