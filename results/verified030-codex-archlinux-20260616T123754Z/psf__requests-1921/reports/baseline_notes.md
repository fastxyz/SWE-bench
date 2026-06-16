# Baseline Notes

## Root cause

`Session.prepare_request()` merges per-request headers with `Session.headers`
through `merge_setting()`. That helper already treated `None` as a deletion
sentinel, but only when the `None` value came from the request-level mapping.
When a default session header was set to `None`, the merged headers retained
that key and the prepared request later serialized the value as the literal
header value `None`.

## Files changed

- `repo/requests/sessions.py`: changed `merge_setting()` to remove keys whose
  final merged value is `None`, instead of checking only the request-level
  mapping. This preserves request-level overrides while allowing session-level
  `None` values to suppress default headers.

## Assumptions

- A session header value of `None` is intended to mean "omit this header" when
  preparing a request, matching the already-supported per-request behavior.
- The session's stored headers should not be mutated during preparation; the
  sentinel can remain in `Session.headers` so it continues suppressing that
  default header on future prepared requests.
- If a request explicitly supplies a non-`None` value for a header whose session
  value is `None`, the explicit request value should still be sent because
  request settings override session settings before deletion is applied.

## Alternatives considered

- Deleting keys from `Session.headers` when they are assigned `None` was
  rejected because it would require changing the header dictionary behavior and
  would mutate user-visible session state as a side effect.
- Filtering only in `PreparedRequest.prepare_headers()` was rejected because the
  bug is in the merge semantics, and `merge_setting()` is already where
  `None` sentinels are handled for request-level mappings.
- Leaving `del session.headers[...]` as the only supported permanent removal
  mechanism was rejected because the issue describes the analogous
  request-level `None` behavior as supported and identifies the current session
  behavior as surprising.
