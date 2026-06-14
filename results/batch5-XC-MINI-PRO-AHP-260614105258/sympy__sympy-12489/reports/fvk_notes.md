# FVK audit notes — sympy__sympy-12489

This documents the Formal Verification Kit pass over the V1 fix: the spec I wrote, the
gaps the spec surfaced, and the justification for **every** V2 decision — each change and
each decision to leave V1 alone — traced to `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`.

## What the spec is

#12489 is not an arithmetic bug; it is a **dynamic-class / frame property**. So I wrote
the spec (`fvk/SPEC.md`) as a *type-preservation contract* with a *backward-compatibility
frame*, over a mini-Python-OO K fragment (`fvk/mini-pyoo.k`) that models exactly what the
fix touches — `classmethod`/`self`/`cls` dispatch and `Basic.__new__(cls, perm)` as the
class-stamping primitive. The obligations are:

- **PO-1** — every public construction/operation on a class `C ⊑ Permutation` returns an
  instance of `C` (fresh objects have `type == C` exactly). Decomposed a–l per surface.
- **PO-2** — at `C = Permutation` the behavior is byte-for-byte the pre-fix behavior
  (no regression; this is what protects the hidden test suite).
- **PO-3** — the permutation *value* (`array_form`) is unchanged by the fix.
- **PO-4** — `Basic.__new__(cls, perm)` constructs a valid `cls` (under Assumption A1).
- **PO-5** — termination (the lone `__new__` self-recursion is 1-level well-founded).

Writing this spec is what flushed out the V1 gaps: V1 had swept the `_af_new` call-sites,
but the type-preservation contract has **surfaces that never call `_af_new`** (an
object-returning pass-through, a coercion, and one classmethod using a literal
constructor). Enumerating PO-1 a–l forced each surface to be checked individually.

## Code changes in V2 (five), each traced

All five are 🔴 correctness gaps against **PO-1**, and all five are **provably
zero-regression** under **PO-2** (`fvk/PROOF.md` §5): for `cls == Permutation` each new
branch is either unreachable or definitionally identical to the old code. They share one
root cause — surfaces that produce an object **without going through `_af_new`** (an
object-returning pass-through, a coercion, a literal-base constructor, and two
`Perm.unrank_*` classmethod calls), which is why V1's `_af_new`-centric sweep missed them
and the PO-1 a–l enumeration caught them.

1. **`__new__` shape-g pass-through** — `repo/.../permutations.py:865-870`.
   `return a` → guarded by `if isinstance(a, cls): return a` else
   `return cls._af_new(a.array_form)`.
   - Traces to **Finding B1** / **PO-1g-rebuild** (claim `NEW-g-rebuild`). V1 returned the
     base `Permutation` argument unchanged for `Sub(Permutation([...]))`.
   - Zero-regression: for `cls=Permutation`, `isinstance(a, Permutation)` is always true,
     so the identity branch always fires — `Permutation(p) is p` preserved (PROOF.md §5,
     step 2). The rebuild uses `array_form` (a copy — Finding D2), honoring `_af_new`'s
     "list held only by the new object" contract (L5).
   - Guard correctness: `isinstance(a, cls)` is exactly the precondition under which
     returning `a` already satisfies the postcondition `isinstance(result, C)` — Finding D3.

2. **`__rmul__`** — `:1244`. `return Perm(other)*self` → `return self.__class__(other)*self`.
   - Traces to **Finding B2** / **PO-1i** (claim `OP-RMUL`). `other * Sub(...)` returned
     base `Permutation`; now the only Permutation operand (`self`) sets the result class.
   - Zero-regression: `self.__class__ is Permutation` for base self (PROOF.md §2 OP-RMUL).

3. **`from_sequence`** — `:1504`. `return ~Permutation([...])` → `return ~self([...])`.
   - Traces to **Finding B3** / **PO-1l** (claim `CTOR-FSEQ`). This was the **one
     classmethod constructor V1 missed** (it builds with a literal `Permutation([...])`,
     not via `_af_new`, so it was outside the V1 sweep). `self` is the class, so
     `~self([...])` carries `C` through the inner construct + invert.
   - Zero-regression: `self is Permutation` for the base call (PROOF.md §2 CTOR-FSEQ).

4. **`__add__` (and `__sub__` by delegation)** — `:1164`.
   `rv = Perm.unrank_lex(self.size, rank)` → `rv = self.unrank_lex(self.size, rank)`.
   - Traces to **Finding B4** / **PO-1h′** (claim `OP-ADD`). `Sub(...) + 1` returned base
     `Permutation`; instance access to the `unrank_lex` classmethod now binds
     `cls = type(self)`.
   - Zero-regression: `self.unrank_lex is Permutation.unrank_lex` for base self (PROOF.md §2
     OP-ADD).

