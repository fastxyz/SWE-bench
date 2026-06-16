# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found that V1 satisfies the real-valued negative-coefficient
window obligation that caused the issue. No source edit beyond V1 is justified
by the public evidence.

## Next Code Guidance

Do not change the production code for complex windows in this issue. If complex
window support is desired, first clarify whether spectrum scaling should use
`window.sum()**2`, `abs(window.sum())**2`, or reject complex windows.

## Next Test Guidance

A future regression test should cover:

- `mode == "psd"`;
- `scale_by_freq=False`;
- a real window with at least one negative coefficient;
- comparison to coherent-gain normalization, not coefficient-wise absolute
  normalization.

Existing positive-window tests should be kept unless the K artifacts are
machine-checked and maintainers decide they are redundant.

## Next Verification Guidance

Run the emitted commands from `PROOF.md` only in an environment with K
installed. If a full-language proof is desired, replace the mini model with a
Python/NumPy-aware semantics or treat FFT/NumPy array behavior as separately
specified lemmas.

