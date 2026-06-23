# sympy__sympy-13877

## Summary

**Severity:** Low — baseline omits an explicit `S.NaN` determinant boundary, so a
matrix that already contains `nan` can silently return `0` instead of `nan`; the
trigger is the uncommon case of a pre-existing `nan` entry, so the blast radius is
small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue, with
**different** patches. Baseline correctly fixed the reported Bareiss pivot bug
(the `i + a*j` symbolic determinant that produced `nan` / `TypeError`); FVK kept
that fix and added a **second guard** for a distinct boundary called out in the
public discussion — a matrix whose entries already contain `S.NaN` must return
`S.NaN` immediately rather than fall through Bareiss. FVK located that second case
by **formalizing the issue's hints as obligations and auditing the determinant
entry point against them**, not by running a new test.

| Arm | Behavior on a matrix containing `S.NaN` (e.g. `Matrix([[0, S.NaN, 0, 0], …]).det()`) | Resolved |
|---|---|---|
| baseline | returns `S.Zero` (Bareiss skips the all-zero first pivot column) | no |
| gold (human oracle) | returns `S.NaN` (gold adds the input-NaN short-circuit) | yes |
| **fvk** | returns `S.NaN` (input-NaN guard added) | **yes** |

## 1. The issue and the real defect

The reported defect is that `det()` of certain symbolic matrices with entries
`i + a*j` returns `nan` (for `n = 5`) or raises `TypeError("Invalid NaN
comparison")` (for `n = 6`) — recorded as evidence
[E1/E2](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L44).
The FVK task prompt is the available problem statement for this non-curated case
([`prompts/fvk.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/prompts/fvk.md#L12));
it points at `benchmark/PROBLEM.md`, which is not retained in the run artifacts.

The root cause is in `MatrixDeterminant._eval_det_bareiss`. Its local `_find_pivot`
helper accepts the first **structurally truthy** entry as the pivot. A symbolic
expression that is algebraically zero (an unexpanded polynomial cancellation) is
truthy as a Python object, so Bareiss can pick a zero pivot and later divide by a
cumulative pivot that is mathematically zero, producing `0/0`, `nan`, and an
invalid comparison inside `factor_terms`/`cancel`
([`reports/baseline_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/baseline_notes.md#L5)).

The public discussion adds a **second, separate** observation: *"if the matrix
contained `nan` to begin with … return `nan` immediately"*
([E4](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L47)).
That is the residual defect this case is about: it is not the same as the
generated-`nan` pivot bug, and the reported example never exercises it.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_baseline.patch)
applied the change the public hint names directly: expand expression-valued pivot
candidates before accepting them, and skip a candidate that expands to exact zero.

```python
if isinstance(val, Expr):
    val = val.expand()
if not val:
    continue
return (pos, val, None, None)
```

Baseline was not careless. Its notes show it deliberately scoped the change to the
pivot test and rejected the broader alternatives — switching the default method to
LU, or replacing the local helper with `_find_reasonable_pivot`:

> *"I considered changing the default determinant method to LU or falling back to
> LU when Bareiss produces `nan`, but rejected that as broader than necessary … I
> also considered switching Bareiss to the general `_find_reasonable_pivot`
> helper, but the surrounding source comments indicate that this local helper is
> intentional for now."*
> — [`reports/baseline_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/baseline_notes.md#L30)

That reasoning is sound for the **generated-`nan`** mechanism, and it is what the
reported test needs. What it leaves unmet is the **input-`nan`** obligation: a
matrix that *already* contains `S.NaN`. For a size-4 matrix whose `nan` sits
outside the first pivot column, Bareiss finds the first column all exact zero,
`_find_pivot` returns no pivot, and `bareiss()` returns `S.Zero` before the `S.NaN`
entry ever participates in arithmetic — so baseline returns `0`, not `nan`
([finding F2](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L43)).

## 3. How FVK formally captured the gap

FVK started from the public intent, not the symptom. The intent spec splits the two
cases that the single reported example conflates — the generated-`nan` pivot bug
(item 3) and the input-`nan` boundary (item 4):

> **Intent item 4:** *If the input matrix already contains `S.NaN`, determinant
> computation should return `S.NaN` directly rather than treating that `nan` as an
> internally generated Bareiss failure to work around.*
> — [`fvk/SPEC.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L32)

It pins that intent to a concrete fact in the public hint — a ledger entry that
treats input `nan` as a *distinct* case, not a symptom to suppress:

> **E4 (public hint):** *"if the matrix contained nan to begin with … return nan
> immediately"* → *Input `S.NaN` is a distinct case and must short-circuit to
> `S.NaN`.*
> — [`fvk/SPEC.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L47)

Which is discharged into a formal obligation over the determinant entry point:

> **O1 — Input NaN Short-Circuit.** *For any square matrix `M`, if `M.has(S.NaN)`
> is true, then `M.det(method)` returns `S.NaN` before the size-specific
> determinant formulas or method-specific algorithms run.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF_OBLIGATIONS.md#L5)

This is the crux: **the second case was located by reasoning about the public
hints, not by observing a new failure.** The reported example only ever produces a
*generated* `nan`; the intent spec lifts "return `nan` immediately when it was
already there" into a separate obligation (O1) on `det()`, and the audit shows
baseline's pivot-only fix does not satisfy it.

## 4. From formal output to the fix

The FVK arm's repair is iterative. Its V1 (carried over from baseline) fixed only
the pivot helper; the completeness audit against the spec raised a finding that the
input-`nan` obligation was still unmet:

> **F2 — V1 Missed The Public Input-NaN Short-Circuit.** *Classification: code bug
> found by FVK audit and fixed in V2. … V1 only prevented internally generated
> expanded-zero pivots; it did not distinguish input `S.NaN`. … Resolution: add
> `if self.has(S.NaN): return S.NaN` immediately after the square-matrix check.*
> — [`fvk/FINDINGS.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L26)

The iteration guidance turns that finding into an instruction for the revision,
traced explicitly to F2/O1:

> *"Add an input-`S.NaN` guard to `MatrixDeterminant.det()`. Traced to
> `FINDINGS.md` F2 and `PROOF_OBLIGATIONS.md` O1. Reason: public intent
> distinguishes input `nan` from a `nan` generated by invalid Bareiss arithmetic."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/ITERATION_GUIDANCE.md#L11)

The decision log records the resulting code change and its provenance:

> *"Added an input-`S.NaN` guard in `…det`. Trace: `fvk/FINDINGS.md` F2 and
> `fvk/PROOF_OBLIGATIONS.md` O1. … The new guard runs after the square-matrix check
> and before size formulas or method dispatch."*
> — [`reports/fvk_notes.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/fvk_notes.md#L13)

The causal chain is fully on the record:

```
SPEC intent-4  ->  E4 (public hint: input nan returns nan immediately)
               ->  F2 (V1 audit: input-NaN case still unhandled)
               ->  O1 (obligation: det() short-circuits on M.has(S.NaN))
               ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch hunk
```

The resulting
[FVK patch](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_fvk.patch)
keeps the V1 pivot-expansion hunk verbatim and adds the second guard at the
`det()` entry point:

```python
if self.has(S.NaN):
    return S.NaN
```

The `V1 -> V2` transition was driven by **finding F2 / obligation O1**, not by a
new failing test — the run had no execution environment and added no test for the
input-`nan` case
([finding F4](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L73)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This case is not on the harness:
both arms passed the official SWE-bench evaluation, but no separate regression
report for the input-`nan` boundary was produced, and the run forbade execution of
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/prompts/fvk.md#L26)).
What was inspected:

- The two patches were diffed directly. They are **not** byte-identical: the FVK
  patch is a strict superset of baseline, adding exactly the `if self.has(S.NaN):
  return S.NaN` hunk after the non-square check in `det()`
  ([baseline](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_baseline.patch),
  [fvk](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_fvk.patch)).
- The behavioral claim is by source reasoning, recorded in F2: for a size-4 matrix
  with `S.NaN` outside the first pivot column, baseline's Bareiss path returns
  `S.Zero`; the FVK guard returns `S.NaN` before dispatch
  ([`fvk/FINDINGS.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L43)).
