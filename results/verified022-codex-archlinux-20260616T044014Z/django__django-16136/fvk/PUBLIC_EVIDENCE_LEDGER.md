# Public Evidence Ledger

Status: constructed, not machine-checked.

This file mirrors the ledger in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | Async post-only view receiving GET raises `TypeError` because `HttpResponseNotAllowed` is awaited. | Unsupported methods on async views must yield a 405 response through an awaitable path. | Encoded in async fallback claims. |
| E2 | `benchmark/PROBLEM.md` | Hint says `http_method_not_allowed()` must handle sync/async like `options()`. | Branch on `view_is_async` and wrap only async fallback responses. | Encoded in parity claim. |
| E3 | `repo/docs/topics/class-based-views/index.txt` | Async class-based handlers are allowed and run in async context. | Async view callbacks must return awaitable-compatible values. | Encoded in domain and async fallback claim. |
| E4 | `repo/docs/ref/class-based-views/base.txt` | `as_view()` marks async handler classes as coroutine functions and rejects mixed handlers. | Successful dispatch domain excludes mixed handler classes. | Encoded as domain assumption. |
| E5 | `repo/docs/ref/class-based-views/base.txt` | Unsupported methods call `http_method_not_allowed()`, returning `HttpResponseNotAllowed` with allowed methods. | Preserve 405 response and `Allow` header. | Encoded in response preservation claim. |
| E6 | `repo/django/views/generic/base.py`, `repo/tests/async/tests.py` | `options()` wraps its response in a coroutine for async views. | `http_method_not_allowed()` should use the same adaptation shape. | Encoded in parity claim. |
| E7 | Source search | Only the base method defines `http_method_not_allowed`; signature is public. | Do not change signature or virtual dispatch call shape. | Encoded in compatibility obligation. |
