# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Code decision

I revised V1 in `repo/django/db/models/sql/compiler.py` by moving the
empty-query guard from `get_combinator_sql()` to `SQLCompiler.as_sql()`, before
the combined-query backend support check.

Reason: `fvk/FINDINGS.md` F-02 showed that V1 only proved the empty combined
query avoided operand SQL assembly after the backend had already accepted the
combinator. That was weaker than the documented `none()` contract. The V2 guard
discharges `fvk/PROOF_OBLIGATIONS.md` PO-03 and PO-04: if `query.is_empty()` is
true, compilation raises `EmptyResultSet`, and existing `execute_sql()` handling
returns no rows without opening a cursor.

F-01 remains the root-cause finding: combined SQL generation must not ignore the
outer empty marker. V2 still resolves it, now at the broader `as_sql()` entry
point.

## Decisions not to change

I did not change `ModelMultipleChoiceField` or admin/form code. F-03 localizes
the form path as a consumer of the ORM contract, not the defect. PO-05 is
discharged by the compiler fix because the field already returns
`self.queryset.none()` for optional empty input.

I did not change `Query.set_empty()` to clear `query.combinator` or
`query.combined_queries`. F-04 records that public evidence requires empty
result access and no query execution, but does not require changing the
operation-support matrix after `union().none()`. PO-07 also favors avoiding a
broader public-behavior change without clear intent evidence.

I did not edit tests. F-05 and PO-08 require all proof and test-redundancy
claims to remain conditioned on later machine checking, and the benchmark
instructions prohibit test edits.

## Artifact decisions

I wrote the five requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote `fvk/mini-django-query.k` and
`fvk/django-query-none-spec.k`. The FVK documentation says a Markdown-only run
is invalid, so these files provide the constructed mini-semantics and claims
referenced by PO-01 through PO-06.

## Residual risk

The proof is constructed, not machine-checked. The mini-K model abstracts the
full Django ORM to the state needed for this issue: the empty marker,
combinator flag, backend support branch, combined SQL assembly, and
`execute_sql()` no-results handling. That abstraction is sufficient for F-01
and F-02 because it distinguishes the failing `sql(...)` path from the passing
`emptyResult` path, but broader ORM behavior remains covered by Django's normal
test suite rather than this proof.
