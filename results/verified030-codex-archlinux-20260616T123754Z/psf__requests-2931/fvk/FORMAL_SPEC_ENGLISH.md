# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases every nontrivial K claim in
`fvk/requests-body-spec.k`.

## CLAIM-ENCODE-BYTES

For any byte sequence `B`, evaluating `encodeParams(rawBytes(B))` returns the
same byte sequence `B`. It does not return a native string and does not decode
`B`.

## CLAIM-PREPARE-BODY-BYTES

For any non-empty byte sequence `B`, preparing a non-file request body from
`rawBytes(B)` returns a prepared body whose body is exactly `B`, whose content
type is absent, and whose length is `len(B)`.

## CLAIM-PREPARE-URL-BYTES

For any ASCII-compatible byte sequence `Q`, preparing URL parameters from
`rawBytes(Q)` returns a URL query containing `toNative(Q)`. The native-string
conversion is located at URL assembly time, not in the body encoder contract.

## CLAIM-PREPARE-BODY-FORM

For any form mapping/list abstraction `F`, preparing a non-file request body
from `formData(F)` returns an encoded form body and marks the body as
`application/x-www-form-urlencoded`.

## No Loop Claims

The audited code path contains no loops. The proof obligations are direct
branch reachability claims.
