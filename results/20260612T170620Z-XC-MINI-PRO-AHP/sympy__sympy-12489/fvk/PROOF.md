# PROOF — Permutation subclassing contract (constructed, not machine-checked)

Proves the contracts in [`SPEC.md`](SPEC.md) / [`mini_python_spec.k`](mini_python_spec.k)
against the semantics in [`mini_python.k`](mini_python.k), by symbolic execution.
**MVP caveat:** the toolchain is *not* run here; see "Reproduce the machine check".

Throughout, the construction axiom

> **(NEW★)** `Basic_new(cls(C), A) ⇒ obj(C, A)`

is the load-bearing step, and the dispatch rules (`cm`/`sm`/`im`/`construct`) bind
the implicit class/`self` per CPython's descriptor protocol. `C` is a symbolic
class in `{Permutation, Sub}`; `D` is any class; `⊑` is `isSubclass`.

---

## 1. AFNEW — `cls(C)._af_new(A) ⇒ obj(C, A)`

```
call(cls(C), _af_new, A)
  ⊢ mlookup(classTable, C, _af_new) = method(cm, perm, ret Basic_new(cls, perm))   [MRO]
  ⇒ ret Basic_new(cls, perm)            with env { cls ↦ classObjOf(cls(C)) = cls(C),  perm ↦ A }   [cm dispatch]
  ⇒ ret Basic_new(cls(C), A)            [read cls, perm from env]
  ⇒ ret obj(C, A)                       [NEW★]
  ⇒ obj(C, A)                           [ret V ⇒ V, pop frame]
```

`classObjOf(cls(C)) = cls(C)`, so the class produced is exactly `C`. ∎ (PO-AFNEW)

**AFNEW-INST** is identical except the receiver is `obj(C,_)` and
`classObjOf(obj(C,_)) = cls(C)` — the classmethod binds `cls` to `type(self)`. ∎
(PO-AFNEW-INST)

**ALIAS** is AFNEW instantiated at `C = Permutation`:
`cls(Permutation)._af_new(A) ⇒ obj(Permutation, A)`. ∎ (PO-ALIAS) — this is the
backward-compatibility fact for every external `_af_new = Permutation._af_new`
caller and the `from … import _af_new` in `tensor_can.py`.

## 2. NEW-ARRAY — `construct(cls(C), L:List) ⇒ obj(C, L)`

```
construct(cls(C), L)
  ⊢ mlookup(classTable, C, __new__) = methodNew(clsp, arg, BODY)        [MRO: Sub inherits Permutation.__new__]
  ⇒ BODY                          with env { clsp ↦ cls(C),  arg ↦ L }  [construct dispatch — cls bound to C]
  = if isObjV(arg) then … else (if isIntV(arg) then … else ret Basic_new(clsp, arg))
  ⇒ ⊥-branch twice: isObjV(L)=false, isIntV(L)=false                    [L is a List]
  ⇒ ret Basic_new(cls(C), L) ⇒ ret obj(C, L) ⇒ obj(C, L)               [read clsp, NEW★]
```
∎ (PO-NEW-ARRAY). **NEW-INT** takes the `isIntV` branch to
`call(cls(C), _af_new, rangeList(N))` and finishes by **AFNEW** ⇒ `obj(C, _)`. ∎
(PO-NEW-INT). The `()`, multi-arg-cycle and `Cycle(...)` paths have the same shape
(`cls._af_new(…)` ⇒ AFNEW) and were already correct in V1. ∎

## 3. NEW-IDENTITY — the crux — `construct(cls(C), obj(D,B)) ⇒ ?O`, `?O ⊑ C`

```
construct(cls(C), obj(D,B))
  ⇒ BODY   with env { clsp ↦ cls(C), arg ↦ obj(D,B) }                  [construct dispatch]
  ⇒ isObjV(obj(D,B)) = true → take the object branch
  ⇒ if isinstance(arg, clsp) then ret arg else ret construct(clsp, arrayForm(arg))
  ⇒ if isinstance(obj(D,B), cls(C)) then ret obj(D,B) else ret construct(cls(C), B)
  ⇒ if (D ⊑ C) then ret obj(D,B) else ret construct(cls(C), B)         [isinstance rule]
```

**Case split** on the guard `D ⊑ C` (Case Analysis / `#Or`):

- **`D ⊑ C` true:** `⇒ ret obj(D,B) ⇒ obj(D,B)`. Postcondition
  `isinstance(obj(D,B), cls(C)) = (D ⊑ C) = true`. ✓
- **`D ⊑ C` false:** `⇒ ret construct(cls(C), arrayForm(obj(D,B))) = ret
  construct(cls(C), B)`. Here `B` is a `List`, so this is **NEW-ARRAY** on a
  strictly advanced state ⇒ `obj(C, B)`. Postcondition `isinstance(obj(C,B),
  cls(C)) = (C ⊑ C) = true`. ✓

Both branches land in `?O` with `isinstance(?O, cls(C)) = true`. ∎ (PO-NEW-ID)

**Circularity / lemma reuse.** The false-branch reuses **NEW-ARRAY** as a lemma on
`construct(cls(C), B)`. This is sound by guarded coinduction: the `construct` step
is one genuine `=>⁺` transition, so the contract may be invoked on the shifted
(list-argument) state. Termination is immediate (the rebuild argument is a `List`,
which takes the non-recursive `Basic_new` branch); no second recursion occurs.

