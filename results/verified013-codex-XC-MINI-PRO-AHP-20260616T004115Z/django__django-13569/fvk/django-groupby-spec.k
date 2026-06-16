requires "mini-django-groupby.k"

module DJANGO-GROUPBY-SPEC-SYNTAX
  imports MINI-DJANGO-GROUPBY-SYNTAX
  syntax Id ::= "randomCol" [token]
              | "relatedCol" [token]
              | "rawCol" [token]
              | "externalSubqueryCol" [token]
endmodule

module DJANGO-GROUPBY-SPEC
  imports MINI-DJANGO-GROUPBY
  imports DJANGO-GROUPBY-SPEC-SYNTAX

  // SPEC-PROVENANCE:
  // - E1/E2/E4: order_by('?') is random and must not alter aggregate grouping.
  claim
    <k> orderGroupCols(
          order(false, gcol(randomCol, false, .Sources) ; .GroupCols)
          ; .OrderEntries
        ) => .GroupCols </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: ordering by related columns is expected to remain grouping-relevant.
  claim
    <k> orderGroupCols(
          order(false, gcol(relatedCol, true, ordinary ; .Sources) ; .GroupCols)
          ; .OrderEntries
        ) => gcol(relatedCol, true, ordinary ; .Sources) ; .GroupCols </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: raw SQL must be included because Django cannot introspect it.
  claim
    <k> orderGroupCols(
          order(false, gcol(rawCol, false, rawSQL ; .Sources) ; .GroupCols)
          ; .OrderEntries
        ) => gcol(rawCol, false, rawSQL ; .Sources) ; .GroupCols </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E7: subqueries with external columns remain grouping-relevant.
  claim
    <k> orderGroupCols(
          order(false, gcol(externalSubqueryCol, false, externalCols ; .Sources) ; .GroupCols)
          ; .OrderEntries
        ) => gcol(externalSubqueryCol, false, externalCols ; .Sources) ; .GroupCols </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: references to selected expressions are already grouped elsewhere.
  claim
    <k> orderGroupCols(
          order(true, gcol(relatedCol, true, ordinary ; .Sources) ; .GroupCols)
          ; .OrderEntries
        ) => .GroupCols </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2-E7: finite order entries are processed in order, retaining only
  //   grouping-relevant non-reference columns.
  claim
    <k> orderGroupCols(order(true, CS:GroupCols) ; OS:OrderEntries)
      => orderGroupCols(OS) </k>
    [all-path]

  claim
    <k> orderGroupCols(order(false, C:GroupCol ; CS:GroupCols) ; OS:OrderEntries)
      => C ; appendKept(CS, orderGroupCols(OS)) </k>
    requires keep(C)
    [all-path]

  claim
    <k> orderGroupCols(order(false, C:GroupCol ; CS:GroupCols) ; OS:OrderEntries)
      => appendKept(CS, orderGroupCols(OS)) </k>
    requires notBool keep(C)
    [all-path]
endmodule
