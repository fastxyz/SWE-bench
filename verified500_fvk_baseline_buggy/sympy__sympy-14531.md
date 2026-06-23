# sympy__sympy-14531

## Summary

**Severity:** Medium — baseline drops the active `sympy_integers` printer option in several
expression families, losing round-trip fidelity for a valid use of that documented option.

Baseline and FVK both passed the official SWE-bench evaluation for the "printer settings
ignored by subexpressions" issue, but baseline fixed only the two `StrPrinter` methods named
in the issue (`Limit`, `Relational`), leaving seven sibling methods carrying the identical
bug. FVK extended the same one-line fix — route operand fields through `self._print(...)` —
to all of them, so `sympy_integers=True` is honored everywhere it was being silently
dropped. FVK located the residue by **formalizing "composite operands must render through
the active printer" as a family obligation** and auditing every sibling method against it,
not by running more tests.

| Arm | `sstr(Interval(S(1)/2, S(3)/2), sympy_integers=True)` | Resolved |
|---|---|---|
| baseline | `Interval(1/2, 3/2)` — lossy float on re-parse | no |
| gold (human oracle) | (does not fix `Interval`; fixes other domain methods) | partial |
| **fvk** | `Interval(S(1)/2, S(3)/2)` — exact | **yes** |

(No harness `_proof` exists for this instance; verification is an executed demonstration on
a version-identical base — see §5.)

## 1. The issue and the real defect

