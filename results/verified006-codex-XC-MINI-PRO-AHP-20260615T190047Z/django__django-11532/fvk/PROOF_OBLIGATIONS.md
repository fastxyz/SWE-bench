# Proof Obligations

Status: constructed, not machine-checked.

## PO1: ASCII Preservation

For every ASCII DNS-domain value `D`, `punycode(D) == D`.

Evidence: E3, E8. Formal claim: `PUNYCODE-ASCII`.

## PO2: Non-ASCII IDNA Conversion

For every in-domain non-ASCII DNS-domain value `D`, `punycode(D)` returns the IDNA/punycode ASCII form of `D`. For the representative issue value `"漢字"`, the result is `"xn--p8s937b"`.

Evidence: E3, E4. Formal claim: `PUNYCODE-NONASCII`.

## PO3: Cache Miss Normalization

On the first `CachedDnsName.get_fqdn()` call, the value returned from `socket.getfqdn()` is normalized before it is stored or returned.

Evidence: E2, E3, E6. Formal claim: `CACHED-DNS-MISS`.

## PO4: Cache Hit Reuse

After the cache contains a normalized DNS name, later `get_fqdn()` calls return that value without requiring another hostname lookup.

Evidence: E6. Formal claim: `CACHED-DNS-HIT`.

## PO5: Default Message-ID Domain Safety

If `EmailMessage.message()` generates a default `Message-ID`, the domain passed to `make_msgid()` is normalized with `punycode()`. Therefore, a Unicode hostname cannot force the generated `Message-ID` through `Header(val, iso-8859-1).encode()` as raw Unicode.

Evidence: E1, E4, E5. Formal claim: `MESSAGE-ID-DEFAULT`.

## PO6: Explicit Message-ID Override Preservation

If `extra_headers` already contains a `Message-ID` key, Django skips default message-id generation and preserves the override behavior.

Evidence: E7. Formal claim: `MESSAGE-ID-OVERRIDE`.

## PO7: Public Compatibility Frame

The fix must not change public method signatures or unrelated header/body construction behavior.

Evidence: E6, E7, public callsite search. Formalized in `PUBLIC_COMPATIBILITY_AUDIT.md`; not a separate K claim because it is a cross-file compatibility frame.
