# Public Compatibility Audit

## Changed Public Symbols

### `astropy.coordinates.ITRS`

- Change: adds frame attribute `location`, defaulting to `EARTH_CENTER`.
- Public compatibility evidence: the issue discussion explicitly describes
  adding an `EarthLocation` argument to ITRS with an Earth-center default.
- Compatibility assessment: existing callers that omit `location` retain the
  Earth-center behavior. Reprs may include the new attribute, but the change is
  intentional public API expansion.
- Status: PASS.

### `ITRS.earth_location`

- Change: now returns the geocentric location represented by `data + location`.
- Public compatibility evidence: for default Earth-center ITRS, this is the
  old value; for topocentric ITRS, it is required for `EarthLocationAttribute`
  conversions to avoid treating a relative vector as an absolute site.
- Status: PASS.

### Transform graph: `ITRS<->AltAz`, `ITRS<->HADec`

- Change: new direct transform registrations.
- Public compatibility evidence: the issue requests transforms between these
  frames and later narrows the shortcut to explicit topocentric ITRS.
- Status: PASS.

## Public Callsite/Override Scan

- Public code constructs `ITRS(...)` without `location`: default location keeps
  those callsites valid.
- `EarthLocationAttribute.convert_input` transforms arbitrary coordinate-like
  values to `ITRS()` and then reads `.earth_location`; the adjusted property
  preserves old default-origin behavior and supports the new topocentric case.
- Existing CIRS/TETE/ITRS transform callsites rely on frame attributes being
  propagated through transform_to; V1 updates the relevant transforms to carry
  `location`.

No public subclass override or virtual dispatch signature conflict was found
in the allowed source tree by static inspection.
