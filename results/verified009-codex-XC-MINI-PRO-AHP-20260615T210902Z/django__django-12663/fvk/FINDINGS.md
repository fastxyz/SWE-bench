# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent
and source inspection only.

## F-001: Wrong output field for selected ForeignKey subqueries

Classification: code bug resolved by V1.

Input shape: `Subquery(C.objects.values("owner"))` nested inside another
subquery annotation, then filtered with `owner_user=SimpleLazyObject(lambda:
User(...))`.

Observed before V1: `Query.output_field` returned `Col.field`, an alias for
`Col.output_field`. For a trimmed `ForeignKey` selection this is the concrete
remote field, e.g. `User.id`. The exact lookup therefore used plain concrete
field preparation and attempted `int(SimpleLazyObject(...))`, matching the
issue traceback.

Expected: the subquery exposes the relation field (`C.owner`) so the exact
lookup uses `RelatedExact` and normalizes the lazy wrapped model to its target
field value.

Evidence: E-001 through E-007 in `fvk/SPEC.md`.

Proof obligations: PO-001, PO-002, PO-003.

Status: resolved by the V1 source change.

## F-002: `Query.select` target availability assumption is discharged

Classification: audit finding, no code change required.

Potential concern: changing `.field` to `.target` would be unsafe if
`Query.select` entries in this branch were arbitrary expressions without a
`target`.

Observed source facts: `Query.add_fields()` fills `select` from
`join_info.transform_function(target, final_alias)`, `Query._get_col()` returns
`target.get_col(alias, field)`, `Field.get_col()` returns a `Col`, and nearby
query code already reads `query.select[0].target`.

Expected: the single-selected-column branch can use `.target`.

Proof obligations: PO-001 and PO-004.

Status: discharged by source inspection; no V2 code change required.

## F-003: Annotation-only and same-field selected-column behavior remains framed

Classification: compatibility finding, no code change required.

Input shape: a query with no single selected column but exactly one selected
annotation, or a selected non-relational column where `Col.target ==
Col.output_field`.

Observed after V1: the annotation-only branch is unchanged. For selected
columns whose `target` and `field` are the same object, returning `.target`
equals the previous `.field` result.

Expected: no unrelated output-field behavior changes.

Proof obligation: PO-004.

Status: discharged.

## F-004: Proof and test recommendations are not machine-checked

Classification: proof capability and process limitation.

Observed: the task forbids running tests, Python, or K tooling.

Expected: proof artifacts must be labeled constructed, not machine-checked; no
test deletion or hidden-test inference is justified.

Proof obligation: PO-005.

Status: open process limitation, not a source-code bug.
