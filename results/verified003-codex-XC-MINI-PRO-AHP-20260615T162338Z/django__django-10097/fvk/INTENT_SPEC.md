# Intent Spec

Status: constructed from public evidence only. Current code behavior is treated
as candidate behavior to audit, not as the specification.

## Required behavior

1. `URLValidator` must continue to accept URLs with ordinary authentication
   forms: `username@host` and `username:password@host`.
2. Inside the username value and inside the password value, raw `:`, raw `@`,
   and raw `/` are invalid. They must be percent-encoded when they are data
   rather than URL syntax.
3. The single `:` separating username from password remains URL syntax, not part
   of either field.
4. A raw `@` may terminate the userinfo component, but another raw `@` inside a
   username or password value must not be accepted.
5. The authentication branch must not consume URL component delimiters before the
   host. In particular, raw `/`, `?`, and `#` before the host must prevent the
   preceding text from being treated as credentials.
6. The reported example `http://foo/bar@example.com` must be invalid.
7. Invalid URLs in `tests/validators/invalid_urls.txt` must not become valid
   merely by appending a query string such as `?m=foo@example.com`.
8. Percent-encoded delimiters in userinfo remain acceptable under the existing
   validator style, which does not reject `%` in URL components.
9. Public API compatibility must be preserved: `URLValidator.__call__`,
   constructor arguments, error type, and default validator usage must not
   change.

## Domain and frame conditions

The audited domain is URL strings processed by `URLValidator` after scheme
checking. The proof is partial correctness: if the validator returns normally,
it accepts only URLs satisfying the userinfo delimiter obligations above; if a
URL violates those obligations, it raises `ValidationError`.

This FVK pass does not attempt to prove the whole Python `re` engine, IDNA
encoding, host grammar, IPv6 grammar, or URL length checks. Those remain part of
Django's existing validator behavior and are framed except where they interact
with userinfo delimiter parsing.
