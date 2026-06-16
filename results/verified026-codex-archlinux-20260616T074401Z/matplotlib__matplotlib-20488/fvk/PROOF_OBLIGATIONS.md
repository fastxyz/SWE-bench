# FVK PROOF OBLIGATIONS

Status: constructed, not machine-checked. Commands are written for reproduction
only and were not run.

## Obligations

PO1. Localize the reported failure mechanism.

Show that the symptom can arise from `_ImageBase._make_image` supplying
`LogNorm.__call__` a non-positive temporary lower limit. Evidence: the public
stack trace raises at transformed limit validation, and image.py temporarily
overrides norm `vmin`/`vmax` immediately before calling the norm.

Status: discharged by inspection and modeled in `image-lognorm-spec.k`.

PO2. Preserve the `LogNorm` domain requirement.

For any `LogNorm` path in the verified domain, the adjusted temporary lower
limit must be strictly positive before the log transform.

Status: discharged by claim C1.

PO3. Repair the exact zero case.

For `EPS > 0` and temporary `s_vmin <= 0`, the adjusted lower limit must be
`EPS`. This includes the old missing boundary case `s_vmin == 0`.

Status: discharged by claim C2.

PO4. Preserve already-valid positive log limits.

For `EPS > 0` and temporary `s_vmin > 0`, the adjusted lower limit must remain
`s_vmin`.

Status: discharged by claim C3.

PO5. Preserve non-LogNorm behavior.

For non-log norms, the local repair function must return the incoming
temporary lower limit unchanged.

Status: discharged by claim C4.

PO6. Preserve public API compatibility.

No signature, dispatch, storage, or public return-shape change is allowed for
this fix.

Status: discharged by source diff inspection; V1 changes only `<` to `<=` in an
internal branch.

PO7. Do not hide invalid non-finite caller limits outside the issue domain.

The repair may correct non-positive finite temporary lower limits introduced by
image rescaling, but it should not globally make `LogNorm` accept arbitrary
invalid `vmin`/`vmax`.

Status: discharged by keeping the existing narrow branch and not adding a
general `not np.isfinite(...)` coercion.

PO8. Be honest about proof scope.

The proof must not claim to verify the whole renderer, NumPy floating-point
semantics, masked-array behavior, or backend drawing.

Status: discharged by limiting test-redundancy recommendations and recording
F5.

## Reproduction Commands

These are exact intended commands for later machine checking. They were not run
in this session.

```sh
kompile fvk/mini-image-lognorm.k --backend haskell
kast --backend haskell fvk/image-lognorm-spec.k
kprove fvk/image-lognorm-spec.k
```

Expected result after a real machine check: all claims discharge to `#Top`.
