# Iteration Guidance

Status: V1 stands unchanged.

## Source Decision

Do not make another source edit for this issue.

Rationale:

- Findings F1 and F2 are resolved by the existing V1 expression
  `issubclass(subclass, self._subclasses) or super().__subclasscheck__(subclass)`.
- Proof obligations O1 and O2 show that this expression accepts the complete
  `BigAutoField` and `SmallAutoField` subclass families.
- Proof obligation O3 shows that direct `AutoField` subclasses still pass.
- Proof obligations O4, O8, and O9 show that negative validation behavior and
  non-subclass error branches are preserved.
- The compatibility audit in `SPEC.md` finds no public signature or dispatch
  break.

## Rejected Follow-Up Edits

- Do not special-case `BigAutoField` or `SmallAutoField` inside
  `_get_default_pk_class()`. That would fix only one consumer and leave the
  public `issubclass(C, AutoField)` compatibility surface inconsistent.
- Do not change `_subclasses`. It already names the compatibility roots; the
  defect was exact membership in `__subclasscheck__()`.
- Do not add a broad non-class guard to `__subclasscheck__()` for this issue.
  The public intent concerns class inputs passed through Python's `issubclass()`
  API, and the current behavior remains consistent with that domain.

## Recommended Tests For A Normal Development Pass

Do not edit tests in this benchmark task. In a normal Django development pass,
add tests for:

- custom `BigAutoField` subclass as `DEFAULT_AUTO_FIELD`;
- custom `SmallAutoField` subclass as `DEFAULT_AUTO_FIELD`;
- indirect custom subclass of a `BigAutoField` subclass as
  `DEFAULT_AUTO_FIELD`;
- preservation of existing non-auto, nonexistent, and empty-path validation
  behavior.

## Machine-Check Follow-Up

When an execution environment is available, run:

```sh
kompile fvk/mini-python-autofield.k --backend haskell
kast --backend haskell fvk/autofield-meta-spec.k
kprove fvk/autofield-meta-spec.k
```

Expected result: `#Top`.

Until that machine check is run, treat the proof as constructed evidence and do
not remove tests based on it.
