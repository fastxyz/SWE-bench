# PROOF_OBLIGATIONS.md — `nthroot_mod` fix (sympy__sympy-18199)

Each obligation: statement · why required (ledger/finding link) · discharge status.
Status legend: **DISCHARGED** (constructed proof, see `PROOF.md`) ·
**DISCHARGED-BY-GUARD** (an upstream guard establishes it) ·
**ASSUMED** (`[trusted]` pre-existing, out of audit scope) ·
**ESCALATION** (true, machine-check needs theory beyond bundled tier).

The fix is **correct** iff PO-ROOT, PO-ONLY, PO-PRIME, PO-NGE1, PO-SHAPE,
PO-FRAME-* and PO-REGRESSION all hold. They do.

---

## PO-ROOT — `0` *is* a root
**Statement:** `N ≥ 1 ∧ A modInt P == 0 ⟹ powModP(0, N, P) == A modInt P`.
**Why:** ledger L1/L2; the value the branch returns must actually solve the equation.
**Discharge:** `powModP(0,N,P) = (0 *Int powModP(0,N-1,P)) modInt P = 0` for `N ≥ 1`, and
`A modInt P = 0` by hypothesis, so both sides are `0`. **DISCHARGED** (PROOF.md §A).

## PO-ONLY — `0` is the *only* root (completeness)
**Statement:** `isPrime(P) ∧ N ≥ 1 ∧ (X^N) modInt P == 0 ∧ 0 ≤ X < P ⟹ X == 0`.
Equivalently `roots(A,N,P) ⊆ {0}` when `A ≡ 0`.
**Why:** ledger L4 (result must be the *complete* set — no spurious omission *and* no missing
root); without it `[0]` might be an under- or over-approximation.
**Discharge:** Euclid's lemma. `P | X^N` and `P` prime ⟹ `P | X` (induction on `N ≥ 1`); with
`0 ≤ X < P` that forces `X = 0`. **DISCHARGED** by hand (PROOF.md §B); machine discharge is
**ESCALATION** (needs inductive primality theory in K — see FINDINGS PF2). *Counterexample
when `P` not prime: `P=4, N=2, X=2` — which is exactly why PO-PRIME is mandatory.*

## PO-PRIME — `P` is prime at the branch
**Statement:** Control reaches line 779 only in states satisfying `isPrime(P)`.
**Why:** PO-ONLY is *false* for composite `P`; the branch must never run out of that domain.
**Discharge:** line 776 `if not isprime(p): raise NotImplementedError` precedes line 779; any
non-prime `p` raises and never reaches the branch. **DISCHARGED-BY-GUARD** (FINDINGS F2/F6).

## PO-NGE1 — `N ≥ 1` at the branch
**Statement:** Control reaches line 779 only in states satisfying `N ≥ 1`.
**Why:** PO-ROOT and PO-ONLY both need `N ≥ 1` (`0^0 = 1 ≠ 0`; the lemma's product needs ≥1
factor).
**Discharge:** `is_nthpow_residue` raises for `n<0` (line 634); for `n==0` it returns
`a==1` (line 637–640), which is `False` whenever `a%p==0` (a multiple of a prime `p` is never
`1`), so `nthroot_mod` returns `None` at line 775 before the branch; `n==2` returns at line 771
before the branch. Therefore every state at line 779 has `n ∈ {1,3,4,…}`.
**DISCHARGED-BY-GUARD** (FINDINGS F2).

## PO-EQUIV — guard ⟺ "0 is a root"
**Statement:** For `N ≥ 1`: `A modInt P == 0  ⟺  0 ∈ roots(A,N,P)`.
**Why:** the guard `a % p == 0` must fire *exactly* when `0` is a root — no false positive
(returning `[0]` when `0` is not a root) and no false negative.
**Discharge:** `0 ∈ roots ⟺ powModP(0,N,P) == A modInt P ⟺ 0 == A modInt P` (by PO-ROOT's
computation) `⟺ A modInt P == 0`. **DISCHARGED** (PROOF.md §A).

## PO-COMPLETE — returned value = contract value
**Statement:** Under the branch precondition, `[0] if all_roots else 0` equals
`sortedList(roots)` resp. `min(roots)`.
**Why:** ledger L4/L5 — match the function's documented output shape.
**Discharge:** from PO-ROOT+PO-ONLY, `roots(A,N,P) = {0}`; `sortedList({0}) = [0]`,
`min({0}) = 0`. **DISCHARGED** (PROOF.md §C).

