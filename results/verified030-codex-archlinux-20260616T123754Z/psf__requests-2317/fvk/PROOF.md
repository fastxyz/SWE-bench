# FVK Proof

Status: constructed, not machine-checked. The K commands below were recorded for
future checking and were not run.

## Reproduce the Machine Check Later

```sh
kompile fvk/mini-requests-method.k --backend haskell
kast --backend haskell fvk/session-request-method-spec.k
kprove fvk/session-request-method-spec.k
```

Expected result after machine checking: `#Top` for the claims in
`fvk/session-request-method-spec.k`.

## Trusted Base

- The mini-K semantics faithfully models only the method-normalization slice of
  `Session.request`.
- `toNative(bytes(T)) => nativeText(T)` corresponds to
  `to_native_string(method)` on Python 3 byte strings in the ASCII token domain.
- `toNative(native(T)) => nativeText(T)` corresponds to `to_native_string` being
  identity for native strings.
- `builtinStr(bytes(T)) => bytesReprText(T)` models the pre-V1 Python 3
  `str(bytes)` behavior reported in the issue.

## Proof of PO-1

Start with:

```k
<k> sessionRequest(bytes(T)) </k>
```

Symbolic execution applies the V1 session rule:

```k
toNative(bytes(T)) ~> upperThenRequest
```

The native-string conversion rule decodes byte input:

```k
nativeText(T) ~> upperThenRequest
```

The upper continuation applies `upperToken` to the native token:

```k
nativeText(upperToken(T)) ~> makeRequest
```

The request-construction continuation yields:

```k
prepared(upperToken(T))
```

This is exactly the postcondition of PO-1. No rule on this path produces
`bytesReprText`.

## Proof of PO-2

Start with:

```k
<k> sessionRequest(native(T)) </k>
```

Symbolic execution applies the same V1 session rule:

```k
toNative(native(T)) ~> upperThenRequest
```

The native-string conversion rule is identity for native input:

```k
nativeText(T) ~> upperThenRequest
```

Uppercasing and request construction yield:

```k
prepared(upperToken(T))
```

This preserves the existing native string method behavior.

## Proof of PO-3

The legacy discriminator starts with:

```k
<k> legacySessionRequest(bytes(T)) </k>
```

The legacy session rule uses `builtinStr`:

```k
builtinStr(bytes(T)) ~> upperThenRequest
```

For byte input, the legacy conversion produces the bytes-repr observable:

```k
bytesReprText(T) ~> upperThenRequest
```

Uppercasing and request construction yield:

```k
preparedBytesRepr(upperToken(T))
```

The V1 session rule uses `toNative`, not `builtinStr`, so the legacy proof is a
discriminator showing the reported bug is removed from the audited path.

## Proof of PO-4

Source inspection establishes that V1 changed only the implementation expression
inside `Session.request`:

```python
method = to_native_string(method)
```

The method signature, construction of `Request`, preparation, environment
setting merge, and adapter dispatch shape remain unchanged. Convenience methods
still pass native string literals and therefore follow PO-2.

## Adequacy and Completeness Check

The English paraphrase in `SPEC.md` matches the public intent: byte-string
methods on the session request path become native uppercase method tokens, and
bytes-repr text is excluded. The proof covers both in-domain byte methods and
native string methods for the changed public path.

The proof deliberately does not cover direct `Request.prepare()` byte-method
normalization. `FINDINGS.md` records that as underspecified rather than silently
certifying it.

## Test Recommendation

Do not delete tests. The proof is constructed, not machine-checked, and this
benchmark forbids modifying test files.

Useful future tests, if test editing were allowed in another context:

- `Session.request(b'GET', ...)` prepares method `GET`.
- `requests.request(b'GET', ...)` follows the same path through `Session`.
- `Session.request('get', ...)` still prepares method `GET`.
