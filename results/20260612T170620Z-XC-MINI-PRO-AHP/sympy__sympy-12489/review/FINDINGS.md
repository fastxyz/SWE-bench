# Code review — sympy__sympy-12489 (V1 fix)

Scope: `repo/sympy/combinatorics/permutations.py` (the only file V1 changed). The issue
asks that `Permutation` be subclassable: `_af_new` should be a `classmethod` creating
with `Basic.__new__(cls, perm)`, and the construction machinery should honor the actual
class instead of hard-coding `Permutation`.

Severity legend: **[blocker]** must fix · **[minor]** fix if cheap/safe ·
**[note]** intentional / out-of-scope, documented.

---

## F1 — Core change matches the issue and is structurally sound. [note]
`_af_new` is now `@classmethod def _af_new(cls, perm): ... Basic.__new__(cls, perm)`,
and `__new__` routes every creation path through `cls` (`cls._af_new(...)` for the
empty/cycle/int/Cycle paths, `cls(a.array_form, size=size)` for the resize path; the
array-form path already used `Basic.__new__(cls, aform)`). Verified `Basic.__new__(cls,
*args)` (core/basic.py:80) is generic — `obj = object.__new__(cls); obj._args = args` —
so it constructs any subclass correctly. This is exactly the change the issue/hint
requested. **Conclusion: correct.**

## F2 — `__init__` is now invoked for subclass instances; verified harmless. [note]
Standard `type.__call__` does `obj = cls.__new__(...)` then, *iff* `isinstance(obj, cls)`,
`cls.__init__(obj, *args, **kwargs)`.
- Verified neither metaclass overrides the protocol: `BasicMeta` (core/core.py:68) and
  `ManagedProperties` (core/assumptions.py:313) define only `__init__` (class
  registration / assumptions), not `__call__`/`__new__`.
- Verified `Basic` defines no `__init__` and `Permutation` defines no `__init__` (the
  only `__init__` in permutations.py, line 425, is in `Cycle(dict)`), so the effective
  `__init__` is `object.__init__`.
- CPython rule: `object.__init__` ignores excess args when the class overrides `__new__`
  but not `__init__` — which is exactly this case — so no `TypeError`.

