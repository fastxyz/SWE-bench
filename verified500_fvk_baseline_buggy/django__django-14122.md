# django__django-14122

## Summary

**Severity:** Low — baseline leaves the public `QuerySet.ordered` property on a
weaker truthiness check (`not self.query.group_by`) that disagrees with the
compiler's documented `group_by is None` grouping sentinel, so introspection can
misreport a grouped query as ordered. The defect touches query *introspection*,
not the SQL that is actually executed, so its blast radius is narrow.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. The FVK patch keeps baseline's compiler fix and adds
a **second hunk** that realigns `QuerySet.ordered` with the same `group_by is
None` sentinel the compiler now uses — a residual inconsistency baseline
explicitly chose to leave alone. FVK located it by **formalizing the
no-grouping sentinel as a single invariant and auditing every consumer of
`group_by`**, not by running a new test.

| Arm | `QuerySet.ordered` uses `group_by is None` sentinel | Resolved |
|---|---|---|
| baseline | [no — keeps `not self.query.group_by`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_baseline.patch) | no |
| gold (human oracle) | not available (non-curated) | — |
| **fvk** | [**yes**](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_fvk.patch#L9) | **yes** |

## 1. The issue and the real defect

The task asks the agent to audit and improve its own fix for
**django__django-14122**: a grouped ORM query on a model with `Meta.ordering`
must not let the default metadata ordering leak into the SQL `GROUP BY` clause
([`prompts/fvk.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/prompts/fvk.md#L2)).
The reported defect is about *SQL generation*: `Meta.ordering` fields were still
being materialized into the grouping list even after the final `ORDER BY` was
suppressed.

The user-facing observable that the residual defect concerns is the adjacent
public boolean `QuerySet.ordered`. Django's own source documents two facts that
must agree:

- `Query.group_by` uses `None` as the *only* "no group by at all" sentinel; a
  tuple (including the empty tuple) or `True` are grouped states
  ([evidence E3](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)).
- the `ordered` property's own inline comment says *"A default ordering doesn't
  affect GROUP BY queries"*
  ([evidence E4](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)).

The property nonetheless guarded its default-ordering branch with a truthiness
check, `not self.query.group_by`, which treats a non-`None` falsy grouped state
(an explicit empty tuple) as ungrouped — disagreeing with the documented
sentinel.

## 2. Baseline's fix — and where it stopped

[Baseline's patch](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_baseline.patch#L10)
edits exactly one site, `SQLCompiler.get_order_by()`, narrowing the metadata
ordering branch to fire only when `self.query.group_by is None`. That is the
correct and minimal fix for the *reported* SQL defect, and its reasoning is
sound: it deliberately picks `group_by is None` over a truthiness check
precisely because an explicit empty tuple still follows the grouped-query path
([`reports/baseline_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/baseline_notes.md#L23)).

Baseline was not careless. Its notes show it *consciously considered* the
`QuerySet.ordered` property and chose to leave it alone:

> *"I also considered changing `QuerySet.ordered`, but it already treats default
> ordering as irrelevant for ordinary grouped queries; the bug is in SQL
> compilation, where metadata ordering was still materialized before being
> suppressed."*
> — [`reports/baseline_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/baseline_notes.md#L33)

That reasoning is **half right**: the reported failure is indeed in SQL
compilation. But it applied the strict `group_by is None` sentinel in the
compiler while leaving `ordered` on the looser `not self.query.group_by` — the
exact mismatch baseline's own assumptions argued against one paragraph earlier.
The unmet obligation is consistency: the public introspection path must use the
same no-grouping sentinel as the compiler.

## 3. How FVK formally captured the gap

FVK started from an intent spec that generalizes the issue beyond the single
reported compiler site. The decisive intent item names the introspection path
explicitly:

> **Required behavior 5:** *"Public introspection through `QuerySet.ordered`
> must agree with the same grouped-query rule: default ordering does not affect
> queries whose `query.group_by` state is active."*
> — [`fvk/INTENT_SPEC.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/INTENT_SPEC.md#L22)

The evidence ledger pins that intent to a concrete code fact found by source
audit — Django's documented `group_by` state shape — **not** to the reported
test:

> **E3:** *"`query.group_by is None` is the no-grouping sentinel; tuple and
> `True` are grouped-query states."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

Which is discharged into a formal obligation that the introspection path must
honor the same sentinel:

> **PO-5: Public `ordered` introspection uses the same grouped sentinel.**
> *"`QuerySet.ordered` must not report default metadata ordering as active for a
> query whose `query.group_by` is a grouped state. The no-grouping sentinel is
> `None`, not falsiness."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PROOF_OBLIGATIONS.md#L49)

This is the crux of FVK's value here: the inconsistency was located by
**reasoning over the sentinel invariant**, not by observing a failing test. The
issue is nominally about `GROUP BY`; FVK lifts it into an invariant over *every*
reader of `query.group_by`, and the audit shows `QuerySet.ordered` is a second
reader that still used the weaker truthiness form.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** (baseline) fixed `SQLCompiler.get_order_by()` only.
- The completeness audit against the spec raised a finding:

  > **F2: V1 left `QuerySet.ordered` on a weaker grouped-query sentinel.** …
  > *"`QuerySet.ordered` still used `not self.query.group_by`, so it would report
  > this state as ordered. … Classification: Consistency bug surfaced by FVK,
  > resolved by `repo/django/db/models/query.py`. Trace: Proof obligation PO-5."*
  > — [`fvk/FINDINGS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/FINDINGS.md#L33)

- The iteration guidance turned the finding into an instruction for the next
  revision:

  > *"Apply the V2 introspection alignment: `QuerySet.ordered` also uses
  > `query.group_by is None` for the default-ordering branch."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/ITERATION_GUIDANCE.md#L13)

- The decision log records the resulting code change and its provenance:

  > *"Added a follow-up edit in `repo/django/db/models/query.py`. … PO-5 requires
  > public `ordered` introspection to use the same grouped-query sentinel … The
  > edit changes the default-ordering branch from `not self.query.group_by` to
  > `self.query.group_by is None`."*
  > — [`reports/fvk_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/fvk_notes.md#L13)

The causal chain is fully on the record:

```
INTENT item 5  ->  E3/E4 (code audit: group_by is None is the documented sentinel)
               ->  PO-5  (obligation: ordered must use the same sentinel)
               ->  F2    (V1 audit: ordered still on `not self.query.group_by`)
               ->  ITERATION_GUIDANCE / fvk_notes  ->  query.py hunk
```

The resulting second hunk realigns the property
([`solution_fvk.patch`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_fvk.patch#L9)):

```python
-            not self.query.group_by
+            self.query.group_by is None
```

The `V1 -> V2` transition was driven by `F2`/`PO-5`, **not** by a new failing
test — the prompt forbids running or adding tests, and no test for the
introspection mismatch exists in the run.

## 5. Verification

**Evidence tier: source-and-artifact reviewed; not executed.** This is a
non-curated case: there is no `verified500_analysis/django__django-14122`
directory, no harness RED/GREEN proof reports, and no gold patch to diff against.
The prompt also explicitly forbids any execution environment — no Python, Django
tests, or K tooling were run
([`prompts/fvk.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/prompts/fvk.md#L27)).

What was inspected to confirm the residual defect and the fix:

- the two solution patches, byte-compared:
  [`diff baseline fvk`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_fvk.patch)
  shows the FVK arm shipped baseline's compiler hunk **plus** the `query.py`
  `ordered` hunk — a real, non-empty code delta;
- baseline's own
  [decision note](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/baseline_notes.md#L33)
  confirming it deliberately did not touch `QuerySet.ordered`;
- the FVK chain INTENT-5 → E3/E4 → PO-5 → F2 → iteration guidance → `fvk_notes`,
  each entry linked in §3–§4, which independently motivates the second hunk.

Both arms were recorded as resolved by the official SWE-bench evaluation per the
run manifest
([`manifest.json`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/manifest.json#L7)),
so the extra hunk did not regress the reported case. No behavioral demonstration
table is claimed because none was executed in this run.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect is an introspection inconsistency:
  `QuerySet.ordered` could return `True` for a grouped, default-ordering-only
  query whose `group_by` is a non-`None` falsy state. Its trigger breadth is
  narrow (an explicit empty-tuple `group_by` reaching the public property) and
  its blast radius is small — it affects what `ordered` *reports*, not the SQL
  that is *executed*. The value demonstrated here is **completeness of the
  audit** (one sentinel, every reader), not impact magnitude — sell the method,
  not the bug.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`django-14122-spec.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/django-14122-spec.k),
  [`mini-django-compiler.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/mini-django-compiler.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PROOF.md#L74),
  [finding F3](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/FINDINGS.md#L62)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations discharged by construction), **not a machine-checked proof**.
- **Attribution.** This is a non-curated case, so there is no gold patch to
  confirm whether the upstream maintainers also realigned `QuerySet.ordered`;
  the gold comparison is by reasoning only. The `V1 -> V2` iteration is
  documented across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`;
  the raw ordering can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/transcripts/fvk.jsonl.gz)
  if a reviewer wants the trace.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/prompts/fvk.md#L2) |
| Baseline patch (compiler only) | [`solutions/solution_baseline.patch`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_baseline.patch#L10) |
| Baseline declined to change `ordered` | [`reports/baseline_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/baseline_notes.md#L33) |
| FVK patch (adds `query.py` hunk) | [`solutions/solution_fvk.patch`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/solutions/solution_fvk.patch#L9) |
| Intent item 5 (ordered introspection) | [`fvk/INTENT_SPEC.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/INTENT_SPEC.md#L22) |
| Evidence E3 (no-grouping sentinel) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Evidence E4 (`ordered` comment) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligation PO-5 | [`fvk/PROOF_OBLIGATIONS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PROOF_OBLIGATIONS.md#L49) |
| Finding F2 | [`fvk/FINDINGS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/FINDINGS.md#L33) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace (follow-up edit) | [`reports/fvk_notes.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/reports/fvk_notes.md#L13) |
| Honesty note F3 | [`fvk/FINDINGS.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/FINDINGS.md#L62) |
| Constructed K core | [`fvk/django-14122-spec.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/django-14122-spec.k), [`fvk/mini-django-compiler.k`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/mini-django-compiler.k) |
| Commands written, not run | [`fvk/PROOF.md`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/fvk/PROOF.md#L74) |
| Both arms resolved (run manifest) | [`manifest.json`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/manifest.json#L7) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified015-codex-XC-MINI-PRO-AHP-20260616T034306Z/django__django-14122/transcripts/fvk.jsonl.gz) |
