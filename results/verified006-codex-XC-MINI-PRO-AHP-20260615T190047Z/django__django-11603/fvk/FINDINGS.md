# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations only.

## F-001: Avg Distinct Exception Is Resolved

Input: `Avg("field", distinct=True)`.

Observed before V1: `Aggregate.__init__()` would raise `TypeError` because
`Avg` inherited `allow_distinct = False`.

Expected from public intent: construction succeeds and preserves
`self.distinct = True`.

V1 evidence: `Avg` now sets `allow_distinct = True`.

Linked proof obligation: PO-1.

Classification: code bug fixed by V1.

Recommendation: keep V1 unchanged for `Avg`.

## F-002: Sum Distinct Exception Is Resolved

Input: `Sum("field", distinct=True)`.

Observed before V1: `Aggregate.__init__()` would raise `TypeError` because
`Sum` inherited `allow_distinct = False`.

Expected from public intent: construction succeeds and preserves
`self.distinct = True`.

V1 evidence: `Sum` now sets `allow_distinct = True`.

Linked proof obligation: PO-2.

Classification: code bug fixed by V1.

Recommendation: keep V1 unchanged for `Sum`.

## F-003: SQL Distinct Propagation Was Already Present

Input: a successfully constructed distinct `Avg` or `Sum` aggregate.

Observed source behavior: `Aggregate.as_sql()` sets the `distinct` template
context to `DISTINCT ` whenever `self.distinct` is true.

Expected from public intent: SQL generation invokes the aggregate over distinct
values.

V1 evidence: once `Avg` and `Sum` can be constructed with `self.distinct =
True`, the existing SQL rendering path provides the required prefix for both
filter and non-filter paths.

Linked proof obligation: PO-3.

Classification: no additional code bug.

Recommendation: no source edit beyond the class attributes.

## F-004: Min and Max Are Optional, Not Required

Input: `Min("field", distinct=True)` or `Max("field", distinct=True)`.

Observed V1 behavior: both still reject `distinct=True` through the inherited
default `allow_distinct = False`.

Expected from public intent: no mandatory requirement. The issue says the same
setting "could also be applied" to `Min` and `Max`, but calls it pointless.

Linked proof obligations: PO-4 and PO-5.

Classification: scoped non-change, not a code bug.

Recommendation: leave `Min` and `Max` unchanged unless a separate public
requirement asks for that optional extension.

## F-005: Proof Is Constructed, Not Machine-Checked

Input: the FVK proof artifacts.

Observed: the benchmark forbids running K tooling, and no execution environment
exists.

Expected: commands are written into `PROOF.md` for later execution, with the
result labeled constructed and not machine-checked.

Linked proof obligation: PO-6.

Classification: verification process limitation, not a source-code bug.

Recommendation: keep tests until the emitted K commands can be run and return
`#Top`.
