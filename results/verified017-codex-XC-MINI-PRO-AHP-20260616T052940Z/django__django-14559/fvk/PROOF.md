# FVK Proof: django__django-14559

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved in the Reduced Model

BU-EMPTY:

```text
ValidBulkUpdateInput([], fields, batch_size)
  => bulk_update([], fields, batch_size) returns 0
```

BU-SUM:

```text
ValidBulkUpdateInput(objs, fields, batch_size) and objs != []
  => bulk_update(objs, fields, batch_size)
     returns sum(rowcount(u) for u in make_updates(objs, fields, batch_size))
```

BU-LOOP:

```text
For updates = [u_0, ..., u_n], after k loop iterations:
rows_matched = sum(rowcount(u_i) for 0 <= i < k).
```

The model treats each existing `QuerySet.update()` call as returning the integer
row-match count for its batch. This is an abstraction boundary over Django's SQL
compiler and database backend, not a new implementation rule.

## Proof Sketch

1. Existing validation runs before any changed successful return. The V2 patch
   does not change invalid-input branches, so validation failures remain outside
   the normal-return proof domain and satisfy PO-5.
2. If `objs` is empty after tuple conversion, the method returns `0`. This is
   the empty sum and discharges BU-EMPTY and PO-2.
3. For non-empty `objs`, the code computes `max_batch_size`, `batch_size`,
   `requires_casting`, `batches`, and `updates` exactly as before. The patch
   does not alter the construction of primary-key filters or update expressions,
   discharging PO-3.
4. Before entering the transaction loop, `rows_matched = 0`. This establishes
   the loop invariant for `k = 0`.
5. Assume the invariant holds before iteration `k`: `rows_matched` equals the
   sum of row counts from the first `k` batch updates. The loop body performs the
   existing update call for batch `k` and adds its returned integer to
   `rows_matched`. Therefore the invariant holds for `k + 1`.
6. The updates list is finite because it is built from the finite tuple `objs`
   using finite slices. When the loop exits after all batches, the invariant
   yields `rows_matched = sum(rowcount(u_i) for all batches)`.
7. The method returns `rows_matched`, so BU-SUM and PO-4 hold.
8. If duplicate primary keys occur across batches, they appear in multiple
   `u_i`. The returned value includes each corresponding batch `rowcount(u_i)`,
   matching the public decision to sum actual `update()` returns rather than
   deduplicate for this ticket.
9. The public return shape is a plain integer. The V2 terminology change from
   "updated" to "matched" aligns the source comment with the issue contract,
   discharging PO-1 and FINDING F-3.

## Machine-Check Commands Not Run

The FVK documentation calls for commands like the following. They are recorded
for reproducibility only and were not executed in this benchmark environment:

```sh
kompile fvk/mini-bulk-update.k --backend haskell
kast --backend haskell fvk/bulk-update-spec.k
kprove fvk/bulk-update-spec.k
```

Expected outcome if the reduced K files are materialized from the claims in
`SPEC.md`: `kprove` discharges BU-EMPTY, BU-SUM, and BU-LOOP to `#Top`.

## Residual Risk

This proof is partial correctness over a reduced model. It does not prove
database backend row-count semantics, SQL expression correctness, transaction
rollback behavior, or performance. It also does not machine-check the claims.

## Test Guidance

No test files were read as oracle inputs or modified. After machine-checking,
point tests that only assert the in-domain integer return for representative
single-batch, multi-batch, and empty-input cases would be subsumed by the proof.
Integration, backend-specific, exception, and duplicate-semantics tests should
be kept because they cover behavior outside this reduced unit proof.
