# PROOF.md — constructed proof for the `polylog` fix

Proof of the obligations in [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)
(claims in [`polylog-spec.k`](polylog-spec.k), semantics in
[`mini-sympy.k`](mini-sympy.k)). Symbolic execution = applying the K rewrite
rules to the redex; `=>¹` is one rule application, `=>⁺` one-or-more.

> **STATUS: CONSTRUCTED, NOT MACHINE-CHECKED.** `kompile`/`kprove` were not run
> (no execution environment). A `#Top` from `kprove` would upgrade this to
> machine-verified. Run-commands in §G.

The trusted base: adequacy of the mini-sympy fragment (it models term
construction + conditional dispatch, which is exactly what `eval` and
`_eval_expand_func` are); the K reachability metatheory; and, for §E, linear
arithmetic via Z3.

---

## §A — PO-1 / PO-2 (EVAL-HALF): placement on the construction path

Redex `mkPolylog(2, oneHalf)` (the model of `polylog(2, Rational(1,2))`).
Rule `eval-half` has LHS `mkPolylog(2, oneHalf)` — an exact match (S = the Int 2,
Z = oneHalf). It is a non-`owise` rule, so it is tried before `eval-frame`:

```
mkPolylog(2, oneHalf)
  =>¹ li2Half                                   [eval-half]
  ≡  Add( Neg(Div(Pow(logE(2),2),2)), Div(Pow(piC,2),12) )   [macro li2Half]
```

So `mkPolylog(2, oneHalf) => li2Half`. **PO-1 discharged.**

For **PO-2**: the only rule whose LHS matches `mkPolylog(2, oneHalf)` is
`eval-half` (the `eval-z1/zm1/z0` patterns need Z ∈ {1,-1,0}; `eval-frame` is
`[owise]`, suppressed whenever any other rule matches). Hence the construction
deterministically yields `li2Half`, and `plog(2, oneHalf)` is **unreachable**
from construction. `li2Half` is an `Add(...)`, structurally `≠ plog(2,oneHalf)`,
so the `ensures` holds. **PO-2 discharged.**

**Adversarial reproduction of the V1 symptom.** Under V1 the special value lived
in `_eval_expand_func`, and `eval` had no `(2,1/2)` rule — i.e. V1's `eval-frame`
matched `mkPolylog(2, oneHalf)`:
```
[V1]  mkPolylog(2, oneHalf) =>¹ plog(2, oneHalf)     [V1 eval-frame owise]
```
That is exactly the issue's `Out[1]: polylog(2, 1/2)` symptom — the bare object
stays unevaluated. The value only appeared after the opt-in step
`expandFunc(plog(2, oneHalf)) =>¹ li2Half`. V2 moves the rule onto construction,
removing the symptom on the bare path. This is the V1→V2 correction.

## §B — PO-3 / PO-4 (legacy special-z preserved; no spurious eval)

```
mkPolylog(S, 1)  =>¹ zetaE(S)        [eval-z1]
mkPolylog(S, -1) =>¹ Neg(detaE(S))   [eval-zm1]
mkPolylog(S, 0)  =>¹ 0               [eval-z0]
```
Each is a single exact-match step. **PO-3 discharged.**

For **PO-4**, `mkPolylog(S, Z)` with `Z:Id` (a symbol): `Z` is not the Int
`1/-1/0` and not `oneHalf`, so none of `eval-z1/zm1/z0/half` match; the `[owise]`
side condition of `eval-frame` is therefore satisfied:
```
mkPolylog(S, Z:Id) =>¹ plog(S, Z)    [eval-frame, owise]
```
So a symbolic-`z` polylog stays symbolic for **every** `s` — in particular the
`(2,1/2)` rule does not leak onto symbolic `z`. **PO-4 discharged.** (This is the
property that keeps `td(polylog(b, z), z)` and symbolic rewriting alive.)

## §C — PO-5 / PO-6 (EXPAND-S1: `-log(1-z)`, and derivative consistency)

```
expandFunc(plog(1, Z)) =>¹ Neg(logE(Sub(1, Z)))      [expand-s1]
```
`expand-s1` matches the literal order `1`; `expand-nonpos` needs `S:Int <=Int 0`
(false for 1); `expand-frame` is `[owise]`. One deterministic step to
`-log(1 - z)`, with **no `exp_polar` constructor anywhere** in the result tree.
**PO-5 discharged.**

