# Proof Obligations

Status: constructed, not machine-checked.

## PO1: SHA1 Mode Emits Legacy Format

Statement: for every in-domain `session_dict`, if `DEFAULT_HASHING_ALGORITHM == 'sha1'`, `SessionBase.encode(session_dict)` returns the pre-Django 3.1 legacy payload.

Evidence: ledger E1-E3, E6.

Formal claim: `SHA1-ENCODES-LEGACY` in `session-encode-spec.k`.

Discharge status: discharged by V1 branch to `_legacy_encode()`.

## PO2: SHA1 Mode Is Decodable by Legacy Instances

Statement: a payload emitted by `SessionBase.encode()` in SHA1 mode is accepted by the legacy decoder and yields the original session dictionary.

Evidence: ledger E1-E3, E6.

Formal claim: `SHA1-LEGACY-ROUNDTRIP` in `session-encode-spec.k`.

Discharge status: discharged because `_legacy_encode()` constructs the exact shape consumed by `_legacy_decode()`.

## PO3: Django 3.1 Continues to Decode Legacy Payloads

Statement: current `SessionBase.decode()` accepts legacy session data.

Evidence: existing `decode()` catches new-format failures and calls `_legacy_decode()`.

Formal claim: `CURRENT-DECODE-LEGACY` in `session-encode-spec.k`.

Discharge status: discharged by existing code; V1 does not weaken it.

## PO4: Default SHA256 Mode Is Unchanged

Statement: when `DEFAULT_HASHING_ALGORITHM == 'sha256'`, `SessionBase.encode()` continues to use the new `signing.dumps(..., compress=True)` format.

Evidence: public setting default and frame condition.

Formal claim: `SHA256-ENCODES-SIGNED` in `session-encode-spec.k`.

Discharge status: discharged by the fall-through path in V1.

## PO5: Current Signed Payload Decode Is Preserved

Statement: current `SessionBase.decode()` continues to decode the signing-based payload.

Evidence: existing `signing.loads(...)` first path in `decode()`.

Formal claim: `CURRENT-DECODE-SIGNED` in `session-encode-spec.k`.

Discharge status: discharged by unchanged decode first path.

## PO6: Public Compatibility

Statement: no public method signature, storage producer, storage consumer, or subclass override is broken by the V1 change.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Formal status: non-K compatibility obligation, discharged by source inspection.

Discharge status: pass. No additional code edit required.

