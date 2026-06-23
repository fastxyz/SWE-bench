# sympy__sympy-24066

## Summary

**Severity:** Low — baseline leaks a low-level `TypeError` instead of the public
units error, but only for un-analyzable edge dimension inputs (e.g.
`Dimension(sin(length))`), not everyday usage, so the practical blast radius is
small.

Baseline and FVK both passed the official SWE-bench evaluation for issue #24062,
with **different** patches. Baseline generalized the dimension checks by calling
`DimensionSystem.is_dimensionless()` / `equivalent_dims()` **inline with no
guard**; those calls genuinely raise `TypeError` on symbolic dimensions the
system cannot reduce, so baseline turned a clean `ValueError` into an uncaught
`TypeError` — a regression it introduced. FVK located this by formalizing
"the new checks must be conservative" as a proof obligation and auditing the
inline call sites, then wrapped them in `try/except TypeError` helpers. The
defect is minor; the case matters because FVK caught a robustness gap that even
the human gold fix still has.

| Arm | `_collect_factor_and_dimension(meter + Q)`, `Q` dim `Dimension(sin(length))` | Resolved |
|---|---|---|
| baseline | uncaught **`TypeError`** ← regression | no |
| gold (human oracle) | `ValueError` (`Add` branch untouched) | n/a for `Add`; **`TypeError`** on `exp(Q)` |
| **fvk** | `ValueError` (matches original) | **yes** |

## 1. The issue and the real defect

