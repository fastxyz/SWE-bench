# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands unchanged. The audit found that the original fix covers both sources
that can introduce `""` into `get_template_directories()` and keeps non-empty
path normalization unchanged.

## Code guidance

Do not broaden the guard to a truthiness check. The proof obligations require
skipping exactly `""`; broad falsey filtering would risk hiding invalid values
or changing explicit current-directory behavior without public intent evidence.

Do not move the fix into `to_path()` globally. The issue is specific to template
autoreload behavior, and changing `to_path("")` would alter a shared utility
with a wider blast radius than the public intent justifies.

## Test guidance

A future test pass should cover both direct `DIRS = [""]` and loader-provided
`get_dirs() == [""]`. Those tests would exercise PO1, PO2, and PO5. Tests for
non-empty relative path normalization should remain because PO3 and PO6 are
important compatibility frame conditions.

## Verification guidance

The proof is constructed only. To upgrade it, a maintainer would run:

```sh
kompile fvk/mini-autoreload.k --backend haskell
kast --backend haskell fvk/autoreload-spec.k
kprove fvk/autoreload-spec.k
```
