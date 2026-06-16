module MINI-MIGRATIONS-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // Abstract keys and finite key sets. A real machine check would instantiate
  // these with concrete constructors or an imported collection theory.
  syntax Key
  syntax KeySet
  syntax ReplacementMap

  syntax Stmt ::= "checkReplacements"
endmodule

module MINI-MIGRATIONS
  imports MINI-MIGRATIONS-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <applied> .KeySet </applied>
    <replacements> .ReplacementMap </replacements>

  syntax KeySet ::= ".KeySet"
                  | add(KeySet, Key)      [function]
                  | remove(KeySet, Key)   [function]
                  | reconcile(KeySet, ReplacementMap) [function]

  syntax KeySet ::= targets(ReplacementMap, Key) [function]
                  | replacementKeys(ReplacementMap) [function]

  syntax Bool ::= contains(KeySet, Key) [function]
                | allApplied(KeySet, KeySet) [function]

  // This is the abstract transition corresponding to
  // MigrationExecutor.check_replacements(). The spec file states the required
  // properties of reconcile(), mirroring the branch behavior of the Python
  // implementation.
  rule
    <k> checkReplacements => .K </k>
    <applied> A:KeySet => reconcile(A, RM) </applied>
    <replacements> RM:ReplacementMap </replacements>
endmodule