**Issue #24062** — *"`SI._collect_factor_and_dimension()` cannot properly detect
that exponent is dimensionless"*
([`problem_statement.md`](../verified500_analysis/sympy__sympy-24066/_materials/problem_statement.md#L1)).
The reproducer collects `100 + exp(second/(ohm*farad))` and gets a spurious
mismatch because `second/(ohm*farad)` collects as
`Dimension(time/(capacitance*impedance))`, which is dimensionless under SI but
not *structurally* equal to `Dimension(1)`
([`problem_statement.md`](../verified500_analysis/sympy__sympy-24066/_materials/problem_statement.md#L17)).

The root cause is that `UnitSystem._collect_factor_and_dimension()` compared
collected dimensions structurally rather than asking the dimension system whether
they reduce to the same base dimensions
([`baseline_notes.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/reports/baseline_notes.md#L22)).
The user-facing observable that is wrong is the function-branch result dimension:
`exp(second/(ohm*farad))` should collect with dimension `Dimension(1)`, and the
addition to `100` should not raise.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch)
fixed the reported case correctly: in the `Function` branch it normalizes a
dimension the system proves dimensionless to `Dimension(1)`, and in the `Add`
branch it falls back to `equivalent_dims()` before raising. Its notes show the
choice was deliberate and reasonable:

> *"In the `Add` branch … dimensions that are not structurally equal are now
> checked with the active dimension system's `equivalent_dims()` before raising
> `ValueError`. … In the `Function` branch, collected argument dimensions that
> the active dimension system proves dimensionless are normalized to
> `Dimension(1)`."*
> — [`baseline_notes.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/reports/baseline_notes.md#L22)

But it called both predicates **inline with no exception guard**:

```python
if dim != addend_dim and (
        dimsys is None or not dimsys.equivalent_dims(dim, addend_dim)):
```
— [`solution_baseline.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch#L15)

```python
dims = [Dimension(1) if dimsys.is_dimensionless(dim)
        else dim for _, dim in fds]
```
— [`solution_baseline.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch#L25)

`DimensionSystem.is_dimensionless()` / `equivalent_dims()` raise `TypeError` when
a `Dimension` expression cannot be reduced to base dependencies (e.g.
`Dimension(sin(length))`). So for an incompatible addend carrying such a
dimension, baseline replaces the collector's clean `ValueError` with an uncaught
low-level `TypeError`. The obligation it left unmet: the *new* checks it
introduced must be **conservative** — an un-analyzable dimension must not escape
as a `TypeError`, and must keep the collector on its established `ValueError`
path.

## 3. How FVK formally captured the gap

FVK started from a spec that explicitly demands conservative new checks, not from
the symptom. The decisive intent item generalizes beyond the reported case:

> *"New equivalence or dimensionless checks introduced by the fix must be
> conservative: failure to analyze a dimension expression is not proof of
> dimensionlessness or equivalence."*
> — [`INTENT_SPEC.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/INTENT_SPEC.md#L15)

The evidence ledger pins that intent to a concrete code fact found by auditing
the V1 (baseline-shaped) inline call sites — **not** to the reported test:

> **I9 (FVK audit finding):** *V1 inline checks could leak `TypeError` from
> dependency analysis in additive compatibility checks. → An unanalyzable
> non-equal dimension pair should be treated as not equivalent by the new helper,
> keeping the collector on its `ValueError` path.*
> — [`SPEC.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/SPEC.md#L30)
> (mirrored in [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PUBLIC_EVIDENCE_LEDGER.md#L15))

That intent and evidence are discharged into a formal obligation distinct from
the one the reported test exercises:

> **PO4 — Conservative behavior for unsupported dimension-system checks.** *If
> `DimensionSystem.is_dimensionless()` or `equivalent_dims()` cannot analyze a
> dimension expression and raises `TypeError`, the V2 helpers return false for
> the new normalization/equivalence checks.*
> — [`PROOF_OBLIGATIONS.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF_OBLIGATIONS.md#L38)

paired with the obligation it must not break:

> **PO3 — Incompatible additions still raise.** *If addend dimensions are neither
> structurally equal nor dimension-system equivalent, … raises `ValueError` from
> the `Add` branch.*
> — [`PROOF_OBLIGATIONS.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF_OBLIGATIONS.md#L27)

This is the crux of FVK's value here: the regression was located by reasoning
about the *new code's* failure modes, not by observing a failing test. The spec
demands conservative checks; the audit (I9) shows the inline V1 calls are not
conservative; PO4 makes that a discharge obligation.

## 4. From formal output to the fix

The completeness audit against the conservativeness obligation raised an explicit
finding against the V1 (baseline) shape:

> **F2: V1 equivalence checks could leak lower-level `TypeError`.** *… the `Add`
> branch called `dimsys.equivalent_dims(dim, addend_dim)` inline. If dependency
> analysis raised `TypeError`, that lower-level exception could escape instead of
> following the collector's established incompatible-addend `ValueError` path.*
> — [`FINDINGS.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/FINDINGS.md#L26)

The iteration guidance turned the finding into an instruction for the next
revision:

> *"V1 did address the reported issue, but FVK finding F2 exposed a robustness
> gap in the way V1 called `DimensionSystem.equivalent_dims()` and
> `is_dimensionless()` inline. V2 keeps V1's intended behavior and adds
> conservative private helpers: `_is_dimensionless()`; `_dimensions_equivalent()`."*
> — [`ITERATION_GUIDANCE.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting code change and its provenance:

> *"FVK finding F2 showed that V1 could leak a lower-level `TypeError` from
> `DimensionSystem.equivalent_dims()` … PO3 requires incompatible additions to
> keep raising `ValueError`, and PO4 requires unsupported dimension analysis to
> be treated as not equivalent. Decision: add a private helper that returns true
> for structural equality, true for dimension-system equivalence, and false when
> no dimension system exists or analysis raises `TypeError`."*
> — [`fvk_notes.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/reports/fvk_notes.md#L24)

The causal chain is fully on the record:

```
INTENT_SPEC #6 (conservative checks)
  ->  I9   (audit: V1 inline calls can leak TypeError)
  ->  PO4  (obligation: TypeError -> false, stay on ValueError path)
  ->  F2   (V1-shape finding: inline equivalent_dims can escape)
  ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 helpers
```

The resulting [V2 patch](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch)
extracts both predicates into helpers that swallow `TypeError` as a negative
result:

```python
def _is_dimensionless(self, dimension):
    dimension_system = self.get_dimension_system()
    if dimension_system is None:
        return False
    try:
        return dimension_system.is_dimensionless(dimension)
    except TypeError:
        return False
```
— [`solution_fvk.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch#L9)

and routes the `Add` branch through the equivalence helper
([`solution_fvk.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch#L37)).
The `V1 -> V2` transition was driven by `F2`/`PO4`, **not** by a new failing test
— no test passes an un-analyzable dimension into the `Add` branch (see §5).

## 5. Verification

**No harness proof.** This case has no `enhanced_tests/_proof/` reports, so there
is no automated RED/GREEN table on the official harness. Evidence is the executed
behavioral demonstration below plus source/artifact review.

**Behavioral demonstration (executed, sympy 1.11.1 — the exact pre-fix
version).** `Q` is a quantity whose dimension is `Dimension(sin(length))`
(un-analyzable), fed as an incompatible addend:

```python
SI._collect_factor_and_dimension(meter + Q)   # incompatible add
```

| variant | result |
|---|---|
| original / gold | `ValueError` (clean, "incompatible dimensions") |
| **baseline** | **uncaught `TypeError`** ← regression |
| **fvk** | `ValueError` (matches original/gold) |

This demonstration is from the analysis record
([`ANALYSIS.md`](../verified500_analysis/sympy__sympy-24066/ANALYSIS.md#L15)); it
was executed on the exact buggy version but is **not** part of the SWE-bench
harness. The official suite exercises only the reported transcendental-of-
dimensionless case via `test_issue_24062`
([`tests.json`](../verified500_analysis/sympy__sympy-24066/_materials/tests.json#L2)),
which gold's `Function`-branch normalization handles; nothing in the suite passes
an un-analyzable dimension into the `Add` branch, so baseline's regression is
never triggered there.

**FVK is more robust than the human oracle.** The
[gold patch](../verified500_analysis/sympy__sympy-24066/_materials/gold.patch#L13)
changes only the `Function` branch and calls
`self.get_dimension_system().is_dimensionless(...)` **without a guard** — it never
touches the `Add` branch and shares the same `TypeError` crash on `exp(Q)` with
an un-analyzable dimension. FVK's `try/except` wrapping is a strict superset
([`ANALYSIS.md`](../verified500_analysis/sympy__sympy-24066/ANALYSIS.md#L26)):
on `exp(Q)`, baseline **and** gold raise `TypeError`, while fvk returns
`(E, Dimension(sin(length)))`.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger is narrow: only `Dimension` expressions the
  system cannot reduce (e.g. transcendental functions of dimensionful quantities
  used as `Dimension` arguments) hit the unguarded predicate. These are
  un-analyzable / edge inputs, not everyday units usage, so the practical blast
  radius is small. The value here is **detection of a self-inflicted regression
  and a robustness gap the gold fix also has**, not impact magnitude — sell the
  method, not the bug.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-sympy-units.k`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/mini-sympy-units.k),
  [`unitsystem-collect-spec.k`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/unitsystem-collect-spec.k))
  and the `kompile` / `kprove` commands were *written but never run* — the FVK
  artifacts say so explicitly
  ([`PROOF.md`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF.md#L3),
  [finding F4](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/FINDINGS.md#L65)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations PO3/PO4 discharged by construction), **not a machine-checked
  proof**. The regression-detection value does not depend on the unrun `kprove`;
  it rests on the executed demonstration in §5.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the full ordering can be
  recovered from
  [`transcripts/fvk.jsonl.gz`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/transcripts/fvk.jsonl.gz)
  if a reviewer wants the raw trace. The §5 demonstration is reconstructed from
  the curated `ANALYSIS.md`, not re-executed in this conversion; the patch delta
  (baseline inline vs fvk guarded helpers) is directly observed from the two
  patches.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`problem_statement.md`](../verified500_analysis/sympy__sympy-24066/_materials/problem_statement.md#L1) |
| Reported `ValueError` | [`problem_statement.md`](../verified500_analysis/sympy__sympy-24066/_materials/problem_statement.md#L17) |
| Baseline patch | [`solution_baseline.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch) |
| Baseline inline `equivalent_dims` (Add) | [`solution_baseline.patch#L15`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch#L15) |
| Baseline inline `is_dimensionless` (Function) | [`solution_baseline.patch#L25`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_baseline.patch#L25) |
| Baseline reasoning | [`baseline_notes.md#L22`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/reports/baseline_notes.md#L22) |
| FVK patch | [`solution_fvk.patch`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch) |
| FVK `_is_dimensionless` helper | [`solution_fvk.patch#L9`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch#L9) |
| FVK guarded `Add` branch | [`solution_fvk.patch#L37`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/solutions/solution_fvk.patch#L37) |
| Gold patch (Function-only, unguarded) | [`gold.patch#L13`](../verified500_analysis/sympy__sympy-24066/_materials/gold.patch#L13) |
| Intent: conservative checks | [`INTENT_SPEC.md#L15`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/INTENT_SPEC.md#L15) |
| Evidence I9 | [`SPEC.md#L30`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/SPEC.md#L30), [`PUBLIC_EVIDENCE_LEDGER.md#L15`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PUBLIC_EVIDENCE_LEDGER.md#L15) |
| Obligation PO4 (conservative) | [`PROOF_OBLIGATIONS.md#L38`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF_OBLIGATIONS.md#L38) |
| Obligation PO3 (still raises) | [`PROOF_OBLIGATIONS.md#L27`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF_OBLIGATIONS.md#L27) |
| Finding F2 | [`FINDINGS.md#L26`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/FINDINGS.md#L26) |
| Honesty note F4 | [`FINDINGS.md#L65`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/FINDINGS.md#L65) |
| Iteration instruction (V1→V2) | [`ITERATION_GUIDANCE.md#L7`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (helpers) | [`fvk_notes.md#L24`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/reports/fvk_notes.md#L24) |
| Executed demonstration table | [`ANALYSIS.md#L15`](../verified500_analysis/sympy__sympy-24066/ANALYSIS.md#L15) |
| Gold shares `exp(Q)` TypeError | [`ANALYSIS.md#L26`](../verified500_analysis/sympy__sympy-24066/ANALYSIS.md#L26) |
| Harness test scope | [`tests.json#L2`](../verified500_analysis/sympy__sympy-24066/_materials/tests.json#L2) |
| Constructed K core | [`mini-sympy-units.k`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/mini-sympy-units.k), [`unitsystem-collect-spec.k`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/unitsystem-collect-spec.k) |
| Proof not machine-checked | [`PROOF.md#L3`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/fvk/PROOF.md#L3) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified050-codex-wsl-ubuntu-260615221107/sympy__sympy-24066/transcripts/fvk.jsonl.gz) |
