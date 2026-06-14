# PROOF.md — constructed correctness proof for the sympy-16597 fix

**Status: constructed, not machine-checked** (FVK MVP does not invoke
`kompile`/`kprove`). The run-commands to discharge it are in §7. The Findings
(benefit 2) do not depend on machine-checking and are stated with full
confidence in [`FINDINGS.md`](FINDINGS.md).

Proof target: the claims in [`mini_assumptions-spec.k`](mini_assumptions-spec.k)
over [`mini_assumptions.k`](mini_assumptions.k). Each is a reachability rule
`φ_pre ⇒ φ_post`; we discharge by symbolic execution against the semantic rules,
the closure loop via its fixpoint circularity, and the leftover side conditions.

---

## 1. (DEDUCE-EVEN) — PO1 — `even ⟹ finite`

Goal: `⟨ tell(even,true) close | .Map | ok ⟩ ⇒ ⟨ .K | ?KB | ok ⟩`
with `?KB[finite]=true ∧ ?KB[integer]=true ∧ ?KB[rational]=true`.

Symbolic execution (each `=>` is one Axiom step, `...` = framing):

```
tell(even,true) close
=>  [tell-new, even∉KB]      activate(even,true) ~> close      <kb> even↦true </kb>
=>  [activate even]          tell(integer,true) ~> checkBeta ~> close
=>  [tell-new]               activate(integer,true) ~> …       <kb> …, integer↦true </kb>
=>  [activate integer]       tell(rational,true) ~> checkBeta ~> …
=>  [tell-new]               activate(rational,true) ~> …      <kb> …, rational↦true </kb>
=>  [activate rational]      tell(real,true) ~> tell(finite,true) ~> checkBeta ~> …
=>  [tell-new ×2]            …                                 <kb> …, real↦true, finite↦true </kb>
=>  [activate finite=true]   tell(infinite,false) ~> checkBeta ~> …   <kb> …, infinite↦false </kb>
=>  [checkBeta: noninteger? integer=true ⇒ premise(¬integer) false ⇒ no fire]
=>  [checkBeta: irrational? rational=true ⇒ premise(¬rational) false ⇒ no fire]
=>  [close ⇒ checkBeta ⇒ owise .K]                            <k> .K </k>
```

Final `<kb>` ⊇ `{even↦true, integer↦true, rational↦true, real↦true,
finite↦true, infinite↦false}`, `<status> ok ` (no conflict ever told).
Post-condition satisfied. **∎ (constructed).**

Note the essential edge fired at step "activate rational":
`tell(finite,true)` — this is precisely the V1 line `rational -> finite`. Remove
it and `finite` is never told; the closure ends with `finite ∉ KB` (i.e. `None`),
reproducing the **bug** the issue reports.

## 2. (DEDUCE-INT) — PO2 — `integer ⟹ finite`
Identical to §1 truncated to start at `activate(integer,true)`: integer → rational
→ {real, **finite**}. `?KB[finite]=true`. **∎ (constructed).**

## 3. (DEDUCE-RAT) — PO3 — `rational ⟹ finite`
The `activate(rational,true)` rule directly tells `finite,true`. One activation,
one `tell-new`. **∎ (constructed).**

## 4. (CONSISTENT-OO) — PO5 / PO-C1 — the singletons still build

Goal: `⟨ tell(positive,true) tell(infinite,true) close ⟩ ⇒ ⟨ .K | ?KB | ok ⟩`
with the six forced determinations, **and `status` never leaves `ok`** (the crux).

