# SPEC

Status: FVK formalization for `django__django-10097`, constructed, not
machine-checked.

## Unit Under Audit

Production unit: `repo/django/core/validators.py`, `URLValidator`.

Changed source expression:

```python
userinfo_re = r'[^\s:/@?#]+(?::[^\s:/@?#]*)?'
```

The old expression was:

```python
r'(?:\S+(?::\S*)?@)?'
```

## Intent Ledger

The public evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

Required obligations:

1. Reject raw `:`, `@`, and `/` when they appear as data inside username or
   password fields.
2. Preserve one raw `:` as the username/password separator.
3. Preserve ordinary `username@host` and `username:password@host` URLs.
4. Preserve percent-encoded delimiters in userinfo.
5. Prevent the auth branch from consuming `/`, `?`, or `#` before the host,
   because those delimiters begin path, query, or fragment components.
6. Keep public API shape and downstream default validator use unchanged.

Conflicting public-test evidence:

`tests/validators/valid_urls.txt` line 51 contains raw extra colons in userinfo.
Under the FVK intent-evidence rules this is SUSPECT legacy evidence because it
directly conflicts with the issue's RFC-derived obligation.

## Formal Model

The K model in `fvk/mini-urlvalidator.k` is a minimal URL-validator fragment.
It does not model Python's regex engine as a whole. It models the property axis
under audit:

- allowed scheme;
- optional userinfo;
- cleanliness of userinfo fields;
- host and tail validity;
- final `valid` or `invalid` result.

The model preserves the discriminator needed for this bug: a clean credential
field and an unclean credential field map to different observable results when
scheme, host, and tail are held fixed.

## Intended Contract

For every URL in the audited domain:

- if userinfo is present and either credential field contains raw `:`, `@`, `/`,
  `?`, or `#`, `URLValidator` rejects the URL;
- if userinfo is present and follows `user@host` or `user:password@host` with
  clean fields, a valid scheme, valid host, valid port, and valid tail, this
  fix does not reject it;
- if an invalid host is followed by `?m=foo@example.com`, the `?` remains a URL
  delimiter rather than part of userinfo, so the URL remains invalid;
- percent-encoded delimiters such as `%40`, `%2f`, and `%3A` are not raw
  delimiters and remain acceptable in userinfo under this validator.

## Boundaries

The proof is partial correctness and constructed only. It does not prove:

- termination of Python regex matching;
- exact Python `re` backtracking semantics;
- the full host grammar;
- IDNA correctness;
- IPv6 correctness;
- max-length behavior.

These are framed because the issue and patch only change userinfo delimiter
recognition.
