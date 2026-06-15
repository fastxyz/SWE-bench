# Public Evidence Ledger

## E-001

Source: `benchmark/PROBLEM.md`

Quoted evidence: `HttpResponse doesn't handle memoryview objects`

Semantic obligation: `HttpResponse` must handle memoryview body values.

Status: encoded by I-003 and K claims `MAKE-BYTES-MEMORYVIEW` and `CONTENT-MEMORYVIEW`.

## E-002

Source: `benchmark/PROBLEM.md`

Quoted evidence: `# memoryview content` followed by `response = HttpResponse(memoryview(b"My Content"))` and `I am expecting b'My Content'`

Semantic obligation: Direct regular `HttpResponse` construction from a memoryview must expose the underlying bytes as `.content`.

Status: encoded by I-003 and I-004.

## E-003

Source: `benchmark/PROBLEM.md`

Quoted evidence: `String content` and `Bytes content` examples are marked `This is correct`.

Semantic obligation: The fix must not regress existing string or bytes response content behavior.

Status: encoded by I-001, I-002, and I-006.

## E-004

Source: `benchmark/PROBLEM.md`

Quoted evidence: `make_bytes could be adapted to deal with memoryview objects by casting them to bytes`

Semantic obligation: The shared conversion helper must recognize memoryview and return `bytes(value)`.

Status: encoded by I-005 and K claim `MAKE-BYTES-MEMORYVIEW`.

## E-005

Source: `benchmark/PROBLEM.md`

Quoted evidence: `simply wrapping the memoryview in bytes works as a workaround`

Semantic obligation: The intended memoryview conversion is exactly the Python `bytes(memoryview_value)` conversion, not stringification.

Status: encoded by I-003 and I-005.

## E-006

Source: `repo/django/utils/encoding.py`

Quoted evidence: `if isinstance(s, memoryview): return bytes(s)`

Semantic obligation: Django already has public internal precedent that memoryview is a bytes-like input for byte conversion helpers.

Status: supporting evidence for I-005.

## E-007

Source: `repo/docs/ref/models/fields.txt`

Quoted evidence: `BinaryField` stores raw binary data and can be assigned `bytes`, `bytearray`, or `memoryview`.

Semantic obligation: A database `BinaryField` value that arrives as memoryview is raw binary content, not text or object representation.

Status: supporting evidence for I-003.

## E-008

Source: `repo/django/http/response.py`

Quoted evidence: `Per PEP 3333, this response body must be bytes.`

Semantic obligation: Every regular response body conversion must result in bytes.

Status: encoded across all claims.

## E-009

Source: `repo/django/http/response.py`

Quoted evidence: `Consume iterators upon assignment to allow repeated iteration.`

Semantic obligation: Existing non-scalar iterable content should keep being consumed as chunks.

Status: encoded by I-006 and K claim `CONTENT-ITERABLE-FRAME`.
