# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited observable is whether request preparation adds `Content-Length` to
headers. The relevant production functions are:

- `Request.__init__`, only for normalization of omitted/`None` request body
  values before preparation.
- `PreparedRequest.prepare_body`, only for routing bodyless data to
  `prepare_content_length`.
- `PreparedRequest.prepare_content_length`, where automatic `Content-Length`
  is added or suppressed.
- `PreparedRequest.prepare_auth`, only because it recomputes content length
  after an auth handler.

There are no loops or recursive functions in this slice.

## Intent-only requirements

See `fvk/INTENT_SPEC.md`. The core obligation is:

For every public request-preparation path that represents a `GET` request with
no body, and where the user did not explicitly supply `Content-Length`, the
prepared headers must not contain an automatically added `Content-Length`.

## Public intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2/E4 require no automatic `Content-Length` for bodyless/default `GET`.
- E3 requires preserving computed `Content-Length` when a `GET` has a real body.
- E5/E6 expose the V1 gap: `data=None` in the public `Request` constructor must
  also be bodyless.
- E8 preserves non-`GET` zero-length behavior.

## Formal abstraction

The K-style abstraction in `fvk/mini-python.k` models only the property under
verification:

- `Method`: `GET` or `OTHER`.
- `Data`: omitted, `None`, empty dict, body data with length, or stream data
  with length.
- `Body`: no body, body with known length, or stream body with known length.
- `Headers`: a boolean recording whether `Content-Length` is present.

This abstraction intentionally omits URL parsing, cookies, auth internals,
multipart details, and network transport, because those constructs do not
contribute to the audited observable.

## Formal claims in English

See `fvk/FORMAL_SPEC_ENGLISH.md`. The main claims are:

- `GET-NO-BODY`: omitted/empty-body `GET` with no explicit length finishes with
  no `Content-Length`.
- `GET-NONE-DATA`: `Request(..., data=None)` is normalized to the same bodyless
  state and finishes with no `Content-Length`.
- `GET-BODY`: a `GET` with an actual body finishes with `Content-Length`.
- `OTHER-NO-BODY`: a non-`GET` bodyless request still finishes with
  `Content-Length: 0`.
- `GET-EXPLICIT-CL`: an explicit `Content-Length` on a bodyless `GET` is
  preserved.

## Adequacy audit summary

See `fvk/SPEC_AUDIT.md`. All claims pass against public intent except the
explicit empty iterable case, which is intentionally marked ambiguous and not
used as a success condition.

## Public compatibility summary

See `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. No public signatures or return types
are changed. The V2 source edit only changes `Request.__init__`'s internal
normalization of `data=None` from an empty list to an empty dict, aligning the
public "no body" value with omitted data.
