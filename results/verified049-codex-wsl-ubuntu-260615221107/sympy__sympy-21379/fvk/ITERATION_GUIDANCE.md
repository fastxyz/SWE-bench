# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Decision

V1 stands unchanged.

The FVK audit found the V1 patch satisfies the intent-derived obligations for
the reported issue:

- F-001 / PO-001: `PolynomialError` from optional `Mod` `gcd` extraction is
  contained.
- F-002 / PO-002: supported `gcd` simplifications remain on the original branch.
- PO-003: modulo-by-zero behavior remains outside the catch.
- PO-004: failed extraction does not partially mutate `p` or `q`.
- PO-005: the reported `subs` traceback reaches the repaired edge.

## Recommended Future Work

1. Add source tests in the hidden/public suite for the direct `Piecewise` modulo
   reproducer and the original `subs` reproducer. Do not remove existing tests
   unless a machine-checked proof later returns `#Top`.
2. Treat branchwise `gcd` for `Piecewise` as a separate feature request
   (F-003). It needs an explicit contract for condition merging when both
   arguments are `Piecewise`.
3. Treat old-assumption cache rollback after exceptions as a separate design
   issue (F-004). It is not a substitute for the `Mod` fix because it would not
   make the reported first call succeed.
4. If a later environment supports K, run the commands in `fvk/PROOF.md` and
   update this guidance based on the actual `kprove` result.

