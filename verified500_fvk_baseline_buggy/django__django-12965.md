# django__django-12965

## Summary

**Severity:** High — baseline's `single_alias` predicate ignores `query.extra_tables`,
so a delete carrying explicit `extra(tables=...)` contributors can be routed through the
direct `DELETE FROM base_table` branch even though that branch emits no `FROM` clause for
those tables; a delete-compiler predicate that under-constrains the SQL shape is a
silent-data-loss class.

Baseline and FVK both passed the official SWE-bench evaluation for `django__django-12965`
with **different** patches. The FVK arm closed two residual gaps baseline left: it widened
the alias-initialization guard from "empty `alias_map`" to "all alias refcounts zero" (the
existing compiler invariant), and it added a frame condition `not self.query.extra_tables`
so a query with extra FROM contributors stays on the fallback path. Both gaps were located
by **lifting the issue into an invariant over the branch decision and auditing the
predicate against the source**, not by running a new test.

| Arm | `single_alias` predicate for `extra(tables=...)` delete | Resolved |
|---|---|---|
| baseline | [direct branch taken — over-broad](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_baseline.patch) | no |
| gold (human oracle) | direct branch taken (no extra-table guard) | no |
| **fvk** | [fallback retained — `not self.query.extra_tables`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_fvk.patch) | **yes** |

## 1. The issue and the real defect

The reported regression: `Model.objects.all().delete()` changed SQL shape between Django
3.0 and 3.1. Django 3.0 emitted a direct `DELETE FROM testapp_alphabet`; Django 3.1 emitted
`DELETE FROM ... WHERE pk IN (SELECT pk FROM same_table)` — a self-subquery that blocks
`LOCK TABLES` and is a performance regression
([`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/prompts/fvk.md#L5),
issue text transcribed in
[`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5)).

The user-facing observable is the generated DELETE SQL. The decision lives in
`SQLDeleteCompiler.single_alias`, a cached property consumed by
`SQLDeleteCompiler.as_sql()`: when true, `as_sql()` calls `_as_sql(self.query)` (the direct
`DELETE FROM base_table` path); when false, the query goes to the primary-key subquery
fallback. The original predicate was a single line:

```python
return sum(self.query.alias_refcount[t] > 0 for t in self.query.alias_map) == 1
```

