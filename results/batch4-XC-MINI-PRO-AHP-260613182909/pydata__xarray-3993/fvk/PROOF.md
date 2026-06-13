# PROOF.md — constructed proof for pydata/xarray #3993 (V1)

**Status: CONSTRUCTED, NOT MACHINE-CHECKED** (FVK MVP). This proof is symbolic
execution of `mini-python-spec.k`'s four claims against `mini-python.k`, by hand.
The exact `kompile`/`kprove` commands to machine-check it are in §Reproduce.

The changed code is **loop-free**, so the proof uses only **Axiom (+framing)**,
**Transitivity**, and **Case Analysis** — there is **no Circularity** to
discharge (contrast the `sum` template, whose value is the loop invariant; here
the value is the exhaustive case split). No arithmetic VCs arise, so no
`[simplification]` lemmas are needed.

The modeled body (`integrateBody`, see `mini-python-spec.k`) is, as a `~>`
sequence after the `S1 S2 => S1 ~> S2` linearization:

```
g1 := if (dim isNotNone) and (coord isNotNone) then { raiseValueError(MSG) }
g2 := if (dim isNotNone) and (coord isNone)    then { coord = dim  warn() }
a  := ds = dsetIntegrate(coord, datetimeUnit)
b  := result = fromTemp(ds)
r  := return result
<k> = g1 ~> g2 ~> a ~> b ~> r
```
with `MSG = "Cannot pass both 'dim' and 'coord'. Please pass only 'coord' instead."`

---

## §R1 — new-style: `coord|->tok(CI), dim|->None`  (PO-1)

`<warned>=false`, `<out>=.K` initially.

1. **g1 guard.** `strict(1)` heats the guard `(dim isNotNone) and (coord
   isNotNone)`. `and` is `strict(1)`: evaluate left `dim isNotNone`; `dim` looks
   up to `None`; `None isNotNone => false`. Then `false and _ => false`. Guard =
   `false`. Rule `if false then {…} => .K`. (Axiom steps; the unused right
   operand `coord isNotNone` is never evaluated — short-circuit.)
2. `.K ~> g2 ~> … => g2 ~> …` (`.K` absorbed).
3. **g2 guard.** left `dim isNotNone => false` (as above) ⇒ `false and _ =>
   false`. `if false then {…} => .K`. No alias, no `warn()`.
4. **a.** `dsetIntegrate(coord, datetimeUnit)` is `seqstrict`: `coord => tok(CI)`,
   `datetimeUnit => U`; then `dsetIntegrate(tok(CI), U) => dset(tok(CI), U)`.
   Assign: `ds <- dset(tok(CI), U)`.
5. **b.** `fromTemp(ds)`: `ds => dset(tok(CI),U)`; `fromTemp(dset(tok(CI),U)) =>
   daOf(dset(tok(CI),U))`. Assign `result <- daOf(dset(tok(CI),U))`.
6. **r.** `return result`: `result => daOf(dset(tok(CI),U))`; `return V ~> _ =>
   .K` with `<out> => daOf(dset(tok(CI),U))`.

End: `<k>=.K`, `<warned>=false`, `<out>=daOf(dset(tok(CI),U))`. **Matches R1. ∎**

## §R2 — deprecated: `coord|->None, dim|->tok(DI)`  (PO-2)

1. **g1 guard.** left `dim isNotNone`: `dim => tok(DI)`; `tok(DI) isNotNone =>
   true`. `true and E => E`, `E = coord isNotNone`; `coord => None`; `None
   isNotNone => false`. Guard = `false`. `if false then {…} => .K`. (The
   conflict guard is correctly **not** taken: `coord` is absent.)
2. **g2 guard.** left `dim isNotNone => true` ⇒ `true and E => E`, `E = coord
   isNone`; `coord => None`; `None isNone => true`. Guard = `true`. `if true then
   { coord = dim  warn() } => (coord = dim  warn())`.
3. `coord = dim  warn()` linearizes to `(coord = dim) ~> warn()`. `coord = dim`:
   `dim => tok(DI)`; assign `coord <- tok(DI)`. Then `warn() => .K` with
   `<warned> => true`.
4. **a.** now `coord => tok(DI)`, `datetimeUnit => U`; `dsetIntegrate(tok(DI),U)
   => dset(tok(DI),U)`; `ds <- dset(tok(DI),U)`.
5. **b/r.** as in R1 ⇒ `<out> => daOf(dset(tok(DI),U))`.

End: `<k>=.K`, `<warned>=true`, `<out>=daOf(dset(tok(DI),U))`. **Matches R2. ∎**

## §R3 — conflict: `coord|->tok(CI), dim|->tok(DI)`  (PO-3)

1. **g1 guard.** left `dim isNotNone`: `tok(DI) isNotNone => true`. `true and E
   => E`, `E = coord isNotNone`; `tok(CI) isNotNone => true`. Guard = `true`.
   `if true then { raiseValueError(MSG) } => raiseValueError(MSG)`.
