# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK run audits the V1 source change for `sympy__sympy-15809`:

- File under audit: `repo/sympy/functions/elementary/miscellaneous.py`
- Function under audit: `MinMaxBase.__new__`, as used by public `Min` and `Max`
- Changed behavior: zero-argument constructor calls
- Frame behavior: non-empty calls continue into the existing constructor body

There are no loops or recursive calls in the audited branch.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Zero-argument Min() and Max()" | Empty argument lists are in scope. | Encoded by empty-argument claims. |
| E2 | `benchmark/PROBLEM.md` | "`Min()` and `Max()` with no arguments raise `ValueError...`" | The previous exception is the defect. | Finding F1. |
| E3 | `benchmark/PROBLEM.md` | "return `oo` and `-oo`, respectively" | `Min()` returns `oo`; `Max()` returns `-oo`. | PO1, PO2. |
| E4 | `benchmark/PROBLEM.md` | "valid answers mathematically" | Use extended-real empty-set identities. | PO1, PO2. |
| E5 | source | `Min.identity = S.Infinity`; `Max.identity = S.NegativeInfinity` | Subclass identities already encode requested values. | V1 uses `cls.identity`. |
| E6 | source | `LatticeOp` identity contract | Empty lattice operations may reduce to identity. | Supports placement in constructor. |
| E7 | public tests | `raises(ValueError, lambda: Min())`, `raises(ValueError, lambda: Max())` | Legacy tests conflict with issue. | SUSPECT; not used as oracle. |
| E8 | source diff | V1 changes only the initial `if not args` branch. | Non-empty path must be preserved. | PO4. |

## Intended Contract

For calls through `MinMaxBase.__new__` with the concrete subclasses `Min` and
`Max`:

- If `cls is Min` and `args` is empty, return `Min.identity`, which is
  `S.Infinity` (`oo`).
- If `cls is Max` and `args` is empty, return `Max.identity`, which is
  `S.NegativeInfinity` (`-oo`).
- If `args` is non-empty, follow the existing non-empty constructor logic:
  sympification, identity/zero filtering, optional collapse, local-zero search,
  single-argument return, or expression construction.

## Formal Model

The formal core is in:

- `fvk/mini-python.k`
- `fvk/minmax-spec.k`

The mini semantics abstracts the non-empty constructor tail as
`tailResult(C, AS)`. This abstraction is property-complete for the audited
change because the changed property is the empty-vs-non-empty branch and the
observable empty return value. A passing instance (`construct(MinCls, .Args)`)
and a failing legacy instance (the old guard raising instead of returning an
identity) remain distinguishable in the model.

## Claims

1. `MIN-EMPTY`: `construct(MinCls, .Args)` reaches `oo`.
2. `MAX-EMPTY`: `construct(MaxCls, .Args)` reaches `negOo` (the model name for
   `-oo`).
3. `NONEMPTY-FRAME`: `construct(C, consArg(A, REST))` reaches the unchanged
   abstract non-empty tail `tailResult(C, consArg(A, REST))`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and
`fvk/SPEC_AUDIT.md` checks them against `fvk/INTENT_SPEC.md`. All obligations
needed to justify V1 are marked PASS. No ambiguous or implementation-only
postcondition is used to justify keeping V1 unchanged.

