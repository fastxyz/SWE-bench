module MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax Name ::= String
  syntax Fields ::= fields(String)
  syntax Options ::= options(String)
  syntax Bases ::= bases(String)
  syntax Managers ::= managers(String)
  syntax ModelSpec ::= modelSpec(Fields, Options, Bases, Managers)

  syntax Operation ::= create(Name, Fields, Options, Bases, Managers)
                     | alterManagers(Name, Managers)
  syntax Operations ::= ".Ops"
                      | Operation ";" Operations [right]
  syntax ReduceResult ::= reduced(Operations)
                        | canReduceThrough
                        | noReduce

  syntax KItem ::= reduceCreate(Operation, Operation)
                 | applyAll(Operations)
endmodule

module MINI-MIGRATION-OPTIMIZER
  imports MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports STRING
  imports MAP

  configuration
    <k> $PGM:K </k>
    <state> .Map </state>

  rule <k> reduceCreate(create(N, F, O, B, M0), alterManagers(N, M1))
        => reduced(create(N, F, O, B, M1) ; .Ops) ... </k>

  rule <k> reduceCreate(create(N1, F, O, B, M0), alterManagers(N2, M1))
        => canReduceThrough ... </k>
    requires N1 =/=String N2

  rule <k> applyAll(.Ops) => .K ... </k>

  rule <k> applyAll(create(N, F, O, B, M) ; OPS)
        => applyAll(OPS) ... </k>
       <state> S:Map => S [N <- modelSpec(F, O, B, M)] </state>

  rule <k> applyAll(alterManagers(N, M) ; OPS)
        => applyAll(OPS) ... </k>
       <state>
         S:Map [N <- modelSpec(F, O, B, M0)]
         => S [N <- modelSpec(F, O, B, M)]
       </state>
endmodule
