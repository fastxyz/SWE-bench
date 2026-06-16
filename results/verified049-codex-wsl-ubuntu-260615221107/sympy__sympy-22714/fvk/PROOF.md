# PROOF

Status: constructed, not machine-checked.

## What Is Proved

Within the mini-K abstraction in `mini-sympy-point.k`, the V2 validation check
has these partial-correctness properties:

- If no coordinate has a nonzero imaginary part under evaluated semantics,
  validation returns `ok`, even when the old ambient flag is `false`.
- If any coordinate has a nonzero imaginary part under evaluated semantics,
  validation returns `imaginaryError`.
- The old ambient evaluation flag is restored on both paths.

These properties discharge PO-001 through PO-005 for the modeled validation
slice. PO-006 is a compatibility/diff obligation and PO-007 is the FVK honesty
gate.

## Proof Sketch

The semantics models validation as `validate(CS)`, which first saves the old
ambient `<eval>` flag and sets it to `true`, corresponding to
`with evaluate_context(True)`. It then runs `validateEval(CS, OLD)` over the
coordinate list.

For the empty list, `validateEval(.Coords, OLD)` reaches `ok` and rewrites
`<eval>` back to `OLD`.

For a non-empty list `C, CS`, the proof splits on
`isNumber(C) andBool imagTruthy(C, true)`:

- If true, the semantic rule reaches `imaginaryError` and restores `<eval>` to
  `OLD`. This proves the head-coordinate case of PO-003 and PO-005.
- If false, the semantic rule consumes the head and continues with
  `validateEval(CS, OLD)`. The circularity is applied to the smaller list after
  one rewrite step, which is guarded. This proves the inductive step for both
  pass and error outcomes.

The key V1 counterexample class is `residualZeroNum`. In the abstraction,
`imagTruthy(residualZeroNum, false) == true` but
`imagTruthy(residualZeroNum, true) == false`. V2 uses the second value because
the entire validation probe runs under evaluated semantics, so the pass proof
covers this class.

## Machine-Check Commands

These commands are emitted for later checking only. They were not run.

```sh
cd fvk
kompile mini-sympy-point.k --backend haskell
kast --backend haskell point-imaginary-validation-spec.k
kprove point-imaginary-validation-spec.k
```

Expected machine-check result after the commands are run in an environment with
K installed: `kprove` reduces the claims to `#Top`.

## Residual Risk

The proof is over a small abstraction of the relevant SymPy behavior, not the
full Python/SymPy runtime. It is property-complete for this issue's axis:
numeric-vs-symbolic coordinates, evaluated nonzero imaginary parts, ambient
evaluation flag dependence, and flag restoration. It does not prove unrelated
Point behaviors such as dimension morphing, float rationalization, or geometric
methods.

No termination issue is present in the modeled finite-list validation beyond
the structural descent over `Coords`. The proof remains constructed, not
machine-checked.

## Test Recommendation

No tests were edited. If the K proof is later machine-checked, tests that only
assert the in-domain modeled behavior of the imaginary-coordinate guard are
subsumed by the proof. Existing tests for broader geometry integration,
constructor return shape, parser integration, or out-of-model behavior should be
kept.
