# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and algebraic proof construction only.

## F1: Resolved Code Bug - Wrong Sign in M12

Input:

```
q = Quaternion(cos(x/2), sin(x/2), 0, 0)
q.to_rotation_matrix()
```

Observed before V1: the issue reports

```
[[1, 0, 0],
 [0, cos(x), sin(x)],
 [0, sin(x), cos(x)]]
```

Expected: under the active quaternion rotation convention used by
`rotate_point`, the matrix is

```
[[1, 0, 0],
 [0, cos(x), -sin(x)],
 [0, sin(x),  cos(x)]]
```

Cause: `M12` used `2*s*(q.c*q.d + q.b*q.a)`, the same `+ q.b*q.a` sign used by
`M21`. V1 changed it to `2*s*(q.c*q.d - q.b*q.a)`.

Status: resolved by V1. Proof obligations: PO2, PO3, PO4.

## F2: SUSPECT Legacy Public Test Expectation

Input:

```
q = Quaternion(1, 2, 3, 4)
q.to_rotation_matrix()
q.to_rotation_matrix((1, 1, 1))
```

Observed in visible in-repo tests: `M12` is expected as `14/15`, and the 4x4
translation row-1 entry is expected as `-4/15`. These values follow from the
pre-fix `M12 = 2*s*(c*d + b*a)` expression.

Expected under the public-intent contract:

```
M12 = 2*(3*4 - 2*1)/30 = 2/3
m13 = 1 - 2/3 - (-1/3) - 2/3 = 0
```

Classification: SUSPECT legacy evidence. The visible tests encode the same
sign defect reported in the issue for a general quaternion, so they cannot be
used as authoritative intent.

Status: tests were not modified, per task constraints. Proof obligations: PO2,
PO6, PO7.

## F3: Nonzero Quaternion Domain Assumption

Input:

```
q = Quaternion(0, 0, 0, 0)
q.to_rotation_matrix()
```

Observed from source: the method computes `s = q.norm()**-2`, so the zero
quaternion makes the scale undefined.

Expected by this FVK spec: the zero quaternion is outside the verified domain,
because it does not represent a rotation. A future API hardening pass could
document or enforce this precondition with a guard, but that is not required by
the public issue.

Classification: missing explicit precondition / boundary note, not a blocker
for the reported in-domain rotation bug.

Status: no source edit in this FVK pass. Proof obligation: PO1.

## F4: Constructed Proof Not Machine-Checked

The FVK proof artifacts include K-style semantics, claims, and exact commands,
but the task forbids running K tooling. Therefore the proof is constructed, not
machine-checked, and test-removal recommendations remain conditional.

Status: expected process limitation, not a source bug. Proof obligation: PO8.
