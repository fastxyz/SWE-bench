# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit did not surface a blocking problem in the source fix. The public intent is discharged by adding `Choices.__str__()` to delegate to the concrete `.value`, and the rejected alternatives would change broader ORM behavior without public evidence.

## Recommended Next Iteration Inputs

1. Add or keep tests for `str()` on freshly created `TextChoices` field values.
2. Add or keep analogous tests for `IntegerChoices` field values.
3. Keep tests that assert enum metadata and `repr()` behavior.
4. Do not implement model assignment-time coercion unless a separate public requirement asks for exact primitive storage in `__dict__`.
5. If the project wants stricter compatibility review for custom `Choices` subclasses, add public tests documenting their desired `str()` behavior. Current public evidence supports concrete-value stringification.

## Machine-Check Follow-up

In an environment with K installed, run:

```sh
cd fvk
kompile mini-python-enum.k --backend haskell
kast --backend haskell choices-str-spec.k
kprove choices-str-spec.k
```

Until `kprove` returns `#Top`, treat the proof as constructed evidence and do not remove tests on its basis.
