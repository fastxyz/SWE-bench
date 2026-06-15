# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Formal Files

- Semantics: `fvk/mini-django-save.k`
- Claims: `fvk/save-table-spec.k`

Machine-check commands to run later in a K-enabled environment:

```sh
kompile fvk/mini-django-save.k --backend haskell
kast --backend haskell fvk/save-table-spec.k
kprove fvk/save-table-spec.k
```

Expected result if the constructed proof is accepted by K: `#Top`.

## Transition System

The mini semantics models the relevant `_save_table()` decision as:

```text
ForceInsertOut =
    ForceInsertIn or (
        not Raw and
        not ForceInsertIn and
        Adding and
        HasPkDefault
    )
```

Then:

- If `PkSet` and not `ForceInsertOut`, try UPDATE.
- If UPDATE sees `RowExists`, the save is updated and no INSERT happens.
- If UPDATE sees no row, INSERT follows.
- If `ForceInsertOut` is true, UPDATE is skipped and INSERT is attempted.
- If that INSERT targets an existing row, the observable is modeled as `duplicate`.

This transition is the branch changed by V1. The pre-V1 model is obtained by deleting `not Raw` from `ForceInsertOut`; under PO1 it reaches `duplicate`, which is the regression.

## PO1 Proof - Raw Existing Fixture Row

Initial symbolic state:

```text
saveTable(true, false, true, true, true, true)
```

Symbolic execution of the transition rule:

```text
ForceInsertOut =
    false or (
        not true and
        not false and
        true and
        true
    )
  = false or (false and true and true and true)
  = false
```

The state rewrites to:

```text
decide(true, false, true)
```

The `decide(true, false, true)` rule rewrites to:

```text
saved(true, update .Queries)
```

This proves the raw existing fixture path updates and does not insert.

## PO2 Proof - Raw Missing Fixture Row

Initial symbolic state:

```text
saveTable(true, false, true, true, true, false)
```

The same Boolean simplification gives `ForceInsertOut = false`, so the state rewrites to:

```text
decide(true, false, false)
```

The corresponding decision rule rewrites to:

```text
saved(false, update insert .Queries)
```

This proves raw fixture loads retain the UPDATE then INSERT fallback when the row is absent.

## PO3 Proof - Non-Raw Generated-Default Creation

Initial symbolic state:

```text
saveTable(false, false, true, true, true, false)
```

Symbolic execution:

```text
ForceInsertOut =
    false or (
        not false and
        not false and
        true and
        true
    )
  = true
```

The state rewrites to:

```text
decide(true, true, false)
```

The decision rule rewrites to:

```text
saved(false, insert .Queries)
```

This proves V1 preserves the insert-only optimization for the generated-default creation path.

## PO4 Diagnostic - Normal Explicit Primary Key

The opening issue example corresponds to:

```text
saveTable(false, false, true, true, true, true)
```

V1 computes `ForceInsertOut = true`, then reaches:

```text
decide(true, true, true) => saved(false, duplicate .Queries)
```

This does not satisfy the stronger backward-compatible postcondition `saved(true, update .Queries)`. The proof therefore does not claim that V1 fixes normal non-raw explicit-pk saves. It records the path as Finding F3 and relies on the public compromise that selected a raw fixture repair plus the `force_update` workaround for this direct pattern.

## Adequacy and Compatibility

The adequacy gate passes for PO1, PO2, and PO3 because their English paraphrases match the intent ledger entries I1 through I5 in `SPEC.md`.

The adequacy gate does not pass for a broad claim that "all explicit-pk saves update existing rows." That claim is intentionally absent from the success proof and is preserved as Finding F3.

The compatibility audit passes because V1 changes no signatures and the source still carries `raw=True` from serializer deserialization to `_save_table()`.

## Test Guidance

No tests were run or modified. No tests should be removed based on this constructed proof. A future machine-checked run could make narrow unit tests for PO1 through PO3 redundant, but integration tests for serializers, fixture loading, database errors, signals, parent model saves, and direct non-raw explicit-pk behavior should be kept.
