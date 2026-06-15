# FVK Specification

Status: constructed, not machine-checked.

## Scope

The audited unit is the stored session data encoding/decoding contract centered on `SessionBase.encode()` in `repo/django/contrib/sessions/backends/base.py`.

Domain:

- `session_dict` is serializable by `settings.SESSION_SERIALIZER`.
- Participating instances use the same `SECRET_KEY`, serializer, and session store class/key salt.
- `settings.DEFAULT_HASHING_ALGORITHM` is either `'sha1'` or `'sha256'`, matching Django's setting validation.
- The property concerns stored server-side session data, not the pure cache backend's direct dictionary storage or the signed-cookie backend's cookie-value signing path.

## Abstract Definitions

Let `serialize(D)` be the configured session serializer's byte output for session dictionary `D`.

Let `legacy_hash(C, B)` be `_hash(B)` for store class `C`, using the existing legacy key salt `"django.contrib.sessions" + C.__name__`.

Let `legacy_format(C, D)` be:

```text
base64(legacy_hash(C, serialize(D)) + ":" + serialize(D))
```

Let `signed_format(C, D)` be the Django 3.1 signing-based format produced by:

```text
signing.dumps(D, salt=key_salt(C), serializer=serializer, compress=True)
```

## Public Intent Ledger Summary

- `E1`, `E2`, `E3`: the issue requires transition-mode writes to use legacy session data encoding when `DEFAULT_HASHING_ALGORITHM == 'sha1'`.
- `E4`, `E5`: public docs describe `DEFAULT_HASHING_ALGORITHM` as a compatibility setting that includes user sessions.
- `E6`: existing `_legacy_decode()` defines the old session data format exactly.
- `E7`: pre-fix `encode()` always wrote `signed_format`, which is the reported mismatch in transition mode.
- `E8`: server-side encoded storage consumers all route through `SessionBase.encode()` or a store class delegating to it.

## Function Contract

For every in-domain store class `C`, session dictionary `D`, and algorithm `A`:

1. If `A == 'sha1'`, `SessionBase.encode(D)` returns `legacy_format(C, D)`.

2. If `A == 'sha256'`, `SessionBase.encode(D)` returns `signed_format(C, D)`.

3. The legacy decoder from older Django versions decodes `legacy_format(C, D)` to `D`.

4. Django 3.1 `SessionBase.decode()` decodes both `legacy_format(C, D)` and `signed_format(C, D)` to `D`.

5. Public method signatures and storage call shapes are unchanged.

## Formal Artifacts

- `fvk/mini-session-format.k`: minimal K semantics for format selection and decode compatibility.
- `fvk/session-encode-spec.k`: K reachability claims for the contract above.

The K model deliberately abstracts cryptographic and serialization internals into uninterpreted constructors while preserving the property under test: the observable storage format shape and whether a legacy decoder can recover the original session data.

