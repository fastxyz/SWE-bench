# Formal Spec English

The K files are abstract and constructed, not machine-checked.

## Claims

### CLAIM WHERE-VALUE

For every in-domain `cond`, `x`, and `y`, the V2 `where` wrapper returns the
same selected data values as applying `duck_array_ops.where(cond, x, y)`.
Changing the wrapper argument order used for `apply_ufunc` does not change the
value-level `cond ? x : y` selection.

### CLAIM WHERE-KEEP-TRUE

When `keep_attrs=True`, the result attrs are copied from the first xarray object
among `x` and `y`; if neither `x` nor `y` is an xarray object with attrs, attrs
fall back to `cond`; if no xarray input has attrs, attrs are empty.

### CLAIM WHERE-KEEP-FALSE

When `keep_attrs=False`, result attrs are empty.

### CLAIM WHERE-KEEP-NONE

When `keep_attrs=None`, the wrapper resolves the policy through the global
`keep_attrs` option with this operation's default set to preserving attrs. If
the resolved value is true, `WHERE-KEEP-TRUE` applies; otherwise
`WHERE-KEEP-FALSE` applies.

### CLAIM WHERE-EXACT-JOIN

The wrapper keeps the existing exact alignment policy for dimensions and
dataset variables. Inputs that were invalid because exact alignment failed
remain invalid; valid exact-aligned inputs remain in-domain.

## No Loop Circularities

The audited change contains no loops or recursion.
