requires "mini-mail-dns.k"

module MAIL-DNS-SPEC
  imports MINI-MAIL-DNS

  // SPEC-PROVENANCE:
  // - E3: "convert domain name to punycode before using" => ASCII domains are already safe.
  claim
    <k> punycodeDomain(asciiDomain(S:String)) => asciiDomain(S) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: the issue's executable snippet expects "xn--p8s937b" for "漢字".
  // - In this mini-semantics, unicodeHanDomain denotes "漢字" and aceHanDomain denotes "xn--p8s937b".
  claim
    <k> punycodeDomain(unicodeHanDomain) => aceHanDomain ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: the real system hostname path is in scope.
  // - E6: the hostname lookup remains lazy and then cached.
  claim
    <k> getFqdn(noCache, unicodeHanDomain) => aceHanDomain ... </k>
    <cache> noCache => cached(aceHanDomain) </cache>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: after caching, get_fqdn() reuses the cached value.
  claim
    <k> getFqdn(cached(aceHanDomain), asciiDomain("ignored")) => aceHanDomain ... </k>
    <cache> cached(aceHanDomain) </cache>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E5: default Message-ID generation must avoid a non-ASCII-domain header crash.
  // - E4: DNS_NAME may itself be the Unicode value at the message.py use site.
  claim
    <k> defaultMessageId(false, unicodeHanDomain) => generated(aceHanDomain) ... </k>
    <messageId> noMessageId => generated(aceHanDomain) </messageId>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: user-provided Message-ID headers override generated defaults.
  claim
    <k> defaultMessageId(true, unicodeHanDomain) => explicitMessageId ... </k>
    <messageId> explicitMessageId </messageId>
    [all-path]
endmodule
