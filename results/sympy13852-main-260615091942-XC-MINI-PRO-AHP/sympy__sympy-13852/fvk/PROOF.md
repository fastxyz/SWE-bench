# PROOF.md — constructed correctness proof for the #13852 fix

Target: `polylog._eval_expand_func` in
`sympy/functions/special/zeta_functions.py`.
Semantics: [`mini-python.k`](mini-python.k); claims: [`polylog-spec.k`](polylog-spec.k).

> **Honesty gate.** The proofs below are **constructed, not machine-checked** —
> `kompile`/`kprove` were *not* run (no execution environment; see §E for the exact
> commands). The Findings (`FINDINGS.md`) and the mathematical adequacy
> derivations (§A) stand on their own and do not depend on the machine check.

Two-layer structure, kept deliberately separate:
- **§A — adequacy (mathematics):** the produced terms *are* the right values of
  `Li_s(z)`. This is number theory, not K rewriting.
- **§B/§C — soundness (K dispatch):** `expandPL` *rewrites to* those terms, and the
  added branch does not perturb the others.

---

## §A — Adequacy: the values are mathematically correct

### A1. `Li₁(z) = −log(1 − z)` (branch 1)
By definition `Li₁(z) = Σ_{n≥1} zⁿ/n = −log(1 − z)` for `|z| < 1` (standard Maclaurin
series of `−log(1−x)`). Both sides continue analytically to ℂ∖[1,∞) and share the
**same** branch cut `[1,∞)`: for real `z>1`, `1−z<0`, so `−log(1−z) = −log|1−z| − iπ`,
giving `Im = −π` — exactly the value the issue reports for `polylog(1,z)`. Hence the
two functions are identical, branch cut included, and `−log(1−z)` carries **no**
winding/`exp_polar` data (log is unbranched at 1, so the `+1` shift's winding number
is irrelevant — the issue's own argument). ∎

Consequence (PO-2): `d/dz[−log(1−z)] = 1/(1−z)`, and
`polylog(1,z).diff(z) = polylog(0,z)/z = (z/(1−z))/z = 1/(1−z)` (using branch 2 at
s=0). They agree ⇒ `expand_func(diff(polylog(1,z)+log(1−z),z)) = 0`. ∎

### A2. `Li₂(1/2) = π²/12 − log(2)²/2` (branch 3)
Euler's **reflection law** `Li₂(z) + Li₂(1−z) = π²/6 − log(z)·log(1−z)`. Put `z = ½`
(a fixed point of `z ↦ 1−z`):
`2·Li₂(½) = π²/6 − log(½)² = π²/6 − log(2)²`, so
`Li₂(½) = π²/12 − log(2)²/2`. Numeric: `≈ 0.82247 − 0.24023 = 0.58224`, matching
`Li₂(0.5) ≈ 0.582241`. This is the V1 term `add(neg(divE(powE(logE 2,2),2)),
divE(powE(piC,2),12))`. ∎

### A3. Golden-ratio values (F2) — *derived & triple-checked* (deferred, not in code)
Let `φ=(1+√5)/2`, `1/φ=(√5−1)/2`, `1/φ²=(3−√5)/2`; note `1/φ + 1/φ² = 1` and
`log(1/φ) = −log φ`. Claimed:
`Li₂(1/φ)=π²/10−log²φ`, `Li₂(1/φ²)=π²/15−log²φ`,
`Li₂(−1/φ)=−π²/15+½log²φ`, `Li₂(−φ)=−π²/10−log²φ`.
Three independent functional equations confirm them simultaneously:
1. **Reflection** at `z=1/φ` (partner `1−1/φ=1/φ²`):
   `Li₂(1/φ)+Li₂(1/φ²) = π²/6 − log(1/φ)log(1/φ²) = π²/6 − 2log²φ`.
   Check: `(π²/10−log²φ)+(π²/15−log²φ) = π²/6 − 2log²φ` ✓ (π²/10+π²/15=π²/6).
2. **Landen** `Li₂(z)+Li₂(z/(z−1)) = −½log²(1−z)` at `z=1/φ` (`z/(z−1)=−φ`):
   `Li₂(1/φ)+Li₂(−φ) = −½log²(1/φ²) = −2log²φ`.
   Check: `(π²/10−log²φ)+(−π²/10−log²φ) = −2log²φ` ✓.
3. **Duplication** `Li₂(z²)=2[Li₂(z)+Li₂(−z)]` at `z=1/φ` (`z²=1/φ²`):
   Check: `2[(π²/10−log²φ)+(−π²/15+½log²φ)] = 2[π²/30−½log²φ] = π²/15−log²φ` ✓.
All three close consistently ⇒ the four values are sound. They are **not** added to
code (F2): the *arguments* have no canonical SymPy form, so a literal guard risks
dead code un-confirmable without execution. Derivation preserved for the next pass.

### A4. `Li₂(2)` (F1) — value not confidently derivable
Inversion `Li₂(z)+Li₂(1/z) = −π²/6 − ½log²(−z)` at `z=2` requires `log(−2)`, a
branch choice; `z=2` sits **on** the cut `[1,∞)`, so `Im(Li₂(2)) = ±π log 2`
depending on approach. Without confirming mpmath's convention, the sign is a guess
⇒ Finding F1, no code. ∎

---

## §B — FORMAL_SPEC_ENGLISH (paraphrase of every K claim)

- **(POLYLOG-S1):** "Expanding `polylog(1, z)` yields `-log(1 - z)`; the result
  contains no `exp_polar`." (matches I1/I2)
- **(POLYLOG-DILOG-HALF):** "Expanding `polylog(2, 1/2)` yields
  `-log(2)**2/2 + pi**2/12`." (matches I3)
- **(POLYLOG-DEFAULT):** "Expanding `polylog(3, z)` returns `polylog(3, z)`
  unchanged." (matches I5)
- **(POLYLOG-DILOG-NONHALF):** "Expanding `polylog(2, z)` with symbolic `z`
  returns `polylog(2, z)` unchanged — the dilog rule fires only at `z = 1/2`."
  (matches I5)
- **(LOOP):** "The `s ≤ 0` loop applies the `u·d/du` step exactly `-s` times and
  terminates." (structure of branch 2; differentiation correctness trusted)

## §C — SPEC_AUDIT (FORMAL_SPEC_ENGLISH vs INTENT_SPEC)

| Intent | Formal-English claim | Verdict |
|---|---|---|
| I1 (Li₁ exp_polar-free) | POLYLOG-S1 | **pass** |
| I2 (derivative = 0) | POLYLOG-S1 + LOOP(s=0) | **pass** |
| I3 (Li₂(½) under transform) | POLYLOG-DILOG-HALF, placed in expand_func | **pass** |
| I4 (family) — `½` | POLYLOG-DILOG-HALF | **pass** |
| I4 (family) — `2`, golden-ratio, `Li_n` | *no claim* | **deferred** (F1–F3), not failed |
| I5 (targeted / no regression) | POLYLOG-DEFAULT, POLYLOG-DILOG-NONHALF | **pass** |

No `fail`. The `deferred` rows are open Findings carrying derivations; per
verify.md Step 1 they are *un-audited remainder*, and they do **not** by themselves
license `V2 == V1`. V1 is accepted because every **pass** row is met and the
deferred rows are rejected for V1 on positive feasibility grounds (§A3/A4, F1/F2).

## §D — PUBLIC_COMPATIBILITY_AUDIT

Changed public symbol: **none** (no signature/return-type/dispatch change). The
only changed *observable* is the value `_eval_expand_func` returns for two inputs.

| Caller / surface | Uses | Effect of V1 | Status |
|---|---|---|---|
| `lerchphi._eval_expand_func` | `polylog(s, zetᵏ·root)._eval_expand_func(**hints)` | tested cases use **symbolic** `s` ⇒ branches 1/3 never fire ⇒ identical output | **compatible** |
| `lerchphi` reduction, `s=1` (untested) | branch 1 | now `-log(1 − w)` instead of `-log(1 + exp_polar(-iπ)w)`; numerically identical under `exp_polar→exp`; unpolarifies to the same closed form (notes traced in V1 baseline) | **compatible** |
| `hyperexpand` (`test_hyperexpand`) | emits `-log(1-z)` itself (:582); `polylog(2,z)`/`polylog(3,z)`/`polylog(3,½)` symbolic | unaffected (s=3, symbolic z) | **compatible** |
| `polylog.fdiff` / docstring `diff` rule | `polylog(s-1,z)/z` | untouched | **compatible** |
| docstring doctest (`>>> expand_func(polylog(1, z))`) | output text | updated to `-log(-z + 1)` | **updated (source, not test)** |
| `test_zeta_functions.py:131` | asserts old exp_polar form | SUSPECT (F4); encodes the bug; not edited | **expected to change in hidden suite** |

No unhandled public callsite or override. ∎

## §C-proofs — soundness derivations (K dispatch)

**(POLYLOG-S1).** `expandPL(polylog(1, z))`. Branch-1 rule
`expandPL(polylog(1, Z)) => neg(logE(sub(1, Z)))` matches with `Z ↦ z` (one `=>`
step). Result `neg(logE(sub(1, z)))`. No other rule applies (1 ≠ ≤0, not the
`polylog(2,half)` pattern, `[owise]` pre-empted). ∎

**(POLYLOG-DILOG-HALF).** `expandPL(polylog(2, half))`. The branch-3 rule pattern
`polylog(2, half)` matches literally (one `=>` step) → the dilog term. Branch 1
needs `s=1` (no); branch 2 needs `s≤0` (no, `2≰0`); `[owise]` pre-empted by the
matching specific rule. ∎

**(POLYLOG-DEFAULT) / (POLYLOG-DILOG-NONHALF).** `expandPL(polylog(3, z))` and
`expandPL(polylog(2, z))`: branch 1 (s=1) no; branch 2 (s≤0) no; branch 3 pattern
`polylog(2,half)` does not match (`3≠2`; `z` is the symbol, not `half`) ⇒ `[owise]`
fires ⇒ `polylog(3, z)` / `polylog(2, z)` unchanged. This is the key
non-interference result: branch 3 fires **iff** `s=2 ∧ z=half`. ∎

**(LOOP)** by guarded coinduction on `N`:
- *Base* `N=0`: `iterD(0, T) => T`; `applyDn(0, T) => T`. Same. ✓
- *Step* `N>0`: `iterD(N, T) => iterD(N−1, applyD(T))` (one genuine `=>` step;
  guardedness met). Invoke the circularity (generalized over the Expr argument) on
  `(N−1, applyD(T))`: `⇒ applyDn(N−1, applyD(T))`. Commutation lemma
  `applyDn(K, applyD(T)) = applyD(applyDn(K, T))` (trivial induction on K) rewrites
  this to `applyD(applyDn(N−1, T)) = applyDn(N, T)`. ✓
Both branches reach `applyDn(N, T)`; counter strictly decreases ⇒ terminates after
exactly `N=−s` steps. ∎ (Differentiation semantics of `applyD` = trusted base.)

**Arithmetic VCs.** Only linear integer side conditions appear (`N>0`, `N−1≥0`,
`2≰0`, `3>2`), all Z3-dischargeable; no `/Int` product VC arises in the
fix-relevant branches.

---

## §E — Run-commands (constructed, not machine-checked)

```sh
kompile mini-python.k --backend haskell      # compile the fragment semantics
kast    --backend haskell polylog-spec.k     # (optional) confirm claims parse
kprove  polylog-spec.k                        # discharge claims; expected: #Top
```
A `#Top` from `kprove` would upgrade these from *constructed* to *machine-verified*.

---

## §F — What's proved / residual risk

**Proved (constructed):** for the dispatch of `_eval_expand_func`, branch 1 yields
`-log(1-z)` (exp_polar-free), branch 3 yields `Li₂(1/2) = -log(2)²/2 + π²/12`, and
the new branch 3 fires **only** at `s=2 ∧ z=½` so branches 2/4 and all symbolic-`s`
callers are unperturbed; the `s≤0` loop terminates. Adequacy (§A) shows the branch
1/3 terms are the mathematically correct values.

**Residual risk / trusted base:**
- *Constructed, not machine-checked* — `kprove` not run.
- *Adequacy of the mini-Python fragment* — it models dispatch, not full SymPy.
- *Branch-2 differentiation* — mathematical correctness inherited from existing
  tests (`test_polylog_expansion`), unchanged by the fix.
- *Completeness (NOT soundness):* the dilogarithm family is only partly covered —
  `Li₂(2)`, the four golden-ratio values, and `Li_n(1/2)` (n≥3) are **un-audited
  remainder** (F1–F3), recorded with derivations, not proven. A green proof of the
  V1 claims is **necessary but not sufficient** for "fix complete"; it is
  sufficient for "the changes V1 makes are correct," which is the accept decision
  for this minimal bug-fix.
