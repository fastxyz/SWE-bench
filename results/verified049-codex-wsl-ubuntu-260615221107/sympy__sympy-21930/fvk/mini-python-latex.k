// Minimal K-style fragment for the audited LaTeX power-printing behavior.
// Constructed for FVK documentation; not machine-checked in this task.

module MINI-PYTHON-LATEX-SYNTAX
  imports STRING-SYNTAX

  syntax Obj ::= Creator(String)
               | Symbol(String)
               | Function(String)
               | Other(String)

  syntax Exp ::= Exp(String)

  syntax Pgm ::= print(Obj)
               | power(Obj, Exp)
               | foldFracPower(Obj, String, String)
               | customPowerBase(Obj)

endmodule

module MINI-PYTHON-LATEX
  imports MINI-PYTHON-LATEX-SYNTAX
  imports STRING

  configuration <k> $PGM:Pgm </k> <out> "" </out>

  rule <k> print(Creator(L)) => . </k>
       <out> _ => L </out>

  rule <k> customPowerBase(Creator(L)) => . </k>
       <out> _ => "{" +String L +String "}" </out>

  rule <k> power(Creator(L), Exp(E)) => . </k>
       <out> _ => "{" +String L +String "}^{" +String E +String "}" </out>

  rule <k> foldFracPower(Creator(L), P, Q) => . </k>
       <out> _ => "{" +String L +String "}^{" +String P +String "/" +String Q +String "}" </out>

  rule <k> power(Other(L), Exp(E)) => . </k>
       <out> _ => L +String "^{" +String E +String "}" </out>

endmodule

