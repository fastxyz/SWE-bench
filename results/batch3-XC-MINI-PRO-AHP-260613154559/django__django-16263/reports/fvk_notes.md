# reports/fvk_notes.md — FVK audit decisions for django-16263

This explains every V2 decision (each code change, and each part of V1 kept
unchanged), tracing it to `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## How the audit was run

Per `fvk_materials`, I worked in **intent-spec mode**: I wrote a precise
contract for the V1 fix (`fvk/SPEC.md`) and discovered that the governing
postcondition is not the ticket's informal "same as `Book.objects.count()`" but
Django's stronger documented invariant **`count() == len(list(qs))`** /
**`exists() == (len(qs) > 0)`** (SPEC §0). The ORM is far outside the FVK
fast-path, so I built a **mini-ORM** abstraction (SPEC §1, PROOF §1) that keeps
only what determines the row count — base rows, joins with multiplicities,
GROUP BY mode, referenced annotations — and proved the transformation against
it, marking model adequacy as an explicit escalation boundary (PO7).

The act of writing that spec immediately produced the central finding.

## Change 1 — `_annotation_is_strippable` guard (new method + use in `_strip_unused_annotations`)

- **Traces to:** FINDINGS **F1** (critical bug), PROOF_OBLIGATIONS **PO1**,
  ITERATION_GUIDANCE **G1**, proof-derived **PD1**.
- **What V1 did wrong:** `_strip_unused_annotations` stripped *any* unreferenced
  selected annotation. For a non-aggregate annotation over a **multi-valued**
  relation (e.g. `annotate(x=F('authors__name')).count()`), the query is
  ungrouped and the join multiplies rows, so `list(qs)` returns the multiplied
  count. V1 deleted the annotation and its join → `SELECT COUNT(*) FROM book` →
  the base count, breaking `count() == len(qs)`. Writing STRIP-PRESERVES-COUNT
  forced the case split (PD1) that exposed this branch as a non-universal
  postcondition.
- **Fix:** added `Query._annotation_is_strippable(annotation)` returning
  `contains_aggregate OR (no column on a non-base join)`, and gated the `unused`
  set on it. PO1 is now discharged by two safe branches — aggregates (PO1a: the
  forced GROUP BY collapses multiplication) and base-only non-aggregates (PO1b:
  no join removed) — and the dangerous branch (PO1c) is excluded by
  construction. The headline ticket case still collapses to `SELECT COUNT(*)`
  (F6), and the Concat-of-local-fields case from the issue's comments is still
  stripped (base-only).
- **Why this shape (not a precise multi-valued detector):** a to-one join is
  also safe to strip, but detecting to-one vs to-many needs join-cardinality
  inspection; the base-only rule is provably safe and covers every example the
  ticket cites. To-one annotations are kept conservatively (FINDINGS **F5**,
  G3) — correct value, slightly non-minimal SQL.

## Change 2 — scan `self.distinct_fields` in `_get_referenced_annotation_aliases`

- **Traces to:** FINDINGS **F2**, PROOF_OBLIGATIONS **PO2**, ITERATION_GUIDANCE
  **G2**, proof-derived **PD2**.
- **What V1 missed:** the reference-site enumeration for REF-COMPLETE omitted
  `DISTINCT ON`. An annotation used only as a `distinct(*fields)` target was
  classifiable as unreferenced and could be stripped, leaving the DISTINCT-ON
  path referencing a dropped column. Enumerating reference sites while
  discharging PO2 surfaced this (PD2).
- **Fix:** added `self.distinct_fields` to the string-reference scan, alongside
  `order_by`/`group_by`. PO2 is now discharged for all ORM-object reference
  sites.

## What was kept from V1 unchanged — and why it's justified

- **Stripping confined to `get_count` (not `get_aggregation`/`aggregate()`).**
  Kept. FINDINGS **F9**, PO4. `get_aggregation` retains its base-commit body, so
  `QuerySet.aggregate()` is unchanged — protecting tests whose results depend on
  existing-annotation joins. Confirmed by re-reading the reverted method.
- **`_unref_annotation_joins` (join-refcount surgery).** Kept as-is. PO3 / PD3:
  the per-column parent-chain walk exactly matches `setup_joins`' one-ref-per-
  column-path accounting; after the Change-1 gate it is only invoked on
  aggregates-with-joins (real walk, exact) and base-only annotations (no-op),
  and it never descends into nested `Subquery` queries, so it cannot touch an
  alias outside `self.alias_refcount`.
- **`exists()` GROUP BY drop.** Kept. PO5 / FINDINGS **F7**: existence is
  invariant under grouping and LEFT joins, so dropping a HAVING-free GROUP BY is
  row-existence-neutral; the HAVING case keeps the grouping (referenced
  aggregate). No multi-valued bug here because `exists()` does not strip
  annotations, only drops grouping, and `LIMIT 1` over a LEFT-joined relation
  still exists iff the base is non-empty.
- **Combinator early-return.** Kept. FINDINGS **F8**, PO4: pruning is unsafe
  across UNION-aligned SELECTs; skipping matches base-commit behaviour.
- **Identity-based filter reference detection.** Kept. FINDINGS **F3**: sound
  under the single-clone invariant that holds for `get_count`/`exists`;
  documented as a trusted-base item (G5) to re-verify if call sites change.
- **Transitive-reference worklist loop.** Kept. PO6 / PD4: terminates with the
  `seen`-bounded measure `|annotations| − |seen|`.

## Residual risk (honest status)

The proof is **constructed, not machine-checked** (FVK MVP). The mini-ORM
model's fidelity to real SQL `GROUP BY`/`LEFT JOIN`/`DISTINCT`/subquery-count
semantics is an explicit **`[ESCALATION BOUNDARY]` (PO7)**, argued and
cross-checked against the suite's expected counts but not proved against a
SQL-in-K semantics. Consequently **no tests are recommended for removal**
(PROOF §5): the count/exists tests are kept both because `kprove` has not been
run and because several pin the very SQL semantics PO7 depends on.

## Net effect

V1's headline behaviour is preserved (aggregate/base-only annotations stripped
→ `SELECT COUNT(*)`), the V1 correctness regression on non-aggregate
multi-valued annotations is fixed, and the reference detection is completed for
DISTINCT ON. All non-count paths (`aggregate()`, combinators, `exists()`
HAVING, no-annotation) are unchanged.
