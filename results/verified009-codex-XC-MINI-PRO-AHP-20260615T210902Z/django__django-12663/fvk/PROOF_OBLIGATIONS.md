# FVK Proof Obligations

Status: constructed, not machine-checked. The commands listed here are not run.

## PO-001: Single selected `Col` exposes `target`

Claim: If `query.select == (Col(target=FK, output_field=PK),)` and
`query.annotation_select` is empty or irrelevant, then `query.output_field ==
FK`.

Intent: INT-003, E-004.

Source support:

- `Expression.field` returns `self.output_field`.
- `Col.__init__()` stores `self.alias, self.target = alias, target`.
- `Query.output_field` currently returns `self.select[0].target`.

Counterexample for the pre-fix code: with `Col(target=C.owner,
output_field=User.id)`, `self.select[0].field` evaluates to `User.id`, which
does not have related lookup semantics for a model RHS.

Constructed K claim: `QUERY-OUTPUT-FIELD-TARGET` in
`fvk/query-output-field-spec.k`.

## PO-002: `Subquery` delegates output-field resolution to `Query`

Claim: `Subquery(query)._resolve_output_field() == query.output_field`.

Intent: INT-001, E-006.

Source support: `Subquery._resolve_output_field()` returns
`self.query.output_field`.

Consequence: PO-001 lifts through each nested `Subquery()` layer in the issue
shape. If the innermost `values("owner")` query exposes `C.owner`, the outer
annotation also exposes `C.owner`.

Constructed K claim: `SUBQUERY-DELEGATES` in `fvk/query-output-field-spec.k`.

## PO-003: Related exact lookup normalizes lazy model RHS values

Claim: If an exact lookup's LHS output field is a `ForeignKey` and the RHS is a
`SimpleLazyObject` wrapping an instance of the related model, preparation
returns the wrapped model's target-field value instead of passing the lazy
object to the concrete target field's `get_prep_value()`.

Intent: INT-001, INT-002, E-003, E-007.

Source support:

- `ForeignObject.register_lookup(RelatedExact)` registers the relation-aware
  exact lookup.
- `RelatedLookupMixin.get_prep_lookup()` calls
  `get_normalized_value(self.rhs, self.lhs)[0]` before target-field preparation.
- `LazyObject.__class__` proxies the wrapped object's class, and attribute
  access proxies to the wrapped object, allowing model-instance normalization.

Constructed K claim: `RELATED-EXACT-NORMALIZES-LAZY` in
`fvk/query-output-field-spec.k`.

## PO-004: Frame conditions for unaffected output-field cases

Claim: If a selected `Col` has `target == output_field`, then returning
`.target` is equivalent to returning `.field`. If `len(select) != 1` and
`len(annotation_select) == 1`, `Query.output_field` remains the selected
annotation's output field.

Intent: INT-004.

Source support: the V1 edit changes only the selected-column return expression
and leaves the annotation branch unchanged.

Constructed K claims: `SAME-TARGET-FIELD-FRAME` and
`ANNOTATION-ONLY-FRAME` in `fvk/query-output-field-spec.k`.

## PO-005: Process and verification honesty

Claim: The audit may confirm source-level correctness only as constructed,
not machine-checked. It must not claim test results, hidden evaluator behavior,
or safe test deletion.

Intent: task no-execution rule; FVK honesty gate.

Status: discharged by not running tests, Python, `kompile`, `kast`, or
`kprove`, and by labeling artifacts accordingly.

## Commands to Machine-Check Later

Do not run these in this benchmark session:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-output-field-spec.k
kprove fvk/query-output-field-spec.k
```
