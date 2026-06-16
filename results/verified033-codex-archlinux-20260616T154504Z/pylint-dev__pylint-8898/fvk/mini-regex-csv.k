module MINI-REGEX-CSV-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Chr ::= "COMMA" | "BSLASH" | "LBRACE" | "RBRACE" | "LBRACK" | "RBRACK" | "OTHER" "(" String ")"
  syntax Chrs ::= ".Chrs" | Chr Chrs [right]
  syntax Pat ::= "pat" "(" Chrs ")"
  syntax Pats ::= ".Pats" | Pat ";;" Pats [right]
  syntax State ::= "st" "(" Pats "," Chrs "," Bool "," Bool "," Bool ")"
  syntax Cmd ::= "split" "(" Chrs ")" | "scan" "(" Chrs "," State ")" | "done" "(" Pats ")"
  syntax KResult ::= "done" "(" Pats ")"
endmodule

module MINI-REGEX-CSV
  imports MINI-REGEX-CSV-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Chrs ::= append(Chrs, Chr) [function]
  syntax Chrs ::= strip(Chrs) [function]
  syntax Bool ::= nonEmpty(Chrs) [function]
  syntax Pats ::= snoc(Pats, Pat) [function]
  syntax Pats ::= emit(Pats, Chrs) [function]

  rule append(.Chrs, C:Chr) => C .Chrs
  rule append(C:Chr CS:Chrs, D:Chr) => C append(CS, D)

  // strip/nonEmpty are spec helpers for Python's fragment.strip() and truthiness.
  // This fragment has no whitespace token, so strip is identity for modeled inputs.
  rule strip(CS:Chrs) => CS
  rule nonEmpty(.Chrs) => false
  rule nonEmpty(_:Chr _:Chrs) => true
  rule snoc(.Pats, P:Pat) => P ;; .Pats
  rule snoc(P:Pat ;; PS:Pats, Q:Pat) => P ;; snoc(PS, Q)
  rule emit(PS:Pats, CUR:Chrs) => snoc(PS, pat(strip(CUR))) requires nonEmpty(strip(CUR))
  rule emit(PS:Pats, CUR:Chrs) => PS requires notBool nonEmpty(strip(CUR))

  rule <k> split(CS:Chrs) => scan(CS, st(.Pats, .Chrs, false, false, false)) </k>

  rule <k> scan(.Chrs, st(PS:Pats, CUR:Chrs, _:Bool, _:Bool, _:Bool)) => done(emit(PS, CUR)) </k>

  rule <k> scan(C:Chr CS:Chrs, st(PS:Pats, CUR:Chrs, true, INCLASS:Bool, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, C), false, INCLASS, OPENBRACE)) </k>

  rule <k> scan(BSLASH CS:Chrs, st(PS:Pats, CUR:Chrs, false, INCLASS:Bool, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, BSLASH), true, INCLASS, OPENBRACE)) </k>

  rule <k> scan(LBRACK CS:Chrs, st(PS:Pats, CUR:Chrs, false, false, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, LBRACK), false, true, OPENBRACE)) </k>

  rule <k> scan(RBRACK CS:Chrs, st(PS:Pats, CUR:Chrs, false, true, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, RBRACK), false, false, OPENBRACE)) </k>

  rule <k> scan(LBRACE CS:Chrs, st(PS:Pats, CUR:Chrs, false, false, _:Bool))
        => scan(CS, st(PS, append(CUR, LBRACE), false, false, true)) </k>

  rule <k> scan(RBRACE CS:Chrs, st(PS:Pats, CUR:Chrs, false, false, true))
        => scan(CS, st(PS, append(CUR, RBRACE), false, false, false)) </k>

  rule <k> scan(COMMA CS:Chrs, st(PS:Pats, CUR:Chrs, false, false, false))
        => scan(CS, st(emit(PS, CUR), .Chrs, false, false, false)) </k>

  rule <k> scan(COMMA CS:Chrs, st(PS:Pats, CUR:Chrs, false, true, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, COMMA), false, true, OPENBRACE)) </k>

  rule <k> scan(COMMA CS:Chrs, st(PS:Pats, CUR:Chrs, false, false, true))
        => scan(CS, st(PS, append(CUR, COMMA), false, false, true)) </k>

  rule <k> scan(C:Chr CS:Chrs, st(PS:Pats, CUR:Chrs, false, INCLASS:Bool, OPENBRACE:Bool))
        => scan(CS, st(PS, append(CUR, C), false, INCLASS, OPENBRACE)) </k>
    requires C =/=K BSLASH andBool C =/=K COMMA
     andBool notBool (C ==K LBRACK andBool notBool INCLASS)
     andBool notBool (C ==K RBRACK andBool INCLASS)
     andBool notBool (C ==K LBRACE andBool notBool INCLASS)
     andBool notBool (C ==K RBRACE andBool OPENBRACE andBool notBool INCLASS)
endmodule
