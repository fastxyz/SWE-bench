# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Proof Summary

The V1 fix satisfies the intended contract. For a trimmed `ForeignKey`
selection, Django represents the selected column as a `Col` whose `target` is
the relation field (`C.owner`) and whose `field`/`output_field` is the concrete
remote field (`User.id`). Returning `.target` from `Query.output_field` makes
`Subquery._resolve_output_field()` expose the relation field to the outer
lookup. The exact lookup then uses `RelatedExact`, which normalizes a lazy model
instance to its target-field value before concrete field preparation.

## Constructed Proof

1. `names_to_path()` identifies a relation field's `final_field` separately
   from its concrete target fields. `trim_joins()` can trim a direct
   `ForeignKey` join back to the local relation column.

2. `add_fields()` and related selection paths store selected fields as `Col`
   instances. For `values("owner")` after join trimming, the relevant shape is
   `Col(target=C.owner, output_field=User.id)`.

3. `Expression.field` is an alias for `output_field`. Therefore the pre-fix
   `Query.output_field == self.select[0].field` selected `User.id`, which is
   the concrete integer field in the reported failure.

4. V1 changes that step to `self.select[0].target`. By PO-001, the same query
   now exposes `C.owner`.

5. `Subquery._resolve_output_field()` returns `self.query.output_field`. By
   PO-002, the relation field result from step 4 propagates through nested
   `Subquery()` annotations.

6. `ForeignObject` registers `RelatedExact`, and a relation output field
   dispatches exact lookup preparation through `RelatedLookupMixin`. By PO-003,
   `SimpleLazyObject(lambda: User(...))` is normalized to the wrapped user's
   target-field value before `User.id.get_prep_value()` is called.

7. The reported `int(SimpleLazyObject(...))` path is therefore unreachable for
   the in-domain issue shape after V1. The expected SQL parameter preparation
   receives the user's primary-key value instead.

8. By PO-004, selected non-relational columns with `target == output_field` are
   unchanged, and annotation-only output-field resolution is unchanged.

## Residual Risk

The proof is source-level and constructed only. It relies on the adequacy of
the mini model in `fvk/mini-django-query.k` and on the source inspection that
`Query.select` entries in the single-selected-column branch are `Col`-like.

No termination argument is needed for the audited property because the changed
unit is a property accessor and the modeled lookup-preparation path has no loop.

No test-removal recommendation is made. Existing and hidden tests should be
kept unless the K claims are later machine-checked and a separate public test
mapping is performed.

## Machine-Check Commands

These commands are recorded for a later environment and were not executed:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-output-field-spec.k
kprove fvk/query-output-field-spec.k
```
