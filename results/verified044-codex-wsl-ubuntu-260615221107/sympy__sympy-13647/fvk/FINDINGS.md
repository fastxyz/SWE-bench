# FVK Findings

Status: constructed, not machine-checked.

## F-001: Pre-V1 right-frame index violates the public intent

Input:

```text
A = eye(6)
B = 2 * ones(6, 2)
P = 3
```

Observed before V1:

```text
the original columns 3, 4, 5 were read as columns 0, 1, 2 after insertion
```

Expected:

```text
the original columns 3, 4, 5 remain in rows 3, 4, 5 and shift to result
columns 5, 6, 7
```

Reason:

The legacy expression `self[i, j - pos - other.cols]` maps the first
right-frame result column `j = P + K` to original column `0`, not original
column `P`.

Status:

Resolved by V1. PO-6 requires `self[i, j - other.cols]`, which is exactly the
current source expression.

## F-002: V1 satisfies the full entry-mapping contract for normalized positions

Input class:

```text
self.rows == other.rows
0 <= P <= self.cols
0 <= i < self.rows
0 <= j < self.cols + other.cols
```

Observed in V1:

The three source branches implement the left frame, inserted block, and right
frame obligations in PO-4, PO-5, and PO-6.

Expected:

The piecewise insertion contract in `fvk/SPEC.md`.

Status:

No additional code issue found. V1 stands unchanged.

## F-003: Existing public tests do not exercise nonzero right-frame preservation

Input class:

```text
interior insertion into a matrix with nonzero columns to the right of P
```

Observed:

The visible public tests insert one column into a zero matrix, so the old
right-frame bug could pass because wrong zero columns still look correct.

Expected:

A regression test would assert preservation of nonzero right-side entries, such
as the issue's identity-matrix example.

Status:

Test gap only. The task forbids modifying tests, so no test file was changed.

## F-004: No compatibility blocker found

Input:

```text
public calls to col_insert(pos, other) and subclass _eval_col_insert overrides
```

Observed:

V1 changes only the internal source-column expression. It does not change the
public signature, virtual dispatch call, shape guard, return protocol, or sparse
override requirements.

Expected:

Existing public API and subclass compatibility are preserved.

Status:

Resolved by inspection; see PO-8 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## F-005: Proof was not machine-checked in this environment

Input:

```text
fvk/mini-matrix.k and fvk/col-insert-spec.k
```

Observed:

The K commands were written into the artifacts but not executed.

Expected:

In an environment with K installed, `cd fvk && kprove col-insert-spec.k` should
return `#Top` for the constructed claims.

Status:

Residual verification caveat only. It does not justify a source-code change.
