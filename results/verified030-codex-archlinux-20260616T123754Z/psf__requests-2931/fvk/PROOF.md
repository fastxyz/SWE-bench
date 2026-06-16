# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were executed.

## Claims Proved By Construction

The formal claims are in `fvk/requests-body-spec.k` and are paraphrased in
`fvk/FORMAL_SPEC_ENGLISH.md`.

- `CLAIM-ENCODE-BYTES`: bytes input to `_encode_params` is preserved.
- `CLAIM-PREPARE-BODY-BYTES`: non-empty bytes `data` prepares a bytes body.
- `CLAIM-PREPARE-URL-BYTES`: ASCII bytes `params` becomes native URL query
  text at URL assembly time.
- `CLAIM-PREPARE-BODY-FORM`: form data remains form-encoded.

## Proof Sketch

`CLAIM-ENCODE-BYTES` follows by one symbolic step in the mini semantics:
`encodeParams(rawBytes(B))` rewrites to `B`. This models the V2 source branch
`if isinstance(data, bytes): return data`.

`CLAIM-PREPARE-BODY-BYTES` follows by one symbolic step under the precondition
`nonEmpty(B)`. `prepareBody(rawBytes(B), noFiles())` rewrites to
`prepared(bodyBytes(B), noCType(), len(B))`. This models the Python branch where
truthy non-file data uses `_encode_params(data)`, then `basestring` data leaves
`content_type = None`, and content length is derived from `super_len(body)`.
Because `encodeParams(rawBytes(B))` preserves `B`, the body path contains no
`toNative(B)` conversion.

`CLAIM-PREPARE-URL-BYTES` follows by one symbolic step under the precondition
`asciiBytes(Q)`. `prepareUrlParams(rawBytes(Q), noQuery())` rewrites to
`urlPrepared(query(toNative(Q)))`. This models the V2 source change that keeps
bytes preservation in `_encode_params` but performs `to_native_string` at the
URL boundary when `enc_params` is bytes.

`CLAIM-PREPARE-BODY-FORM` follows by one symbolic step:
`prepareBody(formData(F), noFiles())` rewrites to an encoded form body with
`formCType()`. This models the unchanged iterable/form branch.

There are no loop circularities and no recursion in the audited slice.

## Adequacy Gate

The adequacy artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

`fvk/SPEC_AUDIT.md` marks all claims needed for V2 as PASS. The empty-bytes and
multipart/stream/file-like boundaries are explicitly not used to justify the
repair.

## Machine-Check Commands To Run Later

These commands are emitted for a future environment with K installed. They were
not run in this session.

```sh
kompile fvk/mini-requests-body.k --backend haskell
kast --backend haskell fvk/requests-body-spec.k
kprove fvk/requests-body-spec.k
```

Expected machine-check result after any syntax adjustments required by the
local K version: `#Top`.

## Test Guidance

Conditioned on a future machine check returning `#Top`, unit tests that assert
the same in-domain properties as the claims would be formally subsumed. No test
files were modified.

Recommended tests to add or keep:

- Keep or add a test that `data=b"\xc3\xb6\xc3\xb6\xc3\xb6"` prepares without
  decoding and leaves `PreparedRequest.body` as the same bytes.
- Keep the existing public behavior that `params=b"test=foo"` prepares
  `?test=foo`.
- Keep form-encoding tests such as dictionary/list `data`.
- Keep integration tests that exercise actual network send behavior, because
  this proof covers preparation only.
