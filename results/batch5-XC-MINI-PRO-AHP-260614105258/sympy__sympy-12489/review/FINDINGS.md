# Code review — V1 fix for sympy__sympy-12489

Issue: `combinatorics.Permutation` cannot be subclassed properly because object
creation funnels through `Permutation._af_new`, a `staticmethod` hard-coding
`Basic.__new__(Perm, perm)`, so every result is a base `Permutation`. Public hint:
make `_af_new` a `classmethod` using `Basic.__new__(cls, perm)`.

V1 fix (recap): `_af_new` → `classmethod` (`Basic.__new__(cls, perm)`); `__new__`
routes creation through `cls`; instance operators use `self._af_new`; classmethod
constructors use `self._af_new` / `self(perm)`; `rmul_with_af`, `__rmul__`, the
same-size `isinstance(a, Perm)` pass-through, and the module-level alias left as-is.

Review method: no execution environment, so correctness is argued by reasoning about
Python's descriptor/`__new__` semantics and by checking every in-file doctest and
every cross-module caller for behavioral equivalence on the **base** class (the only
class exercised by existing tests/doctests). I re-audited *every* way a base instance
can be produced, not only `_af_new` sites: (a) `Basic.__new__(...)`, (b) module-global
`_af_new(...)`, (c) `Perm(...)`/`Permutation(...)` constructor calls, (d)
class-qualified classmethod calls `Perm.<ctor>(...)`, and (e) operations applied to a
freshly built base literal.

---

## F1 — Core change is correct  [Correctness · CONFIRMED]
`@classmethod def _af_new(cls, perm): p = Basic.__new__(cls, perm); ...`.
`Basic.__new__(cls, *args)` (core/basic.py:80) is `object.__new__(cls)` plus
`obj._assumptions = cls.default_assumptions` and `obj._args = args`. Passing a
subclass `cls` yields a subclass instance; `default_assumptions` is supplied for any
`Basic` subclass by the `ManagedProperties` metaclass. The previous `Perm`-hard-coded
form is the special case `cls is Permutation`, so base behavior is preserved.
Verdict: correct foundation.

## F2 — `__new__` now routes all paths through `cls`  [Correctness · CONFIRMED]
Lines 860/862/870/872 use `cls._af_new(...)`; line 868 (size adjust) uses
`cls(a.array_form, size=size)`; line 922 (main array-form path) already used
`Basic.__new__(cls, aform)`. So `Subclass()`, `Subclass(int)`, `Subclass(Cycle)`,
`Subclass(c1, c2, ...)`, `Subclass([...])`, `Subclass([[...]])` all produce the
subclass. No infinite recursion in 868: `a.array_form` is a list of ints, which takes
the main path. Verdict: correct.

## F3 — Instance operators preserve subclass with zero base regression  [Regression · CONFIRMED SAFE]
`mul_inv`, `__mul__`, `__pow__`, `__xor__`, `__invert__`, `next_lex`, `commutator`,
`next_trotterjohnson` now use `self._af_new(...)`. `self._af_new` resolves the
classmethod on `type(self)`; when `type(self) is Permutation` this is *identical* to
the old module-global `_af_new` (which is `Permutation._af_new`). Doctests checked and
unchanged: `a*b`→[2,0,1], `p**4`→Permutation([0,1,2,3]), `~p`→Permutation([2,3,0,1]),
etc. Verdict: safe; enables subclass propagation through operators.

## F4 — Classmethod constructors preserve subclass with zero base regression  [Regression · CONFIRMED SAFE]
`unrank_nonlex`, `unrank_trotterjohnson`, `from_inversion_vector`, `random`,
`unrank_lex` use `self._af_new(...)`; `josephus` uses `self(perm)` (faithful to its
original validating `Perm(perm)`). In a `@classmethod` the first parameter (named
`self` here) is the class, so for base calls these equal the prior behavior. Doctests
checked: `Permutation.random(2) in (...)`, `unrank_lex(5,10)`→Permutation([0,2,4,1,3]),
`josephus(3,6,2).array_form`→[2,5,3,1,4,0], `from_inversion_vector([3,2,1,0,0])`, etc.
None use `self` as an instance. Verdict: safe.

