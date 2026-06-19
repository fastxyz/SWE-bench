# FVK Notes

## Summary

The FVK audit did not leave V1 unchanged. V1 fixed the public
`prepare_body(data=bytes)` path, but F-001 showed that the shared
`_encode_params` helper still decoded bytes with `to_native_string` if reached
directly or through a future body path. V2 moves bytes preservation into
`_encode_params` and adds the compensating URL conversion required by F-002.

No tests, Python, or K tooling were executed.

## Source changes

`repo/requests/models.py`

1. `_encode_params` now handles `bytes` before `str` and returns bytes
   unchanged.

   Trace: F-001, PO-1, PO-2. The issue identifies `to_native_string` on a
   binary payload as the failure mechanism, and PO-1 requires bytes
   preservation at the encoder boundary.

2. `_encode_params` still sends text strings through `to_native_string`.

   Trace: PO-1 and PO-5. The audit only authorizes changing bytes handling;
   text/native-string compatibility is not part of the binary payload defect.

3. `prepare_url` now converts byte `enc_params` with `to_native_string` before
   joining them into the URL query.

   Trace: F-002 and PO-3. Once `_encode_params` returns bytes unchanged, the URL
   call site must perform the native-string conversion needed for
   `params=b"test=foo"` compatibility.

4. The V1 caller-local bytes bypass in `prepare_body` was removed.

   Trace: PO-1 and PO-2. With `_encode_params(bytes)` safe, the normal body path
   proves the same body preservation property without a special local bypass.

## Decisions to keep behavior unchanged

`to_native_string` was not changed.

Trace: PO-5. It is a shared compatibility helper used outside the reported
body-preparation path.

Multipart, streamed, and file-like body branches were not changed.

Trace: the frame conditions in `fvk/SPEC.md` and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. The public issue does not identify those
paths as defective, and V2 does not need to touch them to satisfy the
bytes-body obligations.

Empty bytes combined with `json` was not changed.

Trace: F-003. The existing truthiness behavior is an audited boundary, not a
finding with enough public intent evidence to justify broadening this repair.

## Artifacts

The required FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts were also written:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-requests-body.k`
- `fvk/requests-body-spec.k`
