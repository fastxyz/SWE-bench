requires "domains.md"

module MINI-AUTORELOAD-SYNTAX
  imports STRING
  imports BOOL
  imports LIST

  syntax Parent ::= noParent() | parent(String)
  syntax Outcome ::= returned(List) | runtimeError(String)
  syntax KResult ::= Outcome

  syntax KItem ::= Outcome
                 | getChildArguments(
      String,  // sys.executable
      List,    // sys.warnoptions as strings without "-W"
      List,    // sys.argv, non-empty
      Parent,  // abstraction of __main__.__spec__.parent
      Bool,    // Path(sys.argv[0]).exists()
      Bool,    // py_script.with_suffix(".exe").exists()
      Bool,    // py_script.with_name("%s-script.py").exists()
      String,  // exe fallback path
      String   // script fallback path
  )
endmodule

module MINI-AUTORELOAD
  imports MINI-AUTORELOAD-SYNTAX
  imports STRING
  imports BOOL
  imports LIST

  configuration <k> $PGM:K </k>

  syntax List ::= warnArgs(List) [function]
  rule warnArgs(.List) => .List
  rule warnArgs(ListItem(W:String) WS:List) => ListItem("-W" +String W) warnArgs(WS)

  syntax String ::= head(List) [function]
  rule head(ListItem(A:String) _:List) => A

  syntax List ::= tail(List) [function]
  rule tail(ListItem(_:String) REST:List) => REST

  syntax List ::= pythonPrefix(String, List) [function]
  rule pythonPrefix(EXE:String, WARN:List) => ListItem(EXE) warnArgs(WARN)

  // A non-empty spec parent is the public-intent package "-m" branch.
  rule <k> getChildArguments(EXE, WARN, ARGV, parent(P), SCRIPTEXISTS, EXEFALLBACK, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ListItem("-m") ListItem(P) tail(ARGV)) ... </k>
    requires P =/=String ""

  // No parent, or an empty parent, uses the legacy script/fallback logic.
  rule <k> getChildArguments(EXE, WARN, ARGV, noParent(), true, EXEFALLBACK, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ARGV) ... </k>

  rule <k> getChildArguments(EXE, WARN, ARGV, noParent(), false, true, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(ListItem(EXEPATH) tail(ARGV)) ... </k>

  rule <k> getChildArguments(EXE, WARN, ARGV, noParent(), false, false, true, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ListItem(SCRIPTPATH) tail(ARGV)) ... </k>

  rule <k> getChildArguments(EXE, WARN, ARGV, noParent(), false, false, false, EXEPATH, SCRIPTPATH)
        => runtimeError("Script " +String head(ARGV) +String " does not exist.") ... </k>
endmodule
