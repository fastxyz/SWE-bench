# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or Django code were executed.

## Claims Proved on Paper

The proof covers the five K claims in `session-encode-spec.k`:

1. SHA1 transition mode encodes to the legacy payload shape.
2. SHA1 transition-mode output is accepted by a legacy decoder.
3. Current Django decode accepts legacy payloads.
4. SHA256 default mode encodes to the signed payload shape.
5. Current Django decode accepts signed payloads.

There are no loops or recursive functions in the modeled unit, so no circularity claim is required.

## Symbolic Execution Sketch

### Claim 1: SHA1 Encodes Legacy

Initial state:

```k
<k> encode(C, D, SHA1) </k>
```

Rule 1 rewrites `encode(C, D, SHA1)` to `legacyEncode(C, D)`.

Rule 3 rewrites `legacyEncode(C, D)` to:

```k
legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))
```

By transitivity, the claim reaches the expected legacy payload.

### Claim 2: SHA1 Legacy Round Trip

Initial state:

```k
<k> legacyDecode(C, encode(C, D, SHA1)) </k>
```

The `strict(2)` annotation evaluates the second argument first. Claim 1's rewrite sequence reduces it to:

```k
legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))
```

The legacy decoder rule then rewrites the whole expression to `D`. This proves a SHA1 transition-mode write is decodable by the legacy decoder.

### Claim 3: Current Decode Accepts Legacy

Initial state:

```k
<k> decode(C, legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))) </k>
```

The current decode legacy rule matches the payload shape and rewrites directly to `D`.

### Claim 4: SHA256 Default Preserved

Initial state:

```k
<k> encode(C, D, SHA256) </k>
```

The SHA256 encode rule rewrites directly to `signedEncoded(C, D)`, preserving the default signing-based format.

### Claim 5: Current Decode Accepts Signed

Initial state:

```k
<k> decode(C, signedEncoded(C, D)) </k>
```

The current decode signed rule rewrites directly to `D`.

## Adequacy

The K model preserves the audited observable: whether `SessionBase.encode()` returns the legacy payload shape or the signing-based payload shape, and whether the relevant decoder can recover the original session dictionary. A passing instance and failing instance are distinguished:

- Passing transition instance: `legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))`.
- Failing pre-fix transition instance: `signedEncoded(C, D)`, which has no legacy decoder rule.

Therefore the abstraction is property-complete for the reported defect.

## Exact Machine-Check Commands

These commands are emitted for later machine checking only. They were not run in this session.

```sh
cd fvk
kompile mini-session-format.k --backend haskell
kast --backend haskell session-encode-spec.k
kprove session-encode-spec.k
```

Expected result after successful machine checking: `#Top` for all claims.

## Test Recommendation

No test files were modified. If public tests were available for this issue, in-domain tests that merely assert `encode()` in SHA1 mode emits the legacy format would be candidates for redundancy only after the K claims are machine-checked. Integration tests covering DB/file persistence, signed cookies, invalid payload handling, and transition deployment wiring should be kept.

## Residual Risk

This is a partial, constructed proof over a mini semantics. It does not prove byte-level HMAC/base64 implementations, serializer implementation correctness, or total application-level upgrade behavior. Those remain trusted Django/library behavior and integration concerns.

