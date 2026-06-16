module MINI-PYTHON-QUICKSTART-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Stmt ::= "mainInteractive"
                | "askUserExisting"
                | "warnExisting"
                | "exit" "(" Int ")"
                | "generate"
                | "promptReplacement"

  syntax KResult ::= Int | Bool
endmodule

module MINI-PYTHON-QUICKSTART
  imports MINI-PYTHON-QUICKSTART-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Stmt </k>
    <rootConf> false </rootConf>
    <sourceConf> false </sourceConf>
    <status> 0 </status>
    <warning> false </warning>
    <replacementPrompt> false </replacementPrompt>
    <generated> false </generated>

  // Reduced model of quickstart.main() entering the interactive branch:
  // ask_user(d), then generate(d), unless ask_user exits.
  rule <k> mainInteractive => askUserExisting ~> generate ... </k>

  // V1 behavior: an existing project at either supported location exits before
  // any replacement-root prompt or generation.
  rule <k> askUserExisting => warnExisting ~> exit(1) ... </k>
       <rootConf> true </rootConf>

  rule <k> askUserExisting => warnExisting ~> exit(1) ... </k>
       <rootConf> false </rootConf>
       <sourceConf> true </sourceConf>

  // Frame for the unchanged non-conflict path in this reduced model.
  rule <k> askUserExisting => .K ... </k>
       <rootConf> false </rootConf>
       <sourceConf> false </sourceConf>

  rule <k> warnExisting => .K ... </k>
       <warning> _ => true </warning>

  // sys.exit(1), caught by main(), aborts the remaining continuation.
  rule <k> exit(I:Int) ~> _REST:K => .K </k>
       <status> _ => I </status>

  rule <k> exit(I:Int) => .K </k>
       <status> _ => I </status>

  rule <k> generate => .K ... </k>
       <generated> _ => true </generated>

  // Legacy V0 path kept only to make the omitted property observable: V1 claims
  // require this statement not to be reached when rootConf/sourceConf is true.
  rule <k> promptReplacement => .K ... </k>
       <replacementPrompt> _ => true </replacementPrompt>
endmodule
