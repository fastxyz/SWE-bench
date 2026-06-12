# SPEC — Permutation subclassing contract

**Target:** `repo/sympy/combinatorics/permutations.py` (the V1 fix is applied).
**Mode:** intent-spec (align NL intent ↔ code ↔ formal contract).
**Default:** partial correctness (correct *if* construction returns).
**Status:** constructed, **not** machine-checked (FVK MVP).

K artifacts: [`mini_python.k`](mini_python.k) (semantics fragment),
[`mini_python_spec.k`](mini_python_spec.k) (the claims below).

---

## 1. Intent

From `benchmark/PROBLEM.md` and the maintainer hint: **`Permutation` must be
subclassable.** The object-creation machinery (`__new__` and the internal
`_af_new` factory) must thread the *actual* class through construction instead of
hard-coding `Permutation`, so that a user subclass `Sub(Permutation)` yields `Sub`
instances — both when constructed and when operated on. The hint is specific:
`_af_new` should be a `classmethod` whose creation command is
`Basic.__new__(cls, perm)`.

The single property under verification is therefore about the **class of the
constructed object**, nothing else. The mini-Python fragment models exactly that
(`obj(C, A)` = class tag + array form) and abstracts away array validation, sizes,
cycles, exceptions, and caches, which cannot change the result class.

## 2. Vocabulary

- `cls(C)` — a class object named `C`. `obj(C, A)` — an instance with class `C`
  and array form `A`.
- `classOf(obj(C,_)) = cls(C)`; `isinstance(obj(C,_), cls(D)) = isSubclass(C, D)`;
  `isSubclass` is reflexive and walks the single-parent chain (`Sub → Permutation
  → Object`).
- The **one** trusted construction axiom: `Basic.__new__(cls(C), A) ⇒ obj(C, A)` —
  the produced object's class is **the class passed in**.
- Dispatch (CPython descriptor protocol, trusted): a `@classmethod` accessed on
  `X` binds its implicit parameter to `X` if `X` is a class, else to `type(X)`; a
  `@staticmethod` binds nothing implicit; an instance method binds `self` to the
  receiver; `C(arg)` runs `__new__` with its first explicit parameter bound to `C`
  even when `__new__` is inherited.

Logical (symbolic) variables are upper-case (`C`, `D`, `A`, `B`, `N`); program
identifiers are tokens (lower/mixed case). The class variable `C` ranges over
`{Permutation, Sub}`.

## 3. Function contracts (reachability rules)

Each contract is `φ_pre ⇒ φ_post`; the post-state pins the **class** of the
result. All are stated over the class table in `mini_python_spec.k`.

| Name | Contract | Precondition |
|---|---|---|
| **AFNEW** | `cls(C)._af_new(A) ⇒ obj(C, A)` | `C` is a class in the table |
| **AFNEW-INST** | `obj(C,_)._af_new(A) ⇒ obj(C, A)` | — |
| **ALIAS** | `cls(Permutation)._af_new(A) ⇒ obj(Permutation, A)` | — (corollary of AFNEW at `C=Permutation`) |
| **NEW-ARRAY** | `construct(cls(C), L:List) ⇒ obj(C, L)` | — |
| **NEW-INT** | `construct(cls(C), N:Int) ⇒ obj(C, ?A)` | — |
| **NEW-IDENTITY** | `construct(cls(C), obj(D,B)) ⇒ ?O` with **`isinstance(?O, cls(C)) = true`** | — (∀ `D`) |
| **OP** | `obj(C,B).mul(X) ⇒ ?O` with `classOf(?O) = cls(C)` | — |
| **FACTORY** | `cls(C).random(N) ⇒ ?O` with `classOf(?O) = cls(C)` | — |

### The master postcondition

> **(SUBCLASS-SOUND)** For every construction entry point `e` and every valid
> input `x`, the object `cls(C)`-construction produces satisfies
> `isinstance(result, cls(C)) = true` — the result is an instance of the class
> that was constructed. For the raw-data paths (`_af_new`, array, int, factory,
> operation-on-`self`) the stronger `classOf(result) = cls(C)` holds exactly.

NEW-IDENTITY is the **only** entry point where the exact form is *not* universal
(passing an already-built `obj(D,B)` that is itself an instance of `C` returns it
unchanged, so its class may be a *more derived* `D ⊑ C`). The weaker
`isinstance(result, cls(C))` is universal — and is exactly the intended property
("constructing via `C` gives you a `C`"). See FINDINGS F1.

## 4. The loop / recursion content

There are no counting loops here. The only back-edge is the **recursion in
`__new__`**: the NEW-IDENTITY rebuild branch and the resize branch call
`construct(cls(C), …)` again on a *list* argument, which is discharged by reusing
**NEW-ARRAY** as a lemma (its own claim is the coinduction hypothesis; the
genuine `construct`/`call` step provides guardedness). This is the
recursion-circularity pattern, not a counting-loop invariant.

## 5. Preconditions / side conditions surfaced

- `C` must be a class registered with a `__new__` reachable by MRO. In the real
  code this is guaranteed: every subclass inherits `Permutation.__new__`.
- NEW-ARRAY assumes the list is a *valid* array form. The real `__new__`
  validates and raises `ValueError` otherwise; that guard is a no-op on the
  in-domain inputs the contract covers and is modelled as identity (a Finding,
  not part of the proved domain — exceptions are outside the fragment).
- The exact-class postcondition is **not** claimed for NEW-IDENTITY; only
  `isinstance`. This weaker-but-universal form is the deliberate spec choice
  (§3, FINDINGS F1).

## 6. What is intentionally out of contract

- `__rmul__` (`Perm(other)*self`): coerces a **non-Permutation** left operand to
  the base class; result class is base. Left operand is not a subclass instance,
  so this is in spec intent (FINDINGS F2, kept).
- `rmul_with_af` (`@staticmethod`): no class/instance to dispatch on; returns base
  (FINDINGS F3, kept).
- Exceptions / validation / `print_cyclic` / numeric values of array forms — out
  of fragment.