2. `<k> = raiseValueError(MSG) ~> (g2 ~> a ~> b ~> r)`. Rule
   `raiseValueError(M) ~> _REST => .K` fires: `_REST` captures `g2 ~> a ~> b ~>
   r` and is **discarded**; `<out> => raised(MSG)`.

End: `<k>=.K`, `<warned>=false` (never touched), `<out>=raised(MSG)`, and
`dset(...)`/`dsetIntegrate` were **never evaluated** (they lived only in the
discarded `_REST`). **Matches R3. ∎**

## §R4 — degenerate: `coord|->None, dim|->None`  (PO-4)

1. **g1 guard.** `dim isNotNone => false` ⇒ `false and _ => false`. `if false …
   => .K`.
2. **g2 guard.** `dim isNotNone => false` ⇒ `false and _ => false`. `if false …
   => .K`. No alias, no warn.
3. **a.** `dsetIntegrate(None, U) => dset(None, U)`; `ds <- dset(None,U)`.
4. **b/r.** ⇒ `<out> => daOf(dset(None,U))`.

End: `<k>=.K`, `<warned>=false`, `<out>=daOf(dset(None,U))`. **Matches R4
(resolution step). ∎** The *runtime* `ValueError("Coordinate None does not
exist.")` is produced inside the opaque delegate (PO-7, escalation boundary);
modeling that exception propagation is out of the fragment, so the model stops
at `daOf(dset(None,U))`. This is honest: the resolution layer is proved to
forward `None` with no warning; the delegate's own validation does the rest.

## §Corollary — behavior preservation (PO-5)
Instantiate `CI := X` in R1 and `DI := X` in R2: both reach the delegated value
`daOf(dset(tok(X), U))`. Hence `integrate(coord=X)` and `integrate(dim=X)` compute
**identically**; only `<warned>` differs (false vs true). The legacy positional
`integrate(X)` binds `coord := X` (first positional parameter) and so equals R1.
∎ — the deprecation changes the API surface and the warning, never the result.

---

## Verification conditions
None nonlinear. Every side condition is a propositional/identity fact about
`None` vs `tok(_)` and short-circuit `and`, discharged directly by the rewrite
rules (the SMT/Z3 tier is not even exercised). No `[simplification]` lemma and no
map-extensionality lemma are required, because the postconditions pin `<out>`
and `<warned>` rather than a symbolic store binding.

## What is proved (plain language)
For every call to `DataArray.integrate`:
- if you pass `coord` (or pass it positionally) and not `dim`, you get the
  integration over that coordinate, with **no** warning;
- if you pass only `dim`, you get the **same** integration over that coordinate,
  plus a `FutureWarning` telling you to switch to `coord`;
- if you pass **both**, you get a `ValueError` and nothing is computed;
- the deprecated and new spellings are **result-identical** (PO-5).

## Residual risk
- **Partial vs total correctness:** the changed code is loop-free, so it
  terminates trivially; termination/performance of the abstracted numerical
  delegate is out of scope.
- **Trusted base:** adequacy of the mini-X fragment; the abstraction of the
  unchanged delegate as `dset(coord,unit)` (PO-7, an explicit
  `[ESCALATION BOUNDARY]`, not a faked `[trusted]` arithmetic claim); the K
  reachability metatheory and `kprove`.
- **Constructed, not machine-checked** — see Honesty gate.

---

## Test-redundancy (benefit 1) — recommendation: **KEEP ALL TESTS**
Mapping the existing tests onto the proved contract:

- `test_dataset.py::test_integrate`, `::test_trapz_datetime` (and the DataArray
  equivalents) assert **numerical** results of the integration. Those exercise
  the *abstracted, unchanged* delegate (PO-7), which this proof **does not**
  cover. → **KEEP** (out of the verified contract; F-6 escalation boundary).
- Any (hidden) deprecation test asserting `da.integrate(dim=...)` emits a
  `FutureWarning` would, *after machine-checking*, be partially subsumed by R2 —
  but it is cheap and a useful regression guard. → **KEEP**.
- No test is recommended for removal. The MVP has not run `kprove`, so per the
  Honesty gate no removal would be advised regardless.

**CI time saved: none claimed.** This fix is an API/dispatch change; its value is
correctness + backward-compat, not test reduction.

## Honesty gate
The proof is **constructed, not machine-checked**. No test removal is advised.
The Findings (`FINDINGS.md`) stand independently of machine-checking.

## Reproduce the machine check
```sh
kompile mini-python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-python-spec.k   # (optional) confirm the claims parse
kprove  mini-python-spec.k                      # expected: #Top  (R1–R4 all proved)
```
A `#Top` from `kprove` upgrades this from *constructed* to *machine-verified*.
