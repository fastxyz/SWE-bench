# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Byte Methods Decode to Native Method Text

Intent evidence: E1, E2, E3, E4.

Formal claim:

```k
claim
  <k> sessionRequest(bytes(T:Token))
    => prepared(upperToken(T))
  </k>
  requires asciiHttpToken(T)
  [all-path]
```

Required proof steps:

1. `sessionRequest(bytes(T))` expands to `toNative(bytes(T)) ~> upperThenRequest`.
2. `toNative(bytes(T))` rewrites to `nativeText(T)`.
3. The uppercasing continuation rewrites to `nativeText(upperToken(T))`.
4. The request-construction continuation rewrites to `prepared(upperToken(T))`.

Discharge status: satisfied by V1 source, because `method = to_native_string(method)`
matches step 2 for byte input.

## PO-2: Native String Methods Preserve Existing Semantics

Intent evidence: E5, E6.

Formal claim:

```k
claim
  <k> sessionRequest(native(T:Token))
    => prepared(upperToken(T))
  </k>
  requires asciiHttpToken(T)
  [all-path]
```

Required proof steps:

1. `sessionRequest(native(T))` expands to `toNative(native(T)) ~> upperThenRequest`.
2. `toNative(native(T))` rewrites to `nativeText(T)`.
3. Uppercasing and request construction produce `prepared(upperToken(T))`.

Discharge status: satisfied by V1 source, because `to_native_string` is identity
for `builtin_str` values and `method.upper()` remains in place.

## PO-3: No Bytes-Repr Method Reaches the Prepared Request

Intent evidence: E1, E2, E4.

Formal discriminator:

```k
claim
  <k> legacySessionRequest(bytes(T:Token))
    => preparedBytesRepr(upperToken(T))
  </k>
  requires asciiHttpToken(T)
  [all-path]
```

Required proof steps:

1. The legacy path uses `builtinStr(bytes(T))`.
2. `builtinStr(bytes(T))` rewrites to `bytesReprText(T)`.
3. Uppercasing and request construction preserve the bad bytes-repr observable.
4. V1 does not call `builtinStr` in the audited path, so the V1 claim reaches
   `prepared(...)` rather than `preparedBytesRepr(...)`.

Discharge status: satisfied by V1 source, because the `builtin_str` conversion
was removed from `Session.request`.

## PO-4: Public Compatibility Is Preserved

Intent evidence: E5 and the public compatibility audit in `SPEC.md`.

Required proof/audit steps:

1. Confirm `Session.request` signature is unchanged.
2. Confirm `requests.api.request` still forwards the same keyword arguments.
3. Confirm convenience methods still pass native string constants.
4. Confirm adapter dispatch still reads `request.method`.

Discharge status: satisfied by source inspection. No compatibility code edit is
required.

## PO-5: Domain Boundary Is Explicit

Intent evidence: E3, E4, HTTP default-domain convention.

Required proof/audit steps:

1. Restrict byte-method claim to ASCII HTTP method tokens.
2. Do not certify non-ASCII bytes or arbitrary objects as part of this issue.
3. Record any broader direct-preparation behavior as outside the proven slice.

Discharge status: satisfied by the spec. No source edit is justified by public
intent beyond the V1 session-level native-string conversion.
