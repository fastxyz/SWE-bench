# FVK Notes

## Source Decision

I kept the V1 source code unchanged. The audit did not surface a source defect:
`fvk/FINDINGS.md` F-001 shows the original issue is fixed by the multi-column
message branch, and `fvk/PROOF_OBLIGATIONS.md` PO-005 discharges that branch for
the reproduction state `['time', 'flux']` vs `['time']`.

## Decisions Traced to FVK Artifacts

- Multi-column failures continue to use list-shaped wording. This follows from
  `fvk/FINDINGS.md` F-001 and F-004, and from
  `fvk/PROOF_OBLIGATIONS.md` PO-005.
- Single-column failures keep the legacy scalar wording. This follows from
  `fvk/FINDINGS.md` F-003 and from `fvk/PROOF_OBLIGATIONS.md` PO-004 and
  PO-008.
- The prefix validity predicate remains unchanged. This follows from
  `fvk/FINDINGS.md` F-002 and from `fvk/PROOF_OBLIGATIONS.md` PO-001, PO-002,
  PO-006, and PO-007.
- No public API or dispatch changes were made. This follows from
  `fvk/PROOF_OBLIGATIONS.md` PO-008.
- No tests or code were run, and no test deletion is recommended. This follows
  from `fvk/FINDINGS.md` F-005 and `fvk/PROOF_OBLIGATIONS.md` PO-009.

## Artifact Decisions

The FVK docs request a machine-checkable core and exact verification commands.
In addition to the five required Markdown artifacts, I wrote supporting K-style
files at `fvk/mini-required-columns.k` and `fvk/required-columns-spec.k`, and
listed the not-run commands in `fvk/PROOF.md`. `fvk/FINDINGS.md` F-005 records
the proof-status limitation, and `fvk/PROOF_OBLIGATIONS.md` PO-009 records the
honesty-gate obligation.

## Rejected Changes

I rejected a broader refactor that would normalize all messages to list-shaped
wording. `fvk/FINDINGS.md` F-003 identifies the single-column wording as a
compatibility frame condition, and `fvk/PROOF_OBLIGATIONS.md` PO-004 discharges
the scalar-message branch.

I rejected helper extraction or other cleanup in `_check_required_columns()`.
`fvk/PROOF_OBLIGATIONS.md` PO-001 through PO-007 are already discharged against
the localized V1 source, so a refactor would add risk without addressing a
finding.
