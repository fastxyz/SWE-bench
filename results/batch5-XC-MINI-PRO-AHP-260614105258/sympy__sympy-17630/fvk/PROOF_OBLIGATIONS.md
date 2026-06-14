# PROOF OBLIGATIONS — sympy__sympy-17630

The concrete obligations that the V1/V2 fix must discharge for the contract in
`fvk/SPEC.md` to hold. Each is tagged with the claim it supports, its discharge
tier (Z3 = linear arithmetic; STRUCT = structural/rewriting; SHAPE = shape
algebra), and its status. **Constructed, not machine-checked.**

## Core obligations

| ID | Obligation | Supports | Tier | Status |
|----|------------|----------|------|--------|
| O1 | `allZeroLike(repZ(P,Q,K)) = true` for all `K ≥ 0` (every product in an all-zero entry's `vec` is a `ZeroMatrix`/identity). | REPZ | STRUCT (induction on K) | discharged |
| O2 | For a non-empty list `L` whose every element is `Z(P,Q)`: `rmId(L) = headList(L) = (Z(P,Q), .MVals)` — i.e. the `rm_id` "keep one identity" branch keeps a **`ZeroMatrix`**, because the list contains no scalar. | ADD0 | STRUCT | discharged |
| O3 | `canon((Z(P,Q), .MVals)) = Z(P,Q)` (the `unpack` rule on a singleton). | ADD0 | STRUCT | discharged |
| O4 | Shape consistency: all summands of one product entry share shape `(P,Q)`, so the kept `Z(P,Q)` has the **correct** shape `(rowblocksizes[i], colblocksizes[j])`. | ADD0 | SHAPE | discharged |
| O5 | `cols(Z(P,Q)) = Q` is **defined** (a rule exists); therefore `cols(addM(repZ(P,Q,K))) = Q`. | COLS-OK | STRUCT | discharged |
| O6 | `colsizes` maps a total `cols` over the block row ⇒ terminates with an `IntList`; no element is `s0`. | COLSIZES-OK | STRUCT (induction) | discharged |
| O7 | Repeatability composition: the result of `_blockmul` has all-`MatrixExpr` blocks (O5 over every entry), so a *second* `_blockmul`'s `colblocksizes == rowblocksizes` precondition check evaluates without `AttributeError`. | C2 | STRUCT | discharged |

## Frame / no-regression obligations (contract C3)

| ID | Obligation | Supports | Tier | Status |
|----|------------|----------|------|--------|
| O8 | The `Mul` branch is byte-for-byte unchanged: the fix guards on `mat_class == MatAdd`, so `MatMul(cls._from_args(nonmatrices), *matrices)` is still emitted for `Mul`. | C3 | STRUCT (code inspection) | discharged |
| O9 | The `Add(scalar, matrix)` branch (`nonmatrices` non-empty, `cls == Add`) is untouched — it returns at the earlier `return cls._from_args(nonmatrices + [MatAdd(*matrices).doit()])`, so the fix's new line is unreachable for it. | C3, L6 | STRUCT (control-flow) | discharged |
| O10 | Equivalence on the non-all-zero `Add` case: `MatAdd(*matrices).doit()` = `MatAdd(S.Zero, *matrices).doit()` whenever ≥1 matrix is non-`ZeroMatrix`, because `rm_id` removes the scalar `S.Zero` early (its predicate `x == 0` matches it, and the list is not all-identities). Hence the ONLY observable change is the all-`ZeroMatrix` case (O2). | C3 | STRUCT + Z3 (set-equality of arg lists) | discharged |
| O11 | No new exception: `MatAdd(*matrices).doit()` does not raise where `MatAdd(S.Zero, *matrices).doit()` did not — `MatAdd.__new__` default `check=False` performs no shape validation, and `rm_id`/`unpack` are total on the (now scalar-free) list. | C3 | STRUCT | discharged |

## Out-of-scope / escalation obligations (explicitly NOT claimed)

| ID | Obligation | Why out of scope |
|----|------------|------------------|
| E1 | `BlockMatrix.__new__` does not *enforce* the "all blocks are `MatrixExpr`" invariant when handed a `Matrix` of entries directly (it skips the regularity checks, `blockmatrix.py:90`). A caller that hand-builds a `BlockMatrix` with a scalar block can still break `colblocksizes`. | This is a latent fragility, not the reported bug; the fix removes the only *normal* path that produced such blocks. Recorded as FINDINGS F3 (recommendation), not a required change. See ITERATION_GUIDANCE. |
| E2 | Termination of the real `MatAdd.canonicalize` `exhaust(...)` fixpoint. | Partial-correctness default; `canonicalize` is a standard `exhaust` that is not affected by this change. |
| E3 | Whole-program blast radius of changing core `Add` of all-`ZeroMatrix` (every caller of `Add(*matrix_exprs)` in SymPy). | Bounded by reasoning (FINDINGS F2), not by a global proof; no machine-check of the entire suite is possible here. |

## Discharge summary

All **core** (O1–O7) and **frame** (O8–O11) obligations are discharged by the
constructed proof in `fvk/PROOF.md`. The arithmetic is trivial (shape equalities
and `K ≥ 1`); the substance is structural — *the head kept by `rm_id` is a
`ZeroMatrix` rather than the scalar `S.Zero`*. The (BUG) counter-claim is
deliberately **not** discharged: it gets stuck at `cols(s0)`, which is the proof's
rendering of the original `AttributeError`.
