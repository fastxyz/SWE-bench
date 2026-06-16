# Spec Adequacy Audit

Status: pass for the coordinate-storage contract; constructed, not
machine-checked.

| Formal claim | Intent entry | Audit result | Notes |
| --- | --- | --- | --- |
| `annotation-base-xy-copy-y` | Intent 1, E1, E2, E3 | Pass | Directly models the reported `xy_0[1] = 3` mutation. |
| `annotation-base-xy-copy-x` | Intent 1, E3 | Pass | Symmetric component mutation follows from the same copy obligation. |
| `offsetfrom-ref-copy-y` | Intent 4, E4, E5 | Pass | Public hint asks to check `OffsetFrom`; docs type `ref_coord` as a coordinate pair. |
| `annotationbbox-explicit-xybox-copy-y` | Intent 5, E7 | Pass | `xybox` is an explicit coordinate pair and is read later during drawing. |
| `annotationbbox-default-xybox-uses-copied-xy` | Intent 5, E7 | Pass | Prevents the default `xybox` path from reusing the original caller-owned `xy`. |
| `connectionpatch-endpoints-copy-y` | Intent 6, E8 | Pass | The change is compatible with documented tuple endpoints and the same delayed-use storage pattern. |
| Tuple-like public behavior frame | Intent 3, E6, E9 | Pass | V1 uses `tuple(...)`, not `np.array(...)`, so tuple equality remains well-defined. |

## Coverage Check

The proof covers constructor-time coordinate storage and later caller-array
mutation. It does not prove rendering geometry, transform correctness,
termination, or direct user reassignment after construction. Those are outside
the public issue's aliasing intent and are recorded as residual risk rather
than hidden assumptions.

## Suspect Legacy Evidence

No public test was found that requires the buggy live-alias behavior. Existing
tuple comparisons are treated as compatibility evidence, not as a veto of the
copying intent.
