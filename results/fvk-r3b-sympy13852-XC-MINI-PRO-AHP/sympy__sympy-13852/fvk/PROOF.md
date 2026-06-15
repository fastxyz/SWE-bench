# PROOF.md — constructed correctness proof for the polylog fix

Proves the claims in [`polylog-spec.k`](polylog-spec.k) against [`mini-cas.k`](mini-cas.k)
by symbolic execution (Axiom + Transitivity + Consequence; no loop ⇒ no Circularity
needed for the in-scope claims). **Status: CONSTRUCTED, NOT MACHINE-CHECKED.**

Notation: `=>` one rule step; `CF2 = sub(divi(powr(pi,2),12), divi(powr(log(2),2),2))`
= `pi²/12 − log²2/2`; `LOG1(Z) = neg(log(sub(1,Z)))` = `−log(1−Z)`.

---

## PO1 — (EVAL-HALF) `polylog(2, half) ⇒ CF2`

```
<k> polylog(2, half) </k>
  => CF2                         [Axiom: eval rule `polylog(2, half) => CF2`]
```
One step; lands on the post-state. The rule's target is correct **iff LEM-LI2** holds —
that is the [ESCALATION BOUNDARY] obligation (see §Escalation). ∎ (modulo LEM-LI2)

This models SymPy `polylog.eval`: constructing `polylog(2, Rational(1,2))` returns
`-log(2)**2/2 + pi**2/12`.

## PO2 — (SIMPLIFY-HALF) `simpl(polylog(2, half)) ⇒ CF2`

`simpl` is `strict`, so its argument normalises first:
```
<k> simpl(polylog(2, half)) </k>
  => simpl(CF2)                  [Axiom: eval rule fires under the strict arg — PO1]
  => CF2                         [Axiom: `simpl(A) => A`]
```
**This is the crux of the audit.** `simpl` is the identity on a *bare* polylog (faithful
to `simplify.py`: the main path never `expand_func`s a polylog). The reduction reaches
`CF2` **only because eval already fired** at construction (PO1). Under V1 (no eval rule)
the first step does not happen, `simpl(polylog(2,half)) => polylog(2,half) ≠ CF2`, and the
claim FAILS — exactly the `test_R18` failure. ∎ (modulo LEM-LI2)

## PO3 — (EXPAND-HALF) `expandf(polylog(2, half)) ⇒ CF2`

```
<k> expandf(polylog(2, half)) </k>
  => expandf(CF2)               [eval under strict arg — PO1]
  => ... => CF2                 [expandf congruence rules + `expandf(log(_))=>log(_)`; CF2 has no polylog]
```
(Equivalently, on the `evaluate=False` path where eval did not fire, the dedicated rule
`expandf(polylog(2, half)) => CF2` fires in one step.) ∎ (modulo LEM-LI2)

Models the issue's `In[2]`: `polylog(2, Rational(1,2)).expand(func=True)`.

## PO4 — (EXPAND-LI1) `expandf(polylog(1, z)) ⇒ neg(log(sub(1, z)))`

```
<k> expandf(polylog(1, z)) </k>
  => LOG1(z) = neg(log(sub(1, z)))    [Axiom: `expandf(polylog(1, Z)) => LOG1(Z)`, Z↦z]
```
`z` symbolic ⇒ the eval rules do **not** fire (no `z∈{0,1,-1,half}` match), so the polylog
survives to `expandf`, as in SymPy. The target is correct **iff LEM-LI1**. Crucially the
RHS carries **no `exp_polar`** — the issue's complaint. ∎ (modulo LEM-LI1)

## PO5 — (DERIV-CONSISTENT) `expandf(der(sub(polylog(1,z), expandf(polylog(1,z))))) ⇒ 0`

