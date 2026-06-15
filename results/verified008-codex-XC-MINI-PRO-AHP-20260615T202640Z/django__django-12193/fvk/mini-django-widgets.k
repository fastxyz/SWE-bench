module MINI-DJANGO-WIDGETS-SYNTAX
  imports BOOL-SYNTAX

  syntax Values ::= ".Values" | cons(Bool, Values)
  syntax Checks ::= ".Checks" | ccons(Bool, Checks)
  syntax Attrs ::= attrs(Bool)
  syntax Stmt ::= render(Values) | checkbox(Bool)
  syntax KResult ::= Bool | Values | Checks | Attrs
endmodule

module MINI-DJANGO-WIDGETS
  imports MINI-DJANGO-WIDGETS-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <attrs> attrs(false) </attrs>
    <out> .Checks </out>

  syntax Bool ::= shouldCheck(Bool) [function]
  rule shouldCheck(true) => true
  rule shouldCheck(false) => false

  syntax Bool ::= checkedOut(Bool, Attrs) [function]
  rule checkedOut(V, attrs(C)) => C orBool shouldCheck(V)

  syntax Checks ::= snoc(Checks, Bool) [function]
  rule snoc(.Checks, B) => ccons(B, .Checks)
  rule snoc(ccons(H, T), B) => ccons(H, snoc(T, B))

  syntax Checks ::= append(Checks, Checks) [function]
  rule append(.Checks, CS) => CS
  rule append(ccons(H, T), CS) => ccons(H, append(T, CS))

  rule <k> render(.Values) => .K </k>
  rule <k> render(cons(V, VS)) => checkbox(V) ~> render(VS) </k>

  // V1 semantics: CheckboxInput may add generated checked to the returned
  // context, but the caller-owned attrs cell is unchanged.
  rule <k> checkbox(V) => .K </k>
       <attrs> A => A </attrs>
       <out> OS => snoc(OS, checkedOut(V, A)) </out>
endmodule
