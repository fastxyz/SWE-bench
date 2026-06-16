# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F1: V1 Truncated Fractional Counts Instead of Rounding

Input class: `size <= 1`, for example `min_samples=0.26` with
`n_samples=10`.

Observed in V1 by static inspection:

```python
max(2, int(0.26 * 10)) == 2
```

Expected from public intent IE4 and IE8:

```python
int(round(max(2, 0.26 * 10))) == 3
```

Classification: code bug in V1.

Resolution: V2 changes the three fractional conversions to
`int(round(max(2, size * n_samples)))`.

Related proof obligations: PO2, PO4.

## F2: Original Failure Mode Required Integer Neighbor Count

Input class: fractional `min_samples`, for example the issue snippet
`OPTICS(metric='minkowski', n_jobs=-1, min_samples=0.1)`.

Observed pre-fix behavior from the public issue: the scaled value stayed a
float and `NearestNeighbors(n_neighbors=...)` raised `TypeError` because
`n_neighbors` was not integral.

Expected: after validation and scaling, `compute_optics_graph` passes an
integer count to `NearestNeighbors`.

Classification: original code bug, fixed by V1 and preserved by V2.

Related proof obligations: PO1, PO2, PO3.

## F3: Xi Extraction Needed the Same Fractional Count Semantics

Input class: standalone or `OPTICS(..., cluster_method='xi')` calls where
`min_samples` or `min_cluster_size` is a fraction.

Observed pre-fix behavior from source: `cluster_optics_xi` scaled fractional
values but did not convert them to integer counts. V1 converted them but used
truncation. The same example shape as F1 changes threshold behavior.

Expected: Xi receives the same rounded integer count semantics as the OPTICS
core-distance path.

Classification: original code bug plus V1 rounding mismatch, fixed in V2.

Related proof obligations: PO4, PO5.

## F4: Exact Python Floating-Point Round Semantics Are an Escalation Boundary

Input class: tie cases and binary floating-point edge cases, for example a
scaled value exactly at a Python `round` tie.

Observed: this FVK mini-model records that the code calls Python `round` and
then `int`; it does not model Python's full float representation or
ties-to-even rule.

Expected: runtime behavior follows Python's built-in `round` and `int`.

Classification: proof capability gap, not a code bug.

Recommended next step: keep tests for representative fractional inputs until a
real Python semantics or runtime tests confirm edge cases.

Related proof obligations: PO7.

## F5: Test and Changelog Hints Were Not Actionable Under This Benchmark

Input class: process requirements rather than runtime inputs.

Observed: the public hints requested tests and a changelog entry. The current
benchmark explicitly forbids modifying tests and asks for source-code fixes and
reports.

Expected: no test files are edited; changelog files are left unchanged unless
the benchmark permits them.

Classification: benchmark constraint, not a code bug.

Related proof obligations: PO8.

## F6: Integer-Valued Floats Above 1 Remain Outside the Documented Domain

Input class: `min_samples=5.0`.

Observed from source: `_validate_size` accepts integer-valued floats greater
than 1, but `NearestNeighbors` requires `numbers.Integral`.

Expected from public docs: `min_samples` is either an integer count greater
than 1 or a float fraction between 0 and 1. A float value above 1 is not
documented as an in-domain fractional input.

Classification: underspecified legacy behavior outside this issue's public
intent. No V2 code change is justified by the current evidence.

Related proof obligations: PO1, PO8.
