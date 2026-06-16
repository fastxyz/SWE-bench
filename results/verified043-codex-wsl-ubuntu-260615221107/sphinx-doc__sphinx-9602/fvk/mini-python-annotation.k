module MINI-PY-ANNOTATION-SYNTAX
  imports STRING
  imports INT
  imports BOOL

  syntax Token ::= XRef(String)
                 | Text(String)
                 | Punct(String)
                 | Op(String)

  syntax Tokens ::= ".Tokens"
                  | Token Tokens

  syntax KItem ::= parseAnn(String)
                 | scan(Tokens, Int, Bool)

  syntax Bool ::= isLiteralHead(String) [function]
  rule isLiteralHead("Literal") => true
  rule isLiteralHead("typing.Literal") => true
  rule isLiteralHead("typing_extensions.Literal") => true
endmodule

module MINI-PY-ANNOTATION
  imports MINI-PY-ANNOTATION-SYNTAX

  configuration <k> $PGM:K </k>

  // The production implementation delegates front-end parsing to Python's AST.
  // This MVP semantics abstracts that front-end into representative parseAnn
  // rewrites for the obligation classes audited in this issue.
  rule <k> parseAnn("typing.Literal[True]")
        => XRef("typing.Literal") Punct("[") Text("True") Punct("]") .Tokens
       </k>

  rule <k> parseAnn("typing.Literal[False]")
        => XRef("typing.Literal") Punct("[") Text("False") Punct("]") .Tokens
       </k>

  rule <k> parseAnn("Literal[-1]")
        => XRef("Literal") Punct("[") Text("-1") Punct("]") .Tokens
       </k>

  rule <k> parseAnn("Literal['x']")
        => XRef("Literal") Punct("[") Text("'x'") Punct("]") .Tokens
       </k>

  rule <k> parseAnn("Literal[<Color.RED: 1>]")
        => XRef("Literal") Punct("[") Text("<Color.RED: 1>") Punct("]") .Tokens
       </k>

  rule <k> parseAnn("List[int]")
        => XRef("List") Punct("[") XRef("int") Punct("]") .Tokens
       </k>
endmodule
