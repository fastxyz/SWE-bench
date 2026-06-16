module MINI-PYTHON-DATE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Offset ::= "noOffset"
                  | "year" "(" Int ")"
                  | "formatted" "(" Int "," Int ")"

  syntax Exp ::= "offsetFor" "(" Int "," Bool "," Bool "," Int ")"
  syntax KResult ::= Offset
endmodule

module MINI-PYTHON-DATE
  imports MINI-PYTHON-DATE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // show_offset=False is authoritative for every selected level.
  rule <k> offsetFor(L:Int, false, H:Bool, Y:Int) => noOffset </k>
    requires 0 <=Int L andBool L <=Int 5

  // Year-level labels already carry the year.
  rule <k> offsetFor(0, true, H:Bool, Y:Int) => noOffset </k>

  // Month-level labels with January normally carry the year via zero_formats[1].
  rule <k> offsetFor(1, true, true, Y:Int) => noOffset </k>

  // Month-level labels without January need the offset to carry the year.
  rule <k> offsetFor(1, true, false, Y:Int) => year(Y) </k>

  // Finer levels retain the existing level-specific offset behavior.
  rule <k> offsetFor(L:Int, true, H:Bool, Y:Int) => formatted(L, Y) </k>
    requires 2 <=Int L andBool L <=Int 5
endmodule

