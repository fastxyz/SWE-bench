# SPEC.md — `Permutation` construction/operation **dynamic-class** contract

> Target: `repo/sympy/combinatorics/permutations.py`, the `Permutation` class and its
> internal factory `_af_new`, after the V1+V2 fix for sympy issue **#12489**
> ("`combinatorics.Permutation` can't be subclassed properly").
>
> **Mode:** intent-spec (align NL intent ↔ code ↔ formal spec; mismatches become
> Findings). **Default correctness:** partial (the contract holds *if* the call
> returns; no construction path here loops, so termination is trivial — see §6).
> **Status of `.k` artifacts below:** *constructed, not machine-checked* (no K
> toolchain in this environment, per task constraints).

This target is **not** an arithmetic loop. The property under verification is a
**dynamic-class / frame property**: *which Python class the produced object has*, and
*that the underlying permutation value and all base-class behavior are unchanged*. The
"mini-X" semantics is therefore a **mini-Python-OO** fragment (`mini-pyoo.k`) modeling
exactly the constructs the fix touches: `classmethod`/`staticmethod`/instance dispatch
(the `cls`/`self` binding), `Basic.__new__(cls, perm)` as the class-stamping primitive,
`isinstance`, and the `Permutation.__new__` case split. The "closed form" that plays the
role of a loop invariant is the **class tag** of the result.

---

## 1. Public intent ledger

| # | Source | Evidence (quoted / cited) | Semantic obligation | Status |
|---|--------|---------------------------|---------------------|--------|
| L1 | prompt (issue body) | "object creation is done in `Permutation.__new__`, but internally `_af_new` … creates the object calling `Basic.__new__(Perm, perm)` … this makes subclassing `Permutation` impossible … always instances of `Permutation` are returned" | Every public construction of a subclass `C` must yield an instance **of `C`**, not of base `Permutation`. | **Core obligation** (PO-1) |
| L2 | prompt (issue body) | "stick to Python's instance creation mechanisms, i.e. use classmethods where appropriate (`__new__` is one) and use the mandatory reference to the class (the first argument of a classmethod) … for instance creation" | The factory must create via the **calling class** (`cls`/`self`), not a hard-coded `Perm`. | Realization of PO-1 |
| L3 | hint (public) | "`_af_new` should probably be a `classmethod` with creating command `Basic.__new__(cls, perm)`" | `_af_new` is a `@classmethod`; its body is `Basic.__new__(cls, perm)`. | Realized (PO-1a) |
| L4 | prompt | "I monkeypatched it locally and ran the tests, all succeeded" | The change must be **behavior-preserving for the base class** `Permutation` (no regression to existing tests). | **Frame obligation** (PO-2) |
| L5 | code (`_af_new` docstring) | "the list is bound to the `_array_form` attribute, so it must not be modified … `p = Perm._af_new(a)` is the only object to hold a reference to `a`" | The factory binds the passed list verbatim; its **value** must be the array form. Fix must not alter the computed `perm`. | **Value obligation** (PO-3) |
| L6 | code (`__new__` docstring, comment "g) (Permutation) = adjust size or return copy") | The 7 documented input shapes a–g (`()`, identity int, cycle args, array form, cyclic form, `Cycle`, `Permutation`). | Type preservation must hold on **every** documented shape, not just array form. | Scope of PO-1 |
| L7 | code (`Basic.__new__`, `sympy/core/basic.py:80`) | `obj = object.__new__(cls); obj._assumptions = cls.default_assumptions; obj._args = args` | `Basic.__new__(cls, perm)` yields a valid `cls` instance **provided** `cls` permits the standard instance attributes (`_array_form`, `_size`, …). | **Assumption** A1 (PO-4) |

No source contradicts L1–L7. The legacy hard-coded `Perm` in `_af_new` (pre-fix) is the
*bug*, not an intended behavior, per L1/L2/L3 — so it does **not** veto the
prompt-derived contract.

---

## 2. mini-PyOO semantics — `mini-pyoo.k` (the fragment the fix uses)

