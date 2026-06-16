# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 did not fully satisfy the FVK spec because it missed the public constructor
case `Request('GET', url, data=None)`. V2 addresses that by normalizing
`data=None` to `{}` in `Request.__init__`, so explicit `None` follows the same
bodyless path as omitted data.

## Do not broaden without new intent

Do not change `HEAD` or explicit empty iterable handling in this iteration.
FINDING F5 marks those as underspecified. A later issue or user clarification
should decide whether they belong to the same no-auto-`Content-Length` rule.

## Suggested public tests for a future test-authoring pass

Do not add tests in this benchmark task. If tests are later allowed, cover:

- `Request('GET', url).prepare()` has no automatic `Content-Length`.
- `Request('GET', url, data=None).prepare()` has no automatic `Content-Length`.
- `requests.get(url)` sends no automatic `Content-Length` on the prepared
  request.
- `Request('GET', url, data={'a': 'b'}).prepare()` still has `Content-Length`.
- `Request('POST', url).prepare()` still has `Content-Length: 0`.
- Explicit user `Content-Length` on a bodyless `GET` is preserved.

## Machine-check next step

The proof is only constructed. To upgrade it to machine-checked, run the
commands in `fvk/PROOF.md` in an environment with K installed and keep all tests
until `kprove` returns `#Top`.
