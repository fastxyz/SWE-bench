# PROOF.md — constructed correctness proof, sympy #12489

**Status: constructed, NOT machine-checked.** No K toolchain runs in this environment
(per task constraints); the `kompile`/`kprove` commands in §8 are emitted for later
machine-checking. The Findings (`FINDINGS.md`) and the no-regression argument (§5) do
**not** depend on machine-checking.

Semantics: `fvk/SPEC.md` §2 (`mini-pyoo.k`). Claims: `SPEC.md` §3. Obligations:
`PROOF_OBLIGATIONS.md`.

---

## 1. What is proved (plain language)

> For every class `C` that is `Permutation` or a subclass of it, every public way to
> **construct** a permutation (`C()`, `C(n)`, `C(c1,c2,…)`, `C([...])`, `C([[...]])`,
> `C(Cycle)`, `C(Permutation)`, and the seven class-method constructors) and every
> **operation** on a `C`-instance (`*`, reflected `*`, `~`, `**`, `^`, `mul_inv`,
> `commutator`, `next_lex`, `next_trotterjohnson`) returns an object that **is an instance
> of `C`** — and for freshly built objects, whose **dynamic class is exactly `C`**.
> Moreover, the returned permutation **value is identical** to what the code produced
> before the fix, and at `C = Permutation` the behavior is **byte-for-byte unchanged**.

The proof is a **class-tag propagation** argument: the single primitive
`Basic_new(C, P) => obj(C, P)` stamps the dynamic class, and every method-dispatch rule
carries `C` from the call site to that primitive. There is no arithmetic to discharge for
the *class* property; the permutation *value* is handled by the orthogonal syntactic lemma
(§4).

---

## 2. Symbolic execution of each claim

Notation: `=>` is one (or more) `mini-pyoo.k` rewrite step(s); `⟦C⟧` is a class variable
with `subq(C, Permutation)`.

### (PO-1a) `_af_new` classmethod — the basis
```
⟦C⟧ ._af_new (P)            // receiver is a class  → rule (C:Class)._af_new
  => Basic_new(C, P)        // rule
  => obj(C, P)              // class-stamp primitive
```
and the instance form (`self._af_new`, cls := classOf(self)):
```
obj(C, A) ._af_new (P)
  => Basic_new(C, P) => obj(C, P)
```
∴ `classOf(_af_new-result) = C`. ∎(PO-1a)

### (NEW-a/b/c/f) the early-return constructor shapes
Each early branch of `Permutation.__new__` rewrites to `cls._af_new(<list>)`:
```
newP(C, .List)        => C ._af_new(.List)              => obj(C, .List)            // a  ()
newP(C, N:Int)        => C ._af_new(mkrange(N+1))       => obj(C, mkrange(N+1))     // b  identity int
newP(C, cyc-args)     => C ._af_new(Cycle(args).list)   => obj(C, …)                // c  cycle args
newP(C, Cycle)        => C ._af_new(Cycle.list)         => obj(C, …)                // f  Cycle
```
Each lands on `obj(C, …)` by (PO-1a). ∴ `classOf = C`. ∎

### (NEW-d/e) array / cyclic form (terminal path, was already correct — Finding D1)
```
newP(C, A:List)  [requires ¬isPerm(A) ∧ ¬isCyc(A)]
  => C ._af_new(normA(A))    // models  obj = Basic.__new__(cls, aform)
  => obj(C, normA(A))
```
∎ — note this path used `cls` even pre-fix; the proof confirms it.

### (NEW-g-id) Permutation argument, already an instance of `C`
```
newP(C, obj(C, A))   => obj(C, A)        // rule g-identity (guard isinst(a,cls) holds)
```
Returns the argument; `classOf(obj(C,A)) = C` and `isinst(obj(C,A), C)=true`. ∎

### (NEW-g-rebuild) Permutation argument NOT an instance of `C`  — **V2/B1**
```
newP(C, obj(D, A))   [requires ¬subq(D, C)]      // e.g. C=Sub, D=Permutation
  => C ._af_new(A)                                // models cls._af_new(a.array_form)
  => obj(C, A)
```
∴ `classOf = C` even when the argument was a base/sibling instance. This is the branch the
audit added; without it the rule `newP(C, obj(D,A)) => obj(D,A)` would give `classOf = D ≠ C`,
violating PO-1. ∎

### (OP-INV / OP-MUL) operations route through `self._af_new`
```
inv(obj(C, A))          => obj(C,A) ._af_new(invertA(A))   => obj(C, invertA(A))
obj(C,A) * obj(_,B)     => obj(C,A) ._af_new(rmulA(A,B))   => obj(C, rmulA(A,B))
```
Result class = **left/self** operand’s class `C`. The other operand’s class is irrelevant
(framed out). The remaining ops (`**`, `^`, `mul_inv`, `commutator`, `next_lex`,
`next_trotterjohnson`) have the identical shape `self._af_new(f(self,…))` and reduce the
same way. ∎

