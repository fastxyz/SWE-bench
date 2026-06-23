# sympy__sympy-12096

## Summary

**Severity:** Medium — the baseline (V1) fix makes nested `_imp_` recursion work
but drops two compatibility guarantees: it no longer reaches the legacy direct
`Float(...)` conversion for raw numeric returns, and it can report a
still-unresolved result as a successful numeric evaluation. The scope is confined
to the `_imp_` fallback branch of `Function._eval_evalf`, so valid implemented
functions can fail to evaluate or produce the wrong `evalf` shape, but only on
that one path.

Baseline and FVK both passed the official SWE-bench evaluation for this instance,
with **different** patches. FVK located the two residual gaps by formalizing the
old `Float(...)` conversion as a compatibility frame condition and auditing what
its V1 replacement no longer satisfies — not by running additional tests. The
official suite (`test_issue_12092`) exercises only the reported recursion case,
which V1 already fixed; it does not touch either residual defect.

| Arm | `_imp_` raw-Float fallback / AppliedUndef guard preserved | Resolved |
|---|---|---|
| baseline | **No** — recursive path only; legacy `Float` path unreachable, no `AppliedUndef` guard | no |
| gold (human oracle) | not available for this instance (non-curated) | — |
| **fvk** | **Yes** — restores `Float(imp_result, prec_to_dps(prec))` fallback and rejects unresolved results | **yes** |

## 1. The issue and the real defect

The task: `evalf` does not call `_imp_` recursively, so a composition of
implemented functions at concrete numeric arguments stays unevaluated. With
`f(x) = x**2` and `g(x) = 2*x`, `f(g(2)).evalf()` prints `f(g(2))` instead of
`16`
([`fvk/SPEC.md` E-001/E-002](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L27)).

The cause is in `sympy/core/function.py`, in the no-mpmath fallback branch of
`Function._eval_evalf`. The original code converted the `_imp_` result straight
to a `Float`:

```python
return Float(self._imp_(*self.args), prec)
```

