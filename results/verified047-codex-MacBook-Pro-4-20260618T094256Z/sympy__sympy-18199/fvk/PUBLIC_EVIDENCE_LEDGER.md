# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "nthroot_mod function misses one root of x = 0 mod p." | Zero-residue root must not be omitted. | Encoded in zero-root claims. |
| E2 | `benchmark/PROBLEM.md` | "When in the equation x**n = a mod p , when a % p == 0. Then x = 0 mod p is also a root" | Obligation is keyed by `a % p == 0`, over modular congruence. | Encoded; V1 negative-multiple gap recorded in `FINDINGS.md`. |
| E3 | `benchmark/PROBLEM.md` | "`nthroot_mod(17*17, 5 , 17)` has a root `0 mod 17`." | Concrete example must return/include zero for scalar/list modes. | Encoded as an instance of the symbolic zero-root claims. |
| E4 | `nthroot_mod` docstring | "Find the solutions to ``x**n = a mod p``" | Returned values must be roots of the modular equation. | Encoded in postconditions and English spec. |
| E5 | `nthroot_mod` parameter docs | "`a : integer`; `n : positive integer`; `p : positive integer`" | Negative multiples of `p` are not excluded by `nthroot_mod`'s public parameter docs; `n <= 0` and `p <= 0` are outside this audit. | Encoded as a V1 finding and V2 preconditions. |
| E6 | `nthroot_mod` parameter docs | "`all_roots : if False returns the smallest root, else the list of roots`" | Scalar mode returns `0`; list mode returns `[0]` for the singleton zero-root set. | Encoded in separate scalar/list claims. |
| E7 | Existing implementation | `if n == 2: return sqrt_mod(a, p, all_roots)` | Square-root path is a compatibility frame condition. | Encoded as frame claim; not changed. |
| E8 | Existing implementation and public tests | `raise NotImplementedError("Not implemented for composite p")`; tests assert composite examples raise. | Composite `p` with `n > 2` remains outside implemented domain. | Encoded as frame claim; preserved for zero residue too. |
| E9 | `solveset.py` public callsite | `_invert_modular` calls `nthroot_mod(..., all_roots=True)` and iterates returned remainders unless `None`. | `all_roots=True` must keep returning either `None` or an iterable list. `[0]` is compatible. | Compatibility audit passes. |
| E10 | Existing public tests | Nonzero examples assert `pow(r, q, p) == a`, and all-root nonzero cases compare computed lists. | Nonzero residue behavior is public compatibility surface, but not the zero-residue bug. | Encoded as nonzero frame claim; not changed. |
