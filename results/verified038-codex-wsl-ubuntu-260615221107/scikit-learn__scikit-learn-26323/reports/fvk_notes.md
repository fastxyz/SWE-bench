# FVK Notes

## Decisions

1. Kept the V1 `ColumnTransformer.set_output` change.

   This is justified by F-001 and proof obligations PO-1 through PO-3. The
   issue intent requires estimator-valued `remainder` to receive output
   configuration, and the fit path clones `self.remainder`; configuring only
   explicit transformers is insufficient.

2. Added a V2 change in `repo/sklearn/utils/_set_output.py`.

   This is justified by F-002 and PO-4. V1 made the helper reachable for
   estimator-valued `remainder`, so the helper's documented
   `transform=None` no-op needed to be explicit before checking whether the
   child has `set_output`.

3. Preserved the existing error for unconfigurable transformers when
   `transform` is non-`None`.

   This is required by F-003 and PO-5. The V2 helper edit returns early only
   for `transform is None`; for `"pandas"` or `"default"`, the existing
   `ValueError` path remains.

4. Did not edit tests or run commands.

   The task forbids modifying tests and says no execution environment exists.
   The FVK artifacts therefore include commands and expected outcomes only;
   they are labeled constructed, not machine-checked.

## Changed Files

- `repo/sklearn/compose/_column_transformer.py`: kept V1 propagation of
  `set_output` to estimator-valued `remainder`.
- `repo/sklearn/utils/_set_output.py`: added the `transform is None` early
  return required by PO-4.
- `fvk/`: added the formal spec, findings, proof obligations, constructed
  proof, iteration guidance, adequacy audits, and K artifacts.
