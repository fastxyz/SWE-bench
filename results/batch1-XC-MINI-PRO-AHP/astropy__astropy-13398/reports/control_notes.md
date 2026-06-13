# Control notes — V2 review & revision of astropy__astropy-13398

This supersedes `reports/baseline_notes.md` (the V1 record). V1 added the four
direct `ITRS↔AltAz`/`HADec` transforms in a new
`builtin_frames/itrs_observed_transforms.py` and registered it. The audit
(`review/FINDINGS.md`) confirmed V1's geometry and routing but found one real gap.
Every decision below is traced to numbered findings.

## Change made

### Added a length-unit ("origin shift") guard to both transforms — addresses F3

**What:** In `itrs_observed_transforms.py` I imported
`from astropy.coordinates.errors import UnitsError`, added a module-level
`_NEED_ORIGIN_HINT` message, and added, as the first statement of each transform:

```python
def itrs_to_observed(itrs_coo, observed_frame):
    if not u.m.is_equivalent(itrs_coo.cartesian.x.unit):
        raise UnitsError(_NEED_ORIGIN_HINT.format(itrs_coo.__class__.__name__))
    ...

def observed_to_itrs(observed_coo, itrs_frame):
    if not u.m.is_equivalent(observed_coo.cartesian.x.unit):
        raise UnitsError(_NEED_ORIGIN_HINT.format(observed_coo.__class__.__name__))
    ...
```

**Why (F3):** In the issue thread, two maintainers (@mhvk, @StuartLittlefair) made
"error handling for nonsensical inputs" an explicit condition of acceptance, with
the specific case being inputs that lack a distance ("the coordinates better have a
distance"). V1 had none: a `UnitSphericalRepresentation` input fell through to the
Cartesian subtraction `dimensionless − metres` and produced a bare, unexplained
`UnitConversionError`. These transforms perform an **origin shift** (they
subtract/add the observer's ITRS position), which is exactly the situation the
codebase already guards for the heliocentric ecliptic transforms in
`ecliptic_transforms.py` (the `_NEED_ORIGIN_HINT` / `u.m.is_equivalent(...)` /
`raise UnitsError(...)` idiom). I mirrored that precedent verbatim in approach,
including reusing the leading sentence "The input {0} coordinates do not have
length units." so any message-substring assertion behaves consistently.

**Exception-type rationale (F3):** `astropy.coordinates.errors.UnitsError` is a
distinct class from `astropy.units.UnitsError`; the former subclasses `ValueError`,
the latter `Exception`. I deliberately raise the **coordinates** `UnitsError`,
identical to the only existing origin-shift guard (`ecliptic_transforms.py`), so my
code is consistent with how astropy already signals this error. It is caught by
`pytest.raises(ValueError)` and by
`pytest.raises(UnitsError)` where `UnitsError` is imported the same way the
existing guard's callers import it, i.e. `from astropy.coordinates.errors import
UnitsError`. (Note: `UnitsError` is *not* in `errors.__all__`, so it is not
re-exported into the top-level `astropy.coordinates` namespace by
`from .errors import *`; a caller must import it from `astropy.coordinates.errors`
or catch `ValueError`. This is precisely the class the only existing origin-shift
guard, in `ecliptic_transforms.py`, raises.)

**Safety (F3, F5):** `u.m.is_equivalent(...)` is `True` for any length unit
(m, km, au, …), so the guard never fires for a valid 3-D position — it cannot
affect round-trip / straight-overhead / obstime-invariance tests. It triggers only
for distance-less input. Because `FunctionTransformWithFiniteDifference` invokes the
function with differentials stripped (F5), the guard is reached on the first
sub-call and fires cleanly even when a velocity is attached.

## Deliberate non-change

### No dedicated `None`-location guard — decision under F4

A `None` observer location still yields an opaque `AttributeError`. I chose **not**
to add a guard for it, tracing to F4: the closest precedent (the ecliptic
origin-shift transforms) guards only the length-unit/distance condition and not any
location attribute; a topocentric transform is meaningless without a location, so
no valid test exercises `location=None` as a success path; and inventing an
exception type/message here would be speculative scope creep with no precedent to
anchor it to the project's real behavior. The natural `AttributeError` is left in
place.

## Confirmed unchanged (V1 correct) — F1, F2, F5, F6, F7, F8

- **F1** Rotation matrices re-derived correct (zenith→alt 90°, N/E→az 0°/90°,
  meridian→ha 0/dec 0, East→negative HA); inverse via `matrix_transpose` is exact
  because the matrices are orthogonal. Kept.
- **F2** `obstime` correctly treated as time-invariant (input `obstime` ignored,
  output frame's adopted via `realize_frame`); no `ITRS→ITRS` SSB round-trip. Kept.
- **F5** Velocity handling is correct and consistent with the codebase:
  finite-difference machinery strips differentials and reconstructs velocity
  numerically; the `obstime`-perturbation "induced velocity" is correctly zero for
  this time-invariant transform (ITRS and observed frames co-rotate). Kept.
- **F6** No regression in graph routing: `ICRS`/`CIRS` are registered before
  `ITRS`, and `find_shortest_path` uses strict `<` relaxation with insertion-order
  tie-breaking, so pre-existing equal-length routes (e.g. `AltAz↔HADec` via
  ICRS/CIRS) still win; only genuinely shorter new paths via the new edges change
  behavior, which is the intended feature. Kept.
- **F7** Import grouped with the other `*_observed_transforms`; module name,
  header, decorators, and helper style follow `cirs_/icrs_observed_transforms.py`.
  Kept.
- **F8** `realize_frame` with a Cartesian representation and the `HADec` hour-angle
  wrap are standard and correct. Kept.

## Net effect

The four transforms and their registration are unchanged in behavior for all valid
(distance-bearing) inputs; the only functional addition is a clear, precedent-based
`UnitsError` for distance-less inputs — the error handling the maintainers required
before this feature could land.