Covers *only* what the fixed code touches: a class lattice with one symbolic strict
subclass, the class-stamping primitive, and the three method-dispatch disciplines
(classmethod / instance / staticmethod). Objects are values `obj(C, A)` carrying a
**dynamic class** `C` and an **array form** `A` (a `List` of `Int`).

```k
module MINI-PYOO-SYNTAX
  imports INT-SYNTAX
  imports LIST
  imports ID-SYNTAX

  syntax Class ::= Id                              // class names: Permutation, Sub, ...
  syntax Obj   ::= "obj" "(" Class "," List ")"    // a Permutation/​subclass instance
  syntax Val   ::= Obj | Int | List | Class | Bool

  // expression forms that appear in the fixed source (and nothing else)
  syntax Exp ::= Val
       | "Basic_new" "(" Exp "," Exp ")"      [strict]   // Basic.__new__(cls, perm)
       | Exp "._af_new" "(" Exp ")"           [strict]   // the @classmethod factory
       | "newP"  "(" Exp "," Exp ")"          [strict]   // Permutation.__new__(cls, arg)
       | "inv"   "(" Exp ")"                  [strict]   // ~p   (__invert__)
       | Exp "*" Exp                          [strict]   // p * q  (__mul__)
       | "rmul" "(" Exp "," Exp ")"           [strict(2)]// other * self  (__rmul__)
       | "cctor" "(" Exp "," Exp ")"          [strict]   // C.random/unrank_*/from_inversion_vector
       | "fromseq" "(" Exp "," Exp ")"        [strict]   // C.from_sequence(i)
       | "josephus" "(" Exp "," Exp ")"       [strict]   // C.josephus(...)
       | "classOf" "(" Exp ")"               [function] // dynamic class of a value
       | "isinst" "(" Exp "," Exp ")"        [function] // isinstance(v, C)
       | "subq"  "(" Class "," Class ")"     [function] // C <=: D  (subclass-or-equal)
  syntax KResult ::= Val
endmodule

module MINI-PYOO
  imports MINI-PYOO-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  // --- class lattice (one symbolic strict subclass is enough for the proof) ---
  // Permutation <=: Permutation ;  Sub <=: Permutation ;  Sub <=: Sub
  rule subq(C, C)          => true
  rule subq(Sub, Permutation) => true
  rule subq(Permutation, Sub)  => false
  rule classOf(obj(C, _))  => C
  // isinstance(obj(D,_), C)  ==  D <=: C
  rule isinst(obj(D, _), C) => subq(D, C)

  // --- the ONE class-stamping primitive: Basic.__new__(cls, perm) ------------
  // (faithful to sympy/core/basic.py:80  object.__new__(cls); obj._args = (perm,))
  rule Basic_new(C:Class, P:List) => obj(C, P)

  // --- _af_new is a @classmethod: cls is the receiver's class --------------
  rule (C:Class)  ._af_new (P:List) => Basic_new(C, P)             // C._af_new / cls._af_new
  rule obj(C, _)  ._af_new (P:List) => Basic_new(C, P)             // self._af_new  (cls := classOf(self))

  // --- instance op: __invert__ uses self._af_new --------------------------
  rule inv(obj(C, A)) => obj(C, A) ._af_new (invertA(A))

  // --- __mul__: result tracks the LEFT operand's class (self._af_new) ------
  rule obj(C, A) * obj(_, B) => obj(C, A) ._af_new (rmulA(A, B))

  // --- __rmul__ (V2):  self.__class__(other) * self  -----------------------
  //   other (non-Permutation) coerced to self's class, then multiplied
  rule rmul(X:Int, obj(C, A)) => newP(C, X) * obj(C, A)

  // --- classmethod constructors:  self (= the class) is the stamp ----------
  rule cctor(C:Class, N:Int)        => C ._af_new (mkrange(N))      // random/unrank_*/from_inversion_vector
  rule josephus(C:Class, N:Int)     => newP(C, mkrange(N))          // V2: self(perm)
  rule fromseq(C:Class, I:List)     => inv(newP(C, I))              // V2: ~self([...])

  // --- Permutation.__new__(cls, arg) dispatch (the 7 shapes a..g) ----------
  //   modeled on one representative per branch; size kwarg elided except in (g)
  rule newP(C:Class, .List)          => C ._af_new (.List)                    [owise-a]  // a ()
  rule newP(C:Class, N:Int)          => C ._af_new (mkrange(N +Int 1))                   // b identity int
  rule newP(C:Class, A:List)         => C ._af_new (normA(A))
       requires notBool isPerm(A) andBool notBool isCyc(A)                               // d/e array & cyclic form
  // (g) argument already a Permutation, sizes equal:
  rule newP(C:Class, obj(C, A))      => obj(C, A)                                         // g-identity (isinstance(a,cls))
  rule newP(C:Class, obj(D, A))      => C ._af_new (A)
       requires notBool subq(D, C)                                                       // g-rebuild  [V2 Issue-A fix]
endmodule
```

