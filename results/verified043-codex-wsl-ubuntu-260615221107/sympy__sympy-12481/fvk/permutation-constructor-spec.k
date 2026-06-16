requires "mini-permutation.k"

module PERMUTATION-CONSTRUCTOR-SPEC
  imports MINI-PERMUTATION

  // SPEC-PROVENANCE:
  // - E2/E3/E4: Non-disjoint cycle-list input is in domain.
  // - Formal meaning: even when cross-cycle duplicates exist, construction returns
  //   the left-to-right cycle fold. There is no disjointness precondition.
  claim <k> construct(cycles(CS), SZ)
        => perm(padToSize(cycleMapToInts(foldCycles(CS, emptyCycleMap)), SZ))
       </k>
    requires validCycles(CS) andBool hasCrossCycleDups(CS)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: Permutation([[0,1],[0,1]]) constructs identity.
  // - The two equal transpositions compose to identity on 0 and 1.
  claim <k> construct(cycles(cycle(0 , 1 , .Ints) ; cycle(0 , 1 , .Ints) ; .Cycles), noSize)
        => perm(0 , 1 , .Ints)
       </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: Array form with repeated images remains invalid.
  // - This separates array duplicate rejection from cycle-list overlap.
  claim <k> construct(array(A), SZ) => error(repeatedArray) </k>
    requires hasDups(A)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E9: The constructor processes cycles in list order.
  // - This circularity/recursive fold obligation is the proof model for
  //   "for ci in args: c = c(*ci)".
  claim <k> foldCommand(CS, M) => foldCycles(CS, M) </k>
    requires validCycles(CS)
    [all-path]
endmodule
