# FVK Findings

Constructed, not machine-checked.

## F1 - Resolved V0 bug: oversized explicit batch bypassed backend cap

- Classification: code bug in V0, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` says "`bulk_create` batch_size param overrides the compatible batch size calculation."
- Concrete input class: object count `N > C`, backend compatible cap `C >= 1`, explicit user batch `U > C`.
- Observed in V0: effective batch size was `U`, so the first emitted batch length could be `U`, which is larger than `C`.
- Expected: effective batch size is `C`; every emitted batch length is `<= C`.
- Proof obligations: PO1, PO2, PO3.
- V1 status: resolved by computing `max_batch_size` and using `min(batch_size, max_batch_size)` when an explicit batch size is present.

## F2 - No V1 regression for omitted or smaller explicit batch sizes

- Classification: compatibility check, no active code bug.
- Concrete input class: `batch_size is None`, or `0 < U <= C`.
- Expected: omitted values use `C`; smaller explicit values use `U`.
- V1 status: confirmed by the effective-batch claims and PO4. The source preserves the no-user-value path and smaller-user-value path.

## F3 - Helper-level placement is necessary and correct

- Classification: adequacy/placement finding, no active code bug.
- Evidence: `bulk_create()` calls `_batched_insert()` once with all concrete fields for objects with primary keys and once with `AutoField` removed for objects without primary keys.
- Risk if fixed in `bulk_create()` only: one cap could be calculated for the wrong field list.
- V1 status: confirmed by PO5. Keeping the cap calculation in `_batched_insert()` is the correct placement.

## F4 - Residual domain assumption: compatible cap is positive after Django lower bound

- Classification: named assumption, no V2 code change.
- Evidence: existing `_batched_insert()` already lower-bounded `ops.bulk_batch_size(fields, objs)` with `max(..., 1)`.
- Concrete edge class: a backend could theoretically report `0` for a field set too large for even one row.
- Expected under this audit: supported insertable batches have effective cap `C >= 1`.
- V1 status: unchanged. The issue is about explicit user values bypassing the compatible calculation, not changing Django's preexisting lower-bound policy.

## F5 - No public compatibility issue found

- Classification: compatibility check, no active code bug.
- Evidence: no signature changed; `ignore_conflicts`, returning-row behavior, object state updates, and `_insert()` calls remain structurally unchanged.
- V1 status: confirmed by PO6 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Proof-derived findings from `/verify`

The constructed proof does not surface a new V1 code defect. It does surface two caveats:

- Machine-checking caveat: the K artifacts were constructed but not run through `kompile`/`kprove` because this task forbids running K tooling.
- Coverage caveat: the proof covers batching arithmetic and emitted slice lengths only. Database execution and transaction side effects remain outside the formal model.
