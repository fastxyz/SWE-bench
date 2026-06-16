module LAMBDIFY-STRINGIFY-SYNTAX
  imports STRING-SYNTAX
  imports INT-SYNTAX

  syntax Node ::= atom(String)
                | basic(String)
                | matrix(String)
                | pyString(String)
                | pyList(Nodes)
                | pyTuple(Nodes)

  syntax Nodes ::= emptyNodes()
                 | cons(Node, Nodes)

  syntax KResult ::= String

  syntax String ::= render(Node) [function]
                  | renderNodes(Nodes) [function]
                  | returnLine(Node) [function]

  syntax Int ::= length(Nodes) [function]
endmodule

module LAMBDIFY-STRINGIFY
  imports LAMBDIFY-STRINGIFY-SYNTAX
  imports STRING
  imports INT

  configuration <k> $PGM:String </k>

  rule render(atom(S:String)) => S
  rule render(basic(S:String)) => S
  rule render(matrix(S:String)) => S
  rule render(pyString(S:String)) => S

  rule render(pyList(NS:Nodes)) => "[" +String renderNodes(NS) +String "]"

  rule render(pyTuple(emptyNodes())) => "()"
  rule render(pyTuple(cons(N:Node, emptyNodes()))) => "(" +String render(N) +String ",)"
  rule render(pyTuple(cons(N:Node, cons(M:Node, NS:Nodes)))) =>
       "(" +String renderNodes(cons(N, cons(M, NS))) +String ")"

  rule renderNodes(emptyNodes()) => ""
  rule renderNodes(cons(N:Node, emptyNodes())) => render(N)
  rule renderNodes(cons(N:Node, cons(M:Node, NS:Nodes))) =>
       render(N) +String ", " +String renderNodes(cons(M, NS))

  rule returnLine(N:Node) => "return " +String render(N)

  rule length(emptyNodes()) => 0
  rule length(cons(N:Node, NS:Nodes)) => 1 +Int length(NS)
endmodule