Inner-most first (strictness), then `der`, then outer `expandf`:
```
expandf(polylog(1,z))                       => LOG1(z)                              [PO4]
sub(polylog(1,z), LOG1(z))                                                            (frozen until der)
der(sub(polylog(1,z), LOG1(z)))
  => sub(der(polylog(1,z)), der(LOG1(z)))   [der(sub)=>sub(der,der)]
  der(polylog(1,z)) => divi(polylog(sub(1,1),z), z) = divi(polylog(0,z), z)         [fdiff]
  der(LOG1(z)) = der(neg(log(sub(1,z))))
     => neg(der(log(sub(1,z))))             [der(neg)]
     => neg(divi(der(sub(1,z)), sub(1,z)))  [der(log)]
     => neg(divi(sub(der(1),der(z)), sub(1,z)))  [der(sub)]
     => neg(divi(sub(0,1), sub(1,z)))       [der(1)=>0, der(z)=>1]            // = -( -1/(1-z) ) = 1/(1-z)
  so der(...) => sub(divi(polylog(0,z),z), neg(divi(sub(0,1),sub(1,z))))
outer:
expandf( sub( divi(polylog(0,z),z), neg(divi(sub(0,1),sub(1,z))) ) )
  => sub( expandf(divi(polylog(0,z),z)), expandf(neg(...)) )       [expandf congruence]
  expandf(divi(polylog(0,z),z)) => divi(expandf(polylog(0,z)), z)
     => divi( divi(z, sub(1,z)), z )        [expandf(polylog(0,Z))=>Z/(1-Z)]
     => divi(1, sub(1,z))                   [VC-CANCEL-2: (Z/W)/Z = 1/W]      // = 1/(1-z)
  expandf(neg(divi(sub(0,1),sub(1,z)))) reduces to divi(1, sub(1,z))         // -(-1/(1-z)) = 1/(1-z)
  => sub( divi(1,sub(1,z)), divi(1,sub(1,z)) )
  => 0                                       [VC-CANCEL-1: a - a = 0]
```
Lands on `0`. VCs: **VC-CANCEL-1**, **VC-CANCEL-2** (linear/cancellation, Z3 tier). ∎

This is the issue's invariant "expand_func does not change the derivative"; with the OLD
`exp_polar` form the `der(LOG1(z))` branch produced `exp_polar(-I*pi)/(z*exp_polar(-I*pi)+1)`
which does **not** cancel against `1/(1-z)` — i.e. PO5 would NOT close. The fix is what
makes PO5 discharge.

## PO6 — (EVAL-PRESERVED) regression

```
polylog(s, 1)      => zeta(s)         [eval rule, unchanged]
polylog(s, neg(1)) => neg(deta(s))    [eval rule, unchanged]
polylog(s, 0)      => 0               [eval rule, unchanged]
```
One step each; unchanged from before the fix. ∎

## PO7 — doctest form

`-log(1 - z)` prints `-log(-z + 1)` (SymPy orders the `Add` `1 + (-z)` as `-z + 1`,
identical to the neighbouring doctest `polylog(0,z) -> z/(-z + 1)` and the tutorial
`hyperexpand(hyper([1,1],[2],z)) -> -log(-z + 1)/z`). The V2 docstring matches. ∎

---

## Escalation — LEM-LI1 / LEM-LI2 (honest boundary)

PO1/PO3/PO4 reduce to two transcendental identities that the bundled Z3 +
`[simplification]` tier cannot mechanically prove (they need special-function /
analytic-continuation theory):

- **LEM-LI1** `Li_1(Z) = -log(1-Z)` — power-series equality on `|Z|<1`, identical branch
  cut, identical monodromy; corroborated numerically in issue #7132.
- **LEM-LI2** `Li_2(1/2) = pi²/12 - log²2/2` — dilogarithm reflection at `z=1/2`.

These are stated as named `[simplification]` lemmas with provenance in `polylog-spec.k`
and marked **[ESCALATION BOUNDARY]**: discharge everything the tier can (the rewrites and
the linear VCs), route LEM-LI1/LEM-LI2 to the references below, and **do not** admit them
as `[trusted]`. The SymPy code's correctness rests on exactly these two textbook
identities, so the open obligation is *specified*, not hidden.

References: Lewin, *Polylogarithms and Associated Functions* (reflection formula §1.1);
DLMF §25.12 (dilogarithm). For the K reachability metatheory: Roșu & Ștefănescu, FM 2012.

---

## Reproduce the machine check (not run here)

```sh
kompile mini-cas.k --backend haskell        # compile the fragment (Haskell/symbolic backend)
kast    --backend haskell polylog-spec.k     # optional: confirm claims parse
kprove  polylog-spec.k                        # expected: #Top for PO1–PO7 modulo LEM-LI1/LEM-LI2
```
A `#Top` upgrades this from *constructed* to *machine-verified* (still modulo the two
escalation lemmas, which require a special-functions theory or a numerical certificate).

## Two plain-language payoffs

- **Hidden bug found (benefit 2):** V1 placed `Li_2(1/2)` on `expand_func` only, but the
  tracking test and the issue's intent demand it on the construction path — PO2 cannot
  close under V1. Fixed by adding the `eval` branch (FINDINGS F1).
- **Test guidance (benefit 1):** PO1–PO6 prove the behavior for *all* the in-scope inputs,
  so the new `test_zeta_functions` asserts (bare and `myexpand`) and `test_R18`'s
  `.simplify()` assertion are all entailed — see ITERATION_GUIDANCE for the keep/redundant
  split. Conditioned on running `kprove` (above) first.
