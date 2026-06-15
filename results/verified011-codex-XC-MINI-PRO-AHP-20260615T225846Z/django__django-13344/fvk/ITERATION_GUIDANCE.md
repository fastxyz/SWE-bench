# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by the FVK audit. The V1 code changes
discharge all proof obligations listed in `fvk/PROOF_OBLIGATIONS.md`; the
findings in `fvk/FINDINGS.md` are either resolved by V1 or are honesty/coverage
notes that do not call for a production-code change.

## Traceability

F-001 maps to PO-001, PO-002, and PO-005. Decision: keep
`SecurityMiddleware.__init__()` as V1 wrote it, with
`super().__init__(get_response)`.

F-002 maps to PO-001, PO-003, PO-004, and PO-005. Decision: keep the split cache
middleware constructors delegating to `super().__init__(get_response)` and keep
the combined cache constructor calling `MiddlewareMixin.__init__()` directly.

F-003 maps to PO-004 and PO-007. Decision: do not refactor
`CacheMiddleware.__init__()` to plain `super().__init__()` because that would
introduce a compatibility risk through the multiple-inheritance MRO.

F-004 maps to PO-008. Decision: do not broaden the patch to other middleware
constructors; the audited in-tree constructors either already execute
`_async_check()` or already call `super().__init__()`.

F-005 maps to all proof obligations. Decision: label the result constructed,
not machine-checked, and do not remove or modify tests.

## Suggested Future Tests

Do not add tests in this benchmark. In a normal development setting, targeted
tests should exercise:

- ASGI chain with an outer dummy `MiddlewareMixin` before `SecurityMiddleware`.
- ASGI chain with the same dummy before `UpdateCacheMiddleware`.
- ASGI chain with the same dummy before `FetchFromCacheMiddleware`.
- ASGI chain with the same dummy before `CacheMiddleware`.
- `cache_page()` with explicit `cache`, `key_prefix`, and timeout options to
  guard the combined-cache compatibility decision.

## Machine-Check Follow-Up

When a K environment exists, run the commands recorded in `fvk/PROOF.md`.
Until `kprove` returns `#Top`, treat test-removal recommendations as disabled.
