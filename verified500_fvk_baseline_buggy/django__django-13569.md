# django__django-13569

## Summary

**Severity:** High — baseline's order-by `GROUP BY` rewrite silently drops a
correlated multivalued `Subquery` from `GROUP BY`, changing aggregate semantics
for any query that orders by such a subquery, so the trigger is a whole class of
queries rather than one syntactic corner.

Baseline and FVK both passed the official SWE-bench evaluation for this ticket,
with **different** patches. Fixing the reported `order_by('?')` random-ordering
case, baseline replaced the order-by grouping append with a narrowed predicate —
keep only column references or `RawSQL` — which is **over-broad**: a correlated
subquery used in `order_by()` is neither, so baseline **drops it from `GROUP BY`**,
a regression baseline itself introduced. FVK located this by **formalizing
"column-dependent ordering must keep grouping" as an invariant and auditing how
`Subquery.get_group_by_cols()` encodes that dependency** — not by running a new
test — then added a `get_external_cols()` branch that restores the
original/upstream behavior.

| Arm | [subquery retained in `GROUP BY`](../verified500_analysis/django__django-13569/_materials/problem_statement.md#L19) | Resolved |
|---|---|---|
| baseline | **dropped** (regression) | no |
| gold (human oracle) | **kept** | yes |
| **fvk** | **kept** (matches original/gold) | **yes** |

## 1. The issue and the real defect

The ticket *"order_by('?') unexpectedly breaking queryset aggregation"* reports
that `order_by('?')` (random ordering) is wrongly added to a query's `GROUP BY`,
splitting one aggregate row into two
([`problem_statement.md`](../verified500_analysis/django__django-13569/_materials/problem_statement.md#L19)).
The dumped SQL shows the cause directly:

```sql
... GROUP BY "thing"."id", RANDOM() ORDER BY RANDOM() ASC
```

([`problem_statement.md`](../verified500_analysis/django__django-13569/_materials/problem_statement.md#L23)).
The random call "has nothing to do with the aggregation"
([`problem_statement.md`](../verified500_analysis/django__django-13569/_materials/problem_statement.md#L21)).
The root cause is in `SQLCompiler.get_group_by()`, which folds every
non-reference `order_by` expression into `GROUP BY`:

```python
if not is_ref:
    expressions.extend(expr.get_group_by_cols())
```

For `order_by('?')`, `get_group_by_cols()` yields `Random()`, which gets appended
and pollutes the grouping. The gold fix targets the source expression — it makes
`Random.get_group_by_cols()` return `[]`
([`gold.patch`](../verified500_analysis/django__django-13569/_materials/gold.patch#L8)) —
leaving the compiler's order-by loop untouched, so every other expression that
the loop used to keep stays kept.

## 2. Baseline's fix — and where it stopped

Baseline did not touch the source expression. Instead it
[rewrote the compiler loop](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/solutions/solution_baseline.patch#L9)
to filter what the order-by pass appends — keep a grouping column only if it has
column references or contains `RawSQL`:

```python
for col in expr.get_group_by_cols():
    if (
        col.contains_column_references or
        any(isinstance(source, RawSQL) for source in col.flatten())
    ):
        expressions.append(col)
```

This was a considered choice, not a careless one. Baseline explicitly weighed and
rejected special-casing `Random` ("it would leave the same problem for other
column-free ordering expressions") and rejected changing
`Expression.get_group_by_cols()` globally ("wider behavioral impact, including
SELECT and HAVING grouping paths")
([`baseline_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/reports/baseline_notes.md#L31)).
It kept the `RawSQL` exception on the correct ground that Django "cannot
introspect whether a `RawSQL` fragment references columns"
([`baseline_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/reports/baseline_notes.md#L29)).

The unmet obligation: baseline's predicate enumerates only **two** kinds of
column dependency (direct references, raw SQL). It overlooked a **third** — a
correlated `Subquery` whose dependence on outer columns is carried through
`Query.get_external_cols()`, not through `contains_column_references`. Such a
subquery has `contains_column_references=False` and is not `RawSQL`, so baseline's
filter discards it from `GROUP BY` — exactly the grouping-omission class the
ticket is about, now reintroduced on a different code path.

## 3. How FVK formally captured the gap

FVK started from the issue's own examples lifted into an intent spec, not from the
random-ordering symptom. One example fixes the rule that baseline under-covered:

> **I2. Column-dependent ordering must continue to influence grouping.** … Source:
> `benchmark/PROBLEM.md`. Evidence: `order_by('related')` is described as expected
> to break grouping into two rows. Obligation: *Ordering expressions that depend
> on model columns must still contribute their grouping expressions.*
> — [`fvk/INTENT_SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/INTENT_SPEC.md#L15)

That intent is generalized into the decisive obligation, which names the hidden
form of column dependence:

> **I5. Hidden column dependencies exposed by subqueries must be preserved.** …
> Evidence: `Subquery.get_group_by_cols()` returns `[self]` when external columns
> are possibly multivalued; those external columns are found via
> `Query.get_external_cols()`. Obligation: *A subquery grouping expression …
> must not be treated as column-free merely because `contains_column_references`
> is false.*
> — [`fvk/INTENT_SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/INTENT_SPEC.md#L39)

The evidence ledger pins that intent to a concrete code fact found by **source
audit** — `Subquery.get_group_by_cols()`, not the reported test:

> **E7 | source implementation | `Subquery.get_group_by_cols()` can return
> `[self]` when external cols are possibly multivalued. | Expressions with
> non-empty external columns must be retained. | V1 failed; V2 encoded in
> `KEEP-EXTERNAL-COLS`.**
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13)

Which is discharged into a formal obligation distinct from the random-ordering one:

> **PO4: Subquery External-Column Orderings Are Included.** For any non-reference
> order entry whose group-by column has a flattened source with non-empty
> `get_external_cols()`, the order-by grouping pass appends that column, even if
> direct column-reference metadata is false. Intent trace: E3, E7. Claim:
> `KEEP-EXTERNAL-COLS`.
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PROOF_OBLIGATIONS.md#L33)

This is the crux: the dropped-subquery defect was located by **reasoning over the
invariant**, not by observation. The issue says column-dependent ordering must
keep grouping (I2); the spec recognizes that a subquery encodes that dependence
through external columns rather than `contains_column_references` (I5, E7); so
baseline's two-clause predicate is provably incomplete against PO4.

## 4. From formal output to the fix

The FVK arm audited baseline's patch as "V1" and recorded the exact step where the
formalism changed the code:

- The completeness audit raised a finding against V1:

  > **F1: V1 Dropped Subquery Grouping Expressions With External Columns.** …
  > Observed in V1: the grouping expression was skipped because V1 only retained
  > direct `contains_column_references` expressions or expressions containing
  > `RawSQL`. … Resolution: V2 keeps expressions whose flattened sources expose
  > non-empty `get_external_cols()`. Trace: `PROOF_OBLIGATIONS.md` PO4 …
  > — [`fvk/FINDINGS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/FINDINGS.md#L5)

- The iteration guidance turned the finding into the instruction for V2:

  > Apply the V2 source change justified by F1 and PO4: keep V1's exclusion of
  > column-free order-by grouping expressions; keep V1's raw SQL exception; **add
  > preservation for expressions whose flattened sources expose non-empty external
  > columns through `get_external_cols()`.**
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the resulting change and its provenance:

  > Added the external-column preservation branch. This is justified by
  > `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO4. The source evidence is
  > `Subquery.get_group_by_cols()`, which can return the subquery itself when
  > external columns are possibly multivalued; V1's predicate would have treated
  > that expression as column-free.
  > — [`reports/fvk_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/reports/fvk_notes.md#L29)

The causal chain is fully on the record:

```
INTENT I2/I5  ->  E7 (code audit: Subquery.get_group_by_cols returns [self] on external cols)
              ->  PO4 (obligation: keep order entries with non-empty get_external_cols)
              ->  F1  (V1 audit: baseline's two-clause predicate drops them)
              ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting
[V2 patch](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/solutions/solution_fvk.patch#L17)
adds the third clause to baseline's filter:

```python
isinstance(source, RawSQL) or
(
    hasattr(source, 'get_external_cols') and
    source.get_external_cols()
)
```

The `V1 -> V2` transition was driven by finding **F1 / obligation PO4**, **not**
by a new failing test — the hidden suite never places a subquery in `order_by`
(see §5).

## 5. Verification

**No harness RED/GREEN exists for this case.** There is no
`enhanced_tests/_proof/` directory; the FVK arm explicitly did not run tests,
Python, or K tooling
([`fvk/FINDINGS.md` F3](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/FINDINGS.md#L46)).
Evidence here is the **executed demonstration** carried over from the prior
analysis, plus source/artifact review — it is real execution but **not on the
SWE-bench harness**.

**Behavioral demonstration (executed, Django 3.2 repo checkout).** The query that
places a correlated multivalued subquery in `order_by()`:

```python
Author.objects.annotate(c=Count('book')).order_by(
    Subquery(Author.objects.filter(pk=OuterRef('pk'),
                                    book__name=OuterRef('book__name')).values('pk')))
```

| Variant | subquery in `GROUP BY`? |
|---|---|
| original Django / **gold** | **kept** |
| **baseline** | **dropped** (regression) |
| **fvk** | **kept** (matches original/gold) |

Consequence of dropping a multivalued subquery from `GROUP BY`: on backends that
enforce full-group-by (PostgreSQL, MySQL `ONLY_FULL_GROUP_BY`) the query raises
*"must appear in the GROUP BY clause"*, or where tolerated silently returns
incorrect grouped rows — the exact bug class this ticket is about.

**Why the harness suite missed it.** The hidden suite's multivalued-subquery test
`test_aggregation_subquery_annotation_multivalued` places the subquery in
**select/annotate** (the unmodified path), never in **order_by**
([`tests.json`](../verified500_analysis/django__django-13569/_materials/tests.json#L17)),
so baseline's narrowed order-by filter is never exercised on a subquery and
baseline passes the FAIL_TO_PASS / PASS_TO_PASS set.

**FVK vs. the human oracle.** Gold changes only `Random.get_group_by_cols()`
([`gold.patch`](../verified500_analysis/django__django-13569/_materials/gold.patch#L8)),
leaving the compiler's order-by loop intact — so original and gold both keep the
subquery. FVK reaches the same outcome by a **different mechanism** (an added
compiler-loop branch). GOLD_MATCH: partial — different mechanism, same correct
outcome; baseline regressed, FVK did not.

## 6. Boundaries & honesty

- **Severity: High.** The trigger breadth is a whole **class** of queries — any
  aggregate query that orders by a correlated multivalued subquery — not a single
  syntactic corner case, and the failure mode is a hard error or silently wrong
  grouped results on full-group-by backends. That breadth and the silent-data /
  hard-error consequence place it at High per the rubric. Note this is a
  regression **baseline itself introduced**: the original code and gold both keep
  the subquery; only baseline's over-broad predicate drops it.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-groupby.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/mini-django-groupby.k),
  [`django-groupby-spec.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/django-groupby-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PROOF.md#L5)).
  We claim **proof-structured reasoning** (a formal spec with obligations
  discharged by construction), **not a machine-checked proof**. The bug-detection
  value does not depend on the unrun `kprove`; the regression is confirmed
  independently by the executed query-SQL demonstration in §5.
- **Attribution and what is reconstructed vs. observed.** The dropped-subquery
  regression and the original→gold→fvk grouping behavior were **observed** by
  executing SQL generation on a real Django 3.2 checkout across all three trees.
  The full-group-by **error** on PostgreSQL/MySQL was **not** run — it is the
  well-known consequence of the confirmed `GROUP BY` omission, not a fresh
  observation. The `V1 -> V2` causal ordering is documented across
  `INTENT_SPEC.md`, `PROOF_OBLIGATIONS.md`, `FINDINGS.md`, `ITERATION_GUIDANCE.md`,
  and `fvk_notes.md`; the raw model trace is in
  [`transcripts/fvk.jsonl.gz`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/transcripts/fvk.jsonl.gz)
  if a reviewer wants the ordering timestamped.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, broken SQL, repro | [`_materials/problem_statement.md`](../verified500_analysis/django__django-13569/_materials/problem_statement.md#L19) |
| Gold patch (`Random.get_group_by_cols` → `[]`) | [`_materials/gold.patch`](../verified500_analysis/django__django-13569/_materials/gold.patch#L8) |
| Baseline patch (narrowed order-by filter) | [`solutions/solution_baseline.patch`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/solutions/solution_baseline.patch#L9) |
| Baseline rejected alternatives | [`reports/baseline_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/reports/baseline_notes.md#L31) |
| Intent I2 (column-dependent ordering keeps grouping) | [`fvk/INTENT_SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/INTENT_SPEC.md#L15) |
| Intent I5 (subquery external-column dependency) | [`fvk/INTENT_SPEC.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/INTENT_SPEC.md#L39) |
| Evidence E7 (code audit of `Subquery.get_group_by_cols`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13) |
| Obligation PO4 (keep external-col order entries) | [`fvk/PROOF_OBLIGATIONS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PROOF_OBLIGATIONS.md#L33) |
| Finding F1 (V1 drops subquery grouping cols) | [`fvk/FINDINGS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/FINDINGS.md#L5) |
| Honesty note F3 (nothing executed in run) | [`fvk/FINDINGS.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/FINDINGS.md#L46) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (added external-col branch) | [`reports/fvk_notes.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/reports/fvk_notes.md#L29) |
| FVK patch (added `get_external_cols` clause) | [`solutions/solution_fvk.patch`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/solutions/solution_fvk.patch#L17) |
| Suite never tests subquery-in-order_by | [`_materials/tests.json`](../verified500_analysis/django__django-13569/_materials/tests.json#L17) |
| Proof status (constructed, not run) | [`fvk/PROOF.md`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/PROOF.md#L5) |
| Constructed K core | [`fvk/mini-django-groupby.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/mini-django-groupby.k), [`fvk/django-groupby-spec.k`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/fvk/django-groupby-spec.k) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified013-codex-XC-MINI-PRO-AHP-20260616T004115Z/django__django-13569/transcripts/fvk.jsonl.gz) |
</parameter>
</invoke>
