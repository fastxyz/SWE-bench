# FVK Spec

Status: constructed specification, not machine-checked.

## Scope

This FVK pass audits the V1 source changes for `astropy__astropy-13398`:

- `astropy/coordinates/builtin_frames/itrs.py`
- `astropy/coordinates/builtin_frames/intermediate_rotation_transforms.py`
- `astropy/coordinates/builtin_frames/itrs_observed_transforms.py`
- `astropy/coordinates/builtin_frames/__init__.py`

The spec covers the public behavior introduced by the fix: ITRS can carry an
observer `location`; explicitly topocentric ITRS coordinates transform directly
to/from AltAz and HADec; geocentric or otherwise differing-origin ITRS
coordinates continue to use the existing ITRS self-transform for origin
changes; refraction delegates to the existing CIRS observed machinery.

The exact ERFA/NumPy numeric operations and the pre-existing ITRS/CIRS/ICRS
self-transform are abstracted in the formal model. They are named proof
obligations, not silently trusted as newly verified code.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2 require ITRS<->AltAz/HADec transform edges and a no-refraction
  topocentric path that does not synchronize ITRS obstimes through the
  SSB-oriented self-transform.
- E3/E7 require a `location` attribute on ITRS with an Earth-center default.
- E4/E6 require preserving existing geocentric ITRS behavior; the later issue
  discussion explicitly says the topocentric ITRS design does not create a
  direct geocentric satellite-observation shortcut.
- E5 requires refraction not to be silently ignored.

## Intended Contract

### ITRS frame

`ITRS` has frame attributes:

- `obstime`, as before;
- `location`, defaulting to `EARTH_CENTER`.

For an ITRS coordinate with cartesian data `V` and frame location `L`,
`earth_location` denotes the geocentric location represented by
`L.get_itrs().cartesian + V` after dropping differentials.

### ITRS to observed, no refraction

For observed frame `O = AltAz(location=L, pressure=0)` or
`HADec(location=L, pressure=0)` and ITRS coordinate
`C = ITRS(data=V, location=L)`, `C.transform_to(O)` returns `O` realized with
the local ITRS-to-observed rotation matrix applied to `V`.

This path must not perform an ITRS self-transform merely because `obstime`
differs between the source and target frames.

### ITRS to observed, differing location

If `C.location != O.location`, the transform must first convert `C` to
`ITRS(location=O.location, obstime=O.obstime or C.obstime)` through the existing
ITRS self-transform, then apply the local observed rotation. This preserves
geocentric ITRS behavior and avoids silently adopting the earlier rejected
"subtract observer from every geocentric ITRS coordinate" interpretation.

### Observed to ITRS, no refraction

For `AltAz` or `HADec` coordinate `O(data=V, location=L, pressure=0)` and target
`ITRS(location=L2, obstime=TOut)`, the transform first rotates `V` back to a
topocentric ITRS vector at `L` and realizes `ITRS(location=L, obstime=TOut)`.
If `L != L2`, the existing ITRS self-transform performs the origin change.

### Refraction

If `pressure != 0`, the transform must route through CIRS observed machinery:

- ITRS->observed: local topocentric ITRS vector is rotated into CIRS at the
  observed frame `obstime`, then CIRS->observed applies refraction.
- observed->ITRS: observed->CIRS removes refraction, then CIRS is rotated to
  topocentric ITRS.

If refraction is requested and `obstime is None`, the transform raises a clear
`ValueError`.

### Intermediate transforms

ITRS->CIRS and ITRS->TETE must construct the intermediate coordinate with
`location=itrs_coo.location` before any further transform. CIRS/TETE->ITRS must
first transform to the requested ITRS frame location before rotating into ITRS.

### Registration

`builtin_frames.__init__` imports `itrs_observed_transforms` so the graph
registers ITRS<->AltAz and ITRS<->HADec during normal built-in frame import.

## Formal Artifacts

- `mini-coordinate-transforms.k`: minimal K semantics for the transform
  dispatch/origin/refraction abstraction.
- `itrs-observed-spec.k`: reachability claims for the obligations above.

Exact machine-check commands, not executed here:

```sh
kompile fvk/mini-coordinate-transforms.k --backend haskell
kast --backend haskell fvk/itrs-observed-spec.k
kprove fvk/itrs-observed-spec.k
```

Expected outcome after installing/running K: `kprove` should reduce these
abstract claims to `#Top`. This pass did not run those commands.
