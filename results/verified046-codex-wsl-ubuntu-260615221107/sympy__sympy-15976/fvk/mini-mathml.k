// Constructed, not machine-checked.
// A deliberately small K model for the MathML presentation-symbol shape used
// in sympy__sympy-15976. It models only the observable under audit: whether a
// scripted symbol returns MSUB/MSUP/MSUBSUP directly or is wrapped in MI.

module MINI-MATHML-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Strs ::= ".Strs"
                | String "|" Strs [right]

  syntax NodeList ::= ".Nodes"
                    | Node "," NodeList [right]

  syntax Node ::= MI(String, Bool)
                | MO(String)
                | MROW(NodeList)
                | MSUB(Node, Node)
                | MSUP(Node, Node)
                | MSUBSUP(Node, Node, Node)
                | MIWRAP(Node)

  syntax Node ::= join(Strs) [function]
                | printSymbol(String, Strs, Strs, Bool) [function]

  syntax NodeList ::= joinItems(Strs) [function]
  syntax Bool ::= isEmpty(Strs) [function]

  syntax KResult ::= Node | Bool
endmodule

module MINI-MATHML
  imports MINI-MATHML-SYNTAX
  imports BOOL

  configuration <k> $PGM:Node </k>

  rule isEmpty(.Strs) => true
  rule isEmpty(_:String | _:Strs) => false

  rule join(S:String | .Strs) => MI(S, false)
  rule join(S:String | SS:Strs) => MROW(joinItems(S | SS))
    requires notBool isEmpty(SS)

  rule joinItems(S:String | .Strs) => MI(S, false), .Nodes
  rule joinItems(S:String | T:String | REST:Strs)
    => MI(S, false), MO(" "), joinItems(T | REST)

  // printSymbol(BASE, SUPERS, SUBS, BOLD) models
  // MathMLPresentationPrinter._print_Symbol after split_super_sub and
  // translation have produced the base and script lists.
  rule printSymbol(BASE:String, .Strs, .Strs, BOLD:Bool)
    => MI(BASE, BOLD)

  rule printSymbol(BASE:String, .Strs, SUBS:Strs, BOLD:Bool)
    => MSUB(MI(BASE, BOLD), join(SUBS))
    requires notBool isEmpty(SUBS)

  rule printSymbol(BASE:String, SUPERS:Strs, .Strs, BOLD:Bool)
    => MSUP(MI(BASE, BOLD), join(SUPERS))
    requires notBool isEmpty(SUPERS)

  rule printSymbol(BASE:String, SUPERS:Strs, SUBS:Strs, BOLD:Bool)
    => MSUBSUP(MI(BASE, BOLD), join(SUBS), join(SUPERS))
    requires notBool isEmpty(SUPERS) andBool notBool isEmpty(SUBS)
endmodule
