requires "mini-queryset-ordered.k"

module QUERYSET-ORDERED-SPEC
  imports QUERYSET-ORDERED

  // SPEC-PROVENANCE:
  // - from_prompt: "A property should say whether the queryset will be ordered
  //   or not." => QuerySet.ordered must agree with semantic SQL ordering.
  // - from_prompt: "Meta.ordering doesn't affect GROUP BY queries..." =>
  //   default Meta.ordering is suppressed for grouped queries.
  // - from_code: SQLCompiler preserves explicit order_by/extra_order_by and
  //   drops only compiler-selected Meta.ordering when grouping is emitted.
  claim <k> ordered(QS:QueryState) => compilerOrdered(QS) </k>
    [all-path]

  // The reported issue point: default Meta.ordering plus GROUP BY, without an
  // explicit order_by source, is not semantically ordered.
  claim <k> ordered(qs(false, false, false, true, true, true)) => false </k>
    [all-path]

  // Explicit ordering remains ordered even on a grouped query.
  claim <k> ordered(qs(false, false, true, true, true, true)) => true </k>
    [all-path]

  // Non-grouped default Meta.ordering remains ordered.
  claim <k> ordered(qs(false, false, false, true, true, false)) => true </k>
    [all-path]

  // No empty queryset, no explicit ordering, and no effective default ordering
  // is unordered.
  claim <k> ordered(qs(false, false, false, true, false, false)) => false </k>
    [all-path]
endmodule
