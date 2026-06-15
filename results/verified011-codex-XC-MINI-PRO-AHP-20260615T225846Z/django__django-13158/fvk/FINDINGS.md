# FVK Findings

Status: constructed, not machine-checked. Findings come from public intent,
source inspection, and proof construction only.

## F-01: Combined SQL assembly ignored the outer empty marker

Input: a queryset `Q = union(A, B)` followed by `Q.none()`.

Observed before the repair: `QuerySet.none()` added a `NothingNode` to the outer
query, but combined SQL generation assembled SQL from `query.combined_queries`.
The outer empty marker was not checked on that path, so the query could evaluate
to the original union operands.

Expected: per E1, E2, and E3, `Q.none()` must never return objects and must use
the no-results path.

Classification: code bug.

Status: resolved. V1 fixed the main combined SQL assembly path; V2 generalizes
the guard to `SQLCompiler.as_sql()` so the empty marker is honored before any
combined-query support check or operand SQL assembly.

Proof obligations: PO-01, PO-02, PO-03, PO-04.

## F-02: V1 placed the empty guard too late for the full documented contract

Input: an empty combined queryset on a backend where the combinator support flag
is false.

Observed in V1 by source inspection: `as_sql()` checked
`supports_select_<combinator>` before calling `get_combinator_sql()`, so the V1
guard inside `get_combinator_sql()` would not run first. The result could be
`NotSupportedError` rather than the documented empty-query no-results behavior.

Expected: per E3, a `none()` queryset should not execute or require the original
query's SQL path. Its emptiness is independent of whether the original combined
query would have been executable on the backend.

Classification: V1 proof obstacle and code robustness bug.

Status: resolved in V2 by moving the guard to `SQLCompiler.as_sql()` immediately
after setup and before the combinator feature check.

Proof obligations: PO-03, PO-04, PO-06.

## F-03: Form/admin code is not the root cause

Input: optional `ModelMultipleChoiceField` with an empty submitted value and a
combined field queryset.

Observed: `ModelMultipleChoiceField.clean()` already returns
`self.queryset.none()` for this case. The form layer is relying on the ORM empty
queryset contract described in the docs.

Expected: no form-specific workaround. The ORM should make the returned queryset
empty for all query shapes.

Classification: localization finding.

Status: no code change in forms. The compiler fix discharges the form path
through PO-05.

Proof obligations: PO-05.

## F-04: Clearing combined-query state is not required by the proven intent

Input: `union_queryset.none()` followed by further queryset-transforming calls
such as `filter()`.

Observed: the query still has `query.combinator` set after `.none()`, so Django's
existing "operation not supported after combined queries" checks may still
apply.

Expected by public evidence: the issue and docs require empty result behavior
and no query execution when results are accessed. They do not explicitly require
that `.none()` erase all combined-query metadata or change the operation support
matrix after `union()`.

Classification: audited ambiguity, not a code bug for this task.

Status: no code change. Do not use this point to weaken PO-01 through PO-04; it
is outside the proven result-access contract.

Proof obligations: PO-01, PO-07.

## F-05: Proof and test-redundancy claims are not machine-checked

Input: all formal claims in `fvk/django-query-none-spec.k`.

Observed: K tooling was not run, by task constraint.

Expected: artifacts must label proofs as constructed, not machine-checked, and
must not delete or modify tests.

Classification: proof honesty gate.

Status: open operational caveat, not a code bug.

Proof obligations: PO-08.
