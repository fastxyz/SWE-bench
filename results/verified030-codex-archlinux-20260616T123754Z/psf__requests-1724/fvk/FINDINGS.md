# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof obligations only.

## F-001: Python 2 unicode method reaches transport as unicode

Classification: code bug, fixed by V1.

Input:

```python
requests.request(method=u'POST', url=u'http://httpbin.org/post', files=files)
```

Observed before V1: the prepared method could remain Python 2 unicode. When
httplib concatenated request-line/header unicode with a multipart byte body, it
attempted ASCII decoding of non-ASCII body bytes and raised the reported
`UnicodeDecodeError`.

Expected: for ASCII method token `POST`, the prepared method reaching transport
is native Python 2 `str` containing `POST`, the same transport type used when
the caller passes `'POST'`.

Evidence: E-001, E-002, E-003, E-006.

Resolution: V1 changes `PreparedRequest.prepare_method()` to assign
`to_native_string(self.method.upper())`. This discharges PO-001 and PO-002 for
prepared request construction paths.

## F-002: Non-ASCII method names are outside the proven domain

Classification: domain boundary / underspecified intent.

Input example:

```python
requests.Request(method=u'P\u00d8ST', url='http://example.test').prepare()
```

Observed under V1 reasoning: `to_native_string(..., encoding='ascii')` would not
define a native Python 2 byte string for non-ASCII method text.

Expected from public intent: no positive public evidence requires non-ASCII
HTTP method names. The issue uses `u'POST'` to mean a unicode object containing
an ASCII HTTP method token.

Evidence: E-002, E-004.

Resolution: no source change. The FVK spec explicitly scopes the fix to ASCII
HTTP method tokens.

## F-003: No public method-native regression test is present

Classification: test gap, no test files modified.

Input:

```python
requests.Request(method=u'POST', url='http://example.test').prepare()
```

Observed public tests: there are public tests that prepared header keys become
native strings and that unicode request data works, but no visible test asserts
that prepared methods are native strings.

Expected: a future public regression test should assert both value and native
type for a unicode ASCII method on Python 2.

Evidence: E-003, E-005.

Resolution: no test changes in this task. The hidden/fixed suite remains the
test target; this finding only recommends a visible regression test for a future
non-benchmark change.

## Proof-derived findings from `/verify`

No proof obligation required a further source edit beyond V1. The only
nontrivial side condition is PO-004: method text must be an ASCII HTTP method
token for `to_native_string(..., 'ascii')` to be defined on Python 2 unicode.
That side condition is supported by public intent and is recorded as F-002, not
as a remaining code bug.