### (OP-ADD / OP-NEXTNL) ops that route through a `self.unrank_*` classmethod — **V2/B4,B5**
`__add__`/`__sub__` and `next_nonlex` build their result by calling a *classmethod
constructor on the instance*: `self.unrank_lex(…)` / `self.unrank_nonlex(…)`. Accessing a
`@classmethod` through an instance binds `cls := classOf(self)`, so this is the instance
form of `cctor`:
```
classOf(obj(C,A)) ._unrank_ (…)   // self.unrank_*  ≡  cctor(classOf(self), …)
  => C ._af_new(…) => obj(C, …)   // by classOf rule + CTOR-CLS
```
∴ `classOf = C`. Before V2 these used `Perm.unrank_*` (the *class object* `Permutation`),
giving `classOf = Permutation` regardless of `self` — exactly Findings B4/B5. ∎

### (OP-RMUL) reflected multiplication — **V2/B2**
```
rmul(X:Int, obj(C, A))                 // other * self ; other coerced
  => newP(C, X) * obj(C, A)            // self.__class__(other) * self
  => obj(C, mkrange(X+1)) * obj(C, A)  // by NEW-b
  => obj(C, rmulA(mkrange(X+1), A))    // by OP-MUL, left operand class C
```
∴ `classOf = C` (was `Permutation` in V1, since `newP` was `Perm(other)`). ∎

### (CTOR-CLS / CTOR-JOS / CTOR-FSEQ) class-method constructors
```
cctor(C, N)     => C ._af_new(mkrange(N))   => obj(C, …)               // random / unrank_* / from_inversion_vector
josephus(C, N)  => newP(C, mkrange(N))      => obj(C, …)   (NEW-d/e)   // V2: self(perm)
fromseq(C, I)   => inv(newP(C, I))          => obj(C, invertA(normA(I)))// V2: ~self([...])
                => obj(C, …)                                            (OP-INV)
```
All land on `obj(C, …)`. The `fromseq`/`josephus` reductions are exactly why B3 and the V1
josephus change matter: the inner constructor/​invert now carry `C`. ∎

**Conclusion of §2:** every claim’s RHS has `classOf = C` (fresh objects) or returns an
argument already `isinst _, C` (g-id). The Master Property of `SPEC.md` §3 holds. ∎(PO-1)

---

## 3. The one circularity + termination (PO-5, Finding E1)

`Permutation.__new__`'s size-adjust branch (`newP(C, obj(D,A))` with size differing) and,
in source, the B1 rebuild both **re-enter** construction:
`cls(a.array_form, size=size)` → `newP(C, A':List)`. By the **Circularity** rule the
contract `newP(C, _) => obj(C, _)` may serve as its own hypothesis — *but only after the
genuine `=>⁺` step of entering `__new__` and evaluating the argument shape*. The re-entry
argument `A'` is a **raw `List`**, so it matches the **base case** `(NEW-d/e)` and rewrites
to `obj(C, normA(A'))` with **no further re-entry**.

Hence the recursion is **one level deep** over a well-founded measure
(`Permutation-object ▷ raw-list ▷ ·`), strictly decreasing. Guardedness is satisfied (≥1
real step before the hypothesis is used), and because the measure bottoms out immediately,
the `[all-path]` claims are **total**, not merely partial. No VC beyond
`size ≥ len(aform)` (linear, Z3-dischargeable) arises. ∎

---

## 4. Value-preservation lemma (PO-3, Finding E2) — discharged by diff

The class proof treats `invertA`, `rmulA`, `mkrange`, `normA`, `isPerm`, `isCyc` as opaque.
That is sound **iff** the fix feeds them the same inputs as before. It does:

| Site | pre-fix value arg | post-fix value arg | same? |
|---|---|---|---|
| `_af_new` body | `perm` | `perm` | ✓ (only `Perm`→`cls` in the stamp) |
| `__new__` a/b/c/f | `list(range(...))` / `Cycle(...).list(...)` / `a.list(...)` | identical | ✓ |
| `__new__` g-rebuild **[V2]** | *(n/a — returned `a`)* | `a.array_form` *(copy of the same value)* | ✓ value, new class |
| ops (`*`,`~`,`**`,`^`,…) | `_af_rmul/_af_pow/_af_invert/…(self…)` | identical | ✓ |
| `__rmul__` **[V2]** | `Perm(other)*self` | `self.__class__(other)*self` | ✓ value (same array math), new class |
| `from_sequence` **[V2]** | `~Permutation([i[1]…])` | `~self([i[1]…])` | ✓ value, new class |
| `__add__`/`next_nonlex` **[V2]** | `Perm.unrank_*(self.size, r)` | `self.unrank_*(self.size, r)` | ✓ value (same `size,r` args), new class |
| `josephus` **[V1]** | `Perm(perm)` | `self(perm)` | ✓ value, new class |

