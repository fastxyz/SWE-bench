# Constructed Proof

Status: constructed, not machine-checked. No Python, tests, `kompile`, `kast`, or `kprove` commands were executed.

## Claims Proved On Paper

The proof covers the six claims in `mail-dns-spec.k`:

- `PUNYCODE-ASCII`
- `PUNYCODE-NONASCII`
- `CACHED-DNS-MISS`
- `CACHED-DNS-HIT`
- `MESSAGE-ID-DEFAULT`
- `MESSAGE-ID-OVERRIDE`

There are no loops or recursive calls in the changed code, so no circularity claim is required.

## Symbolic Execution Sketch

### `PUNYCODE-ASCII`

Start with `<k> punycodeDomain(asciiDomain(S)) </k>`. The `punycodeDomain` rule rewrites to `normalize(asciiDomain(S))`. The `normalize(asciiDomain(S))` function rule rewrites to `asciiDomain(S)`. This is exactly PO1.

### `PUNYCODE-NONASCII`

Start with `<k> punycodeDomain(unicodeHanDomain) </k>`. The command rewrites to `normalize(unicodeHanDomain)`, and the representative IDNA rule rewrites it to `aceHanDomain`, denoting `"xn--p8s937b"`. This is PO2 for the issue's concrete value.

### `CACHED-DNS-MISS`

Start with `<cache> noCache </cache>` and `<k> getFqdn(noCache, unicodeHanDomain) </k>`. The cache-miss rule rewrites the result to `normalize(unicodeHanDomain)` and rewrites the cache to `cached(normalize(unicodeHanDomain))`. The non-ASCII normalization rule reduces both occurrences to `aceHanDomain`. This proves PO3.

### `CACHED-DNS-HIT`

Start with `<cache> cached(aceHanDomain) </cache>` and `<k> getFqdn(cached(aceHanDomain), asciiDomain("ignored")) </k>`. The cache-hit rule returns the cached value and leaves the cache unchanged. This proves PO4 under the cache invariant established by PO3.

### `MESSAGE-ID-DEFAULT`

Start with `<messageId> noMessageId </messageId>` and `<k> defaultMessageId(false, unicodeHanDomain) </k>`, where `false` means no explicit `Message-ID` header exists. The default-generation rule rewrites the result and message-id cell to `generated(normalize(unicodeHanDomain))`; normalization rewrites that domain to `aceHanDomain`. This proves PO5 and resolves F1.

### `MESSAGE-ID-OVERRIDE`

Start with `<messageId> explicitMessageId </messageId>` and `<k> defaultMessageId(true, unicodeHanDomain) </k>`, where `true` means an explicit `Message-ID` header exists. The override rule returns `explicitMessageId` and does not inspect or normalize the DNS domain. This proves PO6.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` marks each paraphrase as supported by public intent. The V1-only claim set would have failed adequacy because it omitted the direct `DNS_NAME` substitution path from E4; V2 includes that path.

## Residual Risk

The proof is partial correctness over the modeled domain. It does not prove behavior for invalid IDNA hostnames, does not machine-check the K files, and does not justify deleting tests.

## Test Guidance

Tests covering `EmailMessage.message()` with a valid non-ASCII DNS name and `iso-8859-1` encoding are subsumed by the constructed proof only after the K claims are machine-checked. Integration tests, explicit-header override tests, and invalid-hostname behavior tests should be kept.

## Commands To Machine-Check Later

These commands are recorded for a future environment with K installed. They were not run here.

```sh
cd fvk
kompile mini-mail-dns.k --backend haskell
kast --backend haskell mail-dns-spec.k
kprove mail-dns-spec.k
```

Expected successful `kprove` result after any syntax adjustments required by the local K version: `#Top`.
