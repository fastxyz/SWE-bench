# Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction. No tests, Python,
K tooling, hidden data, internet, or evaluator artifacts were used.

## F-001: V1 fixes the reported alias-resolution failure

- Type: confirmed V1 obligation discharge
- Evidence: PO-1; issue reports `FieldError` for `book_alice`.
- V1 behavior by inspection: `split_exclude()` copies `_filtered_relations`
  into the fresh inner query before `add_filter()`.
- Expected: the annotation alias is available to `names_to_path()` inside the
  inner query.
- Decision: keep V1 line `query._filtered_relations =
  self._filtered_relations.copy()`.

## F-002: V1 fixes the copy-only filtered-condition loss

- Type: confirmed V1 obligation discharge
- Evidence: PO-2; public hint says copy-only SQL omits the filtered predicate.
- V1 behavior by inspection: when the first trimmed join has a filtered
  relation and the predicate does not depend on trimmed aliases, V1 adds the
  resolved filtered condition to the inner query `WHERE` before trimming.
- Expected: the anti-subquery filters on both the `exclude()` lookup predicate
  and the `FilteredRelation.condition`.
- Decision: keep V1 `trim_start()` predicate-preservation branch.

## F-003: V1's alias-safety guard is justified

- Type: confirmed V1 side condition
- Evidence: PO-3.
- Input class: filtered relation conditions that resolve to columns on an alias
  that `trim_start()` would otherwise remove.
- Risk without guard: moving the predicate into `WHERE` could leave a condition
  referring to an alias no longer present in the subquery.
- V1 behavior by inspection: if the resolved condition aliases intersect the
  aliases to be trimmed, V1 leaves the first join intact.
- Decision: keep the guard.

## F-004: No public compatibility regression found

- Type: compatibility audit result
- Evidence: PO-4, PO-5, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- V1 behavior by inspection: no signatures, return shapes, public docs, or test
  files change; unfiltered and left-outer trim paths remain framed.
- Decision: no compatibility-driven source edit.

## F-005: Machine checking and tests remain unavailable

- Type: verification environment limitation
- Evidence: task instruction forbids running tests, Python, `kompile`, or
  `kprove`.
- Impact: proof is constructed, not machine-checked; no test-redundancy
  recommendation should be applied.
- Decision: record commands in `PROOF.md`; do not run them.

## Overall audit finding

The FVK audit did not surface a source-code defect in V1. V1 stands unchanged.