- The compatibility frame was audited: the guard adds no signature, method-name, or
  exception-behavior change, and calls the already-public `MatrixCommon.has`
  ([`fvk/SPEC.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L85)).

**Comparison to the human oracle.** The gold (upstream) fix for this issue likewise
adds an input-`nan` short-circuit at the determinant entry point, so FVK's extra
guard converges with what the maintainers shipped rather than going beyond it; it
is baseline that stopped one step short. (No gold patch file is retained for this
non-curated case, so this comparison is not linked.)

## 6. Boundaries & honesty

- **Severity: Low.** The trigger is an explicit `nan` *already present* in the
  input matrix — an uncommon boundary value, not the reported failure mode. The
  generated-`nan` bug that motivated the issue is fixed by both arms; the residual
  baseline gap is only the narrower "return the existing `nan`" case. The value
  demonstrated here is **completeness of the audit** — separating two cases the
  single reported example conflates — not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-sympy-bareiss.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/mini-sympy-bareiss.k),
  [`bareiss-det-spec.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/bareiss-det-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  proof document says so explicitly
  ([`fvk/PROOF.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF.md#L3),
  [O6](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF_OBLIGATIONS.md#L75)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not a machine-checked proof**.
- **Attribution.** The behavioral RED/GREEN contrast in the summary table is a
  *reasoned* outcome from F2's source analysis, not an executed test result; it was
  not run on the harness. The residual scope is also bounded by FVK's own residual
  risk: `.expand()` does not catch every algebraic identity, so a pivot zero only
  by a non-polynomial identity is out of scope and left as future work
  ([finding F3](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L54)).

## Artifact map

| Claim | Source |
|---|---|
| Problem statement (FVK task prompt) | [`prompts/fvk.md`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/prompts/fvk.md#L12) |
| Reported symptom E1/E2 | [`fvk/SPEC.md#L44`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L44) |
| Root cause (pivot truthiness) | [`reports/baseline_notes.md#L5`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/baseline_notes.md#L5) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_baseline.patch) |
| Baseline reasoning (rejected alternatives) | [`reports/baseline_notes.md#L30`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/baseline_notes.md#L30) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/solutions/solution_fvk.patch) |
| Intent item 4 (input-NaN) | [`fvk/SPEC.md#L32`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L32) |
| Evidence E4 (public hint) | [`fvk/SPEC.md#L47`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L47) |
| Obligation O1 | [`fvk/PROOF_OBLIGATIONS.md#L5`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF_OBLIGATIONS.md#L5) |
| Finding F2 (input-NaN gap) | [`fvk/FINDINGS.md#L26`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L26) |
| F2 behavioral reasoning (returns S.Zero) | [`fvk/FINDINGS.md#L43`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L43) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L11`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/ITERATION_GUIDANCE.md#L11) |
| Decision trace (guard added) | [`reports/fvk_notes.md#L13`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/reports/fvk_notes.md#L13) |
| Compatibility frame | [`fvk/SPEC.md#L85`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/SPEC.md#L85) |
| Residual risk F3 | [`fvk/FINDINGS.md#L54`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L54) |
| Verification not executed F4 | [`fvk/FINDINGS.md#L73`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/FINDINGS.md#L73) |
| Proof constructed, not run | [`fvk/PROOF.md#L3`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF.md#L3) |
| K commands emitted but not run | [`fvk/PROOF_OBLIGATIONS.md#L75`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/PROOF_OBLIGATIONS.md#L75) |
| Constructed K core | [`fvk/mini-sympy-bareiss.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/mini-sympy-bareiss.k), [`fvk/bareiss-det-spec.k`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/fvk/bareiss-det-spec.k) |
| No-exec task constraint | [`prompts/fvk.md#L26`](../results/verified045-codex-wsl-ubuntu-260615221107/sympy__sympy-13877/prompts/fvk.md#L26) |
