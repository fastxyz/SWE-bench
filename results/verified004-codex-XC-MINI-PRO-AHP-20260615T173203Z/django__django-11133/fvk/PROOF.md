# Constructed Proof

Status: constructed, not machine-checked. No tests, Python snippets, `kompile`, or `kprove` were run.

## Claims Proved in the Constructed Model

- `MAKE-BYTES-MEMORYVIEW`
- `CONTENT-MEMORYVIEW`
- `CONTENT-BYTES-FRAME`
- `CONTENT-STRING-FRAME`
- `CONTENT-ITERABLE-FRAME`

The K artifacts are `mini-python-response.k` and `http-response-spec.k`.

## Proof Sketch

### MAKE-BYTES-MEMORYVIEW

Initial state: `<k> makeBytes(memoryView(PAYLOAD), C) </k>`.

Semantic rule used: `makeBytes(memoryView(S), _) => outBytes(S)`.

Substitution: `S := PAYLOAD`.

Result: `<k> outBytes(PAYLOAD) </k>`, matching the claim.

Corresponding source branch: `if isinstance(value, memoryview): return bytes(value)`.

### CONTENT-MEMORYVIEW

Initial state: `<k> setContent(memoryView(PAYLOAD), C) </k> <container> .List </container>`.

Step 1: `isScalarContent(memoryView(PAYLOAD)) => true`, so the scalar content-assignment rule applies and rewrites to `makeBytes(memoryView(PAYLOAD), C) ~> storeContent`.

Step 2: by `MAKE-BYTES-MEMORYVIEW`, `makeBytes(memoryView(PAYLOAD), C)` rewrites to `outBytes(PAYLOAD)`.

Step 3: `outBytes(PAYLOAD) ~> storeContent` stores `ListItem(outBytes(PAYLOAD))` in `<container>` and leaves `<k> .K </k>`.

Corresponding source branches: the content setter's iterable condition excludes `memoryview`, so the `else` branch calls `self.make_bytes(value)`; `make_bytes()` returns `bytes(value)`.

### CONTENT-BYTES-FRAME

Initial state: `<k> setContent(bytesValue(PAYLOAD), C) </k>`.

The scalar rule applies because bytes are scalar content. `makeBytes(bytesValue(PAYLOAD), C)` rewrites to `outBytes(PAYLOAD)`, then `storeContent` writes one container item.

Corresponding source branches: unchanged bytes exclusion in the content setter and unchanged `if isinstance(value, bytes): return bytes(value)`.

### CONTENT-STRING-FRAME

Initial state: `<k> setContent(textValue(PAYLOAD), C) </k>`.

The scalar rule applies because text is scalar content. `makeBytes(textValue(PAYLOAD), C)` rewrites to `encodedText(PAYLOAD, C)`, then `storeContent` writes one container item.

Corresponding source branches: unchanged string exclusion in the content setter and unchanged `if isinstance(value, str): return bytes(value.encode(self.charset))`.

### CONTENT-ITERABLE-FRAME

Initial state: `<k> setContent(iterableValue(CHUNKS), C) </k>`.

The iterable rule applies and writes `ListItem(joined(CHUNKS, C))` to the container.

Corresponding source branch: the content setter still consumes non-`bytes`, non-`str`, non-`memoryview` iterables with `b''.join(self.make_bytes(chunk) for chunk in value)`.

## Adequacy Gate

`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and `PUBLIC_COMPATIBILITY_AUDIT.md` are present.

`SPEC_AUDIT.md` marks all formal claims as passing the public-intent comparison. No formal claim preserves the issue's reported legacy behavior as expected behavior.

## Test Redundancy

No test deletion is recommended. The task forbids editing tests, and the constructed proof has not been machine-checked.

Recommended tests to add in a normal development setting, without editing tests in this benchmark task:

- `HttpResponse(memoryview(b"My Content")).content == b"My Content"`.
- Assigning `response.content = memoryview(b"My Content")` stores `b"My Content"`.
- `response.write(memoryview(b"My Content"))` appends `b"My Content"`.
- `StreamingHttpResponse([memoryview(b"My Content")])` yields `b"My Content"` as a chunk.

## Machine-Check Commands Not Run

These are the exact commands to run in an environment with K installed. They were not executed in this session.

```sh
cd fvk
kompile mini-python-response.k --backend haskell
kast --backend haskell http-response-spec.k
kprove http-response-spec.k
```

Expected machine-check success token after the proof is made executable in the K toolchain: `#Top`.

## Residual Risk

The proof is partial correctness over an abstract mini semantics, not a full Python semantics. It is constructed, not machine-checked. The main residual risk is adequacy of the abstraction, mitigated by anchoring the memoryview conversion directly in public issue text and Django's existing `force_bytes()` behavior.
