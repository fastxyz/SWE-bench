# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not change the source beyond V1. The audit confirms that V1 discharges the
issue intent and the proof obligations:

- F1/PO3: univariate `[EX(0)]` is stripped to `[]`.
- F2/PO4: recursive multivariate dense results are stripped at inner levels
  before outer zero detection.
- F3/PO7: generic ground multiplication stays unchanged, limiting blast radius.
- F4/PO7: public API shape is preserved.

## Recommended Follow-Up Outside This Benchmark

1. Run the constructed K commands:

   ```sh
   kompile fvk/mini-dense-polys.k --backend haskell
   kast --backend haskell fvk/clear-denoms-spec.k
   kprove fvk/clear-denoms-spec.k
   ```

2. Run SymPy's relevant polynomial tests.

3. Add source tests in a normal development setting for:

   - `Poly.clear_denoms()` on an `EX` expression that becomes zero after
     denominator clearing, asserting `poly.is_zero` and canonical `rep`.
   - `dup_clear_denoms([EX(0)], EX)` or an equivalent denominator-clearing
     construction returning `[]`.
   - A multivariate recursive dense analogue where an inner `[EX(0)]` must
     become the recursive dense zero.

No test files were modified in this benchmark, as required.
