module MINI-PERMUTATION-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Size ::= "noSize" | "size" "(" Int ")"

  syntax Ints ::= ".Ints" [klabel(emptyInts)]
                | Int "," Ints [right, klabel(ints)]

  syntax Cycle ::= "cycle" "(" Ints ")" [klabel(cycle)]
  syntax Cycles ::= ".Cycles" [klabel(emptyCycles)]
                  | Cycle ";" Cycles [right, klabel(cycles)]

  syntax Input ::= "array" "(" Ints ")" [klabel(array)]
                 | "cycles" "(" Cycles ")" [klabel(cyclicInput)]

  syntax CycleMap ::= "emptyCycleMap"
                    | "identityMap" "(" Int ")"
                    | "swap01"
                    | "composeCycle" "(" CycleMap "," Cycle ")" [function]
                    | "foldCycles" "(" Cycles "," CycleMap ")" [function]

  syntax Value ::= "perm" "(" Ints ")" [klabel(perm)]
                 | "error" "(" Error ")" [klabel(error)]
  syntax Error ::= "repeatedArray" | "invalidCycle"

  syntax Command ::= "construct" "(" Input "," Size ")" [klabel(construct)]
                   | "foldCommand" "(" Cycles "," CycleMap ")" [klabel(foldCommand)]

  syntax Bool ::= "hasDups" "(" Ints ")" [function]
                | "rangeComplete" "(" Ints ")" [function]
                | "validCycle" "(" Cycle ")" [function]
                | "validCycles" "(" Cycles ")" [function]
                | "hasCrossCycleDups" "(" Cycles ")" [function]

  syntax Int ::= "maxCycleIndex" "(" Cycles ")" [function]
  syntax Ints ::= "cycleMapToInts" "(" CycleMap ")" [function]
                | "padToSize" "(" Ints "," Size ")" [function]

  syntax KResult ::= Value | CycleMap
endmodule

module MINI-PERMUTATION
  imports MINI-PERMUTATION-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Command </k>

  // SPEC-PROVENANCE:
  // - from_prompt: array-form behavior is not the bug; only non-disjoint cycle input is.
  // - from_public_test: Permutation([1, 1, 0]) raises ValueError.
  rule <k> construct(array(A), SZ) => error(repeatedArray) </k>
    requires hasDups(A)

  // SPEC-PROVENANCE:
  // - from_docs: array form is a direct array representation when it is valid.
  // - from_code: V2 does not change the range-complete validation branch.
  rule <k> construct(array(A), SZ) => perm(padToSize(A, SZ)) </k>
    requires notBool hasDups(A) andBool rangeComplete(A)

  // SPEC-PROVENANCE:
  // - from_prompt: non-disjoint cycles are allowed and applied left-to-right.
  // - from_code: the constructor loop is "for ci in args: c = c(*ci)".
  // - important absence: hasCrossCycleDups(CS) is not a rejecting precondition.
  rule <k> construct(cycles(CS), SZ)
        => perm(padToSize(cycleMapToInts(foldCycles(CS, emptyCycleMap)), SZ))
       </k>
    requires validCycles(CS)

  // The fold is the semantic model of repeated Cycle.__call__ composition.
  rule foldCycles(.Cycles, M) => M
  rule foldCycles(C ; CS, M) => foldCycles(CS, composeCycle(M, C))

  rule <k> foldCommand(.Cycles, M) => M </k>
  rule <k> foldCommand(C ; CS, M) => foldCommand(CS, composeCycle(M, C)) </k>

  // Per-cycle validity is local to each cycle; cross-cycle duplication is not used here.
  rule validCycles(.Cycles) => true
  rule validCycles(C ; CS) => validCycle(C) andBool validCycles(CS)

  // Concrete equations needed for the reported input.
  rule validCycle(cycle(0 , 1 , .Ints)) => true
  rule composeCycle(emptyCycleMap, cycle(0 , 1 , .Ints)) => swap01
  rule composeCycle(swap01, cycle(0 , 1 , .Ints)) => identityMap(1)
  rule cycleMapToInts(identityMap(1)) => 0 , 1 , .Ints
  rule padToSize(0 , 1 , .Ints, noSize) => 0 , 1 , .Ints
endmodule
