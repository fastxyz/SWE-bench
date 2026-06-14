# Key FVK artifact excerpts (sympy__sympy-18199)

Artifacts dir: `results/batch5-XC-MINI-PRO-AHP-260614105258/sympy__sympy-18199/fvk/`
Markdown-only: SPEC.md, FINDINGS.md, PROOF_OBLIGATIONS.md, PROOF.md, ITERATION_GUIDANCE.md.
NO `.k` files (K source embedded as fenced blocks inside SPEC.md). This is expected, not incompleteness.

solution_baseline.patch == solution_fvk.patch (md5 528d474404f1adc012afc8c827f949e5, byte-identical).
=> FVK CONFIRMED V1 unchanged; it produced no new code.

## V1 == final FVK patch (the entire change)  [solutions/solution_fvk.patch]

```diff
@@ -776,6 +776,10 @@ def nthroot_mod(a, n, p, all_roots=False):
     if not isprime(p):
         raise NotImplementedError("Not implemented for composite p")
 
+    if a % p == 0:
+        # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
+        return [0] if all_roots else 0
+
     if (p - 1) % n == 0:
         return _nthroot_mod1(a, n, p, all_roots)
```

V1 only adds the prime-`p` zero-root branch. It leaves `raise NotImplementedError("Not implemented
for composite p")` in place. The gold patch DELETES that raise and routes composite p to a new
`_nthroot_mod_composite` helper (see oracle_patch.diff).

================================================================================
## THE DECISIVE EXCERPTS — FVK fences the composite axis OUT OF SCOPE and certifies the bug
================================================================================

### SPEC.md:29 (intent ledger row L6) — composite NotImplementedError treated as a contract to PRESERVE
```
| L6 | code (line 776) | `if not isprime(p): raise NotImplementedError` | Domain is **prime `p`** only; composite `p` raises (must be **preserved**). | frame / preserve |
```
=> FVK classifies the very behavior the gold patch REMOVES ("composite p raises") as a frame
   condition that "must be preserved." The composite axis is excluded from the spec domain
   before any obligation is written. (Tell #7: scope-induced false negative.)

### SPEC.md:209-210 (human-readable spec note) — composite raise enshrined as the spec
```
`nthroot_mod(a, n, p, all_roots)` returns the solutions of `x**n ≡ a (mod p)` in `[0, p)`
(`p` prime; composite `p` raises `NotImplementedError`; `None` when there is no solution).
```

### FINDINGS.md:75-79 (F6 — [POSITIVE]) — the bug certified as correct behavior
```
## F6 — [POSITIVE] Composite-`p` contract preserved

- input `nthroot_mod(0, 5, 12)` → still `NotImplementedError` (line 777), because the new
  guard sits *after* the `isprime` check. The fix does not silently start "supporting" a
  case the function never supported. Confirms frame obligation `PO-FRAME-COMPOSITE`.
```
=> The graded test `test_solve_modular` requires `solveset(Mod(x**3,8)-1,...)` (8=2^3 composite)
   to be SOLVED. FVK marks the opposite — raising on composite p — as [POSITIVE], i.e. it
   certifies the buggy output as the intended spec. (Tell #9: false-positive certification.)

### SPEC.md:12-16 (Scope blockquote) — verification deliberately narrowed to the a%p==0 branch
```
> **Scope.** `/formalize` is run in *intent-spec mode*. The verified object is the
> **new branch** and its interaction with the surrounding guards. The two pre-existing
> solving paths (`_nthroot_mod1`, and the gcd-on-exponents loop) are **assumed correct
> on their own domain** (`a % p != 0`) ... their full correctness is an explicit
> `[ESCALATION BOUNDARY]` (see §5).
```

### CLAIM-PRIME-GUARD (SPEC.md:165-172) — proves composite p "still raises" as a goal
```
### CLAIM-PRIME-GUARD (frame, L6) — composite `p` still raises
claim <k> PGM_nthroot => .K </k>
  <env> a|->A n|->N p|->P all_roots|->AR </env>
  <out> _ => raised </out>
  requires isNthPowResidue(A,N,P) andBool notBool isPrime(P) [all-path]
```
=> FVK actively constructs a claim asserting that composite p MUST raise — the exact behavior
   the gold patch removes.

### ITERATION_GUIDANCE.md:16 — declares intent fully met, no open question
```
- **UltimatePowers question:** none — intent (issue L1–L3) is fully met.
```
=> The audit treats the issue text (L1-L3, prime zero-root only) as the WHOLE spec, concludes
   "intent fully met," and never reconsiders the composite axis the hidden test measures.

### PROOF_OBLIGATIONS.md / PROOF.md / fvk_notes.md — V1 certified correct & complete
- PROOF_OBLIGATIONS.md:123 — "**Conclusion: V1 is correct and stands.**"
- PROOF.md:16-19 — "For every prime `p`, every `n >= 1`, ... returns the **complete and correct**
  root set ... because for a prime modulus that root set is exactly `{0}`."
- reports/fvk_notes.md:3 — "**Outcome: V1 stands unchanged.**"
  (Note: PROOF.md correctly restricts its completeness claim to "for every PRIME p" — the spec
   is internally honest on the prime domain; the failure is that the domain was chosen to exclude
   the composite axis the test grades.)

================================================================================
## What the artifacts DO correctly capture (the zero-root half of the gold fix)
================================================================================
The prime-`p` zero-root cause is STATED precisely and repeatedly:
- SPEC.md:24-26 (ledger L1-L3): "nthroot_mod function misses one root of x = 0 mod p", "a % p == 0 ==> 0 is a root".
- FINDINGS.md:10-31 (F1 [BUG, FIXED BY V1]): exact failure taxonomy incl. the crash modes
  `nthroot_mod(11,5,11)` -> "ValueError: Log does not exist", resolution = short-circuit `a%p==0` to `[0]`/`0`.
- PROOF_OBLIGATIONS PO-ROOT / PO-ONLY: `0` is a root and the only root for prime p (Euclid's lemma).
But this half corresponds only to the (non-graded) prime `nthroot_mod(0,12,37,True)==[0]` assertion
in test_residue — NOT to the graded `test_solve_modular`, which is entirely composite-modulus.
