# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims Proved In The Model

The K model in `mini-java-shapefield.k` defines a single statement, `resolveTriangleType`, operating on a mutable `DecodedTriangle`-like record:

`DT(aX, aY, ab, bX, bY, bc, cX, cY, ca, type)`.

`shape-field-spec.k` states five branch claims:

- `RESOLVE-POINT`
- `RESOLVE-AEQB-LINE`
- `RESOLVE-AEQC-LINE`
- `RESOLVE-BEQC-LINE`
- `RESOLVE-TRIANGLE`

There are no loops or recursion, so there are no circularity obligations. The proof is branch-by-branch symbolic execution.

## Main Proof: `RESOLVE-AEQB-LINE`

Precondition:

- `AX == BX`
- `AY == BY`
- not both `AX == CX` and `AY == CY`

Symbolic execution:

1. The first rule, point case, is not applicable because `C` is distinct from `A`.
2. The second rule matches the `A == B`, `C` distinct precondition.
3. The rule rewrites:

   `DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)`

   to:

   `DT(AX, AY, BC, CX, CY, BC, AX, AY, CA, LINE)`

4. This satisfies the claim by instantiating the ignored line-case metadata fields to their concrete values. Therefore the result is a canonical line `A-C-A` and the result `ab` field equals old `bc`.

By the source query bridge, `LatLonShapeQuery` and `XYShapeQuery` pass this result `ab` to `withinLine`, so the `CONTAINS` relation observes the non-collapsed `B-C` edge metadata.

## Remaining Branch Proofs

- `RESOLVE-POINT`: the all-equal precondition matches the first rule, which only sets `type = POINT`.
- `RESOLVE-AEQC-LINE`: the `A == B` branch is excluded, and the `A == C` rule sets only `type = LINE`; `ab` remains old `ab`.
- `RESOLVE-BEQC-LINE`: both earlier equality branches are excluded, and the `B == C` rule rewrites `C = A` and sets `type = LINE`; `ab` remains old `ab`.
- `RESOLVE-TRIANGLE`: all equality branches are excluded, so the final rule sets `type = TRIANGLE`.

## Adequacy

The formal claims match `INTENT_SPEC.md` according to `SPEC_AUDIT.md`. The core issue obligation is not candidate-derived: it comes from `PROBLEM.md` and the query source showing that `withinLine` consumes `ab`.

## Machine-Check Commands Not Run

These are the commands to run in an environment with K installed:

```sh
kompile fvk/mini-java-shapefield.k --backend haskell
kast --backend haskell fvk/shape-field-spec.k
kprove fvk/shape-field-spec.k
```

Expected result after successful machine checking: `#Top` for all five claims.

## Test Redundancy

No tests are recommended for removal. This proof is constructed only, not machine-checked, and the task forbids modifying tests.

## Residual Risk

The proof uses a mini-Java/K model of only `resolveTriangleType`; it does not verify the full Java runtime, full BKD query traversal, or full polygon tessellation. The abstraction is property-complete for the reported defect because it preserves the decoded coordinates, edge flags, type, and the query-observed `ab` field.