For a nested implemented function the `_imp_` result is itself a symbolic
expression (`g(2)**2`), which is not float-convertible until the inner `g(2)` is
evaluated, so the conversion fails and the whole expression is left unchanged
([`reports/baseline_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_baseline.patch)
replaced the direct `Float` conversion with a sympify-then-recurse path:

```python
result = sympify(self._imp_(*self.args))
if result.is_number:
    return result._evalf(prec)
```

This is a reasonable, targeted fix. Its notes show the choices were deliberate:
it recurses only when the result is numeric, to keep `f(x).evalf()` returning
`f(x)` rather than rewriting `_imp_` for free-symbol input
([`reports/baseline_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/baseline_notes.md#L29)),
and it uses internal `_evalf(prec)` (binary precision) rather than public
`result.evalf(...)` because `_eval_evalf` receives binary precision
([`reports/baseline_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/baseline_notes.md#L35)).

But the rewrite is **subtractive without a backstop**. The old `Float(...)` call
was the conversion path for raw, directly-Float-compatible `_imp_` returns; V1
removed it entirely. Two obligations are now unmet:

1. If `sympify(...)` produces a non-numeric SymPy object, V1 returns `None` and
   never reaches the legacy `Float` conversion that previously succeeded for raw
   numeric returns.
2. V1 returns `result._evalf(prec)` whenever `result.is_number` is true, even if
   that recursive result still contains an applied undefined function — reporting
   a not-actually-resolved expression as a successful numeric evaluation.

## 3. How FVK formally captured the gap

FVK's audit started from intent items that generalize the issue beyond "make the
example evaluate." The decisive compatibility item names the behavior V1
silently dropped:

> **I-004.** *Existing successful behavior for direct numeric `_imp_` returns
> must be preserved, including values acceptable to the legacy `Float(...)`
> conversion path.*
> — [`fvk/SPEC.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L19)

The evidence ledger pins that intent to a concrete fact about the *pre-fix*
code — a compatibility frame condition recovered by reading what the old line
did, not from any test:

> **E-005.** *Source: implementation and compatibility. Quote: the legacy code
> was `Float(self._imp_(*self.args), prec)`. Obligation: direct numeric returns
> accepted by `Float` should remain accepted.*
> — [`fvk/SPEC.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L35)

which is discharged into a formal obligation V1 fails:

> **PO-005: Legacy raw numeric conversion is preserved.** *If
> `_imp_(*self.args)` returns a raw value accepted by `Float`, and the numeric
> SymPy recursion path does not apply, `_eval_evalf` returns
> `Float(imp_result, prec_to_dps(prec))`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L45)

The second gap is captured the same way. The evidence item generalizes the old
"return `None` when conversion cannot produce a value" behavior:

> **E-007.** *fallback returns `None` when direct conversion cannot produce a
> value … a recursive result that still contains an applied undefined function
> should fall back rather than being returned as an apparent success.*
> — [`fvk/SPEC.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L39)

> **PO-009: Unresolved applied undefined functions do not escape.** *If
> recursive `_evalf(prec)` of a numeric `_imp_` result still contains
> `AppliedUndef`, the recursive branch does not return that result.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L81)

Both gaps were located by reasoning over the spec: the issue asks only to *add*
recursive evaluation, so anything the fix *removes* (the `Float` backstop) or
*loosens* (accepting `is_number` results without checking for residual
`AppliedUndef`) is a compatibility regression, independent of any test.

## 4. From formal output to the fix

The findings tie each obligation to a concrete V1 defect and to the V2 source
change that repairs it. The fix is driven by the formal audit, not by a new
test (the prompt forbids adding tests, and none was added).

- The first residual gap is recorded as a finding against V1:

  > **F-002: V1 compatibility gap for direct Float-compatible raw returns.** *If
  > sympification produced a nonnumeric container-like SymPy object, V1 could
  > return `None` without trying the legacy direct `Float` conversion.*
  > — [`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L19)

- The second is recorded as F-005:

  > **F-005: Numeric-looking result with unresolved applied undefined function.**
  > *the recursive branch could return the partially unresolved expression as if
  > evaluation succeeded.*
  > — [`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L59)

- The iteration guidance turns F-002/PO-005 into the explicit reason for the V2
  source change:

  > *V1 did not fully preserve the legacy direct `Float(...)` conversion path …
  > Finding F-002 and PO-005 justify the V2 source change.*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting code and the additional precision and
  `AppliedUndef` adjustments:

  > *V2 fixes this by falling back to
  > `Float(imp_result, mlib.libmpf.prec_to_dps(prec))` … The recursive branch
  > now also checks that the evaluated result has no `AppliedUndef`. Finding
  > F-005 and PO-009 justify this guard.*
  > — [`reports/fvk_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/fvk_notes.md#L7)

The causal chain is on the record:

```
SPEC I-004 -> E-005 (frame: old code was Float(_imp_, prec))
           -> F-002 (V1 drops the Float backstop)
           -> PO-005 -> ITERATION_GUIDANCE / fvk_notes -> V2 Float fallback

SPEC E-007 -> F-005 (V1 returns unresolved AppliedUndef as success)
           -> PO-009 -> fvk_notes -> V2 `not result.has(AppliedUndef)` guard
```

The resulting
[FVK patch](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_fvk.patch)
keeps V1's recursion but restores the backstop and adds the guard:

```python
imp_result = self._imp_(*self.args)
try:
    result = sympify(imp_result)
except (AttributeError, TypeError, ValueError):
    pass
else:
    if getattr(result, 'is_number', False):
        result = result._evalf(prec)
        if result is not None and not result.has(AppliedUndef):
            return result
return Float(imp_result, mlib.libmpf.prec_to_dps(prec))
```

Note also the precision split (PO-003): the recursive path keeps binary `prec`
via `_evalf(prec)`, while the restored `Float` path converts to decimal digits
with `prec_to_dps(prec)` — V1's removed `Float(..., prec)` had passed binary
precision where `Float` expects decimal
([`reports/fvk_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/fvk_notes.md#L11)).

## 5. Verification

**Tier: source-and-artifact reviewed; not executed.** This instance is
non-curated: there is no `verified500_analysis/` directory and no enhanced-test
proof reports (`_proof/{baseline,gold,fvk}.report.json`). No regression test
isolates either residual defect.

**Official harness shows parity, not a distinguishing demonstration.** The
standard SWE-bench evaluation passed both arms with identical results — the same
single `FAIL_TO_PASS` (`test_issue_12092`) and the same `PASS_TO_PASS` set, no
failures
([baseline `eval/baseline.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/eval/baseline.report.json),
[fvk `eval/fvk.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/eval/fvk.report.json)).
The official test exercises only the reported recursion case, which V1 already
fixed; **neither residual defect (raw-Float fallback, unresolved `AppliedUndef`)
is covered by any test in the suite**, so the harness does not and cannot
demonstrate the gap. The defects are established by source review of the patch
delta against the FVK spec and obligations, not by an executed RED→GREEN.

What was inspected: the two patches
([baseline](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_baseline.patch),
[fvk](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_fvk.patch));
they differ in the three expected places), the intent spec and evidence ledger
([`fvk/SPEC.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L11)),
the obligations
([`fvk/PROOF_OBLIGATIONS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L45)),
the findings tracing V1 gaps to V2
([`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L19)),
and the decision trace
([`reports/fvk_notes.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/fvk_notes.md#L5)).

**No gold comparison.** This instance is non-curated, so no `gold.patch` is
available to compare against. The FVK patch's behavior beyond baseline is judged
only against the reconstructed spec, not against the human oracle.

## 6. Boundaries & honesty

- **Severity: Medium.** Carried forward from the prior evidence doc, unchanged.
  The trigger breadth is the `_imp_` fallback branch of `Function._eval_evalf`
  only — implemented functions returning raw Float-compatible values, or numeric
  expressions that retain an applied undefined function after recursion. Within
  that branch the user-facing effect is real (a valid implemented function fails
  to evaluate, or an unresolved expression is reported as a numeric success), but
  it is one code path, not a broad correctness regression — hence Medium, not
  High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-sympy-evalf.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/mini-sympy-evalf.k),
  [`function-evalf-spec.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/function-evalf-spec.k))
  and the `kprove` commands were written but never run — the FVK artifacts say so
  explicitly
  ([`fvk/PROOF.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF.md#L3)).
  The claim is **proof-structured reasoning** (a spec with obligations discharged
  by construction over an abstract fallback model), **not a machine-checked
  proof**. The honesty gate is recorded as F-004/PO-008
  ([`fvk/FINDINGS.md`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L45)).
- **Attribution caveats.** The residual-defect claim rests on source review of
  the patch delta plus the FVK spec; it is **not** independently confirmed by an
  executed test, because the official suite passes both arms identically and no
  enhanced test isolates the gap. The `V1 → V2` iteration ordering is documented
  across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the raw
  trace is in
  [`transcripts/fvk.jsonl.gz`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/transcripts/fvk.jsonl.gz)
  if a reviewer wants the full ordering. The V2 patch also relies on
  `AppliedUndef` and `mlib` being in scope in `function.py`; that import context
  was not separately verified here.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro (E-001/E-002) | [`fvk/SPEC.md#L27`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L27) |
| Pre-fix cause (`Float(...)` fails on nested `_imp_`) | [`reports/baseline_notes.md#L5`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/baseline_notes.md#L5) |
| Baseline patch (V1) | [`solutions/solution_baseline.patch`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_baseline.patch) |
| Baseline reasoning (numeric-only / `_evalf` choice) | [`reports/baseline_notes.md#L29`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/baseline_notes.md#L29) |
| FVK patch (V2) | [`solutions/solution_fvk.patch`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/solutions/solution_fvk.patch) |
| Intent I-004 (preserve legacy Float path) | [`fvk/SPEC.md#L19`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L19) |
| Evidence E-005 (old code = `Float(_imp_, prec)`) | [`fvk/SPEC.md#L35`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L35) |
| Evidence E-007 (unresolved fallback) | [`fvk/SPEC.md#L39`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/SPEC.md#L39) |
| Obligation PO-005 (raw Float fallback) | [`fvk/PROOF_OBLIGATIONS.md#L45`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L45) |
| Obligation PO-009 (no `AppliedUndef` escape) | [`fvk/PROOF_OBLIGATIONS.md#L81`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L81) |
| Obligation PO-003 (precision split) | [`fvk/PROOF_OBLIGATIONS.md#L25`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF_OBLIGATIONS.md#L25) |
| Finding F-002 (V1 drops Float backstop) | [`fvk/FINDINGS.md#L19`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L19) |
| Finding F-005 (unresolved result returned as success) | [`fvk/FINDINGS.md#L59`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L59) |
| Honesty note F-004 (proof boundary) | [`fvk/FINDINGS.md#L45`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/FINDINGS.md#L45) |
| Iteration decision (V1→V2 via F-002/PO-005) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (Float fallback + AppliedUndef guard) | [`reports/fvk_notes.md#L7`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/reports/fvk_notes.md#L7) |
| Constructed K core | [`fvk/mini-sympy-evalf.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/mini-sympy-evalf.k), [`fvk/function-evalf-spec.k`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/function-evalf-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/fvk/PROOF.md#L3) |
| Official eval (both arms resolved, identical) | [`eval/baseline.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/eval/fvk.report.json) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified043-codex-wsl-ubuntu-260615221107/sympy__sympy-12096/transcripts/fvk.jsonl.gz) |
