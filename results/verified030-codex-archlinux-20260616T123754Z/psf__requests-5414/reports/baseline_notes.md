# Baseline Notes

## Root cause

`PreparedRequest.prepare_url` only IDNA-validates hostnames when they contain
non-ASCII characters. ASCII hostnames are allowed through after only checking
for a leading wildcard. Because `.example.com` is ASCII, it bypasses IDNA
validation even though it has an empty DNS label before `example`. That lets
the prepared request reach lower networking layers, where IDNA encoding raises
a raw `UnicodeError` instead of Requests raising `InvalidURL`.

## Changed files

`repo/requests/models.py`

- Extended the existing ASCII-host validation in `PreparedRequest.prepare_url`
  to reject hostnames that start with `.` or contain `..`.
- Reused the existing `InvalidURL('URL has an invalid label.')` exception path
  so the new behavior matches the established handling for wildcard-prefixed
  ASCII hosts and invalid non-ASCII IDNA labels.
- Left non-ASCII IDNA encoding behavior unchanged.

## Assumptions and alternatives considered

- I treated the issue as an invalid empty-label hostname problem, not as a
  general URL parsing failure, because `parse_url` successfully returns a host
  for `.example.com`.
- I preserved a single trailing dot, such as `example.com.`, because that is a
  common fully qualified domain name form; the fix targets leading or interior
  empty labels that cause the reported failure.
- I considered IDNA-validating every ASCII hostname, but rejected that because
  the existing code deliberately allows ASCII hosts without full IDNA validation
  for compatibility. The targeted empty-label check fixes the reported leak
  without introducing broader hostname policy changes.
- I did not modify tests or run the test suite, in accordance with the task
  constraints.
