# Baseline Notes

## Root cause

`URLValidator` used `(?:\S+(?::\S*)?@)?` for optional `user:pass@`
authentication. Because `\S` accepts any non-whitespace character, the
authentication branch could consume URL delimiters such as `/`, `?`, `#`, raw
`@`, and extra raw `:` characters before the host. That allowed invalid input
such as `http://foo/bar@example.com` to be interpreted as credentials plus a
valid host instead of as an invalid host/path combination.

## Files changed

`repo/django/core/validators.py`

Added a `userinfo_re` component for the authentication part of `URLValidator`
and replaced the broad `\S` authentication pattern with it. The new pattern
allows the existing `username` and `username:password` shapes, including empty
passwords, but rejects raw URL delimiters inside the username and password
values. Percent-encoded delimiters still match because the validator already
permits `%` in this part of the URL.

`reports/baseline_notes.md`

Added this report to document the cause, the source edit, and the assumptions
behind the fix.

## Assumptions and alternatives considered

I treated the single colon between username and password as the URL syntax
separator, not as part of either field. Raw additional colons are rejected so
that colons inside the username or password must be percent-encoded.

I also excluded `?` and `#` from the authentication branch. They were not named
in the RFC quote in the issue, but allowing them would preserve the same class
of bug where an invalid URL can be made to look valid by placing `@example.com`
in a query string or fragment.

I considered validating credentials after `urlsplit()`, but that would not catch
the main failure mode because `urlsplit()` parses `http://foo/bar@example.com`
with `foo` as the netloc and `/bar@example.com` as the path. The regex must stop
the authentication branch from consuming delimiters in the first place.
