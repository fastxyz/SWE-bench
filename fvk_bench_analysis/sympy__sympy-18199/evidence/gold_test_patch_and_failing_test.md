# Gold test patch + the FAIL_TO_PASS test (sympy__sympy-18199)

Source: `logs/run_evaluation/batch5-XC-MINI-PRO-AHP-260614105258.goldcheck/gold/sympy__sympy-18199/eval.sh`
(the `git apply` heredoc; `instances.json` has no `test_patch` field).

The sole graded **FAIL_TO_PASS** test is `test_solve_modular` (in `sympy/solvers/tests/test_solveset.py`).
`test_residue` (in `sympy/ntheory/tests/test_residue.py`) is run alongside but the authoritative
`eval/fvk.report.json` lists ONLY `test_solve_modular` as FAIL_TO_PASS.

## The graded test change — `test_solve_modular` (test_solveset.py)

```diff
@@ -2242,11 +2242,12 @@ def test_solve_modular():
     assert solveset(Mod(3**(3**x), 4) - 3, x, S.Integers) == \
             Intersection(ImageSet(Lambda(n, Intersection({log(2*n + 1)/log(3)},
             S.Integers)), S.Naturals0), S.Integers)
-    # Not Implemented for m without primitive root
+    # Implemented for m without primitive root
     assert solveset(Mod(x**3, 8) - 1, x, S.Integers) == \
-            ConditionSet(x, Eq(Mod(x**3, 8) - 1, 0), S.Integers)
+            ImageSet(Lambda(n, 8*n + 1), S.Integers)
     assert solveset(Mod(x**4, 9) - 4, x, S.Integers) == \
-            ConditionSet(x, Eq(Mod(x**4, 9) - 4, 0), S.Integers)
+            Union(ImageSet(Lambda(n, 9*n + 4), S.Integers),
+            ImageSet(Lambda(n, 9*n + 5), S.Integers))
```

CRITICAL: the two assertions that flip from `ConditionSet` (unsolved) to a real `ImageSet`/`Union`
are BOTH **composite moduli**: `8 = 2**3` and `9 = 3**2`. The comment literally changes from
"Not Implemented for m without primitive root" to "Implemented for m without primitive root."
These are the lines that make `test_solve_modular` FAIL unless composite-modulus support is added.
The prime-modulus `a%p==0` zero-root fix (V1/FVK) does NOT touch this path.

## The ntheory test change — `test_residue` (test_residue.py) [run alongside, not the graded F2P]

```diff
@@ -162,7 +162,8 @@ def test_residue():
     assert is_nthpow_residue(8547, 12, 10007)
-    raises(NotImplementedError, lambda: nthroot_mod(29, 31, 74))
+    assert nthroot_mod(29, 31, 74) == [45]          # 74 = 2*37 composite
@@ -170,8 +171,12 @@ def test_residue():
     assert nthroot_mod(11, 3, 109) is None
-    raises(NotImplementedError, lambda: nthroot_mod(16, 5, 36))
-    raises(NotImplementedError, lambda: nthroot_mod(9, 16, 36))
+    assert nthroot_mod(16, 5, 36, True) == [4, 22]          # 36 composite
+    assert nthroot_mod(9, 16, 36, True) == [3, 9, 15, 21, 27, 33]
+    assert nthroot_mod(4, 3, 3249000) == []
+    assert nthroot_mod(36010, 8, 87382, True) == [40208, 47174]
+    assert nthroot_mod(0, 12, 37, True) == [0]             # the zero-root case (prime 37)
+    assert nthroot_mod(0, 7, 100, True) == [0, 10, ... 90] # zero-root, composite 100
```

Note: the *only* assertions in `test_residue` that the V1/FVK zero-root fix satisfies are the
prime `nthroot_mod(0, 12, 37, True) == [0]`. ALL the other new assertions require composite
support. And `test_residue` is NOT the graded FAIL_TO_PASS anyway.

## Problem statement (instances.json) — full text

> nthroot_mod function misses one root of x = 0 mod p.
> When in the equation x**n = a mod p , when a % p == 0. Then x = 0 mod p is also a root of
> this equation. But right now `nthroot_mod` does not check for this condition.
> `nthroot_mod(17*17, 5 , 17)` has a root `0 mod 17`. But it does not return it.

The problem statement is EXCLUSIVELY about the prime-`p` zero-root case. It NEVER mentions
composite moduli. The example `nthroot_mod(17*17, 5, 17)` uses a PRIME modulus (17).

## Authoritative eval result (eval/fvk.report.json)

- resolved: false
- FAIL_TO_PASS.failure: ["test_solve_modular"]   (success: [])
- PASS_TO_PASS: 113/113 success
- baseline.report.json and control.report.json: identical FAIL_TO_PASS failure on test_solve_modular.
  => zero flips; fvk == baseline outcome.
