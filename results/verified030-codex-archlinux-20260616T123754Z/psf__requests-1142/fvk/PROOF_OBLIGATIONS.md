# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Bodyless GET must not auto-add Content-Length

For method `GET`, `body is None`, and no user-provided `Content-Length`, after
`prepare_content_length(body)` the header remains absent.

Evidence: E1, E2, E4.

## PO2 - GET with body keeps computed Content-Length

For method `GET` and an actual body with computable length, after
`prepare_content_length(body)` the header is present and reflects the body
length.

Evidence: E3.

## PO3 - Non-GET bodyless behavior is preserved

For method not equal to `GET` and `body is None`, after
`prepare_content_length(body)` the header is present as `Content-Length: 0`.

Evidence: E8.

## PO4 - Explicit bodyless-GET Content-Length is preserved

For method `GET`, `body is None`, and an initial user-supplied
`Content-Length`, preparation does not delete that header.

Evidence: E2 limits the bug to automatic addition.

## PO5 - `Request(..., data=None)` reaches the bodyless path

For public `Request` construction with `data=None`, the stored data value must
prepare as no body rather than as a stream body. For method `GET`, this composes
with PO1.

Evidence: E5, E6.

## PO6 - Auth recomputation does not reintroduce the header

For a bodyless `GET`, a later call to `prepare_content_length(self.body)` from
`prepare_auth` must preserve absence of automatically added `Content-Length`.

Evidence: E7.

## PO7 - No public API shape changes

The fix must not change public method signatures or request/response object
shape.

Evidence: compatibility audit.