5. **`next_nonlex`** — `:1729`.
   `return Perm.unrank_nonlex(self.size, r + 1)` → `return self.unrank_nonlex(self.size, r + 1)`.
   - Traces to **Finding B5** / **PO-1h′** (claim `OP-NEXTNL`). Analogous to `next_lex`/
     `next_trotterjohnson` (which V1 fixed via `self._af_new`); these two were the odd ones
     out because they route through `Perm.unrank_*`.
   - Zero-regression as B4.

## V1 decisions confirmed unchanged (with proof)

The FVK pass *confirmed* the rest of V1 against the spec — these stand because the proof
discharges their obligations, not by assertion:

- **`_af_new` → `@classmethod` with `Basic.__new__(cls, perm)`** — discharges **PO-1a**,
  the basis of every other claim (PROOF.md §2). Matches hint L3 exactly.
- **`__new__` early returns** `cls._af_new(...)` and **terminal** `Basic.__new__(cls, aform)**
  — **PO-1b/c/e/f**. (The terminal array-form path was already `cls`-correct even pre-fix —
  **Finding D1** — which is why a naive array-form smoke test passed while subclassing was
  still broken.)
- **Instance operations** `self._af_new(...)` for `*`,`~`,`**`,`^`,`mul_inv`,`commutator`,
  `next_lex`,`next_trotterjohnson` — **PO-1h** (claims OP-INV/OP-MUL/…).
- **Classmethod constructors** `random`,`unrank_lex`,`unrank_nonlex`,
  `unrank_trotterjohnson`,`from_inversion_vector` via `self._af_new(...)`, and **`josephus`**
  via `self(perm)` — **PO-1j/k** (CTOR-CLS/CTOR-JOS).
- **Module-global `_af_new = Perm._af_new` retained** — required for **PO-2** (base-class
  factory for class-agnostic internal code and external importers; PROOF.md §5).

## Decisions to NOT change (residuals), each traced

Both are named explicitly rather than hidden (the kit's honesty discipline: never fake an
obligation as discharged):

- **`rmul_with_af` (`@staticmethod`) + global `_af_new` stay base `Permutation`** —
  **Finding C1** / residual **R-C1**. A staticmethod has no canonical class, its args may be
  different subclasses, and base is backward-compatible and is what the group-theory
  internals consume. The only well-defined upgrade (`args[-1]._af_new(...)`, matching
  `rmul`'s fold) is recorded in `fvk/ITERATION_GUIDANCE.md` §4, **not applied**.
- **`__pow__` exponent guard `type(n) == Perm` left as-is** — **Finding C2** / residual
  **R-C2**. Real but out of the *result-class* contract (it is error-path behavior for a
  Permutation *exponent*). The zero-regression fix (`isinstance(n, Perm)`) is recommended in
  `ITERATION_GUIDANCE.md` §5 but withheld to keep the #12489 change minimal/targeted.

I also verified several non-sites the spec could have flagged and correctly did not:
`__call__`/`__rxor__` return ints/lists (not constructed objects); line `:1574`’s
`self*Permutation(...)` gets its class from `self.__mul__` (the inner operand’s class is
irrelevant); and the `Permutation(self)` calls inside the **`Cycle`** class (`:395/:417/
:462`) are out of scope (subclassing `Permutation` does not involve `Cycle` internals).

## Residual risk (from PROOF.md §6)

Constructed, not machine-checked (no K toolchain here). Trusted base: adequacy of the
mini-PyOO fragment as a model of CPython dispatch (MVP stopgap; full Python-in-K is the
roadmap), Assumption A1 (subclass permits the standard instance attributes — a
`__slots__`-restricted subclass is out of domain), and the opaque value functions (their
inputs are unchanged by the fix — **PO-3**, a syntactic diff lemma, PROOF.md §4). The
`kompile`/`kprove` commands to upgrade "constructed" → "machine-verified" are in PROOF.md
§8 against `fvk/mini-pyoo.k` / `fvk/mini-pyoo-spec.k`.

## Net

The audit kept the entire V1 fix and **added five targeted, zero-regression edits**
(B1–B5) that close the type-preservation sub-obligations PO-1g-rebuild, PO-1i, PO-1l, and
PO-1h′. With those, PO-1 (a–l + h′), PO-2, PO-3, PO-4 (under A1), and PO-5 are all
discharged (constructed). Recommended follow-up: add the subclass unit tests of PROOF.md §7
/ ITERATION_GUIDANCE.md (assert `type`/`isinstance`, never equality — Finding E3).
