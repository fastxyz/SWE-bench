// Constructed FVK model for sphinx.domains.python._parse_annotation().
// Status: constructed, not machine-checked.
//
// This is a property-complete mini semantics for the audited delimiter behavior,
// not a full Python or docutils semantics. It models the AST node families and
// output token order needed to distinguish the reported failure from the fix.

module MINI-PYTHON-ANNOTATION-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Ast ::= Name(String)
               | List(Asts)
               | Tuple(Asts)
               | Subscript(Ast, Ast)

  syntax Asts ::= ".Asts"
                | Ast "," Asts [klabel(astsCons)]

  syntax Tok ::= XRef(String)
               | Punct(String)

  syntax Toks ::= ".Toks"
                | Tok Toks [klabel(toksCons)]

  syntax Cmd ::= render(Ast)

  syntax KResult ::= Toks
endmodule

module MINI-PYTHON-ANNOTATION
  imports MINI-PYTHON-ANNOTATION-SYNTAX

  configuration <k> $PGM:Cmd </k>

  syntax Toks ::= renderTok(Ast)       [function]
                | renderList(Asts)     [function]
                | renderTuple(Asts)    [function]
                | join(Asts)           [function]
                | concat(Toks, Toks)   [function]
                | commaThen(Asts)      [function]

  syntax Bool ::= isEmpty(Asts) [function]

  rule isEmpty(.Asts) => true
  rule isEmpty(_A:Ast , _AS:Asts) => false

  rule concat(.Toks, TS:Toks) => TS
  rule concat(T:Tok TS1:Toks, TS2:Toks) => T concat(TS1, TS2)

  rule renderTok(Name(S:String)) => XRef(S) .Toks
  rule renderTok(Subscript(V:Ast, S:Ast))
    => concat(renderTok(V),
              Punct("[") concat(renderTok(S), Punct("]") .Toks))
  rule renderTok(List(AS:Asts)) => renderList(AS)
  rule renderTok(Tuple(AS:Asts)) => renderTuple(AS)

  // Empty delimiter cases.
  rule renderList(.Asts) => Punct("[") Punct("]") .Toks
  rule renderTuple(.Asts) => Punct("(") Punct(")") .Toks

  // Non-empty delimiter cases.
  rule renderList(AS:Asts)
    => Punct("[") concat(join(AS), Punct("]") .Toks)
    requires isEmpty(AS) ==Bool false

  rule renderTuple(AS:Asts) => join(AS)
    requires isEmpty(AS) ==Bool false

  rule join(A:Ast , .Asts) => renderTok(A)
  rule join(A:Ast , AS:Asts)
    => concat(renderTok(A), Punct(", ") commaThen(AS))
    requires isEmpty(AS) ==Bool false

  rule commaThen(AS:Asts) => join(AS)

  rule <k> render(A:Ast) => renderTok(A) ... </k>
endmodule
