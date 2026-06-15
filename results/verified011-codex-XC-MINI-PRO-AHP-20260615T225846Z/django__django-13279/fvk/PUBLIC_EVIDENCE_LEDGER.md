# Public Evidence Ledger

## E1: Reported Defect

Source: prompt / `benchmark/PROBLEM.md`

Quoted evidence: "Session data cannot be decoded during the transition to Django 3.1."

Semantic obligation: stored session data written in the transition mode must remain decodable by older participating instances.

Status: encoded in `SPEC.md`, `session-encode-spec.k` claim `SHA1-LEGACY-ROUNDTRIP`, and proof obligation `PO1`.

## E2: Transitional Setting Is Insufficient Without Format Change

Source: prompt / `benchmark/PROBLEM.md`

Quoted evidence: "setting DEFAULT_HASHING_ALGORITHM to 'sha1' is not enough to support running multiple instances of the same project during the transition to Django 3.1."

Semantic obligation: SHA1 algorithm selection alone is insufficient; the session data wire format must also be selected for compatibility.

Status: encoded in `SPEC.md` as the branch condition for `SessionBase.encode()`.

## E3: Suggested Mechanism

Source: prompt / `benchmark/PROBLEM.md`

Quoted evidence: "We could use the legacy encode() when DEFAULT_HASHING_ALGORITHM == 'sha1'."

Semantic obligation: for `DEFAULT_HASHING_ALGORITHM == 'sha1'`, `SessionBase.encode()` should emit the legacy session format.

Status: implemented in V1; encoded in K claim `SHA1-ENCODES-LEGACY`.

## E4: Documentation for Transitional Setting

Source: `repo/docs/releases/3.1.txt`

Quoted evidence: "you should set DEFAULT_HASHING_ALGORITHM to 'sha1' during the transition, in order to allow compatibility with the older versions of Django."

Semantic obligation: SHA1 transition mode is a compatibility mode, not merely a cryptographic-signature preference.

Status: supports `PO1` and the frame condition that default SHA256 behavior remains unchanged outside transition mode.

## E5: Settings Reference Includes Sessions

Source: `repo/docs/ref/settings.txt`

Quoted evidence: "Default hashing algorithm to use for encoding cookies, password reset tokens in the admin site, user sessions, and signatures..."

Semantic obligation: user sessions are in scope for the setting's compatibility behavior.

Status: supports applying the SHA1 compatibility branch in session data encoding.

## E6: Legacy Decode Defines Legacy Format

Source: `repo/django/contrib/sessions/backends/base.py`

Quoted evidence: `_legacy_decode()` base64-decodes the payload, splits `hash:serialized`, checks `_hash(serialized)`, then loads `serialized`.

Semantic obligation: the corresponding legacy encoder must serialize the session dictionary, prepend `_hash(serialized)` and `':'`, and base64-encode the combined bytes.

Status: implemented by V1 `_legacy_encode()`; encoded in `legacyEncoded(StoreClass, legacyHash(...), serialized(...))`.

## E7: New Encode Was the Mismatch

Source: V1 pre-edit code in `repo/django/contrib/sessions/backends/base.py`

Quoted evidence: `SessionBase.encode()` always returned `signing.dumps(session_dict, salt=self.key_salt, serializer=self.serializer, compress=True)`.

Semantic obligation: this behavior is SUSPECT for transition mode because it matches the reported defect.

Status: recorded as finding `F1` and fixed by the SHA1 branch.

## E8: Storage Consumers

Source: `repo/django/contrib/sessions/backends/db.py`, `cached_db.py`, `file.py`, `base_session.py`, `cache.py`, `signed_cookies.py`

Quoted evidence: DB and file save paths call `self.encode(...)`; cached DB inherits DB save; `BaseSessionManager.encode()` delegates to the session store's `encode()`; pure cache stores `self._get_session(...)` directly; signed cookies call `signing.dumps(...)` in `_get_session_key()`.

Semantic obligation: the source fix belongs in `SessionBase.encode()` for server-side encoded storage. It must not alter pure cache dictionary storage or signed-cookie session key generation.

Status: public compatibility audit passes; baseline note over-scoped the pure cache backend but source behavior remains correct.

