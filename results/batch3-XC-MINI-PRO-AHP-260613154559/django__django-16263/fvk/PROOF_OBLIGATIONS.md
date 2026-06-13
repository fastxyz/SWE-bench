# PROOF_OBLIGATIONS.md — django-16263

Verification conditions the V2 fix must satisfy, each tied to a `SPEC.md`
contract and a `FINDINGS.md` entry. Status legend: **DISCHARGED** (argued in
`PROOF.md` via the mini-ORM model + Z3-class reasoning), **DISCHARGED (no-op)**,
**ESCALATION BOUNDARY** (specified, routed to a deeper semantics; not
machine-checked here).

All obligations are checked against the master postcondition
**CONTRACT-COUNT** `count() == len(list(qs))` / **CONTRACT-EXISTS**
`exists() == (len(list(qs)) > 0)` (SPEC §0).

---

## PO1 — Count preservation under stripping  *(⇐ SPEC STRIP-PRESERVES-COUNT, STRIPPABLE; FINDINGS F1, F6)*

**Claim.** For each alias `a` that `_strip_unused_annotations` removes,
`rowcount(strip(a, Q)) = rowcount(Q)`; hence over the whole `unused` set,
`rowcount(Q') = rowcount(Q)`.

Case split on `_annotation_is_strippable(Ann[a])` (the only aliases removed):

- **PO1a — aggregate (`is_agg`)**: `Ann[a]` forced `G ∈ {BYPK, BYTUPLE}`
  (set by `annotate()`). Sub-cases after the full strip pass:
  - all aggregates removed and no other existing annotation ⇒ `get_aggregation`
    else-branch ⇒ `G` flag present but empty SELECT ⇒ no GROUP BY emitted ⇒
    `rowcount = B`. The pre-strip grouped value was `BYPK ⇒ B`. **Equal.**
  - some annotation kept ⇒ subquery path, grouping preserved (`BYPK`/`BYTUPLE`).
    Removing `a`'s join cannot change the number of groups because grouping is
    by base-pk (or a kept tuple) and the removed join was multi-valued —
    collapsed by the grouping. **Equal.**
  **Status: DISCHARGED** (PROOF.md §4.1).

- **PO1b — base-only non-aggregate** (`cols(Ann[a]) ⊆ {base, ⊥}`): `strip`
  removes no join (`_unref_annotation_joins` only walks non-base aliases; there
  are none) and does not touch `G`. Therefore `J`, `G` unchanged ⇒
  `rowcount` unchanged. **Status: DISCHARGED (PROOF.md §4.2).**

- **PO1c — excluded class (non-aggregate with a join): NOT stripped.** V2 gate
  returns `False`, so such `a` never enters `unused`; `Q` is unchanged for it.
  This is the V1 bug (F1) closed by construction. **Status: DISCHARGED by
  exclusion.**

## PO2 — Reference completeness  *(⇐ SPEC REF-COMPLETE; FINDINGS F2, F3, F4)*

**Claim.** `_get_referenced_annotation_aliases` returns `R ⊇ Ref_true`, where
`Ref_true` = annotations whose removal could change the result.

Reference sites enumerated and covered:
- WHERE/HAVING: `self.where.get_source_expressions()` — by-`Ref`, by-`F`, and
  **by object identity** (filters embed the annotation object). ✓
- GROUP BY tuple: scanned (string refs and expression refs). ✓
- ORDER BY: string names (`-` stripped) and expressions. ✓
- **DISTINCT ON** (`self.distinct_fields`): scanned (V2 fix, F2). ✓
- Added summaries / unselected annotations: seeded via `extra_exprs`. ✓
- Transitive annotation→annotation: fixed-point closure. ✓
- Raw `extra()` SQL: **ESCALATION BOUNDARY** (F4) — opaque strings; cannot be
  proven complete. Over-approx elsewhere keeps the *direction* safe except for
  this documented gap.

**Status: DISCHARGED** for ORM-object reference sites; **ESCALATION BOUNDARY**
for raw `extra()`.

## PO3 — Join-unref exactness  *(⇐ SPEC UNREF-EXACT; FINDINGS PD3)*

