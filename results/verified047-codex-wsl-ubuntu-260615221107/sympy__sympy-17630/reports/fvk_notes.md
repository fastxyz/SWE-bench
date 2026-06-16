# FVK Notes

## Decisions

### Strengthened V1 zero normalization

Changed `repo/sympy/matrices/expressions/blockmatrix.py` in
`BlockMatrix._blockmul` so the local `entry(i, j)` helper normalizes both:

- entries with `is_ZeroMatrix`, and
- non-matrix entries equal to scalar `0`.

Both cases now return `ZeroMatrix(rowblocksizes[i], colblocksizes[j])`.

Reason: `fvk/FINDINGS.md` F1 records the reported scalar-zero bug, and F2 shows
V1's narrower predicate did not fully match the proof obligation that every
zero-like output block must be shaped. The edit discharges
`fvk/PROOF_OBLIGATIONS.md` PO-3 and PO-5.

### Kept the repair inside `_blockmul`

I did not change `MatAdd`, `MatMul`, `ZeroMatrix`, or generic dense matrix
arithmetic.

Reason: F3 identifies those as broader alternatives without public intent
evidence for this issue. `_blockmul` has the left row block sizes and right
column block sizes needed by PO-3 and PO-6, so it is the narrowest location that
can restore the `BlockMatrix` invariant without guessing.

### Preserved fallback behavior

The non-aligned and non-`BlockMatrix` fallback remains `return self * other`.

Reason: `fvk/SPEC.md` E5 and `fvk/PROOF_OBLIGATIONS.md` PO-7 require API and
dispatch compatibility outside the aligned block-matrix branch.

### No test edits or execution

No tests were run, and no test files were modified.

Reason: the benchmark forbids test/code execution and test edits. F4 and PO-8
record the honesty gate: the proof is constructed, not machine-checked, and no
test-redundancy action is justified in this session.

## Artifact Summary

The FVK package is under `fvk/`:

- `SPEC.md`: intent ledger, contract, formal claim paraphrases, adequacy audit,
  and compatibility audit.
- `FINDINGS.md`: public and proof-derived findings F1-F4.
- `PROOF_OBLIGATIONS.md`: obligations PO-1 through PO-8 and future K commands.
- `PROOF.md`: constructed proof of the normalized block-product invariant.
- `ITERATION_GUIDANCE.md`: V2 decision, suggested future tests, and next K step.
- `mini-blockmatrix.k` and `blockmatrix-spec.k`: abstract K-style core for the
  property-bearing fragment, not executed here.
