# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent and source inspection only.

## F-001: Legacy multi-hop FK attname ordering expanded related default ordering

Input:
`TwoModel.objects.filter(record__oneval__in=[1,2,3]).order_by("record__root_id")`
where `root` is a self-referential `ForeignKey` and `OneModel.Meta.ordering =
("-id",)`.

Observed before V1:
The compiler compared `field.attname == "root_id"` with the whole lookup name
`"record__root_id"`, found them unequal, and entered the related-default-ordering
branch. The issue's SQL shows the symptom as an unnecessary self-join and
`ORDER BY T3."id" DESC`.

Expected:
`record__root_id` names the FK attname at the final lookup segment, so the
compiler should skip related default ordering, trim the final direct join, and
order by the concrete `root_id` column reached through `record`.

Classification:
code bug, resolved by V1. Traces to SPEC E-001, E-002, E-005 and proof
obligations PO-001 through PO-004.

## F-002: Direction inversion was a consequence of the wrong expansion path

Input:
`order_by("-record__root_id")` for the same model shape.

Observed before V1:
The issue shows the compiler expanding through the related model ordering and
producing `ORDER BY T3."id" ASC`, because `get_order_dir()` inverts the related
model's `-id` under the caller's descending default order.

Expected:
The lookup is an FK attname lookup, so direction applies directly to the FK
column: `record__root_id` ascending by default and `-record__root_id`
descending.

Classification:
code bug, resolved by the same V1 condition. Traces to SPEC INT-004 and
obligations PO-002 through PO-004.

## F-003: Relation-name ordering must remain expanded

Input:
`order_by("record__root")`.

Observed after V1 by source reasoning:
The final piece is `root`, while the field attname is `root_id`, so the V1
predicate still enters the related-default-ordering branch.

Expected:
The issue explicitly says `order_by('record__root') should use
OneModel.Meta.ordering`, and the queryset docs say relation-name ordering uses
related model default ordering.

Classification:
compatibility obligation satisfied by V1. Traces to SPEC E-003/E-004 and
obligation PO-005.

## F-004: Existing one-hop FK attname behavior remains preserved

Input:
`Article.objects.order_by("author_id")`.

Observed after V1 by source reasoning:
For a one-segment lookup, `pieces[-1] == name == "author_id"`, so the predicate
has the same truth value as the pre-V1 implementation.

Expected:
The public ordering test documents that ordering by a FK attname prevents
inheriting the related model's ordering.

Classification:
frame condition satisfied by V1. Traces to SPEC E-006 and obligation PO-006.

## F-005: No new API or dispatch compatibility issue was introduced

Input:
Internal calls to `SQLCompiler.find_ordering_name()`.

Observed after V1 by source reasoning:
No function signature, argument passing, return shape, or recursion guard
changed. Only the comparison operand inside the existing predicate changed.

Expected:
The fix should be local to ordering semantics and not require caller or
subclass changes.

Classification:
compatibility check passed. Traces to SPEC compatibility audit and PO-008.

## Residual Findings

R-001: The proof is constructed, not machine-checked. Exact `kompile`, `kast`,
and `kprove` commands are listed in `fvk/PROOF.md`; they were intentionally not
run.

R-002: The formal core abstracts the full Django SQL compiler to the
ordering-classification predicate plus source-level reasoning for
`trim_joins()`. This is adequate for the reported bug because the defect is the
classification predicate, but full SQL rendering would require a separate,
larger compiler proof and remains covered by tests, not by this abstract proof
alone.
