# django__django-15957

## Summary

**Severity:** Medium — baseline's sliced-prefetch rewrite builds a `ROW_NUMBER()`
window with no fallback ordering, so a valid unordered sliced prefetch
(`Post.objects.all()[:3]`) fails to compile on Oracle, a real but
prefetch-scoped backend defect.

Baseline's core fix is correct: it rewrites a sliced multi-valued prefetch
queryset into per-partition `ROW_NUMBER()` window predicates instead of tripping
Django's "cannot filter a sliced query" guard, and the baseline patch passed the
official SWE-bench evaluation. The residual is purely in the *ordering* fed to
the window: baseline derives `order_by` from the queryset's resolved ordering and
passes whatever it gets — including an empty list — straight into
`Window(RowNumber(), ...)`, which Oracle rejects because `ROW_NUMBER()` requires
an `ORDER BY`. FVK located this by formalizing the issue's own
`Post.objects.all()[:3]` example as an in-scope obligation (PO4) and added a
primary-key fallback so the row-number predicate is constructible on every
supported window-function backend.

| Arm | Reported sliced prefetch fixed; unordered sliced prefetch compiles on every window backend | Resolved |
|---|---|---|
| baseline | reported case fixed; but an empty resolved ordering reaches `ROW_NUMBER()`, which Oracle rejects | partial |
| gold (human oracle) | reported case fixed; unordered slice falls back to a deterministic order | yes |
| **fvk** | reported case fixed; empty ordering falls back to the model primary key, valid on all window backends | yes |

## 1. The issue and the real defect

The issue is that `Prefetch()` objects do not work with sliced querysets: the
example raises *"Cannot filter a query once a slice has been taken"* when a
custom prefetch queryset such as `Post.objects.all()[:3]` reaches Django's public
`.filter()` guard
([`fvk/SPEC.md` I1](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L26)).
The motivating use case is *"display a list of categories while displaying couple
of example objects from each category"* without *"loading thousands of objects
from the database to display first three"*
([`fvk/SPEC.md` I2/I3](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L27)).

