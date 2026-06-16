# FVK FINDINGS

Status: constructed, not machine-checked.

## F1: Zero temporary LogNorm lower limit was unhandled

Input class: a log-normalized image whose finite positive user `vmin` round-trips
through the huge-range image rescaling path to a temporary `s_vmin == 0`.

Observed in V0: the old guard checked only `s_vmin < 0`, so `s_vmin == 0`
reached `LogNorm.__call__`. The log transform of zero is non-finite, so the path
can raise `ValueError("Invalid vmin or vmax")`.

Expected: zero must be treated like any other non-positive lower log limit and
repaired before calling `LogNorm`.

Status: resolved by V1. `repo/lib/matplotlib/image.py` now checks
`s_vmin <= 0` and replaces the temporary limit with the existing positive dtype
epsilon fallback.

Related proof obligations: PO1, PO2, PO3.

## F2: Positive temporary LogNorm lower limits must be preserved

Input class: `LogNorm` image resampling where the temporary `s_vmin` after the
round trip is already positive.

Observed in V1: the branch does not execute; `s_vmin` is unchanged.

Expected: unchanged behavior, because a positive lower limit is valid for
`LogNorm` and shifting it would unnecessarily perturb color mapping.

Status: confirmed. No further source edit.

Related proof obligations: PO4.

## F3: Non-LogNorm normalization paths must be preserved

Input class: image resampling under norms other than `mcolors.LogNorm`.

Observed in V1: the edit is guarded by `isinstance(self.norm, mcolors.LogNorm)`,
so non-log norms use the same temporary limits as before.

Expected: unchanged behavior outside the reported log-normalization bug.

Status: confirmed. No further source edit.

Related proof obligations: PO5, PO6.

## F4: Non-finite caller limits remain outside the repaired success domain

Input class: non-finite or intentionally invalid log limits, such as an invalid
caller-provided `vmin`/`vmax`.

Observed in V1: the source edit does not convert arbitrary non-finite limits
into positive finite values.

Expected: this remains `LogNorm` validation territory. The public issue concerns
finite huge-range image data and a positive `vmin` becoming zero by numerical
round trip, not accepting invalid log limits globally.

Status: intentionally unchanged. Broadening the repair to all non-finite cases
would risk hiding invalid user input outside the public intent.

Related proof obligations: PO7.

## F5: Proof scope does not subsume image integration tests

Input class: full renderer behavior including masked arrays, resampling,
colormap under/over colors, backend drawing, and figure comparison.

Observed in FVK: the proof abstracts only the local lower-limit repair and is
constructed, not machine-checked.

Expected: keep integration tests such as `test_huge_range_log`; they exercise
behavior outside the local proof model.

Status: test-retention guidance only. No test files were modified.

Related proof obligations: PO8.
