# ITERATION_GUIDANCE.md — django-16263

Actionable feedback from the FVK pass, in the `/verify` Step-3 format
(Evidence · Classification · UltimatePowers question · Recommended change ·
Tests). Items G1–G2 were **applied in V2**; G3–G6 are open
recommendations/risks for a future pass.

---

## G1 — Strip only row-count-neutral annotations  *(APPLIED in V2)*

- **Evidence:** PROOF_OBLIGATIONS PO1 / FINDINGS F1. STRIP-PRESERVES-COUNT's
  postcondition is false on the branch "non-aggregate annotation owning a
  multi-valued join" — `annotate(x=F('authors__name')).count()` returned the
  base count, not `len(qs)`.
- **Classification:** code bug (non-universal postcondition).
- **UltimatePowers question:** "Should `count()` ever differ from `len(qs)`?"
  → No (Django contract). Confirms the postcondition CONTRACT-COUNT.
- **Recommended change (done):** add `Query._annotation_is_strippable` =
  `contains_aggregate ∨ no-non-base-join`, and gate the `unused` set on it.
- **Tests:** would be covered by a count test over a multi-valued non-aggregate
  annotation (e.g. `annotate(x=F('authors__name')).count() == len(qs)`); the
  existing aggregate/base-only count tests remain green.

## G2 — Track DISTINCT ON as a reference site  *(APPLIED in V2)*

- **Evidence:** PO2 / FINDINGS F2. `distinct_fields` was an unscanned reference
  site; a distinct-on annotation could be stripped.
- **Classification:** missing precondition / under-approximation.
- **UltimatePowers question:** "Which clauses may name an annotation?" → WHERE,
  HAVING, GROUP BY, ORDER BY, **DISTINCT ON**, other annotations.
- **Recommended change (done):** add `self.distinct_fields` to the
  string-reference scan in `_get_referenced_annotation_aliases`.
- **Tests:** `annotate(c=Lower('name')).distinct('c').order_by('c').count()`.

## G3 — Optionally strip to-one-join non-aggregate annotations  *(OPEN — optimisation)*

- **Evidence:** FINDINGS F5. The V2 rule conservatively keeps
  `annotate(x=F('publisher__name')).count()` (correct value, non-minimal SQL).
- **Classification:** missed optimisation (not a correctness gap).
- **UltimatePowers question:** "Is the extra subquery for a to-one annotation
  acceptable, or should it also collapse to `SELECT COUNT(*)`?"
- **Recommended change:** refine `_annotation_is_strippable` to also allow
  non-aggregate annotations all of whose introduced joins are **to-one**
  (cardinality-1), using join-field nullability/uniqueness metadata. Only if a
  benchmark/test demands it — it adds join-cardinality inspection complexity.
- **Tests:** keep until a precise multi-valued detector is proven.

## G4 — Machine-check the mini-ORM adequacy (PO7)  *(OPEN — escalation)*

- **Evidence:** PROOF.md §6, PO7. `rowcount` ↔ real SQL semantics is argued,
  not proved.
- **Classification:** proof capability gap / `[ESCALATION BOUNDARY]`.
- **UltimatePowers question:** none for the user; this is a kit-capability item.
- **Recommended change:** build/borrow a relational-algebra or SQL-in-K
  semantics for `GROUP BY`, `LEFT JOIN`, `DISTINCT`, `COUNT(*)`-over-subquery
  and re-discharge PO1/PO5 against it; route via
  `fvk_materials/knowledge/sources.md`.
- **Tests:** **keep all count/exists tests** until this closes (they pin the
  very SQL semantics the model assumes).

## G5 — Re-verify F3 identity assumption if call sites change  *(OPEN — watch)*

- **Evidence:** FINDINGS F3 / PROOF §6. Filter-embedded annotation detection
  uses object identity, sound only because `get_count`/`exists` clone exactly
  once and `WhereNode.clone` preserves leaf-lookup identity.
- **Classification:** soundness-relevant assumption.
- **Recommended change:** if stripping is ever invoked from a relabeled or
  repeatedly-cloned query, add a name-based fallback (resolve filter LHS/RHS to
  aliases) or assert the identity invariant.
- **Tests:** a count over a filtered annotation
  (`annotate(c=Count('ch')).filter(c__gt=2).count()`) guards this today.

## G6 — Raw `extra()` reference opacity  *(OPEN — documented limitation)*

- **Evidence:** FINDINGS F4 / PO2. `extra(select=/where=/order_by=)` strings
  are not scanned for annotation references.
- **Classification:** escalation boundary (raw-SQL opacity).
- **UltimatePowers question:** "Should `extra()` interacting with annotated
  `count()` be supported, or documented as undefined?"
- **Recommended change:** none low-risk; standard SQL cannot reference SELECT
  aliases in WHERE, and alias-by-string in `extra_order_by` is unsupported. If
  ever needed, skip stripping entirely when `self.extra` is non-empty.
- **Tests:** none required now.

---

## Summary of state after V2

- **Headline ticket case** (`annotate(Count('chapters')).count()` →
  `SELECT COUNT(*) FROM book`) — works, proven row-count-neutral (PO1a/F6).
- **V1 correctness bug** (multi-valued non-aggregate) — **fixed** (G1/F1).
- **Reference completeness** for ORM-object sites — closed, incl. DISTINCT ON
  (G2/F2).
- **`aggregate()`, combinator, no-annotation, exists** paths — no regression
  (PO4/PO5; F7–F9).
- **Open:** to-one optimisation (G3), model adequacy machine-check (G4), the F3
  identity watch (G5), raw-extra opacity (G6) — none block correctness of the
  count/exists contracts within the stated scope.
