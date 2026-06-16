# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## V2 Decision

V1 stands unchanged.

The FVK audit found the original bug as two missing compressed-encoding map
members:

- FVK-F1 / PO-2: `.br` requires `application/x-brotli`.
- FVK-F2 / PO-3: `.Z` requires `application/x-compress`.

The V1 source change already implements both obligations in
`repo/django/http/response.py`.

## No Additional Source Edits

No further code edits are justified by the current public intent:

- Existing `.gz`, `.bz2`, and `.xz` behavior is preserved (FVK-F3 / PO-4).
- `FileResponse` still avoids setting `Content-Encoding` in this branch
  (PO-5).
- Explicit content type and fallback behavior are preserved (PO-6).
- Public call signatures and call protocols are unchanged (PO-7).
- `django.views.static.serve()` remains unchanged because it has a separate
  explicit `Content-Encoding` contract (FVK-F4 / PO-8).

## Suggested Future Checks Outside This Task

If execution were allowed, run the recorded FVK commands in `PROOF.md` and the
relevant Django response tests. Add focused tests for:

```python
FileResponse(open("test.html.br", "rb"))
FileResponse(open("test.html.Z", "rb"))
```

with expected `Content-Type` values `application/x-brotli` and
`application/x-compress`, respectively, and no `Content-Encoding` header.

These suggestions are not applied here because the task forbids running code and
modifying test files.
