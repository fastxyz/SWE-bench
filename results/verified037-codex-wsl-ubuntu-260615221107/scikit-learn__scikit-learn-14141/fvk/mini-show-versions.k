requires "domains.md"

module MINI-SHOW-VERSIONS-SYNTAX
  imports STRING-SYNTAX
  imports LIST
  imports MAP

  syntax Pgm ::= getDepsInfo(List)
               | showVersions(List)

  syntax KItem ::= depsLoop(List, Map)
                 | printDeps(Map)

  syntax String ::= versionOf(String, Map) [function]
endmodule

module MINI-SHOW-VERSIONS
  imports MINI-SHOW-VERSIONS-SYNTAX
  imports BOOL
  imports STRING
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Pgm </k>
    <installed> .Map </installed>
    <depsInfo> .Map </depsInfo>
    <printedDeps> .Map </printedDeps>

  // Abstract importlib.import_module(name).__version__ with the same
  // ImportError fallback shape used by _get_deps_info().
  rule versionOf(D, INSTALLED) => {INSTALLED[D]}
    requires D in_keys(INSTALLED)
  rule versionOf(D, INSTALLED) => "None"
    requires notBool D in_keys(INSTALLED)

  rule <k> getDepsInfo(DEPS) => depsLoop(DEPS, .Map) ... </k>

  rule <k> depsLoop(.List, M) => M ... </k>
       <depsInfo> _ => M </depsInfo>

  rule <k> depsLoop(ListItem(D) REST, M)
        => depsLoop(REST, M [ D <- versionOf(D, INSTALLED) ]) ... </k>
       <installed> INSTALLED </installed>

  // show_versions() obtains deps_info and then prints every dependency entry.
  // BLAS and system sections are intentionally abstracted away because the
  // issue concerns only the Python dependency block.
  rule <k> showVersions(DEPS) => getDepsInfo(DEPS) ~> printDeps(.Map) ... </k>

  rule <k> M:Map ~> printDeps(_) => . ... </k>
       <printedDeps> _ => M </printedDeps>
endmodule
