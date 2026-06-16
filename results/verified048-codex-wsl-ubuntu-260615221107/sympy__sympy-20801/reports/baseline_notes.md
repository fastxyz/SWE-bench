# Baseline Notes

## Root cause

`Float.__eq__` in `sympy/core/numbers.py` sympifies the right-hand operand and then immediately handles the zero-Float case with `return not other`. Since `S.false` is a falsey SymPy Boolean, `S(0.0) == S.false` returned `True` before the later Boolean guard had a chance to reject Boolean operands.

This made Float equality asymmetric with `S.false == S(0.0)`, which uses the Boolean/Basic equality path and returns `False`. It was also inconsistent with the existing numeric equality behavior documented by the issue for `S(0) == S.false`.

## Files changed

`repo/sympy/core/numbers.py`

Added an early `isinstance(other, Boolean)` guard in `Float.__eq__` before sympification and before the zero shortcut. This makes already-SymPy Booleans compare unequal to Floats before any truth-value shortcut can treat `S.false` as numeric zero, while leaving the existing post-sympification comparison flow in place for other inputs.

## Assumptions and rejected alternatives

I interpreted the final sentence of the issue as intending `S(0.0) == S.false` to return `False`, matching both the issue title and the `S(0) == S.false` examples. The wording says "return True as well", but the surrounding examples point the other way.

I considered changing `BooleanAtom.__eq__` or `Basic.__eq__`, but rejected that because the asymmetry is caused by the Float-specific zero shortcut and the reverse comparison already returns the expected result.

I considered adding broader special handling for native Python `False`/`True` in Float equality to mirror integer behavior more explicitly. I rejected that as outside the reported issue because it would change additional public comparisons beyond the already-SymPy Boolean operands reported here.
