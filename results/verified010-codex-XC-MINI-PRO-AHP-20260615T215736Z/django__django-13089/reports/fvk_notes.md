# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that requires V2 edits.

## Trace to Findings and Proof Obligations

F-001 / PO-001 cover the public issue's reported crash. V1 stores the cutoff query result in `cull_key` and only indexes `cull_key[0]` when `cull_key is not None`, so the no-row cutoff path no longer raises `'NoneType' object is not subscriptable`.

F-002 / PO-002 cover the deterministic boundary where `CULL_FREQUENCY` is `1`. Because the documented culling ratio is `1 / CULL_FREQUENCY`, frequency one means all current rows are culled. V1 handles this by deleting all rows when `cull_num == num`, avoiding the offset-past-end cutoff query.

F-003 / PO-003 confirm that normal culling is preserved. When the cutoff query returns a row and the cull count is not the entire table, V1 still uses `connection.ops.cache_key_culling_sql()` followed by `DELETE ... WHERE cache_key < %s`.

PO-004 and PO-005 are preserved frame obligations. The zero-frequency `self.clear()` branch and the below-limit no-cull branch are unchanged.

F-004 / PO-006 record an underspecified area, not a required code change. Negative `CULL_FREQUENCY` is outside the public issue and outside the documented fraction/zero behavior, so I did not add new option validation in this fix.

F-005 / PO-007 record the proof boundary. The mini model abstracts full database concurrency into the observable cutoff result `none`; it does not prove transaction isolation or backend cursor behavior. That limitation justifies keeping backend/integration tests, not changing the V1 source.

## Artifacts Produced

The required FVK artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

To satisfy the FVK formal-core and adequacy contract, I also wrote `fvk/mini-cache-cull.k`, `fvk/database-cache-cull-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

No tests, Python, K framework tools, or project code were run.
