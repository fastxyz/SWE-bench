// Constructed claims for django/contrib/admindocs regex group simplification.
// These claims were not run with kprove in this session.

requires "mini-regex-groups.k"

module ADMINDOCS-REGEX-SPEC
  imports MINI-REGEX-GROUPS

  // SPEC-PROVENANCE:
  // - E1/E2: the issue requires a final named group to be replaced without a
  //   trailing slash.
  // - from_code: V2 checks the balance after consuming the current character.
  claim <k> scanNamed(P, START, END, IDX, 1)
        => replaceSpan(P, START, END +Int IDX +Int 1, "<name>") </k>
    requires validPattern(P)
     andBool closesNamedAt(P, END, IDX)
    [label(REPLACE-NAMED-TRAILING)]

  // SPEC-PROVENANCE:
  // - E3: the public hint requires the analogous unnamed-group trailing fix.
  // - from_code: V2 records START + 1 + IDX + 1 when the balance reaches zero.
  claim <k> scanUnnamed(P, START, IDX, 1)
        => replaceSpan(P, START, START +Int 1 +Int IDX +Int 1, "<var>") </k>
    requires validPattern(P)
     andBool closesUnnamedAt(P, START, IDX)
    [label(REPLACE-UNNAMED-TRAILING)]

  // SPEC-PROVENANCE:
  // - E4: all outermost unnamed groups are replaced; nested groups are consumed
  //   by the outer span and adjacent groups are independent top-level spans.
  claim <k> filterOutermost(unnamedSpans(P))
        => outermostSpans(unnamedSpans(P)) </k>
    requires validPattern(P)
    [label(UNNAMED-OUTERMOST)]

  // SPEC-PROVENANCE:
  // - E4: text outside selected unnamed spans must be preserved exactly once.
  // - F3: V1 duplicated prefixes for multiple selected spans.
  claim <k> reconstructUnnamed(P, SPANS)
        => reconstructExpected(P, SPANS) </k>
    requires validPattern(P)
     andBool sortedNonOverlapping(SPANS)
    [label(UNNAMED-RECONSTRUCT)]

  // SPEC-PROVENANCE:
  // - E2: issue example must simplify all named groups.
  // - E6: simplifyRegex composes named replacement, unnamed replacement,
  //   cleanup, and leading-slash insertion.
  claim <k> simplifyRegex("entries/(?P<pk>[^/.]+)/relationships/(?P<related_field>\\w+)")
        => "/entries/<pk>/relationships/<related_field>" </k>
    [label(SIMPLIFY-ISSUE-CASE)]

  // SPEC-PROVENANCE:
  // - E6: no changed public signature, return type, or call order.
  claim <k> samePublicApi => true </k>
    [label(COMPATIBILITY)]
endmodule
