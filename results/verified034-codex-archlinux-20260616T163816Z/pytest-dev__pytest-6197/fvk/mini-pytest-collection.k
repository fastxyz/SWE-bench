// Abstract mini-K model for pytest package/module collection.
// Constructed for FVK documentation; not machine-checked in this workspace.

module MINI-PYTEST-COLLECTION-SYNTAX
  imports ID-SYNTAX
  imports BOOL-SYNTAX
  imports SET-SYNTAX

  syntax Path ::= Id

  syntax Cmd ::= collectPackage(Path)
               | collectModule(Path, Set)
               | mountPackages(Set)
               | importModule(Path)
               | done

  syntax KResult ::= done
endmodule

module MINI-PYTEST-COLLECTION
  imports MINI-PYTEST-COLLECTION-SYNTAX
  imports BOOL
  imports SET

  configuration
    <k> $PGM:Cmd </k>
    <imports> .Set </imports>

  syntax Bool ::= hasModuleDesc(Path) [function]
                | initMatchesPythonFiles(Path) [function]
  syntax Set ::= parents(Path) [function]

  // V1 Package.collect: package discovery/scanning itself has no import event.
  rule <k> collectPackage(P) => done ... </k>
    requires notBool hasModuleDesc(P) andBool notBool initMatchesPythonFiles(P)

  // If a module descendant exists, importing is delegated to Module.collect.
  rule <k> collectPackage(P) => collectModule(P, parents(P)) ... </k>
    requires hasModuleDesc(P) orBool initMatchesPythonFiles(P)

  // V1 Module.collect: mount package parents before collecting the module.
  rule <k> collectModule(M, PS) => mountPackages(PS) ~> importModule(M) ... </k>

  rule <k> mountPackages(.Set) => done ... </k>

  rule <k> mountPackages(SetItem(P) PS) => mountPackages(PS) ... </k>
       <imports> IS => IS SetItem(P) </imports>

  rule <k> importModule(M) => done ... </k>
       <imports> IS => IS SetItem(M) </imports>

  rule <k> done ~> K => K </k>
endmodule
