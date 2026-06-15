# FVK Notes

## Decision

V1 stands unchanged. No additional production source edits were made after the FVK audit.

## Trace to Findings and Proof Obligations

Finding F1 and proof obligation PO1 are the central repair target. They model `loaddata`/deserialization with `raw=True`, an explicit primary key, a primary-key default, and an existing row. The constructed proof shows V1 keeps `force_insert` false in that state, so `_save_table()` reaches UPDATE and avoids INSERT. This justifies keeping the V1 `not raw` guard.

Finding F2 and PO2 cover the adjacent raw fixture case where the row is absent. They show the same `not raw` guard preserves the historical UPDATE then INSERT fallback instead of suppressing INSERT entirely. No extra code is needed.

Finding F4 and PO3 cover the optimization-preservation requirement. The proof shows non-raw creation with a generated primary-key default still reaches INSERT-only. This is why I did not replace the condition with `not pk_set`: `pk_set` is true for default-generated UUID primary keys after `Model.__init__()`, so that alternative would discard the optimization the public discussion wanted to keep.

Finding F3 and PO4 record the residual limitation: normal non-raw `Sample(pk=existing_pk).save()` still attempts INSERT under V1. The audit does not use that behavior as proof of full backward compatibility. It is kept as an explicit limitation because the public issue discussion accepted the `force_update` workaround for this direct pattern while selecting the raw fixture repair.

Finding F5 and PO5 cover compatibility. V1 does not change signatures or public dispatch, and serializer deserialization still passes `raw=True` through `save_base()` into `_save_table()`. That supports making no further API or callsite edits.

PO6 covers the honesty gate. The FVK proof and K files are constructed but not machine-checked, and the emitted commands are recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`. No tests were run or modified.

## Artifacts Written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-django-save.k`
- `fvk/save-table-spec.k`

The additional `.k` files are present because the FVK documentation says a markdown-only result is not a valid FVK run.
