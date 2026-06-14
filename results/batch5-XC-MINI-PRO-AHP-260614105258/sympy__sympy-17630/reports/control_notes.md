# Control notes — V2 review outcome for sympy__sympy-17630

This documents the review of the V1 fix and every resulting decision, each traced to
a numbered entry in `review/FINDINGS.md`.

## Summary of outcome

V1's logic is **kept**: the root cause is fixed at the right layer with a
precisely-bounded behavioral delta. The only edit made in V2 is a behavior-preserving
clarity/consistency improvement to the same lines.

## The single V2 code change

**File:** `sympy/matrices/expressions/matexpr.py`, `get_postprocessor`.

**What:** The guard introduced in V1 was rewritten from `if mat_class == MatAdd:` to
`if cls == Add:`, and a comment was added that explains the fix and cites issue
#17630.

**Why (traces to F8):** The two spellings are functionally identical
(`mat_class == {Mul: MatMul, Add: MatAdd}[cls]`, so `mat_class == MatAdd` iff
`cls == Add`). The surrounding function already branches with `cls == Mul`
(matexpr.py:613), so `cls == Add` is the consistent idiom, and neighbouring code
documents non-obvious intent and even cites issue numbers (e.g. dense.py:200 cites
ISSUE #11599). This change touches no behavior — it only improves readability and
makes the intent (and the bug it prevents) explicit. No other finding required a
code change.

## Decisions to keep V1 unchanged (and why)

- **Keep the fix in the `Add`/`Mul` post-processor rather than in `blockmatrix.py`.**
  Traces to **F2** (correct layer: the type-incorrect scalar `S.Zero` is repaired
  where it is created) and **F9** (the `blockmatrix._blockmul` reconstruction and the
  "tolerate scalar `Zero` in `colblocksizes`" alternatives were rejected — they fix a
  symptom, add code, and leave malformed values / the underlying `Add(Z,Z) == 0` bug
  in place; the `rm_id` alternative touches a generic strategy).

- **Keep the change scoped to the `Add` branch only; leave `MatMul` untouched.**
  Traces to **F4** (the `MatMul` return is byte-for-byte original and cannot drop a
  scalar factor) and **F3** (the entire observable delta is "all-`ZeroMatrix` `Add`
  → `ZeroMatrix` instead of scalar `S.Zero`"). Broadening the guard to
  `if not nonmatrices:` would also (harmlessly) alter the `MatMul` empty case; I kept
  it `Add`-only to minimize blast radius.

- **Do not add defensive handling to `colblocksizes`/`rowblocksizes` or `_blockmul`.**
  Traces to **F1** (with the root cause fixed, blocks are never scalar `Zero`, so
  these accessors no longer receive a non-matrix) and **F9** (defensive accessors
  would mask malformed block matrices and could yield silently-wrong shapes).

- **Accept the `is_zero` semantic change of the result.** Traces to **F6**: the
  result moves from `S.Zero` (`is_zero == True`) to `ZeroMatrix` (`is_zero == None`).
  This matches `ZeroMatrix`'s pre-existing behavior and does not affect matrix
  zero-detection, which uses `is_ZeroMatrix` (e.g. `any_zeros`, matmul.py:220). No
  code change is warranted.

## Verification performed (static, no execution available)

- Re-traced the reported scenarios end-to-end (**F1**): `block_collapse(b*b*b)`,
  `b._blockmul(b)._blockmul(b)`, and `type(b._blockmul(b).blocks[0,1])` — all now
  succeed / yield `ZeroMatrix`.
- Bounded the behavioral delta to the all-`ZeroMatrix` `Add` case via the `rm_id`
  early-strip argument (**F3**), and confirmed the `MatMul` path is unchanged (**F4**).
- Audited matrix-valued sum sites and the post-processor trigger conditions (**F5**):
  the only matrix-valued *core* `Add(*...)` in `sympy/matrices` is the dense
  multiply at dense.py:198 (the fix target); direct `MatAdd(*...)` constructions
  bypass the post-processor.
- Reviewed visible tests (`test_matadd.py`, `test_blockmatrix.py`, `test_trace.py`,
  `test_determinant.py`, `test_hadamard.py`, `test_constructor_postprocessor.py`):
  none assert that an all-zero matrix `Add` equals the scalar `0`, and the
  block-diag multiply/add tests use element-wise paths that never hit `Add(*vec)`
  (**F5**, **F7**).

## Net diff vs. V1

Only the guard expression and an added comment differ; the executable behavior is
identical to V1. `reports/baseline_notes.md` remains an accurate description of the
fix's mechanism.
