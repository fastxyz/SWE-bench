# FINDINGS.md — sympy-16597 (plain-language report)

Each finding is `input → observed vs expected`. Benefit-2 findings do **not**
depend on machine-checking. Tags: ✅ fixed/positive, ⚠ accepted consequence,
🔎 residual risk, 🧭 design-gap signal.

---

## ✅ F1 — the reported bug, fixed (PO1/PO2/PO3)

> **input:** `m = Symbol('m', even=True)` → **observed (pre-fix):**
> `m.is_finite is None`; **expected:** `True`. Same for
> `Symbol('i', integer=True)` and `Symbol('r', rational=True)`.

Root cause: the rule base had `even → integer → rational → real` but **no**
edge to `finite`, and `real` deliberately does not imply `finite` (it is the
*extended* reals — see F6). After adding `rational → finite`
(`assumptions.py:175`), the existing chain delivers `finite=True` to every
even/odd/integer/rational symbol. Proof: [`PROOF.md`](PROOF.md) §1–3.

## ⚠ F2 — forced new determinations on `oo` / `-oo` (PO-C1)

> **input:** `oo` (and `-oo`) → **observed (post-fix):** `is_rational=False`,
> `is_integer=False`, `is_even=False`, `is_odd=False`, `is_noninteger=True`,
> `is_irrational=True` (all were `None` pre-fix). `is_finite=False`,
> `is_infinite=True` unchanged.

These are *forced* by the new rule's contrapositive `infinite → ¬finite →
¬rational → ¬integer → ¬even ∧ ¬odd`, plus the unchanged biconditionals
`noninteger == real & !integer` and `irrational == real & !rational`. **All are
mathematically correct except `is_irrational=True`:** within this codebase
`irrational` is *defined* as `real & !rational`, and `oo` is `real` (extended
real) and now provably not rational — so the engine consistently labels it
irrational. Conventionally an infinity is *not* an irrational number. This is the
visible symptom of the design gap F6, **not** an engine bug. The deduction is
consistent (no exception): [`PROOF.md`](PROOF.md) §4.

*Why accepted (not "fixed"):* removing it cleanly is impossible without either
(a) `irrational → finite`, which makes `oo` **inconsistent** and crashes import
(`real & !rational` forces `irrational=True` via beta, while `irrational →
finite` + `oo` non-finite forces `irrational=False`), or (b) redefining
`irrational == real & finite & !rational`, which changes `irrational` for
ordinary symbols and exceeds the issue/hint scope (L3/L4). See ITERATION_GUIDANCE.

## ⚠ F3 — forced new determinations on `zoo`; `nan` unchanged

> **input:** `zoo` → **observed:** `is_rational=False`, `is_integer=False` (were
> `None`); `is_irrational` stays `False` (needs `real=True`, but `zoo.is_real`
> is `False`). **input:** `nan` → **observed:** unchanged (it pins
> `is_real/is_rational/is_finite = None` at the class level, blocking the rule).

Correct and consistent. [`PROOF.md`](PROOF.md) §4 note, [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md) PO-C2.

## ⚠ F4 — contradictory user symbols now raise (improvement)

> **input:** `Symbol('x', rational=True, finite=False)` or
> `Symbol('x', integer=True, infinite=True)` → **observed (post-fix):** raises
> `InconsistentAssumptions`; **pre-fix:** silently constructed.

This is *correct*: a rational/integer cannot be non-finite/infinite, so the
contradiction *should* be rejected. It is a behavior change (previously the two
facts were independent). No in-repo class constructs such a symbol (VC-B), so it
only affects user code that deliberately wrote a contradiction. Net positive:
the engine now catches a real inconsistency it used to ignore.

## 🔎 F5 — `oo.is_irrational=True` feeds power-rationality paths (residual)

> **input:** an *unevaluated* `Pow` with an infinite base and symbolic exponent,
> e.g. `oo**e` that stays a `Pow` → `Pow._eval_is_rational` (`power.py:1197`,
> `elif b.is_irrational: return e.is_zero`) and `_eval_is_algebraic`
> (`power.py:1218`) now take the `b.is_irrational`-True branch instead of falling
> through on `None`.

This is a rarely-exercised edge path (infinite powers usually evaluate to
`oo`/`0`/`nan` and never form such a `Pow`), and the correctness of that branch
is independent of and predates this fix. **Out of scope** for issue-16597.
Flagged so a future pass can audit infinite-power rationality directly.

## 🧭 F6 — spec-difficulty signal: `real` is the *extended* reals (design gap)

A clean, intent-faithful rule `real → finite` is **impossible to add** in this
version: `oo`/`-oo` are simultaneously `is_real=True` and `is_infinite=True`
(`numbers.py:2657-2660, 2881-2883`), so `real → finite` would make them
inconsistent. Per the FVK "if a clean spec is hard to write, that is a bug
signal" rule, this difficulty is itself the finding: the codebase conflates
**real** with **extended-real**. The targeted fix correctly *works around* it by
attaching `finite` to `rational` (which excludes the infinities) rather than to
`real`. The residual F2 (`oo.is_irrational`) is the leftover symptom; the proper
resolution is a separate `extended_real` predicate (a large, breaking change the
hint explicitly defers — L4). See [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md).

---

## Proof-derived findings from `/verify`

- **PO4/VC-A:** the new edge does **not** make the rule base inconsistent — the
  `finite` "true vs false" antecedents (`rational`/`zero` vs `infinite`) are
  mutually exclusive, so `deduce_alpha_implications` does not raise. *Classification:*
  confirms safety, no code change. 
- **PO5/VC-B + PO5-rt:** no class (and no `Add`/`Mul` composite) can be both
  rational/integer and non-finite, so `_tell` never hits a conflict at runtime.
  *Classification:* confirms safety, no code change.
- **PO7/NO-CONVERSE:** only the forward edge was added; finiteness does not
  back-imply rationality. *Classification:* confirms the fix is minimal and not
  over-strengthened.
- **Spec-difficulty (F6):** the impossibility of a clean `real → finite`
  is the one genuine smell, and it is a *pre-existing design* issue, not
  introduced by this fix. *Classification:* underspecified intent → route to an
  `extended_real` redesign (out of scope).

**Bottom line:** the audit surfaced **no correctness defect** in V1. F1 confirms
the fix; F2–F6 are forced consequences / residual design risk, all consistent.
V1 stands. (See [`../reports/fvk_notes.md`](../reports/fvk_notes.md).)
