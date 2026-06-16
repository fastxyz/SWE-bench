# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | `benchmark/PROBLEM.md` | "`a.is_even` does not imply `a.is_finite`" | `even=True` must entail `finite=True` for old `.is_*` assumptions. | Encoded in the even claim and PO-2. |
| E-2 | `benchmark/PROBLEM.md` | "I would expect that a number should be finite before it can be even." | Parity facts describe integer numbers, so finiteness is a semantic prerequisite. | Encoded in SPEC and PO-2. |
| E-3 | `benchmark/PROBLEM.md` | "Similarly: `i = Symbol('i', integer=True)` ... `print(i.is_finite)` None" | `integer=True` must entail `finite=True`. | Encoded in the integer claim and PO-3. |
| E-4 | Public hint in `benchmark/PROBLEM.md` | "`rational -> real` should be extended to `rational -> real & finite`" | The minimal implication is `rational -> finite`; it covers integer and parity through existing rules. | Implemented in `sympy/core/assumptions.py`; encoded in the rational claim and PO-1. |
| E-5 | Public hint in `benchmark/PROBLEM.md` | "adding `finite` to `real` would probably break a lot of code" | Do not add `real -> finite` in the old assumption rules for this issue. | Encoded as a frame claim and PO-5. |
| E-6 | `repo/sympy/core/assumptions.py` | `integer -> rational`; `even == integer & !odd`; `odd == integer & !even` | A single rational-level rule should propagate to integer, even, and odd through existing closure. | Encoded in mini semantics and proof sketch. |
| E-7 | `repo/sympy/core/symbol.py` | `Symbol.__new_stage2__` stores constructor assumptions in `StdFactKB`. | The changed rule must act through the existing constructor path, not through special cases in `Symbol`. | Satisfied by changing only `_assume_rules`. |
| E-8 | `repo/sympy/assumptions/tests/test_query.py` | Public tests combine `Q.positive(x)` and `~Q.finite(x)` in finite-addition reasoning. | Do not broaden the repair to `Q.real -> Q.finite` or sign predicates in the newer `ask` engine in this pass. | Recorded as compatibility finding F-4. |
