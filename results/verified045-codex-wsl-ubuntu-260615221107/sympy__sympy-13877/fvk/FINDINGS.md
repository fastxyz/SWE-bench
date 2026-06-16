# FVK Findings

Status: constructed, not machine-checked.

## F1 - V1 Correctly Localized The Reported Bareiss Pivot Bug

Classification: code bug fixed by V1.

Evidence: E5 in `SPEC.md` states that `_find_pivot` should expand candidate
values before accepting them. The V1 code does this for expression-valued
candidates and skips the candidate if expansion produces exact zero.

Input to reason about: a Bareiss recursive pivot column containing
`a**2 - a*(a + 1) + a`.

Observed before V1: the local pivot helper used Python truthiness, so the
unsimplified expression was accepted as a pivot even though expansion makes it
zero.

Expected: the candidate is skipped, so it cannot become the next cumulative
denominator and cannot lead to a Bareiss-created `0/0` expression.

Resolution: keep V1's pivot-expansion change. This discharges proof obligations
O2 and O3 for the polynomial expanded-zero mechanism in the issue.

## F2 - V1 Missed The Public Input-NaN Short-Circuit

Classification: code bug found by FVK audit and fixed in V2.

Evidence: E4 in `SPEC.md` says that a matrix containing `nan` to begin with
should return `nan` immediately. V1 only prevented internally generated
expanded-zero pivots; it did not distinguish input `S.NaN`.

Input to reason about:

```python
Matrix([[0, S.NaN, 0, 0],
        [0, 1,     0, 0],
        [0, 0,     1, 0],
        [0, 0,     0, 1]]).det()
```

Observed by source reasoning before V2: for size 4, `det()` enters Bareiss.
The first Bareiss pivot column is all exact zero, so `_find_pivot` returns no
pivot and `bareiss()` returns `S.Zero` before the `S.NaN` entry participates in
arithmetic.

Expected from public intent: `S.NaN`, because the matrix contained `nan` before
determinant computation began.

Resolution: add `if self.has(S.NaN): return S.NaN` immediately after the
square-matrix check in `MatrixDeterminant.det()`. This discharges O1.

## F3 - Full Algebraic Zero Detection Remains Intentionally Narrow

Classification: residual risk, not a required code change for this issue.

Evidence: E5 names expansion as the pivot zero detection relevant to the issue.
V2 does not switch Bareiss to `_find_reasonable_pivot` and does not call full
`simplify()`/`.equals(0)` for every pivot candidate.

Input class outside the proven abstraction: a pivot candidate that is zero only
by a non-polynomial identity not detected by `.expand()`.

Expected if such a case is in scope in the future: a stronger pivot detection
policy or a carefully designed fallback.

Reason for no change now: the public issue's matrix entries are polynomial in
`a`, and the public hint specifically points to expansion. The source comments
also state that replacing the local helper with `_find_reasonable_pivot` is
blocked by another issue.

## F4 - Verification Was Not Executed

Classification: proof honesty gate.

The K artifacts and proof are constructed only. No tests, Python code, or K
tooling were run, in accordance with the task constraints. Test removal is not
recommended.

