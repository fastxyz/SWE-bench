# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`repo/astropy/io/fits/diff.py`

- Added private helper `_vla_values_differ(a, b, rtol=0.0, atol=0.0)`.
- Changed the internal VLA branch condition and row predicate inside
  `TableDataDiff._diff`.

## Public API

No public function, method, class, constructor, return type, or parameter list
was changed.

`FITSDiff`, `HDUDiff`, `TableDataDiff`, `fits.printdiff`, and the command-line
`fitsdiff` entry point keep the same public call shape. The changed behavior is
limited to whether `TableDataDiff` marks VLA table rows as different.

## Callsite And Override Audit

Static search found the relevant production call path:

- `FITSDiff` constructs `TableDataDiff` via `TableDataDiff.fromdiff(...)`.
- `fits.printdiff` and the CLI construct `FITSDiff`.

No override or subclass signature is affected because the edited logic is inside
`TableDataDiff._diff` and the new helper is private.

Compatibility status: pass.