Before V1, the base class already returned an instance of the called type from every
path (the array path), so `object.__init__` was *already* called with the constructor
args; V1 does not change that for the base class. For subclasses, `__init__` now runs —
this is the standard Python contract the issue explicitly asked to restore ("stick to
Python's instance creation mechanisms"). A subclass with a custom `__init__` receives the
constructor args, as expected. **No regression.**

## F3 — Module-level alias `_af_new = Perm._af_new` stays correct. [note]
With `_af_new` now a classmethod, `Perm._af_new` is a method bound to `Permutation`, so
the module global `_af_new(perm)` still yields a base `Permutation`. All external
importers — `perm_groups`, `named_groups`, `util`, `tensor_can`, `tensor`,
`group_constructs` (each does `_af_new = Permutation._af_new`), plus
`testutil`/`polyhedron` (`Permutation._af_new(...)`/`Perm._af_new(...)`) — are unaffected
(they intentionally produce base `Permutation`s). Equivalent to the old staticmethod for
callers; only a negligible bound-method indirection. **No regression.**

## F4 — Pickling/copy now round-trips subclasses; base unchanged. [note]
`Basic.__reduce_ex__` returns `(type(self), self.__getnewargs__(), ...)` and
`__getnewargs__` returns `self.args == (aform,)`. With the fix, unpickling a subclass
calls `Subclass(aform)` → array path → subclass instance. For the base class this is
identical to before. Positive side effect, **no regression.**

## F5 — No existing `Permutation` subclasses ⇒ base behavior provably identical. [note]
Searched the whole tree: there is no `class …(Permutation)`/`class …(Perm)`. Therefore
in every existing call site `cls` / `type(self)` / `self`(-as-class) resolves to
`Permutation`, and since `Perm is Permutation`, each rewritten expression
(`self._af_new(x)`, `cls._af_new(x)`, `cls(...)`, `self.unrank_*`, `self(perm)`) produces
an object identical to the V0 code. All doctests exercise the base class, so they are
unaffected. This is what makes the breadth of V1 safe rather than risky.

## F6 — V1 MISSED the `from_sequence` factory. [blocker → FIXED]
`from_sequence` (a `@classmethod`, line 1480) returned `~Permutation([i[1] for i in ic])`,
hard-coding the base class. So `Subclass.from_sequence(seq)` would return a base
`Permutation` — inconsistent with the other factory classmethods V1 *did* fix (`random`,
`unrank_lex`, `unrank_nonlex`, `unrank_trotterjohnson`, `from_inversion_vector`,
`josephus`) and contrary to the issue ("always instances of `Permutation` are returned").
**Fix applied:** `return ~self([i[1] for i in ic])`. `self` is the class, so for the base
class `self([...]) == Permutation([...])` (identical, including the doctest output
`(4)(0 1 3)`); for a subclass it constructs the subclass, and `~` preserves it through
the now-classmethod-based `__invert__`. This was the only genuine defect found.

## F7 — Static helpers `rmul` / `rmul_with_af` left as base. [note]
Both are `@staticmethod` with no class/instance to dispatch on. `rmul` reduces via `*`,
so it already preserves the operands' type through `__mul__`. `rmul_with_af` uses the
module-level `_af_new` and returns a base `Permutation`; it is an explicitly internal,
performance-oriented helper taking `*args` with no canonical owning class. Leaving it as
base is acceptable and avoids guessing an owner from `args`. **Intentional.**

## F8 — `__rmul__`: `Perm(other)*self` intentionally coerces to base. [note]
`__rmul__` coerces a *non-Permutation* left operand (e.g. a raw list) to a base
`Permutation` before multiplying. The left operand is not a subclass instance, so
coercing to base is the correct semantics; routing it through `self.__class__` could feed
input a subclass constructor does not accept. Result of `[list] * subclass` is a base
`Permutation` — an acceptable edge driven by the (non-subclass) left operand. **Left.**

## F9 — `__pow__` guard `if type(n) == Perm` is exact-type, not isinstance. [note]
This guards `p**p` by inspecting the *exponent's* type. Now that subclass instances can
exist, `p ** subclass_instance` skips the guard and raises `TypeError` from `int(n)`
instead of the intended `NotImplementedError`. This is an exponent-type check, not an
object-creation path; it is pre-existing and does not affect the base class
(`p ** int` correctly returns the subclass). Out of the issue's scope (creation);
flagged as a minor, separable robustness item. **Left unchanged.**

## F10 — Identity short-circuit `return a` in `__new__` is deliberate. [note]
When an existing `Permutation` is passed with a matching size, `__new__` returns that
same object (`line 867`). Consequently `Subclass(base_perm)` (same size) returns the base
instance, and `Permutation(sub_perm)` returns the subclass instance. This preserves the
original identity optimization and avoids disturbing equality/identity/performance
assumptions elsewhere. Construction from raw data and the resize branch both honor `cls`.
A user who needs to re-type can use `Subclass(p.array_form)`. **Intentional limitation.**

## F11 — `@classmethod`s use `self` (not `cls`) as first param. [note]
Pre-existing convention in this file. `self._af_new(...)`, `self(perm)`,
`self.unrank_*(...)` inside these classmethods are correct because `self` *is* the class.
Kept the existing parameter name to minimize churn. **Cosmetic, no change.**

## F12 — Intermediate base-class constructions are harmless. [note]
`__call__` (line 1574) builds `Permutation(Cycle(*i), size=self.size)` only as the right
operand of `self*…`; the result type flows from `self.__mul__` → subclass, so the
intermediate's class is irrelevant. The `Permutation(self)` calls at lines 395/417 and
`self(*c)` at 441 are inside `Cycle`, converting a `Cycle` to a base `Permutation` —
unrelated to `Permutation` subclassing. `self(i)` (line 1358) is permutation *application*
(`__call__`), not construction. **All correctly left unchanged.**

## F13 — Docstrings/doctests remain consistent; no test files touched. [note]
`_af_new`'s example `Perm._af_new(a)` still yields `Permutation([2, 1, 3, 0])`.
`from_sequence`'s doctest (`Permutation.from_sequence('SymPy') -> (4)(0 1 3)`) is
unchanged because `self` resolves to `Permutation`. No edits to any test/`_test_` files,
per task constraints.

---

## Verdict
V1's design is correct and its breadth is provably safe (F1–F5). One real consistency
defect existed — the `from_sequence` factory (F6) — now fixed. All other base-class
construction sites are either correctly rewritten or intentionally and defensibly left
(F7–F12). Remaining items (F9 exact-type guard, F10 identity short-circuit) are
documented, out-of-scope-or-deliberate, and carry no base-class regression.
