# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

Target source: `repo/django/db/models/aggregates.py`.

The V1 candidate changed only the class-level `allow_distinct` attributes for
`Avg` and `Sum`. This FVK pass audits whether that change satisfies the public
issue intent and whether the source should be revised further.

Formal core files:

- `fvk/mini-django-aggregate.k`
- `fvk/django-aggregate-spec.k`

## Intent-Only Spec

I1. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Add DISTINCT support for Avg and Sum aggregates."

Semantic obligation: `Avg(..., distinct=True)` and `Sum(..., distinct=True)`
are in-domain public API calls and must not fail solely because `distinct=True`
was supplied.

Status: encoded by claims `init(Avg, true) => Obj(true)` and
`init(Sum, true) => Obj(true)`.

I2. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Before 2.2, these aggregations just ignored the parameter,
but now throw an exception."

Semantic obligation: the defect is the new exception on `distinct=True` for the
named aggregates. The fix must remove that exception path for `Avg` and `Sum`.

Status: encoded by proof obligations PO-1 and PO-2.

I3. Source: `repo/docs/ref/models/expressions.txt`.

Quoted evidence: the `Aggregate` API documents that `distinct` invokes the
aggregate for each distinct value when the aggregate has `allow_distinct` set to
`True`.

Semantic obligation: after construction succeeds with `distinct=True`, SQL
generation must carry the existing `DISTINCT ` prefix through the aggregate
template.

Status: encoded by claims over `asSql("AVG", true, E)` and
`asSql("SUM", true, E)`.

I4. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "could also be applied to Min and Max (although pointless)."

Semantic obligation: this is optional public evidence, not a required behavior.
It identifies a possible extension while the issue title and concrete repair
language require `Avg` and `Sum`.

Status: encoded as a frame condition: V1 may leave `Min` and `Max` inheriting
the default rejection behavior.

## Implementation Evidence

E1. `Aggregate.__init__()` rejects `distinct=True` only when
`self.allow_distinct` is false (`repo/django/db/models/aggregates.py`, lines
24-28).

E2. `Aggregate.as_sql()` writes `extra_context['distinct'] = 'DISTINCT '` when
`self.distinct` is true, otherwise the empty string (`aggregates.py`, lines
70-72). The same `extra_context` is passed into both the filter and non-filter
SQL rendering paths (`aggregates.py`, lines 72-88).

E3. `Avg` now defines `allow_distinct = True` (`aggregates.py`, lines 99-102).

E4. `Sum` now defines `allow_distinct = True` (`aggregates.py`, lines 143-146).

E5. `Count` already allowed distinct and its behavior is unchanged. `Max` and
`Min` still inherit the default `allow_distinct = False`.

## Formal English Paraphrase

F1. Constructing an `Avg` aggregate with `distinct=True` produces an aggregate
object whose distinct flag is true rather than a `TypeError`.

F2. Constructing a `Sum` aggregate with `distinct=True` produces an aggregate
object whose distinct flag is true rather than a `TypeError`.

F3. Rendering SQL for a distinct `AVG` aggregate produces an `AVG(DISTINCT
...)` aggregate call.

F4. Rendering SQL for a distinct `SUM` aggregate produces a `SUM(DISTINCT
...)` aggregate call.

F5. `Min` and `Max` are not required by the public issue to accept
`distinct=True`; leaving them unchanged is within the audited scope.

## Adequacy Audit

F1 and F2 pass: they are directly entailed by I1 and I2.

F3 and F4 pass: they combine I3 with existing implementation evidence E2. The
V1 edit does not add a new SQL path; it unlocks the already documented distinct
path for the intended aggregate classes.

F5 passes as a scoped frame condition: I4 says the change "could" be applied to
`Min` and `Max`, and describes it as pointless. That is not a mandatory
postcondition.

## Public Compatibility Audit

No public function or method signature changes. `Aggregate.__init__()` already
accepted `distinct=False` as a keyword argument. The V1 edit changes only class
attributes on two concrete aggregate subclasses.

Existing `distinct=False` behavior is unchanged for every aggregate class.
Existing `distinct=True` support on `Count` is unchanged. Existing rejection of
`distinct=True` for subclasses that do not opt in is unchanged.
