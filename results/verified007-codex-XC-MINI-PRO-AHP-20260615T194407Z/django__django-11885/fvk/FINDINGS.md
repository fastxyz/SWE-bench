# FVK Findings

Status: constructed, not machine-checked.

## F-1: V1 Addresses the Reported Redundant Fast Deletes

Input scenario: A deleted object has two fast-delete cascade paths to the same
related model/table, such as `Entry.created_by` and `Entry.updated_by`, with a
backend parameter budget large enough for both predicates.

Observed in V1: The first queryset-like entry is retained in `fast_deletes`; the
second same-model queryset is combined into it using `fast_delete | qs`.

Expected by intent: One related-table DELETE with `created_by OR updated_by`.

Trace: PO-1 and PO-5.

Classification: confirm V1 behavior; no source change required.

## F-2: Self-M2M Through-Table Case Is Covered

Input scenario: Deleting `Person` creates fast-delete querysets for a
self-referential many-to-many through table, one for `from_id` and one for
`to_id`.

Observed in V1: Both querysets have the same through model, so the second is
combined with the first when parameter counts fit.

Expected by intent: `DELETE FROM person_friends WHERE from_id = :id OR to_id = :id`.

Trace: PO-1 and `fast-delete-spec.k` claim 2.

Classification: confirm V1 behavior; no source change required.

## F-3: Parameter Guard Is a Required Safety Condition

Input scenario: Same-model fast-delete relation batches have known parameter
counts whose sum exceeds a backend's `max_query_params`, or one side has unknown
parameter count on a limited backend.

Observed in V1: The helper skips combination and appends a separate entry.

Expected by safety frame: Existing batching behavior must not be bypassed by
constructing an oversized OR query.

Trace: PO-3.

Classification: confirm V1 behavior; no source change required.

## F-4: "By Table" Does Not Force a Distinct-Model SQL Combiner

Input scenario: Two distinct Django model classes hypothetically share one
physical database table and both produce fast-delete querysets.

Observed in V1: They are not combined because `QuerySet.__or__` combines
same-model querysets, and V1 checks `fast_delete.model != qs.model`.

Expected by audited intent: The public issue examples and collector call sites
use ordinary model-owned related tables. No allowed public evidence requires a
new lower-level SQL combiner across distinct model classes sharing a table.

Trace: PO-2 and SPEC audit.

Classification: non-blocking ambiguity rejected as outside the public intent
slice; no source change required.

## F-5: Proof Is Constructed, Not Machine-Checked

Input scenario: A future maintainer wants to delete tests or claim K-verified
correctness.

Observed in this session: The K commands were recorded but not executed, per the
task instructions.

Expected by FVK honesty gate: Do not remove tests or claim machine-checked proof
until `kprove` returns `#Top`.

Trace: all proof obligations.

Classification: residual proof-process risk, not a source-code defect.
