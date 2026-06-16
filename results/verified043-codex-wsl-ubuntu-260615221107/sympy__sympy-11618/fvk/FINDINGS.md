# FVK FINDINGS - sympy__sympy-11618

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## F-001 - Resolved Code Bug: Truncated Mixed-Dimension Euclidean Distance

Input:

`Point(2, 0).distance(Point(1, 0, 2))`

Observed in the issue:

`1`, because only `(2, 0)` and `(1, 0)` were paired.

Expected from public intent:

`sqrt(5)`, because the missing third coordinate of the 2D point is `0` and the
third coordinate difference is `0 - 2`.

Classification:

Code bug, resolved by V1.

Evidence:

- SPEC E-001 and E-002.
- PROOF_OBLIGATIONS PO-001 and PO-002.

V1 status:

Resolved. `Point.distance` now uses `zip_longest(..., fillvalue=S.Zero)`, so
extra coordinates are included instead of silently ignored.

## F-002 - Compatibility Check: Same-Dimensional Distances

Input class:

Any `Point.distance` call where both coordinate lists have the same length.

Observed before V1:

The old `zip` formula used every coordinate pair.

Expected from public intent:

Same-dimensional examples such as `Point(1, 1).distance(Point(4, 5)) == 5`
must continue to hold.

Classification:

Compatibility/frame obligation, discharged by proof obligation PO-003.

V1 status:

Confirmed. On equal-length inputs, `zip_longest` and `zip` produce the same
pairs, so the formula is unchanged.

## F-003 - Audited But Not Changed: Adjacent Zip-Based Point Methods

Input class:

Mixed-dimensional calls to methods such as `midpoint`, `dot`, or
`taxicab_distance`.

Observed from source:

Some adjacent methods also use `zip`.

Expected from public intent:

The allowed public issue names `.distance` and gives a Euclidean expected value,
`sqrt(5)`. The available public evidence does not require changing midpoint,
dot product, or taxicab distance for this issue.

Classification:

Underspecified adjacent behavior, not a code-change obligation for this task.

Decision:

No source edits beyond `Point.distance`. This keeps V2 scoped to the public
intent and avoids broadening behavior without evidence.

## F-004 - Proof Honesty Gate

Input:

The FVK artifacts and K claims.

Observed:

The session has no execution environment, and the user prohibited running tests,
Python, `kompile`, or `kprove`.

Expected:

Artifacts must contain exact commands and label the proof as constructed, not
machine-checked.

Classification:

Proof capability constraint, not a code bug.

Decision:

The proof is recorded as constructed only. Test removal is not recommended until
the emitted commands have been run and return `#Top`.
