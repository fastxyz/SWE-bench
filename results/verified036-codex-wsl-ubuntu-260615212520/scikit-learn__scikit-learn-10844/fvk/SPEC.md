# FVK SPEC - fowlkes_mallows_score overflow fix

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited source change is the arithmetic return expression in
`repo/sklearn/metrics/cluster/supervised.py::fowlkes_mallows_score`.

The formal core models the score kernel after the public implementation has
derived three contingency-count quantities:

- `tk`: pair count for samples clustered together in both labelings.
- `pk`: pair count for samples clustered together in `labels_pred`.
- `qk`: pair count for samples clustered together in `labels_true`.

This is a property-complete abstraction for the reported defect because the
defect is exactly the integer product `pk * qk` in the final score expression.
The label-to-contingency construction is recorded as an implementation
assumption and compatibility boundary, not as a machine-checked proof target.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "`return tk / np.sqrt(pk * qk)` ... produces RuntimeWarning: overflow ... when `(pk * qk)` is bigger" | The implementation must not evaluate the denominator through an overflowing integer product. | Encoded in PO-5 and the K claim comments. |
| I2 | `benchmark/PROBLEM.md` | "Be able to calculate `tk / np.sqrt(pk * qk)` and return a float." | For valid counts, the returned nonzero score must equal the FMI formula. | Encoded in PO-4. |
| I3 | `benchmark/PROBLEM.md` | "I propose to use `np.sqrt(tk / pk) * np.sqrt(tk / qk)` instead" | The proposed algebraic rewrite is public intent evidence, subject to proof of equivalence and denominator safety. | Confirmed by PO-3 and PO-4. |
| I4 | Function docstring and user guide | "FMI = TP / sqrt((TP + FP) * (TP + FN))" | The public score contract is the Fowlkes-Mallows formula. | Encoded in PO-1 and PO-4. |
| I5 | Function docstring and user guide | "The score ranges from 0 to 1" | On valid contingency counts the score should remain bounded. | Encoded in PO-6. |
| I6 | Public examples/tests | perfect labelings score `1.0`; complete split scores `0.0`; handcrafted score is `4 / sqrt(12 * 6)`; symmetry and permutation are expected. | The arithmetic rewrite must preserve existing formula behavior and invariance properties derived from counts. | Encoded in PO-2, PO-4, and PO-6. |
| I7 | Implementation | `tk`, `pk`, and `qk` are computed from the sparse contingency matrix before the return expression. | Count construction provides the variables used by the arithmetic kernel; current audit does not change API or count construction. | Compatibility boundary and PO-7. |

## Intent-Only Contract

For two checked cluster label arrays of equal length, `fowlkes_mallows_score`
returns:

- `0.0` when the shared-pair count is zero.
- Otherwise, the Fowlkes-Mallows index:

  `tk / sqrt(pk * qk)`

where the mathematical counts are nonnegative and contingency-derived, so
`0 < tk <= pk` and `0 < tk <= qk` on the nonzero path.

The implementation must avoid integer overflow in intermediate arithmetic for
the reported large-`pk`, large-`qk` denominator case.

## Candidate V1

V1 computes:

```python
return np.sqrt(tk / pk) * np.sqrt(tk / qk) if tk != 0. else 0.
```

## Formal Model Summary

The formal K artifacts are:

- `fvk/mini-python.k`: a compact score-kernel semantics for `fmi(TK, PK, QK)`.
- `fvk/fowlkes-mallows-spec.k`: claims that the kernel returns the intended
  mathematical score under valid count assumptions.

The model represents the overflow-relevant observable: whether the denominator
is formed by integer multiplication or by two real divisions followed by square
roots. It intentionally abstracts away NumPy arrays, SciPy sparse matrices, and
floating-point rounding.

## Adequacy Verdict

The formal claim matches the intent ledger:

- It proves the public formula, not candidate behavior for its own sake.
- It keeps the zero branch required by public examples.
- It requires only count facts entailed by contingency pair counts.
- It explicitly forbids the integer product that caused the bug.

No source edit beyond V1 is justified by these obligations.
