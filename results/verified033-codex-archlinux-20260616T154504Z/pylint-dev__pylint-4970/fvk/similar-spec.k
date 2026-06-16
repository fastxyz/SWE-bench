requires "mini-python-similar.k"

module SIMILAR-SPEC
  imports MINI-PYTHON-SIMILAR
  imports INT
  imports LIST
  imports MAP

  // SPEC-PROVENANCE:
  // - E1/E4: "min-similarity-lines=0" disables duplicate-code checking.
  // - E3: disabled checking emits no duplicate-code findings.
  claim
    <k> computeSims(MIN:Int) => .List ... </k>
    <linesets> LS:List </linesets>
    requires MIN <=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E4/E7: disabled duplicate-code checking should avoid local collection work.
  claim
    <k> processModule(MIN:Int) => noOp ... </k>
    <linesets> LS:List => LS </linesets>
    requires MIN <=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: no R0801 messages with disabled duplicate-code checking.
  claim
    <k> closeChecker => emitStats(0, 0) ... </k>
    <sims> .List </sims>
    <messages> MS:List => MS </messages>
    <stats> ST:Map => ("nb_duplicated_lines" |-> 0
                       "percent_duplicated_lines" |-> 0) </stats>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: positive thresholds retain existing duplicate-code semantics.
  claim
    <k> computeSims(MIN:Int) => computeSimsPositive(MIN) ... </k>
    requires MIN >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: positive thresholds retain existing module collection behavior.
  claim
    <k> processModule(MIN:Int) => processModulePositive(MIN) ... </k>
    requires MIN >Int 0
    [all-path]
endmodule
