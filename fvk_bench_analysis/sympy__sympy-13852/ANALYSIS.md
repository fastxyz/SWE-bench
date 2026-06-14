# sympy__sympy-13852 — FVK arm failure analysis

**Instance:** `sympy__sympy-13852` (SymPy, symbolic mathematics)
**Batch:** `batch5-XC-MINI-PRO-AHP-260614105258`
**Outcome:** FAIL_TO_PASS 0/1 — failing test `test_polylog_values`. Baseline, control, and fvk all fail identically; zero flips.
**VERDICT: STATED** (root cause named in the artifacts, then explicitly reasoned against) — **counts toward headroom.**

---

## 1. Root cause

The bug is a **math-correctness** defect in SymPy's polylogarithm, file
`sympy/functions/special/zeta_functions.py`, `class polylog`. The gold patch
(`logs/run_evaluation/batch5-….goldcheck/gold/sympy__sympy-13852/patch.diff`;
upstream commit `1c752d37e6`, "Implement special values of dilogarithm, most
notably at 2 and 1/2") has two parts:

**(A) Missing special-value evaluation — the graded defect.** At the base commit
`polylog.eval` (the `@classmethod`, run at *construction* time) only special-cased
`z ∈ {0, 1, -1}`. The dilogarithm `Li₂` has well-known closed forms that the code
never produced. The gold patch adds them **to `polylog.eval`**:

```python
if s == 2:
    if   z == S.Half:            return pi**2/12 - log(2)**2/2
    elif z == 2:                 return pi**2/4 - I*pi*log(2)
    elif z == -(sqrt(5) - 1)/2:  return -pi**2/15 + log((sqrt(5)-1)/2)**2/2
    elif z == -(sqrt(5) + 1)/2:  return -pi**2/10 - log((sqrt(5)+1)/2)**2
    elif z == (3 - sqrt(5))/2:   return  pi**2/15 - log((sqrt(5)-1)/2)**2
    elif z == (sqrt(5) - 1)/2:   return  pi**2/10 - log((sqrt(5)-1)/2)**2
# (gold also adds s==0 -> z/(1-z) and s==-1 -> z/(1-z)**2; imports I, sqrt)
```

The test asserts the **bare** forms — `polylog(2, 2) == pi**2/4 - I*pi*log(2)` and
`polylog(2, S.Half) == pi**2/12 - log(2)**2/2` with **no** `.expand(func=True)` —
so the value must auto-evaluate at construction (in `eval`), and **six** `z`-values
must be covered (1/2, 2, and four golden-ratio/Landen arguments), with a numerical
continuity sweep.

**(B) Spurious `exp_polar(-I*pi)` branch factor in the `s==1` expansion** — the
*other* half of the GitHub issue. `polylog._eval_expand_func` returned
`-log(1 + exp_polar(-I*pi)*z)` where the correct identity is `Li₁(z) = -log(1-z)`
exactly (same series, same branch cut; the `exp_polar` winding about the point `1`
is meaningless because `log` is unbranched there, and it breaks the derivative
identity). This is real, but **the graded test does not touch it** — gold leaves
`_eval_expand_func`'s `s==1` branch alone.

**Bug TYPE:** compound *wrong/missing math identity* — (A) missing special-value
auto-evaluation at construction time + (B) spurious branch-cut factor. **The
failure axis is (A), and within (A) the dominant cause is *placement* (`eval` vs
`_eval_expand_func`) plus *coverage* (six args vs one).**

**Public-data reachability: YES (strong).** The problem statement (the GitHub
issue) gives the exact desired output `polylog(2, Rational(1,2)) -> -log(2)**2/2 +
pi**2/12`, and the dilogarithm closed forms (Li₂(1/2), Li₂(2), the golden-ratio
values) plus Li₀/Li₋₁ are standard public math. See
`evidence/problem_statement.txt`, `evidence/failing_test_snippet.txt`.

---

## 2. What the fvk arm did (V1 vs final)

**V1 (`solutions/solution_baseline.patch`)** edited *only* `_eval_expand_func`:
`s==1` -> `-log(1 - z)` (fixed B), and a new `if s == 2 and z == S.Half: return
-log(2)**2/2 + pi**2/12` (one value, in the wrong method), trimmed `exp_polar, I`
imports, updated doctests. It does **not** touch `polylog.eval`.

**Final fvk (`solutions/solution_fvk.patch`) = CONFIRMED V1, no behavioral
change.** `diff` of the two patches differs only in the index hash and **two inert
source comments** (`evidence/V1_vs_final_patch.txt`):
```
+            # polylog(1, z) == -log(1 - z), unbranched at 1; no exp_polar
+            # dilogarithm value Li_2(1/2) = pi**2/12 - log(2)**2/2
```
`fvk_notes.md` D1–D7 are all "(No edit.)" except D7 (the comments).

**Key artifact contents.** FVK scoped the whole audit to `_eval_expand_func`,
modeled it as a clean 4-way dispatch, declared the spec "clean ⇒ positive evidence
the code is correct" (`FINDINGS.md:8-12`, `:140-145`), discharged the two analytic
identities at `[ESCALATION BOUNDARY]` (capability gap, honestly not machine-checked
— a §vi-legitimate escalation, *not* the root cause), and confirmed V1.

---

## 3. Artifact audit — VERDICT: **STATED**

The two axes of the gold fix — **placement** (value belongs in `eval`, at
construction) and **coverage** (the golden-ratio table) — are both *named* in the
artifacts and then *explicitly rejected* with constructed justifications. This is
primer tell **#8 (STATED-but-reasoned-against)**: FVK localized the answer and held
it, then argued itself out of it by treating the issue's pre-fix display as binding
intent. Per PLAN §4, STATED = the info was right there; the failure is acting on it.

**Pointed-at-the-spot test applied to the CAUSE, not a symptom string** — three
independent excerpts:

**(a) Placement — the dominant cause — named and rejected (the single most
important excerpt).** `reports/baseline_notes.md:83-88` (this reasoning is carried
into the fvk fork; control reaffirms it):
> **Where to add the `Li_2(1/2)` value — `eval` vs `_eval_expand_func`.**
> Chosen: `_eval_expand_func`. The issue demonstrates the bug with
> `.expand(func=True)` and shows `polylog(2, 1/2)` deliberately staying
> unevaluated by default (`Out[1]: polylog(2, 1/2)`). Putting the value in
> `eval` would auto-evaluate it and change the default display, which the issue
> does not ask for. **Rejected.**

Reaffirmed at `reports/control_notes.md:35-38`:
> **Keep the value in `_eval_expand_func`, not `eval`.** Justified by **F4**: the
> issue's `In [1]` shows the value must stay unevaluated by default and appear only
> under `.expand(func=True)`. Moving it to `eval` would change the default display
> and contradict the issue. No change.

This is exactly the fabricated-requirement pattern of tell #8: the issue's `In [1]`
display *predates* the fix; the gold patch makes `polylog(2, S.Half)` evaluate at
construction (and the hidden test asserts the bare form). FVK proved an invariant
("must stay unevaluated by default") that **preserves the bug**, on the authority
of a pre-fix display it read as ground-truth intent.

**(b) Coverage — the golden-ratio table — named and rejected.**
`fvk/FINDINGS.md:92-97` (F8):
> **F8 — V1 is intentionally narrow (only `Li_2(1/2)`)** … Other dilogarithm
> values (e.g. **golden-ratio arguments**) are not requested and are not added. …
> A broader special-value table is an enhancement, routed to ITERATION_GUIDANCE.md,
> **not a correctness gap.**

Reinforced at `reports/baseline_notes.md:96-98` ("A broader special-value table …
Rejected as out of scope") and `fvk/ITERATION_GUIDANCE.md` G3 ("generalize the
special-value table … NOT required … unprompted scope creep"). The golden-ratio
arguments are literally the gold patch's added cases — dismissed by name.

**(c) The gold fix *site* was read and correctly described, then used only to
argue the values belong elsewhere.** `fvk/PROOF_OBLIGATIONS.md:93-97` (PO7):
> `polylog.eval` returns `0 / zeta(s) / -dirichlet_eta(s)` … **Discharge.** `eval`
> is a `@classmethod` run at construction; for `z in {0,1,-1}` it [pre-filters] …

FVK understood `polylog.eval` is the construction-time evaluator (`SPEC.md:28`,
`:38-39`; PO7 lines 91-100) — i.e. it had the precise mechanism needed to place the
values — yet treated it only as a pre-filter and never proposed extending it.

**Supporting tells.** (c-divergence) The spec *certifies the narrowness*:
`SPEC.md` claim EXPAND-FRAME-2 requires "s == 2 with z != 1/2 must **NOT** collapse
to the special value." (e-positive certification) `FINDINGS.md:36-38` marks the
single mis-placed value "audit verdict: correct." (f-inverted) `FINDINGS.md:140-145`
turns "clean spec" into a correctness claim — clean only because mis-scoped.

**Why STATED and not MISSING-via-#9 (false certification) or #7 (scope-fenced).**
Tells #7/#9 require the cause to be *defined out of scope before any obligation* or
*enshrined as the spec with no trace of the alternative*. Here the opposite holds:
the artifacts **explicitly raise the correct fix on both axes** (eval-placement;
golden-ratio table) as considered alternatives and **reject them with named
arguments**. The information is present and localized; the defect is the rejection.
That is the definition of STATED (tell #8), the most-improvable class.

**Not a §vi formal blind spot.** This is not outside the mini-X fragment, not
termination/concurrency/I-O. It is an intent-fidelity / localization failure: FVK
formalized the implementation's narrowness as the contract and read a pre-fix
display as binding intent — identical in kind to the batch1–4 calibration failures.

---

## 4. How FVK could surface it (prose, general, no-exec)

1. **Treat issue *display output* as pre-fix evidence, not as a postcondition.** The
   single fatal step was reading `Out[1]: polylog(2, 1/2)` (an artifact of the
   *buggy* state) as a "must stay unevaluated by default" invariant. An intent-ledger
   rule: a value shown in the issue's *reproduction* block is the symptom, not the
   spec; the desired-output block (`The answer should be …`) is the spec. When the
   issue's "desired" form is a closed-form *value*, the obligation should be the bare
   `polylog(2, z) == value`, which immediately exposes the `eval`-vs-`expand`
   placement question instead of foreclosing it.

2. **Make placement a first-class proof obligation.** FVK already identified that
   `polylog.eval` is the construction-time evaluator (PO7). A "where must this hold"
   obligation — *at construction, or only under expand?* — derived from the desired
   bare equality would have forced the value into `eval`. The information was in the
   artifacts; it needed an obligation, not a footnote.

3. **Do not let "minimal/targeted fix" override an enumerated requirement.** The
   golden-ratio values were named and waved off as "scope creep." When the desired
   behavior is a *table of values* of the same kind, generalization is the fix, not
   creep; a spec keyed to the issue's stated *class* of values (dilogarithm special
   values), rather than the one literal example, would have kept them in scope.

4. **Distrust "clean spec => correct" when the spec domain was narrowed to match V1.**
   The spec was clean only because it was scoped to `_eval_expand_func` and the one
   value V1 added (tell #7 guard). Cross-checking the spec's domain against the
   issue's *full* desired output (a bare value, multiple arguments) would have shown
   the cleanliness was vacuous.
