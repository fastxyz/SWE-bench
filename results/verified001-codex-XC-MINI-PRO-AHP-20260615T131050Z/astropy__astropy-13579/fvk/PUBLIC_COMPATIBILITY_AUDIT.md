# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Surface

No public symbol was added, removed, or renamed.

## Public Method Signatures

- `SlicedLowLevelWCS.world_to_pixel_values(self, *world_arrays)`: unchanged.
- `SlicedLowLevelWCS.pixel_to_world_values(self, *pixel_arrays)`: unchanged.
- `SlicedLowLevelWCS.dropped_world_dimensions`: unchanged public property.

## Private Implementation

- Added private helper `_world_values_at_sliced_pixel(self)`.
- `dropped_world_dimensions` now calls that helper instead of duplicating the
  fixed-slice pixel-to-world calculation.
- `world_to_pixel_values` now calls that helper only when at least one world
  axis is dropped.

## Callsite And Override Audit

Search evidence in `repo/astropy/wcs/wcsapi` shows no public callsite depends on
the old placeholder value. The changed helper is private and has no external
callers. The public virtual method signature remains unchanged, so subclasses or
wrappers of `BaseLowLevelWCS` are not required to accept new arguments or return
new shapes.

## Verdict

PASS. The source edit changes internal value reconstruction only. It does not
change public dispatch shape, public method arity, return arity, object classes,
or metadata keys.
