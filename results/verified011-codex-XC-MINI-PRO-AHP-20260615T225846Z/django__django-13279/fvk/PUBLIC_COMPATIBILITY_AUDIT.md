# Public Compatibility Audit

Status: pass.

## Changed Symbols

`SessionBase.encode(session_dict)`

- Public signature changed: no.
- Return type changed: no, still returns a string.
- Dispatch shape changed: no, existing callers still call `encode(session_dict)`.
- Behavior changed only under `DEFAULT_HASHING_ALGORITHM == 'sha1'`, where public intent requires the legacy session data format.

`SessionBase._legacy_encode(session_dict)`

- New private helper.
- Public signature compatibility impact: none.
- Override compatibility impact: none found in source. Existing subclasses do not override `_legacy_encode()`.

## Callers and Storage Consumers

`django.contrib.sessions.backends.db.SessionStore.create_model_instance()`

- Calls `self.encode(data)` for DB `session_data`.
- Compatibility status: covered by `SessionBase.encode()` branch.

`django.contrib.sessions.backends.cached_db.SessionStore.save()`

- Inherits DB save for database persistence and stores the decoded dictionary in cache.
- Compatibility status: database row covered by `SessionBase.encode()` branch; cache write remains a dictionary and is not part of encoded session-data format.

`django.contrib.sessions.backends.file.SessionStore.save()`

- Writes `self.encode(session_data).encode()` to the session file.
- Compatibility status: covered by `SessionBase.encode()` branch.

`django.contrib.sessions.base_session.BaseSessionManager.encode()`

- Delegates to `session_store_class().encode(session_dict)`.
- Compatibility status: covered by the store class's `SessionBase.encode()` implementation.

`django.contrib.sessions.backends.cache.SessionStore.save()`

- Stores `self._get_session(...)` directly in cache, not encoded text.
- Compatibility status: not affected by this session-data format issue.

`django.contrib.sessions.backends.signed_cookies.SessionStore._get_session_key()`

- Uses `signing.dumps(...)` directly for the cookie-stored session key.
- Compatibility status: not affected by `SessionBase.encode()`; global signing SHA1 compatibility remains handled by `django.core.signing`.

## Result

No public callsite, override, producer, or consumer requires an additional source edit.

