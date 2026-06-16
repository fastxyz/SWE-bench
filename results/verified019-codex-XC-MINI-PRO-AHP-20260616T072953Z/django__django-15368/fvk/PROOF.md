# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Claims Proved in the Mini-Semantics

The proof targets the K claims in `fvk/bulk-update-spec.k`:

1. `bulkThen(Resolvable(FRef(NAME))) => Column(NAME)`
2. `bulkThen(Plain(V)) => Param(V)`
3. `bulkThen(Resolvable(ExprNode(SQL))) => ExprNode(SQL)`

These claims cover the property needed to distinguish the bug: whether `bulk_update()` treats an assigned field value as an expression to resolve or as a literal to bind.

## Symbolic Execution Sketch

For `Resolvable(FRef(NAME))`:

1. `bulkThen(Resolvable(FRef(NAME)))` rewrites to `normalize(Resolvable(FRef(NAME))) ~> #resolveForUpdate`.
2. `normalize(Resolvable(E))` rewrites to `E`, so the state becomes `FRef(NAME) ~> #resolveForUpdate`.
3. The continuation rewrites to `resolveForUpdate(FRef(NAME))`.
4. `resolveForUpdate(FRef(NAME))` rewrites to `Column(NAME)`.

This discharges PO-1 through PO-3.

For `Plain(V)`:

1. `bulkThen(Plain(V))` rewrites to `normalize(Plain(V)) ~> #resolveForUpdate`.
2. `normalize(Plain(V))` rewrites to `Value(V)`.
3. The continuation rewrites to `resolveForUpdate(Value(V))`.
4. `resolveForUpdate(Value(V))` rewrites to `Param(V)`.

This discharges PO-4.

For `Resolvable(ExprNode(SQL))`:

1. `bulkThen(Resolvable(ExprNode(SQL)))` rewrites to `normalize(Resolvable(ExprNode(SQL))) ~> #resolveForUpdate`.
2. `normalize(Resolvable(E))` rewrites to `E`, so the state becomes `ExprNode(SQL) ~> #resolveForUpdate`.
3. The continuation rewrites to `resolveForUpdate(ExprNode(SQL))`.
4. `resolveForUpdate(ExprNode(SQL))` rewrites to `ExprNode(SQL)`.

This discharges the general expression-protocol obligation in PO-2 and PO-3.

## Source-Level Composition

The source loops compose the pointwise transfer function over all selected objects and fields:

- The object loop applies the normalization predicate once per object/field value.
- The field loop collects those normalized `When` results into a `Case` for each field.
- The batch loop collects update kwargs and applies them through the existing `update()` path.

Because V1 only changes the normalization predicate, and because the rest of the loops and update application are textually unchanged, the pointwise proof composes over every object/field pair in each batch.

## Adequacy and Compatibility

`FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and `SPEC_AUDIT.md` checks them against `INTENT_SPEC.md`. No adequacy failure or public compatibility failure was found.

## Machine-Check Commands

These commands are recorded for later machine checking and were not executed:

```sh
kompile fvk/mini-django-bulk-update.k --backend haskell
kast --backend haskell fvk/bulk-update-spec.k
kprove fvk/bulk-update-spec.k
```

Expected machine-check result: `#Top` for all three claims, assuming the mini-semantics files parse as written.

## Residual Risk

The proof is partial correctness only and is constructed, not machine-checked. It does not verify the full Django ORM, backend SQL generation, or database execution. Those are trusted-base boundaries for this FVK run. The proof does verify the branch property that caused the reported SQL literalization failure.

## Test Recommendation

Do not remove tests. Add or keep a regression test outside this task that assigns `F("name")` to a model field and calls `bulk_update()`, then asserts the stored field equals the referenced column value rather than `"F(name)"`. Any future test-redundancy claim would be conditional on successful `kprove` output and broader project test execution.