```
tell(positive,true) tell(infinite,true) close
=> [tell-new positive]   activate(positive,true) ~> tell(infinite,true) ~> close   kb: positive↦true
=> [activate positive]   tell(real,true) ~> checkBeta ~> tell(infinite,true) ~> close
=> [tell-new real]       … kb: …, real↦true
=> [checkBeta] irrational? real=true ∧ rational∈KB? NO (rational absent) ⇒ no fire
              noninteger? integer absent ⇒ no fire
=> [tell-new infinite]   activate(infinite,true) ~> close   kb: …, infinite↦true
=> [activate infinite]   tell(finite,false) ~> checkBeta ~> close
=> [tell-new finite=false] activate(finite,false) ~> checkBeta ~> close   kb: …, finite↦false
=> [activate finite=false] tell(rational,false) ~> checkBeta ~> checkBeta ~> close
=> [tell-new rational=false] activate(rational,false) ~> …   kb: …, rational↦false
=> [activate rational=false] tell(integer,false) ~> checkBeta ~> …
=> [tell-new integer=false]  activate(integer,false) ~> …    kb: …, integer↦false
=> [activate integer=false]  tell(even,false) ~> tell(odd,false) ~> checkBeta ~> …
=> [tell-new even,odd=false] kb: …, even↦false, odd↦false
=> [checkBeta] irrational? real=true ∧ rational=false ⇒ FIRE ⇒ tell(irrational,true)
=> [tell-new irrational]     kb: …, irrational↦true
=> [checkBeta] noninteger? real=true ∧ integer=false ⇒ FIRE ⇒ tell(noninteger,true)
=> [tell-new noninteger]     kb: …, noninteger↦true
=> [checkBeta owise] no premise newly satisfied ⇒ .K ;  close ⇒ checkBeta ⇒ .K
```

**Crucial observation for safety:** every `tell` above hit either the *new* or
*redundant* case; the *conflict* case (→ `inconsistent`) was **never** reachable,
because `finite` is told only `false` (once), `rational` only `false` (once),
etc. — no fact is told in two polarities. Hence `status = ok` throughout: the
`oo`/`-oo` singletons construct without `InconsistentAssumptions`. **PO5 ∎.**

Forced `?KB`: `finite=false, rational=false, integer=false, even=false,
odd=false, irrational=true, noninteger=true` — exactly the new determinations in
**F2**, and all consistent. (`-oo` is identical with `negative` in place of
`positive`; both reach `real=true`.)

## 5. (NO-CONVERSE) — PO7

```
tell(finite,true) close
=> [tell-new finite=true]  activate(finite,true) ~> close   kb: finite↦true
=> [activate finite=true]  tell(infinite,false) ~> checkBeta ~> close
=> [tell-new infinite=false] kb: …, infinite↦false
=> [checkBeta owise: real absent ⇒ neither beta fires] .K ; close ⇒ .K
```
Final `<kb> = {finite↦true, infinite↦false}`. `rational`,`integer`,`even` are
**absent** ⟹ `None`. There is **no** rule with `finite=true` on the left that
introduces `rational`. Post-condition (all three absent) holds. **∎.** This is the
proof that the fix is *one-directional*: finite does not back-imply rational.

## 6. Verification conditions (discharged by inspection of the rule base)

The claims above are reachability over a finite, deterministic transition system,
so the only first-order VCs are the consistency/closure side conditions:

- **VC-A (PO4) — alpha consistency.** New edges: `rational→finite`,
  `¬finite→¬rational`. Build the closure and check no fact gets both polarities
  from a common antecedent. The relevant chains:
  `rational → finite → ¬infinite`  and  `infinite → ¬finite → ¬rational →
  ¬integer → ¬even ∧ ¬odd`. The fact `finite` is implied `true` by `rational`/
  `zero` and `false` by `infinite`; these have **disjoint, mutually exclusive
  antecedents** (`rational`/`zero` vs `infinite`), and `rational ∧ infinite` is
  itself excluded by the very contrapositive `infinite→¬rational`. No antecedent
  forces `finite` both ways. Likewise `rational` is `false` from `infinite`/
  `¬finite` and never forced `true` by anything that is also `infinite`.
  ⟹ `deduce_alpha_implications` finds `Not(a) ∉ impl[a]` for all `a`: **no raise.**
  Discharged by the finite closure computation (Z3-trivial / structural).

- **VC-B (PO5) — no constructible witness of conflict.** A conflict needs a class
  with `(rational|integer|even|odd)=True ∧ (finite=False ∨ infinite=True)`. Static
  audit of every explicit assertion of those positives in the source:
  `Rational.is_rational=True`, `Integer.is_integer=True`
  (`numbers.py:1458,1920`), `KroneckerDelta`/`LeviCivita` `is_integer=True`
  (`tensor_functions.py:71,133`), `Idx.is_integer=True` (`indexed.py:578`) — **none
  also asserts `finite=False`/`infinite=True`** (all denote ordinary finite
  numbers/indices). The infinities assert no `rational/integer/even/odd` positive.
  No witness exists ⟹ no construction raises.

