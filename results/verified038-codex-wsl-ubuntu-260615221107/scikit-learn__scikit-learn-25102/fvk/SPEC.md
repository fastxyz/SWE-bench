# FVK Spec

Status: constructed, not machine-checked.

## Scope

The verified unit is `SelectorMixin.transform` plus the selected-column portion of `SelectorMixin._transform` in `repo/sklearn/feature_selection/_base.py`. The observable being verified is whether selectors return selected columns from the validated homogeneous array or from the original pandas `DataFrame` under pandas output.

The spec deliberately models only the property-carrying state:

- data container kind: DataFrame, dense array, sparse array;
- row index;
- column labels;
- per-column dtype metadata;
- column values;
- selector support mask;
- output configuration and auto-wrap flag;
- validation success as a precondition for in-domain claims.

It does not model score computation, individual selector fitting algorithms, pandas internals, NumPy numeric conversion details, or all Python exception paths.

## Public Intent Ledger Summary

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Key obligations:

- E1/E2/E3 require dtype-preserving pandas output for the `SelectKBest` mixed-dtype DataFrame workflow.
- E4/E5 limit the fix to selectors/subset transformers and reject generic cast-back.
- E6 establishes that `SelectorMixin` returns selected input features.
- E7 requires respect for existing `set_output` configuration.
- E9 requires public API compatibility for selector subclasses.

## Domain

In-domain inputs for the dtype-preservation claim:

- `X` is a pandas `DataFrame` represented by `df(index, columns, dtypes, values)`.
- `X` passes existing selector validation.
- The selector support mask has length equal to the number of input columns unless the existing all-false selected-feature branch is taken.
- Output config is pandas and auto wrapping is configured.

In-domain inputs for preservation of legacy behavior:

- The same selector transform inputs when output config is default, auto wrapping is disabled, or input is not a pandas `DataFrame`.

## Formal Claims

The K claims are in `selector-transform-spec.k`.

- `SELECTOR-DEFAULT-ARRAY`: default output uses validated data and selected mask.
- `SELECTOR-PANDAS-PRESERVE`: pandas output for a DataFrame validates first, then selects from the original DataFrame.
- `SELECTOR-EMPTY-PANDAS`: all-false mask on the pandas-preserving path returns an empty DataFrame retaining the input index.
- `SELECTOR-EMPTY-ARRAY`: all-false mask outside the pandas-preserving path keeps old empty-array behavior.
- `INVALID-CONFIG-ORDER`: invalid output config is not used to choose original-DataFrame slicing in raw `transform`; existing wrapper reports it after raw transform if raw transform succeeds.

## K Commands

These commands are emitted for later machine checking. They were not run.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/selector-transform-spec.k
kprove fvk/selector-transform-spec.k
```
