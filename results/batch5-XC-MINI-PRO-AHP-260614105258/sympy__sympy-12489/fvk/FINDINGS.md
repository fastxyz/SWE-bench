# FINDINGS.md — `Permutation` subclassing (sympy #12489)

Plain-language findings, each as **`input → observed vs expected`**. Severity:
🔴 correctness bug (in scope) · 🟡 residual / out-of-primary-scope · 🟢 positive
(guard/assumption that *helps* the spec) · 🔵 proof-derived.

The spec (`SPEC.md`) is the dynamic-class contract: *every public construction/operation
on a class `C ⊑ Permutation` returns an instance of `C`, with the underlying array-form
value and all base-class behavior unchanged.*

---

## A. The original defect (pre-fix `aa9780761`) — fixed in V1 🔴→✅

**Finding A0 — `_af_new` hard-codes the result class.**
- input: `class Sub(Permutation): pass; Sub([1, 0, 2])` *(empty/​int/​cyclic/​Cycle form)* →
  observed (pre-fix): `Basic.__new__(Perm, perm)` makes a base **`Permutation`**, so
  `type(Sub([1,0,2])) is Permutation` on every path routed through the module-global
  `_af_new`; expected (L1): `type(...) is Sub`.
- root cause: `_af_new` was a `@staticmethod` with a baked-in `Perm`, and `__new__`'s
  early-return paths + every operation called the `Perm`-bound module global.
- **Fix (V1):** `_af_new` → `@classmethod` doing `Basic.__new__(cls, perm)` (L3); `__new__`
  routes through `cls._af_new`; operations through `self._af_new`; class-method
  constructors through their class first-arg. Verified by claims (NEW-*), (OP-*),
  (CTOR-*) in `PROOF_OBLIGATIONS.md`.

---

## B. Gaps the FVK audit found in **V1** — fixed in V2 🔴→✅

**Finding B1 — `__new__` `Permutation`-argument pass-through ignored the subclass.**
- input: `Sub(Permutation([1, 0, 2]))` *(shape g, sizes equal)* →
  observed (V1): the branch `if size is None or size == a.size: return a` returns the
  **base** `Permutation` argument unchanged, so `type(...) is Permutation`; expected
  (L1/L6, claim **NEW-g-rebuild**): `type(...) is Sub`.
- why V1 missed it: this path returns an *existing object* and never calls `_af_new`, so
  the V1 sweep of factory call-sites skipped it.
- **Fix (V2):** guard the identity return with `isinstance(a, cls)`; otherwise rebuild via
  `cls._af_new(a.array_form)` (a fresh copy — `array_form` already copies).
  `repo/.../permutations.py:865-870`.
- **Zero-regression argument (PO-2):** for `cls == Permutation`, *every* `Permutation`
  argument `a` satisfies `isinstance(a, Permutation)`, so the identity branch is always
  taken — base-class behavior, including `Permutation(p) is p`, is byte-for-byte
  preserved. The rebuild branch fires only for a strict subclass `cls` with an argument
  that is *not* already an instance of it — a scenario impossible before subclassing
  worked at all.

**Finding B2 — `__rmul__` coerced to the base class.**
- input: `[0, 2, 1] * Sub([1, 0, 2])` → Python dispatches `Sub(...).__rmul__([0,2,1])`,
  which ran `return Perm(other)*self`; observed (V1): `type(...) is Permutation`; expected
  (claim **OP-RMUL**): `type(...) is Sub` (the result tracks the only `Permutation`
  operand, `self`).
- **Fix (V2):** `return self.__class__(other)*self`. `repo/.../permutations.py:1244`.
- zero-regression: for base `self`, `self.__class__ is Permutation`, identical to `Perm`.

**Finding B3 — `from_sequence` (a `@classmethod` constructor) was missed by V1.**
- input: `Sub.from_sequence('SymPy')` → ran `return ~Permutation([...])`; observed (V1):
  `type(...) is Permutation`; expected (claim **CTOR-FSEQ**): `type(...) is Sub`.
