# Baseline Notes

## Root cause

`PreparedRequest.prepare_body` calls `prepare_content_length` for normal,
non-streaming requests regardless of HTTP method. `prepare_content_length`
started by unconditionally setting `Content-Length` to `0`, so a default
`GET` request with no body was still prepared with a zero-length body header.
That is the header pattern described in the issue as causing some servers to
reject otherwise normal `GET` requests.

## Files changed

`repo/requests/models.py`

- Added an early return in `PreparedRequest.prepare_content_length` when the
  prepared request is a `GET` and the computed body is `None`.
- Left existing length calculation in place for `GET` requests that do have a
  body, and left non-`GET` zero-length behavior unchanged.

`reports/baseline_notes.md`

- Added this report describing the root cause, the source change, and the
  assumptions behind the fix.

## Assumptions and alternatives considered

- I treated the issue as applying to default/bodyless `GET` requests. A `GET`
  request with explicit body data should still receive a computed
  `Content-Length`, because the issue discussion notes that a `GET` request can
  carry data.
- I preserved explicitly supplied `Content-Length` headers on bodyless `GET`
  requests. The new branch only avoids adding the automatic default when there
  is no body.
- I kept the change out of the adapter layer because the incorrect header is
  created during request preparation, before transport selection.
- I considered suppressing automatic `Content-Length: 0` for other bodyless
  methods such as `HEAD`, but rejected that as broader than the reported `GET`
  behavior and potentially conflicting with the earlier "attach Content-Length"
  behavior for other methods.
