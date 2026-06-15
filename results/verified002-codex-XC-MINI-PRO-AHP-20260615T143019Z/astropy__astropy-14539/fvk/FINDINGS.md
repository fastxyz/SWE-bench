# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
static code inspection, and constructed proof obligations only.

## F-001 - Original Q VLA false-positive path

Status: resolved by the source change.

Input class: two identical binary-table columns with format `QD`, such as the
public reproducer rows `[[0], [0, 0]]`.

V0 behavior: `Q` was not recognized by the VLA branch, so `TableDataDiff._diff`
fell through to the generic object-array inequality path. The public issue
reports this as `FITSDiff(path, path).identical == False`.

Expected behavior: `Q` VLA rows must be compared by row content, like `P` VLA
rows, and identical rows must produce no differing row index.

Trace: PO-001, PO-009.

## F-002 - V1 row predicate was too weak for the full VLA contract

Status: resolved by the source change.

Input class A: identical floating VLA rows containing matching invalid floating
values.

V1 behavior by static reasoning: the VLA branch used raw `np.allclose`, while
the established FITSDiff floating-array helper is `where_not_allclose`. Public
helper tests and code show matching invalid floating values are not intended
differences for FITSDiff.

Expected behavior: floating VLA rows should use the same invalid-value policy as
other floating FITSDiff data.

Input class B: VLA row arrays with different shapes.

V1 risk by static reasoning: raw numeric closeness is not a shape-equality
predicate. VLA row shape is part of the stored row value.

Expected behavior: rows with different shapes must be reported different before
element-value tolerance is considered.

Trace: PO-003, PO-004.

## F-003 - Format detection should use the normalized FITS format code

Status: resolved by the source change.

Input class: any table column whose format object has a top-level FITS format
code.

Risk: a substring test such as `"P" in col.format or "Q" in col.format` fixes
the reported `Q` case but describes the implementation less precisely than the
available normalized format-code field.

Expected behavior: only top-level `P` and `Q` VLA descriptor formats enter the
VLA branch.

Trace: PO-001, PO-002, PO-007, PO-008.

## F-004 - Proof not machine-checked in this environment

Status: open process limitation, not a source-code defect.

The FVK proof is constructed and the exact commands are recorded, but the task
forbids running K tooling. Test removal is therefore not recommended. Add or
keep tests until a real `kprove` run returns `#Top`.

Trace: all proof obligations.
