# FVK Iteration Guidance: django__django-14559

Status: V2 is recommended.

## Source Changes Recommended by FVK

1. Keep the V1 behavioral fix: return `0` for valid empty input and return the
   sum of the batched `update()` return values for non-empty input.
   - Supported by FINDINGS F-1 and F-2.
   - Discharges PO-1, PO-2, and PO-4.

2. Keep the V2 terminology cleanup: use "rows matched" in the docstring and
   `rows_matched` for the accumulator.
   - Supported by FINDING F-3.
   - Discharges PO-1 more precisely against the issue wording.

## Source Changes Rejected by FVK

1. Do not introduce a named tuple or future-proof wrapper return value.
   - Rejected by FINDING F-5.
   - The public issue converged on a plain integer return matching `update()`.

2. Do not add duplicate-primary-key deduplication in this fix.
   - Rejected by FINDING F-4.
   - The public issue explicitly notes this edge case and accepts summing the
     actual batched `update()` returns for this ticket.

3. Do not alter validation ordering or exception behavior.
   - Rejected by FINDING F-6.
   - The issue changes successful return values only.

## Suggested Tests for a Future Test Author

Do not modify tests in this benchmark. A future public test patch could cover:

- valid empty `objs` returns `0`;
- valid single-batch `bulk_update()` returns the row count from one `update()`;
- valid multi-batch `bulk_update()` returns the sum of row counts from each
  batch;
- validation errors remain unchanged;
- duplicate primary keys split across batches follow the accepted sum of actual
  batch update counts, if that behavior needs to be documented.

## Verification Follow-Up

The proof is constructed, not machine-checked. If K artifacts are materialized
from the formal claims in `SPEC.md`, the expected commands are:

```sh
kompile fvk/mini-bulk-update.k --backend haskell
kast --backend haskell fvk/bulk-update-spec.k
kprove fvk/bulk-update-spec.k
```

Until those commands are run and return `#Top`, do not remove tests based on
the proof.
