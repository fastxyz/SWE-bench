# PROOF — polylog._eval_expand_func (V2)

**Status: CONSTRUCTED, NOT MACHINE-CHECKED.** Symbolic execution against
`mini-sympy.k`; the MVP does not run `kprove`. Reproduce with the commands at the end.

Target: the claims in `polylog-expand-spec.k` hold of the V2 implementation, and in
particular the derivative-consistency property the public issue requires (which the
pre-fix `exp_polar` output failed).

## §PL1 — `expandPolylog(1, z) ⇒ -log(1 - z)`

One Axiom step:
```
expandPolylog(1, z)
  =>  Neg(Log(Sub(1, z)))            [rule: expandPolylog(1, Z) => Neg(Log(Sub(1, Z)))]
```
Terminal (a normal form). No `exp_polar` anywhere. ∎ (PO-1)

## §PL2 — `expandPolylog(2, 1/2) ⇒ -log(2)²/2 + π²/12`

One Axiom step (literal match on `2` and `Half`):
```
expandPolylog(2, Half)
  =>  Add(Neg(Div(Pow(Log(2),2),2)), Div(Pow(Pi,2),12))
```
Terminal. ∎ (PO-2)

**§Numeric (adequacy of the value).** The closed form is the dilogarithm reflection
formula at the fixed point `z = 1-z = 1/2`:
`Li_2(z) + Li_2(1-z) = π²/6 - log(z)·log(1-z)` ⇒ at `z=1/2`,
`2·Li_2(1/2) = π²/6 - log(1/2)² = π²/6 - log(2)²` ⇒ `Li_2(1/2) = π²/12 - log(2)²/2`.
Numerically `0.8224670334 - 0.2402265070 = 0.5822405264`, matching
`mpmath.polylog(2, 0.5) = 0.5822405264…`. The value is correct. ∎

## §PL0 — `expandPolylog(0, z) ⇒ z/(1 - z)`

```
expandPolylog(0, z)
  =>  ratPolylog(0, z)               [rule requires 0 <=Int 0  — Z3: true]
  =>  Div(z, Sub(1, z))              [rule: ratPolylog(0, Z) => Div(Z, Sub(1, Z))]
```
Transitivity of the two steps. ∎ (PO-3)

## §PLF — fallbacks unchanged

`expandPolylog(3, z)`: no literal rule matches (`3 ∉ {1,2}`), the `s<=0` rule's
`requires 3 <=Int 0` is false (Z3), so `[owise]` fires ⇒ `PolyLog(3, z)`.
`expandPolylog(2, z)` with symbolic `z`: the dilog rule needs the literal `Half`;
`z` is not `Half`, so `[owise]` ⇒ `PolyLog(2, z)`. ∎ (PO-4, PO-5)

## §PO-6 — Derivative consistency (the load-bearing proof)

**Goal A:** `Diff(Neg(Log(Sub(1, z))), z) ⇒ Div(1, Sub(1, z))`.
```
Diff(Neg(Log(Sub(1, z))), z)
  => Neg(Diff(Log(Sub(1, z)), z))             [Diff(Neg(E),X) => Neg(Diff(E,X))]
  => Neg(Div(Diff(Sub(1, z), z), Sub(1, z)))  [Diff(Log(E),X) => Div(Diff(E,X), E)]
  => Neg(Div(Sub(Diff(1,z), Diff(z,z)), Sub(1, z)))  [Diff(Sub(A,B),X) => Sub(Diff(A,X),Diff(B,X))]
  => Neg(Div(Sub(0, 1), Sub(1, z)))           [Diff(1,_) => 0 ;  Diff(z,z) => 1]
  => Neg(Div(Neg(1), Sub(1, z)))              [lemma: Sub(0,1) => Neg(1)]
  => Div(1, Sub(1, z))                        [lemma: Neg(Div(Neg(E),F)) => Div(E,F)]
```
∎ Goal A.

