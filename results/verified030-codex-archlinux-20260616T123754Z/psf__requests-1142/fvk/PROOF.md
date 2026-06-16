# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## K artifacts

- Semantics fragment: `fvk/mini-python.k`
- Claims: `fvk/requests-content-length-spec.k`

Exact commands to machine-check later:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/requests-content-length-spec.k
kprove fvk/requests-content-length-spec.k --definition mini-python-kompiled
```

Expected machine-check result after installing/configuring K: `#Top` for all
claims.

## Proof outline

### PO1 / claim GET-NO-BODY

In V2, `prepare_content_length` first checks `body is None and self.method ==
'GET'`. When true, it returns before any write to `self.headers`. Therefore, if
`Content-Length` was absent before the call, it remains absent after the call.

### PO2 / claim GET-BODY

When `body is not None`, the bodyless-GET guard is false. Execution reaches the
existing logic that initializes `Content-Length` to `0` and then, for seekable or
length-bearing bodies, overwrites it with the computed length. Thus actual
`GET` bodies still carry `Content-Length`.

### PO3 / claim OTHER-NO-BODY

When the method is not `GET`, the early return is false even if `body is None`.
Execution reaches the unchanged initialization `self.headers['Content-Length'] =
'0'`. Non-`GET` bodyless behavior is preserved.

### PO4 / claim GET-EXPLICIT-CL

For bodyless `GET`, the method returns before mutating headers. If the caller
explicitly supplied `Content-Length`, it remains present. This proof is a frame
condition: no header write occurs on that branch.

### PO5 / claim GET-NONE-DATA

V1 normalized `data=None` to `[]`, which made `prepare_body` classify it as a
stream and write `Content-Length: 0`. V2 normalizes `data=None` to `{}`. In
`prepare_body`, `{}` is a dict, so `is_stream` is false; it is also falsey, so no
body is encoded and `body` remains `None`. For method `GET`, PO1 then applies,
leaving `Content-Length` absent.

### PO6 / auth recomputation

`prepare_auth` calls `prepare_content_length(self.body)` after auth mutation.
For a bodyless `GET` where auth does not add a body, `self.body` is still
`None`, so the same PO1 branch returns without adding the header.

### PO7 / compatibility

Both edited methods keep their public signatures. `Request.__init__` still
stores a `data` attribute; it only maps explicit `None` to the same empty-dict
no-body value already used by omitted data. No virtual dispatch call gains a new
argument.

## Test recommendation

No tests were run or modified. Existing tests that merely check one in-domain
instance of bodyless `GET` header omission would be subsumed only after the K
claims are actually machine-checked. Integration/network tests, auth integration
tests, non-GET behavior tests, and tests for underspecified inputs such as
`HEAD` or explicit empty iterable data should be kept.
