module MINI-MIGRATION-AUTODETECTOR-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  syntax Op  ::= create(String, String)
               | addField(String, String, String)
               | remove(String, String, String)
  syntax Dep ::= depCreate(String, String)
               | depRemove(String, String, String)
  syntax Step ::= generateDeps(String, String, String, String, String, String)
                | sortSameApp(Op, Op, Dep)
                | splitCrossApp(Op, Op, Dep)
                | generateRemoved(String, String, String)
                | done

  syntax Bool ::= baseOf(String, String, String, String) [function]
                | localField(String, String) [function]
                | removedField(String, String, String) [function]
                | relatedField(String, String) [function]
                | generated(Op) [function]
                | autoDep(Op, Dep) [function]
                | matches(Op, Dep) [function]
                | before(Op, Op) [function]
                | migrationDependsOn(Op, Op) [function]
                | countRemove(String, String, String, Int) [function]
endmodule

module MINI-MIGRATION-AUTODETECTOR
  imports MINI-MIGRATION-AUTODETECTOR-SYNTAX

  configuration <k> $PGM:Step </k>

  // This MVP semantics is intentionally abstract. The predicates above are
  // uninterpreted relations over the symbolic old/new field sets and operation
  // graph. The reachability claims constrain the relations to the audited
  // Django source paths.
endmodule
