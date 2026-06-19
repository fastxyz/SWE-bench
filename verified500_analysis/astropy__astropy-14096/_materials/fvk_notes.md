# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decisions and Traceability

### D1: Replace V1 descriptor replay with saved-error handoff

Changed `repo/astropy/coordinates/sky_coordinate.py` by adding
`SkyCoord.__getattribute__`. When normal lookup raises `AttributeError` from a
custom subclass `property`, the method records the original exception on a
private marker before Python falls through to `__getattr__`.

Reason:

- `fvk/FINDINGS.md` F2 identified that V1 invoked the failing property twice by
  calling `descriptor.__get__` inside `__getattr__`.
- `fvk/PROOF_OBLIGATIONS.md` PO2 requires the failing property getter to run
  exactly once.
- PO1 still requires the final exception to be the inner `AttributeError`.

### D2: Re-raise the original AttributeError from `__getattr__`

Changed `SkyCoord.__getattr__` to pop the private marker and raise the saved
exception when the marker attribute matches the current `__getattr__` request.

Reason:

- F1 requires the final message to name the inner missing attribute such as
  `random_attr`, not the property name `prop`.
- PO1 requires preserving the inner error.
- PO5 requires the saved marker to be single-use and attribute-matched.

### D3: Scan the first Python MRO provider instead of stopping at `SkyCoord`

Changed the subclass-property detection into
`_get_subclass_property_descriptor`. It scans `type(self).__mro__` for the first
class defining the attribute, then intercepts only if that provider is outside
`SkyCoord.__mro__` and the descriptor is a `property`.

Reason:

- F3 identified that V1 could miss custom property providers inherited from a
  user-defined base class or mixin.
- PO4 requires Python MRO precedence and also requires leaving
  `SkyCoord`-owned properties alone.

### D4: Preserve existing dynamic SkyCoord fallback

Kept the original `SkyCoord.__getattr__` frame-name, frame-attribute,
underlying-frame delegation, transform-alias, and generic missing-attribute
fallback order unchanged after the marker check.

Reason:

- F1 only concerns the subclass-property failure path.
- PO3 requires non-custom-property attributes to continue through the existing
  dynamic fallback.
- PO6 requires no public API/signature change and no broader behavior change for
  ordinary `SkyCoord` attribute access.

### D5: Keep descriptor support limited to `property`

Did not expand the fix to arbitrary descriptors such as `cached_property`.

Reason:

- F4 records this as a residual scope decision.
- PO1 and PO4 define the verified domain as Python `property` descriptors,
  matching the public issue reproducer and wording.
- There is no public intent evidence requiring a broader descriptor contract.

### D6: Add formal artifacts without running tools

Added:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-attr.k`
- `fvk/skycoord-attribute-access-spec.k`

Reason:

- F5 records the task constraint that no tests, Python, `kompile`, or `kprove`
  may be run.
- The FVK docs require constructed proof artifacts and exact commands, so
  `PROOF.md` includes the commands while labeling them constructed, not
  machine-checked.

## Summary

The FVK audit did not merely confirm V1. It found two concrete improvements:
avoid double property execution (F2/PO2/PO5) and honor the first custom MRO
provider rather than stopping at `SkyCoord` (F3/PO4). V2 applies both while
preserving the original issue fix (F1/PO1) and the existing dynamic fallback
contract (PO3/PO6).

