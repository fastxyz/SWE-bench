# Baseline notes — sympy__sympy-12489

## Issue

`combinatorics.Permutation` cannot be subclassed properly. Although a user can write
`class MyPerm(Permutation): ...`, constructing one (`MyPerm(...)`) and operating on it
returns plain `Permutation` instances rather than `MyPerm` instances. The reporter and
the maintainer hint that the fix is to make the internal factory `_af_new` a
`classmethod` whose creation command is `Basic.__new__(cls, perm)`.

## Root cause

All low-level `Permutation` creation funnels through the static method
`Permutation._af_new`, which hard-coded the class:

```python
@staticmethod
def _af_new(perm):
    p = Basic.__new__(Perm, perm)   # Perm == Permutation, hard-coded
    ...
```

`Perm._af_new` is also exported as a module-level function `_af_new = Perm._af_new`,
and almost every method that returns a new permutation (the constructor `__new__`, the
arithmetic operators, the rank/unrank factories, etc.) calls this module-level
`_af_new` or the hard-coded `Perm(...)`. Because the target class is fixed to
`Permutation`, the actual subclass (`cls` / `type(self)`) is ignored, so a subclass can
never be instantiated through the normal machinery. The reporter's only workaround was
to monkeypatch `Permutation._af_new` itself.

Note that the *array-form* path of `__new__` already used `Basic.__new__(cls, aform)`
correctly; the leak is in every path that delegates to `_af_new` / `Perm(...)`.

## Fix

Single file changed: `repo/sympy/combinatorics/permutations.py`.

1. **`_af_new`: `@staticmethod` → `@classmethod`** (the change the maintainer asked
   for). It now takes `cls` and creates with `Basic.__new__(cls, perm)`. Called as
   `Permutation._af_new(p)`, `subclass._af_new(p)`, `instance._af_new(p)`, or via the
   module-level alias, `cls` is bound to the correct class in every case.

2. **`__new__` construction paths use `cls`** so building through a subclass returns
   that subclass:
   - the four early `_af_new(...)` returns (empty/cycle args, `Cycle` input, single int)
     → `cls._af_new(...)`;
   - the resize path `Perm(a.array_form, size=size)` → `cls(a.array_form, size=size)`.

3. **Methods that derive a new permutation from an existing one use `self._af_new`**
   (so results keep the subclass): `__mul__`, `mul_inv`, `__pow__`, `__xor__`
   (conjugation), `__invert__`, `next_lex`, `next_trotterjohnson`, `commutator`. The
   rank-arithmetic operators `__add__` (and therefore `__sub__`, which delegates to it)
   and `next_nonlex` now call `self.unrank_lex` / `self.unrank_nonlex` instead of
   `Perm.unrank_*`.

4. **Factory classmethods use the bound class**: `unrank_nonlex`,
   `unrank_trotterjohnson`, `unrank_lex`, `random`, and `from_inversion_vector` now use
   `self._af_new(...)` (here `self` is the class, since they are `@classmethod`s), and
   `josephus` uses `self(perm)` in place of `Perm(perm)`. So `MyPerm.random(n)` etc.
   return `MyPerm`.

The module-level alias `_af_new = Perm._af_new` (line 2831) is kept unchanged. With
`_af_new` now a classmethod, this evaluates to a method bound to `Permutation`, so
`_af_new(perm)` still produces a base `Permutation` — exactly as before — for every
external module that imports it (`perm_groups`, `named_groups`, `util`, `tensor_can`,
`group_constructs`, `testutil`, `polyhedron`) and for the one internal static helper.

### Why this is safe for existing behavior

There are no subclasses of `Permutation` anywhere in the codebase (verified by search),
so in all existing call sites `cls`/`type(self)`/`self`(-as-class) resolve to
`Permutation`. Every changed expression therefore produces the identical object it did
before; doctests (which all use the base `Permutation`) are unaffected. The change only
adds new, correct behavior for user-defined subclasses.

## Deliberately left unchanged

- **`rmul_with_af` (`@staticmethod`, line ~1229)**: keeps the module-level `_af_new`.
  It has no class/instance to dispatch on; it is an internal performance helper and
  producing a base `Permutation` is acceptable.
- **`__rmul__`: `Perm(other)*self`**: this coerces a *non-Permutation* left operand
  (e.g. a list) to a base `Permutation` before multiplying. The left operand is not a
  subclass instance, so coercing it to the base class is the right semantics; changing
  it would alter coercion behavior and could feed invalid input to a subclass'
  constructor.
- **`__pow__`: `if type(n) == Perm`**: this is a guard against `p**p`, i.e. it inspects
  the *exponent's* type, not object creation. It is outside the scope of the reported
  issue (object construction), so it is left as-is.
- **`isinstance(a, Perm)` (line ~865)**: already correct — `isinstance` matches
  subclasses too.
- **Module-level aliases `Perm = Permutation` / `_af_new = Perm._af_new`**: required by
  external modules and unchanged in meaning.

## Assumptions / alternatives considered

- **Minimal vs. complete fix.** The strict reading of the issue ("object creation is
  done in `Permutation.__new__`") would justify changing only `_af_new` and `__new__`.
  However the title and body ask for subclassing to work *properly*, which implies
  operations and factories should preserve the subclass type. Because making those
  changes is provably behavior-preserving for the base class (no existing subclasses),
  I applied the complete, uniform fix rather than leaving operations returning the base
  class. Every change serves the single goal of subclassing, so this is not unrelated
  refactoring.
- **Identity short-circuit in `__new__` (`return a`).** When an existing `Permutation`
  is passed and the size matches, `__new__` still returns that same object as-is. I
  kept this optimization: forcing a re-wrap into `cls` would break the established
  `Permutation(p)`-returns-`p` identity behavior, and the object returned is already a
  valid permutation. The resize branch (different size) does honor `cls`.
- **Renaming the `self` parameter of the classmethods to `cls`.** The existing
  `@classmethod`s use `self` as the first parameter name. I kept that name to minimize
  churn; `self._af_new(...)` there is functionally correct because `self` is the class.
