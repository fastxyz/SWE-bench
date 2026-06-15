# FVK Notes

## Decision

V1 stands unchanged. The audit found that the added line in
`Field.__deepcopy__()` is exactly the source-level operation needed to discharge
the reported aliasing bug.

## Trace to findings and proof obligations

F-001 maps the original bug to PO-1 and PO-4: copied form fields shared the same
`error_messages` dictionary. V1 discharges those obligations by assigning
`result.error_messages = copy.deepcopy(self.error_messages, memo)` in
`repo/django/forms/fields.py`.

F-002 maps the issue phrase "the error message itself" to PO-2. This rejected a
minimal `dict.copy()` alternative because it would isolate only the top-level
mapping. V1 already uses `copy.deepcopy()`, so no further edit is needed.

F-003 maps the compatibility audit to PO-3 and PO-5. The V1 fix preserves the
existing widget deepcopy, validators list copy, method signature, and subclass
dispatch shape. No compatibility repair is justified.

PO-6 records that there is no loop or recursive control flow in the audited
method, so no circularity or termination edit is required.

## Artifacts

The FVK evidence package is under `fvk/`. The formal core is
`fvk/mini-field-copy.k` and `fvk/field-deepcopy-spec.k`; the proof is
constructed but not machine-checked because the task forbids running K tooling.
