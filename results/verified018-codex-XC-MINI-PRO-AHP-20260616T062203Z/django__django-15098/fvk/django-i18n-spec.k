requires "mini-django-i18n.k"

module DJANGO-I18N-SPEC
  imports MINI-DJANGO-I18N
  imports MAP
  imports STRING
  imports BOOL

  syntax Map ::= issueLangs() [function]
               | lowerOnlyLangs() [function]
               | germanOnlyLangs() [function]

  rule issueLangs()
    => "en-us" |-> "English"
       "en-latn-us" |-> "Latin English"
       "en-Latn-US" |-> "BCP 47 case format"
       .Map
    [simplification]

  rule lowerOnlyLangs() => "en-latn-us" |-> "Latin English" .Map [simplification]
  rule germanOnlyLangs() => "de" |-> "German" .Map [simplification]

  rule hasLeadingSlash("/en-latn-us/") => true [simplification]
  rule hasLeadingSlash("/en-Latn-US/") => true [simplification]
  rule hasLeadingSlash("/de-simple-page/") => true [simplification]

  rule firstPathSegment("/en-latn-us/") => "en-latn-us" [simplification]
  rule firstPathSegment("/en-Latn-US/") => "en-Latn-US" [simplification]
  rule firstPathSegment("/de-simple-page/") => "de-simple-page" [simplification]

  rule validLanguageCode("en-latn-us") => true [simplification]
  rule validLanguageCode("en-Latn-US") => true [simplification]
  rule validLanguageCode("de-simple-page") => true [simplification]

  rule configuredCaseMatch("en-latn-us", issueLangs()) => true [simplification]
  rule configuredCaseValue("en-latn-us", issueLangs()) => "en-latn-us" [simplification]
  rule configuredCaseMatch("en-Latn-US", issueLangs()) => true [simplification]
  rule configuredCaseValue("en-Latn-US", issueLangs()) => "en-Latn-US" [simplification]
  rule configuredCaseMatch("en-Latn-US", lowerOnlyLangs()) => true [simplification]
  rule configuredCaseValue("en-Latn-US", lowerOnlyLangs()) => "en-latn-us" [simplification]
  rule configuredCaseMatch("de-simple-page", germanOnlyLangs()) => false [simplification]

  rule legacyPrefixRegexMatches("/de-simple-page/") => false [simplification]
  rule ciStartsWith("en-Latn-US/", "en-latn-us/") => true [simplification]
  rule dropPrefixLength("en-Latn-US/", "en-latn-us/") => "" [simplification]
  rule ciStartsWith("anything/", "") => true [simplification]
  rule dropPrefixLength("anything/", "") => "anything/" [simplification]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: configured en-latn-us path should be accepted.
  claim <k> getLanguageFromPath("/en-latn-us/", issueLangs())
        => lang("en-latn-us") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3/E5: configured BCP 47 case path should be accepted.
  claim <k> getLanguageFromPath("/en-Latn-US/", issueLangs())
        => lang("en-Latn-US") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: language tags are case-insensitive, so configured lower-case
  //   language can be selected from BCP 47 case URL spelling.
  claim <k> getLanguageFromPath("/en-Latn-US/", lowerOnlyLangs())
        => lang("en-latn-us") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: arbitrary three-part URL slugs must not become language prefixes by
  //   broad regex fallback.
  claim <k> getLanguageFromPath("/de-simple-page/", germanOnlyLangs())
        => none </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5 plus Django active-language normalization: resolver prefix match
  //   must tolerate case differences and strip the same prefix width.
  claim <k> localePrefixMatch("en-Latn-US/", "en-latn-us/")
        => match("en-latn-us/", "") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Compatibility C2: empty-prefix behavior remains equivalent to
  //   path.startswith("").
  claim <k> localePrefixMatch("anything/", "")
        => match("", "anything/") </k>
    [all-path]
endmodule