## PO-SHAPE — return-type consistency
**Statement:** Branch returns `int` when `all_roots=False` and `list[int]` when `True`.
**Why:** ledger L5; callers (incl. `solveset.py:1211` iterating the list) depend on it.
**Discharge:** literal `0` is `int`; `[0]` is `list`. Matches every sibling branch.
**DISCHARGED** (FINDINGS PF3).

## PO-FRAME-COMPOSITE — composite-`p` behavior preserved
**Statement:** For composite `p`, `nthroot_mod` still raises `NotImplementedError` (incl. when
`a%p==0`).
**Why:** ledger L6 — do not change the supported domain.
**Discharge:** guard at line 776 is upstream of and unchanged by the fix.
**DISCHARGED-BY-GUARD** (FINDINGS F6 / CLAIM-PRIME-GUARD).

## PO-FRAME-NONE — "no root ⟹ None" preserved
**Statement:** When `is_nthpow_residue` is False, the function still returns `None`.
**Why:** ledger L7.
**Discharge:** guard at lines 774–775 is upstream of and unchanged by the fix; and for
`a%p==0` the residue check is `True`, so the branch (not `None`) is the correct outcome.
**DISCHARGED-BY-GUARD** (CLAIM-RESIDUE-GUARD).

## PO-FRAME-N2 — `n==2` path preserved and consistent
**Statement:** `n==2` still delegates to `sqrt_mod`, which returns `0`/`[0]` for `a≡0`.
**Why:** ledger L8; avoid divergent answers between `n==2` and `n≠2` on `a≡0`.
**Discharge:** line 771 unchanged; `sqrt_mod_iter` lines 323–326 + `_sqrt_mod1(0,p,1)` yield
`[0]`. **ASSUMED** (pre-existing, tested) + checked consistent (FINDINGS F3 / CLAIM-SQRT).

## PO-SOLVE — pre-existing solver correct on `a%p≠0`
**Statement:** For `isPrime(P) ∧ A modInt P ≠ 0 ∧ isNthPowResidue`, `_nthroot_mod1`/gcd paths
return `roots(A,N,P)` correctly.
**Why:** the fix's `else` falls through to these paths; their correctness is needed for the
*whole* function but is **not** what this change touches.
**Discharge:** **ASSUMED** `[trusted]` (ASSUME-SOLVE); full proof is **ESCALATION** (primitive
roots, discrete log, structure of `(Z/pZ)*`). Untouched by V1 and covered by existing tests
`test_residue.py:166–187`.

## PO-REGRESSION — existing tests still pass
**Statement:** No existing assertion in `test_residue.py` changes outcome.
**Why:** the change must be purely additive on the `a≡0` slice.
**Discharge:** the exhaustive loop ranges `a ∈ [1, p-2]` (never `≡ 0`); the explicit cases all
have `a%p≠0` or exercise the `n==2`/composite branches the fix doesn't touch. The new guard is
only reachable on inputs none of those tests use. **DISCHARGED** (FINDINGS PF4).

---

### Summary

| PO | status |
|----|--------|
| PO-ROOT | DISCHARGED |
| PO-ONLY | DISCHARGED (hand) / ESCALATION (machine) |
| PO-PRIME | DISCHARGED-BY-GUARD |
| PO-NGE1 | DISCHARGED-BY-GUARD |
| PO-EQUIV | DISCHARGED |
| PO-COMPLETE | DISCHARGED |
| PO-SHAPE | DISCHARGED |
| PO-FRAME-COMPOSITE | DISCHARGED-BY-GUARD |
| PO-FRAME-NONE | DISCHARGED-BY-GUARD |
| PO-FRAME-N2 | ASSUMED + consistency-checked |
| PO-SOLVE | ASSUMED / ESCALATION (out of scope) |
| PO-REGRESSION | DISCHARGED |

No obligation is **open against the fix**. The only ESCALATION items are (i) a *machine*
recheck of an elementary lemma already proved by hand, and (ii) the pre-existing solver that
the fix does not modify. **Conclusion: V1 is correct and stands.**
