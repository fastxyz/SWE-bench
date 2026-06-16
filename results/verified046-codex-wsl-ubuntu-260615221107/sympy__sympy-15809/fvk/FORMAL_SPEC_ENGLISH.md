# Formal Spec English

Status: constructed, not machine-checked.

1. Claim `MIN-EMPTY`: running the modeled `MinMaxBase.__new__` constructor for
   class `Min` with the empty argument list returns `oo`.

2. Claim `MAX-EMPTY`: running the modeled `MinMaxBase.__new__` constructor for
   class `Max` with the empty argument list returns `-oo`.

3. Claim `NONEMPTY-FRAME`: running the modeled constructor for either class
   with at least one argument reaches the same abstract non-empty constructor
   tail, represented by `tailResult(class, args)`. This claim does not prove
   the full non-empty Min/Max simplification algorithm; it proves the V1 edit
   did not redirect non-empty calls away from that algorithm.

4. There are no loops or recursive calls in the audited branch, so no
   circularity/loop invariant claim is required.

