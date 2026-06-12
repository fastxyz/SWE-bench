# FINDINGS — Permutation subclassing

Plain-language findings, each as `input → observed vs expected`. Findings are
non-blocking advice. "V1" = the fix as left after the first pass; "V2" = after
this FVK audit. The Findings report does **not** depend on machine-checking.

Severity legend: 🔴 correctness bug · 🟡 robustness / non-universal postcondition ·
🟢 confirmed-correct / positive finding.

---

## F1 🔴→🟢 `__new__` identity short-circuit returned the wrong class for subclasses

**Where:** `Permutation.__new__`, the `isinstance(a, Perm)` branch (was lines
866–868). Surfaced directly by trying to write a *universal* postcondition for
NEW-IDENTITY — it could not be written as `classOf(result) = cls`, and the
spec-difficulty is the bug signal.

- **input:** `class Sub(Permutation): pass; Sub(Permutation([1, 0, 2]))`
  → **V1 observed:** the *base* `Permutation` object is returned unchanged
  (`return a`), so `type(result) is Permutation` and
  `isinstance(result, Sub)` is **False**.
  → **expected (intent "constructing via `Sub` yields a `Sub`"):**
  `isinstance(result, Sub)` is True.

This is the one path of `__new__` that did **not** thread `cls`: every other path
already routed through `cls._af_new(...)` / `Basic.__new__(cls, …)` / the
`cls(a.array_form, size=size)` resize. The `return a` identity reuse ignored
`cls`.

**Fix (V2):** guard the identity reuse with the requested class —

```python
if size is None or size == a.size:
    if isinstance(a, cls):
        return a                  # already the right class: reuse (identity preserved)
    return cls(a.array_form)      # otherwise rebuild as the requested class
return cls(a.array_form, size=size)
```

**Why this guard and not `type(a) == cls`:** `isinstance(a, cls)` is the minimal
guard that makes **SUBCLASS-SOUND** universal while changing *zero* base-class
behavior. For `cls == Permutation`, `isinstance(any_perm, Permutation)` is always
True, so `Permutation(p)` still returns the *same object* `p` (the relied-upon
idempotency `Permutation(p) is p` is preserved exactly). The guard only ever fires
its new branch when `cls` is a **subclass** and `a` is not an instance of it — and
no such subclass exists anywhere in the shipped codebase, so no existing behavior
moves. See PROOF.md (NEW-IDENTITY) and PROOF_OBLIGATIONS PO-NEW-ID / PO-REG.

## F2 🟡 `__rmul__` coerces a non-Permutation operand to the base class — kept

- **input:** `[0, 2, 1] * Sub([0, 2, 1])` (a raw list on the left)
  → **observed:** `Perm(other) * self` builds a *base* `Permutation` from the
  list and multiplies, so the result is a base `Permutation`.
  → **expected:** ambiguous — the left operand is a plain list, not a `Sub`.

**Decision: keep.** `__rmul__` exists only to coerce a *non-Permutation* left
operand; making it mint a `Sub` would mean calling the subclass constructor on
data the user never routed through the subclass, which can be invalid for a
subclass with extra invariants. The *primary* product path
`self.__mul__(x)` already returns `type(self)` (the OP contract), so
`Sub(...) * anything` is a `Sub`. Only `non_perm * Sub` (which routes through
`__rmul__`) degrades to base, and that is acceptable. Documented, not changed.

## F3 🟡 `rmul_with_af` (`@staticmethod`) always returns base — kept

- **input:** `Permutation.rmul_with_af(Sub([1,0]), Sub([1,0]))`
  → **observed:** returns a base `Permutation` (the module-level `_af_new`,
  bound to `Permutation`, is used).
  → **expected:** ambiguous; it is an internal performance helper.

**Decision: keep.** A `@staticmethod` has no `cls`/`self` to dispatch on. This is
the *only* remaining internal user of the module-level `_af_new`, and producing a
base `Permutation` is acceptable for an internal helper. Changing it (e.g.
`args[0]._af_new`) would special-case the empty-args call and add risk for no
intent benefit.

