requires "mini-regex-csv.k"

module REGEX-CSV-SPEC
  imports MINI-REGEX-CSV

  // SPEC-PROVENANCE:
  // - E4/E6: top-level comma-separated regex lists remain supported.
  claim <k> split(OTHER("f") OTHER("o") OTHER("o") COMMA OTHER("b") OTHER("a") OTHER("r") .Chrs)
        => done(pat(OTHER("f") OTHER("o") OTHER("o") .Chrs) ;; pat(OTHER("b") OTHER("a") OTHER("r") .Chrs) ;; .Pats) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5: `(foo{1,3})` must be one regex fragment.
  claim <k> split(OTHER("(") OTHER("f") OTHER("o") OTHER("o") LBRACE OTHER("1") COMMA OTHER("3") RBRACE OTHER(")") .Chrs)
        => done(pat(OTHER("(") OTHER("f") OTHER("o") OTHER("o") LBRACE OTHER("1") COMMA OTHER("3") RBRACE OTHER(")") .Chrs) ;; .Pats) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: escaped comma is the explicit workaround for literal commas.
  claim <k> split(OTHER("f") OTHER("o") OTHER("o") BSLASH COMMA OTHER("b") OTHER("a") OTHER("r") .Chrs)
        => done(pat(OTHER("f") OTHER("o") OTHER("o") BSLASH COMMA OTHER("b") OTHER("a") OTHER("r") .Chrs) ;; .Pats) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: a valid regex character-class comma is regex syntax, not a separator.
  claim <k> split(LBRACK OTHER("a") COMMA OTHER("b") RBRACK .Chrs)
        => done(pat(LBRACK OTHER("a") COMMA OTHER("b") RBRACK .Chrs) ;; .Pats) </k>
    [all-path]
endmodule