**Claim.** `_unref_annotation_joins(a)` decrements `refcnt` by exactly the
amount `a` contributed; a join reaches `0` iff no surviving clause references
it.

- Each `Col` is produced by one `setup_joins` call, which `ref`s every alias on
  that column's path exactly once (`join()` → `table_alias`/`ref_alias`, +1
  each). Walking `col.alias → parent_alias → …` (stop before base) unrefs each
  once ⇒ per-column exact; summed over `_gen_cols(a)` ⇒ exact for `a`.
- Shared joins keep other clauses' refs (refcnt stays > 0).
- **Reachability of risky inputs:** `_gen_cols` does not descend into nested
  `Query` (`Subquery`) — `Query.get_source_expressions()` inherits `[]`. After
  the V2 gate, `_unref_annotation_joins` is only ever called on **aggregates
  with joins** or **base-only** annotations; a `Subquery`/`Exists` annotation is
  non-aggregate with no outer cols ⇒ base-only ⇒ unref is a no-op. So no alias
  outside `self.alias_refcount` is ever touched (also guarded by
  `alias in self.alias_refcount`).
**Status: DISCHARGED (PROOF.md §4.3).**

## PO4 — No regression / valid query on out-of-scope shapes  *(⇐ FINDINGS F8, F9)*

- `aggregate()` path: `get_aggregation` body reverted to base commit; stripping
  lives only in `get_count`. **Unchanged.** ✓
- combinator (UNION/…): `_strip_unused_annotations` early-returns; `exists()`
  keeps original expansion. **Unchanged.** ✓
- no user annotations / `Book.objects.count()`: `unused` empty ⇒ early return ⇒
  identical to base commit. ✓
- `set_annotation_mask` clears `_annotation_select_cache`; `__count` always
  remains selected so `get_aggregation`'s `["__count"]` lookup is well-defined.
**Status: DISCHARGED (PROOF.md §4.4).**

## PO5 — Exists preservation  *(⇐ SPEC EXISTS; FINDINGS F7)*

**Claim.** `exists()` returns `rowcount(Q) > 0` before and after the GROUP BY
drop.

- Only triggers when `G = True` (an aggregate was added). Drop happens iff no
  *referenced aggregate* exists (no HAVING needs the grouping).
- `rowcount(Q) > 0 ⇔ B > 0` (annotation joins are LEFT, preserving base rows;
  grouping a non-empty relation is non-empty) `⇔ rowcount(drop_groupby(Q)) > 0`.
- HAVING case: a referenced aggregate ⇒ GROUP BY kept (original expansion) ⇒
  HAVING semantics preserved.
**Status: DISCHARGED (PROOF.md §4.5).**

## PO6 — Termination of the reference closure  *(⇐ SPEC CLOSURE; FINDINGS PD4)*

**Claim.** The `while to_process` worklist loop terminates and computes the
least closed set.

- Measure `μ = |annotations| − |seen|` ∈ ℕ; each iteration either pops without
  growth (μ unchanged but `to_process` shrinks) or pushes a *new* alias
  (`alias not in seen`), strictly increasing `|seen|`, strictly decreasing `μ`.
  Pushes are bounded by `|annotations|`; pops by total pushes. ⇒ terminates.
- Partial-correctness (it reaches the least fixed point) follows from the
  monotone closure under `_gen_annotation_refs`.
**Status: DISCHARGED (PROOF.md §4.6).** (Note: FVK default is partial
correctness; termination is proved here because the measure is trivial.)

## PO7 — Adequacy of the mini-ORM abstraction  *(⇐ SPEC §1)*

**Claim.** `rowcount(Q)` as modelled equals the row count of the SQL Django
compiles for `Q` (so reasoning in the model transfers).

This equates the abstraction with Django's real GROUP BY / LEFT JOIN / DISTINCT
ON / subquery-count semantics and the compiler's FROM-from-refcount rule.
Argued informally in PROOF.md §6 and cross-checked against the existing test
suite's expected count values; **not** machine-checked against a full SQL-in-K
semantics.
**Status: ESCALATION BOUNDARY** (specified, routed; never `[trusted]`-faked).
