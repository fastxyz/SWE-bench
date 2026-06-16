# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent
and source inspection only; no tests or code were run.

## F1 - V1 missed `Request(..., data=None)` bodyless GET

- Classification: code bug in V1.
- Evidence: `Request.__init__` documented `data` as the request body, while V1
  still normalized `data=None` to `[]`.
- Input: `requests.Request('GET', url, data=None).prepare()`.
- V1 observed by source reasoning: `data` becomes `[]`; `prepare_body` treats an
  iterable non-dict as a stream; `super_len([])` is `0`; the stream path writes
  `Content-Length: 0`.
- Expected: `data=None` means no body, so the bodyless `GET` must not receive an
  automatic `Content-Length`.
- Resolution: V2 changes `data=None` normalization to `{}`, matching omitted
  data. This makes `prepare_body` compute `body is None`, after which
  `prepare_content_length`'s bodyless-GET guard suppresses the automatic header.
- Related obligations: PO1, PO5.

## F2 - Original automatic header defect is fixed for the normal GET path

- Classification: confirmed code bug fixed by V1 and retained by V2.
- Evidence: issue text says "`requests.get` always adds 'content-length'" and
  "the right behavior is not to add this header automatically in GET requests."
- Input: `requests.get(url)` or `Request('GET', url)` with data omitted.
- Pre-fix observed by source reasoning: `prepare_content_length(None)` wrote
  `Content-Length: 0` before inspecting `body`.
- V2 expected and derived: `method == 'GET'` and `body is None` returns before
  adding the header.
- Related obligations: PO1, PO6.

## F3 - GET with an actual body still gets Content-Length

- Classification: required preservation.
- Evidence: public discussion says "There's nothing stopping you from sending
  data in a GET request."
- Input: `Request('GET', url, data={'a': 'b'}).prepare()`.
- Expected: prepared body has a concrete encoded length and receives
  `Content-Length`.
- V2 source reasoning: `body` is not `None`, so the `GET` early return does not
  fire; existing length logic runs.
- Related obligation: PO2.

## F4 - Non-GET bodyless behavior remains unchanged

- Classification: required preservation.
- Evidence: issue context says the previous change was "Attach Content-Length to
  everything"; the new issue objects specifically to `GET`.
- Input: `Request('POST', url).prepare()` with no body.
- Expected for this scoped fix: continue adding `Content-Length: 0`.
- V2 source reasoning: method is not `GET`, so the early return does not fire.
- Related obligation: PO3.

## F5 - HEAD and explicit empty iterables are not resolved by this issue

- Classification: underspecified intent / follow-up question.
- Evidence: public issue is framed around `requests.get` and `GET`. It does not
  define whether `HEAD` or explicit empty iterable body values such as `data=[]`
  should follow the same no-header rule.
- Input examples: `Request('HEAD', url).prepare()`,
  `requests.get(url, data=[])`.
- V2 behavior by source reasoning: `HEAD` still gets `Content-Length: 0`; an
  explicit empty iterable still enters the stream branch and can get
  `Content-Length: 0`.
- Expected: ambiguous from allowed public evidence.
- Recommendation: ask whether bodyless `HEAD` and explicit empty iterable data
  should be treated like default/bodyless `GET`. Do not broaden this patch
  without that intent.
