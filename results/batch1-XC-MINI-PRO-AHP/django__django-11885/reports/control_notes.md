# Control notes — audit outcome for django__django-11885

## Summary of outcome
After a systematic, skeptical re-review of the V1 fix (recorded in
`review/FINDINGS.md`), **no code was changed**: the V1 fix is confirmed correct and
complete. Every review dimension required by the task — correctness against the
issue, edge/boundary cases, error handling, interactions/regressions, and
convention/API consistency — was examined and produced either a ✅ (correct) or a
⚠️ (analyzed, judged acceptable and not a regression). There were no ❌ findings, so
there is nothing to repair, and no refactor improves the fix without adding churn
or risk. This decision is justified finding-by-finding below.

## Why V1 stands unchanged — traced to findings

- **The fix actually does what the issue asks (F1).** Grouping reverse relations by
  `related_model` and OR-ing their per-field `IN` predicates produces exactly the
  combined `DELETE … WHERE a IN (...) OR b IN (...)` from `PROBLEM.md`. No change
  needed.

- **The combination is parameter-safe across backends (F2).** This is the single
  most important correctness question. V1 combines *before* batching and forwards
  the full field list to `bulk_batch_size`, so SQLite/Oracle (which expose
  `max_query_params`) divide the batch size by the field count, while PostgreSQL/
  MySQL (no hard param-count limit) accept the larger combined query. Crucially,
  this is *why* the V1 design combines at collection time inside `collect()` rather
  than post-hoc in `delete()`: a `delete()`-time merge would OR across already-sized
  batches and could exceed limits. F2 therefore both validates V1 and rejects the
  most tempting alternative implementation, so V1's structure is kept deliberately.

- **Counts, semantics, and ordering are preserved (F3, F5, F11).** The summed
  rowcount equals the union deleted (unchanged total), CASCADE-only/NULL handling is
  identical under OR, and fast deletes remain mutually order-independent and
  deterministically ordered. No behavioral drift to correct.

- **Eligibility decisions are unchanged (F4).** Passing `related_model` +
  `from_field` to `can_fast_delete` reproduces the per-field decisions (including
  the MTI parent-link distinction) the old per-queryset call made; only eligible
  fields are combined. No change needed.

- **Queries stay single-table/direct (F6).** The combined queryset introduces no
  join, so `DeleteQuery.delete_qs` copies the `WHERE` directly instead of falling
  back to a subquery — the efficient path the issue intends. No change needed.

- **All in-repo collaborators were already updated (F7, F8).** `NestedObjects`
  (admin) is migrated to the new `related_objects` signature with identical behavior
  (single field), and `NoFastDeleteCollector` needs nothing because it only overrides
  `can_fast_delete`. The non-fast path is byte-for-byte equivalent SQL. Nothing is
  left half-migrated, so no follow-up edit is required.

- **No new failure modes or import hazards (F9, F10).** `related_fields` is provably
  never empty (so `reduce` cannot raise), `objs` is always a non-empty list, the new
  imports are circular-safe, and `type(objs)` → `objs._meta.model` is exactly
  equivalent for existing callers. These confirm there is nothing to harden.

- **Consistent with visible tests and conventions (F12, F13).** Single-FK and
  top-level fast-delete query counts in `tests/delete/` are preserved; the only
  behavioral change is the intended *reduction* for multi-FK tables. No docs
  reference the changed internal methods. A release note is out of scope for the
  behavioral fix.

## Items deliberately NOT changed (and why)
- **`field.remote_field.on_delete == DO_NOTHING` (`deletion.py:225`, `==` vs `is`).**
  Pre-existing and untouched by V1; "fix the described issue without unrelated
  refactoring." Changing it is out of scope and would add review noise. (Not tied to
  any defect finding.)
- **No explanatory comment added to the grouping loop.** The file's comment density
  is sparse and `model_fast_deletes` / `related_objects` are self-describing;
  matching surrounding style (per F-level "consistency" review) is preferred over
  adding commentary. Kept minimal.
- **No backward-compatibility shim for the changed method signatures (F7 ⚠️).** A
  dual-signature shim would add complexity for an undocumented internal extension
  point; the clean signature change is the intended, minimal approach and all
  in-repo overriders are updated.

## Net change in this pass
Files edited in the audit pass: **none**. V1 (`django/db/models/deletion.py` and
`django/contrib/admin/utils.py`) is confirmed as the final fix.
