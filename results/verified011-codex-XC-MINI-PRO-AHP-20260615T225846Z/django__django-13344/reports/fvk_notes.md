# FVK Notes

The FVK audit confirmed V1 unchanged. No production source files were edited in
this phase.

`fvk/FINDINGS.md` F-001 identifies the original `SecurityMiddleware` async
recognition defect and traces it to PO-001, PO-002, and PO-005. V1 already
discharges those obligations by calling `super().__init__(get_response)` in
`SecurityMiddleware.__init__()`, so no further security middleware edit was
needed.

`fvk/FINDINGS.md` F-002 identifies the same constructor defect across the cache
middleware family and traces it to PO-001, PO-003, PO-004, and PO-005. V1
already discharges the split cache obligations with `super().__init__()` in
`UpdateCacheMiddleware` and `FetchFromCacheMiddleware`, and the combined cache
obligation with direct `MiddlewareMixin.__init__()`, so no additional cache
family edit was needed.

`fvk/FINDINGS.md` F-003 is the reason V1's `CacheMiddleware` implementation was
kept instead of being refactored to plain `super().__init__()`. PO-004 requires
the mixin async initialization; PO-007 requires preserving explicit
`cache_page()` options. Direct mixin initialization satisfies both without
running parent cache constructors through the multiple-inheritance MRO.

`fvk/FINDINGS.md` F-004 records the completeness audit for other in-tree custom
middleware constructors. It maps to PO-008 and found no additional source edit:
`SessionMiddleware` already calls `_async_check()`, and
`RedirectFallbackMiddleware` already calls `super().__init__()`.

`fvk/FINDINGS.md` F-005 records the proof/tooling limitation. Because this
benchmark forbids running Python, tests, or K tooling, `fvk/PROOF.md` is labeled
constructed, not machine-checked, and no tests were removed or recommended for
removal.
