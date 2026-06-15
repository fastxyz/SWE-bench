# Intent Spec

Status: constructed from public evidence; no hidden tests or execution used.

## Required Behavior

I-001. Creating a `Quantity` from a NumPy half-precision floating value without
an explicit `dtype` must preserve `float16` dtype.

Evidence: `benchmark/PROBLEM.md` reports that `(np.float16(1) * u.km).dtype`
currently becomes `dtype('float64')`, while other floating dtypes keep their
dtype.

I-002. The dtype preservation rule should cover every NumPy inexact dtype, not
only the concrete `float16` example.

Evidence: the public hint says the old check used
`np.can_cast(np.float32, value.dtype)` and that "It does seem reasonable to
allow every inexact type."

I-003. Existing documented default behavior for non-inexact inputs should stay
unchanged: if no `dtype` is supplied, inputs that cannot represent float, such
as integer and bool, are converted to float.

Evidence: `Quantity.__new__` docstring says that when `dtype` is not provided
it is determined from the input, except inputs that cannot represent float are
converted to float. Public tests in `test_preserve_dtype` assert explicit dtype
is honored, integer quantities copy to float by default, `float32` is
preserved, and object Decimal is converted to float unless `dtype=object` is
explicit.

I-004. Explicit `dtype` must continue to override default dtype inference.

Evidence: `Quantity.__new__` docstring and `test_preserve_dtype` both state
that explicit `dtype` is used.

I-005. No public API signature, unit multiplication protocol, or test file
should be changed for this issue.

Evidence: the problem asks for a targeted source fix and forbids modifying
tests. Unit multiplication already delegates numeric operands to
`Quantity(m, self)`, so the intended behavior can be fixed in `Quantity`
construction.
