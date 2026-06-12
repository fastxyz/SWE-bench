# FVK audit notes — sympy__sympy-12489

This documents the FVK audit of the V1 fix and every decision that followed,
tracing each to specific entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## What FVK was applied to

The verified property is **SUBCLASS-SOUND** ([`fvk/SPEC.md`](../fvk/SPEC.md) §3):
*every construction entry point yields an instance of the class it was invoked
on.* I built a mini-Python fragment ([`fvk/mini_python.k`](../fvk/mini_python.k))
that models the one thing the fix is about — how the **class** flows through
`Basic.__new__` and through classmethod / staticmethod / instance-method dispatch
— and stated the contracts as reachability claims
([`fvk/mini_python_spec.k`](../fvk/mini_python_spec.k)). Writing those contracts is
what surfaced the findings.

## Code changes made in this pass (V1 → V2)

### Change 1 — `__new__` identity short-circuit (the substantive result)
**File:** `repo/sympy/combinatorics/permutations.py`, `Permutation.__new__`.
**Traces to:** FINDINGS **F1** (🔴), obligation **PO-NEW-ID**, PROOF §3, PD-2.

Trying to write a *universal* postcondition for the "argument is already a
Permutation" path is what exposed the bug: it could not be written as
`classOf(result) = cls`. V1 returned the input object unchanged
(`return a`), so `Sub(Permutation([1,0,2]))` returned a **base** `Permutation` —
`isinstance(result, Sub)` is False. PO-NEW-ID is therefore **false in V1** (refuted
claim in `mini_python_spec.k`, counter-model `C=Sub, D=Permutation`).

I guarded the identity reuse with the requested class and rebuilt otherwise:

```python
if size is None or size == a.size:
    if isinstance(a, cls):
        return a
    return cls(a.array_form)
return cls(a.array_form, size=size)
```

The proof (PROOF §3) now closes by case split on `isSubclass(D,C)`: the true
branch returns the input (already `⊑ C`); the false branch rebuilds via
**PO-NEW-ARRAY** used as a lemma, giving exactly `C`. Both satisfy
`isinstance(result, cls)`.

Choice of `isinstance(a, cls)` (not `type(a) == cls`) is justified in F1 and
**PO-REG**: for `cls == Permutation` the guard is always True, so `Permutation(p)`
still returns the *same object* — the relied-upon idempotency `Permutation(p) is
p` is preserved byte-for-byte, and since no in-tree subclass exists, no shipped
call site changes behavior.

### Change 2 — `__pow__` hard-coded type check
**File:** same, `Permutation.__pow__`.
**Traces to:** FINDINGS **F4** (🟡), obligation **PO-POW**.

`type(n) == Perm` is the exact hard-coded-class anti-pattern the issue is about; a
subclass exponent slipped past it into `int(n)` and raised a bare `TypeError`
instead of the intended `NotImplementedError`. Changed to `isinstance(n, Perm)`.
Zero base-class change (truth value identical for base permutations and for
non-permutation exponents); it only additionally catches subclass exponents,
which it should.

## V1 decisions the audit CONFIRMED (kept unchanged)

- **All of V1's core rewrite** — `_af_new` as a `classmethod` using `cls`;
  `cls._af_new(...)`/`cls(...)` in `__new__`; `self._af_new(...)` in the ten
  instance operations; `self.unrank_*` in `__add__`/`__sub__`/`next_nonlex`;
  `self._af_new`/`self(perm)` in the six factory classmethods — is **confirmed
  correct** by obligations **PO-AFNEW, PO-AFNEW-INST, PO-NEW-ARRAY/-INT/-CYCLE,
  PO-OP, PO-FACTORY** (all ✅ discharged, PROOF §1–4). No change needed.
- **Module-level `_af_new = Perm._af_new`** — confirmed by **PO-ALIAS** /
  FINDINGS **F5**: as a bound classmethod it still yields a base `Permutation`, so
  the 7 external modules and `tensor_can.py`'s `from … import _af_new` are
  unaffected. This is the reason the staticmethod→classmethod switch is
  non-breaking. Kept.
- **`__rmul__` (`Perm(other)*self`)** — FINDINGS **F2**, SPEC §6,
  **PO-KEEP-RMUL**: coerces a *non-Permutation* left operand; minting a subclass
  there would feed unvalidated data to a subclass constructor. The primary product
  path already preserves the subclass via PO-OP. Kept.
- **`rmul_with_af` (`@staticmethod`)** — FINDINGS **F3**, SPEC §6,
  **PO-KEEP-RMULAF**: no `cls`/`self` to dispatch on; an internal helper returning
  base is acceptable. Kept.
- **`Permutation(sub_instance)` returns the subclass instance** — FINDINGS **F6**,
  ITERATION_GUIDANCE **G4**: this is why the master postcondition is stated as
  `isinstance`, not exact type. Accepted as correct (the result *is* a
  `Permutation`); down-casting would needlessly break `Permutation(x) is x`.

## Regression argument (PO-REG)

For `cls == Permutation`, every dispatch binds `cls(Permutation)`, so every
contract yields exactly a base `Permutation` — identical to pre-fix behavior — and
the new identity guard is always-True, so `Permutation(p) is p` is preserved
(PROOF §5). The behavior delta is confined to *strict subclasses*, of which the
shipped codebase has none.

## Honesty / limits

Proofs are **constructed, not machine-checked** — no `kompile`/`kprove` was run
(the environment has no execution). The `.k` files are faithful-but-compact
(single-arg calls, single inheritance, accessor/`owise` sketches noted inline);
closing them to a clean machine check is the only residual item
(ITERATION_GUIDANCE **G5**). No obligation required inductive/heap/multiset/binder
reasoning, so nothing was marked `[ESCALATION BOUNDARY]` and nothing was faked
`[trusted]`. The Findings (F1–F6) hold independently of machine-checking. The
test-redundancy list (PROOF §7) is recommendation-only and conditioned on a future
`kprove ⇒ #Top`; no tests were touched.
