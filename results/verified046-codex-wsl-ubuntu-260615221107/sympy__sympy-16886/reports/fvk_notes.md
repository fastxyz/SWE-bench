# FVK Notes

## Decisions

- Kept V1 source unchanged. F-001 records the original bug and confirms V1
  resolves it; PO-1, PO-3, and PO-4 cover the corrected table entry plus default
  encode/decode behavior.
- Did not add a separate `char_morse` edit. F-002 and PO-2 show `char_morse` is
  derived from `morse_char`, so editing both would duplicate state without adding
  correctness.
- Did not broaden the source patch to other digits. F-004 and PO-5 statically
  check the full digit family and find no remaining digit-family mismatch.
- Did not edit tests. F-003 identifies missing public digit-1 coverage, but the
  task forbids modifying tests. `fvk/ITERATION_GUIDANCE.md` records the future
  test recommendation instead.
- Added FVK artifacts under `fvk/`, including the five requested reports and the
  formal/adequacy support files required by the FVK docs. F-005 and
  `fvk/PROOF.md` label the result constructed, not machine-checked.

## Source Changes In This Phase

None. The only production source change remains the V1 edit in
`repo/sympy/crypto/crypto.py`.

## Verification Limits

No tests, Python, or K commands were run. The emitted commands in `fvk/PROOF.md`
are the commands to run later if a machine check is desired.

