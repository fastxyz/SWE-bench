# Baseline notes — sympy__sympy-16597

## Issue

`a.is_even` (and `a.is_integer`) does not imply `a.is_finite`:

```python
>>> m = Symbol('m', even=True)
>>> print(m.is_finite)
None          # expected: True
>>> i = Symbol('i', integer=True)
>>> print(i.is_finite)
None          # expected: True
```

A number cannot be even/integer/rational without first being finite, so these
queries should return `True`.

## Root cause

SymPy's old-style assumptions are driven by the declarative rule set
`_assume_rules` in `sympy/core/assumptions.py`. The relevant chain was:

```
integer  -> rational
rational -> real
even     == integer & !odd        (so even -> integer -> rational -> real)
```

There was **no rule connecting `rational` (or `integer`/`even`) to `finite`**.
`real` deliberately does not imply `finite` because, in this version of SymPy,
`real` is effectively the *extended* reals: `oo` and `-oo` have
`is_real = True` and `is_infinite = True` simultaneously. Consequently nothing
in the deduction graph could conclude `finite = True` for a generic symbol that
was only declared `even`/`integer`/`rational`, so `is_finite` came back `None`.

For concrete `Number` instances the value was already `True` only because
`Number._eval_is_finite` (`sympy/core/numbers.py:610`) returns `True`; that
handler is never reached for a bare `Symbol`, which relies purely on the rules.

## Fix

`sympy/core/assumptions.py` — added one rule to `_assume_rules`:

```python
'rational       ->  finite',
```

Every rational number is finite, so this implication is mathematically sound.
Because `integer -> rational` and `even/odd -> integer` already exist, the new
rule propagates `finite = True` to integers and to even/odd numbers, fixing both
cases in the report (and the analogous `rational`/`odd` cases). This is exactly
the change suggested in the public hint ("it should be safe to add finite to
rational"); equivalently it could be written by extending the existing line to
`'rational -> real & finite'` — the `FactRules` parser splits `a -> b & c`
into the same two implications, so the two spellings compile identically.

### Why this is safe (no inconsistencies introduced)

The rule also yields the contrapositive `!finite -> !rational`, hence
`infinite -> !finite -> !rational -> !integer -> !even & !odd`. I verified that
no class declares `is_rational/is_integer/is_even/is_odd = True` together with
`is_infinite = True` (checked `numbers.py` `Rational`/`Integer`,
`tensor_functions.py` `KroneckerDelta`/`LeviCivita`, `indexed.py` `Idx`), so no
class's `default_assumptions` becomes contradictory and SymPy still imports.
I also checked the `FactRules` engine in `sympy/core/facts.py`: the alpha-rule
consistency check (`deduce_alpha_implications`) is not tripped because no fact is
implied both `True` and `False`.

### Intended consequences for the infinities

Because `oo`/`-oo`/`zoo` hard-code `is_infinite = True`, the new rule now lets
the engine *determine* facts that used to be `None`:

* `oo.is_rational`, `oo.is_integer`, `oo.is_even`, `oo.is_odd`  -> `False`
  (and identically for `-oo`, `zoo`).
* `oo.is_noninteger` -> `True`  (from `noninteger == real & !integer`).
* `oo.is_irrational` -> `True`, `-oo.is_irrational` -> `True`
  (from the existing biconditional `irrational == real & !rational`, since
  `oo` is `real` and now provably `!rational`). `zoo.is_irrational` stays
  `False` because `zoo.is_real` is `False`.

All of these are correct deductions (an infinity is not a rational/integer).
`NaN` is unaffected: it pins `is_real`, `is_rational`, `is_finite` to `None` at
the class level. `Float('inf')` is also unaffected externally: `Float` pins
`is_rational`/`is_irrational` to `None` at the class level (blocking the
auto-property), and its `is_finite` already comes from its own
`_eval_is_finite`.

## Assumptions / alternatives considered and rejected

* **Add `real -> finite` instead.** Rejected: `oo`/`-oo` are `real` *and*
  `infinite`, so this would raise `InconsistentAssumptions` when constructing
  those singletons (and the hint explicitly warns it "would break a lot of
  code"). The proper long-term solution is a separate `extended_real`
  predicate, which is a large, out-of-scope refactor.

* **Add `integer -> finite` only.** Rejected: it would leave non-integer
  rationals (e.g. a bare `Symbol('q', rational=True)`) without `is_finite`,
  whereas all rationals are finite. `rational -> finite` is the most general
  correct statement and still covers integer/even/odd via the existing chain.

* **Also tighten `irrational` (e.g. `irrational == real & finite & !rational`)
  to keep `oo.is_irrational` from becoming `True`.** Rejected: it broadens the
  change beyond the reported issue and beyond the public hint, and it modifies
  the meaning of `irrational` for ordinary symbols. Within this version's
  extended-real model, `oo.is_irrational == True` is a consistent deduction, so
  the minimal, targeted change is preferred.

* **Spelling** — added a standalone `'rational -> finite'` line rather than
  editing the existing `'rational -> real'` line, purely so the new fact is
  self-documenting; the compiled rule set is identical either way.

## Files changed

* `sympy/core/assumptions.py` — one added rule line in `_assume_rules`.
