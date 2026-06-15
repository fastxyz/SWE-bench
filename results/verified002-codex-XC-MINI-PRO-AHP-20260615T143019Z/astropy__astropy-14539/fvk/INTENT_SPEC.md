# Intent Spec

Status: intent-only; written before accepting candidate behavior as correct.

1. `FITSDiff` reports differences only when differences exist.
2. Self-comparison of a FITS file is in domain and must be reflexive:
   comparing a file to itself must not produce any data differences.
3. The public reproducer makes a binary table VLA column with `format='QD'`.
   Therefore `Q` VLA descriptor columns are in scope.
4. `P` and `Q` are variants of FITS VLA descriptors. They should differ in
   descriptor storage width, not in the content-comparison predicate used by
   `FITSDiff`.
5. For VLA row values, row shape is part of row equality.
6. Floating row values should follow FITSDiff's existing floating comparison
   policy, including tolerance and matching invalid-value handling.
7. Non-VLA comparison behavior and public APIs should remain unchanged.
