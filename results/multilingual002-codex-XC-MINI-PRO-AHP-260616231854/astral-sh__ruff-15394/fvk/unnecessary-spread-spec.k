requires "mini-pie800-fixer.k"

module UNNECESSARY-SPREAD-SPEC
  imports MINI-PIE800-FIXER

  // CLAIM: NON-EMPTY-BALANCED
  // SPEC-PROVENANCE:
  // - I1/I2: parenthesized non-empty spread fixes must not leave unmatched ")".
  // - I3/I4: non-empty inner dict entries remain after removing the spread wrapper.
  claim <k> fix(nonEmpty(P:Int)) => valid </k>
    requires P >=Int 0
    [all-path]

  // CLAIM: EMPTY-ONLY
  // SPEC-PROVENANCE:
  // - I3/I5/I6: empty spread as only item contributes no entries and must leave no stray comma.
  claim <k> fix(empty(only, P:Int)) => valid </k>
    requires P >=Int 0
    [all-path]

  // CLAIM: EMPTY-FIRST
  // SPEC-PROVENANCE:
  // - I3/I5/I6: empty spread before another item must remove the following separator.
  claim <k> fix(empty(first, P:Int)) => valid </k>
    requires P >=Int 0
    [all-path]

  // CLAIM: EMPTY-MIDDLE
  // SPEC-PROVENANCE:
  // - I3/I5/I6: middle empty spread must leave one separator between neighboring items.
  claim <k> fix(empty(middle, P:Int)) => valid </k>
    requires P >=Int 0
    [all-path]

  // CLAIM: EMPTY-LAST
  // SPEC-PROVENANCE:
  // - I3/I5/I6: last empty spread must remove the preceding separator through the spread.
  claim <k> fix(empty(last, P:Int)) => valid </k>
    requires P >=Int 0
    [all-path]
endmodule
