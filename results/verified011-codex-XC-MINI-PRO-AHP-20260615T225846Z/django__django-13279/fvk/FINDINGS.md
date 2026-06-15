# FVK Findings

Status: no open code bugs found in V1 for the stated intent. Findings are constructed from public/local evidence only.

## F1: V0 Transition-Mode Writes Used the Wrong Format

Classification: code bug, fixed by V1.

Evidence: `benchmark/PROBLEM.md` says `DEFAULT_HASHING_ALGORITHM = 'sha1'` was not enough because the session data format changed, and suggests using the legacy encoder in SHA1 mode.

Input: any serializable session dictionary `D` with `DEFAULT_HASHING_ALGORITHM == 'sha1'`.

Observed in V0: `SessionBase.encode(D)` returned a `signing.dumps(...)` payload.

Expected: `SessionBase.encode(D)` returns the legacy `base64(hash + ':' + serialized)` payload accepted by older Django instances.

Resolution: V1 adds `_legacy_encode()` and branches to it when `settings.DEFAULT_HASHING_ALGORITHM == 'sha1'`. This discharges `PO1` and `PO2`.

## F2: V1 Baseline Notes Overstated Pure Cache Backend Coverage

Classification: documentation/report correction, not a source bug.

Evidence: `cache.SessionStore.save()` stores `self._get_session(...)` directly, while DB, cached DB's DB row, file, and model manager saves use `encode()`.

Input: compatibility audit of storage consumers.

Observed in V1 notes: pure cache was listed among backends that inherit the encoded storage behavior.

Expected: pure cache should be excluded from encoded session-data format scope.

Resolution: FVK artifacts and `reports/fvk_notes.md` correct the scope. No source edit is needed because V1 changed the shared encoder used by actual encoded storage consumers.

## F3: Mini-K Proof Abstracts Serialization and Cryptographic Primitives

Classification: proof capability caveat, not a code bug.

Evidence: `mini-session-format.k` represents serialization, HMAC, and base64 as visible constructors rather than full byte-level semantics.

Input: proof model adequacy.

Observed: the proof can distinguish legacy versus signed storage formats and can prove decoder compatibility, but it does not prove cryptographic properties of HMAC or byte-level base64 correctness.

Expected: for this issue, preserving the format shape and decoder compatibility is the property under test.

Resolution: accepted as property-complete for the reported defect. Machine-checking remains unrun and is documented in `PROOF.md`.

## Proof-Derived Findings from `/verify`

No proof obligation required a new source-side precondition, API change, or behavior beyond V1. The adequacy and compatibility audits do not block `V2 == V1`.

