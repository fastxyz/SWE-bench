# FVK Notes

## Decision

V1 stands unchanged. No additional production-code edits were made after the
FVK audit.

## Why the `StrCategoryConverter.convert` V1 guard stands

F-001 identifies the root defect as vacuous truth: empty `values` made
`is_numlike` true, so empty data entered the deprecated numeric pass-through
branch. PO-1 requires the empty case to complete with result size `0` and no
numeric deprecation warning, even when `AllNumlike` is true by vacuity. The V1
condition `if values.size and is_numlike:` discharges PO-1 because
`values.size` is false for empty data.

The same guard also discharges the frame obligations for non-empty inputs. PO-2
requires non-empty numeric-like values to keep the existing warning path, and
`values.size and is_numlike` remains true when `values.size > 0` and
`is_numlike` is true. PO-3 and PO-4 require non-empty categorical and invalid
mixed inputs to keep falling through to `UnitData.update`; when `is_numlike` is
false, adding `values.size` does not change that branch choice.

## Why the `UnitData.update` V1 guard stands

F-002 identifies the same vacuous-truth pattern in the all-convertible
informational log. PO-5 requires empty update data to emit no
all-convertible log. The V1 condition `if data.size and convertible:`
discharges PO-5 because `data.size` is false for empty data.

PO-6 requires non-empty all-convertible data to preserve the existing log path.
The V1 guard keeps that behavior because both `data.size` and `convertible` are
true for non-empty all-convertible input.

## Why no broader code change was made

Changing `Axis.convert_units`, `Artist.convert_xunits`, or plotting callsites
was rejected because F-001 localizes the operative defect to
`StrCategoryConverter.convert`, and PO-1 is discharged at that converter entry
point. That also covers the issue's direct `ax.convert_xunits([])` example.

Suppressing the numeric pass-through deprecation warning more broadly was
rejected because F-003 and PO-2 require the warning to remain for non-empty
numeric-like data.

Changing validation behavior was rejected because F-004 and PO-4 require
non-empty invalid mixed categorical data to remain rejected by
`UnitData.update`.

No API compatibility edit was needed because PO-7 and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show that V1 changes only internal branch
predicates and leaves method signatures, registry entries, and dispatch shapes
unchanged.

## Verification status

The FVK proof is constructed, not machine-checked. Per the benchmark
instructions, no tests, Python, `kompile`, `kast`, or `kprove` were run. The
artifact commands in `fvk/PROOF.md` are recorded for a future executable
environment only.
