# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 should not stand exactly as written. F-001 showed that V1 fixed the public
`prepare_body` path by bypassing `_encode_params`, but left the shared helper's
bytes behavior as "decode with `to_native_string`." V2 moves bytes preservation
into `_encode_params` and compensates at the URL call site, satisfying PO-1
through PO-4.

## Source Changes Justified By FVK

1. In `_encode_params`, split bytes and text handling:
   - bytes return unchanged
   - text still uses `to_native_string`

   Justification: F-001, PO-1, PO-2.

2. In `prepare_url`, convert byte `enc_params` to native text before joining
   the query string.

   Justification: F-002, PO-3.

3. Remove the V1 caller-local bytes bypass in `prepare_body`.

   Justification: PO-1 now makes `_encode_params` safe for raw bytes bodies,
   and PO-2 proves the same body result through the normal body path.

## No Further Source Changes Recommended

- Do not modify `to_native_string`; PO-5 treats it as a frame condition.
- Do not alter multipart, streaming, or file-like branches; they are frame
  conditions and have no issue evidence.
- Do not change empty-bytes/json truthiness behavior in this issue repair; F-003
  records it as an underspecified boundary.

## Future Tests

The fixed test suite is hidden for this task, so no tests were edited. A
maintainer-facing follow-up test set should include:

- raw non-ASCII bytes `data` preserves `PreparedRequest.body`
- raw bytes `data` does not set form content type
- bytes `params` still prepares a native URL query
- dictionary/list `data` still form-encodes

## Future Machine Check

Run the commands emitted in `fvk/PROOF.md` in an environment with K installed.
Treat any K syntax or proof residual as a proof-engineering issue unless it
changes the adequacy audit or one of the proof obligations.
