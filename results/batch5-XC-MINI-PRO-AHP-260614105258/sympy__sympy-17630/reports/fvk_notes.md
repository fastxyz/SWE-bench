# FVK audit notes — sympy__sympy-17630

This documents the Formal Verification Kit (FVK) audit of the V1 fix and the V2
outcome. Every decision is traced to a specific entry in `fvk/FINDINGS.md` and/or
`fvk/PROOF_OBLIGATIONS.md`. Artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, plus the
mini-X semantics `fvk/mini_matexpr.k` and claims `fvk/mini_matexpr-spec.k`.

## Outcome in one line

**V1 stands** (it is provably correct and minimal); V2 adds only a clarifying
**comment** at the fix site — no behavioral change.

## What the audit did

1. Built a public intent ledger (`fvk/SPEC.md` §2) from the issue prompt, the
   public tests, and the docstrings — *not* from the as-built code. The clean
   contract C1 ("a sum of equal-shape zero matrices is the zero matrix of that
   shape") is exactly what `ZeroMatrix`'s "additive identity" docstring and tests
   `test_matexpr.py:105,128,238` already assert.
2. Wrote a mini-X K fragment (`fvk/mini_matexpr.k`) modeling only the touched
   pieces: the value domain `{s0, Z(p,q), Sym(p,q)}`, `MatMul.any_zeros`, the
   `Add` post-processor (`addM` fixed / `addMbug` base), `MatAdd`'s
   `rm_id`/`unpack`, and the partial `.cols`/`.rows` access.
3. Stated reachability claims (`fvk/mini_matexpr-spec.k`) and constructed their
   proofs (`fvk/PROOF.md`), discharging obligations O1–O11
   (`fvk/PROOF_OBLIGATIONS.md`). Constructed, not machine-checked (no toolchain).

## The decisions, each traced

### Decision 1 — Keep the fix at the matexpr post-processor (do not relocate to `blockmatrix.py`)
- **Traces to:** FINDINGS **F1** (root cause), **F4** (the bug is an inconsistency
  between the `+` operator and the core `Add` constructor), obligation **O10**
  (change is confined to the all-zero case).
- **Reasoning:** F4 — discovered while writing contract C1 — showed that at the
  base commit `ZeroMatrix + ZeroMatrix` (operator → `MatAdd`) already produced
  `ZeroMatrix`, whereas `Add(ZeroMatrix, ZeroMatrix)` (core constructor, used by
  `DenseMatrix._eval_matrix_mul`) produced the scalar `S.Zero`. The defect is a
  single inconsistent sink, so the root-cause site is the post-processor. Fixing
  there repairs all consumers; a `blockmatrix.py`-only patch would be symptomatic
  and leave F1 live elsewhere. PROOF.md §2 vs §4 pins the difference to exactly the
  prepended scalar.

### Decision 2 — Guard the change with `mat_class == MatAdd` (leave `Mul` untouched)
- **Traces to:** FINDINGS **F6**, obligation **O8**.
- **Reasoning:** O8 confirms the `Mul` branch must keep emitting
  `MatMul(cls._from_args(nonmatrices), *matrices)` (its scalar identity `S.One` is
  harmless and never caused this bug — ledger L8, `any_zeros`). Guarding on
  `MatAdd` keeps `MatMul` byte-for-byte identical and confines the behavior change
  to `Add`.

### Decision 3 — Do NOT add the comment/behavior to the `Add(scalar, matrix)` branch
- **Traces to:** obligation **O9**, ledger **L6** (`test_MatAdd_postprocessor`).
- **Reasoning:** O9 shows the `nonmatrices`-non-empty `Add` case returns earlier
  (line 628) and is never reached by the fixed line, so the documented
  "`Add(scalar, matrix)` without raising" capability is preserved untouched.

### Decision 4 — Do NOT harden `colblocksizes`/`rowblocksizes` or `BlockMatrix.__new__`
- **Traces to:** FINDINGS **F3**, escalation **E1**.
- **Reasoning:** the root-cause fix removes the only *normal* path that produced a
  scalar block, so the downstream methods are now total (proved: O5–O7,
  claims COLS-OK/COLSIZES-OK). Swallowing a scalar in `colblocksizes` would mask
  future bugs (a scalar has no meaningful `.cols`); enforcing a block-type
  invariant in `__new__` is a broader, separately-motivated change. Left as a
  recommendation (ITERATION_GUIDANCE D3), not applied — consistent with "minimal
  and targeted."

### Decision 5 — V2 adds a provenance comment at the fix site (the only V2 edit)
- **Traces to:** FINDINGS **F1/F4**, obligation **O2** (the crux: `rm_id` keeps the
  head, which must be a `ZeroMatrix`).
- **Reasoning:** the sibling branch (`Add(scalar, matrix)`) is already commented,
  but the fixed branch was not, and its rationale (the prepended scalar `S.Zero`
  combined with `MatAdd`'s "keep one identity" `rm_id`) is non-obvious. The comment
  records it inline and references issue #17630. This is a minimal, behavior-neutral
  refactor permitted by the task; it does not alter any obligation.

## Why no further code change was warranted

- **Correctness:** claims REPZ, ADD0, COLS-OK, COLSIZES-OK all discharge
  (PROOF.md §1–§3); the (BUG) counter-claim gets stuck at `cols(s0)`, which is the
  faithful rendering of the reported `AttributeError` and confirms the fix removes
  exactly that stuck state (PROOF.md §4).
- **No regression:** O8–O11 + FINDINGS F5/F6/F7 bound the change to the
  all-`ZeroMatrix` `Add` case; no existing test exercises it (it uses explicit
  `zeros(2)` or non-zero matrices), and the operator-path tests L4/L5 keep passing.
  `ZeroMatrix` is falsy and `any_zeros` keys on `is_ZeroMatrix`, so the global
  blast radius is benign.
- **Spec-difficulty signal:** the contract was *easy* to write and the as-built
  code violated it — the classic "the difficulty is in the code, not the intent"
  benefit-2 signal. There was no missing precondition beyond the natural,
  structurally-satisfied `K ≥ 1` (non-empty sum) and shape agreement (O4).

## Honesty gate

All proofs are **constructed, not machine-checked** — no K toolchain exists in
this environment. The `kompile`/`kprove` commands are recorded in `fvk/PROOF.md`
§5 for later confirmation. The test-redundancy recommendation
(`fvk/ITERATION_GUIDANCE.md`) is conditioned on that machine check and recommends
**removing nothing**; it instead flags a coverage *gap* (tests to add). The
FINDINGS do not depend on the machine check.
