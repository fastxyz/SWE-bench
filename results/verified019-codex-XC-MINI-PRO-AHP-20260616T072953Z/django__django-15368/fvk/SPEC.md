# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 change for `django__django-15368`: `QuerySet.bulk_update()` must handle plain `F("...")` values assigned to model instance fields. The formal model covers the value-classification branch inside `bulk_update()` and the downstream update-expression resolution path that determines whether the generated SQL uses a literal parameter or a column reference.

The full Django ORM, database backend SQL compiler, transactions, and model system are outside the mini-semantics trusted base. They are represented only where needed to distinguish the reported failure from the intended behavior.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the issue places plain `F()` assigned to an instance field in the intended input domain for `bulk_update()`.
- E3: the SQL must resolve the `F()` to a column reference rather than storing the literal string representation.
- E4: the public hint says to check `resolve_expression` like elsewhere.
- E5/E6: Django source uses `resolve_expression` as the local expression protocol in expression parsing and update resolution.
- E7: unrelated validation, batching, casting, PK filtering, transaction, and return behavior should remain unchanged.

## Contract

For each object/field value processed by `bulk_update()`:

1. If `attr` has `resolve_expression`, `bulk_update()` must pass it through as the `then` expression of the generated `When`.
2. If `attr` does not have `resolve_expression`, `bulk_update()` must wrap it in `Value(attr, output_field=field)`.
3. The generated `Case` expression must later resolve through the existing update path, so `F("name")` resolves to the model column `name` with `allow_joins=False` and `for_save=True`.
4. The fix must not alter object batching, field batching, PK filtering, validation, related-field preparation, optional backend casting, transaction handling, or row-count accumulation.

## Loop Invariants

`bulk_update()` has nested finite loops over batches, fields, and objects. The formal claims in `bulk-update-spec.k` model the pointwise transfer function used in the innermost loop; the source-level invariants are:

- Batch loop: all completed batches have update kwargs satisfying the contract for every field/object pair in those batches; pending batches are untouched.
- Field loop: all completed fields in the current batch have one `Case` expression whose `When.then` values satisfy the contract for every object in the batch.
- Object loop: after processing the first `k` objects for a field, `when_statements` contains exactly `k` `When` objects, each tied to the corresponding object's primary key and normalized attribute expression.

The V1 edit changes only the object-loop normalization predicate.

## Formal Core

K artifacts:

- `fvk/mini-django-bulk-update.k`
- `fvk/bulk-update-spec.k`

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-django-bulk-update.k --backend haskell
kast --backend haskell fvk/bulk-update-spec.k
kprove fvk/bulk-update-spec.k
```

Expected result if the mini-semantics and claims parse as written: `kprove` discharges the three claims to `#Top`.