## F4 🟡→🟢 `__pow__` used `type(n) == Perm` (hard-coded, not subclass-aware)

**Where:** `Permutation.__pow__`, the `p**p` guard (was line 1340).

- **input:** `Sub([2,0,3,1]) ** Sub([2,0,3,1])` (a subclass permutation exponent)
  → **V1 observed:** `type(n) == Perm` is **False** (type is `Sub`), so the guard
  is skipped and `int(n)` is attempted; `Permutation` defines no `__int__`, so a
  bare `TypeError` is raised instead of the intended, helpful
  `NotImplementedError('p**p is not defined; do you mean p^p (conjugate)?')`.
  → **expected:** the same `NotImplementedError` a base-class exponent triggers.

`type(x) == Perm` is exactly the hard-coded-class anti-pattern the whole issue is
about. **Fix (V2):** `isinstance(n, Perm)`. Zero base-class change (for any base
`Permutation` and for any non-Permutation exponent the truth value is identical);
it only additionally catches subclass exponents, which *should* be caught. See
PO-POW.

## F5 🟢 Module-level alias `_af_new = Perm._af_new` — confirmed correct

- **input:** the 7 external modules that do `_af_new = Permutation._af_new` and
  the `from … import _af_new` in `tensor_can.py`, then call `_af_new(list)`.
  → **observed:** with `_af_new` now a `classmethod`, `Permutation._af_new` is a
  method *bound to `Permutation`*, so `_af_new(list)` constructs a **base**
  `Permutation` — byte-for-byte the old behavior.
  → **expected:** base `Permutation` (backward compatibility). ✓

Confirmed by the ALIAS contract (`cls(Permutation)._af_new(A) ⇒ obj(Permutation,
A)`). No change. This is the load-bearing reason the staticmethod→classmethod
switch is non-breaking.

## F6 🟢 `Permutation(sub_instance)` keeps the subclass — accepted, documented

- **input:** `Permutation(Sub([1,0,2]))`
  → **observed (V2):** `isinstance(sub, Permutation)` is True, so the identity
  branch returns the `Sub` unchanged; result is a `Sub`.
  → **expected:** acceptable — the result *is* a `Permutation`
  (`isinstance(result, Permutation)` holds), and the alternative (downcasting to
  base, breaking `Permutation(x) is x`) is worse.

This is why **SUBCLASS-SOUND** is stated with `isinstance`, not exact type, for
NEW-IDENTITY (SPEC §3). Not a bug; it documents the deliberate scope of the
postcondition.

---

## Proof-derived findings (from `/verify`)

- **PD-1 (positive).** Every raw-data construction path —
  `_af_new`, the array path `Basic_new(cls, …)`, the int path, the factory
  `random`, the operation `mul` — discharges `classOf(result) = cls` (exact) by a
  *single* application of the construction axiom plus one dispatch rule. The proof
  is short precisely because, post-fix, the class is threaded uniformly. (Benefit
  2: a clean spec was *easy* to write for these paths — the opposite of a bug
  signal.)
- **PD-2 (the bug, F1).** The *only* path where the universal exact-class
  postcondition could **not** be discharged is NEW-IDENTITY under the V1 body:
  the refuted claim in `mini_python_spec.k` (commented out) has the concrete
  counter-model `C=SubV1, D=PermutationV1`,
  `isinstance(obj(PermutationV1,B), cls(SubV1)) = isSubclass(PermutationV1, SubV1)
  = false`. The forced retreat from `classOf = cls` to `isinstance` is the
  spec-difficulty signal that located F1.
- **PD-3 (escalation boundary, none).** No VC required inductive data-structure,
  multiset, or binder reasoning. The whole obligation set is dispatch + a
  reflexive-transitive `isSubclass` relation over a finite single-parent chain,
  which the bundled tier handles. No `[ESCALATION BOUNDARY]` was needed; no VC was
  faked `[trusted]`.
