# FVK Iteration Guidance

## V2 Source Decision

Keep the V1 source change unchanged.

Reason: Findings F-1 and F-2 are resolved by proof obligations PO-5, PO-6, and
PO-7. Finding F-3 confirms the guard is intentionally placed after validation
and the composite-modulus rejection. No finding requires another source edit for
the reported prime zero-residue bug.

## Do Not Broaden Composite Behavior in This Iteration

Finding F-4 records that composite zero-residue calls have a mathematical zero
root, but the existing public behavior for `n > 2` composite moduli is
`NotImplementedError`. Returning `0` only for `all_roots=False` would be a
partial feature, and returning `[0]` for `all_roots=True` would be incomplete for
some composite moduli. A future composite-support iteration should specify the
full root set and then implement it uniformly.

## Suggested Public Tests for a Future Test Patch

Do not modify tests in this task. If tests are added later, target:

- `nthroot_mod(17*17, 5, 17) == 0`
- `nthroot_mod(17*17, 5, 17, True) == [0]`
- `nthroot_mod(0, 3, 2) == 0`
- `nthroot_mod(0, 3, 2, True) == [0]`

These exercise the prime zero-residue family, including the smallest prime.

## Machine-Check Follow-Up

Run the emitted commands from `fvk/PROOF.md` only in an environment where K is
available. Until `kprove` returns `#Top`, treat the proof as constructed but not
machine-verified and do not remove tests on its basis.
