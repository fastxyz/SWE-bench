# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Bytes preservation in `_encode_params`

Claim: for all byte sequences `B`, `_encode_params(B)` returns `B`.

Public evidence: E1, E2, E7.

Code evidence: `if isinstance(data, bytes): return data`.

K claim: `CLAIM-ENCODE-BYTES`.

## PO-2: Raw bytes body preparation

Claim: for all non-empty byte sequences `B`, with no files and no stream branch,
`prepare_body(data=B, files=None)` sets `self.body` to `B`, leaves content type
unset, and computes content length from `len(B)`.

Public evidence: E1, E2, E3.

Code evidence: `prepare_body` calls `_encode_params(data)` for truthy non-file
data, then treats `basestring` data as no content type.

K claim: `CLAIM-PREPARE-BODY-BYTES`.

## PO-3: URL bytes params remain native URL text

Claim: for ASCII-compatible byte query `Q`, `prepare_url(..., params=Q)` uses
native text `to_native_string(Q)` for URL assembly.

Public evidence: E5.

Code evidence: `prepare_url` converts `enc_params` with `to_native_string` when
`enc_params` is bytes.

K claim: `CLAIM-PREPARE-URL-BYTES`.

## PO-4: Form data frame condition

Claim: mapping/list form data still uses `_encode_params` form encoding and
sets form content type on the body path.

Public evidence: E4, E6.

Code evidence: `_encode_params` iterable branch and the existing
`application/x-www-form-urlencoded` branch are unchanged.

K claim: `CLAIM-PREPARE-BODY-FORM`.

## PO-5: No global compatibility change to `to_native_string`

Claim: V2 does not modify `to_native_string`, so unrelated method, URL, header,
auth, and redirect conversions keep their prior semantics.

Public evidence: E7 and compatibility audit.

Code evidence: `repo/requests/utils.py` unchanged.

K claim: represented as a frame condition, not a rewrite claim, because the
utility function is outside the edited code path.
