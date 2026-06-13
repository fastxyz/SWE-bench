# PROOF.md — constructed correctness proof (CDS #14369, V1)

**Constructed, not machine-checked.** The FVK MVP builds the proof and emits the
`kompile`/`kprove` commands but does not run them. The Findings (benefit 2) and the
code-trace obligations stand independently of the machine check.

Artifacts: [`mini-cds.k`](mini-cds.k) (semantics), [`mini-cds-spec.k`](mini-cds-spec.k)
(claims). Claims and obligations: [SPEC.md](SPEC.md), [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md).

---

## 1. What is proved, in one sentence

For every leading unit `A`, every denominator sequence `L = [u1,…,un]`, and every
base generator `I`, the V1 left-recursive grammar reduces `A/u1/…/un` to a unit whose
`I`-exponent is `expo(A,I) − Σ_k expo(u_k,I)` — i.e. `A / (u1·…·un)` — and the V0
right-recursive grammar does **not**.

## 2. (DIVCHAIN) by guarded coinduction — the recursion circularity

Claim `(DIVCHAIN)`:  `expo(pdiv(A,L),I) => expo(A,I) -Int sumExpo(L,I)`  `[all-path]`.

K treats this very claim as its own coinduction hypothesis; it is used only after a
genuine `=>⁺` step (guardedness). Case-split on `L`.

**Base, `L = .UnitList`.** Symbolic execution:
```
expo(pdiv(A, .UnitList), I)
  => expo(A, I)                          // rule pdiv(A,.UnitList) => A
```
RHS of the claim: `expo(A,I) -Int sumExpo(.UnitList, I) => expo(A,I) -Int 0`.
VC-BASE: `expo(A,I) == expo(A,I) -Int 0`. **Linear → Z3 → #Top.**

**Step, `L = X : Xs`.** The genuine step (this discharges guardedness):
```
expo(pdiv(A, X : Xs), I)
  => expo(pdiv(div(A,X), Xs), I)         // rule pdiv(A,X:Xs) => pdiv(div(A,X),Xs)
```
Now invoke the **circularity** on the shifted state `{A := div(A,X), L := Xs}`
(legal: one real step has been taken). It rewrites the goal to:
```
  => expo(div(A,X), I) -Int sumExpo(Xs, I)
  => (expo(A,I) -Int expo(X,I)) -Int sumExpo(Xs, I)   // expo(div(A,B),I) => expo(A,I) -Int expo(B,I)
```
The claim's RHS at `L = X:Xs`:
```
expo(A,I) -Int sumExpo(X:Xs, I)
  => expo(A,I) -Int (expo(X,I) +Int sumExpo(Xs,I))    // sumExpo(X:Xs,I) => expo(X,I) +Int sumExpo(Xs,I)
```
VC-STEP (Consequence): 
`(expo(A,I) - expo(X,I)) - sumExpo(Xs,I)  ==  expo(A,I) - (expo(X,I) + sumExpo(Xs,I))`.
Pure linear integer arithmetic (associativity of `+`/`−` over ℤ). **Z3 → #Top.**

Both branches reach the claimed post-state ⇒ `(DIVCHAIN)` is constructed. ∎
`(LEADDIV)` is the instance `A = one` (`expo(one,I) => 0`); nothing new to prove.

**No `[simplification]` lemmas needed.** Because `expo` is a homomorphism, the only
VCs are VC-BASE and VC-STEP, both linear — contrast the `sum` example, which needed
the even-product halving lemma. The absence of any nonlinear/awkward VC is the
formal evidence that the division logic is clean and complete on its domain.

## 3. Where the group laws enter (PO-2-AXIOMS)

The step used `expo(div(A,X),I) = expo(A,I) − expo(X,I)`, which unfolds
`div(A,X)=mul(A,inv(X))` and `expo(mul(_,_))`/`expo(inv(_))`. The collapse
`Σ_k expo(u_k,I)` ↦ `expo(prod(L),I)` (i.e. that the *intended denominator* is the
product) is `inv` distributing over `mul` plus `expo` additivity. These are the
abelian-group axioms; in astropy they are theorems of `CompositeUnit`, so the proof's
assumptions are met by the host type (PO-2-AXIOMS, [FINDINGS.md](FINDINGS.md) F-4).
Associativity/identity are used implicitly: the left-nested fold
`mul(…mul(mul(A,inv(u1)),inv(u2))…,inv(un))` and the homomorphic image agree because
in `(ℤ,+)` addition is associative — which is why we never needed `mul`-commutativity.

## 4. (BUG-V0) — the old code is provably wrong

