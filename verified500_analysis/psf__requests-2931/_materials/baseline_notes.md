# Baseline Notes

## Root cause

`PreparedRequest.prepare_body` used `_encode_params` for every non-file,
non-stream truthy `data` value. `_encode_params` treats both text strings and
bytes as string-like input and calls `to_native_string` on them. On Python 3,
`to_native_string` decodes bytes with ASCII by default, so a raw binary request
body containing non-ASCII UTF-8 bytes, such as repeated `\xc3\xb6` sequences,
raises during request preparation instead of being preserved as the request
body.

The same helper is also used by `prepare_url` for query parameters. In that
context, bytes query strings must still be converted to a native text string so
URL assembly continues to work.

## Files changed

`repo/requests/models.py`

- Updated `PreparedRequest.prepare_body` so raw bytes passed as `data` are
  assigned directly to `body`.
- Left dictionaries, lists, tuples, text strings, file-like objects, multipart
  data, and URL parameter encoding on their existing paths.

`reports/baseline_notes.md`

- Added this report with the root cause, changed files, assumptions, and
  rejected alternatives.

## Assumptions and alternatives considered

I assumed the issue is limited to raw bytes request bodies, not form fields. A
mapping such as `data={"field": value}` should continue to be form-encoded by
`_encode_params`, including its existing UTF-8 handling for text values.

I rejected changing `to_native_string` because it is a shared compatibility
helper used for methods, URLs, headers, auth, and redirects. Making it preserve
bytes globally would alter unrelated call sites.

I rejected changing `_encode_params` to return bytes unchanged in all cases
because `prepare_url` uses it for query strings, and the existing behavior
expects `params=b"test=foo"` to become a usable native URL query string.

I rejected broadening the fix to other binary-like types such as `bytearray`
because the reported regression is specifically for bytes, and this codebase
already treats other iterable non-string values differently during body
preparation.