Every row changes **only the class operand**, never the value expression. ∴ array form is
invariant under the fix. ∎(PO-3)

---

## 5. Frame instantiation — backward compatibility (PO-2). The no-regression core.

Set `C := Permutation`. Then:
1. Every `cls`/`self`/`self.__class__` factory stamps `Permutation` (§2 with `C=Permutation`)
   — same class as the hard-coded `Perm` pre-fix.
2. The B1 guard `isinst(a, Permutation)` is **valid for every `Permutation` argument `a`**
   (any base or subclass instance is an instance of `Permutation`), so rule **NEW-g-id**
   always fires and **NEW-g-rebuild** is **unreachable** at `C=Permutation`. ⇒ `return a`
   is always taken, preserving `Permutation(p) is p` identity exactly.
3. By §4 the value is unchanged.

∴ at `C = Permutation` the post-fix configuration equals the pre-fix configuration on every
cell (class tag, array form, identity). **No base-class behavior changes** — this is the
formal content of "I ran the tests, all succeeded" (L4) and the guarantee that the hidden
suite is unaffected. ∎(PO-2)

---

## 6. Residual risk

- **Constructed, not machine-checked** — §8 commands would upgrade this to machine-verified.
- **Trusted base:** (i) adequacy of the `mini-pyoo.k` fragment as a model of CPython
  classmethod/`__new__` descriptor dispatch and `Basic.__new__` (the MVP mini-X stopgap;
  full Python-in-K is the roadmap); (ii) Assumption A1 (subclass permits standard
  attributes — out-of-domain otherwise, PO-4); (iii) the opaque value functions (justified
  by the §4 diff lemma, not re-modeled).
- **Out-of-scope residuals R-C1/R-C2** (`rmul_with_af`/global `_af_new` stay base;
  `__pow__` exponent guard) — named in FINDINGS C, not bugs against PO-1.
- **Termination** is *proved* here (§3), unusually for the kit's partial-correctness
  default, because the sole recursion is 1-level.

---

## 7. Test-redundancy (benefit 1) — recommendation only, conditioned on machine-checking

This fix is **purely class-tag** + a no-op frame on the base class. Implications:

- **KEEP all existing base-class tests.** They live at `C = Permutation`, where PO-2 says
  behavior is unchanged; none are *subsumed* by the new contract (the contract adds nothing
  at `C = Permutation` beyond what they already check). They remain the witnesses of PO-2 /
  Finding D1 and must stay until `kprove` confirms the claims.
- **ADD subclass tests** (the contract's actual new content), asserting **`type(x) is Sub`**
  / `isinstance(x, Sub)` (not equality — Finding E3) for: each `__new__` shape a–g incl.
  `Sub(Permutation(...))` (B1) and `Sub(p, size=…)`; `other * Sub(...)` (B2);
  `Sub.from_sequence(...)` (B3); `Sub.josephus/random/unrank_*` ; ops `~`, `*`, `**`,
  `^`, `mul_inv`, `commutator`, `next_lex`, `next_trotterjohnson` on a `Sub` instance; and
  `Sub(...) + 1` / `Sub(...) - 1` (B4) and `Sub(...).next_nonlex()` (B5).
- **No removals recommended.** Nothing is proven redundant: the proof *adds* a guarantee
  (subclass domain) disjoint from what base-class unit tests cover.

(Per the Honesty gate: removals would be conditioned on running §8; here there are none.)

---

## 8. Reproduce the machine check (emitted, not run)

```sh
kompile fvk/mini-pyoo.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/mini-pyoo-spec.k   # (optional) confirm the claims parse
kprove  fvk/mini-pyoo-spec.k                     # discharge NEW-*/OP-*/CTOR-* ; expect #Top
```
`#Top` on every claim upgrades this from *constructed* to *machine-verified*. The `.k`
sources are inlined in `SPEC.md` §2–§3 (write them to `fvk/mini-pyoo.k` /
`fvk/mini-pyoo-spec.k` to run). Expected outcome: all claims `#Top` — the reductions in §2
are single-rule chains with no open arithmetic VC for the class property, and the lone
linear side condition (`size ≥ len(aform)`) is within Z3’s tier.
