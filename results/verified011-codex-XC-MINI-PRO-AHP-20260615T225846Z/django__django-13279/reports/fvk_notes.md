# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no additional source edit required for the public intent.

## Trace to Findings and Proof Obligations

`fvk/FINDINGS.md` entry `F1` identifies the original V0 bug: SHA1 transition mode still wrote the new signing-based session format. `fvk/PROOF_OBLIGATIONS.md` entries `PO1` and `PO2` are the corresponding positive obligations, and V1 discharges them by adding `_legacy_encode()` and routing `SessionBase.encode()` to it when `settings.DEFAULT_HASHING_ALGORITHM == 'sha1'`.

`PO3` and `PO5` confirm decode compatibility remains intact: V1 did not alter the existing `signing.loads()` first path or the `_legacy_decode()` fallback. `PO4` confirms default SHA256 behavior remains on the existing `signing.dumps(..., compress=True)` path.

`F2` corrected an explanatory overstatement from `reports/baseline_notes.md`: the pure cache backend stores dictionaries directly, so it is not part of the encoded session-data format surface. This did not require a source edit because the actual encoded storage consumers are DB, cached DB's database row, file storage, and `BaseSessionManager`, all covered by `PO6` and `PUBLIC_COMPATIBILITY_AUDIT.md`.

`F3` records the proof caveat: the mini-K model abstracts byte-level serializer, HMAC, and base64 behavior. The abstraction still distinguishes the failing pre-fix signed payload from the passing legacy payload, so it is adequate for this issue's format-selection property. The proof remains constructed, not machine-checked.

## Commands Not Run

Per the task constraints, I did not run tests, Python, Django code, `kompile`, `kast`, or `kprove`. The exact formal commands are written in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a future environment that permits execution.

