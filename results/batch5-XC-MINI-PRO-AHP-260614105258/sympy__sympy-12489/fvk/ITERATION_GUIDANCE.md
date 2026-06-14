# ITERATION_GUIDANCE.md — sympy #12489

Feedback package for the next code/spec/intent iteration. Each item: evidence →
classification → the question the intent layer should ask → recommended change → tests.
Items applied in V2 are marked **[DONE V2]**; items intentionally deferred are **[OPEN]**.

---

## 1. [DONE V2] Close the `__new__` Permutation-argument pass-through (B1 / PO-1g-rebuild)

- **Evidence:** claim **NEW-g-rebuild**; `Sub(Permutation([1,0,2]))` returned base
  `Permutation` in V1 (`:867 return a`).
- **Classification:** code bug (missing case in the type-preservation contract).
- **Intent question (resolved):** *“When you pass an existing permutation of a different
  class into `C(...)`, do you want a `C`?”* → Yes (L1). The pass-through is an optimization,
  not a semantic promise.
- **Change applied:** guard `return a` with `isinstance(a, cls)`; else
  `return cls._af_new(a.array_form)`.
- **Tests:** add `type(Sub(Permutation([1,0,2]))) is Sub`; keep `Permutation(p) is p`.

## 2. [DONE V2] Make `__rmul__` track the subclass (B2 / PO-1i)

- **Evidence:** claim **OP-RMUL**; `[0,2,1]*Sub(...)` returned base `Permutation`.
- **Classification:** code bug.
- **Change applied:** `Perm(other)*self` → `self.__class__(other)*self`.
- **Tests:** `type([0,2,1] * Sub([1,0,2])) is Sub`.

## 3. [DONE V2] Convert the missed classmethod constructor `from_sequence` (B3 / PO-1l)

- **Evidence:** claim **CTOR-FSEQ**; `Sub.from_sequence('SymPy')` returned base.
- **Classification:** code bug (incomplete V1 sweep — the only classmethod constructor
  still using a literal `Permutation([...])`).
- **Change applied:** `~Permutation([...])` → `~self([...])`.
- **Tests:** `type(Sub.from_sequence('SymPy')) is Sub`.

## 3b. [DONE V2] Route `__add__`/`__sub__` and `next_nonlex` through the instance (B4/B5 / PO-1h′)

- **Evidence:** claims **OP-ADD**, **OP-NEXTNL**; `Sub(...)+1` and `Sub(...).next_nonlex()`
  returned base `Permutation` in V1 because they constructed via `Perm.unrank_lex` /
  `Perm.unrank_nonlex` (the literal base class), not `_af_new`.
- **Classification:** code bug (operation type-preservation; the two ops V1's `_af_new`
  sweep could not catch because they go through `unrank_*`).
- **Change applied:** `Perm.unrank_lex(...)` → `self.unrank_lex(...)` (`:1164`);
  `Perm.unrank_nonlex(...)` → `self.unrank_nonlex(...)` (`:1729`). Instance access to the
  classmethod binds `cls = type(self)`.
- **Tests:** `type(Sub([2,1,3,0]) + 1) is Sub`; `type(Sub([2,1,3,0]) - 1) is Sub`;
  `type(Sub([2,0,3,1]).next_nonlex()) is Sub`.

---

## 4. [OPEN] `rmul_with_af` / module-global `_af_new` produce base `Permutation` (R-C1)

- **Evidence:** Finding C1; `@staticmethod`, no `self`/`cls`; args may be mixed subclasses.
- **Classification:** proof capability / design ambiguity — **not** a #12489 bug.
- **Intent question for the next pass:** *“`rmul_with_af(a, b, …)` takes several
  permutations possibly of different subclasses — which subclass should the product be:
  the first operand’s, the last’s, or always base `Permutation`?”* `rmul`’s left-fold makes
  the **last** operand’s class the natural answer.
- **Recommended change (only if intent says ‘track a subclass’):**
  `args[-1]._af_new(_af_rmuln(*a))`. Deliberately **not** applied — base is
  backward-compatible and is what the group-theory internals (`perm_groups.py`,
  `tensor_can.py`) consume.
- **Tests:** keep base-class `rmul_with_af` tests; add a subclass test only after the
  intent question is answered.

## 5. [OPEN] `__pow__` exponent guard `type(n) == Perm` (R-C2)

- **Evidence:** Finding C2; `p ** Sub([0,2,1])` skips the helpful `NotImplementedError`.
- **Classification:** needed code guard on an **error path** — outside PO-1 (result class).
- **Intent question:** *“Should `p ** q` for any Permutation-subclass exponent `q` raise the
  ‘did you mean `p^q`?’ error (vs. only the exact base type)?”* Almost certainly yes.
- **Recommended change:** `type(n) == Perm` → `isinstance(n, Perm)` (zero-regression). Held
  back to keep the #12489 change minimal/targeted; safe to land in a follow-up.
- **Tests:** `raises(NotImplementedError, lambda: p ** Sub([0,2,1]))`.

---

## 6. [OPEN] Roadmap: replace the mini-PyOO fragment with real Python-in-K

- **Evidence:** PROOF.md §6 trusted base (i).
- **Classification:** proof capability gap (MVP mini-X stopgap).
- **Recommendation:** when full Python-in-K semantics (descriptor protocol,
  `classmethod`/`staticmethod`, `__new__`/metaclass `__call__`) are available, re-run
  `/verify` against the *literal* source instead of the abstracted `newP`/`cctor` terms,
  removing adequacy assumption (i). Until then the constructed proof stands as the evidence
  package.

---

## 7. Net verdict for V2

The audit upgraded V1 → V2 by discharging the previously-open type-preservation
sub-obligations **PO-1g-rebuild (B1)**, **PO-1i (B2)**, **PO-1l (B3)**, and **PO-1h′
(B4/B5: `__add__`/`__sub__`/`next_nonlex`)**. With those applied,
PO-1 (all a–l + h′), PO-2 (frame/backward-compat), PO-3 (value), PO-4 (under A1), and PO-5
(termination) are all discharged (constructed). The two **[OPEN]** items are named residuals
that do **not** affect the #12489 contract. Recommended next action: **add the subclass
unit tests of §1–§3 and §7 of PROOF.md** (asserting `type`/`isinstance`, never equality —
Finding E3), then machine-check via PROOF.md §8.
