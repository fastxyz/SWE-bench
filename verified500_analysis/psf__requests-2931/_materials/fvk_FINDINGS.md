# FVK Findings

Status: constructed, not machine-checked.

## F-001: V1 fixed the public body path but left the shared encoder hazard

Classification: code bug in the V1 candidate, fixed in V2.

Evidence: E1, E2, E7, E8.

Input: direct encoder use or any future body path reaching
`_encode_params(b"\xc3\xb6\xc3\xb6\xc3\xb6")` on Python 3.

Observed in V1: `_encode_params` treated `bytes` like text and called
`to_native_string(data)`, which decodes with ASCII by default.

Expected: raw bytes that represent a request body are already encoded and must
be preserved as bytes.

V2 action: `_encode_params` now returns `bytes` unchanged and handles text in a
separate `elif isinstance(data, str)` branch.

## F-002: Moving bytes preservation into `_encode_params` requires URL-callsite conversion

Classification: compatibility obligation, fixed in V2.

Evidence: E5, E8.

Input: `requests.Request("GET", "http://example.com", params=b"test=foo")`.

Observed risk after the F-001 repair: if `_encode_params` returns bytes and
`prepare_url` directly joins those bytes into a Python 3 URL string, URL
assembly can mix bytes and text.

Expected: bytes URL params continue to produce a native query string.

V2 action: `prepare_url` converts `enc_params` with `to_native_string` only at
the URL assembly boundary when `enc_params` is bytes.

## F-003: Empty bytes with `json` remains an audited boundary, not a V2 change

Classification: underspecified intent boundary.

Evidence: D1.

Input: `data=b""` together with `json=...`.

Observed: the existing implementation uses truthiness checks such as
`if not data and json is not None` and `if data:`.

Expected: not established by the issue. The reported failure is a non-empty
binary payload that reaches `to_native_string`.

Decision: no source change. This boundary is recorded so the V2 proof is not
overstated.

## F-004: Proof is constructed, not machine-checked

Classification: proof status limitation.

Evidence: FVK verify honesty gate.

Observed: K commands were written into `fvk/PROOF.md` but not executed.

Expected: a future machine check should run the emitted `kompile`, `kast`, and
`kprove` commands and expect `#Top` before treating tests as formally
subsumed.
