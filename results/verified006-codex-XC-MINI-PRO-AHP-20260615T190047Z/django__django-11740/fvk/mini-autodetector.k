module MINI-AUTODETECTOR-SYNTAX
  imports BOOL-SYNTAX

  syntax Deps ::= ".Deps" [klabel(noDeps)]
                | "deps" "(" Bool ")" [klabel(deps)]

  syntax Field ::= "field" "(" Bool "," Deps ")"
  syntax Op ::= "alterField" "(" Field "," Deps ")"
  syntax KItem ::= "genAlterField" "(" Field ")"
endmodule

module MINI-AUTODETECTOR
  imports MINI-AUTODETECTOR-SYNTAX
  imports LIST

  configuration
    <k> $PGM:K </k>
    <ops> .List </ops>

  // Relational emitted fields carry their FK/M2M dependency list.
  rule
    <k> genAlterField(field(true, DEPS)) => .K </k>
    <ops> OPS => OPS ListItem(alterField(field(true, DEPS), DEPS)) </ops>

  // Non-relational emitted fields preserve the old empty-dependency behavior.
  rule
    <k> genAlterField(field(false, DEPS)) => .K </k>
    <ops> OPS => OPS ListItem(alterField(field(false, DEPS), .Deps)) </ops>
endmodule
