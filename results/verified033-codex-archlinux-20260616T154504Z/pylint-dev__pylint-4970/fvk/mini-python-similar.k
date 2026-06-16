// Abstract mini semantics for the pylint similarity-disable proof.
// Constructed, not machine-checked.
// This is not full Python. It models only the state dimensions needed for the
// min-similarity-lines disabled-path proof.

module MINI-PYTHON-SIMILAR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX
  imports STRING-SYNTAX

  syntax KItem ::= computeSims(Int)
                 | computeSimsPositive(Int)
                 | processModule(Int)
                 | processModulePositive(Int)
                 | closeChecker
                 | emitDuplicateMessages(List)
                 | emitStats(Int, Int)
                 | noOp

  syntax KResult ::= List | Int | Bool | noOp
endmodule

module MINI-PYTHON-SIMILAR
  imports MINI-PYTHON-SIMILAR-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP
  imports STRING

  configuration
    <k> $PGM:K </k>
    <linesets> .List </linesets>
    <sims> .List </sims>
    <messages> .List </messages>
    <stats> .Map </stats>

  // Disabled computation: mirrors Similar._compute_sims guard.
  rule <k> computeSims(MIN:Int) => .List ... </k>
       requires MIN <=Int 0

  // Positive computation is intentionally abstract: the patch preserves the
  // previous algorithm when MIN > 0.
  rule <k> computeSims(MIN:Int) => computeSimsPositive(MIN) ... </k>
       requires MIN >Int 0

  // Disabled pylint processing: mirrors SimilarChecker.process_module guard.
  rule <k> processModule(MIN:Int) => noOp ... </k>
       <linesets> LS:List => LS </linesets>
       requires MIN <=Int 0

  // Positive processing is abstract and stands for the pre-existing stream
  // read plus append_stream path.
  rule <k> processModule(MIN:Int) => processModulePositive(MIN) ... </k>
       requires MIN >Int 0

  // Closing over an empty similarity list emits no duplicate-code messages and
  // writes zero duplicate stats.
  rule <k> closeChecker => emitStats(0, 0) ... </k>
       <sims> .List </sims>
       <messages> MS:List => MS </messages>
       <stats> _ => ("nb_duplicated_lines" |-> 0
                     "percent_duplicated_lines" |-> 0) </stats>
endmodule
