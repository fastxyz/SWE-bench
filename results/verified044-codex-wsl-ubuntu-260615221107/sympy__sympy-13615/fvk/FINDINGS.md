# FVK Findings

Status: constructed from public intent and source inspection; not
machine-checked. No tests or project code were run.

## F-001: Generic finite complement treated unknown membership as outside

Classification: code bug, fixed in V1 and retained in V2.

Evidence: E-1 and E-2 in `fvk/SPEC.md`.

Input: `Complement(FiniteSet(x, y, 2), Interval(-10, 10))`.

Observed before fix: the generic `Set._complement` branch kept any element for
which `self.contains(el) != True`, so symbolic `x` and `y` were returned as a
bare finite set after numeric `2` was removed.

Expected: `Complement(FiniteSet(x, y), Interval(-10, 10), evaluate=False)`.
The symbols remain conditional because they might later denote interval
members.

Resolution: `Set._complement` now partitions finite elements into definitely
contained, definitely not contained, and unknown; unknowns remain under an
unevaluated `Complement`.

Proof obligations: PO-001 and PO-003.

## F-002: `ComplexRegion.contains(symbol)` collapsed symbolic conditions to true

Classification: code bug, fixed in V1 and retained in V2.

Evidence: E-3 in `fvk/SPEC.md`.

Input: `C = ComplexRegion(Interval(0, 10) * Interval(0, 10))`,
`C.contains(x)`.

Observed before fix: `_contains` tested a SymPy `And(...)` with Python
truthiness and returned `True`.

Expected: a symbolic condition over `re(x)` and `im(x)`, or another non-true
undecidable Boolean expression.

Resolution: `ComplexRegion._contains` now accumulates component containment
conditions and returns `S.true` only for definite true components, `S.false` only
when all components are definitely false, and otherwise an `Or` of the remaining
symbolic conditions.

Proof obligations: PO-004.

## F-003: V1 finite-minus-finite retained a residual unsound compatibility case

Classification: code bug found by FVK audit, fixed in V2.

Evidence: E-2 and E-4 in `fvk/SPEC.md`.

Input: `Complement(FiniteSet(1, x), FiniteSet(x))`.

Observed in V1 reasoning: V1 could return bare `{1}` because its finite-finite
patch only retained syntactically shared symbolic right-hand elements when the
remaining left-hand element also had a `Symbol`. That excludes the case where a
symbolic right-hand element may later denote numeric `1`.

Expected: `{1} \ {x}`. If `x = 1`, the complement is empty; therefore `{1}` is
not a sound unconditional simplification.

Resolution: `FiniteSet._complement` now partitions the finite minuend by
membership in the finite subtrahend and retains every finite subtrahend element
that may equal an undecidable minuend element. For
`Complement(FiniteSet(a, b), FiniteSet(a, c))`, this yields `{b} \ {a, c}`.

Proof obligations: PO-002.

## F-004: Legacy finite-set simplification expectations are suspect

Classification: stale public-test risk, not a blocker for V2.

Evidence: E-2 and E-4 in `fvk/SPEC.md`.

Input family: finite symbolic differences where a right-hand symbol also appears
syntactically in the left-hand set, for example
`Complement(FiniteSet(1, 2, x), FiniteSet(x, y, 2, 3))`.

Observed legacy shape: older source tests in this checkout expect a more
aggressive simplification that can drop `x` from the residual subtrahend.

Expected under the current issue intent: `x` must remain relevant to residual
`1` because `x` may later denote `1`; definitely unequal numeric right-hand
elements such as `2` and `3` may be pruned. The sound residual is
`Complement(FiniteSet(1), FiniteSet(x, y), evaluate=False)`.

Resolution: V2 follows the current issue intent. The old expectation is marked
SUSPECT because it conflicts with the issue's statement that symbolic values may
later denote concrete values.

Proof obligations: PO-002 and PO-006.

## Residual Risks

R-001. The proof is constructed, not machine-checked. The exact commands are
listed in `fvk/PROOF.md`; they were not run.

R-002. Termination is not separately proved. The audited code paths contain only
finite iteration over finite `.args`/`psets` collections supplied by existing
SymPy objects.
