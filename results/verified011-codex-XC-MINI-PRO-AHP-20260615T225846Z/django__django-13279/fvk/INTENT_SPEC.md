# Intent Specification

Status: constructed from public/local evidence only. No hidden tests, evaluator data, internet, or upstream fix knowledge used.

## Intended Behavior

1. During a rolling upgrade to Django 3.1, configuring `DEFAULT_HASHING_ALGORITHM = 'sha1'` must make newly written server-side session data decodable by older instances of the same project.

2. The compatibility mechanism requested by the issue is to use the legacy session data encoding when `DEFAULT_HASHING_ALGORITHM == 'sha1'`.

3. When `DEFAULT_HASHING_ALGORITHM` remains at the Django 3.1 default, session data should keep using the new `signing.dumps(..., compress=True)` storage format.

4. Django 3.1 must continue to decode both the new signing-based format and the legacy pre-3.1 `base64(hash + ':' + serialized)` session format.

5. The intended domain is serializable session dictionaries, with the same `SECRET_KEY`, `SESSION_SERIALIZER`, and session store class/key salt across the participating project instances. Invalid or tampered session payload behavior is outside the reported compatibility defect.

6. The storage compatibility surface is the server-side session-data format used by DB rows, cached DB database rows, file contents, and `BaseSessionManager` saves. The pure cache backend stores dictionaries directly, and the signed-cookie backend uses `django.core.signing` for the cookie value rather than `SessionBase.encode()`.

## Frame Conditions

1. Do not change the public signature of `SessionBase.encode(session_dict)` or `SessionBase.decode(session_data)`.

2. Do not change session serializer selection, session key generation, persistence behavior, expiry behavior, or signed-cookie session key generation.

3. Do not change global signing behavior in `django.core.signing`; the issue is specific to stored session data format selection.