- why V1 missed it: it constructs with the *literal* `Permutation([...])`, not via
  `_af_new`, so it wasn't in the V1 factory sweep. This is the one classmethod
  constructor V1 did not convert (the other six were).
- **Fix (V2):** `return ~self([i[1] for i in ic])` (`self` is the class). `:1504`.
- zero-regression: for base, `self is Permutation`, identical to `~Permutation([...])`.

**Finding B4 — `__add__` (and `__sub__`) rebuilt via the hard-coded base class.**
- input: `Sub([2, 1, 3, 0]) + 1` → ran `rv = Perm.unrank_lex(self.size, rank)`; observed
  (V1): `type(...) is Permutation`; expected (claim **OP-ADD**, an operation on the
  `self`-instance): `type(...) is Sub`. `__sub__` delegates to `__add__`, so it shared the
  bug.
- why V1 missed it: it constructs via the classmethod `Perm.unrank_lex(...)` on the
  *literal* base class, not via `_af_new` — outside the V1 sweep.
- **Fix (V2):** `Perm.unrank_lex(...)` → `self.unrank_lex(...)`. `self` is an instance, so
  the classmethod binds `cls = type(self)`. `repo/.../permutations.py:1164`.
- zero-regression: for base `self`, `self.unrank_lex is Permutation.unrank_lex` (PO-2).

**Finding B5 — `next_nonlex` rebuilt via the hard-coded base class.**
- input: `Sub([2, 0, 3, 1]).next_nonlex()` → ran `return Perm.unrank_nonlex(self.size, r+1)`;
  observed (V1): base `Permutation`; expected (claim **OP-NEXTNL**): `Sub`. (Analogous to
  `next_lex` / `next_trotterjohnson`, which V1 *did* fix via `self._af_new` — these two were
  the odd ones out because they go through `Perm.unrank_*`.)
- **Fix (V2):** `Perm.unrank_nonlex(...)` → `self.unrank_nonlex(...)`. `:1729`.
- zero-regression: for base, identical to `Perm.unrank_nonlex(...)` (PO-2).

---

## C. Accepted residuals — documented, **not** changed 🟡

**Finding C1 — `rmul_with_af` (`@staticmethod`) and the module-global `_af_new` produce base `Permutation`.**
- input: `Permutation.rmul_with_af(Sub(a), Sub(b))` → `return _af_new(_af_rmuln(...))` →
  base `Permutation`. Also any in-`combinatorics` caller of the imported global
  `_af_new` (e.g. `perm_groups.py`, `tensor_can.py`) yields base `Permutation`.
- **classification:** *not a bug for #12489.* A `@staticmethod` has **no** `self`/`cls`,
  and the args may be different subclasses — there is **no canonical result class**, so
  any choice is arbitrary. Keeping it base is (i) backward-compatible (PO-2) and (ii)
  exactly what the group-theory internals rely on. The module-global alias
  `_af_new = Perm._af_new` is deliberately retained as the base-class factory for
  class-agnostic internal code and external importers.
- **`[ESCALATION BOUNDARY]`-style note:** if a future caller needs subclass tracking
  here, the only well-defined choice is `args[-1]._af_new(...)` (matching `rmul`'s
  left-fold result class) — recorded in `ITERATION_GUIDANCE.md`, not applied.

**Finding C2 — `__pow__` exponent guard uses exact type.**
- input: `p ** Sub([0, 2, 1])` (a subclass *exponent*) → `if type(n) == Perm:` is
  `False`, so the helpful `NotImplementedError("p**p is not defined; do you mean p^p?")`
  is skipped and `int(n)` is attempted instead, raising a less informative error;
  expected: same `NotImplementedError` as for a base-`Permutation` exponent.
- **classification:** real but **out of the spec's scope** — this is *error-path*
  behavior, not the *result-class* contract PO-1 covers. Fixing it (`type(n) == Perm` →
  `isinstance(n, Perm)`) is zero-regression and recommended, but deliberately **not**
  applied to keep the change minimal/targeted (the issue is about returned-object class,
  not exponent validation). Recorded in `ITERATION_GUIDANCE.md`.

