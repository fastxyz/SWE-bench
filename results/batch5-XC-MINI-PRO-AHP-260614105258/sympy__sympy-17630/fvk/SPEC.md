# SPEC — sympy__sympy-17630

Formal specification of the behavior the fix must guarantee, plus the public
intent ledger that justifies each obligation. Companion artifacts:
`fvk/mini_matexpr.k` (mini-X semantics), `fvk/mini_matexpr-spec.k` (claims),
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/FINDINGS.md`.

> Mode: **intent-spec**. The contract below is derived from the issue text, the
> existing public tests, and the docstrings — *not* from "whatever the code
> happens to do." Where the as-built code diverged from the contract, that
> divergence is the bug (see FINDINGS F1).
>
> Status: **constructed, not machine-checked** (no K toolchain available here).

## 1. What is being specified

The unit under audit is the change applied in V1:

- `sympy/matrices/expressions/matexpr.py` — `get_postprocessor(cls)._postprocessor`,
  the constructor post-processor registered for `MatrixExpr` on the core `Add`/`Mul`
  nodes (`Basic._constructor_postprocessor_mapping[MatrixExpr]`).

The post-processor is what turns a core `Add(m1, m2, …)` / `Mul(…)` containing
matrix expressions into the corresponding `MatAdd` / `MatMul`. The behavior under
spec is therefore: **what does `Add(*args)` evaluate to when its arguments are
matrix expressions** — in particular when they are all `ZeroMatrix`.

Downstream consumers that depend on this behavior (and motivate the contract):

- `DenseMatrix._eval_matrix_mul` (`dense.py:198`) builds every product entry with
  the *core* `Add(*vec)`; for a `BlockMatrix` the entries are matrix expressions.
- `BlockMatrix.colblocksizes` / `rowblocksizes` (`blockmatrix.py:150-155`) read
  `block.cols` / `block.rows` of every block.
- `BlockMatrix._blockmul` (`blockmatrix.py:164`) multiplies the block grids and
  must produce a result that can itself be block-multiplied again.

## 2. Public intent ledger

| # | Source | Evidence (quoted) | Semantic obligation | Status |
|---|--------|-------------------|---------------------|--------|
| L1 | prompt (issue title) | "Exception when multiplying BlockMatrix containing ZeroMatrix blocks" | `block_collapse`/`_blockmul` of a block matrix with `ZeroMatrix` blocks must not raise. | **violated at base** → fixed |
| L2 | prompt (diagnosis) | "the zeros in `b._blockmul(b)` are not `ZeroMatrix` but `Zero`" … `type(...) == <class 'sympy.core.numbers.Zero'>` | A sum of zero blocks must remain a **matrix** (`ZeroMatrix`), never the scalar `S.Zero`. | **violated at base** → fixed |
| L3 | prompt (traceback) | "`AttributeError: 'Zero' object has no attribute 'cols'`" in `colblocksizes` | Every block of a `BlockMatrix` produced by `_blockmul` must expose `.cols`/`.rows` (i.e. be a `MatrixExpr`), so the result is itself block-multipliable. | **violated at base** → fixed |
| L4 | public test | `test_matexpr.py:105` `2*A - A - A == ZeroMatrix(*A.shape)` | A matrix sum that vanishes is `ZeroMatrix`, not `0`. | holds (operator path) — fix makes the **constructor** path agree |
| L5 | public test | `test_matexpr.py:128,238` `A - A == ZeroMatrix(*A.shape)`, `A + ZeroMatrix(n,m) - A == ZeroMatrix(n,m)` | same, via `+`/`-`. | holds — defines the target value |
| L6 | public test | `test_matexpr.py:571` `test_MatAdd_postprocessor`: `Add(scalar, matrix)` must NOT raise (kept "to replace matrices with dummy symbols") | The fix must preserve the `Add(scalar, matrix)` capability (the `nonmatrices` non-empty branch). | preserved |
| L7 | code/docstring | `ZeroMatrix` doc "additive identity"; `MatAdd` rule `rm_id(lambda x: x == 0 or isinstance(x, ZeroMatrix))` | Summing additive identities yields the identity *of the matrix kind*. | basis of contract |
| L8 | code | `MatMul.any_zeros` uses `arg.is_zero or (arg.is_Matrix and arg.is_ZeroMatrix)` | The multiplication side already treats `ZeroMatrix` correctly; only the addition/constructor side needed repair. | scoping note |

No upstream fix or hidden test was consulted (forbidden). The contract is built
from the issue prompt + public tests + docstrings only.

## 3. The contract (plain language)

Let `A` be the core-`Add` post-processor for matrix expressions.

- **C1 (type-preservation / the fix).** If every argument of a core `Add` node is a
  `MatrixExpr` of a common shape `(p, q)` (the `nonmatrices`-empty case), then
  `A` returns a `MatrixExpr` of shape `(p, q)`. In particular, if *all* arguments
  are `ZeroMatrix(p, q)`, the result is `ZeroMatrix(p, q)` — **never** the scalar
  `S.Zero`. *(Ledger: L2, L4, L5, L7.)*
- **C2 (repeatability).** Consequently `BlockMatrix._blockmul` returns a
  `BlockMatrix` all of whose blocks are `MatrixExpr`; therefore `colblocksizes`
  and `rowblocksizes` of the result are total (no `AttributeError`), so the result
  can be block-multiplied again. *(Ledger: L1, L3.)*
- **C3 (frame / no regression).** `A` is unchanged for the `Mul` case and for the
  `Add(scalar, matrix)` case (`nonmatrices` non-empty); the only value that changes
  versus the base code is the all-`ZeroMatrix` sum (`S.Zero` → `ZeroMatrix`).
  *(Ledger: L6, L8.)*

## 4. Formalization map (mini-X ↔ SymPy)

`fvk/mini_matexpr.k` models the value domain `{ s0, Z(p,q), Sym(p,q) }`
(`s0` = scalar `S.Zero`; `Z` = `ZeroMatrix`; `Sym` = a generic non-zero matrix
expression) and the relevant operations:

| mini-X symbol | SymPy reality |
|---|---|
| `mmul(_,_)` | `MatMul(...).doit()` with `any_zeros` (a zero factor ⇒ `ZeroMatrix` of outer shape) |
| `addM(L)` | core `Add(*L)` + `MatrixExpr` "Add" post-processor + `MatAdd` `canonicalize` — **fixed** form |
| `addMbug(L)` | the same path on the **base** code (prepends the scalar identity `S.Zero`, i.e. `cls._from_args([])`) |
| `rmId` / `canon` | `MatAdd` `rules = (rm_id(...), unpack, …)` |
| `cols(_)` / `rows(_)` | `.cols` / `.rows`; **no rule for `cols(s0)`** = `AttributeError: 'Zero' object has no attribute 'cols'` |
| `repZ(p,q,k)` | the k-indexed `vec` of products in `dense._eval_matrix_mul` for an all-zero entry |
| `colsizes(_)` | the comprehension in `BlockMatrix.colblocksizes` |

## 5. Claims (see `fvk/mini_matexpr-spec.k`)

- **(REPZ)** `allZeroLike(repZ(P,Q,K)) ⇒ true` for `K ≥ 0` — recursion/circularity.
- **(ADD0)** `addM(repZ(P,Q,K)) ⇒ Z(P,Q)` for `K ≥ 1` — **contract C1**.
- **(COLS-OK)** `cols(addM(repZ(P,Q,K))) ⇒ Q` for `K ≥ 1` — **contract C2** (definedness).
- **(COLSIZES-OK)** `colsizes(addM(repZ(P,Q,K)), .MVals) ⇒ Q, .IntList` — the loop is total.
- **(BUG)** `cols(addMbug(repZ(P,Q,K))) ⇒ Q` — **expected to get STUCK** at `cols(s0)`; documents the defect (it is the AttributeError), not part of the positive package.

### Side conditions / preconditions surfaced

- `K ≥ 1` for ADD0/COLS-OK: a product entry in a matrix multiply always has
  `self.cols ≥ 1` summands (`dense.py:188`), so the sum is non-empty; the empty
  sum is out of domain (and is handled separately by `Add()`/`MatAdd()` identities).
- All summands share shape `(P,Q)`: guaranteed because every product
  `A[i,k]*B[k,j]` for fixed `(i,j)` has shape `(rowblocksizes[i], colblocksizes[j])`.
  This is recorded as proof obligation O4 and is what makes the kept `ZeroMatrix`
  have the *correct* shape.
