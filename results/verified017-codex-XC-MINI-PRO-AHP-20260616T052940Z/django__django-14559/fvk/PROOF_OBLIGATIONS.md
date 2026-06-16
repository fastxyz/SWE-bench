# FVK Proof Obligations: django__django-14559

Status: constructed, not machine-checked.

## PO-1: Successful return type and meaning

For every normal-return execution in the valid input domain,
`QuerySet.bulk_update()` returns an `int` representing rows matched, not `None`.

Evidence: SPEC I-1 and I-3; FINDINGS F-1, F-3, and F-5.

Discharge status: satisfied by the V2 implementation, which returns `0` for the
empty case and the integer accumulator `rows_matched` for the batched case.

## PO-2: Empty object list

After existing validation succeeds and `objs = tuple(objs)` is empty,
`bulk_update()` returns `0`.

Evidence: SPEC I-1 and the empty-sum interpretation in the Intent Spec;
FINDING F-2.

Discharge status: satisfied by `if not objs: return 0`.

## PO-3: Existing update plan construction is preserved

For non-empty valid input, the code builds the same `updates` list as the
pre-fix implementation: each batch contributes a pair of primary-key values and
field update expressions, including existing `Case` and optional `Cast`
behavior.

Evidence: SPEC I-6; FINDING F-6.

Discharge status: satisfied by the patch only adding a row-count accumulator
after `updates` is built.

## PO-4: Batched accumulation loop

Let `updates = [u_0, ..., u_n]` and let `r_i` be the integer returned by the
existing call `self.filter(pk__in=pks_i).update(**update_kwargs_i)` for `u_i`.

Loop invariant:

```text
Before iteration k, rows_matched = r_0 + ... + r_(k-1).
```

Initialization:

```text
Before the first iteration, rows_matched = 0.
```

Step:

```text
The loop body executes one existing update call, receives r_k, and sets
rows_matched = rows_matched + r_k.
```

Exit:

```text
After all iterations, rows_matched = r_0 + ... + r_n, and that value is returned.
```

Evidence: SPEC I-2 and I-4; FINDINGS F-1 and F-4.

Discharge status: satisfied by the V2 implementation.

## PO-5: Validation and exceptional behavior frame condition

The fix must not reorder or weaken the existing validation guards, and it must
not convert validation failures or database exceptions into row-count returns.

Evidence: SPEC I-6; FINDING F-6.

Discharge status: satisfied. The only changed control-flow branch before batch
construction is the empty valid-input branch, which now returns `0` instead of
`None` after all existing validation.

## PO-6: Public compatibility

The method signature remains unchanged. Existing public source callsites that
ignore the return value remain compatible. The return-value shape changes to
plain `int`, as requested by public intent.

Evidence: SPEC Public Compatibility Audit; FINDING F-5.

Discharge status: satisfied. No paired source changes are required.

## PO-7: Honesty and verification boundary

No tests, Python code, or K tooling may be run in this environment. The proof is
therefore a constructed proof only, and no test-removal action is justified.

Evidence: task instructions and FINDING F-7.

Discharge status: satisfied by recording commands and caveats in `PROOF.md` and
by not modifying test files.