**PO-6 (derivative VC, by hand — it concerns `diff`, outside the rewrite model):**
```
d/dz polylog(1,z) = polylog(0,z)/z                         [fdiff]
expand_func(polylog(0,z)) = z/(1-z)  ⇒  polylog(0,z)/z = 1/(1-z)
d/dz(-log(1-z)) = 1/(1-z)
⇒ expand_func( d/dz [ polylog(1,z) - (-log(1-z)) ] )
   = 1/(1-z) - 1/(1-z) = 0.                                ✓
```
**Adversarial check vs V1:** V1's `-log(1 + exp_polar(-I*pi)*z)` differentiates to
`exp_polar(-I*pi)/(1 + exp_polar(-I*pi)*z)`, and
`exp_polar(-I*pi)/(z*exp_polar(-I*pi)+1) + 1/(-z+1)` does **not** reduce to 0
(the issue's exact complaint). V2 removes the `exp_polar`, so the VC closes.
**PO-6 discharged**, and the V1 defect is reproduced and shown fixed.

## §D — PO-7 (EXPAND-S0 and symbolic-order frame)

```
expandFunc(plog(0, Z))
  =>¹ expandNonpos(0, Z)                  [expand-nonpos]  (0:Int <=Int 0 ✓)
  =>¹ subU(runTheta(0 -Int 0, base), Z)   [nonpos-body]
   ≡  subU(runTheta(0, base), Z)
  =>¹ subU(base, Z)                       [loop-base]
```
i.e. `expand_func(polylog(0,z)) = (u/(1-u))|_{u:=z} = z/(1-z)`, matching the
docstring/test. By Transitivity, **EXPAND-S0 discharged.**

```
expandFunc(plog(S:Id, Z)) =>¹ plog(S, Z)  [expand-frame, owise]
```
(`expand-s1` needs literal 1; `expand-nonpos` needs `S:Int`; neither matches a
symbolic `S`.) So expand leaves a non-reducible polylog untouched and introduces
no `exp_polar`. **PO-7 discharged.**

## §E — PO-8 (LOOP circularity)

Claim `(LOOP): runTheta(N, ACC) => thetaPow(N, ACC)  requires N >=Int 0`.
Guarded coinduction (reachability Circularity rule): K adds `(LOOP)` to the
hypotheses; it may be used only after ≥1 genuine `=>⁺` step. Case-split on the
loop guard.

- **Exit branch `N = 0`** (`loop-base`):
  `runTheta(0, ACC) =>¹ ACC`, and `thetaPow(0, ACC) =>¹ ACC` (`thetaPow-base`).
  Both land on `ACC`. ✓ (one genuine step taken).
- **Body branch `N > 0`** (`loop-step`):
  `runTheta(N, ACC) =>¹ runTheta(N -Int 1, theta(ACC))` — the genuine step that
  enables the circularity. Invoke `(LOOP)` on the shifted state, precondition
  `N -Int 1 >=Int 0`:
  - **VC-LOOP:** `N >Int 0  ⇒  N -Int 1 >=Int 0` — linear, discharged by Z3.
  Get `runTheta(N-1, theta(ACC)) => thetaPow(N-1, theta(ACC))`. By
  `thetaPow-step` (since `N > 0`), `thetaPow(N, ACC) =>¹ thetaPow(N-1, theta(ACC))`.
  Both branches reach `thetaPow(N-1, theta(ACC))`. ✓

Both cases land on the claimed post-state, all VCs are linear and discharge.
`A ⊢ runTheta(N, ACC) => thetaPow(N, ACC)` for `N >= 0`. **PO-8 discharged.**

*Scope note (honest):* this certifies **termination + exactly `N = -s`
theta-applications**, correctly gated to integer `s <= 0`. The counter `N` is a
strictly decreasing measure bounded below by `0`, so this loop is even totally
correct. It is intentionally *not* an arithmetic identity about the resulting
expression (theta has no closed form simpler than its iteration). This branch is
**unchanged** by the fix; the claim documents that the move of the `(2,1/2)` case
to `eval` does not perturb the `s<=0` path (PO-4 shows `(2,1/2)` never reaches
`_eval_expand_func`).

---

## §F — Composition and completeness

By Transitivity the per-obligation derivations compose into the two
contributors' contracts:

- **`eval`** (construction): for input `(s,z)`, `eval` returns the reduced term
  for `z∈{0,1,-1}` (any s) and for `(2,1/2)`, else `None` ⇒ symbolic polylog
  (PO-1..PO-4).
- **`_eval_expand_func`** (opt-in): `s==1 ⇒ -log(1-z)` (PO-5), `integer s<=0 ⇒`
  the theta-loop reduction (PO-7, PO-8), else unchanged (PO-7).

**Completeness (verify.md Step 1).** The discharged claims are *sound* for what
they state. They do **not** prove the *whole* intent: **I8 (the family of `Li_2`
special values)** is only partially covered — only `1/2`. That uncovered slice is
**un-audited, not certified correct**, and is recorded as Finding **F3**. A green
proof here is necessary, not sufficient, for "the fix is complete"; F3 is the
named residue, not a silent drop.

---

## §G — Run-commands (to machine-check later)

```sh
kompile fvk/mini-sympy.k --backend haskell    # compile the fragment semantics
kast    --backend haskell fvk/polylog-spec.k  # (optional) confirm claims parse
kprove  fvk/polylog-spec.k                     # discharge claims; expected: #Top
```
Until `kprove` returns `#Top`, every result above is **constructed, not
machine-checked**.

---

## §H — Benefit 1: test-redundancy (recommendation only; conditioned on the machine check)

Mapping current public tests (`functions/special/tests/test_zeta_functions.py`)
onto the proven contract:

| Test | Status | Reason |
|------|--------|--------|
| `polylog(s, 0) == 0`, `polylog(s, 1) == zeta(s)`, `polylog(s, -1) == -dirichlet_eta(s)` | **redundant if machine-checked** | entailed by PO-3 (holds for all `s`). |
| `myexpand(polylog(0, z), z/(1 - z))` | **redundant if machine-checked** | entailed by EXPAND-S0 (PO-7). |
| `myexpand(polylog(-1, z), …)`, `myexpand(polylog(-5, z), None)` | **keep** | exercise the loop at concrete depths; PO-8 is termination+count only, not the resulting expression. |
| `myexpand(polylog(1, z), …)` | **keep, but its target must be `-log(1 - z)`** | PO-5 changes the expected value; the V1 target `-log(1 + exp_polar(-I*pi)*z)` is **SUSPECT** (it encodes the reported bug, L8) and must not be re-asserted. |
| `test_derivatives` `td(polylog(b, z), z)` | **keep** | numerical/termination flavor; PO-4/PO-6 cover the symbolic shape, not the numeric sampling. |

**Never auto-deleted.** Recommendations only; run §G first. The kit does not edit
test files.
