// Minimal K semantics for the parse_bits keyword-validation slice.
// Constructed for FVK review only; not machine-checked in this environment.

module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Name ::= String
  syntax Names ::= ".Names"
                 | Name "," Names [klabel(names), right]

  syntax Bit ::= kw(Name, String)
               | pos(String)
  syntax Bits ::= ".Bits"
                | Bit Bits [klabel(bits), right]

  syntax Outcome ::= pending
                   | ok
                   | unexpected(Name)
                   | multiple(Name)
                   | missing(Names)

  syntax Stmt ::= parse(Bits)
                | done

  syntax KResult ::= Outcome | Bool | Names
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Stmt </k>
    <params> .Names </params>
    <kwonly> .Names </kwonly>
    <varkw> false </varkw>
    <kwargs> .Names </kwargs>
    <requiredKwonly> .Names </requiredKwonly>
    <outcome> pending </outcome>

  syntax Bool ::= member(Name, Names) [function]
  rule member(N, .Names) => false
  rule member(N, N , NS) => true
  rule member(N, M , NS) => member(N, NS)
    requires N =/=String M

  syntax Names ::= add(Name, Names) [function]
  rule add(N, NS) => N , NS

  syntax Names ::= remove(Name, Names) [function]
  rule remove(N, .Names) => .Names
  rule remove(N, N , NS) => NS
  rule remove(N, M , NS) => M , remove(N, NS)
    requires N =/=String M

  syntax Bool ::= legal(Name, Names, Names, Bool) [function]
  rule legal(P, PARAMS, KWONLY, HASVARKW) =>
    member(P, PARAMS) orBool member(P, KWONLY) orBool HASVARKW

  rule
    <k> parse(kw(P, V) REST) => done ... </k>
    <kwargs> SEEN </kwargs>
    <outcome> O:Outcome => multiple(P) </outcome>
    requires member(P, SEEN)

  rule
    <k> parse(kw(P, V) REST) => done ... </k>
    <params> PARAMS </params>
    <kwonly> KWONLY </kwonly>
    <varkw> HASVARKW </varkw>
    <kwargs> SEEN </kwargs>
    <outcome> O:Outcome => unexpected(P) </outcome>
    requires notBool member(P, SEEN)
     andBool notBool legal(P, PARAMS, KWONLY, HASVARKW)

  rule
    <k> parse(kw(P, V) REST) => parse(REST) ... </k>
    <params> PARAMS </params>
    <kwonly> KWONLY </kwonly>
    <varkw> HASVARKW </varkw>
    <kwargs> SEEN => add(P, SEEN) </kwargs>
    <requiredKwonly> REQ => remove(P, REQ) </requiredKwonly>
    requires notBool member(P, SEEN)
     andBool legal(P, PARAMS, KWONLY, HASVARKW)

  rule
    <k> parse(pos(V) REST) => parse(REST) ... </k>

  rule
    <k> parse(.Bits) => done ... </k>
    <requiredKwonly> .Names </requiredKwonly>
    <outcome> O:Outcome => ok </outcome>

  rule
    <k> parse(.Bits) => done ... </k>
    <requiredKwonly> REQ </requiredKwonly>
    <outcome> O:Outcome => missing(REQ) </outcome>
    requires REQ =/=K .Names
endmodule