For an unfiltered `all().delete()` the fast-delete query reaches the compiler with an empty
`alias_map`, so the sum is `0`, the predicate is false, and the query falls to the
self-subquery — the reported bug
([`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_baseline.patch#L9)
added the minimal guard that makes the reported case direct: initialize the base alias when
`alias_map` is empty, then keep the original sum-and-compare:

```python
if not self.query.alias_map:
    self.query.get_initial_alias()
return sum(self.query.alias_refcount[t] > 0 for t in self.query.alias_map) == 1
```

Baseline was deliberate. Its notes reject the broader options — special-casing
`QuerySet.delete()` and "bypassing the fallback whenever the queryset has no `WHERE`
clause" — and settle on the compiler as the right owner of the single-table decision:

> *"I also considered bypassing the fallback whenever the queryset has no `WHERE` clause,
> but rejected that as too broad. The minimal condition is whether the delete query has
> only the base table alias after normal alias initialization."*
> — [`reports/baseline_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/baseline_notes.md#L19)

That reasoning is sound for the reported state but leaves two obligations unmet. First, it
normalizes aliases only when `alias_map` is **empty**, not when `alias_map` is populated but
all refcounts are zero — diverging from Django's own `SQLCompiler.setup_query()` invariant.
Second, and more consequential, the predicate still reasons purely about `alias_map`: a
delete carrying `extra(tables=...)` can normalize to exactly one active alias and take the
direct branch, even though `_as_sql()` emits no `FROM` clause for the extra tables.

## 3. How FVK formally captured the gap

FVK started from an intent item that generalizes the issue past the single reported state to
the **shape** the direct branch is allowed to represent:

> *"A query with explicit `extra(tables=...)` has additional table contributors outside
> `alias_map`; it is not safely representable by the direct `_as_sql()` branch, which only
> emits `DELETE FROM base_table` plus `WHERE`."*
> — [`fvk/INTENT_SPEC.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/INTENT_SPEC.md#L11)

The evidence ledger pins that intent to a concrete code fact found by **source audit** — not
by a failing test:

> **E7 (code):** *`get_from_clause()` appends `query.extra_tables`; `_as_sql()` does not
> emit a `FROM` clause beyond the delete target* → *`extra_tables` must keep the query off
> the direct branch.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11)

Which is discharged into a formal obligation that the predicate must satisfy:

> **PO5 — Extra-table exclusion.** *If `query.extra_tables` is non-empty, direct `_as_sql()`
> is not a valid representation because `_as_sql()` emits no `FROM` clause for those tables.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PROOF_OBLIGATIONS.md#L44)

This is the crux of FVK's value here: the `extra_tables` defect was located by **reasoning
about which table contributors the direct SQL can represent**, not by observing a failure.
The issue asks only for a direct single-table delete; FVK lifts that into a frame condition
over *every* FROM contributor, and the audit (E7) shows `extra_tables` is a contributor the
direct branch silently drops. A parallel chain (intent item 6 → evidence E6 → PO2) captures
the alias-normalization gap.

## 4. From formal output to the fix

There is no per-step `kprove` trace; the artifacts say so plainly. The fix is driven by two
findings against V1 (baseline), each traced to obligations and then to the source edit.

- The completeness audit raised the extra-table finding:

  > **F2: V1 over-broadened direct delete for `extra_tables`.** *`single_alias` initialized
  > the base alias and returned `True`, because it counted exactly one active alias and
  > ignored `extra_tables` … A query with `extra_tables` cannot be safely classified as a
  > direct single-table delete by this branch. Classification: code bug introduced by V1's
  > incomplete predicate.*
  > — [`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/FINDINGS.md#L19)

- The iteration guidance turned the finding into an instruction for the revision:

  > *"F2: `extra_tables` must prevent the direct delete branch."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/ITERATION_GUIDANCE.md#L12)

- The decision log records the resulting edit and its provenance:

  > *"Decision: revise `SQLDeleteCompiler.single_alias` so it returns true only when
  > `active_alias_count == 1 and not self.query.extra_tables`. Trace: `fvk/FINDINGS.md` F2
  > and `fvk/PROOF_OBLIGATIONS.md` PO5-PO6. … Static source audit showed `get_from_clause()`
  > appends `extra_tables`, while `_as_sql()` emits no additional `FROM` clause."*
  > — [`reports/fvk_notes.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/fvk_notes.md#L15)

The causal chain for the extra-table defect:

```
INTENT_SPEC item 5  ->  E7 (code audit: get_from_clause appends extra_tables,
                                _as_sql emits none)
                    ->  F2 (V1 predicate ignores extra_tables -> over-broad direct)
                    ->  PO5 (obligation: extra_tables must force fallback)
                    ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting
[V2 patch](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_fvk.patch#L9)
rewrites the predicate to widen the alias guard (F1) and add the frame condition (F2):

```python
if all(self.query.alias_refcount[a] == 0 for a in self.query.alias_map):
    self.query.get_initial_alias()
active_alias_count = sum(
    self.query.alias_refcount[t] > 0 for t in self.query.alias_map
)
return active_alias_count == 1 and not self.query.extra_tables
```

The `baseline -> fvk` transition was driven by findings **F1/F2** against the formal
obligations, **not** by a new failing test — the run had no execution environment and was
forbidden to add tests, and the fix is justified entirely by the FVK artifacts
([`prompts/fvk.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/prompts/fvk.md#L26)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This run is non-curated: there is no harness
RED/GREEN proof bundle, no gold patch file, and the existing evidence doc carried no executed
demonstration table. The verification here is a static review of:

- the two patches —
  [`solution_baseline.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_baseline.patch)
  vs
  [`solution_fvk.patch`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_fvk.patch)
  — confirming the FVK arm shipped a strictly stronger predicate (baseline:
  `... == 1`; fvk: `... == 1 and not self.query.extra_tables`, plus the widened alias guard);
- the evidence chain E7 → PO5 → F2 against the Django source claims about `get_from_clause()`
  and `_as_sql()` (asserted in the artifacts, not re-run here).

**Gold comparison (prose only, no gold file available).** The gold/upstream fix for this
issue normalized the alias and kept the `single_alias` count test; like baseline, it did not
add an `extra_tables` guard. So FVK's extra-table frame condition goes beyond what the
reported case and the human oracle needed — but it is unverified against a gold artifact in
this run, and the claim that gold omits the guard is reconstructed from the issue, not from a
checked-out gold patch.

## 6. Boundaries & honesty

- **Severity: High (carried over, unchanged).** The rubric ties severity to the breadth and
  consequence of the trigger. The trigger is narrow — it needs a delete query carrying
  explicit `extra(tables=...)` contributors, which is uncommon — but the **consequence
  class** is data-shape: a delete-compiler predicate that ignores extra FROM sources can take
  the direct `DELETE FROM base_table` branch under a weaker condition than the query
  describes
  ([`fvk/FINDINGS.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/FINDINGS.md#L19)).
  That is a potential silent-data-loss class, which is why the carried severity is High even
  though the concrete trigger is narrower than the original `all().delete()` regression.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-delete.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/mini-django-delete.k),
  [`django-delete-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/django-delete-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the FVK
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a formal spec with obligations
  discharged by construction), **not a machine-checked proof**. The `deleteShape` model
  abstracts SQL to a two-valued `direct`/`fallback` shape over active-alias count and
  extra-table presence; it does not prove quoting, parameters, row counts, or
  backend-specific syntax.
- **Attribution.** No harness was run for this instance, so neither the baseline residual
  defect nor the FVK fix is observed end-to-end here; both are established by static patch
  and artifact review. The `extra_tables` over-broadening is real in the baseline patch (the
  predicate has no extra-table guard), but its concrete data-loss impact is reasoned from
  E7/F2, not demonstrated by an executed test. The gold-omits-the-guard comparison is
  reconstructed from the issue text, not from a checked gold patch.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, SQL-shape regression | [`prompts/fvk.md#L5`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/prompts/fvk.md#L5), [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L5`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5) |
| Baseline root cause | [`reports/baseline_notes.md#L5`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/baseline_notes.md#L5) |
| Baseline patch | [`solutions/solution_baseline.patch#L9`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_baseline.patch#L9) |
| Baseline reasoning (rejected broader options) | [`reports/baseline_notes.md#L19`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/baseline_notes.md#L19) |
| FVK patch | [`solutions/solution_fvk.patch#L9`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/solutions/solution_fvk.patch#L9) |
| Intent item (extra_tables not representable) | [`fvk/INTENT_SPEC.md#L11`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/INTENT_SPEC.md#L11) |
| Evidence E7 | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L11`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11) |
| Obligation PO5 | [`fvk/PROOF_OBLIGATIONS.md#L44`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PROOF_OBLIGATIONS.md#L44) |
| Obligation PO2 (alias normalization) | [`fvk/PROOF_OBLIGATIONS.md#L11`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PROOF_OBLIGATIONS.md#L11) |
| Finding F2 (extra_tables over-broadening) | [`fvk/FINDINGS.md#L19`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/FINDINGS.md#L19) |
| Finding F1 (alias invariant) | [`fvk/FINDINGS.md#L5`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/FINDINGS.md#L5) |
| Iteration instruction (F2) | [`fvk/ITERATION_GUIDANCE.md#L12`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/ITERATION_GUIDANCE.md#L12) |
| Decision trace (extra_tables exclusion) | [`reports/fvk_notes.md#L15`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/reports/fvk_notes.md#L15) |
| Constructed K core | [`fvk/mini-django-delete.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/mini-django-delete.k), [`fvk/django-delete-spec.k`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/django-delete-spec.k) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/fvk/PROOF.md#L3) |
| No execution environment / no test edits | [`prompts/fvk.md#L26`](../results/verified010-codex-XC-MINI-PRO-AHP-20260615T215736Z/django__django-12965/prompts/fvk.md#L26) |
