// Constructed mini-semantics for the admindocs regex-group helpers.
// This is not machine-checked in this session.

requires "domains.md"

module MINI-REGEX-GROUPS-SYNTAX
  imports STRING
  imports INT
  imports BOOL
  imports LIST

  syntax Program ::= replaceNamedGroups(String)
                   | replaceUnnamedGroups(String)
                   | simplifyRegex(String)
                   | scanNamed(String, Int, Int, Int, Int)
                   | scanUnnamed(String, Int, Int, Int)
                   | filterOutermost(List)
                   | reconstructUnnamed(String, List)

  syntax String ::= namedReplaceAll(String)        [function]
                  | unnamedReplaceAll(String)      [function]
                  | cleanupRegexChars(String)      [function]
                  | ensureLeadingSlash(String)     [function]
                  | simplifyExpected(String)       [function]
                  | replaceSpan(String, Int, Int, String) [function]
                  | reconstructExpected(String, List) [function]

  syntax List ::= namedSpans(String)               [function]
                | unnamedSpans(String)             [function]
                | outermostSpans(List)             [function]

  syntax Bool ::= validPattern(String)             [function]
                | closesNamedAt(String, Int, Int, Int) [function]
                | closesUnnamedAt(String, Int, Int) [function]
                | sortedNonOverlapping(List)       [function]
                | samePublicApi                    [function]
endmodule

module MINI-REGEX-GROUPS
  imports MINI-REGEX-GROUPS-SYNTAX

  configuration <k> $PGM:Program </k>

  rule <k> replaceNamedGroups(P) => namedReplaceAll(P) </k>
    requires validPattern(P)

  rule <k> replaceUnnamedGroups(P) => unnamedReplaceAll(P) </k>
    requires validPattern(P)

  rule <k> simplifyRegex(P) => ensureLeadingSlash(cleanupRegexChars(unnamedReplaceAll(namedReplaceAll(P)))) </k>
    requires validPattern(P)

  // Abstract scanner endpoints used by the proof obligations.
  rule <k> scanNamed(P, START, END, IDX, 1) => replaceSpan(P, START, END +Int IDX +Int 1, "<name>") </k>
    requires closesNamedAt(P, END, IDX)

  rule <k> scanUnnamed(P, START, IDX, 1) => replaceSpan(P, START, START +Int 1 +Int IDX +Int 1, "<var>") </k>
    requires closesUnnamedAt(P, START, IDX)

  rule <k> filterOutermost(SPANS) => outermostSpans(SPANS) </k>

  rule <k> reconstructUnnamed(P, SPANS) => reconstructExpected(P, SPANS) </k>
    requires sortedNonOverlapping(SPANS)
endmodule
