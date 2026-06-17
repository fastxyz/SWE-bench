# Public Compatibility Audit

## Changed Public Symbol

`sympy.core.numbers.Rational.__new__(cls, p, q=None, gcd=None)`

## Signature

No signature change.

## Return Shape

No new public return category. The constructor still returns `Integer`, `Rational`, `S.Half`, `S.ComplexInfinity`, `S.NaN`, or raises existing errors according to the same downstream branches.

## Call Sites and Overrides

The V1 patch changes only local normalization arithmetic inside `Rational.__new__`. It does not add arguments, call virtual methods with new keywords, change storage layout, or alter subclass dispatch.

## Compatibility Result

Pass. No public callsite or override update is required.
