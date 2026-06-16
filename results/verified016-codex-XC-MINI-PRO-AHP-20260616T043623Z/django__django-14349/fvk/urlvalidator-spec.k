requires "mini-urlvalidator.k"

module MINI-URLVALIDATOR-SPEC
  imports MINI-URLVALIDATOR
  imports BOOL

  // SPEC-PROVENANCE:
  // - E-001 docs: URLValidator raises invalid for values that do not look like URLs.
  claim <k> validate(V:Val) => VE </k>
    requires notBool isStr(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003 issue: patched urlsplit strips all LF, CR, and tab characters.
  // - E-004 issue: newline URLValidator examples must raise ValidationError.
  // - E-005 public tests: trailing newlines not accepted.
  claim <k> validate(V:Val) => VE </k>
    requires isStr(V) andBool hasUnsafe(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001 docs: invalid-looking URL values raise invalid.
  // - E-006 docs/API: schemes remain the URLValidator scheme allowlist.
  claim <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool notBool schemeAllowed(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002 docs: valid literal IPv6 and Unicode-domain paths remain supported.
  // - from_code: the direct regex success path is unchanged when hasUnsafe is false.
  claim <k> validate(V:Val) => OK </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool directRegexOK(V)
     andBool notBool ipv6Bad(V)
     andBool notBool hostTooLong(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002 docs: Unicode domains are supported.
  // - from_code: IDN fallback still applies when hasUnsafe is false.
  claim <k> validate(V:Val) => OK </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool notBool directRegexOK(V)
     andBool splitOK(V)
     andBool punycodeOK(V)
     andBool fallbackRegexOK(V)
     andBool notBool hostTooLong(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001 docs: values that still do not look like valid URLs raise invalid.
  claim <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool notBool directRegexOK(V)
     andBool (notBool splitOK(V)
              orBool notBool punycodeOK(V)
              orBool notBool fallbackRegexOK(V))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001 docs: values that fail final IPv6 or host-length checks raise invalid.
  // - E-002 docs: IPv6 remains validated when no unsafe character is present.
  claim <k> validate(V:Val) => VE </k>
    requires isStr(V)
     andBool notBool hasUnsafe(V)
     andBool schemeAllowed(V)
     andBool (directRegexOK(V)
              orBool (splitOK(V) andBool punycodeOK(V) andBool fallbackRegexOK(V)))
     andBool (ipv6Bad(V) orBool hostTooLong(V))
    [all-path]
endmodule
