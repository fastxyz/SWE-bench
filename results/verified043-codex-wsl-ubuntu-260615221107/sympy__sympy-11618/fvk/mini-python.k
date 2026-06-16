module MINI-POINT-DISTANCE-SYNTAX
  imports INT-SYNTAX

  syntax Ints ::= ".Ints" [klabel(nilInts)]
                | Int ";" Ints [klabel(consInts), right]

  syntax Point ::= "point" "(" Ints ")"
  syntax Num ::= Int | "sqrt" "(" Int ")"
  syntax Exp ::= Num
               | "distance" "(" Point "," Point ")"

  syntax KResult ::= Num
endmodule

module MINI-POINT-DISTANCE
  imports MINI-POINT-DISTANCE-SYNTAX
  imports INT

  configuration <k> $PGM:Exp </k>

  syntax Int ::= "sumsq" "(" Ints "," Ints ")" [function]

  rule sumsq(.Ints, .Ints) => 0
  rule sumsq(A:Int ; AS:Ints, .Ints)
    => (A *Int A) +Int sumsq(AS, .Ints)
  rule sumsq(.Ints, B:Int ; BS:Ints)
    => (B *Int B) +Int sumsq(.Ints, BS)
  rule sumsq(A:Int ; AS:Ints, B:Int ; BS:Ints)
    => ((A -Int B) *Int (A -Int B)) +Int sumsq(AS, BS)

  rule <k> distance(point(AS:Ints), point(BS:Ints))
        => sqrt(sumsq(AS, BS)) ... </k>
endmodule
