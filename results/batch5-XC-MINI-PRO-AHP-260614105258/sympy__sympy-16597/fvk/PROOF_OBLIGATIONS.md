# PROOF_OBLIGATIONS.md — sympy-16597

Obligations the V1 fix must satisfy. Each is tagged **intent** (must hold to
solve the issue), **safety** (must hold or SymPy breaks/regresses), or **frame**
(must be preserved). Status is the result of the constructed proof
([`PROOF.md`](PROOF.md)); ✔ = discharged (constructed, not machine-checked),
⚠ = holds but with a recorded Finding, ✗ = fails.

Notation: `R₀` = pre-fix rule base; `R = R₀ ∪ {rational→finite}` = V1 rule base.
`Closure_R(S)` = deductive closure of input facts `S`; `⊥` = inconsistent.

---

### PO1 — intent — `even ⟹ finite`  ✔
For every object `x`: `x.is_even = True ⟹ x.is_finite = True`.
Formally: `finite↦True ∈ Closure_R({even↦True})`.
Trace: ledger **L1**. Claim **(DEDUCE-EVEN)**.

### PO2 — intent — `integer ⟹ finite`  ✔
`integer↦True ∈ S ⟹ finite↦True ∈ Closure_R(S)`.
Trace: ledger **L2**. Claim **(DEDUCE-INT)**.

### PO3 — intent — `rational ⟹ finite`  ✔
`rational↦True ∈ S ⟹ finite↦True ∈ Closure_R(S)`.
Trace: ledger **L3** (the sanctioned fix). Claim **(DEDUCE-RAT)**.

### PO4 — safety — global rule-base consistency  ✔
The augmented alpha closure contains **no** atom `p` and fact `f` with both
`p→(f,True)` and `p→(f,False)`. ⟹ `deduce_alpha_implications` does **not** raise
at import (`facts.py:126-131`).
Reduction: the only new edges are `rational→finite` and contrapositive
`¬finite→¬rational`. The single fact reachable in two polarities would be
`finite` or `rational`; neither acquires both (proof: PROOF §VC-A). 
Trace: ledger **L5**.

### PO5 — safety — per-object construction consistency  ✔ (⚠ for oo/-oo/zoo: see F2/F3)
For every class/singleton `C` with explicit assumption set `A_C`,
`Closure_R(A_C) ≠ ⊥` (no `InconsistentAssumptions`, `facts.py:484-496`).
Reduction (static): a conflict requires some `C` with
`(rational|integer|even|odd)=True` **and** `(finite=False ∨ infinite=True)`.
Audited: **no such class exists** — see PROOF §VC-B (checked `Rational`,
`Integer`, `KroneckerDelta`, `LeviCivita`, `Idx`; and the composite predicates
of `Add`/`Mul`). Singletons `oo`,`-oo`,`zoo` close to `ok` (claim
**CONSISTENT-OO**), with the *forced* new determinations recorded as F2/F3.
Trace: ledger **L4, L6**.

### PO5-rt — safety — runtime closure under `_eval_is_*`  ✔
For composite expressions, whenever `_eval_is_rational` returns `True`, the same
object's `_eval_is_finite` returns `True`, so the rule never creates a runtime
conflict. Reduction: `Add`/`Mul` `_eval_is_rational = _fuzzy_group(a.is_rational
…)` returns `True` only when **all** args are rational; under `R` each such arg
is finite, and `_eval_is_finite = _fuzzy_group(a.is_finite …)` then returns
`True`. (`add.py:502-509`, `mul.py:1099-1119`.)
Trace: ledger **L6**. PROOF §VC-B(rt).

### PO6 — frame — conservativity over finite numbers / generic symbols  ✔
For input `S`, `Closure_R(S) ⊇ Closure_{R₀}(S)`, and the **only** facts added are
those forced by `rational↔finite` transitively. In particular, if `S` mentions
neither `rational=True/finite` polarity that triggers the new edge, the closure
is unchanged. ⟹ `Rational(3,4).is_finite` stays `True` (L8); a generic
`Symbol('x')` is unchanged; `Float` (which pins `is_rational=None`) is unchanged.
Trace: ledger **L8**. PROOF §VC-C.

### PO7 — safety — one-directionality (no spurious `finite ⟹ rational`)  ✔
`R` adds `rational→finite` but **not** the converse. Hence
`finite↦True ∈ S` does **not** put `rational` into `Closure_R(S)`.
⟹ a merely-finite symbol keeps `is_rational = None` (and `is_integer`,
`is_even = None`). Guards against accidentally classifying every finite quantity
as rational. Claim **(NO-CONVERSE)**.
Trace: derived safety check on L3.

### PO8 — termination (recommendation, discharged)  ✔
`deduce_all_facts` terminates: the state is a finite `Fact ⇀ Bool` map that only
grows; each `tell` either adds a key, is a no-op, or halts via `inconsistent`.
Reported as a side note (FVK default is partial correctness); here it happens to
close.

---

## Consequence obligations (not bugs — *forced, must be consistent*)

### PO-C1 — `oo`/`-oo` consequences are consistent  ✔ ⚠F2
`Closure_R(positive=True, infinite=True)` determines, newly vs `R₀`:
`rational=False, integer=False, even=False, odd=False, noninteger=True,
irrational=True`, with `status=ok`. All are mathematically correct **except**
`irrational=True`, which is an artifact of the unchanged definition
`irrational == real & !rational` (L7) under extended-real `real` (L4). Recorded
as **Finding F2**; it is *consistent*, not a crash. Claim **CONSISTENT-OO**.

### PO-C2 — `zoo` consequence  ✔ ⚠F3
`Closure_R(infinite=True, complex=True, real=False)` adds `rational=False,
integer=False`; `irrational` stays `False` (needs `real=True`). `nan` unchanged
(pins `is_finite=None`). Finding **F3**.

See [`FINDINGS.md`](FINDINGS.md) for the plain-language write-ups and
[`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md) for the open design question
behind F2/F6.
