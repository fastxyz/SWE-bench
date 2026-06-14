# Baseline notes — sympy__sympy-12489

## Issue
`combinatorics.Permutation` cannot be subclassed properly. Although `Permutation.__new__`
is a (de-facto) class-aware constructor, almost all object creation is funneled through the
internal helper `Permutation._af_new`, which was a **staticmethod** that hard-coded the
target class:

```python
@staticmethod
def _af_new(perm):
    p = Basic.__new__(Perm, perm)   # Perm == Permutation, hard-coded
    ...
```

Because `Perm` (i.e. `Permutation`) is baked in, every path that went through `_af_new`
returned a base `Permutation`, never a subclass instance. The module-level alias
`_af_new = Perm._af_new` made this even more pervasive: `__new__` and the various
constructors/operators all called the module-global `_af_new`, so subclass type
information was lost.

## Root cause
Object creation did not honor Python's normal instance-creation mechanism (the class
on which the method was invoked). `_af_new` ignored the calling class and always built a
`Permutation`. As a result:
- `__new__` early-return paths (empty perm, separate-cycle args, `Cycle`, single int)
  returned base `Permutation` even when called as `Subclass(...)`.
- Operators (`__mul__`, `__pow__`, `__invert__`, `__xor__`, `mul_inv`, `commutator`,
  `next_lex`, `next_trotterjohnson`) and the alternate constructors (`random`,
  `unrank_lex`, `unrank_nonlex`, `unrank_trotterjohnson`, `from_inversion_vector`,
  `josephus`) all produced base `Permutation`s.

(The main array-form branch of `__new__` already used `Basic.__new__(cls, aform)`, so
only that single path worked for subclasses before this change.)

## Fix
All in `repo/sympy/combinatorics/permutations.py`.

1. **`_af_new` is now a `classmethod`** that creates the object with the calling class:
   ```python
   @classmethod
   def _af_new(cls, perm):
       p = Basic.__new__(cls, perm)
       ...
   ```
   This is exactly what the public hint recommended (`Basic.__new__(cls, perm)`).
   `Basic.__new__(cls, *args)` simply does `object.__new__(cls)` + arg bookkeeping, so
   passing a subclass `cls` produces a subclass instance with no other behavioral change.

2. **`__new__` uses the class reference** for every creation path:
   `cls._af_new(...)` for the empty / multi-arg-cycle / `Cycle` / single-int branches, and
   `cls(a.array_form, size=size)` (was `Perm(...)`) for the size-adjust branch. The
   already-correct main array-form branch (`Basic.__new__(cls, aform)`) is untouched.

3. **Instance methods use `self._af_new(...)`** so operations preserve the subclass:
   `mul_inv`, `__mul__`, `__pow__`, `__xor__`, `__invert__`, `next_lex`, `commutator`,
   `next_trotterjohnson`.

4. **Classmethod constructors use the class reference** (their first parameter, named
   `self`, is the class because they are `@classmethod`): `unrank_nonlex`,
   `unrank_trotterjohnson`, `from_inversion_vector`, `random`, `unrank_lex` now call
   `self._af_new(...)`; `josephus` now calls `self(perm)` (it previously used the full
   `Perm(perm)` validating constructor, so `self(perm)` is the faithful, validation-
   preserving subclass-aware translation rather than `_af_new`).

### Deliberately left unchanged
- `rmul_with_af` (line ~1229) is a `@staticmethod` with no `self`/`cls` and operates on
  arbitrary `Permutation` arguments; it keeps using the module-global `_af_new`. There is
  no single "calling class" to honor, and it is an internal group-theory optimization
  helper.
- `__rmul__` (`return Perm(other)*self`): this only fires when the *left* operand is not a
  `Permutation` and must be coerced; coercing an arbitrary object to the base `Permutation`
  is a reasonable default and is outside the object-creation mechanism the issue targets.
- The `isinstance(a, Perm)` same-size pass-through in `__new__` (`return a`): it returns an
  already-valid object and preserves the existing `Permutation(p) is p` identity
  optimization. Only the size-mismatch sub-case (which always rebuilds) was switched to
  `cls(...)`.
- The module-level alias `_af_new = Perm._af_new` is kept. With `_af_new` now a
  classmethod, `Perm._af_new` is a bound method (cls=`Permutation`), so the global helper
  still produces base `Permutation`s — preserving behavior for `rmul_with_af` and for the
  other `combinatorics` modules that import this alias.

## Backward-compatibility check
Converting `_af_new` from `staticmethod` to `classmethod` is safe for every caller because
they all invoke it with a **single** argument (the array form). A classmethod auto-binds
`cls`, so a single positional arg remains correct. I checked all in-repo call sites under
`sympy/combinatorics/` (`named_groups.py`, `tensor_can.py`, `testutil.py`, `polyhedron.py`,
`util.py`, `group_constructs.py`, `perm_groups.py`): they call either the imported global
`_af_new(list)` or `Permutation._af_new(list)` / `Perm._af_new(list)` — all single-arg,
none pass an explicit class. For the base `Permutation` class itself, `self._af_new` /
`cls._af_new` / the global `_af_new` all resolve to `Permutation._af_new` with
`cls == Permutation`, i.e. **identical** to the previous behavior; the new behavior only
differs for genuine subclasses (which previously could not be produced at all).

## Assumptions / alternatives considered
- **Assumption:** the desired semantics are that constructing or operating on a subclass
  yields subclass instances, while base `Permutation` usage is byte-for-byte unchanged. The
  fix is designed so that the base class observes no behavioral difference.
- **Alternative (narrowest) — only change `_af_new` + `__new__`:** matches the literal hint
  but leaves operators and alternate constructors returning base `Permutation`, which the
  issue explicitly complains about ("always instances of `Permutation` are returned").
  Rejected in favor of completing the subclass support, since the broader change is a strict
  superset and carries no regression risk for the base class.
- **Alternative — rebuild on the `isinstance(a, Perm)` same-size path:** would make
  `Subclass(base_perm)` upcast to the subclass, but risks changing the documented
  `Permutation(p) is p` copy/identity behavior. Rejected to keep the change minimal and
  avoid altering identity semantics relied upon elsewhere.
- **Alternative — also make `rmul_with_af`/`__rmul__` subclass-aware:** rejected;
  `rmul_with_af` has no class context (staticmethod) and `__rmul__` coerces a non-Permutation
  operand, neither of which is the construction mechanism the issue is about.
