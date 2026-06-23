# django__django-13158

## Summary

**Severity:** High — the baseline leaves an empty guard placed late enough that a
`.none()` combined queryset can still drive operand SQL on a backend path the
guard does not dominate, so a queryset the contract requires to be empty can
silently return rows. It rates High because that is a wrong-result defect with no
error surfaced, reached through ordinary ORM usage (`union()`/`|` followed by
`.none()`, including the documented optional-`ModelMultipleChoiceField` empty
path).

Both arms passed the official SWE-bench evaluation. FVK's contribution was not a
new test: a formal audit of the `.none()` contract showed the empty guard
belongs at the compiler entry point `SQLCompiler.as_sql()`, before the
combinator backend-support check, rather than inside the single consumer
`get_combinator_sql()` that the baseline guarded.

| Arm | `union().none()` empty-result contract | Resolved |
|---|---|---|
| baseline | guard inside `get_combinator_sql()` — fires too late for the full contract | partial |
| gold (human oracle) | empty-result contract enforced | yes |
| **fvk** | guard at `SQLCompiler.as_sql()` entry, before the combinator branch | yes |

## 1. The issue and the real defect

The reported issue is *"QuerySet.none() on combined queries returns all
results"* — `QuerySet.none()` does not work properly on combined querysets and
returns all results instead of an empty queryset
([`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/prompts/fvk.md#L2)).

`QuerySet.none()` marks a queryset empty by cloning it and calling
`clone.query.set_empty()`, which adds a `NothingNode` to the outer
`Query.where`. For an ordinary query the compiler honors that marker and raises
`EmptyResultSet`. For a **combined** queryset (produced by `union()`,
`intersection()`, `difference()`, or `|`), SQL generation is delegated to
`SQLCompiler.get_combinator_sql()`, which assembles SQL from
`query.combined_queries`. That path skipped empty *child* queries but never
checked whether the **outer** combined query had itself been marked empty, so
the compiler emitted SQL for the original union operands instead of raising
`EmptyResultSet`
([`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/baseline_notes.md#L4)).

The user-facing observable: an optional `ModelMultipleChoiceField` whose queryset
is a `union()` returns `self.queryset.none()` for an empty submission, and that
supposedly empty queryset evaluates to **all** rows from the union. No error is
raised; the wrong rows simply come back.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_baseline.patch)
added an early `self.query.is_empty()` check at the top of the combined-query
consumer:

```python
def get_combinator_sql(self, combinator, all):
    if self.query.is_empty():
        raise EmptyResultSet
    features = self.connection.features
    ...
```

This was a deliberate, defensible choice. The baseline notes record that it
located the fix in ORM SQL compilation rather than the form layer, and
explicitly rejected both a form-level special case and a broader mutation of
`Query.set_empty()`:

> *"Added an early `self.query.is_empty()` check in
> `SQLCompiler.get_combinator_sql()`. If the outer combined query has already
> been marked empty, the compiler now raises `EmptyResultSet` before assembling
> SQL from the stored combined operands."*
> — [`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/baseline_notes.md#L23)

The choice is right about *where* the defect lives (the compiler, not the form)
and *what* signal to raise (`EmptyResultSet`). What it leaves unmet is **when**
the guard runs. `get_combinator_sql()` is only reached *after* `as_sql()` has
already selected the combinator branch and checked
`supports_select_<combinator>`. The empty marker therefore does not dominate the
whole compilation path — it is enforced inside one consumer rather than at the
compiler entry point. The unmet obligation is precisely that the empty-state
check must take precedence over the combinator backend-support check.

## 3. How FVK formally captured the gap

FVK started from the `.none()` contract as an invariant, not from the single
symptom. The decisive intent item generalizes the empty contract to *all* query
shapes:

> **I3.** *The empty-query contract applies to combined querysets as well as
> ordinary querysets. In particular, calling `.none()` on a `union()` queryset
> must not evaluate to the union's original operands.*
> — [`fvk/SPEC.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L29)

The evidence ledger pins that intent to two concrete code facts found by source
audit — the producer of the empty state, and the existing consumer of
`EmptyResultSet` — not to any reported test:

> **E5 (implementation, `query.py`):** *`none()` clones the queryset and calls
> `clone.query.set_empty()`* → *the compiler must honor `query.is_empty()` for
> any cloned query shape.*
> — [`fvk/SPEC.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L64)

> **E6 (implementation, `compiler.py`):** *`execute_sql()` catches
> `EmptyResultSet` and returns `iter([])` for `MULTI`* → *raising
> `EmptyResultSet` from SQL compilation is the existing Django mechanism for
> "empty queryset, no cursor."*
> — [`fvk/SPEC.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L69)

Together these say: the empty marker is produced once on the outer query, and
the no-results channel already exists at the compiler — so the marker must be
*honored at the point where compilation begins*, independent of any later
branch. That reasoning is discharged into a precedence obligation:

> **PO-03 — Empty-state precedence in SQL compilation.** *If `query.is_empty()`
> is true, `SQLCompiler.as_sql()` must raise `EmptyResultSet` before checking
> combined-query backend support or assembling SQL from `query.combined_queries`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF_OBLIGATIONS.md#L28)

This is the crux: the placement defect was located by **reasoning over the
contract**, not by observation. The issue says "`.none()` on a union must be
empty"; FVK lifts that to "the outer empty marker must dominate the entire
compile path," and the obligation names the exact ordering — `as_sql()` entry,
*before* the `if combinator:` block — that the baseline's `get_combinator_sql()`
guard does not satisfy.

## 4. From formal output to the fix

The FVK arm treated the baseline as a candidate (V1) and audited it against the
spec. The completeness audit raised a finding that V1's guard sits behind the
backend-support branch:

> **F-02: V1 placed the empty guard too late for the full documented contract.**
> *`as_sql()` checked `supports_select_<combinator>` before calling
> `get_combinator_sql()`, so the V1 guard inside `get_combinator_sql()` would not
> run first. The result could be `NotSupportedError` rather than the documented
> empty-query no-results behavior … Its emptiness is independent of whether the
> original combined query would have been executable on the backend.*
> — [`fvk/FINDINGS.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L26)

That finding maps onto **PO-03** (precedence) and the frame condition **PO-06**
(non-empty combined queries must be unchanged). The iteration guidance turned the
obligation into a concrete instruction:

> *"Move the empty-query guard from `get_combinator_sql()` to
> `SQLCompiler.as_sql()` before the combined-query backend support check. This is
> justified by F-02 and PO-03."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting code change and its provenance:

> *"I revised V1 … by moving the empty-query guard from `get_combinator_sql()` to
> `SQLCompiler.as_sql()`, before the combined-query backend support check … The
> V2 guard discharges PO-03 and PO-04: if `query.is_empty()` is true, compilation
> raises `EmptyResultSet`."*
> — [`reports/fvk_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/fvk_notes.md#L8)

The causal chain is fully on the record:

```
SPEC I3   ->  E5 / E6 (code audit: empty marker produced on outer query;
                       EmptyResultSet is the existing no-results channel)
          ->  F-02   (V1 audit: guard sits behind the backend-support branch)
          ->  PO-03  (obligation: as_sql() must raise EmptyResultSet first)
          ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [FVK patch](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_fvk.patch)
places the guard at the `as_sql()` entry, before the combinator branch:

```python
combinator = self.query.combinator
features = self.connection.features
if self.query.is_empty():
    raise EmptyResultSet
if combinator:
    if not getattr(features, 'supports_select_{}'.format(combinator)):
        raise NotSupportedError(...)
```

The `V1 -> V2` transition was driven by the **formal finding F-02 / obligation
PO-03**, not by a new failing test — the prompt forbade running or adding tests,
so the relocation was reasoned from the contract, and the form path was left
untouched as a localization finding
([F-03](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L47)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** No harness RED/GREEN
reports exist for this instance, and the FVK run had no execution environment
([`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/prompts/fvk.md#L27)).
What was inspected:

- the [baseline patch](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_baseline.patch)
  (guard in `get_combinator_sql()`) versus the
  [FVK patch](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_fvk.patch)
  (guard at `as_sql()` entry, before the `if combinator:` block) — the relocation
  is exactly the ordering PO-03 requires;
- the proof obligations
  [PO-03](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF_OBLIGATIONS.md#L28)
  (precedence) and
  [PO-06](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF_OBLIGATIONS.md#L67)
  (non-empty frame condition), against the patch delta;
- the constructed K spec files
  [`mini-django-query.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/mini-django-query.k)
  and
  [`django-query-none-spec.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/django-query-none-spec.k),
  whose claim C1 (`asSql(setEmpty(Q), S)` reaches `emptyResult` regardless of
  combinator or backend support) models the same ordering the V2 patch enforces.

Both arms were marked resolved by the official SWE-bench evaluation. That
evaluation exercises the reported `.none()` path but does not cover the residual
the FVK audit names — an empty combined queryset on a backend whose combinator
support flag is false, where the baseline's late guard can yield
`NotSupportedError` (or, more generally, lets the backend-support branch run
before the empty marker is honored). No executed behavioral demonstration of that
residual exists; the gap is established by contract reasoning, not by a run.

**Gold comparison.** The human oracle enforces the empty-result contract for
`union().none()`; the baseline enforces it only inside `get_combinator_sql()`.
The FVK patch matches the gold-level contract by lifting the guard to the
compiler entry point. (No gold patch file is published for this non-curated
instance, so this comparison is from contract reasoning, not a file diff.)

## 6. Boundaries & honesty

- **Severity: High.** A valid empty queryset can silently return rows it must not
  contain — a wrong-result defect with **no error surfaced**. The trigger breadth
  is ordinary, realistic ORM usage: combined `.none()` querysets via `union()` /
  `|`, including the documented optional-`ModelMultipleChoiceField` empty-value
  path. That combination — silent wrong result + ordinary trigger — is what makes
  it High per the rubric. The narrowing caveat is that the *residual* beyond the
  reported case (the backend-support ordering) requires a backend whose
  combinator support flag is false to be observably distinct.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-query.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/mini-django-query.k),
  [`django-query-none-spec.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/django-query-none-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction), **not** a machine-checked proof.
- **Attribution.** This instance is non-curated: no `_materials/`, no gold patch
  file, no harness reports. The baseline-vs-FVK placement gap and the
  gold-level-contract comparison are reconstructed from the patch deltas and the
  FVK artifacts, not observed on a harness. The `V1 -> V2` ordering is documented
  across
  [`FINDINGS.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L26),
  [`ITERATION_GUIDANCE.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/ITERATION_GUIDANCE.md#L7),
  and
  [`reports/fvk_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/fvk_notes.md#L8).

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/prompts/fvk.md#L2) |
| Root cause (outer empty marker ignored on combined path) | [`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/baseline_notes.md#L4) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/baseline_notes.md#L23) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/solutions/solution_fvk.patch) |
| Intent I3 | [`fvk/SPEC.md#L29`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L29) |
| Evidence E5 / E6 | [`fvk/SPEC.md#L64`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L64), [`fvk/SPEC.md#L69`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/SPEC.md#L69) |
| Obligation PO-03 (precedence) | [`fvk/PROOF_OBLIGATIONS.md#L28`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF_OBLIGATIONS.md#L28) |
| Frame condition PO-06 | [`fvk/PROOF_OBLIGATIONS.md#L67`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF_OBLIGATIONS.md#L67) |
| Finding F-01 (root cause) | [`fvk/FINDINGS.md#L6`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L6) |
| Finding F-02 (guard placed too late) | [`fvk/FINDINGS.md#L26`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L26) |
| Finding F-03 (form is consumer, not root cause) | [`fvk/FINDINGS.md#L47`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/FINDINGS.md#L47) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md#L8`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/reports/fvk_notes.md#L8) |
| Constructed K core | [`fvk/mini-django-query.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/mini-django-query.k), [`fvk/django-query-none-spec.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/django-query-none-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/fvk/PROOF.md#L3) |
| No execution environment | [`prompts/fvk.md#L27`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13158/prompts/fvk.md#L27) |
