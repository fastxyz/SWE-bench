# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 was correct for the reported `XYPoint` and `XYCircle` source bug, but the FVK
audit found the same contract violation in `Point`, `Circle`, and `Rectangle2D`.
V2 therefore keeps V1 and adds the compare-based repair for those three classes.

## Recommended Tests to Add or Keep

Do not edit tests in this task. For a future test pass, add or keep coverage for:

- `XYPoint(-0.0f, y)` versus `XYPoint(0.0f, y)`
- `XYCircle(-0.0f, y, r)` versus `XYCircle(0.0f, y, r)`
- `Point(-0.0, lon)` versus `Point(0.0, lon)`
- `Circle(-0.0, lon, r)` versus `Circle(0.0, lon, r)`
- `Rectangle2D` signed-zero-distinct bounds if package-private tests cover it
- `XYRectangle` signed-zero-distinct bounds as a regression that should already pass

Existing integration, construction-validation, and geometry-query tests remain useful
because this proof covers only equality/hash consistency.

## Machine Verification

Run the commands listed in `fvk/PROOF.md` in an environment with K installed. Until
then, treat the proof as constructed only and do not remove tests based on it.

## No Further Source Changes Suggested

After V2, the audited scalar geometry equality/hash family is consistent with the
compare-based pattern already present in `XYRectangle` and `Rectangle`. Other numeric
comparisons found by grep are geometric predicates or algorithmic tests, not
`equals`/`hashCode` contract implementations; they should be audited separately only
if a public issue identifies them.
