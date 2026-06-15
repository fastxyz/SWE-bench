// Mini mail-DNS semantics for django__django-11532.
// Constructed for FVK audit; not machine-checked in this session.

module MINI-MAIL-DNS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Domain ::= asciiDomain(String)
                  | unicodeHanDomain
                  | aceHanDomain

  syntax Cache ::= noCache | cached(Domain)
  syntax MessageId ::= noMessageId | generated(Domain) | explicitMessageId

  syntax Cmd ::= punycodeDomain(Domain)
               | getFqdn(Cache, Domain)
               | defaultMessageId(Bool, Domain)

  syntax KResult ::= Domain | MessageId
endmodule

module MINI-MAIL-DNS
  imports MINI-MAIL-DNS-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <cache> noCache </cache>
    <messageId> noMessageId </messageId>

  syntax Domain ::= normalize(Domain) [function]
  rule normalize(asciiDomain(S:String)) => asciiDomain(S)
  rule normalize(unicodeHanDomain) => aceHanDomain
  rule normalize(aceHanDomain) => aceHanDomain

  rule <k> punycodeDomain(D:Domain) => normalize(D) ... </k>

  rule <k> getFqdn(noCache, D:Domain) => normalize(D) ... </k>
       <cache> noCache => cached(normalize(D)) </cache>

  rule <k> getFqdn(cached(D:Domain), _:Domain) => D ... </k>
       <cache> cached(D) </cache>

  rule <k> defaultMessageId(false, D:Domain) => generated(normalize(D)) ... </k>
       <messageId> noMessageId => generated(normalize(D)) </messageId>

  rule <k> defaultMessageId(true, _:Domain) => explicitMessageId ... </k>
       <messageId> explicitMessageId </messageId>
endmodule
