# Formal Spec English

This paraphrases the K claims in `quantity-dtype-spec.k`.

QD-001. On the unit multiplication construction path, the unit object delegates
numeric operands to `Quantity(m, unit)` without supplying an explicit dtype.
Therefore a `float16` numeric operand reaches the non-`Quantity`, no-explicit
dtype branch of `Quantity.__new__`.

QD-002. For any input dtype `D`, if `D` is an inexact NumPy dtype and no
explicit dtype is supplied, the non-`Quantity` branch returns a `Quantity` whose
dtype is `D`.

QD-003. In particular, for `D = float16`, the non-`Quantity` branch returns a
`Quantity` whose dtype is `float16`.

QD-004. For any existing `Quantity` input with dtype `D`, if `D` is inexact,
`copy=True`, and no explicit dtype is supplied, the copied `Quantity` keeps
dtype `D`.

QD-005. For any existing `Quantity` input with `copy=False` and no explicit
dtype, the constructor returns the existing dtype unchanged.

QD-006. For any constructor input where an explicit dtype `E` is supplied, the
result dtype is `E`.

QD-007. For non-inexact, non-structured default inputs such as integer, bool, or
numeric object dtype, the default result dtype is Python float / NumPy
`float64`.

QD-008. Structured dtypes continue to bypass the default float coercion through
the existing `dtype.fields` exception.

QD-009. The implementation does not change public signatures, virtual dispatch
shape, or test files.
