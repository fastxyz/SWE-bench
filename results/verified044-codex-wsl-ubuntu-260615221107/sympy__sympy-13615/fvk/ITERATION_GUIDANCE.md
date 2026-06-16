# FVK Iteration Guidance

Status: V2 source edits applied; proof constructed, not machine-checked.

## Decisions

G-001. Keep the V1 generic `Set._complement` partition.
Justification: fixes F-001 and discharges PO-001 and PO-003.

G-002. Keep the V1 `ComplexRegion._contains` symbolic-condition handling.
Justification: fixes F-002 and discharges PO-004.

G-003. Revise the V1 finite-minus-finite special case.
Justification: F-003 shows V1 still had an unsound case when a right-hand symbol
could later equal a numeric residual. V2 now uses the PO-002
possible-subtrahend rule.

G-004. Do not preserve the legacy finite-set expectation described in F-004.
Justification: PO-006 shows it conflicts with the current issue's public intent
that symbolic values can later denote concrete values.

## Code Changes From V1 to V2

- `repo/sympy/sets/sets.py`: replaced the finite-minus-finite residual logic
  with a sound partition plus `B_possible` pruning.
- `repo/sympy/sets/fancysets.py`: unchanged from V1; the audit confirms the V1
  change is required by F-002 and PO-004.

## Suggested Tests For A Future Environment

Do not add tests in this benchmark. In a normal development environment, add or
update tests for:

- `Complement(FiniteSet(x, y, 2), Interval(-10, 10))` returning an unevaluated
  complement of `{x, y}` against the interval.
- `ComplexRegion(Interval(0, 10) * Interval(0, 10)).contains(x)` not returning
  `S.true`.
- `Complement(FiniteSet(x, y, 3, 33), C)` preserving `{x, y}` conditionally and
  keeping `33` definitely.
- `Complement(FiniteSet(a, b), FiniteSet(a, c))` retaining `a` and `c` in the
  residual subtrahend of `b`.
- `Complement(FiniteSet(1, 2, x), FiniteSet(x, y, 2, 3))` retaining `x` and `y`
  as possible removers of `1`, while pruning definitely unequal `2` and `3`.

## Next Verification Step

When execution is available, materialize the abstract claims in
`fvk/PROOF_OBLIGATIONS.md` into K files and run:

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kprove fvk/sympy-sets-complement-spec.k
```

Keep all tests until the machine check returns `#Top`.
