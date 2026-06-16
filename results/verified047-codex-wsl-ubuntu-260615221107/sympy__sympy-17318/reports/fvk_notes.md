# FVK Notes

The FVK audit applied the public-intent ledger in `fvk/SPEC.md` and the proof
obligations in `fvk/PROOF_OBLIGATIONS.md` to the V1 fix. It produced one V2
source change and otherwise confirmed the V1 decisions.

## Source Changes

`repo/sympy/simplify/radsimp.py`

- Added an explicit `if not surds: return S.One, S.Zero, expr` guard in
  `split_surds`. This follows Finding F2 and Proof Obligation PO2: the no-surd
  case is the source condition reported in the issue, so `split_surds` should
  handle it directly instead of relying primarily on `_split_gcd`'s empty-input
  fallback.

## Kept V1 Decisions

`repo/sympy/simplify/sqrtdenest.py`

- Kept the `_sqrt_match` `sqargs` positivity guard. Finding F1 and PO1 show it
  prevents `4 + I` from entering the `split_surds` fast path and makes
  `_sqrt_match(4 + I)` return no match, satisfying the prompt requirement that
  non-denestable expressions return unchanged.

`repo/sympy/simplify/radsimp.py`

- Kept `rad_rationalize`'s `if not a` early return. Finding F3 and PO4 show it
  stops both no-surd and higher-root additive denominators without raising or
  recurring forever.
- Kept the `split_surds` filter that collects only `Pow` terms with exponent
  `S.Half`. Findings F3/F4 and PO2/PO5 show this rejects cube roots while
  preserving valid square-root rationalization such as `sqrt(2) + I`.
- Kept `_split_gcd`'s neutral empty-input fallback. Findings F2/F5 and PO3/PO6
  justify it as a defensive private-helper behavior while preserving non-empty
  behavior and public caller compatibility.

## Verification Decision

No further source changes are justified by the FVK findings. `fvk/PROOF.md`
constructs the proof over a mini SymPy surd semantics and records the machine
check commands, but those commands were not run. The remaining limitation is
Finding F6: the formal model abstracts the full SymPy expression evaluator, so
test removal is not recommended without a later machine check.
