# Intent-Only Specification

This file intentionally describes required behavior before accepting any
candidate implementation as the specification.

1. `method='POST'` and `method=u'POST'` represent the same ASCII HTTP method
   token and must prepare to the same transport method value.
2. On Python 2, the transport method value must be a native byte string, not
   unicode, so it cannot force ASCII decoding of a byte request body.
3. Existing method uppercasing is intended behavior and must be preserved.
4. The issue requires support for unicode objects containing ASCII HTTP method
   names. It does not establish support for non-ASCII HTTP method names.
5. The public API shape must remain unchanged.

