// Constructed FVK side artifact. Not compiled or machine-checked.

module MINI-SIGNATURE-DEFAULT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Node ::= Const(String)
                | Name(String)
                | Tuple(Nodes)
                | Subscript(Node, Node)
                | List(Node)

  syntax Nodes ::= ".Nodes"
                 | Node ";" Nodes

  syntax String ::= render(Node, Bool) [function]
                  | renderSlice(Node, Bool) [function]
                  | join(Nodes, Bool) [function]
endmodule

module MINI-SIGNATURE-DEFAULT
  imports MINI-SIGNATURE-DEFAULT-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:String </k>

  rule render(Const(S:String), _:Bool) => S
  rule render(Name(S:String), _:Bool) => S

  rule render(Tuple(.Nodes), _:Bool) => "()"
  rule render(Tuple(N ; .Nodes), true)
    => "(" +String render(N, true) +String ",)"
  rule render(Tuple(N1 ; N2 ; NS), true)
    => "(" +String join(N1 ; N2 ; NS, true) +String ")"
  rule render(Tuple(NS), false) => join(NS, false)
    requires NS =/=K .Nodes

  rule render(Subscript(V, S), B)
    => render(V, B) +String "[" +String renderSlice(S, B) +String "]"
  rule renderSlice(Tuple(.Nodes), B) => render(Tuple(.Nodes), B)
  rule renderSlice(Tuple(NS), B) => join(NS, B)
    requires NS =/=K .Nodes
  rule renderSlice(N, B) => render(N, B)
    requires notBool isTupleNode(N)

  rule render(List(N), B) => "[" +String render(N, B) +String "]"

  rule join(.Nodes, _:Bool) => ""
  rule join(N ; .Nodes, B) => render(N, B)
  rule join(N1 ; N2 ; NS, B)
    => render(N1, B) +String ", " +String join(N2 ; NS, B)

  syntax Bool ::= isTupleNode(Node) [function]
  rule isTupleNode(Tuple(_:Nodes)) => true
  rule isTupleNode(Const(_:String)) => false
  rule isTupleNode(Name(_:String)) => false
  rule isTupleNode(Subscript(_:Node, _:Node)) => false
  rule isTupleNode(List(_:Node)) => false
endmodule
