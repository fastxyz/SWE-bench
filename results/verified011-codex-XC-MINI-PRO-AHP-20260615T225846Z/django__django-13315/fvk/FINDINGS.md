# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1 - Direct Join Filtering Duplicates Form Choices

Classification: code bug in the pre-V1 implementation, resolved by V1.

Evidence: `benchmark/PROBLEM.md` states that a `Q` object in
`limit_choices_to` involving a join can render duplicate options.

Concrete model: let the outer ForeignKey choice queryset contain one target row
`A`, and let the join traversed by `limit_choices_to` have two matching related
rows for `A`. Direct filtering behaves like `repeat(A, 2)`, so rendering sees
`[A, A]`. Expected behavior is a single option `[A]` because there is one target
object that satisfies the limit.

V1 status: resolved. The helper now filters the outer queryset with a
correlated `Exists()` condition, which tests whether at least one matching row
exists without joining the outer queryset to every witness.

Related proof obligations: PO-1, PO-2.

## F2 - Duplicate Validation Rows Can Raise MultipleObjectsReturned

Classification: code bug in the pre-V1 implementation, resolved by V1.

Evidence: `benchmark/PROBLEM.md` says the issue "blows up when .get() is called
on the queryset if you select one of the duplicates
(MultipleObjectsReturned)."

Concrete model: after direct filtering produces `[A, A]`, validating submitted
primary key `A.pk` calls `.get(pk=A.pk)` on a queryset with two matching rows.
Expected behavior is one matching model object, because the duplicate rows came
from limit-join witnesses rather than from distinct target objects.

V1 status: resolved. The same de-duplicated-by-existence queryset is used by
`ModelChoiceField.to_python()`, so the limit condition no longer creates more
than one row for `A.pk`.

Related proof obligations: PO-3.

## F3 - DISTINCT-Based Deduplication Is an Invalid Repair Strategy

Classification: rejected alternative, resolved by V1.

Evidence: the public issue history records that a previous distinct-based fix
was reverted because `distinct` caused database errors with custom model fields
whose selected values could not be compared.

Concrete model: a target model contains a custom database field such as the
copied PostgreSQL `point` example. A row-wide `DISTINCT` over all selected
columns asks the database to compare values it may not support comparing.
Expected behavior is to avoid duplicate choices without requiring such
comparisons.

V1 status: resolved. The patch adds `EXISTS(...)` to the outer queryset and
does not call `.distinct()`.

Related proof obligations: PO-4.

## F4 - Existing Duplicate Outer Querysets Are Outside This Issue's Intent

Classification: residual scope boundary, not a V1 bug.

Evidence: the issue localizes the cause to `limit_choices_to` involving a join.
The standard `ForeignKey.formfield()` path starts from the related model's
default manager queryset, not from an intentionally duplicated custom queryset.

Concrete model: if a caller supplies an already duplicated queryset `[A, A]`
before `limit_choices_to` is applied, V1 preserves those outer duplicates.
Expected behavior under this issue is only that applying the limit must not add
duplicates; broad deduplication of arbitrary custom querysets would be a separate
behavior change.

V1 status: accepted unchanged. The proof obligations require no new duplicates
from the limit join when the outer queryset is unique.

Related proof obligations: PO-1, PO-2.

## F5 - Full Django ORM Semantics Are Not Machine-Checked Here

Classification: proof capability gap / honesty gate.

Evidence: the task forbids running Python or K tooling and the FVK MVP is
constructed, not machine-checked.

Concrete model: the artifacts prove a small relational abstraction of
`complex_filter` versus `Exists`, not a full Django SQL compiler semantics.
Expected behavior is to label this honestly and keep tests rather than claiming
machine-checked confidence.

V1 status: accepted. This does not identify a source change; it limits the proof
confidence and test-removal recommendations.

Related proof obligations: PO-6.

## Proof-Derived Findings From `/verify`

No proof-derived code bug was found in V1. The only open item is F5: the proof
is constructed over a property-complete abstraction and must be treated as
not machine-checked until the emitted commands are run in an environment with K.
