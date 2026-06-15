# FVK Notes

## Summary

The FVK audit confirmed V1's core trailing-group fix and found two residual
issues in `replace_unnamed_groups()` that were not covered by the baseline
patch: duplicated prefixes when replacing multiple unnamed groups, and incorrect
selection of adjacent or later nested unnamed spans. V2 keeps the V1 scanner
changes and adds targeted fixes for those unnamed-group obligations.

## Decisions

### Kept the V1 named scanner change

- Finding: `fvk/FINDINGS.md` F1.
- Obligation: `fvk/PROOF_OBLIGATIONS.md` POB-N1.
- Decision: keep the post-character balance check and `idx + 1` slice in
  `replace_named_groups()`.
- Reason: POB-N1 proves the final closing parenthesis is recorded on the same
  iteration, so no trailing slash or `$` is needed.

### Kept the V1 unnamed scanner change

- Finding: `fvk/FINDINGS.md` F2.
- Obligation: `fvk/PROOF_OBLIGATIONS.md` POB-U1.
- Decision: keep the analogous post-character balance check and exclusive end
  index in `replace_unnamed_groups()`.
- Reason: the public hint explicitly requires the unnamed helper to receive the
  same trailing-group treatment.

### Reworked unnamed reconstruction

- Finding: `fvk/FINDINGS.md` F3.
- Obligation: `fvk/PROOF_OBLIGATIONS.md` POB-U3.
- Decision: replace repeated `pattern[:start] + '<var>'` appends with a moving
  `prev_end` cursor that appends only `pattern[prev_end:start]` and `<var>` for
  each selected group.
- Reason: F3 showed that V1 duplicated the original prefix for a second
  top-level unnamed group. POB-U3 requires each non-group segment to be copied
  exactly once.

### Reworked unnamed outermost filtering

- Finding: `fvk/FINDINGS.md` F4.
- Obligation: `fvk/PROOF_OBLIGATIONS.md` POB-U2.
- Decision: select a candidate unnamed span when `prev_end is None or
  start >= prev_end`, and update `prev_end` only for selected spans.
- Reason: F4 showed that V1 skipped adjacent groups and could select a later
  nested group after updating `prev_end` for an earlier skipped nested span.
  POB-U2 requires selected spans to be outermost, non-overlapping, and adjacent
  when their boundaries touch.

### Left public surfaces unchanged

- Finding: `fvk/FINDINGS.md` F5.
- Obligation: `fvk/PROOF_OBLIGATIONS.md` C1.
- Decision: do not change function signatures, imports, return types, or
  `simplify_regex()` call order.
- Reason: the issue is localized to helper loop logic. Compatibility audit C1
  found no public-surface change was needed.

## Verification limits

No tests, Python code, `kompile`, `kast`, or `kprove` were run. The FVK proof is
constructed but not machine-checked, as recorded in `fvk/PROOF.md`. Test files
were not modified.
