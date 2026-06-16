# FINDINGS.md

Status: FVK audit of V1.

## F1: V1 predecessor replaced compatible empty sparse accumulators

- Classification: code bug fixed by V1.
- Evidence: public issue and E6.
- Input: `SparseMatrix.hstack(*[SparseMatrix.zeros(0, n) for n in range(4)])`.
- Observed before V1: shape `(0, 3)` because `row_join` returned
  `type(self)(other)` whenever `rows * cols == 0`.
- Expected: shape `(0, 6)`, matching dense `Matrix` and the public issue hint.
- V1 status: fixed. `row_join` now follows the common null-column adaptation
  only when appropriate, otherwise compatible zero-row shapes use the normal
  sparse shape accumulation path.
- Proof obligations: PO1, PO2, PO5.

## F2: Vertical zero-column sparse family had the same falsy-matrix defect

- Classification: code bug fixed by V1.
- Evidence: E3 and E6.
- Input: `SparseMatrix.vstack(*[SparseMatrix.zeros(n, 0) for n in range(4)])`.
- Observed before V1: by the same `if not self` replacement mechanism, each
  compatible `n x 0` accumulator could be replaced by the next operand.
- Expected: shape `(6, 0)`, matching the dense vertical family.
- V1 status: fixed. `col_join` now follows the common null-row adaptation only
  when appropriate, otherwise compatible zero-column shapes use the normal
  sparse shape accumulation path.
- Proof obligations: PO3, PO4, PO6.

## F3: V1 preserves the sparse-specific public dispatch path

- Classification: compatibility finding, no code change required.
- Evidence: E5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input: public `SparseMatrix.hstack(...)` and `SparseMatrix.vstack(...)` calls.
- Observed in V1: signatures are unchanged; inherited stack methods still
  reduce through the first argument's sparse override; return construction still
  uses sparse `_new`/`copy`.
- Expected: sparse joins remain sparse-specific while matching dense shape
  rules for null dimensions.
- V1 status: pass.
- Proof obligations: PO7, PO8.

## F4: Proof is constructed, not machine-checked

- Classification: proof capability / environment gap, not a code bug.
- Evidence: task forbids running tests, Python, `kompile`, or `kprove`.
- Input: all K claims in `sparse-join-spec.k`.
- Observed: proof obligations are constructed and reasoned about statically.
- Expected before test removal or machine-verification claims: run the emitted
  `kompile`/`kprove` commands and receive `#Top`.
- V1 status: no code change. Keep tests; do not claim machine-checked proof.
- Proof obligations: all.

## Proof-derived Findings from `/verify`

No new source defect was found beyond F1 and F2. The adequacy gate passed:
the formal English claims cover the public issue's horizontal and vertical
families and do not rely on legacy sparse output as an oracle.
