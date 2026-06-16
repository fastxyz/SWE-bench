requires "mini-python.k"

module Q-COMBINE-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - E7: plain non-conditional objects remain invalid.
  // - PO-2: non-conditional operands raise TypeError.
  claim <k> combine(lookupQ, nonCond, AND) => typeError(nonCond) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: the issue's minimal reproduction is Q() & Exists(...).
  // - PO-3, PO-4, PO-5: conditional non-Q operands are wrapped and cloned.
  claim <k> combine(emptyQ, condExpr, AND) => ok(exprQ) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2 and E4: non-empty Q(...) & Exists(...) must be accepted.
  // - PO-6: both operands are represented in the result under AND.
  claim <k> combine(lookupQ, condExpr, AND) => ok(andLookupExprQ) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2 and E4: non-empty Q(...) | Exists(...) must be accepted.
  // - PO-6: both operands are represented in the result under OR.
  claim <k> combine(lookupQ, condExpr, OR) => ok(orLookupExprQ) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - F2 and PO-7: Q(Exists(...)) must deconstruct through positional args.
  claim <k> deconstructQ(exprQ) => argsExpr </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - PO-7 and PO-9: ordinary single lookup Q objects keep kwargs
  //   deconstruction.
  claim <k> deconstructQ(lookupQ) => kwargsLookup </k>
    [all-path]
endmodule

