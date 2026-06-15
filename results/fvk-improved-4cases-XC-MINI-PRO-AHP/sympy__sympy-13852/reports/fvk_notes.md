# FVK notes — sympy__sympy-13852

This documents the FVK audit of the V1 fix and the decisions it produced. Every
decision is traced to a specific entry in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`.

## Outcome in one line

**V1 stands.** The audit confirms V1 is correct against the full public intent; I made
exactly **one behavior-preserving readability refactor** and added the FVK evidence
package. No correctness edit was justified, and that conclusion is backed by the proof
obligations (all discharge) and the adequacy gate (PASS).

## What V1 did, and what the audit asked of it

V1 changed `polylog._eval_expand_func`:
1. `s == 1` → return `-log(1 - z)` (was `-log(1 + exp_polar(-I*pi)*z)`).
2. new `s == 2, z == 1/2` → return `-log(2)**2/2 + pi**2/12`.
3. removed the now-unused `exp_polar, I` local imports; updated the docstring.

The FVK question is not "is V1 plausible?" but "what is still wrong vs. the **full**
intent — the issue text *plus* the docstring/API contract *plus* the public-test
encoding?" I built the intent ledger first (`fvk/INTENT_SPEC.md`,
`fvk/PUBLIC_EVIDENCE_LEDGER.md`), formalized the contract as K claims
(`fvk/polylog-expand-spec.k` over `fvk/mini-sympy.k`), ran the adequacy round-trip
(`fvk/FORMAL_SPEC_ENGLISH.md` → `fvk/SPEC_AUDIT.md`), and constructed the proof
(`fvk/PROOF.md`).

## Decision 1 — Keep `-log(1 - z)` for `s == 1` (no change)

- **Traces to:** FINDINGS **F1** (spurious `exp_polar`), **F3/F6** (derivative
  consistency), obligation **PO-1** and the load-bearing **PO-6**.
- **Reasoning:** PO-6 requires `d/dz(expansion) = d/dz polylog(1,z) = polylog(0,z)/z
  = 1/(1-z)`. PROOF §PO-6 derives `Diff(Neg(Log(Sub(1,z))), z) ⇒ Div(1, Sub(1,z))`,
  matching `Div(expandPolylog(0,z), z)`. The same section shows the **old** form
  `-log(1 + exp_polar(-I*pi)*z)` provably **cannot** discharge PO-6, because SymPy
  keeps `exp_polar(-I*pi)` opaque (never `-1`), so its derivative
  `-exp_polar(-I*pi)/(1 + exp_polar(-I*pi)*z)` never normalizes to `1/(1-z)`. That is
  exactly the non-zero residual the issue reported. V1's value is therefore correct
  and load-bearing — confirmed, not changed.

## Decision 2 — Keep the `polylog(2, 1/2)` value and its placement (refactor only)

- **Traces to:** FINDINGS **F2** (value), **F4** (placement), obligation **PO-2** and
  the numeric adequacy check (PROOF §Numeric); design analysis in `SPEC_AUDIT.md` D1.
- **The hard question (placement):** the FVK materials explicitly warn, for this exact
  issue, "do not enshrine 'stays unevaluated by default' as an invariant." So I did
  **not** simply accept V1's `_eval_expand_func` placement because it preserves the
  unevaluated `In[1]` display. Instead I promoted the named alternative — auto-evaluate
  in `eval` — to a hypothesis and derived both side by side (SPEC_AUDIT D1):
  - Both placements satisfy the **explicit** intent `polylog(2,1/2).expand(func=True)
    == answer` (PO-2). So that obligation does not decide it.
  - The deciding **positive** evidence: `test_polylog_expansion` encodes every
    **specific-`(s,z)`** reduction (`s=1,0,-1,-5`) through `myexpand`/`expand_func`
    and reserves bare `==` for **universal-`z`** reductions (`z∈{0,1,-1}`). `(2, 1/2)`
    is specific, so the `expand_func` path matches the public-test encoding. The whole
    `polylog` class routes non-universal closed forms through `_eval_expand_func`, and
    `eval` only does universal `z`. Auto-eval would add an unrequested side effect
    (`polylog(2,z).subs(z,1/2)` silently turns into logs).
  - I rejected auto-eval on these **positive** grounds (test pattern + named
    `expand_func`-is-opt-in convention), **not** on "out of scope" and **not** by
    treating the unevaluated symptom as a spec. This is recorded as the
    under-determined-but-resolved Finding F4, satisfying the FVK rule that a named
    change must be tested against full intent rather than dropped.

## Decision 3 — One minimal refactor (flatten the special-case guard)

- **Traces to:** PROOF **PO-7** (totality unchanged), a low-severity readability note in
  ITERATION_GUIDANCE.
- **Change:** `if z == S.Half: / if s == 2:` → `if s == 2 and z == S.Half:` in
  `repo/sympy/functions/special/zeta_functions.py`.
- **Why safe:** identical truth table; for `s=2` the earlier `s<=0` guard is already
  false, so dispatch order and results are unchanged (PO-7). It makes the special case
  read in the same flat style as the `s==1` and `s.is_Integer and s<=0` guards above.
  This is the only edit the audit produced, and it is behavior-preserving.

## Decision 4 — Do NOT widen scope

- **Traces to:** FINDINGS **F5**, obligation **PO-LOOP**.
- More dilog special values / a general `polylog(2,z)` reduction were considered and
  rejected: the issue names only `1/2`, and general `z` has no elementary closed form.
  The pre-existing `s<0` rational-function loop is untouched by the fix and not
  re-proved; `mini-sympy.k` abstracts it as `ratPolylog` with the `s=0` instance the
  public tests exercise (PROOF §Loop). These are intent-justified boundaries.

## Decision 5 — Treat the old test assertion as SUSPECT, do not edit tests

- **Traces to:** FINDINGS **F6**, `PUBLIC_COMPATIBILITY_AUDIT.md` "Public test impact".
- `test_zeta_functions.py:131` asserts the old `-log(1 + exp_polar(-I*pi)*z)` output —
  exactly the behavior the issue calls buggy ⇒ SUSPECT (S2). Per the task I do not
  edit tests; the graded suite is expected to assert `-log(1 - z)`. A test that must
  change to honor the intent is a positive bug signal, never a reason to revert V1 to
  the old value (intent-evidence §1).

## Adequacy & compatibility

- **Adequacy gate (SPEC_AUDIT): PASS** — every formal-English paraphrase is entailed
  by intent; nothing over-preserves legacy behavior; no claim asserts the SUSPECT
  "stays unevaluated."
- **Compatibility (PUBLIC_COMPATIBILITY_AUDIT): PASS** — no public signature change;
  the only caller of the changed branch, `lerchphi._eval_expand_func`, passes a
  **symbolic** `s` everywhere public, so it never hits `s==1`/`s==2` and is byte-for-
  byte unaffected; the removed `exp_polar/I` imports are local to `polylog` (lerchphi
  has its own).

## Honest status

The K proof is **constructed, not machine-checked** (the MVP does not run `kprove`;
commands are in `polylog-expand-spec.k`). The Findings (F1–F7) do not depend on
machine-checking and are reported with full confidence. No test removal is
recommended — the change tightens behavior and subsumes no safely-removable in-domain
unit point (ITERATION_GUIDANCE test table).