SymPy's string printer has a `sympy_integers=True` option making output round-trip-safe:
integers print as `S(1)/2` (exact `Rational`), not `1/2` (which re-parses to Python float
`0.5`). The reported bug: `sstr(Eq(x, S(1)/2), sympy_integers=True)` yields `'Eq(x, 1/2)'`
and `sstr(Limit(x, x, S(1)/2), sympy_integers=True)` yields `'Limit(x, x, 1/2)'` — the
setting is dropped
([`problem_statement.md`](../verified500_analysis/sympy__sympy-14531/_materials/problem_statement.md#L6)).

Root cause: several `StrPrinter` methods build output by interpolating raw subexpressions
with `%s` (plain `str()`), bypassing the active printer and dropping the setting. The issue
shows `Eq` and `Limit`; the same defect lurks in many sibling methods.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/solutions/solution_baseline.patch)
correctly diagnosed the root cause and fixed exactly the two methods named in the issue —
`_print_Limit` and the equality branch of `_print_Relational` — routing their operands
through `self._print(...)`. Its notes show the deliberate decision to stop there:

> *"I considered broadly replacing every direct `%s` interpolation in `StrPrinter`, but
> rejected that as too large for this issue. … The minimal fix covers the reported `Limit`,
> `Eq`, and `python(Eq(...))` failures by fixing the shared bypass in their printer
> methods."*
> — [`reports/baseline_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/reports/baseline_notes.md#L19)

That reasoning is half right: a blanket rewrite *would* be too broad, because some methods
intentionally delegate to domain-specific renderers. But baseline left every other method
with the identical operand-bypass bug. The obligation it left unmet: **every composite
printer method whose operands are SymPy subexpressions must route them through the active
printer.**

## 3. How FVK formally captured the gap

FVK started from an intent spec that lifts the issue's two examples into a family rule:

> *"For composite `StrPrinter` methods, public printer behavior requires nested SymPy
> operands to be printed with `self._print(...)`; using direct `str()` or raw `%s`
> interpolation is not an intended special case unless a method is delegating to an
> explicitly domain-specific formatter."*
> — [`fvk/SPEC.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/SPEC.md#L20)

The evidence ledger pins that intent to a concrete code audit of V1 — **not** to the
reported test — enumerating the exact siblings that still carry the bug:

> **E6:** *V1 code audit — V1 fixed `_print_Limit` and equality-like `_print_Relational`,
> but left the same direct-subexpression pattern in `AppliedPredicate`, `ExprCondPair`,
> `Interval`, `Lambda`, `MatrixElement`, `Normal`, and `Uniform`. → V1 is incomplete against
> the generalized printer contract. Finding F1; V2 edits applied.*
> — [`fvk/SPEC.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/SPEC.md#L32)

This discharges into a formal obligation over the whole family:

> **PO-FAMILY — Other audited composite operands use active printer.** *Code paths:
> `_print_AppliedPredicate`, `_print_ExprCondPair`, `_print_Interval`, `_print_Lambda`,
> `_print_MatrixElement`, `_print_Normal`, `_print_Uniform` … The proof requires each listed
> method to compose its observable string from `self._print(...)` results for operand
> fields.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/PROOF_OBLIGATIONS.md#L63)

This is the crux: the residual bugs were located by **reasoning over an invariant**. The
issue names two failing methods; FVK lifts that to "all composite operands must recurse
through the active printer" (intent item 4, grounded by the `printer.py` documentation E4),
and the source audit (E6) enumerates the seven siblings that violate it. A bounded frame
condition (E7) keeps domain-specific delegations out of scope.

## 4. From formal output to the fix

The repair is iterative, and the artifacts record the step where the formalism changed the
patch.

- **V1** fixed only `_print_Limit` and `_print_Relational` (identical to what baseline
  shipped).
- The completeness audit against the spec raised a finding:

  > **F1: V1 fixed the reproductions but not the full recursive-printer obligation.** *V1
  > changed `_print_Limit` and equality-like `_print_Relational`, but the same raw-operand
  > pattern remained in `_print_AppliedPredicate`, `_print_ExprCondPair`, `_print_Interval`,
  > `_print_Lambda`, `_print_MatrixElement`, `_print_Normal`, and `_print_Uniform`.*
  > — [`fvk/FINDINGS.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/FINDINGS.md#L5)

- The iteration guidance turned the finding into the code decision:

  > *"V1 should not stand unchanged. The audit found that V1 fixed the reported `Eq`,
  > `Limit`, and `python(Eq(...))` examples, but left the same active-printer bypass in
  > several other `StrPrinter` composite methods. V2 applies the same `self._print(...)`
  > rule to those methods."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records each extended method, e.g.:

  > *"Changed `_print_Interval` to print endpoints through `self._print(...)`. This follows
  > F1 and PO-FAMILY because endpoints are SymPy expressions and can include rationals or
  > integers affected by `sympy_integers=True`."*
  > — [`reports/fvk_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/reports/fvk_notes.md#L15)

The causal chain is fully on the record:

```
SPEC intent 4  ->  E4 (printer.py: use the active printer for nested exprs) + E6 (audit: 7 siblings still bypass it)
               ->  F1 (V1 audit: reproductions fixed, family obligation unmet)
               ->  PO-FAMILY (obligation: every composite operand uses self._print)
               ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The
[V2 patch](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/solutions/solution_fvk.patch)
keeps baseline's two fixes and routes the operand fields of the seven sibling methods
through `self._print(...)`, while explicitly leaving domain-specific delegating methods
alone (F4/PO-FRAME). The `V1 -> V2` transition was driven by `F1`/`PO-FAMILY`, **not** by a
new failing test — no test exercises Interval/Lambda/Piecewise/etc. under `sympy_integers=True`
(see §5).

## 5. Verification

**Executed demonstration (not on the harness).** Baseline- and fvk-patched copies of
`str.py` were built from a version-identical base (`sympy__sympy-14248/repo`, whose pre-patch
`str.py` is byte-identical to 14531's base — both patches apply with `git apply --check`),
run on Python 3.9 / sympy 1.1.2.dev. All inputs `sstr(..., sympy_integers=True)`:

| Input | baseline (WRONG) | fvk (RIGHT) = expected |
|---|---|---|
| `Interval(S(1)/2, S(3)/2)` | `Interval(1/2, 3/2)` | `Interval(S(1)/2, S(3)/2)` |
| `Lambda(x, S(1)/2)` | `Lambda(x, 1/2)` | `Lambda(x, S(1)/2)` |
| `Piecewise((S(1)/2, x>0),(S(1)/3,True))` | `Piecewise((1/2, x > 0), (1/3, True))` | `Piecewise((S(1)/2, x > S(0)), (S(1)/3, True))` |
| `Q.positive(x + S(1)/2)` | `Q.positive(x + 1/2)` | `Q.positive(x + S(1)/2)` |

Why wrong, not cosmetic: the point of the setting is round-trip safety. Re-evaluated as
Python, baseline's `Interval(1/2, 3/2)` gives float endpoints (`eval('1/2')==0.5`), losing
exactness; fvk's re-parses to exact `Rational`. No regression: with default settings both
print identically; divergence appears only when the setting is on.

**Why the suite missed it.** `FAIL_TO_PASS` is only `test_Rational` + `test_python_relational`,
and `gold_test.patch` adds asserts only for the two methods baseline already fixed. No test
exercises Interval/Lambda/Piecewise/AppliedPredicate/Normal/Uniform/MatrixElement under
`sympy_integers=True`, so the suite is provably blind to the defect.

**Gold comparison.** The human gold patch routes operands through `self._print(...)` in the
methods fvk extended (`_print_AppliedPredicate`, `_print_ExprCondPair`, `_print_Lambda`,
`_print_MatrixElement`, `_print_Normal`, `_print_Uniform`, plus Limit/Relational). Two
divergences: gold also fixed some domain methods fvk left (`_print_Permutation`,
`_print_PolyRing`, `_print_FracField`, `_print_Pi`, `_print_TensAdd`); and gold did **not**
fix `_print_Interval` but fvk did — a legitimate fix, so on `Interval` fvk is *more complete
than the human*.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is any use of `sympy_integers=True` (a documented
  round-trip option) over the seven affected expression families. The symptom is silent loss
  of round-trip fidelity — re-parsing baseline's output yields floats instead of exact
  rationals — which is correctness, not cosmetics, but lower stakes than data corruption,
  hence Medium.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-printing.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/mini-python-printing.k),
  [`strprinter-spec.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/strprinter-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/PROOF.md#L3)).
  We claim **proof-structured reasoning**, not a machine-checked proof.
- **Attribution.** This instance has no harness `_proof`; verification is the executed
  demonstration above, run on a version-equivalent sibling repo whose `str.py` is
  byte-identical to 14531's base. Two unrelated tests fail identically on baseline AND fvk
  (pre-existing version noise, not in 14531's PASS_TO_PASS, not an fvk regression). All
  PASS_TO_PASS tests touching fvk's extended methods (`test_Interval`, `test_Lambda`,
  `test_Limit`, `test_Relational`, `test_RandomDomain`) pass on fvk.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/sympy__sympy-14531/_materials/problem_statement.md#L6) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/reports/baseline_notes.md#L19) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/solutions/solution_fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/sympy__sympy-14531/_materials/gold.patch) |
| Intent (composite operands use _print) | [`fvk/SPEC.md#L20`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/SPEC.md#L20) |
| Evidence E6 (7 siblings still bypass) | [`fvk/SPEC.md#L32`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/SPEC.md#L32) |
| Obligation PO-FAMILY | [`fvk/PROOF_OBLIGATIONS.md#L63`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/PROOF_OBLIGATIONS.md#L63) |
| Finding F1 | [`fvk/FINDINGS.md#L5`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/FINDINGS.md#L5) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (_print_Interval) | [`reports/fvk_notes.md#L15`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/reports/fvk_notes.md#L15) |
| Constructed K core | [`fvk/mini-python-printing.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/mini-python-printing.k), [`fvk/strprinter-spec.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/strprinter-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-14531/fvk/PROOF.md#L3) |