> Helper symbols `invertA`, `rmulA`, `mkrange`, `normA`, `isPerm`, `isCyc` are the
> permutation-value functions (array inversion, composition, `range`, validation/​copy);
> they are **opaque** to the class proof (PO-3 asserts the fix leaves them untouched —
> see §5). The fragment deliberately omits `raise`/exceptions, printing, and arithmetic
> internals: per `formalize.md` §5, input-validation guards are no-ops on the verified
> domain and the value functions are not what #12489 changes.

---

## 3. Function/operation contracts — reachability claims (`mini-pyoo-spec.k`)

Uppercase `C`, `D` are class variables; `A`, `B` array-form lists; `N` an `Int`.

```k
// SPEC-PROVENANCE (all claims):
// - from_prompt(L1): public construction/operation on class C must produce a C instance
// - from_prompt(L2)+hint(L3): realized by routing every factory through cls/self
// - from_code(L6): one claim per documented input shape a..g and per op/ctor
// - frame(L4): instantiate C:=Permutation to recover identical legacy behavior (PO-2)

claim newP(C, .List)        => obj(C, ?A:List)                       [all-path]  // (NEW-a)
claim newP(C, N:Int)        => obj(C, ?A:List) requires N >=Int 0    [all-path]  // (NEW-b)
claim newP(C, A:List)       => obj(C, ?A':List)
      requires notBool isPerm(A) andBool notBool isCyc(A)            [all-path]  // (NEW-d/e)
claim newP(C, obj(C, A))    => obj(C, A)                             [all-path]  // (NEW-g-id)
claim newP(C, obj(D, A))    => obj(C, A) requires notBool subq(D,C)  [all-path]  // (NEW-g-rebuild)

claim inv(obj(C, A))        => obj(C, invertA(A))                    [all-path]  // (OP-INV)
claim obj(C,A) * obj(D,B)   => obj(C, rmulA(A,B))                    [all-path]  // (OP-MUL)
claim rmul(X:Int, obj(C,A)) => obj(C, ?R:List)                      [all-path]  // (OP-RMUL)
claim iunrank(obj(C,A), N:Int) => obj(C, ?R:List)                   [all-path]  // (OP-ADD/OP-NEXTNL)
claim cctor(C, N:Int)       => obj(C, ?A:List)                      [all-path]  // (CTOR-CLS)
claim josephus(C, N:Int)    => obj(C, ?A:List)                      [all-path]  // (CTOR-JOS)
claim fromseq(C, I:List)    => obj(C, ?A:List)                      [all-path]  // (CTOR-FSEQ)
```

**Master property (entailed by the per-shape claims):**
> *For every class `C` with `subq(C, Permutation)`, and every public entry `e(C, …)`
> in {`newP`, `inv`, `*`, `rmul`, `cctor`, `josephus`, `fromseq`}, the produced value
> `v` satisfies `classOf(v) == C` whenever a fresh object is built, and
> `isinst(v, C) == true` always (the `g-id` pass-through returns the argument, which is
> already an instance of `C`).*

