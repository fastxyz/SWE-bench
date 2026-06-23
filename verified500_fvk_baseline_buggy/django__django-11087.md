# django__django-11087

## Summary

**Severity:** Medium — the baseline applies the delete-only field projection to
the admin `NestedObjects` display collector, a path whose contract is to load
full objects for the deletion-confirmation page; a valid admin path can render
partially-loaded objects, but no general data loss or query corruption follows,
so it is Medium, not High.

Both arms passed the official SWE-bench evaluation for this issue, with
**different** patches. The baseline optimized the deletion collector to fetch
only required concrete fields, but routed that projection through
`Collector.related_objects()` — which the admin display collector inherits — so
the admin confirmation page could receive `only()`-narrowed querysets and then
call `select_related()` on a possibly-deferred connector field. FVK located this
second path by **formalizing "fetch only required fields" as an invariant scoped
to the production delete collector and auditing every collector that shares the
code**, then added an opt-out hook so `NestedObjects` keeps full objects.

| Arm | Required-field projection reaches the admin display collector | Resolved |
|---|---|---|
| baseline | yes — `NestedObjects` inherits the narrowed `related_objects()` | no |
| gold (human oracle) | n/a — official eval resolved; no gold artifact available here | — |
| **fvk** | no — `NestedObjects._can_optimize_delete_queryset()` returns `False` | **yes** |

Official SWE-bench evaluation marked **both** the baseline patch and the FVK
patch as resolved
([results dir](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/)).
That eval covers the reported `UnicodeDecodeError`; it does **not** exercise the
residual admin-collector path FVK closed.

## 1. The issue and the real defect

