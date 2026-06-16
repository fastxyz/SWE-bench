# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbol

`sklearn.tree.export.export_text`

## Signature

Unchanged:

`export_text(decision_tree, feature_names=None, max_depth=10, spacing=3, decimals=2, show_weights=False)`

## Return type

Unchanged: the function returns a string report.

## Public callsites and dispatch

The V1 source change is internal to `export_text` and does not add parameters,
change virtual dispatch, alter an override contract, or change a producer/
consumer data shape. Existing callers continue to pass the same arguments.

## Compatibility result

Pass. The change only moves feature-name indexing from an eager all-node list
comprehension into the already-existing split-node branch. Validation behavior
for wrong-length `feature_names` remains unchanged.