**Frame instantiation (PO-2).** Set `C := Permutation`. Then every RHS is
`obj(Permutation, A)` with `A` the *same* array-form term the pre-fix code produced
(PO-3), i.e. observationally identical to commit `aa9780761`. No base-class behavior
changes.

---

## 4. Human-readable spec note

- **What is specified.** The *class* of objects returned by `Permutation`'s public
  construction API and operations.
  - **Constructors** `C(...)` for all 7 input shapes (`C()`, `C(n)`, `C(c1,c2,…)`,
    `C([...])`, `C([[...]])`, `C(Cycle)`, `C(Permutation)`): result is an instance of `C`.
  - **Class-method constructors** `C.random`, `C.unrank_lex`, `C.unrank_nonlex`,
    `C.unrank_trotterjohnson`, `C.from_inversion_vector`, `C.josephus`,
    `C.from_sequence`: result is an instance of `C`.
  - **Operations** on a `C`-instance `p` (`p*q`, `q*p`, `~p`, `p**n`, `p^h`, `p+n`, `p-n`,
    `p.mul_inv`, `p.commutator`, `p.next_lex`, `p.next_nonlex`, `p.next_trotterjohnson`):
    result is an instance of `C`. (`p+n`/`p-n`/`next_nonlex` route through the
    `self.unrank_*` classmethods; the rest through `self._af_new`.)
- **Precondition / domain.** `C` is `Permutation` or a subclass that does not restrict
  instance-attribute assignment (Assumption A1, §5). Inputs are otherwise the existing
  valid domain of `Permutation` (validation/`ValueError` behavior is unchanged and out
  of scope).
- **Postcondition.** `classOf(result) == C` for every freshly built object;
  `isinstance(result, C)` always. The **array form / value** of the result is **byte-for-
  byte** what the pre-fix code computed (only the class tag changed from a hard-coded
  `Permutation` to the dynamic `C`).
- **Side condition (PO-2 frame).** At `C == Permutation` the entire observable behavior
  equals the pre-fix behavior — this is what makes the change non-breaking.
- **Two residuals, deliberately out of the verified domain** (see FINDINGS C, D):
  the `rmul_with_af` `@staticmethod` and the module-global alias `_af_new = Perm._af_new`
  intentionally produce base `Permutation` (no canonical calling class); and the
  `__pow__` exponent guard `type(n) == Perm` recognizes only the exact base type.

---

## 5. Assumptions & value-preservation lemma

- **A1 (PO-4).** `Basic.__new__(cls, perm)` returns a well-formed `cls` instance for any
  `cls` with `subq(cls, Permutation)` that permits the standard instance attributes
  (`_array_form`, `_size`, `_mhash`, `_assumptions`). Base `Permutation` already requires
  this (it sets those attributes), so any ordinary subclass inherits it; a subclass that
  declares `__slots__` excluding them is *out of domain*. (Evidence: `sympy/core/basic.py:80`.)
- **PO-3 value-preservation lemma.** The fix replaces, at each factory call site, only the
  **class argument** (`Perm`/`Permutation` → `cls`/`self`/`self.__class__`); the **`perm`
  argument expression is unchanged** at every site. Therefore `invertA`, `rmulA`,
  `mkrange`, `normA`, … receive identical inputs and the array form is invariant under the
  fix. (This is a syntactic diff fact, confirmed in PROOF.md §4.)

---

## 6. Termination

Every construction path is **straight-line** except `newP`'s `g-rebuild`/size-adjust
branch, which re-enters `newP` **once** with a plain `List` argument (`a.array_form`) —
which lands in the `(NEW-d/e)` array-form base case and does **not** recurse further.
So the `__new__` self-call is **one level deep and well-founded** (argument strictly
decreases from "a Permutation object" to "a raw list", which has no further re-entry).
Termination is therefore immediate; partial vs total correctness coincide here.
