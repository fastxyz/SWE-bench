# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Proof Summary

The V2 patch satisfies the intent spec by enforcing a three-way membership
discipline:

- definitely contained finite elements are removed;
- definitely not contained finite elements remain as ordinary finite members;
- undecidable finite elements remain conditional under an unevaluated
  `Complement`.

For finite-minus-finite, V2 additionally prunes only those right-hand finite
elements that are definitely unequal to every undecidable left-hand element. For
`ComplexRegion.contains`, V2 returns definite booleans only from definite
coordinate containment results and otherwise returns a symbolic `Or`.

## PO-001 Proof: Generic Finite Minuend Partition

The code iterates over every element `el` in `other`.

Case 1: `sympify(self.contains(el)) is S.true`.
The loop executes `continue`, so `el` is added to neither `known` nor `unknown`.
It is absent from the returned set, matching `el in A_T`.

Case 2: the membership result is `S.false`.
The loop appends `el` to `known`. If there are no unknowns, the function returns
`FiniteSet(*known)`. If unknowns exist, it returns a union whose definite part is
`FiniteSet(*known)`. Thus every definitely outside element is preserved.

Case 3: the membership result is neither `S.true` nor `S.false`.
The loop appends `el` to `unknown`. The function returns
`Complement(FiniteSet(*unknown), self, evaluate=False)` either alone or unioned
with the definite finite part. Thus unknown elements are not asserted to be
outside `self`.

These cases are exhaustive over the code's branch condition and prove PO-001.

## PO-002 Proof: Finite-Minus-Finite Possible Subtrahend

The finite-minus-finite branch first repeats the PO-001 partition with
`self.contains(i)` where `self` is the finite subtrahend and `other` is the
finite minuend. Therefore `known` and `unknown` have the same meanings as in
PO-001.

For every subtrahend element `i`, the code compares it with every unknown
minuend element `j` by `Eq(i, j, evaluate=True)`.

If all such equalities are `S.false`, then `i` cannot remove any element in the
unknown residual. Pruning `i` from the residual subtrahend preserves the
denotation of `unknown \ self`.

If any equality is not `S.false`, then `i` may remove some residual unknown
under a later substitution. The code appends `i` to `possible`, so that possible
removal remains represented in the unevaluated complement.

The returned residual is `Complement(FiniteSet(*unknown), FiniteSet(*possible),
evaluate=False)`, optionally unioned with the definite `known` finite part. This
proves PO-002.

## PO-003 Proof: Reported Interval Example

For `Complement(FiniteSet(x, y, 2), Interval(-10, 10))`, reduction calls
`Interval._complement(FiniteSet(x, y, 2))`. Because the finite set has a numeric
member, that method delegates to `Set._complement`.

`Interval(-10, 10).contains(2)` is `S.true`, so `2` is removed.
`Interval(-10, 10).contains(x)` and `.contains(y)` are symbolic conditions for
ordinary symbols, so `x` and `y` are placed in `unknown`.

PO-001 then yields `Complement(FiniteSet(x, y), Interval(-10, 10),
evaluate=False)`, which matches the issue's expected form.

## PO-004 Proof: ComplexRegion Contains

In both rectangular and polar branches, V2 constructs a SymPy Boolean condition
`c` for each product-set component using public `contains` calls.

If any `c is S.true`, the method returns `S.true`; this is exactly the
definitely-contained case.

If no `c is S.true`, each non-`S.false` condition is appended to `unknown`.
When the list is empty, every component is definitely false and the method
returns `S.false`.

When the list is nonempty, the method returns `Or(*unknown)`. No Python
truthiness test is applied to a symbolic `And`, so symbolic membership is
preserved. This proves PO-004.

## PO-005 Proof: Numeric Frame

When all finite membership checks are definite, `unknown` is empty. Both finite
branches return `FiniteSet(*known)`, where `known` is exactly the set of
minuend elements whose membership in the subtrahend was `S.false`. Thus numeric
finite subtraction keeps existing behavior such as `{1, 2, 3} \ {2} == {1, 3}`.

## PO-006 Proof: Legacy Expectation Audit

For `Complement(FiniteSet(1, 2, x), FiniteSet(x, y, 2, 3))`, the finite
subtrahend contains `2` and `x` definitely, so those minuend elements are
removed. The residual `1` is undecidable against `x` and `y`; it is definitely
unequal to `2` and `3`.

The possible-subtrahend loop therefore keeps `x` and `y`, and prunes `2` and
`3`. The residual is `Complement(FiniteSet(1), FiniteSet(x, y),
evaluate=False)`. Dropping `x` would be unsound under the public intent because
substitution `x = 1` changes the result.

## Machine-Check Commands

The benchmark explicitly forbids running K tooling here. If a K formalization is
materialized from `fvk/PROOF_OBLIGATIONS.md`, the commands to run later would be:

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kprove fvk/sympy-sets-complement-spec.k
```

Expected result after materialization and discharge: `#Top`.

## Test Recommendation

No test removal is recommended. The proof is constructed, not machine-checked,
and this benchmark forbids editing tests. Tests that should exist or remain:

- mixed finite symbols/numbers minus interval;
- finite symbols/numbers minus `ComplexRegion`;
- finite-minus-finite residual equality such as `{a, b} \ {a, c}`;
- numeric finite differences to preserve the frame condition.
