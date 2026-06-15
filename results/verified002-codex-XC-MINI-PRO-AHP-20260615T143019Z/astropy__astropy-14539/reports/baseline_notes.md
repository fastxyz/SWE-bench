# Baseline Notes

## Root cause

`TableDataDiff._diff` has a special row-wise comparison path for FITS
variable-length array columns, but it only recognized `P`-format VLA
descriptors. `Q`-format VLA descriptors use the same variable-length array
data model with 64-bit descriptors, but they fell through to the generic
`np.where(arra != arrb)` comparison. For object arrays whose elements are
variable-length ndarray values, that generic comparison can mark rows as
different even when the arrays hold identical values, including when comparing
a file with itself.

## Files changed

`repo/astropy/io/fits/diff.py`

Updated the table-data comparison branch to treat both `P` and `Q` FITS VLA
format codes as variable-length arrays. These columns now use the existing
row-wise `np.allclose` comparison, which compares the actual per-row array
contents and preserves the existing tolerance behavior for numeric VLA data.

## Assumptions and alternatives

I assumed `Column.format` has already been normalized by the FITS column
validation path into the local column-format classes, so checking
`col.format.format` is the precise way to identify the FITS format code.

I considered matching with substring checks such as
`"P" in col.format or "Q" in col.format`, which mirrors the old condition for
`P`. I rejected that in favor of the explicit format-code check because only a
top-level `P` or `Q` format should trigger the VLA comparison path.

I did not modify tests or execute the test suite, per the benchmark
instructions.
