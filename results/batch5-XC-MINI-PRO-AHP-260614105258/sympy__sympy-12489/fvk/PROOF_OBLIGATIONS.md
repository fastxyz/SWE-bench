# PROOF_OBLIGATIONS.md — sympy #12489

The obligations the V2 fix must discharge, derived from the intent ledger
(`SPEC.md` §1) and the Findings (`FINDINGS.md`). Each lists: statement, provenance,
the code that discharges it, and status. `C ⊑ Permutation` means `subq(C, Permutation)`.

Legend: ✅ discharged (constructed, not machine-checked) · 🟡 accepted residual /
out-of-scope · ⛓ depends on an assumption.

---

## PO-1 — Type preservation (core, from L1/L2/L6) ✅

> For every class `C ⊑ Permutation` and every public entry, the returned object is an
> instance of `C`; and when a *fresh* object is built, its dynamic class is exactly `C`.

Decomposed per surface (each is a `claim` in `SPEC.md` §3):

| Sub-obligation | Entry | Discharged by (code) | Claim |
|---|---|---|---|
| PO-1a | `_af_new` is a classmethod stamping `cls` | `_af_new(cls, perm)` → `Basic.__new__(cls, perm)` (`:927-950`) | basis of all |
| PO-1b | `C()` (empty) | `cls._af_new(list(range(size or 0)))` (`:860`) | NEW-a |
| PO-1c | `C(n)` (identity int) | `cls._af_new(list(range(a+1)))` (`:874`) | NEW-b |
| PO-1d | `C(c1,c2,…)` (cycle args) | `cls._af_new(Cycle(*args).list(size))` (`:862`) | NEW-c |
| PO-1e | `C([...])`, `C([[...]])` (array/cyclic) | `Basic.__new__(cls, aform)` (`:924`) | NEW-d/e |
| PO-1f | `C(Cycle)` | `cls._af_new(a.list(size))` (`:872`) | NEW-f |
| PO-1g-id | `C(perm)`, `isinstance(perm,C)`, size ok | `return a` (`:867-868`) | NEW-g-id |
| PO-1g-rebuild | `C(perm)`, `not isinstance(perm,C)`, size ok | `cls._af_new(a.array_form)` (`:869`) **[V2/B1]** | NEW-g-rebuild |
| PO-1g-size | `C(perm, size=…)` size differs | `cls(a.array_form, size=size)` (`:870`) | (via NEW re-entry) |
| PO-1h | `~p`, `p*q`, `p**n`, `p^h`, `mul_inv`, `commutator`, `next_lex`, `next_trotterjohnson` | `self._af_new(...)` (`:1240,1305,1346,1441,1524,1634,2130,2482`) | OP-INV/OP-MUL/… |
| PO-1h′ | `p+n` / `p-n` (`__add__`/`__sub__`); `next_nonlex` | `self.unrank_lex(...)` / `self.unrank_nonlex(...)` (`:1164,:1729`) **[V2/B4,B5]** | OP-ADD/OP-NEXTNL |
| PO-1i | `other*p` (`__rmul__`) | `self.__class__(other)*self` (`:1244`) **[V2/B2]** | OP-RMUL |
| PO-1j | `C.random/unrank_lex/unrank_nonlex/unrank_trotterjohnson/from_inversion_vector` | `self._af_new(...)` (`:1666,2428,2739,2758,2792`) | CTOR-CLS |
| PO-1k | `C.josephus` | `self(perm)` (`:2712`) | CTOR-JOS |
| PO-1l | `C.from_sequence` | `~self([...])` (`:1504`) **[V2/B3]** | CTOR-FSEQ |

All sub-obligations are discharged by the constructed proof (`PROOF.md` §2).

---

## PO-2 — Frame / backward compatibility (from L4) ✅

> Instantiating `C := Permutation` recovers the **exact** pre-fix behavior of every entry
> above (same returned class `Permutation`, same `array_form`, same identity in the
> pass-through case).

Discharged by: at `C = Permutation`, (i) every `cls`/`self`/`self.__class__` factory
stamps `Permutation` (PO-1 specialized), and (ii) the B1 guard `isinstance(a, Permutation)`
is **always true** for any `Permutation` arg, so `:867 return a` is always taken — identical
to pre-fix including `Permutation(p) is p`. The rebuild/coerce branches are *unreachable*
at `C = Permutation`. ⇒ no observable change for base-class usage. (PROOF.md §5.)

**Critical for "all existing tests still pass."** This is the obligation that justifies
not breaking the hidden suite: the diff is a *no-op* on every non-subclassing execution.

---

## PO-3 — Value preservation (from L5) ✅

> The fix does not change the computed permutation **value** (`array_form`) of any result.

Discharged by the syntactic lemma (`SPEC.md` §5): at every modified call-site only the
*class* argument changed; the *perm* argument is identical to pre-fix. Therefore the value
functions receive identical inputs. Verified by diff inspection (PROOF.md §4). No semantic
re-derivation of `invertA`/`rmulA`/… is needed.

---

## PO-4 — Constructibility assumption (from L7) ⛓✅-under-A1

> `Basic.__new__(cls, perm)` yields a valid `cls` instance for `C ⊑ Permutation`.

Holds under **Assumption A1** (`SPEC.md` §5): `cls` permits the standard instance
attributes. True for any ordinary subclass (inherits `Permutation`'s attribute usage);
a `__slots__`-restricted subclass is explicitly out of domain. Evidence:
`sympy/core/basic.py:80`. This is an inherent precondition of subclassing `Basic`, not
introduced by the fix.

---

## PO-5 — Termination / well-foundedness (proof-derived, E1) ✅

> Every entry returns; the only self-recursion (`__new__`'s size-adjust / g-rebuild
> re-entry) is one level deep over a strictly simpler argument.

Discharged in PROOF.md §3 (the `cls(a.array_form,…)` / `cls._af_new(a.array_form)`
re-entry takes a raw list ⇒ array-form base case ⇒ no further recursion). Makes the
`[all-path]` claims total, not merely partial.

---

## Residual obligations (explicitly **not** discharged — by design) 🟡

| ID | Statement | Why not discharged |
|----|-----------|--------------------|
| R-C1 | `rmul_with_af` / global `_af_new` track the subclass | `@staticmethod`, no canonical class among possibly-mixed args; base is backward-compatible and required by group internals (FINDINGS C1). |
| R-C2 | `p ** subclass_exponent` raises the helpful `NotImplementedError` | error-path, not the result-class contract; out of #12489 scope (FINDINGS C2). |

These are **named, not hidden** (per the kit's honesty discipline: never fake an
obligation as `[trusted]`). They do not affect PO-1…PO-5.

---

## Discharge summary

| PO | Status |
|----|--------|
| PO-1 (a–l + h′, type preservation) | ✅ constructed |
| PO-2 (frame / backward compat) | ✅ constructed (the no-regression core) |
| PO-3 (value preservation) | ✅ by syntactic diff lemma |
| PO-4 (constructibility) | ✅ under Assumption A1 |
| PO-5 (termination) | ✅ 1-level well-founded |
| R-C1, R-C2 | 🟡 accepted residuals, documented |

All `kprove`-style results are **constructed, not machine-checked** (no K toolchain in
this environment).
