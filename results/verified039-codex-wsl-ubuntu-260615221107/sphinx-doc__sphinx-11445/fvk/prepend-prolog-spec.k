// Constructed FVK artifact; not machine-checked in this session.

requires "mini-rst-prolog.k"

module PREPEND-PROLOG-SPEC
  imports MINI-RST-PROLOG

  // SPEC-PROVENANCE:
  // - E1/E2/E3: role-title headings must not be split by rst_prolog.
  // - E6: the following line is a valid section underline.
  claim
    <k> prepend(P:Prolog,
                consLine(line(T:String, FieldTitle),
                  consLine(line(U:String, Underline), REST:Lines)))
     =>
        append(prologLines(P),
          consLine(blank(),
            consLine(line(T, FieldTitle),
              consLine(line(U, Underline), REST))))
    </k>
    requires nonEmptyProlog(P)
     andBool validUnderline(T, U)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: genuine leading docinfo remains before rst_prolog.
  // - PREFIX is a scanned docinfo prefix; TAIL is the first unscanned suffix.
  syntax Bool ::= scannedPrefix(Lines, Lines) [function]

  claim
    <k> prepend(P:Prolog, append(PREFIX:Lines, TAIL:Lines))
     =>
        append(PREFIX,
          consLine(blank(),
            append(prologLines(P), consLine(blank(), TAIL))))
    </k>
    requires nonEmptyProlog(P)
     andBool scannedPrefix(PREFIX, TAIL)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E7: ordinary content without leading docinfo receives the prolog at
  //   the beginning.
  claim
    <k> prepend(P:Prolog, consLine(line(S:String, Other), REST:Lines))
     =>
        append(prologLines(P),
          consLine(blank(), consLine(line(S, Other), REST)))
    </k>
    requires nonEmptyProlog(P)
    [all-path]

  // SPEC-PROVENANCE:
  // - Intent 6: falsey/empty prolog is a no-op.
  claim
    <k> prepend(.Prolog, LS:Lines) => LS </k>
    [all-path]
endmodule

