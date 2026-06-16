module MINI-DJANGO-I18N-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax LangResult ::= none | lang(String)
  syntax MatchResult ::= noMatch | match(String, String)
  syntax Exp ::= getLanguageFromPath(String, Map)
               | legacyLanguageFromPath(String, Map)
               | localePrefixMatch(String, String)

  syntax KResult ::= LangResult | MatchResult
endmodule

module MINI-DJANGO-I18N
  imports MINI-DJANGO-I18N-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= hasLeadingSlash(String) [function]
  syntax String ::= firstPathSegment(String) [function]
  syntax Bool ::= validLanguageCode(String) [function]
  syntax Bool ::= configuredCaseMatch(String, Map) [function]
  syntax String ::= configuredCaseValue(String, Map) [function]
  syntax Bool ::= legacyPrefixRegexMatches(String) [function]
  syntax String ::= legacyPrefixValue(String) [function]
  syntax LangResult ::= supportedVariant(String, Map) [function]
  syntax Bool ::= ciStartsWith(String, String) [function]
  syntax String ::= dropPrefixLength(String, String) [function]

  // V1 get_language_from_path(): exact configured first-segment branch.
  rule <k> getLanguageFromPath(PATH, LANGS)
        => lang(configuredCaseValue(firstPathSegment(PATH), LANGS)) </k>
    requires hasLeadingSlash(PATH)
     andBool validLanguageCode(firstPathSegment(PATH))
     andBool configuredCaseMatch(firstPathSegment(PATH), LANGS)

  // V1 get_language_from_path(): otherwise use the legacy regex/fallback path.
  rule <k> getLanguageFromPath(PATH, LANGS)
        => legacyLanguageFromPath(PATH, LANGS) </k>
    requires notBool (
      hasLeadingSlash(PATH)
      andBool validLanguageCode(firstPathSegment(PATH))
      andBool configuredCaseMatch(firstPathSegment(PATH), LANGS)
    )

  rule <k> legacyLanguageFromPath(PATH, LANGS)
        => supportedVariant(legacyPrefixValue(PATH), LANGS) </k>
    requires legacyPrefixRegexMatches(PATH)

  rule <k> legacyLanguageFromPath(PATH, LANGS) => none </k>
    requires notBool legacyPrefixRegexMatches(PATH)

  // V1 LocalePrefixPattern.match(): compare the prefix case-insensitively but
  // strip exactly the original prefix length.
  rule <k> localePrefixMatch(PATH, PREFIX)
        => match(PREFIX, dropPrefixLength(PATH, PREFIX)) </k>
    requires ciStartsWith(PATH, PREFIX)

  rule <k> localePrefixMatch(PATH, PREFIX) => noMatch </k>
    requires notBool ciStartsWith(PATH, PREFIX)
endmodule
