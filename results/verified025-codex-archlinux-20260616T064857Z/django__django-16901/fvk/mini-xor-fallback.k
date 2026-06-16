module MINI-XOR-FALLBACK-SYNTAX
  imports BOOL
  imports INT

  syntax BList ::= ".BList"
                 | Bool "," BList [right]

  syntax Bool ::= "nonEmpty" "(" BList ")" [function]
                | "anyTrue" "(" BList ")" [function]
                | "oddParity" "(" BList ")" [function]
                | "fallback" "(" BList ")" [function]
                | "negFallback" "(" BList ")" [function]
                | "exactlyOne" "(" BList ")" [function]

  syntax Int ::= "truthCount" "(" BList ")" [function]
endmodule

module MINI-XOR-FALLBACK
  imports MINI-XOR-FALLBACK-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:Bool </k>

  rule nonEmpty(.BList) => false
  rule nonEmpty(_:Bool , _:BList) => true

  rule truthCount(.BList) => 0
  rule truthCount(true , BS:BList) => 1 +Int truthCount(BS)
  rule truthCount(false , BS:BList) => truthCount(BS)

  rule anyTrue(.BList) => false
  rule anyTrue(B:Bool , BS:BList) => B orBool anyTrue(BS)

  rule oddParity(BS:BList) => (truthCount(BS) modInt 2) ==Int 1
  rule exactlyOne(BS:BList) => truthCount(BS) ==Int 1
  rule fallback(BS:BList) => anyTrue(BS) andBool oddParity(BS)
  rule negFallback(BS:BList) => notBool fallback(BS)
endmodule
