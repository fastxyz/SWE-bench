# sympy__sympy-22714

## Summary

**Severity:** Medium — under `evaluate(False)`, baseline can still reject valid
real `Point` coordinates whose `im()` reduces to zero only through helper
constructors, so a legitimate geometry construction raises instead of returning a
point. Medium rather than High because it is an incorrect-raise, not silent result
corruption, and the residual class is narrow.

Baseline and FVK both passed the official SWE-bench evaluation for issue #22714,
with **different** patches. Baseline forced evaluated semantics on the single
top-level `im()` call; FVK found that helper constructors inside `im.eval` could
still observe the ambient `evaluate(False)` flag and leave a truthy residual, so it
wrapped the **entire validation probe** in an evaluated context. The defect is
located by reasoning about the evaluation-context invariant, not by a new test.

| Arm | [`test_issue_22684` (FAIL_TO_PASS)](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/baseline.report.json) | Resolved |
|---|---|---|
| baseline | [PASS (official eval)](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/baseline.report.json) | yes (for the harness case) |
| gold (human oracle) | forces evaluated `im` at the validation site | yes (for the harness case) |
| **fvk** | [PASS (official eval)](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/fvk.report.json) | **yes — plus the helper-evaluation residual** |

## 1. The issue and the real defect

The reported issue: `with evaluate(False): S('Point2D(Integer(1),Integer(2))')`
crashes with `ValueError('Imaginary coordinates are not permitted.')`, even though
the same expression constructs fine outside that context
([`prompts/fvk.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/prompts/fvk.md#L2)).

`Point.__new__` validates coordinates with a numeric imaginary-part guard:

```python
if any(a.is_number and im(a) for a in coords):
    raise ValueError('Imaginary coordinates are not permitted.')
```

The trailing `im(a)` is consumed directly in a Python truth test. Under ambient
`evaluate(False)`, `Function.__new__` honors the global flag, so `im(Integer(1))`
can remain an **unevaluated** `im(1)` object instead of collapsing to `0`. An
unevaluated `im(...)` object is truthy, so a real coordinate is misclassified as
imaginary and the construction is wrongly rejected
([`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/baseline_notes.md#L9)).
The user-facing observable: valid real-coordinate geometry raises under a global
evaluation mode that should not affect the validation result.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/solutions/solution_baseline.patch#L10)
forced evaluation on the top-level call, changing `im(a)` to `im(a, evaluate=True)`:

```python
-        if any(a.is_number and im(a) for a in coords):
+        if any(a.is_number and im(a, evaluate=True) for a in coords):
```

Baseline was not careless. Its notes give the right root cause (an unevaluated,
truthy `im` result in a truth test) and deliberately chose this over the broader
alternatives — it rejected rewriting the parser/`sympify`, and rejected switching
to `im(a).is_zero` because that would change indeterminate-numeric behavior. It
called forcing evaluation on `im` "the smaller compatibility-preserving fix"
([`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/baseline_notes.md#L36)).

The obligation it left unmet: `im(a, evaluate=True)` forces evaluation of the
**outer** `im` application only. Constructors built *inside* `im.eval` (e.g. `Add`,
`re`, `im` on sub-expressions) still read `global_parameters.evaluate == False` from
the ambient context, so for a coordinate whose imaginary part needs that internal
simplification, a truthy residual can survive and re-trigger the same `ValueError`.

## 3. How FVK formally captured the gap

FVK started from the evaluation-context invariant, not from the symptom. The intent
spec lifts the issue into a context-invariance rule over the whole guard:

> **I-002:** *The imaginary-coordinate guard is a mathematical validation rule, not
> a request to preserve the ambient expression-building mode. It must classify
> numeric coordinates the same way as the normal evaluated path.*
> — [`fvk/SPEC.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L25)

The evidence ledger pins that intent to the prompt's two-sided observation — it
crashes inside the context but works outside it — establishing context-invariance as
an obligation, not a preference:

> **E-002.** *Source: prompt. Quote: "However, it works without `with
> evaluate(False)`." Obligation: the coordinate validation result should not depend
> on the ambient global evaluation flag for real numeric coordinates.*
> — [`fvk/SPEC.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L47)

The abstract domain then names the exact residual class the outer-only fix misses —
`residualZeroNum`, a numeric coordinate whose imaginary part is mathematically zero
but only after helper evaluation
([`fvk/SPEC.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L74)).
That class is discharged into a proof obligation that explicitly requires accepting
it independent of the ambient flag:

> **PO-002: Evaluation-context invariance for real numeric coordinates.** *…This
> includes `residualZeroNum`, which models real numeric expressions that need helper
> evaluation inside `im.eval` to reduce their imaginary part to zero.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF_OBLIGATIONS.md#L18)

This is FVK's value here: the residual was located by **reasoning about where the
evaluation flag is read**, not by observing a failing test. The invariant says "the
validation must use evaluated semantics for the entire `im` computation"; the code
audit shows the outer-only `evaluate=True` does not cover constructors inside
`im.eval`, so a whole class of real coordinates is still at risk.

## 4. From formal output to the fix

The audit of V1 (baseline's outer-only fix) produced the finding that drove the
revision:

> **F-001: V1 only forced top-level `im`, not helper evaluation.** *…helper
> constructors inside `im.eval` still see ambient `global_parameters.evaluate ==
> False`; a residual truthy expression can remain and trigger `ValueError(...)`.
> Resolution: V2 wraps the whole validation probe in `with evaluate_context(True)`.*
> — [`fvk/FINDINGS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/FINDINGS.md#L5)

The iteration guidance turns the finding plus PO-002 into a concrete code decision,
and justifies it as the minimal change that closes the gap:

> *Apply V2 rather than keeping V1 unchanged. Reason: F-001 shows V1 did not fully
> discharge PO-002 because only the top-level `im` call was forced to evaluate. …
> This is the minimal source change that makes the validation probe use the same
> evaluation semantics as the normal path…*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting source change and its provenance:

> **D-001: Revise V1 instead of leaving it unchanged.** *Trace: FINDINGS F-001 and
> PROOF_OBLIGATIONS PO-002 show that V1 forced only the top-level `im` call. The
> revised code wraps the whole probe in `with evaluate_context(True)`…*
> — [`reports/fvk_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/fvk_notes.md#L5)

The causal chain is fully on the record:

```
SPEC I-002  ->  E-002 (context-invariance from the prompt's two-sided observation)
            ->  PO-002 (obligation: accept residualZeroNum independent of ambient flag)
            ->  F-001  (V1 audit: helper constructors inside im.eval still see evaluate(False))
            ->  ITERATION_GUIDANCE / D-001  ->  V2 patch
```

The resulting [FVK patch](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/solutions/solution_fvk.patch#L20)
imports the evaluation context manager and wraps the whole guard, so both the outer
`im` call and any helper constructors inside it run under evaluated semantics:

```python
-        if any(a.is_number and im(a) for a in coords):
-            raise ValueError('Imaginary coordinates are not permitted.')
+        with evaluate_context(True):
+            if any(a.is_number and im(a) for a in coords):
+                raise ValueError('Imaginary coordinates are not permitted.')
```

The `V1 -> V2` transition was driven by `F-001`/`PO-002` from the formal audit,
**not** by a new failing test — the task forbade running or adding tests, so the
residual was found by source reasoning alone.

## 5. Verification

**Source-and-artifact reviewed; not executed (for the residual class).** The FVK
arm had no execution environment — the prompt explicitly forbids running tests,
Python, or K tooling
([`prompts/fvk.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/prompts/fvk.md#L27)) —
and the existing evidence doc contains no executed demonstration table. The residual
(`residualZeroNum` accepted independent of the ambient flag) is established by
reviewing: the V1→V2 patch delta, finding F-001, obligation PO-002, and the
constructed proof sketch's counterexample analysis
([`fvk/PROOF.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF.md#L40),
where `imagTruthy(residualZeroNum, false) == true` but
`imagTruthy(residualZeroNum, true) == false`).

**Harness (official SWE-bench Docker).** Both arms were evaluated. The reported case
(`test_issue_22684`) is FAIL_TO_PASS for both, with all 11 PASS_TO_PASS geometry
tests preserved
([baseline](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/baseline.report.json),
[fvk](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/fvk.report.json)).
The harness does **not** distinguish the two patches: there is no test in the suite
that exercises a `residualZeroNum`-style coordinate, so the residual the FVK fix
closes is invisible to the official evaluation. Both arms read "resolved"; the
difference is only visible by source reasoning.

**Compatibility preserved.** The FVK patch keeps the `a.is_number` boundary and the
truthiness-based rejection (so `Point(3, I)`, `Point(2*I, I)`, `Point(3 + I, I)`
still raise; symbolic `Point(0, x)` still accepted), and restores the ambient flag
on exit via the context manager
([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L9)).

## 6. Boundaries & honesty

- **Severity: Medium (carried over unchanged).** The residual is an incorrect-raise:
  a valid real coordinate that needs helper evaluation can wrongly raise
  `ValueError` under ambient `evaluate(False)`. The trigger breadth is narrow — it
  requires both the suppressed-evaluation context and a coordinate whose imaginary
  part reduces to zero only through `im.eval` internals — and it fails loudly rather
  than corrupting a result silently, which is why it is Medium and not High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-sympy-point.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/mini-sympy-point.k),
  [`point-imaginary-validation-spec.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/point-imaginary-validation-spec.k))
  and the `kompile`/`kprove` commands were written but never run — the artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF.md#L48),
  [finding F-005](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/FINDINGS.md#L71)).
  We therefore claim **proof-structured reasoning** (a formal spec with obligations
  discharged by construction over a mini-K abstraction), **not a machine-checked
  proof**.
- **Attribution.** The residual is reasoned, not observed: no test in the suite
  exercises it, and no code was executed. The argument rests on the V1→V2 patch
  delta plus F-001/PO-002/PROOF.md, all reconstructed from the run artifacts. The
  gold human oracle and baseline both addressed only the outer `im` call, so the
  FVK fix's extra coverage of helper-evaluation residuals goes beyond what the
  harness rewards. The full ordering can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/prompts/fvk.md#L2) |
| Root cause (unevaluated truthy `im`) | [`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/baseline_notes.md#L9) |
| Baseline patch (`im(a, evaluate=True)`) | [`solutions/solution_baseline.patch`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/solutions/solution_baseline.patch#L10) |
| Baseline "smaller compatibility-preserving fix" | [`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/baseline_notes.md#L36) |
| FVK patch (`with evaluate_context(True)`) | [`solutions/solution_fvk.patch`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/solutions/solution_fvk.patch#L20) |
| Intent I-002 | [`fvk/SPEC.md#L25`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L25) |
| Evidence E-002 | [`fvk/SPEC.md#L47`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L47) |
| `residualZeroNum` abstract class | [`fvk/SPEC.md#L74`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/SPEC.md#L74) |
| Obligation PO-002 | [`fvk/PROOF_OBLIGATIONS.md#L18`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF_OBLIGATIONS.md#L18) |
| Finding F-001 | [`fvk/FINDINGS.md#L5`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/FINDINGS.md#L5) |
| Honesty note F-005 | [`fvk/FINDINGS.md#L71`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/FINDINGS.md#L71) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace D-001 | [`reports/fvk_notes.md#L5`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/reports/fvk_notes.md#L5) |
| Counterexample analysis | [`fvk/PROOF.md#L40`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF.md#L40) |
| Proof not machine-checked | [`fvk/PROOF.md#L48`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PROOF.md#L48) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L9`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L9) |
| Constructed K core | [`fvk/mini-sympy-point.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/mini-sympy-point.k), [`fvk/point-imaginary-validation-spec.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/fvk/point-imaginary-validation-spec.k) |
| Harness verdicts | [`eval/baseline.report.json`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/eval/fvk.report.json) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-22714/transcripts/fvk.jsonl.gz) |
