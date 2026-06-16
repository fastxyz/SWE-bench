# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decisions

### D-1: Keep the V1 source fix unchanged

Trace: FI-2, FI-3, PO-2, PO-3, PO-4, PO-5.

The V1 code computes `offset = (window0 - 1) // 2` only for `center=True`,
shifts `starts` and `stops` by that offset, and clips both arrays to the data
extent. The FVK proof obligations show this is equivalent to
`Variable.rolling_window` centered bounds for odd and even windows. No further
source edit is needed.

### D-2: Do not switch iterator implementation to `construct()`

Trace: FI-4, PO-7.

`construct()` would materialize padded window arrays and change more of the
iterator behavior than the issue requires. The existing iterator contract yields
views/slices and masks with `min_periods`; after V1 fixes the slice bounds, that
structure satisfies the centered-window intent.

### D-3: Do not change the offset to `window0 // 2`

Trace: FI-3, PO-4.

For even windows, `Variable.rolling_window` uses left padding `W // 2` and right
padding `(W - 1) // 2`. The iterator shifts the right-aligned bounds by the
right padding. Using `W // 2` as the shift would move even centered windows one
position too far right.

### D-4: Preserve labels, yield shape, and multidimensional error behavior

Trace: FI-5, PO-6, PO-8.

The patch leaves iteration over `self.window_labels`, the yielded
`(label, window)` pair shape, and the `ndim > 1` `ValueError` unchanged. These
are compatibility frame conditions around the corrected bounds.

### D-5: Do not modify tests

Trace: FI-6, PO-9.

The task forbids editing tests. The FVK proof is also constructed rather than
machine-checked, so no test-removal recommendation can be acted on. The artifacts
only record future upstream test guidance.

## Artifacts Written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-rolling.k`
- `fvk/rolling-iter-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
