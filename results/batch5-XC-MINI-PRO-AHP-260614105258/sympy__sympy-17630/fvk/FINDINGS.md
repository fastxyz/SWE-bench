# FINDINGS — sympy__sympy-17630

Plain-language findings from formalizing and verifying the V1 fix. Format:
`input → observed vs expected`. Benefit-2 findings do **not** depend on the
(absent) machine check.

---

## F1 — ROOT CAUSE (fixed). `Add(ZeroMatrix, ZeroMatrix)` collapsed to scalar `0`

- **input:** `Add(ZeroMatrix(2,2), ZeroMatrix(2,2))` (as produced internally by
  `DenseMatrix._eval_matrix_mul`'s `Add(*vec)` when multiplying block grids).
- **observed (base):** the scalar `S.Zero` — `type(...) == sympy.core.numbers.Zero`.
- **expected:** `ZeroMatrix(2,2)` (a matrix; matches the `+`-operator path and
  ledger L2/L4/L5).
- **mechanism:** the `MatrixExpr` "Add" constructor post-processor
  (`matexpr.get_postprocessor`) reached
  `mat_class(cls._from_args(nonmatrices), *matrices).doit()`. With `nonmatrices`
  empty, `cls._from_args([])` returns the scalar additive identity `S.Zero`, so it
  built `MatAdd(S.Zero, Z, Z).doit()`. `MatAdd.canonicalize`'s `rm_id` rule
  (`matadd.py:129`) then saw an all-identities list and, per its "keep one"
  behavior (`strategies/rl.py:36-37`), kept `args[0]` — the scalar `S.Zero` — which
  `unpack` then returned. Proof rendering: §2 vs §4 of `fvk/PROOF.md`.
- **status:** **FIXED** in `matexpr.py` (V1, retained in V2). Discharges
  obligations O2, O3; supports claim (ADD0).

## F2 — Downstream crash (fixed by F1). `_blockmul` twice → AttributeError

- **input:** `block_collapse(b*b*b)` / `b._blockmul(b)._blockmul(b)` with
  `b = BlockMatrix([[a, z],[z, z]])`, `z = ZeroMatrix(2,2)`.
- **observed (base):** `AttributeError: 'Zero' object has no attribute 'cols'` in
  `BlockMatrix.colblocksizes` (`blockmatrix.py:80`/`:155`).
- **expected:** `Matrix([[a**3, 0],[0, 0]])`, no exception.
- **mechanism:** F1 put a scalar `S.Zero` into the off-diagonal blocks of
  `b._blockmul(b)`; the *next* `_blockmul` reads `block.cols` on every block.
- **status:** **FIXED transitively by F1** — with all blocks now `MatrixExpr`,
  `colblocksizes`/`rowblocksizes` are total. Claims (COLS-OK), (COLSIZES-OK); O5–O7.

## F3 — Latent fragility (NOT fixed; recommendation). `BlockMatrix` does not enforce matrix-typed blocks

- **input:** `BlockMatrix(Matrix([[ZeroMatrix(2,2), S.Zero],[...]]))` — a block grid
  built by hand (or by any *future* code path) that contains a scalar.
- **observed:** `colblocksizes`/`rowblocksizes`/`shape`/`_entry`/`_eval_transpose`
  would raise/misbehave — `BlockMatrix.__new__` skips its regularity checks when
  handed a `Matrix` directly (`blockmatrix.py:90`, `if not isMat(rows)`).
- **expected (defensive):** either reject non-`MatrixExpr` blocks at construction,
  or make `colblocksizes`/`rowblocksizes` give a clear error.
- **status:** **left as-is, deliberately** (see ITERATION_GUIDANCE D3). The fix
  removes the only *normal* path (sum-of-zeros via multiply) that produced scalar
  blocks. Hardening `colblocksizes` to swallow scalars would *mask* future bugs
  (a scalar block has no sensible `.cols`), and enforcing the invariant in
  `__new__` is a broader, separately-motivated change outside this issue's scope.
  Escalation obligation E1.

---

## Proof-derived findings from `/verify`

## F4 — The bug is an internal *inconsistency*, which sharpened the fix choice

- **evidence:** Formalizing C1 revealed two paths to "sum two `ZeroMatrix`":
  the `+` operator (`MatrixExpr.__add__` → `MatAdd(...,check=True).doit()`) already
  returned `ZeroMatrix`, while the core `Add(...)` constructor returned scalar `0`.
  Tests L4/L5 (`test_matexpr.py:105,128,238`) pin the operator result as
  `ZeroMatrix`.
- **classification:** code bug (inconsistent sink), not underspecified intent.
- **why it matters for the fix location:** it confirms the correct fix is to make
  the *constructor* post-processor agree with the operator/`MatAdd` — i.e. the
  matexpr post-processor is the right, root-cause site — rather than patching
  `blockmatrix.py` symptomatically. Justifies keeping the V1 location in V2.

## F5 — Frame check: the change is provably confined to the all-zero `Add` case

- **evidence:** discharging O10 required showing `MatAdd(*matrices).doit()` =
  `MatAdd(S.Zero, *matrices).doit()` whenever ≥1 summand is non-`ZeroMatrix`
  (because `rm_id` deletes the scalar `0` early). The only residue is the
  all-`ZeroMatrix` case.
- **classification:** no-regression evidence (benefit 1 enabler).
- **test reading:** no existing test exercises the changed case
  (`test_MatAdd_postprocessor` uses explicit `zeros(2)`/non-zero matrices, never an
  all-symbolic-`ZeroMatrix` core `Add`); `Add(0, z) == z` and `Add(M, M) == 2*M`
  pass unchanged. So the fix neither breaks nor is covered by the current suite —
  a coverage gap (see ITERATION_GUIDANCE, "tests to add").

## F6 — `Mul` path untouched (guard is `mat_class == MatAdd`)

- **evidence:** O8 — the new early-return is guarded so `Mul` still emits
  `MatMul(cls._from_args(nonmatrices), *matrices)`; `MatMul`'s scalar identity is
  `S.One`, harmless, and never produced this bug (`any_zeros` already handles
  zeros, ledger L8).
- **classification:** scoping/no-regression. Reduces blast radius to `Add` only.

## F7 — Blast-radius bound for the global behavior change

- **evidence:** the change makes core `Add` of *all*-`ZeroMatrix` args return
  `ZeroMatrix` everywhere, not only in block matrices. Within
  `sympy/matrices/expressions`, no code relies on the old scalar `0`:
  `MatMul.any_zeros` keys on `is_ZeroMatrix` (not on `Add(...)==0`); `ZeroMatrix`
  is falsy (`__bool__` → False, `matexpr.py:985`), so `if not result:` style checks
  still behave; `is_zero` is not defined on `ZeroMatrix` and is not relied on here.
- **classification:** capability/blast-radius note (not a code bug). The residual
  risk is code elsewhere doing `Add(*mats) == 0` (scalar) on an all-zero sum;
  such a check is semantically wrong (matrix vs scalar) and would be relying on the
  defect. Cannot be globally machine-checked here (E3); reasoned, not proved.

---

## Spec-difficulty signal

Writing C1 was **easy and clean** ("a sum of equal-shape zero matrices is the zero
matrix of that shape"), and it is exactly what `ZeroMatrix`'s "additive identity"
docstring (L7) and tests L4/L5 already assert. A clean spec that the as-built code
violated is the textbook benefit-2 signal: the difficulty was entirely in the
*code path* (the stray scalar prepend), not in the intent. No awkward case-split or
missing precondition was needed beyond the natural `K ≥ 1` (non-empty sum) and
the shape-agreement side condition — both of which hold structurally in matrix
multiplication.
