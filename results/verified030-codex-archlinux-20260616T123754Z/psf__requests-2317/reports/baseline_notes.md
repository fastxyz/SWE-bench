Root cause:

`Session.request` normalized the supplied HTTP method with `builtin_str(method)`.
On Python 3, calling `str()` on a byte string such as `b'GET'` produces the
literal text `"b'GET'"` instead of decoding it to `"GET"`. That malformed method
was then uppercased and sent through request preparation, so callers that passed
byte-string methods could send an invalid HTTP method.

Changed files:

`repo/requests/sessions.py`

- Replaced `builtin_str(method)` with `to_native_string(method)`, the existing
  compatibility helper used elsewhere in this module for converting bytes to
  the native string type.
- Removed the now-unused `builtin_str` import from `requests.compat`.

`reports/baseline_notes.md`

- Added this report describing the cause, the source change, and the reasoning.

Assumptions and alternatives:

- I assumed the intended behavior is to accept ASCII byte-string HTTP methods
  such as `b'GET'` and normalize them to native strings before uppercasing.
  HTTP method tokens are ASCII, which matches `to_native_string`'s default
  encoding.
- I considered changing `PreparedRequest.prepare_method`, but the reported
  failure and public hint identify the `Session.request` conversion specifically.
  Keeping the change there preserves the existing preparation behavior while
  fixing the path used by `requests.request()` and `Session.request()`.
- I did not add or modify tests because the task requires source-only changes
  and hidden tests are fixed by the benchmark.
