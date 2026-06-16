# FVK Spec for sympy__sympy-13615

Status: constructed from public intent and source inspection; not machine-checked.
No tests, Python, or K tooling were run.

## Scope

Audited units:

- `Set._complement(self, other)` for the `other is FiniteSet` branch. This is
  the generic path for `A \ B` when `A` is finite and `B` is an arbitrary set.
- `FiniteSet._complement(self, other)` for `other is FiniteSet`. This is the
  finite-minus-finite specialization for `A \ B`.
- `ComplexRegion._contains(self, other)` in rectangular and polar form.

No loops are present in the audited code paths.

## Intent Spec

I-1. Mixed symbolic/numeric finite set minus interval:
The issue states that `Complement(FiniteSet(x, y, 2), Interval(-10, 10))`
currently returns `{x, y}`, but expected output is `{x, y} \ [-10, 10]`.
Obligation: remove the definitely contained numeric `2`, but keep symbolic
`x` and `y` under a complement because their interval membership is not known.

I-2. Symbols are not fixed numbers:
The issue notes that the result changes if symbols later denote numbers such as
`x = 5`, `y = 12`.
Obligation: undecidable membership is not evidence that a symbolic element is
outside the subtrahend.

I-3. Other set types have the same membership problem:
The issue gives `Complement(FiniteSet(x, y, 3, 33), ComplexRegion(I * I))`
returning `{33}` and identifies `C.contains(x) == True` as suspect.
Obligation: `ComplexRegion.contains(symbol)` must return a symbolic or
undecidable condition unless membership is definitely true or false.

I-4. Finite-minus-finite symbolic equality:
The issue gives `Complement(FiniteSet(a, b), FiniteSet(a, c)) == {b} \ {c}`
and says it is incorrect if `a = b`.
Obligation: after removing a syntactically shared element, the right-hand finite
set must still contain elements that could equal any remaining symbolic element.

I-5. Frame conditions:
Purely numeric finite-set subtraction should still simplify to a finite set.
No public API signature, method name, return container family, or test file is
to be changed.

## Public Evidence Ledger

E-1, prompt: "`{x, y} \ [-10,10]` is expected as output." Encodes I-1.

E-2, prompt: "If `x` and `y` denote `Symbol`s and not `Number`s, they remain in
the set `a` when any numbers are removed. The result will be different when
they denote numbers." Encodes I-2.

E-3, prompt: "It affects other types of sets than intervals as well" and
"C.contains(x) True." Encodes I-3.

E-4, prompt: "`{b} \ {c}` ... incorrect if `a = b`." Encodes I-4.

E-5, implementation/API: `Complement(A, B)` delegates to `B._complement(A)`;
`contains` returns `S.true`, `S.false`, or a symbolic condition. Used only to
model control flow, not as intent.

## Formal Model

For a set `B` and finite minuend `A = {a_i}`, define membership status:

- `M_B(a) = T` iff `sympify(B.contains(a)) is S.true`.
- `M_B(a) = F` iff `sympify(B.contains(a)) is S.false`.
- `M_B(a) = U` otherwise.

Partition `A` into:

- `A_T = {a in A | M_B(a) = T}`
- `A_F = {a in A | M_B(a) = F}`
- `A_U = {a in A | M_B(a) = U}`

Required result for finite `A \ B`:

- If `A_U` is empty, return `FiniteSet(*A_F)`.
- If `A_F` is empty, return `Complement(FiniteSet(*A_U), B, evaluate=False)`.
- Otherwise return `Union(FiniteSet(*A_F), Complement(FiniteSet(*A_U), B,
  evaluate=False))`.

For finite `B`, a sound simplification may replace `B` in the complement of
`A_U` by `B_possible = {b in B | exists u in A_U such that Eq(b, u) is not
S.false}`. Elements outside `B_possible` are definitely unequal to every
undecidable minuend element and cannot affect the conditional remainder.

For `ComplexRegion._contains`, each rectangular component contributes:

`c_i = And(x_set_i.contains(re(other)), y_set_i.contains(im(other)))`

and each polar component contributes:

`c_i = And(r_set_i.contains(r(other)), theta_set_i.contains(theta(other)))`

Required result:

- Return `S.true` if any `c_i is S.true`.
- Return `S.false` if every `c_i is S.false`.
- Otherwise return `Or(*c_i for c_i not S.false)`.

## Adequacy Audit

A-1. The formal finite-set partition directly encodes I-1 and I-2: symbolic
unknowns are not emitted as bare known survivors.

A-2. The finite-minus-finite `B_possible` rule directly encodes I-4: if `a`
could equal remaining `b`, then `a` remains in the subtrahend of `{b}`.

A-3. The `ComplexRegion._contains` result rule directly encodes I-3: Python
truthiness is not used to convert symbolic coordinate conditions to `True`.

A-4. The spec preserves I-5 for numeric finite differences because all numeric
memberships with status `T` are removed and all status `F` elements are returned
as a `FiniteSet` when no unknowns remain.

No adequacy failures remain after the V2 finite-minus-finite revision.

## Public Compatibility Audit

Changed symbols keep their public signatures:

- `Set._complement(self, other)`: unchanged signature, internal method.
- `FiniteSet._complement(self, other)`: unchanged signature, internal method.
- `ComplexRegion._contains(self, other)`: unchanged signature, internal method.

Return types stay within existing SymPy set/boolean families: `FiniteSet`,
`Complement`, `Union`, `S.true`, `S.false`, or symbolic Boolean expressions.
No public callers or overrides require signature updates.
