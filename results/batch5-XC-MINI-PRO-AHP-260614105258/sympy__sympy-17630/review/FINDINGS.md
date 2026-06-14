# Code review — V1 fix for sympy__sympy-17630

V1 changed one place: `sympy/matrices/expressions/matexpr.py`,
`get_postprocessor(cls)._postprocessor`. The final return was split so that an
all-matrix `Add` no longer prepends the scalar additive identity:

```python
        if mat_class == MatAdd:
            return mat_class(*matrices).doit(deep=False)
        return mat_class(cls._from_args(nonmatrices), *matrices).doit(deep=False)
```

Findings below are numbered and referenced from `reports/control_notes.md`.

---

## F1 — Correctness against the issue: CONFIRMED

`BlockMatrix._blockmul` builds `BlockMatrix(self.blocks*other.blocks)`. The block
product uses `DenseMatrix._eval_matrix_mul` (`sympy/matrices/dense.py:198`), which
forms each entry with the **core** `Add(*vec)`. For the off-diagonal entries of
`b.blocks*b.blocks` every product is `ZeroMatrix(2,2)`, so the call is
`Add(ZeroMatrix(2,2), ZeroMatrix(2,2))`.

With the fix, that `Add` is routed through the post-processor to
`MatAdd(ZeroMatrix, ZeroMatrix).doit()`. `MatAdd` canonicalization's `rm_id`
(all-identity branch keeps `args[0]`) now keeps a `ZeroMatrix`, and `unpack`
returns it → `ZeroMatrix(2,2)`. So:

- `b._blockmul(b).blocks[0,1]` is now `ZeroMatrix` (the symptom the reporter
  flagged), not `Zero`.
- `b._blockmul(b)._blockmul(b)` no longer reaches `Zero.cols` →
  `colblocksizes`/`rowblocksizes` work.
- `block_collapse(b*b*b)` returns `BlockMatrix([[a**3, 0],[0,0]])`.

Verified by hand-tracing (no execution available).

## F2 — Root cause is fixed at the correct layer: CONFIRMED

The genuine defect is that summing zero matrices yielded the *scalar* `S.Zero`
(type-incorrect: the sum of two `n×m` zero matrices is an `n×m` zero matrix). The
scalar entered because the post-processor built `MatAdd(cls._from_args([]), Z, Z)`
and `Add._from_args([])` returns `S.Zero`; `rm_id`'s "keep one identity" then kept
that scalar. Fixing it where the value is created repairs every consumer, including
the dense-multiply path block matrices depend on. This is preferable to repairing a
symptom downstream (see F9).

## F3 — Behavioral delta is minimal and precisely characterized: CONFIRMED

The only observable change is: `Add(<args that are all ZeroMatrix>)` now returns
`ZeroMatrix` instead of `S.Zero`. Reasoning:

- `rm_id`'s predicate is `x == 0 or isinstance(x, ZeroMatrix)`. When the original
  `MatAdd(0, *matrices)` contains **at least one** non-zero matrix term, `rm_id`
  strips the injected scalar `0` on its first pass (it is a single identity among
  non-identities), and processing proceeds identically to `MatAdd(*matrices)`.
  Therefore non-all-zero sums (including cancellations such as `A + (-A)`, which
  `glom` already collapsed to `ZeroMatrix` pre-fix) are unchanged.
- The scalar-`0` result only occurred when **every** matrix arg was a literal
  `ZeroMatrix`, so `rm_id`'s all-identity branch fired with the scalar `0` as
  `args[0]`. That is the single case the fix changes.

So the patch is far narrower than "touches the Add/Mul hot path" might suggest.

## F4 — `MatMul` path is untouched: CONFIRMED

The guard restricts the new branch to the `MatAdd` case; the `MatMul` return
(line 632) is byte-for-byte the original. Even the empty-`nonmatrices` `MatMul`
case is unchanged, and `MatMul(S.One, *m).doit() == MatMul(*m).doit()` regardless,
so no scalar factor can ever be dropped.

## F5 — Regression surface of the (global) post-processor: LOW RISK

The post-processor only runs for **core** `Add(...)`/`Mul(...)` that contain a
`MatrixExpr` arg (via `AssocOp.__new__ -> _exec_constructor_postprocessors`).
Important: direct `MatAdd(*...)` / `MatMul(*...)` constructions do **not** trigger
it (they go through `Basic.__new__`, not `AssocOp.__new__`). Audited matrix-valued
sum sites:

