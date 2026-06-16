# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-001: Generic finite minuend partition

Unit: `Set._complement(self, other)` when `other` is `FiniteSet`.

Claim: For each element `el` of the finite minuend `other`, the returned set
classifies `el` according to `sympify(self.contains(el))`:

- `S.true`: `el` is not present in the result.
- `S.false`: `el` is present in the definite finite part.
- any other value: `el` is present only inside
  `Complement(FiniteSet(...), self, evaluate=False)`.

Postcondition: the result denotes `A_F union (A_U \ self)` and never treats
`A_U` as definitely outside `self`.

Provenance: I-1, I-2, E-1, E-2.

## PO-002: Finite-minus-finite possible-subtrahend pruning

Unit: `FiniteSet._complement(self, other)` when `other` is `FiniteSet`, with
`self` as the subtrahend and `other` as the minuend.

Claim: The code first applies the same membership partition as PO-001. For the
unknown finite part `A_U`, it constructs
`B_possible = {b in self | exists u in A_U, Eq(b, u) is not S.false}` and returns
`A_F union (A_U \ B_possible)`.

Postcondition: every right-hand finite element that can affect an undecidable
left-hand element remains in the residual complement; every pruned right-hand
element is definitely unequal to all residual unknowns.

Provenance: I-2, I-4, E-2, E-4.

## PO-003: Interval mixed symbolic/numeric example

Unit path: `Complement(FiniteSet(x, y, 2), Interval(-10, 10))`.

Claim: `Interval._complement` reaches the generic finite branch because the
finite minuend has numeric elements. The partition classifies `2` as
definitely contained and `x`, `y` as unknown, so the result is
`Complement(FiniteSet(x, y), Interval(-10, 10), evaluate=False)`.

Provenance: I-1, I-2, E-1, E-2.

## PO-004: ComplexRegion containment preserves symbolic conditions

Unit: `ComplexRegion._contains(self, other)`.

Claim: For every rectangular or polar product-set component, the coordinate
containment condition is computed as a SymPy Boolean expression `c_i`. The
method returns:

- `S.true` only if some `c_i is S.true`;
- `S.false` only if every `c_i is S.false`;
- otherwise `Or(*non_false_c_i)`.

Postcondition: symbolic coordinate conditions are never coerced to Python
`True`.

Provenance: I-3, E-3.

## PO-005: Numeric frame condition

Unit: both finite complement branches.

Claim: If all finite minuend elements have membership status `S.true` or
`S.false`, and no unknowns exist, the result is exactly `FiniteSet(*known_false)`.

Postcondition: numeric finite differences such as `{1, 2, 3} \ {2}` still reduce
to `{1, 3}`.

Provenance: I-5.

## PO-006: Suspect legacy finite-set expectation is not preserved

Unit: `FiniteSet._complement(self, other)` when a residual unknown may equal a
syntactically shared right-hand symbol.

Claim: For `Complement(FiniteSet(1, 2, x), FiniteSet(x, y, 2, 3))`, residual
`1` is unknown against `x` and `y`, so both remain in `B_possible`; `2` and `3`
are definitely unequal to `1` and are pruned.

Postcondition: the sound residual is
`Complement(FiniteSet(1), FiniteSet(x, y), evaluate=False)`, not
`Complement(FiniteSet(1), FiniteSet(y), evaluate=False)`.

Provenance: I-2, I-4, F-004.

## K-shaped Claims

The proof obligations above correspond to the following abstract claims over a
minimal set-complement model. These are written here as constructed obligations,
not as executed K artifacts.

```k
claim <k> diffFinite(A, B) => assemble(knownFalse(A, B), unknown(A, B), B) </k>
  requires finite(A)
  ensures resultDenotes(A minus B)
```

```k
claim <k> diffFiniteFinite(A, B)
      => assemble(knownFalse(A, B), unknown(A, B),
                  possibleSubtrahend(unknown(A, B), B)) </k>
  requires finite(A) andBool finite(B)
  ensures resultDenotes(A minus B)
```

```k
claim <k> complexContains(C, z)
      => truthOrSymbolicOr(componentContains(C, z)) </k>
  ensures result ==K true iff any component condition is true
   andBool result ==K false iff all component conditions are false
   andBool symbolic conditions are preserved otherwise
```