---

## D. Positive findings (guards/assumptions that *support* the spec) 🟢

**Finding D1 — the main array-form path was already correct.**
- `Permutation.__new__`'s terminal path `obj = Basic.__new__(cls, aform)` already used
  `cls` (pre-fix). So `Sub([1, 0, 2])` produced a `Sub` even before any fix; the bug was
  confined to the *early-return* shapes and the operations. This narrows the trusted
  surface and explains why the reporter's array-form smoke test could pass while
  subclassing was still broken elsewhere.

**Finding D2 — `array_form` returns a copy.**
- `array_form` is `self._array_form[:]`, so the B1 rebuild `cls._af_new(a.array_form)`
  binds a **fresh** list, honoring `_af_new`'s "the list must not be modified / is held
  only by the new object" contract (L5). No aliasing introduced.

**Finding D3 — the `isinstance(a, cls)` guard is the *exact* precondition (A1/PO-2).**
- A clean precondition for "return the argument unchanged" exists and is precisely
  `isinstance(a, cls)`. The fact that a clean guard exists (rather than an awkward case
  split) is positive evidence the B1 fix is right: it returns the input exactly when the
  input already satisfies the postcondition `isinstance(result, C)`, and rebuilds
  otherwise.

---

## E. Proof-derived findings (from `/verify`) 🔵

**Finding E1 — the `__new__` self-recursion is well-founded (1 level).**
- The `size`-adjust / `g-rebuild` branches re-enter `Permutation.__new__` via
  `cls(a.array_form, …)` / `cls._af_new(a.array_form)`. The recursive argument is a raw
  **list**, which lands in the array-form base case and never re-enters. ⇒ termination is
  trivial; the `[all-path]` claims are also total here. (PROOF.md §3.)

**Finding E2 — value-preservation is a syntactic invariant, not a semantic re-derivation.**
- Every fixed call-site changed only the *class* operand; the *perm* operand is identical
  to pre-fix. So PO-3 (array form unchanged) holds by inspection of the diff, and the
  proof can treat the value functions (`invertA`, `rmulA`, …) as opaque. This is why the
  whole audit reduces to a clean class-tag propagation proof. (PROOF.md §4.)

**Finding E3 — cross-class equality is intended, not a regression.**
- `Sub([0,1,2]) != Permutation([0,1,2])` (Basic compares `type` + hashable content). This
  already held pre-fix for the array-form path (D1) and is standard subclass semantics;
  internal group code stays all-base (C1), so nothing in `combinatorics` compares mixed
  classes. Flagged so a reviewer is not surprised. **Test guidance:** any subclass test
  should assert `type(x) is Sub` / `isinstance(x, Sub)`, **not** `x == Permutation(...)`.

---

## Summary table

| ID | Severity | Site | Disposition |
|----|----------|------|-------------|
| A0 | 🔴 | `_af_new` + all factory call-sites | Fixed in V1 |
| B1 | 🔴 | `__new__` shape-g pass-through (`:865`) | **Fixed in V2** |
| B2 | 🔴 | `__rmul__` (`:1244`) | **Fixed in V2** |
| B3 | 🔴 | `from_sequence` (`:1504`) | **Fixed in V2** |
| B4 | 🔴 | `__add__` / `__sub__` (`:1164`) | **Fixed in V2** |
| B5 | 🔴 | `next_nonlex` (`:1729`) | **Fixed in V2** |
| C1 | 🟡 | `rmul_with_af` / global `_af_new` | Accepted residual (documented) |
| C2 | 🟡 | `__pow__` guard `type(n)==Perm` | Recommended, not applied (out of scope) |
| D1–D3 | 🟢 | array-form path; `array_form` copy; `isinstance` guard | Positive |
| E1–E3 | 🔵 | recursion / value-preservation / equality | Proof-derived |