Claim `(BUG-V0)`:
`expo(pdivR(A, X1:X2:.UnitList), I) => (expo(A,I) -Int expo(X1,I)) +Int expo(X2,I)`.
```
expo(pdivR(A, X1:X2:ε), I)
  => expo(div(A, pdivR(X2:ε ... )), I)             // wait: pdivR(A,X1:Xs)=>div(A,pdivR(X1,Xs)) with Xs = X2:ε
```
Carefully, with `pdivR(A, X:Xs) => div(A, pdivR(X,Xs))`:
```
expo(pdivR(A, X1:(X2:ε)), I)
  => expo(div(A, pdivR(X1, X2:ε)), I)              // outer
  => expo(div(A, div(X1, pdivR(X2, ε))), I)        // inner
  => expo(div(A, div(X1, X2)), I)                  // pdivR(X2,ε)=>X2
  => expo(A,I) -Int expo(div(X1,X2),I)             // expo(div)
  => expo(A,I) -Int (expo(X1,I) -Int expo(X2,I))
  => (expo(A,I) -Int expo(X1,I)) +Int expo(X2,I)   // arithmetic
```
**Z3 → #Top** for `(BUG-V0)`. Now compare with `(DIVCHAIN)` at the same input,
`expo(A,I) -Int expo(X1,I) -Int expo(X2,I)`. The two postconditions differ by
`2·expo(X2,I)`. For `X2 = gen(k)` (a real base unit, exponent 1) the difference is
`2 ≠ 0`. Concretely on the issue's `J/s/kpc2` (`A=J`, `X1=s`, `X2=kpc2`,
`I = kpc`): V1 gives `expo = −2` (kpc in the denominator), V0 gives `expo = +2`
(kpc in the numerator) — exactly the reported `1e-7 J kpc2 / s`. The bug and its fix
are now both formal facts. ∎

## 5. Infrastructure obligations (code-trace, machine-checkable by reading PLY)

- **PO-REGEN.** Discharged in [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md) §PO-4: the
  `_tabversion='0.0'` sentinel forces `read_table` → `VersionError` → catch (`:3302`)
  → rebuild from live grammar, on writable *and* read-only filesystems. Without this
  step, `optimize=True` (`:3294`) would reuse the V0 table and the §2 proof would
  describe code that does not run (F-2).
- **PO-NO-CONFLICT.** Discharged in [PROOF_OBLIGATIONS.md](PROOF_OBLIGATIONS.md) §PO-5
  by FOLLOW-set analysis: PRODUCT/DIVISION ∉ FOLLOW(product_of_units), so the
  post-`unit_expression` state has no shift/reduce conflict; the grammar is LALR(1).

## 6. Run-commands (to upgrade "constructed" → "machine-checked")

```sh
kompile mini-cds.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-cds-spec.k   # (optional) confirm the claims parse
kprove  mini-cds-spec.k                      # expected: #Top for (DIVCHAIN),(LEADDIV),(BUG-V0)
```
A `#Top` on all three upgrades the result from *constructed* to *machine-verified*.
Independently, the real grammar can be machine-confirmed conflict-free by deleting
`astropy/units/format/cds_parsetab.py` and running PLY with `debug=1`
(expect "0 shift/reduce, 0 reduce/reduce").

## 7. Residual risk

- **Partial vs total.** Total correctness is immediate here (`pdiv`/`pdivR` recurse
  on a strictly shorter list; the real parse is over a finite token stream), so the
  usual partial-correctness caveat is vacuous — noted, not separately proved.
- **Trusted base.** (a) Adequacy of the mini-CDS fragment: it models the division
  reduction faithfully but abstracts the unit as its exponent vector and omits scale
  (justified in [SPEC.md](SPEC.md) §3). (b) The PLY code-trace (PO-REGEN/PO-NO-CONFLICT)
  is read off the bundled `astropy/extern/ply/yacc.py`, not executed. (c) The
  reachability metatheory + Z3 oracle, used as usual.
- **"Constructed, not machine-checked"** applies to §2/§4; the §5 obligations are
  ordinary code-reading and do not need K.

## 8. The two benefit payoffs (plain language)

- **Benefit 2 (bugs):** formalizing surfaced *two* findings a unit test would miss —
  the associativity bug it was meant to fix (F-1), and the silent no-op trap that the
  obvious one-line grammar edit would have fallen into (F-2, PO-REGEN).
- **Benefit 1 (tests):** once `(DIVCHAIN)` is machine-checked, single-point `/`-chain
  unit tests are subsumed; the out-of-domain (F-3) and failure (PO-8) tests are kept.
  Recommendation only — see [FINDINGS.md](FINDINGS.md), conditioned on `kprove #Top`.
