# Control notes — V2 review & revision of sympy__sympy-12489

This documents every V2 decision (each new edit, and each decision to keep V1
unchanged), traced to numbered entries in `review/FINDINGS.md`.
`reports/baseline_notes.md` remains the V1 record; this file covers the review pass on
top of it (so where V2 changes something V1 had "left unchanged", the trace is noted
explicitly).

## Verdict
V1's core mechanism is correct and confirmed (F1–F5), but the review found **three
real subclassing leaks** that V1 had missed or left. All three are fixed. Everything
else is confirmed correct or consciously kept with justification.

The decisive review improvement over V1 was auditing *all five* ways a base instance
can be produced — not just `_af_new` sites — namely `Basic.__new__`, the global
`_af_new`, `Perm(...)`/`Permutation(...)` constructors, **class-qualified classmethod
calls `Perm.<ctor>(...)`**, and operations on freshly built base literals. The last
two categories are where V1's leaks hid.

## Code changes made in V2

### Change 1 — `from_sequence`: `~Permutation([...])` → `~self([...])`  (traces to F6)
A `@classmethod` constructor that built a hard-coded base `Permutation` and inverted
it, so `Subclass.from_sequence(...)` returned base — the issue's defect inside a
constructor V1 had otherwise fixed (F4). Using `self` (the class) builds the subclass;
`~` preserves it. Zero base regression: identical when `self is Permutation`; doctest
`Permutation.from_sequence('SymPy')` → `(4)(0 1 3)` unchanged (F6).

### Change 2 — `__rmul__`: `Perm(other)*self` → `self.__class__(other)*self`  (traces to F7)
`__mul__` takes the class of its left operand (F3), but `__rmul__` coerced the left
operand to base `Perm`, so `non_perm * subclass_perm` (the only route for
`list * Permutation`, used by `Permutation.rmul` for non-`Permutation` args) returned
base. Coercing to `self.__class__` makes the result match `self`. Zero base
regression: `self.__class__ is Permutation` for the base class; the `rmul` doctest
still holds (F7). Note this overrides V1's "leave `__rmul__`" decision, justified by F7.

### Change 3 — `__add__` / `next_nonlex`: `Perm.unrank_*(...)` → `self.unrank_*(...)`  (traces to F8)
Two instance methods delegated to the (now class-aware) `unrank_lex`/`unrank_nonlex`
classmethods but qualified the call with `Perm`, pinning `cls = Permutation`:
- `__add__` (line ~1162) `Perm.unrank_lex(...)` — and `__sub__` delegates to `__add__`,
  so `Subclass + n` and `Subclass - n` both leaked to base;
- `next_nonlex` (line ~1727) `Perm.unrank_nonlex(...)`.
Calling through the instance (`self.unrank_lex(...)`, `self.unrank_nonlex(...)`) binds
`cls = type(self)`. Zero base regression: identical when `type(self) is Permutation`;
doctests `I + a.rank() == a` and `p.next_nonlex()` → Permutation([3,0,1,2]) unchanged
(F8). These were invisible to V1's constructor-focused audit (method delegation, not
`Perm(...)`/`_af_new(...)`).

## V1 elements confirmed and kept unchanged

- **`_af_new` as classmethod with `Basic.__new__(cls, perm)`** — kept; verified against
  `Basic.__new__` semantics and metaclass-supplied `default_assumptions` (F1).
- **`__new__` routing through `cls`** (860/862/868/870/872; 922 already correct) —
  kept; covers every construction form, no recursion (F2).
- **Instance operators via `self._af_new`** (`mul_inv`, `__mul__`, `__pow__`, `__xor__`,
  `__invert__`, `next_lex`, `commutator`, `next_trotterjohnson`) — kept; doctest-checked
  identical for base, subclass-propagating otherwise (F3).
- **Classmethod constructors via `self._af_new` / `self(perm)`** (`unrank_nonlex`,
  `unrank_trotterjohnson`, `from_inversion_vector`, `random`, `unrank_lex`, `josephus`)
  — kept; doctest-checked (F4).
- **Module-level alias `_af_new = Perm._af_new`** — kept; needed for the staticmethod
  and external importers, backward compatible (all callers single-arg) (F5).
- **`__call__`'s `self*Permutation(...)`** — kept; already returns the subclass because
  `self` is the left operand of `*` (F9).

## V1 elements deliberately left as-is (with justification)

- **`rmul_with_af` keeps the global `_af_new`** (returns base) — F10. Staticmethod with
  no class context; internal optimization; deriving a class from `args[0]` adds an
  `IndexError` edge and serves no constructor role.
- **Same-size `isinstance(a, Perm)` pass-through returns `a`** — F11. Preserves the
  existing `Permutation(p) is p` identity optimization; rebuilding would force
  `Permutation(subclass_instance)` to *downcast* to base — a new surprising semantic.
  `isinstance` is already subclass-aware. Kept; limitation documented.
- **`__pow__` guard `type(n) == Perm`** — F12. Input recognition for an error guard,
  not object creation (creation in `__pow__` already fixed). Pre-existing and outside
  the reported defect; changing it would alter an error path. Kept to stay targeted;
  flagged as a possible separate change.
- **`__repr__` hard-coding "Permutation"; `if Permutation.print_cyclic`** — F13. Display
  only; `print_cyclic` is a documented *global* flag, so reading it from the base class
  is correct. Changing repr would break many doctests. Out of scope.
- **`Cycle` methods building base `Permutation`** — F15. `Cycle` is not a `Permutation`
  subclass and carries no subclass context; base output is correct.

## Behavioral observation (no action)
- **`Subclass([...]) != Permutation([...])`** follows from `Basic.__eq__` comparing
  exact types; inherent sympy behavior, not introduced by this fix, not in scope (F14).

## Net effect
After V2, **every permutation-object creation path honors the calling/owning class**:
constructors (`__new__` in every form, `_af_new`, `unrank_*`, `random`,
`from_inversion_vector`, `josephus`, `from_sequence`) and operators (`__mul__`,
`__rmul__`, `__pow__`, `__invert__`, `__xor__`, `__add__`, `__sub__`, `mul_inv`,
`commutator`, `next_lex`, `next_nonlex`, `next_trotterjohnson`, `__call__`) return the
subclass for subclasses, and remain byte-for-byte identical for base `Permutation`. The
only intentional remaining base-returning sites are the staticmethod helper
`rmul_with_af` (F10) and the same-size pass-through (F11), both justified above; the
remaining base references are non-creating (`isinstance` guard, `type==` guard, global
print flag, `Cycle` conversions, module aliases) per the post-fix invariant in
`review/FINDINGS.md`.
