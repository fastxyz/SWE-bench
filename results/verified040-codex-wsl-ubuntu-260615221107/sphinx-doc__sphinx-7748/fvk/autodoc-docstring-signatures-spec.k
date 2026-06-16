requires "mini-autodoc.k"

module AUTODOC-DOCSTRING-SIGNATURES-SPEC
  imports MINI-AUTODOC

  // CLAIM: FIND-TWO
  // SPEC-PROVENANCE:
  // - E1/E2/E3: overloaded methods place all signatures at docstring start.
  // - Obligation: collect both leading signatures, preserve order, strip both.
  claim
    <k> findTask(
          names("getFeatures", noNames()),
          docs(lines(sig("getFeatures", "request", noneRet),
               lines(sig("getFeatures", "rect", ret("Iterator")),
               lines(text("Body text"), noLines()))),
               noDocs()))
        => found(pairs(pair("request", noneRet),
                  pairs(pair("rect", ret("Iterator")), noPairs())),
                 docs(lines(text("Body text"), noLines()), noDocs()))
    </k>
    [all-path]

  // CLAIM: FIND-THREE-PREFIX
  // SPEC-PROVENANCE:
  // - E4: getFeatures may have four overloads; the family is N signatures.
  // - Obligation: the collector is not hard-coded to one or two.
  claim
    <k> findTask(
          names("f", noNames()),
          docs(lines(sig("f", "a", noneRet),
               lines(sig("f", "b", noneRet),
               lines(sig("f", "c", ret("R")),
               lines(text("Body"), noLines())))),
               noDocs()))
        => found(pairs(pair("a", noneRet),
                  pairs(pair("b", noneRet),
                  pairs(pair("c", ret("R")), noPairs()))),
                 docs(lines(text("Body"), noLines()), noDocs()))
    </k>
    [all-path]

  // CLAIM: FIND-STOPS-AT-PROSE
  // SPEC-PROVENANCE:
  // - E1/E5: the recognized block is at the start of the docstring.
  // - Obligation: stop at prose and leave later signature-looking text.
  claim
    <k> findTask(
          names("f", noNames()),
          docs(lines(sig("f", "a", noneRet),
               lines(text("Example:"),
               lines(sig("f", "example", noneRet), noLines()))),
               noDocs()))
        => found(pairs(pair("a", noneRet), noPairs()),
                 docs(lines(text("Example:"),
                      lines(sig("f", "example", noneRet), noLines())),
                      noDocs()))
    </k>
    [all-path]

  // CLAIM: FIND-NO-MATCH
  // SPEC-PROVENANCE:
  // - E6: base name must match the documented object's valid names.
  // - Obligation: a nonmatching first signature is not extracted.
  claim
    <k> findTask(
          names("f", noNames()),
          docs(lines(sig("g", "a", noneRet),
               lines(text("Body"), noLines())),
               noDocs()))
        => noMatch(docs(lines(sig("g", "a", noneRet),
                         lines(text("Body"), noLines())),
                         noDocs()))
    </k>
    [all-path]

  // CLAIM: FIND-SINGLE-COMPAT
  // SPEC-PROVENANCE:
  // - E5: existing single-signature behavior remains valid.
  // - Obligation: compatibility wrapper returns the one signature pair.
  claim
    <k> firstTask(
          names("f", noNames()),
          docs(lines(sig("f", "a", ret("int")),
               lines(text("Body"), noLines())),
               noDocs()))
        => somePair(pair("a", ret("int")))
    </k>
    [all-path]

  // CLAIM: FORMAT-SINGLE
  // SPEC-PROVENANCE:
  // - E5: formatting a single extracted signature keeps prior shape.
  claim
    <k> formatTask(pairs(pair("a", ret("int")), noPairs()))
        => "(a) -> int"
    </k>
    [all-path]

  // CLAIM: FORMAT-TWO
  // SPEC-PROVENANCE:
  // - E7: add_directive_header consumes newline-separated signatures.
  // - Obligation: multiple pairs format as ordered newline-separated strings.
  claim
    <k> formatTask(pairs(pair("request", noneRet),
                    pairs(pair("rect", ret("Iterator")), noPairs())))
        => "(request)\n(rect) -> Iterator"
    </k>
    [all-path]

  // CLAIM: STRIP-WRAPPER-NO-REEMIT
  // SPEC-PROVENANCE:
  // - E8: strip-only compatibility. After stripping, the delegated plural
  //   lookup over the remainder finds no signature to emit.
  claim
    <k> findTask(
          names("f", noNames()),
          docs(lines(text("Body"), noLines()), noDocs()))
        => noMatch(docs(lines(text("Body"), noLines()), noDocs()))
    </k>
    [all-path]

  // CLAIM: FORMAT-EXPLICIT-BYPASS
  // SPEC-PROVENANCE:
  // - E8: explicit directive signatures bypass docstring extraction.
  claim
    <k> explicitTask("(explicit)") => "(explicit)" </k>
    [all-path]
endmodule