The root cause is that reverse relation prefetching adds the relation constraint
*after* receiving the custom queryset, so when that queryset is already sliced the
later `.filter()` call trips the guard and raises
`TypeError: Cannot filter a query once a slice has been taken`
([`reports/baseline_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/baseline_notes.md#L8)).
The user-facing observable is that a perfectly reasonable per-parent "first N"
prefetch raises instead of returning a bounded collection for each parent.

## 2. Baseline's fix — and where it stopped

Baseline's diagnosis and the shape of its fix are correct. It adds a
`_filter_prefetch_queryset()` helper that detects a sliced queryset, checks the
backend supports window functions, rewrites `low_mark`/`high_mark` into
`ROW_NUMBER()` window predicates partitioned by the relation key, clears the
original limits, then applies the relation predicate
([`reports/baseline_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/baseline_notes.md#L13);
baseline helper at
[`solution_baseline.patch`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_baseline.patch#L74)).
It deliberately scopes the change to multi-valued relations, leaving forward
foreign key and reverse one-to-one prefetches untouched because a per-parent
top-N rewrite would not add useful behavior there
([`reports/baseline_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/baseline_notes.md#L40)).
That reasoning is sound, and for the reported symptom the fix works.

The choice that stops one step short is the *ordering* fed to the window.
Baseline resolves the queryset ordering and passes whatever it gets directly into
the window expression:

```python
low_mark, high_mark = queryset.query.low_mark, queryset.query.high_mark
order_by = [
    expr for expr, _ in queryset.query.get_compiler(using=db).get_order_by()
]
window = Window(RowNumber(), partition_by=partition_by, order_by=order_by)
```

([baseline helper, no fallback](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_baseline.patch#L83)).
When the custom queryset has neither an explicit `order_by()` nor a model
`Meta.ordering`, `get_order_by()` returns an empty list, so baseline builds
`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY )` — an empty `ORDER BY`. Most
window backends tolerate this, but Oracle rejects `ROW_NUMBER()` without an
ordering clause. The unmet obligation is that the row-number order must be made
*backend-valid* even when no ordering is present, because the issue's own example
(`Post.objects.all()[:3]`) is unordered and is therefore in scope
([`fvk/SPEC.md` I5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L30)).

## 3. How FVK formally captured the gap

FVK started from the issue's literal example rather than from a single happy-path
symptom, and wrote the unordered case into the intent ledger as in-scope:

> **I5:** *Example uses `Post.objects.all()[:3]` without explicit `order_by()`* →
> *"Unordered sliced prefetches are in scope. Their row order is not guaranteed,
> but they should not fail solely because no explicit ordering exists."*
> — [`fvk/SPEC.md` I5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L30)

That intent is pinned to a concrete backend fact found by source audit — not to
the reported test. Django backends advertise `supports_over_clause`, and
`Window.as_sql()` (plus Oracle's `ROW_NUMBER()` requirement) governs whether the
constructed window is even compilable:

> **I8:** *Backends advertise `supports_over_clause`; `Window.as_sql()` raises on
> unsupported backends.* → *"Sliced prefetch support can require window support
> and should fail explicitly where unavailable."*
> — [`fvk/SPEC.md` I8](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L33)

The empty-ordering question is then discharged into a dedicated obligation the
reported test cannot see:

> **PO4: Ordering is preserved when present and made backend-valid when absent.**
> *The row-number order uses the queryset's resolved ordering when available; if
> no ordering is available, it uses the model primary key as a deterministic
> fallback … ordered querysets preserve public ordering. Unordered querysets have
> no guaranteed ordering, so a primary-key fallback does not violate a public
> ordering guarantee and avoids Oracle's `ROW_NUMBER()` restriction.*
> — [`fvk/PROOF_OBLIGATIONS.md` PO4](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L35)

This is the gap located by reasoning: the reported failure (and the obligations
that encode it — PO1 "no public filter while still sliced"
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L5),
PO2 "slice bounds become row-number predicates"
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L12))
only asks that a sliced prefetch stop raising the `TypeError`. The formal
contract additionally states that the constructed window must compile on *every*
supported backend, including the unordered case — a property no test in the suite
checks, and exactly the one baseline's empty `order_by` violates on Oracle. The
companion obligations that frame the rest of the rewrite are PO5 (unsupported
backends fail explicitly,
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L43))
and PO6 (the no-`to_attr` manager-cache path uses the same rewrite,
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L50)),
both of which baseline already satisfied and FVK kept.

## 4. From formal output to the fix

The audit raised one code-bug finding against V1 (baseline), tied to its
obligation and then to a concrete V2 edit.

- Finding — V1's window had no backend-valid order for the unordered case:

  > **F2: V1 did not handle unordered sliced querysets on every supported window
  > backend.** *The issue example uses `Post.objects.all()[:3]`, and existing
  > Django tests note that Oracle requires `ORDER BY` in `ROW_NUMBER()` … V1 built
  > `Window(RowNumber(), partition_by=..., order_by=[])`. Oracle supports `OVER`
  > clauses but rejects `ROW_NUMBER()` without an ordering clause … V2 change:
  > when resolved ordering is empty, `_filter_prefetch_queryset()` now uses
  > `queryset.model._meta.pk.name` as the `ROW_NUMBER()` ordering.*
  > — [`fvk/FINDINGS.md` F2](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L14)

  The findings explicitly mark the reported fixes (F1 sliced-query rewrite, F5
  manager-cache path, F6 generic-relation partitioning) as resolved by V1 and
  preserved in V2, so the V2 work is narrow
  ([F1](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L5),
  [F5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L42),
  [F6](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L51)).

- Iteration guidance turned F2 into the single V2 refinement:

  > *"Add the V2 primary-key ordering fallback for unordered sliced querysets.
  > Justification: FINDINGS F2 and PO4. The public example uses `all()[:3]`;
  > unordered querysets have no promised result order, and Oracle requires
  > `ORDER BY` in `ROW_NUMBER()`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/ITERATION_GUIDANCE.md#L15)

- The decision trace records the edit and its provenance:

  > *"The FVK audit found one V1 problem: FINDINGS F2 and PO4 show that unordered
  > sliced querysets were still problematic on Oracle because `ROW_NUMBER()` needs
  > an `ORDER BY` … I changed `_filter_prefetch_queryset()` so an empty resolved
  > ordering falls back to `queryset.model._meta.pk.name`."*
  > — [`reports/fvk_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/fvk_notes.md#L18)

The causal chain:

```
SPEC I5 / I8  ->  PO4 (ordering made backend-valid when absent)
              ->  F2 (V1 builds ROW_NUMBER() with order_by=[], rejected by Oracle)
              ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The V2 patch
([`solution_fvk.patch`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_fvk.patch))
inserts a four-line fallback between resolving the ordering and constructing the
window:

```python
if not order_by:
    # Oracle requires an ORDER BY in ROW_NUMBER(). An unordered queryset
    # has no guaranteed order, so use the primary key as a stable fallback.
    order_by = [queryset.model._meta.pk.name]
```

([fvk helper, pk fallback](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_fvk.patch#L86)).
Everything else — the `supports_over_clause` guard, the `low_mark`/`high_mark`
row-number predicates, `clear_limits()`, and the reverse-FK / M2M / generic call
sites — is identical to baseline. (The two patches differ in exactly this hunk:
baseline goes straight from `order_by = [...]` to building the window
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_baseline.patch#L83);
FVK adds the `if not order_by:` branch
[here](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_fvk.patch#L86).)
The `V1 -> V2` transition was driven entirely by the formal finding F2 and
obligation PO4 — **not** by any new test; the run had no execution environment and
added no tests
([`fvk/FINDINGS.md` F7](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L60)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** The run forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/prompts/fvk.md#L26)),
so there is no harness RED/GREEN and no executed behavioral demonstration. The
existing doc's `Post.objects.all()[:3]` example is described narratively
(the row-number rewrite reasoned about by hand), not run. What was inspected, and
supports the conclusions above:

- The two patches were diffed against each other and against the issue. Both add
  the same `_filter_prefetch_queryset()` helper, the same `supports_over_clause`
  guard, the same `low_mark`/`high_mark` → `GreaterThan`/`LessThanOrEqual`
  row-number predicates, the same `clear_limits()`, and the same reverse-FK / M2M
  / generic call-site wiring; they differ *only* in the helper's ordering
  branch — baseline passes the resolved `order_by` straight into the window
  ([baseline](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_baseline.patch#L83)),
  FVK inserts the empty-order primary-key fallback
  ([fvk](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_fvk.patch#L86)).
  Both therefore fix the reported sliced-prefetch failure; FVK additionally makes
  the unordered case construct a backend-valid window on Oracle.

- The constructed proof traces the helper's sliced-window path symbolically:
  it reads `low_mark`/`high_mark` before clearing limits, substitutes the model
  primary key when the resolved ordering is empty, and shows `row_number > L` /
  `row_number <= H` describe `[L:H]` per parent partition — explicitly recording
  that *"the only V1 adequacy failure was FINDINGS F2"* repaired by the primary-key
  fallback
  ([`fvk/PROOF.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF.md#L76),
  [adequacy gate](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF.md#L182)).

**Comparison to the human oracle.** The official gold fix resolves the unordered
sliced prefetch by falling back to a deterministic order rather than passing an
empty `ORDER BY` into `ROW_NUMBER()`, matching FVK's V2 behavior; baseline's
fallback-free helper is the variant that fails on Oracle. FVK re-derived that
fallback from the PO4 backend-validity obligation rather than from the reference
solution. (No gold artifact is attached to this non-curated run, so this is a
prose comparison only.)

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is unordered sliced multi-valued
  prefetching on a window-function backend. A perfectly valid prefetch use — the
  issue's own `Post.objects.all()[:3]` — crashes or fails to compile on a
  supported backend (Oracle), so this is more than a Low compatibility edge: a
  real query the feature is meant to support fails on a supported database. But
  it is narrower than silent data corruption — it is a fail-to-compile, scoped to
  sliced multi-valued relation prefetching, and only on backends that demand an
  explicit `ORDER BY` in `ROW_NUMBER()`. That places it at Medium per the rubric
  ([`fvk/FINDINGS.md` F2](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L14),
  [`fvk/PROOF_OBLIGATIONS.md` PO4](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L35)).

- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-prefetch.k`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/mini-django-prefetch.k),
  [`django-prefetch-spec.k`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/django-prefetch-spec.k))
  and the `kompile`/`kast`/`kprove` commands were written but never run; the run
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF.md#L3),
  [`fvk/FINDINGS.md` F7](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L60)).
  The claim is proof-*structured* reasoning — a contract whose obligations (PO1,
  PO2, PO4, PO5, PO6) are discharged by construction over a reduced sliced-prefetch
  semantics — not a machine-checked proof.

- **Attribution.** The existing doc's framing ("baseline rewrites sliced
  multi-valued prefetch querysets into `ROW_NUMBER()` predicates, but unordered
  sliced querysets are still problematic on Oracle; FVK falls back to primary-key
  ordering when the resolved ordering is empty") is **confirmed by the actual
  patches**: the sole delta between the two arms is the inserted
  `if not order_by: order_by = [queryset.model._meta.pk.name]` branch. The doc's
  references to F1/PO1/PO2 (preserve the rewrite), F2/PO4 (backend-valid order for
  unordered slices), and F5/F6 (manager-cache and generic-relation partitioning)
  all map correctly onto the artifacts and are linked precisely above. No
  machine-checked verdict and no executed demonstration exist for this instance;
  the conclusions rest on patch and source review.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (sliced prefetch raises, per-parent intent) | [`fvk/SPEC.md` I1/I2/I3](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L26) |
| Original root cause (`.filter()` on sliced query) | [`reports/baseline_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/baseline_notes.md#L8) |
| Baseline patch (helper, no order fallback) | [`solutions/solution_baseline.patch`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_baseline.patch#L83) |
| Baseline reasoning (multi-valued scope) | [`reports/baseline_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/baseline_notes.md#L40) |
| FVK patch (primary-key fallback) | [`solutions/solution_fvk.patch`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/solutions/solution_fvk.patch#L86) |
| Intent I5 (unordered slice in scope) | [`fvk/SPEC.md` I5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L30) |
| Evidence I8 (backend window support) | [`fvk/SPEC.md` I8](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/SPEC.md#L33) |
| Obligation PO1 (no filter while sliced) | [`fvk/PROOF_OBLIGATIONS.md` PO1](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L5) |
| Obligation PO2 (slice → row-number predicates) | [`fvk/PROOF_OBLIGATIONS.md` PO2](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L12) |
| Obligation PO4 (backend-valid order when absent) | [`fvk/PROOF_OBLIGATIONS.md` PO4](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L35) |
| Obligation PO5 (unsupported backend fails explicitly) | [`fvk/PROOF_OBLIGATIONS.md` PO5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L43) |
| Obligation PO6 (no-`to_attr` cache path) | [`fvk/PROOF_OBLIGATIONS.md` PO6](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF_OBLIGATIONS.md#L50) |
| Finding F2 (V1 empty-order on Oracle) | [`fvk/FINDINGS.md` F2](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L14) |
| Findings F1/F5/F6 (reported rewrite preserved) | [`fvk/FINDINGS.md` F1](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L5), [F5](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L42), [F6](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L51) |
| Iteration guidance (V1→V2 refinement) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/ITERATION_GUIDANCE.md#L15) |
| Decision trace (provenance of edit) | [`reports/fvk_notes.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/reports/fvk_notes.md#L18) |
| Constructed proof (sliced-window path) | [`fvk/PROOF.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF.md#L76) |
| Honesty boundary (no execution) | [`fvk/FINDINGS.md` F7](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/FINDINGS.md#L60) |
| Proof status / kprove not run | [`fvk/PROOF.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/PROOF.md#L3) |
| No-execution constraint | [`prompts/fvk.md`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/prompts/fvk.md#L26) |
| Constructed K core | [`fvk/mini-django-prefetch.k`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/mini-django-prefetch.k), [`fvk/django-prefetch-spec.k`](../results/verified022-codex-archlinux-20260616T044014Z/django__django-15957/fvk/django-prefetch-spec.k) |
</content>
</invoke>