**Goal B:** `Div(expandPolylog(0, z), z) ⇒ Div(1, Sub(1, z))`.
```
Div(expandPolylog(0, z), z)
  => Div(Div(z, Sub(1, z)), z)                [§PL0]
  => Div(1, Sub(1, z))                        [lemma: Div(Div(Z,F),Z) => Div(1,F), z != 0]
```
∎ Goal B.

Goals A and B reach the **same** normal form `Div(1, Sub(1, z))`. Hence
`d/dz(expand_func(polylog(1,z))) = d/dz(polylog(1,z))`, so
`expand_func(diff(polylog(1,z) − expand_func(polylog(1,z)), z)) = 0`. ∎ (PO-6)

### Why the OLD code FAILS PO-6 (the bug, formally)

Model the pre-fix return `-log(1 + exp_polar(-I*pi)·z)` as
`Neg(Log(Add(1, Mul(EP, z))))` where `EP` is the opaque constant `exp_polar(-I*pi)`
(SymPy deliberately does **not** rewrite `EP` to `-1`). Differentiating:
```
Diff(Neg(Log(Add(1, Mul(EP, z)))), z)
  => Neg(Div(Mul(EP, 1), Add(1, Mul(EP, z))))        [chain rule; d/dz(EP·z)=EP]
  =  Neg(Div(EP, Add(1, Mul(EP, z))))
```
There is **no** lemma reducing `EP` to `-1`, so this term cannot normalize to
`Div(1, Sub(1, z))`. The two normal forms differ by exactly the residual the issue
reported: `exp_polar(-I*pi)/(z*exp_polar(-I*pi) + 1) + 1/(-z + 1) ≠ 0`. The fix
discharges PO-6 precisely by replacing `Add(1, Mul(EP, z))` with `Sub(1, z)`. ∎

## §PO-7 — Totality

The four rule groups partition the integer-`s` domain: `{1}`, `{(2,1/2)}`, `{s ≤ 0}`,
and the `[owise]` complement (symbolic `s`, `s ≥ 3`, `s = 2 ∧ z ≠ 1/2`). The guards
`s ≤ 0`, `s ≠ 1`, `s ≠ 2` are linear and pairwise non-overlapping at the literals
used; `[owise]` is exhaustive by K's semantics. No input lacks a result; no input
matches two reducing rules. ∎

## §Loop — out of scope, stated honestly

The `s < 0` branch contains the only loop in the method
(`for _ in range(-s): start = u*start.diff(u)`), **unchanged by this fix**. Its full
circularity (`(u d/du)^n` applied to `u/(1-u)`) is not re-proved here; `mini-sympy.k`
abstracts it as `ratPolylog` and pins the `s=0` instance the public tests touch. This
is a deliberate scope boundary, not a gap in the fix (FINDINGS F5).

## What is proved (plain language)

For every `z`: `expand_func(polylog(1, z)) = -log(1 - z)` (no `exp_polar`), and its
derivative equals `polylog(0,z)/z = 1/(1-z)`, so expansion preserves the derivative.
`expand_func(polylog(2, 1/2)) = -log(2)²/2 + π²/12` (the dilogarithm value). All other
documented reductions are unchanged, and the special-case dispatch is total and
non-overlapping. The bug is gone and nothing documented regresses.

## Residual risk / trusted base

- **Partial correctness**, **constructed, not machine-checked.** Termination of the
  (untouched) `s<0` loop is not in scope.
- Trusted: faithfulness of the `mini-sympy.k` fragment (esp. the `ratPolylog`
  abstraction and the `EP`-is-opaque modelling of `exp_polar`); the reachability
  metatheory; the Z3/`[simplification]` oracle for the algebra lemmas.

## Reproduce the machine check

```sh
kompile mini-sympy.k --backend haskell
kast    --backend haskell polylog-expand-spec.k    # optional: parse check
kprove  polylog-expand-spec.k                      # expected: #Top
```
`#Top` upgrades this from *constructed* to *machine-verified*.
