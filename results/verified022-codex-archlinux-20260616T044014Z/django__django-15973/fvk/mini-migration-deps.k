module MINI-MIGRATION-DEPS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Ref ::= ref(String, String)
  syntax Through ::= noThrough | through(Ref)
  syntax Swappable ::= notSwappable | swappable(String)
  syntax Field ::= field(Ref, Through, Swappable)

  syntax Dep ::= dep(String, String, Bool)
  syntax Deps ::= ".Deps" | Dep "," Deps [right]
  syntax Query ::= deps(Field)
  syntax KResult ::= Deps
endmodule

module MINI-MIGRATION-DEPS
  imports MINI-MIGRATION-DEPS-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> deps(field(ref(A, M), noThrough, notSwappable))
        => dep(A, M, true), .Deps
        ... </k>

  rule <k> deps(field(ref(A, M), through(ref(TA, TM)), notSwappable))
        => dep(A, M, true), dep(TA, TM, true), .Deps
        ... </k>

  rule <k> deps(field(ref(_, _), noThrough, swappable(S)))
        => dep("__setting__", S, true), .Deps
        ... </k>

  rule <k> deps(field(ref(_, _), through(ref(TA, TM)), swappable(S)))
        => dep("__setting__", S, true), dep(TA, TM, true), .Deps
        ... </k>
endmodule
