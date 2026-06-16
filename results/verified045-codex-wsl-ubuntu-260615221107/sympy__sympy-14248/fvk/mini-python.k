// FVK mini semantics for the matrix-add sign-joining fragment.
// Constructed, not machine-checked.
//
// This is not a full Python semantics. It models only the observable property
// under audit: how a printer loop joins already-renderable matrix-add terms
// with plus or minus separators.

module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX

  syntax Style ::= "str" | "latex" | "pretty"

  // Abstract positive bodies. The concrete printers render these differently
  // by style; the sign discipline is the verified property.
  syntax Body ::= "A" | "B" | "AB" | "CMD"

  // pos(B) means no extractable minus sign. neg(B) means the matrix coefficient
  // can extract a minus sign and B is the body after negating the term.
  syntax Term ::= pos(Body) | neg(Body)
  syntax Terms ::= ".Terms" | Term ";" Terms

  syntax Piece ::= bare(Body) | firstMinus(Body) | plus(Body) | minus(Body)
  syntax Pieces ::= ".Pieces" | Piece ";" Pieces
  syntax Pieces ::= Pieces "++" Pieces [function, left]

  syntax Pgm ::= render(Style, Terms)
               | loop(Style, Terms, Bool, Pieces)
  syntax KResult ::= Pieces
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Pgm </k>
    <out> .Pieces </out>

  rule .Pieces ++ PS:Pieces => PS
  rule (P:Piece ; PS:Pieces) ++ QS:Pieces => P ; (PS ++ QS)

  rule <k> render(STYLE:Style, TS:Terms)
        => loop(STYLE, TS, true, .Pieces)
       ... </k>
       <out> _ => .Pieces </out>

  rule <k> loop(STYLE:Style, .Terms, FIRST:Bool, ACC:Pieces)
        => .K
       ... </k>
       <out> _ => ACC </out>

  rule <k> loop(STYLE:Style, pos(B:Body) ; TS:Terms, true, ACC:Pieces)
        => loop(STYLE, TS, false, ACC ++ (bare(B) ; .Pieces))
       ... </k>

  rule <k> loop(STYLE:Style, pos(B:Body) ; TS:Terms, false, ACC:Pieces)
        => loop(STYLE, TS, false, ACC ++ (plus(B) ; .Pieces))
       ... </k>

  rule <k> loop(STYLE:Style, neg(B:Body) ; TS:Terms, true, ACC:Pieces)
        => loop(STYLE, TS, false, ACC ++ (firstMinus(B) ; .Pieces))
       ... </k>

  rule <k> loop(STYLE:Style, neg(B:Body) ; TS:Terms, false, ACC:Pieces)
        => loop(STYLE, TS, false, ACC ++ (minus(B) ; .Pieces))
       ... </k>
endmodule
