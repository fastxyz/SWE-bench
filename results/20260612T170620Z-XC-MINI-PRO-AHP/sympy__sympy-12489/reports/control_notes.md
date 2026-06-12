# Control notes — sympy__sympy-12489 (review + V2)

This documents the review of the V1 fix and the single change made in V2, tracing each
decision to the numbered findings in `review/FINDINGS.md`.

## Summary of the review outcome
V1's approach is correct and—crucially—**provably inert for the base class** because the
codebase contains no `Permutation` subclasses (F5). The review confirmed the core change
(F1), the instance-creation protocol (F2), the module-level alias (F3), and pickling
(F4) are all sound. The review surfaced **one** genuine defect: a factory classmethod V1
forgot to convert. That is the only code change in V2.

## Change made in V2

### 1. `from_sequence` now honors the calling class — traces to **F6**
- **Before (V1):** `return ~Permutation([i[1] for i in ic])` — hard-coded base class.
- **After (V2):** `return ~self([i[1] for i in ic])`.
- **Why:** `from_sequence` is a `@classmethod` factory, exactly like `random`,
  `unrank_lex`, `unrank_nonlex`, `unrank_trotterjohnson`, `from_inversion_vector`, and
  `josephus`, all of which V1 already routed through the calling class. Leaving
  `from_sequence` hard-coded meant `Subclass.from_sequence(seq)` returned a base
  `Permutation`, directly contradicting the issue ("always instances of `Permutation`
  are returned"). `self` here is the class, so `self([...])` constructs the right type
  and `~` preserves it through the (now classmethod-based) `__invert__`.
- **Safety:** for the base class `self is Permutation`, so `self([...]) ==
  Permutation([...])`; behavior and the doctest output `(4)(0 1 3)` are unchanged (F5,
  F13). I used `self([...])` (full construction + validation) rather than
  `self._af_new([...])` deliberately, to keep the exact validation behavior of the
  original `Permutation([...])`.

No other code was changed.

## V1 changes confirmed and kept (no edit)

- **`_af_new` → classmethod; `__new__` paths use `cls`** — kept per **F1** (matches the
  issue/hint; `Basic.__new__(cls, …)` is generic and constructs any subclass).
- **Operators/derivations use `self._af_new`** (`__mul__`, `mul_inv`, `__pow__`,
  conjugation `^`, `__invert__`, `next_lex`, `next_trotterjohnson`, `commutator`) and
  **rank arithmetic uses `self.unrank_*`** (`__add__`, hence `__sub__`; `next_nonlex`) —
  kept per **F5**: each is identical to V0 for the base class and necessary for subclass
  type-preservation, which is the substance of "always instances of `Permutation` are
  returned." The maintainer's classmethod hint only takes effect if the call sites use
  `cls`/`self._af_new`, so these are the necessary complement, not scope creep.
- **Factory classmethods use the calling class** (`random`, `unrank_lex`,
  `unrank_nonlex`, `unrank_trotterjohnson`, `from_inversion_vector`, and `josephus` via
  `self(perm)`) — kept per **F5/F6** (consistent with the now-fixed `from_sequence`).
- **Module-level `_af_new = Perm._af_new`** — kept per **F3** (external modules rely on a
  base-`Permutation` factory; equivalent after the classmethod conversion).

## V1 non-changes confirmed as correct (deliberately left)

- **`rmul` / `rmul_with_af` (`@staticmethod`)** — left per **F7**: no class context;
  `rmul` already preserves type via `__mul__`, and `rmul_with_af` is an internal helper.
- **`__rmul__`: `Perm(other)*self`** — left per **F8**: coerces a non-Permutation left
  operand; coercing to base is the correct semantics and avoids feeding a subclass
  constructor invalid input.
- **`__pow__`: `if type(n) == Perm`** — left per **F9**: an exponent-type guard, not an
  object-creation path; pre-existing, out of the issue's scope, and base-class behavior
  is unaffected. Flagged as a minor, separable robustness item rather than fixed here, to
  keep the change targeted at object creation.
- **Identity short-circuit `return a` in `__new__`** — left per **F10**: preserves the
  original identity optimization; converting would risk equality/identity/performance
  assumptions. Construction from raw data and the resize path already honor `cls`.
- **Intermediate constructions** in `__call__` (line 1574) and the `Cycle`-class
  conversions (395/417/441) and permutation application `self(i)` (1358) — left per
  **F12** (results already carry the correct type, or they are unrelated to `Permutation`
  subclassing).
- **Classmethod first-parameter named `self`** — left per **F11** (pre-existing
  convention; functionally correct).

## Why no broader edits / no revert
- The review found no base-class regression in any V1 change (F2–F5), so reverting the
  breadth would only re-break subclass type-preservation that the issue asks for.
- The two documented limitations (F9 exact-type `__pow__` guard, F10 identity
  short-circuit) are outside "object creation" and/or carry behavioral-compatibility
  risk if changed; both are recorded for a potential follow-up rather than altered here,
  consistent with keeping the fix minimal and targeted.
- No execution environment is available; all reasoning above is by inspection of the
  instance-creation protocol, the metaclasses, `Basic`, and the call sites (F1–F13). No
  test files were modified.