- `dense.py:198` `Add(*vec)` — the only matrix-valued *core* `Add` in
  `sympy/matrices`; this is exactly the path the fix targets.
- `matadd.py` (`MatAdd(*...)`, `Add(*[entry...])`), `kronecker.py`
  (`MatAdd(*krons)`), `blockmatrix.py:189/416`, `matexpr` operators — either build
  `MatAdd` directly (bypass) or `Add` over **scalar** entries/traces (no matrix
  args, so the all-zero-matrix branch cannot fire).

No visible test asserts that an all-zero matrix `Add` equals the scalar `0`
(checked `test_matadd.py`, `test_blockmatrix.py`, `test_trace.py`,
`test_determinant.py`, `test_hadamard.py`, `test_constructor_postprocessor.py`).
`test_constructor_postprocessor.py` exercises only custom non-matrix classes.

## F6 — `is_zero` / type semantics of the new result: NOTED, not a regression

The result changes from `S.Zero` (`is_zero` is `True`) to `ZeroMatrix`
(`ZeroMatrix.is_zero` is `None`, since neither `MatrixExpr` nor `ZeroMatrix`
defines `is_zero`). This does not introduce an inconsistency the codebase did not
already have: `ZeroMatrix(...).is_zero` is `None` today independent of this fix, and
zero-detection of matrices is done via `is_ZeroMatrix`, not `is_zero` — e.g.
`any_zeros` (`matmul.py:220`) deliberately checks `arg.is_zero or (arg.is_Matrix
and arg.is_ZeroMatrix)`. The affected dense-multiply path stores the entry into a
matrix cell and does not branch on `is_zero`, so the change is inert there.

## F7 — Edge cases: COVERED

- `Add(Z, Z, ..., Z)` with `n>=2` literal zeros → `ZeroMatrix` (`rm_id` all-identity
  branch keeps a `ZeroMatrix`). OK.
- Block product row of length 1 (`self.cols == 1`): `Add(<single product>)` returns
  that product directly (`AssocOp.__new__` short-circuits `len(args)==1`), so the
  post-processor is not even invoked; a single `ZeroMatrix` stays a `ZeroMatrix`. OK.
- Mixed scalar+matrix `Add` (`Add(2, Z)`): handled by the pre-existing
  non-empty-`nonmatrices` Add branch (line 628), untouched. OK.
- Mismatched-shape all-zero `Add` (`Add(Z(2,3), Z(3,2))`): a degenerate user error;
  `MatAdd` does not validate shapes here (`check=False`), so it returns a single
  zero object in both old (scalar `0`) and new (`ZeroMatrix(2,3)`) code. No
  meaningful regression; arguably the new value is at least matrix-typed.
- `matrices` is guaranteed non-empty at the changed line (line 609 returns earlier
  when empty), so `MatAdd(*matrices)` always has >=1 arg.

## F8 — Consistency with codebase conventions: MINOR IMPROVEMENT

V1's guard `mat_class == MatAdd` is correct but stylistically inconsistent: the same
function already branches with `cls == Mul` (line 613). The fix also lacked an
explanatory comment, whereas neighbouring code documents non-obvious intent and even
cites issue numbers (e.g. `dense.py:200` "ISSUE #11599"). Action: rewrite the guard
as `cls == Add` and add a short comment citing #17630. Behavior-preserving.

## F9 — Alternatives considered and rejected: JUSTIFIED

- **Reconstruct zero blocks in `BlockMatrix._blockmul`.** More code; fixes only
  block-matrix multiplication; leaves `Add(ZeroMatrix, ZeroMatrix) == 0` (a
  type-incorrect result) in place to surface elsewhere.
- **Make `colblocksizes`/`rowblocksizes` tolerate scalar `Zero`.** Masks a
  malformed `BlockMatrix`; `shape`, `_entry`, `_eval_transpose`, etc. all assume
  matrix blocks, so the crash would only move and shapes could be silently wrong.
- **Change `rm_id` to keep a matrix identity.** `rm_id` is a generic strategy used
  widely; safer to not feed `MatAdd` the spurious scalar identity in the first place.

## Overall assessment

V1 is correct and well-localized to the true root cause, with a precisely-bounded
behavioral delta (F1–F5, F7). The only actionable item is the cosmetic/consistency
improvement in F8 (guard style + comment). No functional change to V1's logic is
warranted.
