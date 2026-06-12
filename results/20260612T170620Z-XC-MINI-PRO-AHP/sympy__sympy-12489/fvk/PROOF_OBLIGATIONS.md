# PROOF OBLIGATIONS — Permutation subclassing

Each obligation is what must hold for **SUBCLASS-SOUND** (SPEC §3) and for
backward compatibility. Status is against the **V2** code (V1 + this audit's
edits). "Discharged" = constructed proof in PROOF.md; not machine-checked.

Notation: `C` ranges over `{Permutation, Sub}` (any registered class); `D` over
any class; `A,B,L` are array forms; `N` an int. `⊑` is `isSubclass` (isinstance).

---

## Core construction

| # | Obligation | Reduces to | Status |
|---|---|---|---|
| **PO-AFNEW** | `cls(C)._af_new(A)` produces `obj(C, A)` — class is exactly `C`. | classmethod-on-class binds `cls = cls(C)`; body `Basic_new(cls, perm)` ↦ `Basic_new(cls(C), A)` ↦ `obj(C, A)` by the construction axiom. | ✅ discharged |
| **PO-AFNEW-INST** | `obj(C,_)._af_new(A)` produces `obj(C, A)` — class is `type(self)`. | classmethod-on-instance binds `cls = classObjOf(obj(C,_)) = cls(C)`; then as PO-AFNEW. | ✅ discharged |
| **PO-ALIAS** | module-level `_af_new(A)` (= `Permutation._af_new`) produces `obj(Permutation, A)`. | instance of PO-AFNEW at `C = Permutation`. | ✅ discharged |
| **PO-NEW-ARRAY** | `C(L:List)` produces `obj(C, L)`. | `construct` binds `__new__`'s `clsp = cls(C)`; cascade falls to `Basic_new(clsp, arg)`. | ✅ discharged |
| **PO-NEW-INT** | `C(N:Int)` produces an instance of `C`. | cascade int branch ↦ `cls(C)._af_new(rangeList(N))` ↦ PO-AFNEW. | ✅ discharged |
| **PO-NEW-CYCLE / -EMPTY / -CYCLEOBJ** | the `()` / cycle-args / `Cycle(...)` paths produce an instance of `C`. | each is a single `cls._af_new(...)` (V1 already routed these through `cls`); ↦ PO-AFNEW. | ✅ discharged (by inspection — identical shape to PO-NEW-INT) |

## The flagged path

| # | Obligation | Status |
|---|---|---|
| **PO-NEW-ID** | `C(obj(D,B))` produces `?O` with `?O ⊑ C` (isinstance), for **every** `D`. | ✅ discharged in **V2**; ❌ **false in V1**. Case split on `D ⊑ C`: (true) returns `obj(D,B)`, and `obj(D,B) ⊑ C` holds; (false) returns `construct(cls(C), B)` ↦ `obj(C,B)` by **PO-NEW-ARRAY** used as a lemma, and `C ⊑ C`. V1 omitted the guard and returned `obj(D,B)` unconditionally — refuted by `C=Sub, D=Permutation` (`Permutation ⋢ Sub`). |
| **PO-NEW-ID-RESIZE** | `C(obj(D,B), size=s)` with `s ≠ D.size` produces an instance of `C`. | ✅ `cls(C)(a.array_form, size=s)` ↦ `construct`-with-list ↦ PO-NEW-ARRAY. (Unchanged from V1; already threaded `cls`.) |

## Operations & factories

| # | Obligation | Status |
|---|---|---|
| **PO-OP** | `obj(C,_).mul(X)` produces an instance of `C` (= `type(self)`). | ✅ instance dispatch binds `self = obj(C,_)`; body `self._af_new(...)` ↦ PO-AFNEW-INST. Same shape covers `mul_inv, __pow__(int), __xor__, __invert__, next_lex, next_trotterjohnson, commutator, __add__, __sub__, next_nonlex`. |
| **PO-FACTORY** | `cls(C).random(N)` produces an instance of `C`. | ✅ classmethod binds `cls = cls(C)`; body `cls._af_new(...)` ↦ PO-AFNEW. Same shape covers `unrank_lex, unrank_nonlex, unrank_trotterjohnson, from_inversion_vector, josephus`. |

## Robustness / regression

| # | Obligation | Status |
|---|---|---|
| **PO-POW** | `p ** q` with `q` any `Permutation` (incl. subclass) raises `NotImplementedError`, not `TypeError`. | ✅ V2 uses `isinstance(n, Perm)`; V1's `type(n) == Perm` missed subclass exponents (F4). |
| **PO-REG (no regression)** | For `C = Permutation`, every contract yields **exactly** `obj(Permutation, …)`, identical to pre-fix behavior; and `Permutation(p) is p` for any `Permutation p`. | ✅ For `C = Permutation` the dispatch binds `cls(Permutation)` everywhere, so every result is base `Permutation`. PO-NEW-ID's guard `isinstance(a, Permutation)` is always True, so `return a` (identity) still fires — `Permutation(p) is p` preserved. No subclass exists in-tree, so the new rebuild branch is unreachable for shipped code. |
| **PO-KEEP-RMUL / -RMULAF** | `__rmul__` and `rmul_with_af` may yield base `Permutation`; this is in-spec (F2/F3), not an obligation to thread `cls`. | ✅ explicitly out of contract (SPEC §6). |

---

## Discharge summary

- All ✅ obligations are discharged by **construction** against `mini_python.k`
  (PROOF.md), **not** machine-checked.
- The single obligation that was **false in V1** is **PO-NEW-ID**; the V2 edit
  (F1) makes it hold. This is the audit's substantive result.
- **PO-POW** is a secondary robustness obligation the V2 edit (F4) closes.
- No obligation needed inductive/heap/multiset/binder reasoning ⇒ no
  `[ESCALATION BOUNDARY]`; nothing admitted `[trusted]`.