**Why V1 failed here (refutation).** Under the V1 body the object branch is just
`ret arg`, so `?O = obj(D,B)` unconditionally and the postcondition becomes
`D ⊑ C`, which is **not valid**: the concrete model `C = Sub`, `D = Permutation`
gives `Permutation ⊑ Sub = false`. The commented refuted claim in
`mini_python_spec.k` records exactly this counter-model. The V2 guard
`isinstance(a, cls)` is precisely the predicate that splits the goal so both
branches close. (FINDINGS F1, PD-2.)

## 4. OP and FACTORY

**OP** `obj(C,B).mul(X)`:
```
call(obj(C,B), mul, X)
  ⊢ mlookup(.., C, mul) = method(im, other, ret call(self, _af_new, arrayForm(self)))
  ⇒ ret call(self, _af_new, arrayForm(self))   env { self ↦ obj(C,B), other ↦ X }   [im dispatch]
  ⇒ ret call(obj(C,B), _af_new, B)             [read self, arrayForm]
  ⇒ ret obj(C, B) ⇒ obj(C, B)                  [AFNEW-INST]
```
`classOf(obj(C,B)) = cls(C) = type(self)`. ∎ (PO-OP). The ten instance operations
listed in PO-OP share this shape (each ends in `self._af_new(...)` /
`self.unrank_*` which dispatches the classmethod on `type(self)`).

**FACTORY** `cls(C).random(N)`:
```
call(cls(C), random, N)
  ⇒ ret call(cls, _af_new, rangeList(n))   env { cls ↦ cls(C), n ↦ N }   [cm dispatch]
  ⇒ ret call(cls(C), _af_new, L) ⇒ ret obj(C, L) ⇒ obj(C, L)            [AFNEW]
```
∎ (PO-FACTORY). Same shape for the five factory classmethods.

## 5. Backward compatibility (PO-REG)

Set `C := Permutation`. Every dispatch above binds the implicit class to
`cls(Permutation)`, so every result is `obj(Permutation, …)` — identical to the
pre-fix base behavior. In NEW-IDENTITY the guard `isinstance(a, Permutation)` is
**always** true for a `Permutation` argument, so the proof takes the first branch
`ret a` — i.e. `Permutation(p)` returns the *same object* `p`. The idempotency
`Permutation(p) is p` and the identity short-circuit are preserved verbatim. The
new rebuild branch is reachable only when `cls` is a strict subclass and `a` is
not an instance of it; **no such subclass exists in the shipped tree**, so no
shipped call site changes. ∎

## 6. Residual risk

- **Partial vs total correctness.** Contracts are partial: *if* construction
  returns, the class is correct. The only recursion (NEW-IDENTITY rebuild) is
  one-step and provably terminating, so for these contracts partial = total in
  practice; not separately machine-proved.
- **Trusted base.** (a) The adequacy of the four mini-Python **dispatch rules** to
  CPython's real descriptor protocol — classmethod binds `cls = type(recv)`/`recv`,
  staticmethod binds nothing, `C(x)` runs inherited `__new__` with `cls = C`, MRO
  resolves along the single-parent chain. (b) The construction axiom **(NEW★)**:
  `object.__new__(C)` is an instance of `C`. (c) The K reachability metatheory and
  `kprove`. (d) That array-validation / size / cycle handling abstracted away in
  the fragment cannot change the result *class* — true because in the real code
  those only compute the array form passed to `Basic.__new__(cls, …)`, never the
  class.
- **Constructed, not machine-checked.** No `kompile`/`kprove` was run.

## 7. Test-redundancy (benefit 1) — recommendation only, NEVER auto-delete

Conditioned on machine-checking the claims (`kprove ⇒ #Top`):

- **Subsumed by the proof (in-domain):** any unit test of the form "constructing
  / operating on a subclass yields an instance of that subclass" for the proved
  entry points — e.g. `isinstance(Sub([0,2,1]), Sub)`, `isinstance(Sub(2), Sub)`,
  `isinstance(Sub([0,2,1]) * Sub([0,2,1]), Sub)`, `isinstance(Sub.random(3),
  Sub)`, `isinstance(Sub(Permutation([0,2,1])), Sub)` — is entailed by AFNEW /
  NEW-* / OP / FACTORY / NEW-ID and would become redundant.
- **Keep regardless:** (i) the base-class behavioral tests (`Permutation(p) is p`,
  array/cyclic-form normalization, sizes, cycles) — they pin the abstracted-away
  parts outside the fragment; (ii) the `ValueError`/`NotImplementedError`
  exception tests — exceptions are out of fragment; (iii) any termination /
  performance / integration tests.

**Honesty gate:** the proof is *constructed, not machine-checked*. Do **not**
remove any test until `kprove` returns `#Top`. The Findings (F1–F6) stand
independently of machine-checking.

## 8. Reproduce the machine check

```sh
kompile mini_python.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini_python_spec.k   # (optional) confirm the claims parse
kprove  mini_python_spec.k                      # expected: #Top  (all claims proved)
```

> Labeled **constructed, not machine-checked**. A `#Top` from `kprove` is what
> would upgrade this from *constructed* to *machine-verified*. The `.k` files are
> faithful-but-compact (single-arg calls, single inheritance, accessor/`owise`
> sketches noted inline); closing them to a byte-clean `kompile` is the follow-up.
