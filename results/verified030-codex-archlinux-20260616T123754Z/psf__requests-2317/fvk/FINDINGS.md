# FVK Findings

Status: findings derived from public intent, source inspection, and constructed
proof obligations. No tests or project code were run.

## FVK-F1: Reported Byte-Method Bug Is Fixed by V1

Classification: code bug, resolved.

Trace: PO-1, PO-3.

Input: `Session.request(b'GET', url, ...)` on Python 3.

Pre-V1 observed behavior by source reasoning: `builtin_str(b'GET')` produced the
native text representation `"b'GET'"`; after uppercasing, that bytes-repr text
could reach the prepared request as a malformed method.

Expected behavior from public intent: the prepared method is native `GET`.

V1 behavior by source reasoning: `to_native_string(b'GET')` decodes to native
`GET`; uppercasing preserves `GET`; the prepared method is native `GET`.

Recommended action: keep V1 for this path.

## FVK-F2: Native String Method Behavior Is Preserved

Classification: compatibility finding, resolved.

Trace: PO-2, PO-4.

Input: `Session.request('get', url, ...)` or any convenience method that passes a
native method string.

Observed V1 behavior by source reasoning: `to_native_string('get')` returns the
same native string, then `method.upper()` produces `GET`.

Expected behavior: existing native string method calls continue to produce the
uppercase native token.

Recommended action: no further source change.

## FVK-F3: Direct Request Preparation With Byte Methods Is Underspecified

Classification: underspecified extension, not a V2 code bug for this task.

Trace: PO-5.

Input class considered: `Request(method=b'GET', url=...).prepare()` or
`Session.prepare_request(Request(method=b'GET', ...))`.

Observation by source inspection: this direct path does not pass through the
reported `method = builtin_str(method)` line. It may preserve a byte method
through `method.upper()`, but it does not create the issue's `"b'GET'"` literal
via `builtin_str(bytes)`.

Public-intent analysis: the problem statement and public hint identify the
`Session.request` conversion and specifically say it should be replaced with the
native-string helper. There is not enough public evidence to require a broader
change in `PreparedRequest.prepare_method` for this task.

Rejected alternative: moving or duplicating normalization in
`PreparedRequest.prepare_method`. That could be a coherent future hardening, but
it changes a lower-level public preparation behavior not named by the issue.

Recommended action: leave V1 unchanged unless a separate public requirement says
direct preparation must also coerce byte methods to native strings.

## FVK-F4: Non-ASCII Byte Methods Remain Outside the Proven Domain

Classification: explicit domain boundary.

Trace: PO-5.

Input: a non-ASCII byte-string method.

Expected behavior under this spec: not specified. HTTP method tokens are ASCII,
and `to_native_string` defaults to ASCII decoding.

Recommended action: no source change for this issue. A future task that wants
custom non-ASCII method handling should specify the desired error or decoding
policy explicitly.
