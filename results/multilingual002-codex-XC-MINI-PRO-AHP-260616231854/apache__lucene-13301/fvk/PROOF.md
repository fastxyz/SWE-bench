# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The K claims in `fvk/geo-equality-spec.k` prove, for each audited same-class object
pair:

```text
equals(a, b) == true => hash(a) == hash(b)
```

and include signed-zero discriminator claims showing that different signed-zero bit
keys make equality false.

## Proof Sketch

1. Model every finite `float` and `double` by its hash-relevant canonical bit key.
   This model distinguishes `-0.0` and `+0.0`, satisfying PO-2.
2. `Float.compare`/`Double.compare` equality is represented as key equality.
3. `Float.hashCode`, `Double.hashCode`, and boxed-double hashing are represented as
   deterministic functions of the same key.
4. For `XYPoint`, equality true gives `X1 == X2` and `Y1 == Y2`; substituting those
   equalities into `31 * hash(X) + hash(Y)` makes both hashes equal.
5. For `XYCircle`, equality true gives equality of `X`, `Y`, and `R`; substituting
   those equalities into `31 * (31 * hash(X) + hash(Y)) + hash(R)` makes both hashes
   equal.
6. `XYRectangle` follows the same field-substitution proof over its existing
   `Float.compare` equality and `Float.floatToIntBits` hash formula.
7. `Point`, `Circle`, and `Rectangle2D` follow the same substitution proof with
   double keys and their existing hash formulas.
8. If any compared field has the `-0.0` key on one side and the `+0.0` key on the
   other, the key equality premise is false; equality returns false, so no equal
   objects with unequal hashes are produced.

No loops or recursion are involved, so no circularity invariant is required.

## Machine-Check Commands Not Run

The task forbids running K tooling. These are the commands that would be used later:

```sh
cd fvk
kompile mini-java-float-equality.k --backend haskell
kast --backend haskell geo-equality-spec.k
kprove geo-equality-spec.k
```

Expected result if the constructed claims and mini semantics parse and discharge:
`#Top`.

## Residual Risk

This proof depends on the adequacy of the bit-key abstraction for the audited
property. It intentionally does not prove unrelated geometric predicates, object
construction validation, performance, or termination. Test removal is not recommended
without machine-checking.
