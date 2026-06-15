# Baseline notes — sympy__sympy-16597

## Issue

`a.is_even` (and `a.is_integer`) does not imply `a.is_finite`:

```python
m = Symbol('m', even=True)
m.is_finite          # -> None, expected True

i = Symbol('i', integer=True)
i.is_finite          # -> None, expected True
```

A symbol that is known to be even/integer/rational must be a finite number, so
`is_finite` should be `True`, not `None`.

## Root cause

The old-assumptions inference engine derives all `is_*` facts from a fixed rule
set in `sympy/core/assumptions.py` (`_assume_rules`, a `FactRules` instance).

The relevant chain was:

```
'integer  -> rational'
'rational -> real'
```

`even`/`odd` imply `integer` (via `even == integer & !odd`), `integer` implies
`rational`, and `rational` implies `real`. **Nowhere in this chain is `finite`
implied.** `finite`/`infinite` were only connected to the rest of the graph by
`'zero -> even & finite'` and `'infinite -> !finite'`. Consequently, for a plain
integer/even/rational symbol the engine had no way to conclude `finite`, so it
returned `None`.

Note that `real` is *not* a safe place to attach `finite`: in this version
`real` effectively means *extended real* — `S.Infinity` and
`S.NegativeInfinity` have `is_real is True` and `is_finite is False`
(they declare `is_positive`/`is_negative` = `True`, which forces `is_real`).
Adding `finite` to `real` would make `oo` inconsistent (real & infinite). The
same is true for `complex`: `S.ComplexInfinity` (`zoo`) declares
`is_complex = True` together with `is_infinite = True`, so `complex -> finite`
would also be contradictory. `rational` is the lowest node in the hierarchy that
is genuinely always finite, which is exactly the place the issue's public hint
points to.

## Change made

**File: `sympy/core/assumptions.py`** — one rule changed:

```diff
-    'rational       ->  real',
+    'rational       ->  real & finite',
```

`a -> b & c` is the standard split form already used in this rule set (e.g.
`'zero -> even & finite'`); the `FactRules` parser expands it to `rational ->
real` and `rational -> finite`. This makes every node below `rational`
(`integer`, `even`, `odd`, `prime`, `composite`, and `rational`/`zero` itself)
imply `finite`, resolving the reported cases:

* `Symbol('m', even=True).is_finite` -> `True`
* `Symbol('i', integer=True).is_finite` -> `True`
* `Symbol('r', rational=True).is_finite` -> `True`

It does **not** touch `real`/`complex`, so the extended-real meaning of `real`
(and the `oo`/`zoo` singletons) is preserved.

## Consistency review (why this is safe)

* The only objects that declare `is_infinite = True` are `Infinity`,
  `NegativeInfinity` and `ComplexInfinity`; none of them claim
  `integer`/`rational`/`even`/etc., so no class becomes internally
  inconsistent at construction time.
* All classes that explicitly declare `is_integer = True` / `is_rational = True`
  (`Integer`, `Rational`, `Idx`, `KroneckerDelta`, `LeviCivita`) are genuinely
  finite, so the newly-deduced `is_finite = True` agrees with reality and with
  the inherited `Number._eval_is_finite` (which returns `True`).
* `Float` and the `NumberSymbol` constants (`pi`, `E`, ...) do not derive
  `finite` from this rule (they get it from their own
  handler / class attribute), so they are unaffected.

### Intended, downstream consequences on the infinities

Because `rational -> finite` now holds, its contrapositive `!finite -> !rational`
makes the engine deduce, for `oo` and `-oo` (which are `real` and `infinite`):

* `is_rational`: `None -> False`  (correct — `oo` is not rational)
* `is_integer`:  `None -> False`  (correct — `oo` is not an integer)
* `is_noninteger`: `None -> True` (follows from `noninteger == real & !integer`)
* `is_irrational`: `None -> True` (follows from `irrational == real & !rational`)

The first three are clear improvements. `is_irrational` becoming `True` is the
debatable one, but it is the *unavoidable* and internally-consistent
consequence of keeping `real` as *extended real* (`oo.is_real is True`) while
making `oo.is_rational` `False`: the existing biconditional
`irrational == real & !rational` then forces it. This is precisely the trade-off
the issue's public hint accepts ("it should be safe to add `finite` to
`rational`"), and it is preferred over the alternatives below.

## Alternatives considered and rejected

1. **`real -> finite`.** Rejected: `real` currently means *extended real*;
   `S.Infinity`/`S.NegativeInfinity` are `real` but infinite, so this would make
   those singletons inconsistent and break large amounts of code that relies on
   `oo.is_real`. (Explicitly warned against in the public hint.)

2. **`complex -> finite`.** Rejected: `S.ComplexInfinity` (`zoo`) declares
   `is_complex = True` and `is_infinite = True`; the rule would be an immediate
   contradiction for `zoo`.

3. **Redefining `irrational` (e.g. `irrational == real & !rational & finite`)
   to keep `oo.is_irrational` out of `True`.** Rejected as out of scope: it is a
   larger semantic change to a rule the issue does not ask about, it still
   changes `oo.is_irrational` (to `False`), and it risks diverging from the
   minimal, hint-directed fix. Adding `irrational -> finite` as a *separate*
   rule is impossible — combined with the unchanged backward direction
   `real & !rational -> irrational` it would force `oo` to be simultaneously
   `irrational` and `finite`, contradicting `oo.is_finite is False`.

4. **A per-class `_eval_is_finite`/explicit `is_finite = True` on integer-like
   symbols.** Rejected: symbol assumptions are driven entirely by the rule
   graph; the fix belongs in the rule set so it applies uniformly to symbols and
   to every integer/rational expression, not in individual classes.
