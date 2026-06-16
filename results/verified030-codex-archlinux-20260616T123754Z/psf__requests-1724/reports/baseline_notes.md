# Baseline Notes

## Root cause

On Python 2, calling `.upper()` on a unicode method such as `u'POST'` returns
unicode. Requests passed that unicode method through to the prepared request and
ultimately into httplib. When httplib built the request line and headers, the
unicode method caused byte request bodies, including multipart file upload
bodies containing non-ASCII bytes, to be coerced through ASCII decoding. That
raised the reported `UnicodeDecodeError`.

## Changed files

`repo/requests/models.py`

- Updated `PreparedRequest.prepare_method()` to convert the uppercased method
  with the existing `to_native_string()` helper. This preserves the existing
  uppercasing behavior while ensuring that Python 2 unicode methods become
  native byte strings before the request is sent.

## Assumptions and alternatives considered

- I assumed HTTP method names should remain ASCII/native-string values at the
  transport boundary. Non-ASCII method names are outside the issue scenario and
  would fail during ASCII native-string conversion instead of being sent as
  unicode.
- I considered changing the `.upper()` calls in `Session.request()` and
  `Session.prepare_request()` because the traceback reaches that path, but the
  actual transport boundary is `PreparedRequest.prepare_method()`. Keeping the
  fix there also covers `Request(...).prepare()` and leaves existing session
  call-site behavior intact.
- I considered adding a new compatibility helper, but `to_native_string()`
  already exists for the same Python 2/3 boundary and is already used to coerce
  header names in `PreparedRequest`.
- I did not modify tests or run code, in keeping with the benchmark
  restrictions.
