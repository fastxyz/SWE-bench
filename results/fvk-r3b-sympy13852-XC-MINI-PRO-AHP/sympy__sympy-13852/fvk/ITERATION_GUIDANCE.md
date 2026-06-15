# ITERATION_GUIDANCE.md — polylog fix (sympy__sympy-13852)

What changed this FVK pass, what to feed the next iteration, and the test-redundancy
recommendation. (MVP: proof **constructed, not machine-checked** — gate any test removal
on running `kprove`.)

---

## 1. What the audit changed (V1 → V2)

| | V1 (baseline) | V2 (this pass) | Driver |
|---|---|---|---|
| `polylog.eval` | (unchanged; `z∈{0,1,-1}`) | **+ `elif z == S.Half and s == 2: return -log(2)**2/2 + pi**2/12`** | FINDINGS **F1** / PO1,PO2 |
| `_eval_expand_func` `s==1` | `-log(1 - z)` | same (kept) | F2 / PO4 |
| `_eval_expand_func` `s==2,z==1/2` | closed form | same (kept; `evaluate=False` path) | F4 / PO3 |
| local import | `log, expand_mul, Dummy` | same | F2 |
| docstring | `-log(-z + 1)` | same | F2 / PO7 |

**Net new code vs V1:** two lines in `polylog.eval`. Everything else in V1 was confirmed
correct and kept.

## 2. The single decision and its justification

The audit's whole verdict turns on **placement** of `Li_2(1/2)`:

- V1 satisfied the `expand_func` obligation (In[2]) but **not** the construction-path
  obligation, which the public evidence requires: `test_wester.test_R18` (cites issue
  #7132) checks the value via `.simplify()`, and `simplify` does **not** `expand_func` a
  polylog (PROOF PO2; `simplify.py` analysis). Plus the FVK intent-note forbids enshrining
  "stays unevaluated by default" (the In[1] symptom).
- The two-candidate derivation (PROOF_OBLIGATIONS PO-PLACEMENT) shows candidate A (V1)
  *demonstrably fails* PO2, so the choice is **forced** to eval, not under-determined. This
  is the FVK rule "resolve placement toward the bare-form obligation, never toward V1."
- Gating on `s==2` keeps `polylog(3,1/2)` etc. unevaluated (L8 / `test_hyperexpand:608`),
  so the change does not over-generalise.

## 3. Test-redundancy recommendation (benefit 1) — conditioned on `kprove`

Mapped onto the proved contract (PO1–PO6). **Recommendation only; never auto-delete.**

- **Subsumed if PO1–PO3 machine-check** (the value is proved for the construction path,
  hence for `bare == closed`, `myexpand(...closed)`, and `.simplify()`):
  any single-point assertion of `polylog(2,1/2)`'s value, in whatever access form.
- **Subsumed if PO4 machine-checks:** `myexpand(polylog(1, z), -log(1 - z))` (the proved
  rewrite). The pre-fix `myexpand(polylog(1,z), -log(1+exp_polar(-I*pi)*z))` is **not**
  "redundant" — it is **SUSPECT/wrong** and must be *changed*, not kept (FINDINGS F2).
- **Keep (out of scope of the unit proof):**
  - `test_R18` end-to-end (`Sum.doit().simplify()`) — integration over the summation
    engine, not just polylog; keep (and consider removing its `@XFAIL`).
  - `polylog(3, ·)`, `polylog(s,0/1/-1)` symbolic, the `s≤0` expansion, `td(polylog(b,z),z)`
    numeric-derivative tests — different domain/feature.
- **CI impact:** negligible (a couple of micro-assertions); the value here is the **bug
  found (F1)**, not test deletion.

## 4. Feedback for the next code/spec pass

- **UltimatePowers question to the user:** "Should other closed-form polylog values
  (`Li_2(2)`, `Li_3(1/2)`, `Li_1(1/2)=log2`, `Li_2(golden ratio)`) also auto-evaluate, or
  only `Li_2(1/2)` as requested?" (FINDINGS F7). Current answer encoded: only `Li_2(1/2)`.
- **Possible follow-up (not done — no intent evidence):** teach `simplify`/a polylog
  `_eval_simplify` to expand known polylogs, which would let `expand_func`-only handle
  `.simplify()`. Rejected here as larger and out of this issue's scope; eval is the
  minimal in-convention fix.
- **De-XFAIL `test_R18`:** with V2 the assertion holds; the maintainer may drop its
  `@XFAIL`. If kept, it XPASSes harmlessly (FINDINGS F6; `runtests.py:2224` verdict
  excludes `_xpassed`).
- **Escalation debts to close (PROOF §Escalation):** machine-prove or numerically certify
  **LEM-LI1** (`Li_1=-log(1-z)`) and **LEM-LI2** (`Li_2(1/2)`); they are the only
  non-mechanical obligations and currently rest on textbook identities + the issue's
  numerical verification.

## 5. Residual risk ledger

- Proof **constructed, not machine-checked** — run the `kprove` block in PROOF.md.
- mini-cas.k abstracts the full CAS arithmetic normaliser (faithful for the rewrite
  obligations; not a full SymPy semantics).
- F5 (auto-eval changes the *kind* of `polylog(2,1/2)`): only bites the unlikely
  `myexpand(..., None)` form; explicit-target tests and all other access paths are fine.
- Partial correctness only; no termination obligation in scope.
