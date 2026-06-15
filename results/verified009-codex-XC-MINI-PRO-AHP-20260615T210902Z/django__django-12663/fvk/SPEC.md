# FVK Specification for django__django-12663

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited production change is the current V1 edit in
`repo/django/db/models/sql/query.py`: `Query.output_field` returns
`self.select[0].target` when a query has exactly one selected column.

The specification covers the observable behavior reported in the public issue:
a nested `Subquery()` annotation whose selected value is a `ForeignKey`, filtered
with a `SimpleLazyObject` wrapping a model instance.

## Intent Spec

`INT-001`: A queryset using a nested subquery annotation must accept a
`SimpleLazyObject` model instance on the RHS of an exact filter without raising
`TypeError`.

`INT-002`: The behavior is a regression. The intended behavior is the existing
related-field lookup conversion used by patterns such as
`filter(user=request.user)`, where `request.user` can be lazy.

`INT-003`: For a single selected `Col`, the subquery output field must preserve
the selected column's relation field, not the concrete target field that causes
plain integer preparation.

`INT-004`: The fix must be minimal and must not change annotation-only subquery
output-field resolution, multi-select behavior, public call signatures, or test
files.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "Using SimpleLazyObject with a nested subquery annotation fails." | Nested subquery annotation + lazy model RHS is in domain. | Encoded by PO-001 through PO-003. |
| E-002 | `benchmark/PROBLEM.md` | traceback ends in `int(value)` on `SimpleLazyObject` | Plain concrete-field preparation is the observed bad path. | Recorded as F-001. |
| E-003 | `benchmark/PROBLEM.md` | "Prior to ... it was possible to use a SimpleLazyObject in a queryset" | Preserve related lookup conversion for lazy model instances. | Encoded by PO-003. |
| E-004 | public hint in `benchmark/PROBLEM.md` | "`Col.field` is actually ... `.output_field` ... it's the `Col.target` that should be used as output_field" | `Query.output_field` for a single selected `Col` should return `.target`. | Encoded by PO-001. |
| E-005 | source code | `Expression.field` returns `self.output_field`; `Col` stores separate `target` and `output_field`. | The proof model must distinguish `Col.target` from `Col.field`. | Encoded by PO-001. |
| E-006 | source code | `Subquery._resolve_output_field()` returns `self.query.output_field`. | Correctness of nested subquery annotations depends on `Query.output_field`. | Encoded by PO-002. |
| E-007 | source code | `ForeignObject.register_lookup(RelatedExact)` and `RelatedLookupMixin.get_prep_lookup()` normalize model RHS values. | A relation output field must select the related exact lookup path. | Encoded by PO-003. |

## Formal Spec English

`C-001`: For a query with one selected column represented as
`Col(target=C.owner, output_field=User.id)`, `Query.output_field` returns
`C.owner`.

`C-002`: For `Subquery(query)`, the subquery output field is exactly
`query.output_field`. Therefore a subquery over `values("owner")` exposes
`C.owner`, not `User.id`.

`C-003`: If an exact lookup's LHS output field is a relation field and the RHS
is a lazy object wrapping a model instance of the related model, lookup
preparation normalizes the RHS to the wrapped model's target-field value.

`C-004`: If a selected column has `target == output_field`, changing
`Query.output_field` from `.field` to `.target` is observationally identical.
If the query has no single selected column and exactly one selected annotation,
the existing annotation branch remains the output-field source.

## Adequacy Audit

`C-001` passes. It directly encodes INT-003 and E-004, and it contradicts the
buggy pre-fix behavior recorded in E-002.

`C-002` passes. It is required by E-006 and explains why the one-line
`Query.output_field` change reaches nested `Subquery()` annotations.

`C-003` passes. It encodes INT-001 and INT-002 using the existing related
lookup path from E-007.

`C-004` passes. It is the frame condition required by INT-004.

No claim depends on hidden tests, external benchmark results, or legacy behavior
reported as buggy.

## Public Compatibility Audit

`Query.output_field` remains a property with the same call shape. No public
method signature, virtual dispatch call, argument list, storage format, or
test file changed.

The only intended return-value change is for single selected `Col` instances
where `.target` and `.field` differ. Public evidence E-004 identifies this as
the required compatibility restoration for related-field subquery output.

No additional source compatibility changes are required.