## F5 — `classmethod` conversion is backward compatible  [Backward-compat · CONFIRMED]
Every in-repo caller invokes `_af_new` with a **single** argument (the array form):
`named_groups.py`, `tensor_can.py`, `util.py`, `group_constructs.py`,
`perm_groups.py` use `_af_new = Permutation._af_new` then `_af_new(list)`;
`testutil.py`/`polyhedron.py` call `Permutation._af_new(list)` / `Perm._af_new(list)`.
A classmethod auto-binds `cls`, so single-arg calls remain correct, and none pass an
explicit class (which would have broken). Module-level alias `_af_new = Perm._af_new`
(line 2831) is preserved and, being bound to `Perm`, still yields base `Permutation`.
Verdict: no external breakage.

## F6 — `from_sequence` still created a base `Permutation` (V1 MISS)  [Correctness gap · FIXED]
`from_sequence` (a `@classmethod` alternate constructor, line ~1502) read
`return ~Permutation([i[1] for i in ic])`. The hard-coded `Permutation(...)` builds a
base instance and `~` (inversion) keeps that class, so `Subclass.from_sequence(...)`
returned a base `Permutation` — exactly the defect the issue describes, in a
constructor V1 otherwise made subclass-aware (cf. F4). V1's audit missed it because it
scanned only `_af_new` sites (audit category (e), not (b)).
Fix applied: `return ~self([i[1] for i in ic])` (`self` is the class →
`self([...])` builds the subclass; `~` preserves it). Base doctest
`Permutation.from_sequence('SymPy')`→`(4)(0 1 3)` is unchanged (`self is Permutation`).

## F7 — `__rmul__` coerced to base, leaking through reflected `*` (V1 INCONSISTENCY)  [Consistency · FIXED]
`__rmul__` (line ~1242) read `return Perm(other)*self`. Since `__mul__` takes the
class of its *left* operand (`self._af_new`, see F3), `non_perm * subclass_perm`
returned a base `Permutation`, inconsistent with the now-subclass-aware `__mul__`.
This is the only route for `list * Permutation` (and the one `Permutation.rmul` uses
for non-`Permutation` args). Fix applied: `return self.__class__(other)*self`. For
base, `self.__class__ is Permutation`, identical to `Perm`; the `rmul` doctest
(`Permutation.rmul(a, [0,2,1]) == Permutation.rmul(a, b)`) still holds. `other` is
never already a `Permutation` here (else `__mul__` on the left operand would have run),
so the `isinstance(a, Perm)` pass-through (F11) is not reached.

## F8 — Class-qualified classmethod calls pinned the base class (V1 MISS)  [Correctness gap · FIXED]
Audit category (d): two instance methods delegated to subclass-aware classmethods but
qualified the call with `Perm`, forcing the base class:
- `__add__` (line ~1162): `rv = Perm.unrank_lex(self.size, rank)` — and `__sub__`
  delegates to `__add__`, so both `Subclass + n` and `Subclass - n` returned base.
- `next_nonlex` (line ~1727): `return Perm.unrank_nonlex(self.size, r + 1)`.
Even though `unrank_lex`/`unrank_nonlex` are now class-aware (F4), `Perm.<m>(...)`
binds `cls = Permutation`. These were missed by the constructor-focused grep because
they are method delegations, not `Perm(...)`/`_af_new(...)` construction.
Fix applied: call via the instance — `self.unrank_lex(...)` / `self.unrank_nonlex(...)`
(invoking a classmethod through an instance binds `cls = type(self)`). For base,
`type(self) is Permutation`, identical to `Perm.<m>`; doctests
`I + a.rank() == a` and `p.next_nonlex()`→Permutation([3,0,1,2]) are unchanged.

