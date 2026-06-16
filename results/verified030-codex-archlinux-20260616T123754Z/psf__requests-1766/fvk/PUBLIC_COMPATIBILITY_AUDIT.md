# Public Compatibility Audit

Status: constructed from repository search; not machine-checked.

## Changed Symbol

`requests.auth.HTTPDigestAuth.build_digest_header(self, method, url)`

## Compatibility Checks

- Signature: unchanged.
- Return type shape: unchanged (`str` Digest header or `None` on unsupported branches).
- Public constructor: `HTTPDigestAuth(username, password)` unchanged.
- Internal callsites: `handle_401` and `__call__` still call `self.build_digest_header(method, url)` with the same arguments.
- In-tree overrides/subclasses: none found by repository search for `build_digest_header`, `HTTPDigestAuth`, and digest-auth class names.
- Public docs: examples construct `HTTPDigestAuth('user', 'pass')`; no documented direct call to `build_digest_header`.

## Compatibility Result

No public API or dispatch compatibility issue was introduced. The externally visible header string changes only in the qop directive/value, which is the intended behavior from the issue.

