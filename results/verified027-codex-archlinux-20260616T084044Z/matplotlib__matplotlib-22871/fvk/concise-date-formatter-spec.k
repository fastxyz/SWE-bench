requires "mini-python-date.k"

module CONCISE-DATE-FORMATTER-SPEC
  imports MINI-PYTHON-DATE

  // SPEC-PROVENANCE:
  // - from_prompt: "I expect the year \"2021\" to show in the offset" =>
  //   month-level no-January ticks must render the year offset.
  // - from_docs: offset plus labels should completely specify the date.
  claim <k> offsetFor(1, true, false, Y:Int) => year(Y) </k>
    requires Y >=Int 1
    [all-path, label(C001)]

  // SPEC-PROVENANCE:
  // - from_docs: January month ticks are labeled with the year by zero-format.
  // - from_public_tests: January-origin month-level offset remains empty.
  claim <k> offsetFor(1, true, true, Y:Int) => noOffset </k>
    requires Y >=Int 1
    [all-path, label(C002)]

  // SPEC-PROVENANCE:
  // - from_docs: year-level tick labels are years.
  claim <k> offsetFor(0, true, H:Bool, Y:Int) => noOffset </k>
    requires Y >=Int 1
    [all-path, label(C003)]

  // SPEC-PROVENANCE:
  // - from_public_tests: finer-level offset behavior is preserved.
  claim <k> offsetFor(L:Int, true, H:Bool, Y:Int) => formatted(L, Y) </k>
    requires 2 <=Int L andBool L <=Int 5 andBool Y >=Int 1
    [all-path, label(C004)]

  // SPEC-PROVENANCE:
  // - from_api: show_offset=False means no offset is shown.
  claim <k> offsetFor(L:Int, false, H:Bool, Y:Int) => noOffset </k>
    requires 0 <=Int L andBool L <=Int 5 andBool Y >=Int 1
    [all-path, label(C005)]
endmodule
