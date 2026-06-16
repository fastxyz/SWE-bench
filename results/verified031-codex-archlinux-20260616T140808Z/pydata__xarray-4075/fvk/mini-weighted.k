module MINI-WEIGHTED-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Kind ::= "boolKind" | "otherKind"

  syntax BList ::= ".BList"
                 | "BCons" "(" Bool "," BList ")"

  syntax IList ::= ".IList"
                 | "ICons" "(" Int "," IList ")"

  syntax MaybeInt ::= "NoWeight"
                    | "SomeWeight" "(" Int ")"

  syntax Mean ::= "NaNMean"
                | "Ratio" "(" Int "," Int ")"

  syntax Exp ::= "needsCast" "(" Kind "," Kind ")"
               | "reduceBoolBool" "(" BList "," BList ")"
               | "sumOfWeightsBool" "(" BList "," BList ")"
               | "weightedMeanBoolWeights" "(" IList "," BList "," BList ")"

  syntax KResult ::= Bool | Int | MaybeInt | Mean
endmodule

module MINI-WEIGHTED
  imports MINI-WEIGHTED-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Int ::= "boolToInt" "(" Bool ")" [function]
  rule boolToInt(true) => 1
  rule boolToInt(false) => 0

  syntax Bool ::= "sameLength" "(" BList "," BList ")" [function]
  rule sameLength(.BList, .BList) => true
  rule sameLength(.BList, BCons(_, _)) => false
  rule sameLength(BCons(_, _), .BList) => false
  rule sameLength(BCons(_, BS), BCons(_, WS)) => sameLength(BS, WS)

  syntax Bool ::= "sameLengthIW" "(" IList "," BList ")" [function]
  rule sameLengthIW(.IList, .BList) => true
  rule sameLengthIW(.IList, BCons(_, _)) => false
  rule sameLengthIW(ICons(_, _), .BList) => false
  rule sameLengthIW(ICons(_, DS), BCons(_, WS)) => sameLengthIW(DS, WS)

  syntax Int ::= "dot01" "(" BList "," BList ")" [function]
  rule dot01(.BList, .BList) => 0
  rule dot01(BCons(B, BS), BCons(W, WS))
    => (boolToInt(B) *Int boolToInt(W)) +Int dot01(BS, WS)

  syntax Bool ::= "buggyBoolDot" "(" BList "," BList ")" [function]
  rule buggyBoolDot(.BList, .BList) => false
  rule buggyBoolDot(BCons(B, BS), BCons(W, WS))
    => (B andBool W) orBool buggyBoolDot(BS, WS)

  syntax Int ::= "weightedSumBoolWeights" "(" IList "," BList ")" [function]
  rule weightedSumBoolWeights(.IList, .BList) => 0
  rule weightedSumBoolWeights(ICons(D, DS), BCons(W, WS))
    => (D *Int boolToInt(W)) +Int weightedSumBoolWeights(DS, WS)

  rule <k> needsCast(boolKind, boolKind) => true </k>
  rule <k> needsCast(boolKind, otherKind) => false </k>
  rule <k> needsCast(otherKind, boolKind) => false </k>
  rule <k> needsCast(otherKind, otherKind) => false </k>

  rule <k> reduceBoolBool(BS, WS) => dot01(BS, WS) </k>
    requires sameLength(BS, WS)

  rule <k> sumOfWeightsBool(MASK, WEIGHTS) => SomeWeight(dot01(MASK, WEIGHTS)) </k>
    requires sameLength(MASK, WEIGHTS)
     andBool dot01(MASK, WEIGHTS) =/=Int 0

  rule <k> sumOfWeightsBool(MASK, WEIGHTS) => NoWeight </k>
    requires sameLength(MASK, WEIGHTS)
     andBool dot01(MASK, WEIGHTS) ==Int 0

  rule <k> weightedMeanBoolWeights(DATA, MASK, WEIGHTS)
        => Ratio(weightedSumBoolWeights(DATA, WEIGHTS), dot01(MASK, WEIGHTS)) </k>
    requires sameLengthIW(DATA, WEIGHTS)
     andBool sameLength(MASK, WEIGHTS)
     andBool dot01(MASK, WEIGHTS) =/=Int 0

  rule <k> weightedMeanBoolWeights(DATA, MASK, WEIGHTS) => NaNMean </k>
    requires sameLengthIW(DATA, WEIGHTS)
     andBool sameLength(MASK, WEIGHTS)
     andBool dot01(MASK, WEIGHTS) ==Int 0
endmodule
