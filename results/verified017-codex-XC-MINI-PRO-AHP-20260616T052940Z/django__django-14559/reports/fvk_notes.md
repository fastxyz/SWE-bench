# FVK Notes

## Decisions

### Kept V1's behavioral fix

V1 changed `bulk_update()` from discarding batched `update()` return values to
returning an integer count. The FVK audit confirms that behavior is required by
FINDING F-1 and discharged by PO-1 and PO-4. The proof obligation is the loop
invariant that `rows_matched` equals the sum of the row counts from completed
batches.

### Kept the empty-input return of `0`

V1 changed valid empty input from returning `None` to returning `0`. The FVK
audit confirms this as the empty sum of matched rows in FINDING F-2, discharged
by PO-2. Validation still happens before the empty-input return, preserving the
existing error behavior required by PO-5.

### Made a V2 terminology cleanup

The FVK audit found that V1's docstring and accumulator used "rows updated",
while the public issue specifies "rows matched". FINDING F-3 identified this as
a source-level ambiguity because "changed rows" and "matched rows" can be
different statistics. I changed the docstring to "rows matched" and renamed the
local accumulator to `rows_matched`, satisfying PO-1 without changing runtime
behavior.

### Rejected a named tuple return value

The public issue discussion considered a future-proof wrapper but converged on
`bulk_update()` returning an integer like `update()`. FINDING F-5 records that
decision, and PO-1/PO-6 require the plain integer return shape. No wrapper was
added.

### Rejected duplicate-primary-key deduplication

The public issue discussion explicitly noted that duplicates split across
batches could be counted more than once, and later accepted summing actual
batched `update()` return values for this ticket. FINDING F-4 records this
residual semantic choice, and PO-4 proves the implemented sum-of-batches
contract. No deduplication logic was added.

### Left validation and callsites unchanged

FINDING F-6 and PO-5 require preserving existing validation behavior. PO-6
audits compatibility: the method signature is unchanged, and in-repo non-test
source callsites either refer to a different migration-state context manager or
ignore the `QuerySet.bulk_update()` return value. No additional source edits
were justified.

## Verification Boundary

FINDING F-7 and PO-7 record the benchmark restriction: no tests, Python, or K
tooling were run. The proof in `fvk/PROOF.md` is constructed, not
machine-checked, and no test-removal action is recommended until the recorded
K commands can be run elsewhere.
