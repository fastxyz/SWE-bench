# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged. Findings F-1 and F-2 and proof obligations PO-1 through PO-6
show that the reported defect is removed by localizing feature-name indexing to
the split-node branch.

## Recommended tests for maintainers

Do not edit tests in this benchmark task. For a normal upstream patch, add or
keep tests covering:

1. `export_text` on a one-feature fitted classifier with a one-element
   `feature_names` list.
2. The same one-feature tree with `feature_names=None`, ensuring generic
   `feature_0` labels still appear for split nodes.
3. Wrong-length `feature_names`, ensuring the existing `ValueError` still
   occurs before traversal.
4. A truncated tree path, ensuring truncation output remains unchanged and does
   not require feature-name selection for the truncated node.

After the emitted `kompile` and `kprove` commands are actually run and return
`#Top`, the first two tests are candidates for proof-subsumption. Until then,
all tests should be kept.

## Next FVK step

A deeper FVK pass could model the full text report, including exact indentation,
threshold formatting, class/value formatting, and traversal order. That is
outside the issue-specific proof because V1 does not change those contributors.

