# FVK Notes

Status: FVK audit complete; proof constructed, not machine-checked.

## Decisions

No source changes were made after V1.

Decision D-001: keep the `split_exclude()` copy of `_filtered_relations`.

- Traced to: `fvk/FINDINGS.md` F-001 and
  `fvk/PROOF_OBLIGATIONS.md` PO-1.
- Reason: the public failure is a `FieldError` caused by the fresh inner query
  lacking the filtered relation alias. Copying the mapping before
  `query.add_filter()` discharges that obligation.

Decision D-002: keep the `trim_start()` branch that moves safe filtered
relation conditions into the inner query `WHERE`.

- Traced to: `fvk/FINDINGS.md` F-002 and
  `fvk/PROOF_OBLIGATIONS.md` PO-2.
- Reason: public hints show that fixing only alias resolution leaves incorrect
  SQL/results because the filtered condition is lost when the filtered join is
  trimmed. Moving the condition when its aliases survive trimming preserves the
  intended anti-subquery semantics.

Decision D-003: keep the alias-safety fallback that avoids trimming when the
filtered condition references a trimmed alias.

- Traced to: `fvk/FINDINGS.md` F-003 and
  `fvk/PROOF_OBLIGATIONS.md` PO-3.
- Reason: moving a predicate into `WHERE` is only valid if every alias it uses
  remains available. If not, preserving the join keeps the condition valid in
  its original `ON` clause.

Decision D-004: do not make compatibility or test edits.

- Traced to: `fvk/FINDINGS.md` F-004 and
  `fvk/PROOF_OBLIGATIONS.md` PO-4 and PO-5.
- Reason: the patch changes only internal bodies, preserves signatures and
  return shapes, leaves unfiltered and left-outer behavior framed, and the task
  forbids test modifications.

Decision D-005: do not run tests, Python, `kompile`, or `kprove`.

- Traced to: `fvk/FINDINGS.md` F-005.
- Reason: the task explicitly forbids execution. The proof artifacts record the
  commands for later machine checking instead.

## Outcome

The FVK audit confirms V1 according to the constructed specification and proof
obligations. V1 stands unchanged.

