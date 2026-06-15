# FVK Specification: django__django-13028

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Scope

The verified unit is `Query.check_filterable()` in
`repo/django/db/models/sql/query.py`, plus its call from `build_filter()` after
RHS lookup values are resolved. The proof abstracts Django objects by the
protocol facts that matter for this issue:

- whether the value exposes `resolve_expression`;
- whether its internal expression flag `filterable` is true or false;
- whether a real expression exposes nested source expressions;
- whether recursive source-expression validation succeeds.

The model intentionally does not prove SQL generation, relation type checking,
or database backend behavior. Those remain integration behavior outside this
unit proof.

## Intent Specification

I-01. An ordinary RHS lookup value must not be rejected merely because it has an
application attribute or model field named `filterable` with value `False`.

I-02. The internal `filterable = False` contract must still reject real ORM
expressions from `WHERE` clauses.

I-03. Source-expression recursion is part of expression validation and must
continue to reject a real expression whose nested source expression is not
filterable.

I-04. The fix must preserve public API shape: no method signature changes and no
test-file edits.

## Public Evidence Ledger

E-01. Source: `benchmark/PROBLEM.md`.
Quoted evidence: "Queryset raises NotSupportedError when RHS has
filterable=False attribute."
Obligation: ordinary RHS values with a user-defined `filterable` attribute are
valid lookup data and must not trigger the expression filterability error.
Status: encoded by PO-01 and claim `NON-EXPRESSION-RHS`.

E-02. Source: `benchmark/PROBLEM.md`.
Quoted evidence: `ProductMetaData.objects.filter(...,
metadata_type=self.brand_metadata)` followed by `NotSupportedError:
ProductMetaDataType is disallowed in the filter clause.`
Obligation: a related model instance used as RHS for a foreign key equality
lookup is in domain for normal lookup validation.
Status: encoded by PO-04.

E-03. Source: public hint in `benchmark/PROBLEM.md`.
Quoted evidence: "We should be able to fix this by checking if rhs is an
expression."
Obligation: `resolve_expression` is the expression-protocol discriminator for
the guard.
Status: encoded by PO-01, PO-02, and V2 code.

E-04. Source: `repo/django/db/models/expressions.py`.
Quoted evidence: `BaseExpression` defines `filterable = True` and
`resolve_expression()`, while `Window` defines `filterable = False`.
Obligation: real ORM expressions retain the internal filterability contract.
Status: encoded by PO-02 and PO-03.

E-05. Source: implementation pattern in
`repo/django/db/models/sql/query.py` and nearby ORM code.
Quoted evidence: `resolve_lookup_value()` and other ORM paths use
`hasattr(value, 'resolve_expression')` to decide expression participation.
Obligation: non-expression RHS values should not be walked as expression
containers.
Status: encoded by PO-01 and finding F-02.

## Formal Model

The companion K files are:

- `fvk/mini-django-query.k`: a small abstract semantics for
  `check_filterable()`.
- `fvk/query-filterable-spec.k`: reachability claims for the obligations below.

The core abstract object is:

`obj(HAS_RESOLVE, FILTERABLE, HAS_SOURCES, SOURCES)`

where `HAS_RESOLVE` represents `hasattr(value, 'resolve_expression')`.

## Required Claims

`NON-EXPRESSION-RHS`: for every object with `HAS_RESOLVE == false`,
`checkFilterable()` returns `ok`, regardless of `FILTERABLE`,
`HAS_SOURCES`, or `SOURCES`.

`NON-FILTERABLE-EXPRESSION`: for every object with `HAS_RESOLVE == true` and
`FILTERABLE == false`, `checkFilterable()` returns `notSupported`.

`FILTERABLE-EXPRESSION-NO-SOURCES`: a filterable expression with no source
walk completes with `ok`.

`FILTERABLE-EXPRESSION-SOURCES`: a filterable expression with sources validates
each source in order using the same `checkFilterable()` contract and returns
the first `notSupported` result if any source is rejected.

## Adequacy Audit

The formal claims match the intent:

- I-01 passes because `NON-EXPRESSION-RHS` ignores `filterable` when
  `HAS_RESOLVE == false`.
- I-02 passes because `NON-FILTERABLE-EXPRESSION` still rejects real
  non-filterable expressions.
- I-03 passes because `FILTERABLE-EXPRESSION-SOURCES` keeps recursive source
  validation, but only after the parent is known to be an expression.
- I-04 passes because V2 changes only the body of `check_filterable()` and does
  not alter public signatures or tests.

## Compatibility Audit

Changed public symbol: none. The method name and signature remain
`check_filterable(self, expression)`.

Changed behavior: a non-expression RHS is no longer inspected for expression
protocol fields or source expressions. This is the intended compatibility
restoration for application values that define attributes named like Django's
internal expression API.

Public callers inspected: `build_filter()` calls `check_filterable()` on a
referenced annotation expression and on the resolved RHS value. The refined
early return is compatible with both paths because annotation expressions expose
`resolve_expression`, while ordinary RHS values do not.

No tests were modified.
