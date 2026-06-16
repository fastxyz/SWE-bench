# FVK Specification

Status: constructed, not machine-checked.

## Audited Unit

The audited unit is the request-preparation slice that converts caller input
into either a prepared body or URL query:

- `RequestEncodingMixin._encode_params(data)`
- `PreparedRequest.prepare_body(data, files, json=None)` for non-file,
  non-stream data
- `PreparedRequest.prepare_url(url, params)` at the `_encode_params(params)`
  call site

There are no loops in this slice, so there are no loop circularities.

## Public Intent Ledger

The public evidence ledger is recorded in
`fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- E1/E2: non-ASCII bytes supplied as `data` must be valid raw body bytes.
- E3: raw `data` is request body data.
- E4/E6: dictionary/list data must continue to be form-encoded.
- E5: bytes supplied as URL `params` must still prepare a native URL query.
- E7/E8: the failing conversion is shared by body and URL paths, so the fix
  must separate the contexts instead of changing `to_native_string` globally.

## Intent-Level Contract

For every non-empty byte sequence `B` used as `data`, with no files and no
streaming branch:

- `_encode_params(B) = B`
- `prepare_body(data=B, files=None)` sets `body = B`
- `prepare_body` does not set a form content type for `B`
- `prepare_body` sets `Content-Length` from `len(B)` when `len(B) > 0`
- no `to_native_string(B)` conversion occurs on the body path

For every ASCII byte sequence `Q` used as `params`:

- `_encode_params(Q) = Q`
- `prepare_url(..., params=Q)` converts `Q` to a native string at URL assembly
  time
- the prepared URL query contains that native string

For every mapping/list form value `F` supplied as `data`:

- `_encode_params(F)` produces the URL-encoded form body
- `prepare_body(data=F, files=None)` sets
  `Content-Type: application/x-www-form-urlencoded` if no content type is
  already present

## Mini-K Model

The formal core is split across:

- `fvk/mini-requests-body.k`: a minimal K semantics for this request
  preparation slice
- `fvk/requests-body-spec.k`: K claims for the obligations above

The model intentionally abstracts away network I/O, full URL parsing,
multipart encoding internals, file-like reads, and streaming iterators. It
keeps the property axis that matters for the defect: whether a byte sequence is
preserved as bytes or decoded into native text.

## Frame Conditions

FC1. `to_native_string` remains unchanged.

FC2. The public `Request` and `PreparedRequest` method signatures remain
unchanged.

FC3. Form-encoded `data` remains form-encoded.

FC4. Bytes URL params still produce native URL query text.

FC5. Multipart, streamed, and file-like body branches are not changed.

## Adequacy Summary

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims, and
`fvk/SPEC_AUDIT.md` checks each claim against `fvk/INTENT_SPEC.md`. All claims
needed to justify V2 pass the adequacy check. The empty-bytes/json truthiness
boundary is explicitly marked out of scope for this issue-specific repair.
