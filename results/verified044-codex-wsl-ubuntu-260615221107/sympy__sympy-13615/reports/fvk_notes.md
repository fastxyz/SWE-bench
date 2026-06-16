# FVK Notes

## Decisions and Traceability

The V1 `Set._complement` generic finite-set partition stands. This is justified
by `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-001/PO-003: the
issue requires known numeric members to be removed while symbolic members whose
membership is undecidable remain under `Complement`.

The V1 `ComplexRegion._contains` change stands. This is justified by F-002 and
PO-004: the public issue identifies `C.contains(x) == True` as part of the
problem, and the proof obligation requires symbolic coordinate conditions to be
returned as symbolic Boolean expressions rather than coerced through Python
truthiness.

The V1 finite-minus-finite patch was revised. F-003 identified that V1 still
allowed an unsound compatibility-oriented simplification: a right-hand symbol
could be dropped even when it might later equal a numeric residual, such as
`Complement(FiniteSet(1, x), FiniteSet(x))`. PO-002 required retaining every
finite subtrahend element that may equal an undecidable residual minuend
element, while pruning only definitely unequal subtrahend elements. The source
now builds `possible` using `Eq(i, j, evaluate=True) is not S.false`.

The audit intentionally does not preserve the older finite-set simplification
shape described in F-004. PO-006 shows that dropping `x` from the residual
subtrahend of `Complement(FiniteSet(1, 2, x), FiniteSet(x, y, 2, 3))` conflicts
with the current issue's public intent: if `x = 1`, the result changes.

## Files Changed

`repo/sympy/sets/sets.py`

- Kept the V1 generic `Set._complement` fix for finite minuends.
- Replaced the finite-minus-finite residual logic with the FVK V2
  `B_possible` rule from PO-002.

`repo/sympy/sets/fancysets.py`

- Kept the V1 `ComplexRegion._contains` fix because it discharges PO-004.

## Verification Status

The proof is constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run, as required by the benchmark instructions. No test files were
modified.
