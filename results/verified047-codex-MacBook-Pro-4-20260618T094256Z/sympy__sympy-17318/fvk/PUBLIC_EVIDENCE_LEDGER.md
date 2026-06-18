# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "`sqrtdenest` raises `IndexError`" with traceback through `_sqrt_match`, `split_surds`, `_split_gcd`. | The reported exception is the bug symptom and must be removed. | Encoded by claims C1-C3. |
| E2 | `benchmark/PROBLEM.md` | "If an expression cannot be denested it should be returned unchanged." | Unsupported denesting inputs must take a no-match/no-op path rather than raise. | Encoded by claims C1, C3, C4. |
| E3 | `benchmark/PROBLEM.md` | "`sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)` raises the same error." | The `4 + I` radicand must not enter the real-surd splitting path. | Encoded by claim C1. |
| E4 | `benchmark/PROBLEM.md` | "`split_surds` is designed to split ... regular non-complex square roots." | `_sqrt_match` should gate `split_surds` to positive real-surd candidates. | Encoded by claim C1 and SPEC rule S1. |
| E5 | `benchmark/PROBLEM.md` | "`4+I` ... leads to an empty `surds` list." | `split_surds` must handle no-surd inputs before `_split_gcd`. | Encoded by claim C2. |
| E6 | `benchmark/PROBLEM.md` | "`rad_rationalize` is part of the user documentation, it shouldn't fail like this." | `rad_rationalize(1, 4 + I)` must not raise; no-op is acceptable when no square root can be removed. | Encoded by claim C3. |
| E7 | `benchmark/PROBLEM.md` | "`rad_rationalize(1,1+cbrt(2))`" leads to infinite recursion. | A denominator with no supported square-root term must stop without recursive progress. | Encoded by claim C4. |
| E8 | `benchmark/PROBLEM.md` | "`rad_rationalize(1,sqrt(2)+I)` returns `(sqrt(2) - I, 3)`." | Mixed sqrt/complex denominators with a supported sqrt term must still use the rationalizing path. | Encoded by claim C5. |
| E9 | `benchmark/PROBLEM.md` | "Please do not add bare except statements." | The implementation must use source-level guards instead of catching all exceptions. | Audited in FINDINGS.md; V1 satisfies. |
| E10 | `repo/sympy/simplify/radsimp.py` docstring | `split_surds(3*sqrt(3) + sqrt(5)/7 + sqrt(6) + sqrt(10) + sqrt(15))` returns the documented grouping. | The documented regular-surd example is a frame condition. | Encoded by claim C6. |
| E11 | implementation | `_split_gcd` starts with `g = a[0]`. | Callers must supply at least one surd or avoid calling it. | Reflected in SPEC.md and claims C2-C4. |
| E12 | implementation | V1 preserves helper signatures and tuple/list return shapes. | Public/internal callsites should not require protocol changes. | Audited in PUBLIC_COMPATIBILITY_AUDIT.md. |
