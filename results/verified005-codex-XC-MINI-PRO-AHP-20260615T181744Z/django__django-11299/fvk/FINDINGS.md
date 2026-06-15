# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Pre-V1 recursive `Q` compilation violated schema-predicate intent

Classification: code bug, fixed by V1.

Input: a check constraint equivalent to
`Q(field_1__isnull=False, flag__exact=True) | Q(flag__exact=False)`.

Observed before V1: direct `OR` branch leaves used `SimpleCol`, but nested `AND`
branch leaves fell back to regular `Col`, producing SQL such as
`"new__app_testconstraint"."field_1" IS NOT NULL`.

Expected from SPEC I-001, I-002, and I-003: every column reference in the schema
check predicate is bare, including nested `AND` leaves under an `OR`.

Resolution: PO-001 and PO-002 are discharged by the V1 source change that
preserves `simple_col` in the recursive `_add_q()` call.

## F-002: V1 preserves ordinary query behavior

Classification: compatibility finding, no code change required.

Input: ordinary query filtering through `Query.add_q()`.

Observed after V1 by source inspection: `Query.add_q()` still enters `_add_q()`
without `simple_col=True`, so the recursive propagation introduced by V1
propagates `False` on the ordinary path.

Expected from SPEC I-006: ordinary query filters continue to use table-qualified
`Col` output.

Resolution: PO-003 and PO-005 are discharged; no additional compatibility edit
is justified.

## F-003: Backend-specific SQL rewriting is not needed

Classification: rejected alternative, no code change required.

Input: SQLite and Oracle schema predicate generation.

Observed in source: the defect occurs before backend SQL templates, when `_add_q`
chooses `Col` instead of `SimpleCol` for nested leaves.

Expected from SPEC I-004 and I-005: fix the column expression selection in query
construction rather than stripping table aliases from rendered SQL.

Resolution: PO-006 discharges this by localizing the fix above backend rendering.

## F-004: Proof remains constructed, not machine-checked

Classification: proof capability gap, not a code bug.

Input: the generalized claim over all finite `Q` trees in
`fvk/django-query-spec.k`.

Observed: the task forbids running K tooling, and the generalized tree claim is
a structural proof obligation over recursive data.

Expected: keep the proof caveat explicit and do not remove tests based on this
constructed proof alone.

Resolution: PROOF.md lists the exact `kompile`, `kast`, and `kprove` commands
to run later. This finding does not justify changing production code.