- **VC-B(rt) (PO5-rt) — runtime closure under eval.** `Add`/`Mul`
  `_eval_is_rational` returns `True` only when `_fuzzy_group` sees every arg
  rational; under `R` each such arg is finite, so `_eval_is_finite` (same
  `_fuzzy_group` shape) returns `True`. Therefore `is_rational=True ⟹
  is_finite=True` *holds for the composite too*, and `_tell` never sees a
  `finite` conflict. (`add.py:502-509`, `mul.py:1099-1119,1145-1155`.) Discharged
  structurally.

- **VC-C (PO6) — conservativity.** `R` ⊇ `R₀` (pure addition), so
  `Closure_R(S) ⊇ Closure_{R₀}(S)` by monotonicity of forward chaining. The extra
  facts are exactly the forward/contrapositive closure of the single new edge,
  which is *inert* unless `rational=True` or `finite=False` is present in `S`.
  Hence finite numbers (already `finite=True`, `rational` per their class) gain
  nothing new, and a generic symbol (no `rational`/`finite` known) is unchanged.
  Discharged structurally.

- **VC-T (PO8) — termination.** Measure = number of `Fact` keys still absent from
  `<kb>` (finite, ≥ 0). Every `tell-new` strictly decreases it; `redundant` and
  the `inconsistent` halt do not loop. Strictly decreasing + bounded below ⟹ the
  closure halts. Z3-trivial.

## 7. Reproduce the machine check (not run in the MVP)

```sh
kompile fvk/mini_assumptions.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/mini_assumptions-spec.k   # (optional) confirm the claims parse
kprove  fvk/mini_assumptions-spec.k                     # expected: #Top  (all 5 claims proved)
```
A `#Top` from `kprove` upgrades every result above from *constructed* to
*machine-verified*. Until then, treat §1–§6 as a careful hand proof.

## 8. What is proved (plain language)

- For **every** symbol asserted `even`, `odd`, `integer`, or `rational`,
  `is_finite` is now `True` (PO1–PO3) — the issue is fixed for all such inputs,
  not just the two in the report.
- The change **cannot** make SymPy fail to import (PO4) or make any existing
  object raise `InconsistentAssumptions` (PO5, PO5-rt, VC-B).
- It is **conservative**: finite numbers and generic symbols are unaffected
  (PO6), and it does **not** wrongly back-imply rationality from finiteness (PO7).
- The infinities' new `is_rational=False` / `is_integer=False` / `is_irrational=
  True` values are **forced and consistent** consequences (F2/F3), not bugs in the
  engine — though `is_irrational=True` for `oo` exposes a known *design* gap (F6).

## 9. Residual risk

- **Trusted base:** the adequacy of the mini-X fragment vs the real
  `FactRules`/`FactKB` (we modeled the closure + 3-valued `_tell`, not the
  Python object/metaclass plumbing); the reachability metatheory; and the
  "constructed, not machine-checked" caveat (§7).
- **F2/F6:** `oo.is_irrational == True` is consistent with the codebase's
  `irrational == real & !rational` but diverges from the *intent* that irrational
  means a finite non-rational real. Fully resolving it needs an `extended_real`
  predicate — a separate, larger change (see ITERATION_GUIDANCE).
- **Partial correctness** by default; termination additionally argued in VC-T.

## 10. Test-redundancy (benefit 1) — recommendation only, NEVER auto-delete

The project test suite is **fixed and hidden**; this is advice, conditioned on
running §7.

- **Subsumed by PO1–PO3 once machine-checked** (would be redundant *as pure
  rule-deduction points*): any unit test that only re-checks a single in-domain
  point such as `Symbol('m', even=True).is_finite is True`,
  `Symbol('i', integer=True).is_finite is True`,
  `Symbol('r', rational=True).is_finite is True`. The proof covers *all* such
  symbols. **Keep them anyway** until `kprove` returns `#Top` (Honesty gate) — and
  in this benchmark, do not modify tests at all.
- **Keep regardless** (outside the closure contract): the `oo`/`-oo`/`zoo`/`nan`
  assertions in `test_infinity`/`test_neg_infinity`/`test_zoo`/`test_nan` — these
  pin the *forced consequences* (F2/F3) and are exactly where a regression would
  show; `Number`-level `is_finite` tests (covered by `_eval_is_finite`, not the
  rule); and any integration/termination tests.
- **Net:** no deletion recommended here. CI savings are not the goal of this fix;
  correctness and consistency are.
