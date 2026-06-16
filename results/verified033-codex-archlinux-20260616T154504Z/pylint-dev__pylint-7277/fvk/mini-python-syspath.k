module MINI-PYTHON-SYSPATH-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports LIST

  syntax EnvCase ::= "noEdge"
                   | "leadingImplicit"
                   | "trailingImplicit"
                   | "leadingExplicit"
                   | "trailingExplicit"
                   | "bothImplicit"

  syntax Pgm ::= "modifySysPath" "(" List "," EnvCase "," String ")"
  syntax KResult ::= List
endmodule

module MINI-PYTHON-SYSPATH
  imports MINI-PYTHON-SYSPATH-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports LIST

  configuration <k> $PGM:Pgm </k>

  syntax Bool ::= isCwdPath(String, String) [function]
  rule isCwdPath("", CWD) => true
  rule isCwdPath(".", CWD) => true
  rule isCwdPath(CWD, CWD) => true
    requires CWD =/=String "" andBool CWD =/=String "."
  rule isCwdPath(P, CWD) => false
    requires P =/=String "" andBool P =/=String "." andBool P =/=String CWD

  syntax Bool ::= firstRemoved(List, String) [function]
  rule firstRemoved(.List, CWD) => false
  rule firstRemoved(ListItem(P:String) REST:List, CWD) => isCwdPath(P, CWD)

  syntax List ::= removeSysPathEntry(List, Int, String) [function]
  rule removeSysPathEntry(.List, I, CWD) => .List
  rule removeSysPathEntry(ListItem(P:String) REST:List, 0, CWD) => REST
    requires isCwdPath(P, CWD)
  rule removeSysPathEntry(ListItem(P:String) REST:List, 0, CWD) => ListItem(P) REST
    requires notBool isCwdPath(P, CWD)
  rule removeSysPathEntry(ListItem(P:String) REST:List, I, CWD)
    => ListItem(P) removeSysPathEntry(REST, I -Int 1, CWD)
    requires I >Int 0

  syntax List ::= modifyFirst(List, String) [function]
  rule modifyFirst(PATHS, CWD) => removeSysPathEntry(PATHS, 0, CWD)

  syntax List ::= modifyLeading(List, Bool, String) [function]
  rule modifyLeading(PATHS, true, CWD) => removeSysPathEntry(PATHS, 0, CWD)
  rule modifyLeading(PATHS, false, CWD) => removeSysPathEntry(PATHS, 1, CWD)

  syntax List ::= modifyTrailing(List, Bool, String) [function]
  rule modifyTrailing(PATHS, true, CWD) => removeSysPathEntry(PATHS, 1, CWD)
  rule modifyTrailing(PATHS, false, CWD) => removeSysPathEntry(PATHS, 2, CWD)

  syntax List ::= modifySysPathValue(List, EnvCase, String) [function]
  rule modifySysPathValue(PATHS, noEdge, CWD) => modifyFirst(PATHS, CWD)
  rule modifySysPathValue(PATHS, leadingExplicit, CWD) => modifyFirst(PATHS, CWD)
  rule modifySysPathValue(PATHS, trailingExplicit, CWD) => modifyFirst(PATHS, CWD)
  rule modifySysPathValue(PATHS, leadingImplicit, CWD)
    => modifyLeading(modifyFirst(PATHS, CWD), firstRemoved(PATHS, CWD), CWD)
  rule modifySysPathValue(PATHS, bothImplicit, CWD)
    => modifyLeading(modifyFirst(PATHS, CWD), firstRemoved(PATHS, CWD), CWD)
  rule modifySysPathValue(PATHS, trailingImplicit, CWD)
    => modifyTrailing(modifyFirst(PATHS, CWD), firstRemoved(PATHS, CWD), CWD)

  rule <k> modifySysPath(PATHS, ENV, CWD) => modifySysPathValue(PATHS, ENV, CWD) </k>
endmodule
