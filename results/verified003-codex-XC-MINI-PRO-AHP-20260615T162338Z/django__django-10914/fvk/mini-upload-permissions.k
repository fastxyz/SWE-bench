module MINI-UPLOAD-PERMISSIONS-SYNTAX
  imports INT-SYNTAX

  syntax Source ::= "temporary" | "memory"
  syntax ModeOpt ::= "none" | "mode" "(" Int ")"
  syntax Exp ::= ModeOpt
               | "defaultUploadPermissions"
               | "initialMode" "(" Source "," Int "," Int ")"
               | "savedMode" "(" Source "," Exp "," Int "," Int ")" [strict(2)]

  syntax KResult ::= Int | ModeOpt
endmodule

module MINI-UPLOAD-PERMISSIONS
  imports MINI-UPLOAD-PERMISSIONS-SYNTAX
  imports INT

  configuration <k> $PGM:Exp </k>

  // Decimal 420 is octal 0o644.
  rule <k> defaultUploadPermissions => mode(420) ... </k>

  rule <k> initialMode(temporary, TMP:Int, MEM:Int) => TMP ... </k>
  rule <k> initialMode(memory, TMP:Int, MEM:Int) => MEM ... </k>

  rule <k> savedMode(SRC:Source, mode(MODE:Int), TMP:Int, MEM:Int) => MODE ... </k>
  rule <k> savedMode(SRC:Source, none, TMP:Int, MEM:Int) => initialMode(SRC, TMP, MEM) ... </k>
endmodule
