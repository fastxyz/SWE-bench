# THE STATED excerpt — gold fix named, then rejected (tell #8)

The gold fix has two axes; BOTH are explicitly raised as considered alternatives
and rejected with constructed justifications. This is the load-bearing evidence for
the STATED verdict. (Quoted verbatim; the baseline reasoning is inherited by the
fvk fork, and control re-affirms it. fvk's own FINDINGS.md F8 rejects axis 2.)

================================================================================
AXIS 1 — PLACEMENT (the dominant cause): value belongs in polylog.eval, REJECTED
================================================================================

--- reports/baseline_notes.md:83-88 ---------------------------------------------
- **Where to add the `Li_2(1/2)` value — `eval` vs `_eval_expand_func`.**
  Chosen: `_eval_expand_func`. The issue demonstrates the bug with
  `.expand(func=True)` and shows `polylog(2, 1/2)` deliberately staying
  unevaluated by default (`Out[1]: polylog(2, 1/2)`). Putting the value in
  `eval` would auto-evaluate it and change the default display, which the issue
  does not ask for. Rejected.

--- reports/control_notes.md:35-38 ----------------------------------------------
- **Keep the value in `_eval_expand_func`, not `eval`.** Justified by **F4**: the
  issue's `In [1]` shows the value must stay unevaluated by default and appear only
  under `.expand(func=True)`. Moving it to `eval` would change the default display
  and contradict the issue. No change.

WHY THIS IS THE BUG: the gold patch places the dilog values in `polylog.eval`
(@classmethod, construction-time). The hidden test `test_polylog_values` asserts
the BARE form `polylog(2, S.Half) == pi**2/12 - log(2)**2/2` with NO
.expand(func=True), so the value MUST auto-evaluate at construction. FVK read the
issue's pre-fix display `Out[1]: polylog(2, 1/2)` as a binding "must stay
unevaluated" invariant — an invariant that PRESERVES the bug. Fabricated-requirement
form of primer tell #8.

================================================================================
AXIS 2 — COVERAGE: the golden-ratio table, REJECTED
================================================================================

--- fvk/FINDINGS.md:92-97 (F8) --------------------------------------------------
### F8 — V1 is intentionally narrow (only `Li_2(1/2)`) — ties L1
- The issue asks for exactly one new special value. Other dilogarithm values
  (e.g. golden-ratio arguments) are not requested and are not added.
- This is not a missing-case bug *relative to intent*: the spec's only `s==2`
  obligation is `z==1/2`. A broader special-value table is an enhancement, routed
  to ITERATION_GUIDANCE.md, not a correctness gap.

--- reports/baseline_notes.md:96-98 ---------------------------------------------
- **A broader special-value table for `polylog`.**
  Rejected as out of scope. The task asks for a minimal, targeted fix; only the
  `s == 2, z == 1/2` value is required by the issue.

WHY THIS IS THE BUG: the gold patch's added `s==2` cases ARE the golden-ratio /
Landen arguments (and z==2). The test enumerates all six. FVK names "golden-ratio
arguments" by their exact description and dismisses them as enhancement / scope
creep.

================================================================================
AXIS 3 (corroborating) — gold fix SITE read & correctly described, used to argue
the value belongs elsewhere (NOT to place it there)
================================================================================

--- fvk/PROOF_OBLIGATIONS.md:91-100 (PO7) ---------------------------------------
... `polylog.eval` returns `0 / zeta(s) / -dirichlet_eta(s)` ...
**Tier.** STRUCT (inspection of `polylog.eval`, lines 278-285).
**Discharge.** `eval` is a `@classmethod` run at construction; for `z in {0,1,-1}`
it [pre-filters before _eval_expand_func is reached] ...

FVK demonstrably understood that polylog.eval is the construction-time evaluator —
the exact mechanism needed to satisfy the bare-form test — but used that
understanding only to justify the dispatch's disjointness, never to place the
values there.