The task — *"Optimize `.delete()` to use only required fields"* — comes from a
report that `.delete()` selects every concrete field while building the deletion
graph, so a `UnicodeDecodeError` fires for a field (`text_log_error.line`) that
the delete algorithm never uses
([`prompts/fvk.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/prompts/fvk.md#L2);
issue evidence quoted in
[`fvk/SPEC.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L32)
and
[`fvk/SPEC.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L41)).

`Collector.collect()` materialized the root queryset and each cascade queryset
without restricting columns; the collector only needs identity, cascade keys,
field-update batches, and parent links, so selecting every concrete field decoded
unrelated text/blob columns and produced the error
([`reports/baseline_notes.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/baseline_notes.md#L5)).
The user-facing observable that is wrong: deleting a row whose unrelated text
column holds non-decodable bytes raises `UnicodeDecodeError` instead of deleting.

## 2. Baseline's fix — and where it stopped

The [baseline patch](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_baseline.patch)
is a competent, narrowly-correct optimization. It adds `_delete_fields()` to
compute the required attname set (primary key, parent concrete fields, reverse
`foreign_related_fields` including `to_field` targets) and
`_optimize_delete_queryset()` to apply `QuerySet.only(*fields)` when no relevant
signal listener is connected
([`solution_baseline.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_baseline.patch#L16)).
It applies the projection to unevaluated querysets entering `collect()` and to
querysets produced by `related_objects()`
([`solution_baseline.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_baseline.patch#L84)).

Baseline was not careless. Its notes show it deliberately disabled the
optimization for signal-visible models — *"I assumed delete signal receivers may
inspect arbitrary fields, so queryset narrowing is skipped when the model has
relevant signal listeners"*
([`reports/baseline_notes.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/baseline_notes.md#L34))
— and consciously left `bulk_related_objects()` hooks alone
([`reports/baseline_notes.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/baseline_notes.md#L48)).

What it left unmet: the projection is applied in `related_objects()`, and the
admin `NestedObjects` collector subclasses `Collector` and calls
`super().related_objects()` followed by `select_related()`. So the same narrowing
that is safe for production deletion silently reaches the admin
deletion-confirmation page, whose entire purpose is to load full objects for
display. Baseline's signal-listener guard does not cover this case, because the
issue is **which collector**, not **which model**.

## 3. How FVK formally captured the gap

FVK started from a spec scoped to the *production* delete collector, then made the
admin collector an explicit, separately-justified obligation. The decisive intent
item lifts an in-tree code comment into a requirement:

> **E7.** *`NestedObjects.can_fast_delete()` says "We always want to load the
> objects into memory so that we can display them to the user in confirm page."*
> → *Admin deletion preview must not receive the narrowed querysets intended for
> production delete traversal.*
> — [`fvk/SPEC.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L94)

That intent is pinned to a concrete code fact found by source audit — not by the
reported test, which only ever exercises the production path:

> **O5.** *Admin `NestedObjects` is a display collector, not the production delete
> collector; it must opt out of the required-field optimization.*
> — [`fvk/SPEC.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L127)

Which is discharged into a formal obligation naming the exact dispatch mechanism
the fix must use:

> **PO8 — Admin `NestedObjects` opts out of projection.** *The admin display
> collector never receives the new `only()` projection from the base collector.*
> Required evidence includes that *`Collector._optimize_delete_queryset()`
> consults dynamic dispatch through `self._can_optimize_delete_queryset(queryset)`*
> so *`NestedObjects.related_objects()` can call `super().related_objects()` and
> then `select_related()` without a projection conflict.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L148)

This is the crux of FVK's value here: **the second path was located by reasoning
about the invariant's scope, not by observing a failure.** The issue says "delete
collection should not fetch unrelated fields"; FVK scoped that to "the production
delete collector" and then audited the one subclass — `NestedObjects` — that
inherits `related_objects()` but has the opposite contract.

## 4. From formal output to the fix

The completeness audit against the spec raised the finding that names the V1 bug:

> **F1: V1 optimized the admin display collector.** *V1 changed
> `Collector.related_objects()` so `super().related_objects()` could return an
> `only()` queryset … `NestedObjects.related_objects()` received a queryset
> narrowed by `Collector.related_objects()` and then added `select_related()` …
> That could produce partially loaded display objects and can conflict with
> `select_related()` if the relation connector field is deferred.*
> Classification: code bug in V1, fixed in V2. Proof obligations: PO5 and PO8.
> — [`fvk/FINDINGS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L6)

The iteration guidance turned that finding into the V2 instruction:

> *1. Add `Collector._can_optimize_delete_queryset()`* … *2. Override
> `_can_optimize_delete_queryset()` in `NestedObjects`. Justification: F1 showed
> that admin deletion preview calls `super().related_objects()` and then
> `select_related()`, and its existing `can_fast_delete()` comment requires loaded
> objects for display.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting change and its provenance:

> **Disabled projection for admin `NestedObjects`.** *Override
> `_can_optimize_delete_queryset()` … to return `False`. Trace: SPEC E7 …
> FINDINGS F1 describes the V1 failure mode … PO8 proves the override restores
> full querysets for this subclass.*
> — [`reports/fvk_notes.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/fvk_notes.md#L43)

The causal chain is fully on the record:

```
SPEC E7  ->  O5 (admin display collector must opt out)
         ->  F1 (V1 audit: NestedObjects inherits the narrowed related_objects)
         ->  PO8 (obligation: opt out via self._can_optimize_delete_queryset dispatch)
         ->  ITERATION_GUIDANCE / fvk_notes decision  ->  V2 patch
```

The [V2 patch](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch)
introduces the dynamic-dispatch hook on the base collector
([`solution_fvk.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch#L66))
and overrides it in `NestedObjects` to return `False`
([`solution_fvk.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch#L9)):

```python
# django/contrib/admin/utils.py
def _can_optimize_delete_queryset(self, *args, **kwargs):
    return False
```

A second, smaller finding (F2) was discharged in the same revision: V1 expanded
an unordered `set` into `only()`, so V2 returns the required fields in
`opts.concrete_fields` order
([`fvk/FINDINGS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L46),
discharging
[PO7](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L132);
patch hunk
[`solution_fvk.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch#L55)).

The `V1 -> V2` transition was driven by the **formal finding F1/PO8**, not by a
new failing test — the benchmark forbids running or adding tests, so no test for
the admin path exists in this run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run had no
execution environment: the FVK prompt explicitly forbids running tests, Python,
or K tooling
([`prompts/fvk.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/prompts/fvk.md#L26)),
and there is no harness RED/GREEN report and no behavioral demonstration for this
instance. What was inspected to confirm the fix:

- The two patches
  ([baseline](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_baseline.patch),
  [fvk](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch)):
  the baseline routes projection through `related_objects()` with no collector
  opt-out; the FVK patch adds `_can_optimize_delete_queryset()` and the
  `NestedObjects` override, so the admin subclass falls through to the unchanged
  queryset.
- The obligation set
  ([`fvk/PROOF_OBLIGATIONS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L148))
  and the constructed proof
  ([`fvk/PROOF.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF.md#L72),
  Lemma L5) covering the admin/signal opt-out.

**Official eval scope.** The official SWE-bench evaluation resolved both arms,
which establishes that the FVK patch does not regress the reported behavior. It
does **not** verify the residual admin-collector defect, because the public
test set exercises the production delete path, not the admin confirmation page.

**Gold comparison (prose only; no gold artifact in this run).** No gold patch
file is available here, so this is reasoned from the patch deltas: the residual
defect lives entirely on the admin side, which the production-focused regression
test would not catch — consistent with both arms passing official eval while only
the FVK arm closes the admin path.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is moderate: it requires the admin
  deletion-confirmation flow over a cascading relation, where a narrowed queryset
  then calls `select_related()` on a possibly-deferred connector field. A valid
  admin path can behave incorrectly (partially-loaded display objects / a
  `select_related` conflict), but the defect does not generally lose data or
  silently corrupt query results
  ([Rating Rationale, prior doc]; mirrors
  [`fvk/FINDINGS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L25)).
  So it is Medium, not High.
- **Proof status: constructed, not machine-checked.** The K artifacts and the
  `kompile`/`kast`/`kprove` commands were *written but never run* — the artifacts
  say so explicitly
  ([`fvk/PROOF.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF.md#L1),
  [`fvk/PROOF_OBLIGATIONS.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L185)).
  We claim **proof-structured reasoning** (a spec with obligations discharged by
  static inspection), **not** a machine-checked proof.
- **Accepted residual boundaries.** FVK records three boundaries it did *not*
  close and justifies each as outside the public issue's evidence: generic
  relation `bulk_related_objects()` hooks
  ([F3](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L80)),
  query annotations / `extra(select=...)`
  ([F4](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L113)),
  and custom `on_delete` callables that read deferred fields
  ([F5](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L150)).
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the raw ordering can be recovered
  from
  [`transcripts/fvk.jsonl.gz`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/transcripts/fvk.jsonl.gz)
  if a reviewer wants the unedited trace. No gold patch is available in this
  non-curated run, so the gold comparison is reasoned, not artifact-backed.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/prompts/fvk.md#L2) |
| Issue evidence (optimize / UnicodeDecodeError) | [`fvk/SPEC.md#L32`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L32), [`fvk/SPEC.md#L41`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L41) |
| Root cause | [`reports/baseline_notes.md#L5`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/baseline_notes.md#L5) |
| Baseline patch | [`solution_baseline.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_baseline.patch#L16) |
| Baseline reasoning (signal opt-out) | [`reports/baseline_notes.md#L34`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/baseline_notes.md#L34) |
| FVK patch | [`solution_fvk.patch`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/solutions/solution_fvk.patch#L9) |
| Intent E7 | [`fvk/SPEC.md#L94`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L94) |
| Obligation O5 | [`fvk/SPEC.md#L127`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/SPEC.md#L127) |
| Proof obligation PO8 | [`fvk/PROOF_OBLIGATIONS.md#L148`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L148) |
| Obligation PO7 (ordering) | [`fvk/PROOF_OBLIGATIONS.md#L132`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L132) |
| Finding F1 (admin path bug) | [`fvk/FINDINGS.md#L6`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L6) |
| Finding F2 (ordering) | [`fvk/FINDINGS.md#L46`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L46) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (admin opt-out) | [`reports/fvk_notes.md#L43`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/reports/fvk_notes.md#L43) |
| Constructed proof (Lemma L5) | [`fvk/PROOF.md#L72`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF.md#L72) |
| Proof not machine-checked | [`fvk/PROOF.md#L1`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF.md#L1), [`fvk/PROOF_OBLIGATIONS.md#L185`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/PROOF_OBLIGATIONS.md#L185) |
| Residual boundaries F3–F5 | [`fvk/FINDINGS.md#L80`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L80), [`fvk/FINDINGS.md#L113`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L113), [`fvk/FINDINGS.md#L150`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/fvk/FINDINGS.md#L150) |
| No-exec constraint | [`prompts/fvk.md#L26`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/prompts/fvk.md#L26) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/transcripts/fvk.jsonl.gz) |
| Both arms resolved (official eval) | [results dir](../results/verified003-codex-XC-MINI-PRO-AHP-20260615T162338Z/django__django-11087/) |
