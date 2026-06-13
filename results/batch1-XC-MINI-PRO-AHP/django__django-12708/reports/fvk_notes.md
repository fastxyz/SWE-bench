# FVK notes — audit of the V1 fix for django__django-12708

This records the FVK audit outcome and **traces every decision** to a specific entry
in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

## Outcome: **V1 stands unchanged** (confirm, no source edit)

V1 = `alter_index_together` deletes a composed index with
`{'index': True, 'unique': False}` instead of `{'index': True}`
(`repo/django/db/backends/base/schema.py:396-401`). The audit found **no correctness
defect** and one **positive** secondary effect. Editing anything further would be
scope creep unsupported by the obligations.

## What the audit formalized

The constraint-resolution path: `_constraint_names` (the filtering scan),
`_delete_composed_index` (the `len(constraint_names) != 1` guard), and the two
callers that pick the kwargs. The whole correctness question reduces to one
**set-cardinality** property: *the filter must resolve to exactly one constraint,
and the right one.* See [`fvk/SPEC.md`](../fvk/SPEC.md). Backed by a mini-K fragment
[`fvk/schema_index.k`](../fvk/schema_index.k) + claims
[`fvk/schema_index-spec.k`](../fvk/schema_index-spec.k) (constructed, not
machine-checked — no K toolchain in this environment).

## Decision-by-decision trace

### Decision 1 — Keep the V1 index-filter change `{'index': True, 'unique': False}`
- **Traces to:** OB1 + OB2 (DEL-IDX is exactly-one) and **F3**.
- **Why:** §3 of [`fvk/PROOF.md`](../fvk/PROOF.md) shows
  `cnames(CS,(a,b),idxFilter,EXCL) = {name_idx}`, size 1, **independent of the
  backend flag `IU`** (MySQL/SQLite `IU=True`, PostgreSQL `IU=False`). The unique
  constraint is excluded because `unique=True` fails the `unique=False` test (OB2).
  The fix is correct and backend-uniform.

### Decision 2 — Do **not** modify `alter_unique_together`
- **Traces to:** OB3 + OB4 (DEL-UNIQ already exactly-one) and **F4**.
- **Why:** `{'unique': True}` matches only the unique constraint; the
  `index_together` index has `unique=False` and is excluded (PROOF §4). The unique
  direction was **never** ambiguous, so no change is warranted. **F1** explains the
  asymmetry that makes this so: a unique constraint can report `index=True`, but an
  index never reports `unique=True` — only the index-deletion direction could
  over-match.

### Decision 3 — Confirm there is no regression risk from the added flag
- **Traces to:** OB5 and **F2**.
- **Why:** `matches(C, idxFilter) → matches(C, idxFilterV0)`, so V1's match set is a
  **subset** of the pre-fix set (PROOF §5). Where the old code matched 1 it still
  matches 1; where it matched 2 it now matches 1. V1 cannot create a *new* "too many
  constraints" failure.

### Decision 4 — Treat the reproduced crash as resolved
- **Traces to:** OB7 (and the contrast claim `(DEL-IDX-V0)`).
- **Why:** the pre-fix filter on `IU=True` gives size 2 → the exact reported
  `ValueError("Found wrong number (2) …")` (PROOF §6); V1 collapses it to size 1.

### Decision 5 — Record (do not fix here) the PK-collision edge
- **Traces to:** **F5** and the OB OUT-OF-DOMAIN note.
- **Why:** a `unique_together` declared on the primary-key columns could make the
  *unique* filter match the PK too. It is **pre-existing**, **orthogonal** to this
  fix (V1 only edits the index path), unreachable from the issue's scenario, and
  degenerate. Fixing it (e.g. excluding `primary_key=True`) belongs in a separate
  ticket; see [`fvk/ITERATION_GUIDANCE.md`](../fvk/ITERATION_GUIDANCE.md) item 1.

### Decision 6 — Declare issue "point 2" (index re-creation on a declaration move) out of scope
- **Traces to:** **F6** and the OB OUT-OF-SCOPE note.
- **Why:** moving an index from `index_together` to `Meta.indexes` causing a
  drop+create is **autodetector/optimizer** behavior, not a schema-editor
  cardinality bug — it is churn, not a crash. With V1 the removal half no longer
  crashes (the new Meta index is name-excluded; OB6). The optimization is a distinct
  enhancement (ITERATION_GUIDANCE item 2).

### Decision 7 — Note the bonus safety improvement as supporting evidence
- **Traces to:** OB8 and **F7**.
- **Why:** under DB drift (the `_idx` already gone), the pre-fix filter would
  silently `DROP INDEX` the *unique* constraint (size 1, wrong deletion); V1 yields
  size 0 → a safe `ValueError` (PROOF §6). V1 is strictly safer, never worse —
  additional weight behind "confirm".

## Invariant protected (regression guard)
OB2/OB4 rely on **(INV-I)**: `index_together` builds a *non-unique* index and
`unique_together` a *unique* constraint (the `_create_index_sql(suffix="_idx")` vs
`_create_unique_sql` creation paths). FINDINGS "Proof-derived" notes this: if a
future change made `index_together` build a unique index, the V1 filter would match
size 0 and break. Worth a test pinning that invariant (the suite here is
fixed/hidden, so this is forward guidance only).

## Honesty
Proof is **constructed, not machine-checked**; the only VCs are finite
set-cardinality facts. Test-redundancy advice in [`fvk/PROOF.md`](../fvk/PROOF.md)
§9 is recommendation-only and conditioned on `kprove` returning `#Top`. The
introspection facts (SPEC §2) were read from the backend source, not executed.
