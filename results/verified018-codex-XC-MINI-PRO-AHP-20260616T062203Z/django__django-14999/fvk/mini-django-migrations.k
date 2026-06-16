module MINI-DJANGO-MIGRATIONS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "renameModelForwards" "(" Bool "," Bool "," Int "," Int ")"
                | "emitRename"
                | "emitRelated" "(" Int ")"
                | "emitM2M" "(" Int ")"
                | "done"

  syntax KResult ::= "done"
endmodule

module MINI-DJANGO-MIGRATIONS
  imports MINI-DJANGO-MIGRATIONS-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <dbops> 0 </dbops>

  // SPEC-PROVENANCE:
  // - from_prompt: "RenameModel with db_table should be a noop" => same-table branch emits no DB operations.
  // - from_code: allow_migrate_model() wraps the entire database branch.
  rule <k> renameModelForwards(false, SAME:Bool, R:Int, M:Int) => done ... </k>
    requires R >=Int 0 andBool M >=Int 0

  // SPEC-PROVENANCE:
  // - from_prompt: same-table RenameModel is a no-op.
  // - from_code: V1 returns before alter_db_table(), related alter_field(), and M2M loops.
  rule <k> renameModelForwards(true, true, R:Int, M:Int) => done ... </k>
    requires R >=Int 0 andBool M >=Int 0

  // SPEC-PROVENANCE:
  // - from_public_tests: when table names differ, RenameModel moves the table and repoints relations/M2Ms.
  // - from_code: existing branch emits one table operation, one operation per related object, and two per applicable M2M.
  rule <k> renameModelForwards(true, false, R:Int, M:Int)
        => emitRename ~> emitRelated(R) ~> emitM2M(M) ... </k>
    requires R >=Int 0 andBool M >=Int 0

  rule <k> emitRename => done ... </k>
       <dbops> OPS:Int => OPS +Int 1 </dbops>

  rule <k> emitRelated(0) => done ... </k>
  rule <k> emitRelated(R:Int) => emitRelated(R -Int 1) ... </k>
       <dbops> OPS:Int => OPS +Int 1 </dbops>
    requires R >Int 0

  rule <k> emitM2M(0) => done ... </k>
  rule <k> emitM2M(M:Int) => emitM2M(M -Int 1) ... </k>
       <dbops> OPS:Int => OPS +Int 2 </dbops>
    requires M >Int 0

  rule <k> done ~> K => K ... </k>
endmodule
