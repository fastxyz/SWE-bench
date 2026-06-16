# FVK Notes

## Source Decision

I kept the V1 source fix unchanged. `fvk/FINDINGS.md` F1 identifies the
reported bug as the old empty-argument `ValueError`, and `fvk/PROOF_OBLIGATIONS.md`
PO1 and PO2 require `Min()` and `Max()` to return the subclass identities
`S.Infinity` and `S.NegativeInfinity`. V1 already does that with
`return cls.identity`.

## Why No Additional Code Edit Was Made

- F1 is resolved by V1: the empty branch exits with `cls.identity`.
- F3 plus PO4 show that non-empty calls skip the changed branch and continue
  into the same constructor logic as before.
- PO5 shows the public constructor signature and dispatch shape were not
  changed.

I considered changing the return to `sympify(cls.identity)` to mirror the base
`LatticeOp` constructor more literally, but rejected it as unnecessary here:
both concrete identities are already SymPy singleton objects, and the proof
obligations only require the concrete public `Min` and `Max` results.

## Test Evidence

`fvk/FINDINGS.md` F2 marks the visible tests expecting `ValueError` as SUSPECT
legacy evidence because they encode the behavior the issue asks to remove.
Those tests should be updated when test edits are allowed, but this task
explicitly forbids modifying test files.

## Verification Limits

The proof artifacts are constructed, not machine-checked, as required by PO6.
I did not run tests, Python, `kompile`, `kast`, or `kprove`. The mini-K model
abstracts the non-empty constructor tail, so it justifies preserving that path
around the edit rather than proving the whole SymPy Min/Max simplification
algorithm.
