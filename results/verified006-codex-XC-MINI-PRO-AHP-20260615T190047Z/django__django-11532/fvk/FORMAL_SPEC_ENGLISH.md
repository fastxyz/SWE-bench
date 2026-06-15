# Formal Spec In English

This file paraphrases the claims in `mail-dns-spec.k`.

## `PUNYCODE-ASCII`

For every ASCII DNS-domain value, evaluating the domain normalizer returns exactly the original ASCII value.

## `PUNYCODE-NONASCII`

For the issue's representative Unicode DNS-domain value `"漢字"`, evaluating the domain normalizer returns its IDNA/punycode ASCII form `"xn--p8s937b"`.

## `CACHED-DNS-MISS`

If `CachedDnsName` has no cached hostname and the system FQDN is the issue's representative Unicode domain, `get_fqdn()` returns the IDNA/punycode value and stores that normalized value in the cache.

## `CACHED-DNS-HIT`

If `CachedDnsName` already holds a normalized cached hostname, `get_fqdn()` returns that cached value and leaves it unchanged.

## `MESSAGE-ID-DEFAULT`

If no explicit `Message-ID` header is present and `DNS_NAME` is the issue's representative Unicode domain, the default message-id generation uses the IDNA/punycode value as the domain of the generated id.

## `MESSAGE-ID-OVERRIDE`

If an explicit `Message-ID` header is present, default message-id generation is skipped and the explicit header remains the controlling value.