## F9 — `__call__`'s `self*Permutation(...)` is already correct  [Correctness · CONFIRMED OK]
`__call__` (line ~1574) `return self*Permutation(Cycle(*i), size=self.size)` returns
`type(self)` because `self` is the left operand of `*` and `__mul__` builds via
`self._af_new` (F3). No change needed.

## F10 — `rmul_with_af` returns base  [Intentional · KEPT]
`rmul_with_af` is a `@staticmethod` (no `self`/`cls`) and keeps the module-global
`_af_new` (→ base). It is an internal group-theory speed helper operating on arbitrary
`Permutation` args; deriving a class from `args[0]` would add an `IndexError` edge for
empty args and change an internal optimization with no user-facing constructor role.
Verdict: acceptable to leave; documented.

## F11 — Same-size `isinstance(a, Perm)` pass-through returns `a` unchanged  [Trade-off · KEPT]
`__new__` case (g): when `a` is a `Permutation` and the size already matches, V1
returns `a` (preserving the existing `Permutation(p) is p` identity optimization);
only the size-mismatch sub-case rebuilds (now via `cls`, F2). Consequence:
`Subclass(base_perm)` with equal size returns the base instance. Rebuilding it (e.g.
`if type(a) is not cls: return cls._af_new(a.array_form)`) would also make
`Permutation(subclass_instance)` *downcast* to base — a new, surprising semantic for
the base constructor and a change to identity/equality for an obscure case. Kept V1's
conservative behavior; limitation documented. `isinstance` here is already subclass-
aware (accepts subclasses), which is correct.

## F12 — `__pow__` guard uses exact `type(n) == Perm`  [Out of scope · KEPT]
`if type(n) == Perm:` (line ~1340) does not recognize a subclass exponent, so
`p ** subclass_perm` would fall through to `int(n)` and raise `TypeError` instead of
the intended `NotImplementedError`. This is *input recognition for an error guard*,
not object creation (the creation in `__pow__` is already fixed, F3). It is
pre-existing, unrelated to the reported defect, and inconsistent with the
`isinstance(a, Perm)` at line 865; left unchanged to keep the fix targeted to object
creation. Noted as a candidate for a separate change.

## F13 — `__repr__` hard-codes the string "Permutation"  [Out of scope · KEPT]
Subclass instances print as `Permutation([...])`. This is display only, not object
creation; changing it would break numerous doctests that assert `Permutation([...])`
output. The `if Permutation.print_cyclic:` read at line ~980 reads the documented
*global* print flag (line 2792 comment) from the base class, which is correct by
design. Out of scope; left unchanged.

## F14 — Subclass != base equality  [Inherent behavior · OBSERVATION]
`Basic.__eq__` (core/basic.py:313,328) returns `False` when `type(self) is not
type(other)`, so `Subclass([0,1,2]) != Permutation([0,1,2])`. This is inherent sympy
semantics, not introduced by the fix, and not part of the reported issue. No action.

## F15 — `Cycle` methods create base `Permutation`  [Correctness · CONFIRMED OK]
`Cycle.cyclic_form`/`__repr__` etc. (lines ~395/417/462) build base `Permutation`/
`Cycle`. `Cycle` is not a `Permutation` subclass and carries no subclass context, so
base instances are correct. No change.

---

## Post-fix invariant
After V2, executable references to the base class are exactly: `isinstance(a, Perm)`
(subclass-aware, F11), `type(n) == Perm` (error guard, F12), `if Permutation.print_cyclic`
(global flag, F13), the `Cycle` conversions (F15), `rmul_with_af`'s global `_af_new`
(F10), and the module aliases `Perm = Permutation` / `_af_new = Perm._af_new`. Every
remaining permutation-object *creation* path honors the calling/owning class.
