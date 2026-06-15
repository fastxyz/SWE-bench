# INTENT SPEC

Status: intent-only, written before accepting candidate behavior as the spec.

Required behavior from public evidence:

1. `identify_format("write", Table, "bububu.ecsv", None, [], {})` must not raise
   `IndexError`.
2. For that call, the FITS identifier must be a non-match because the filepath
   has no FITS extension and no FITS object argument is present.
3. Existing positive FITS identification by file signature, FITS filename
   suffix, and FITS HDU object should be preserved.
4. The registry call protocol and `is_fits` signature should not change.

Observed candidate behavior is checked against these obligations in
`SPEC_AUDIT.md`; it is not used as an independent source of expected behavior.
