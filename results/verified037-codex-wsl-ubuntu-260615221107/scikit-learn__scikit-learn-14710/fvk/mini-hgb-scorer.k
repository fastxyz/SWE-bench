module MINI-HGB-SCORER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Mode ::= "base" | "classifier"

  syntax Labels ::= ".Labels" [klabel(.Labels)]
                  | String "," Labels [klabel(labelCons), right]
  syntax Codes ::= ".Codes" [klabel(.Codes)]
                 | Int "," Codes [klabel(codeCons), right]

  syntax YVec ::= labels(Labels) | codes(Codes)

  syntax Exp ::= getYForScorer(Mode, Labels, YVec)
  syntax Stmt ::= checkEarlyStoppingScorer(Mode, Labels, YVec, YVec, Bool)

  syntax KResult ::= YVec | Bool
endmodule

module MINI-HGB-SCORER
  imports MINI-HGB-SCORER-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <trainArg> labels(.Labels) </trainArg>
    <validationArg> labels(.Labels) </validationArg>
    <validationUsed> false </validationUsed>

  syntax Int ::= len(Labels) [function]
  rule len(.Labels) => 0
  rule len(_L:String , LS:Labels) => 1 +Int len(LS)

  syntax Bool ::= validCodes(Labels, Codes) [function]
  rule validCodes(_CLASSES:Labels, .Codes) => true
  rule validCodes(CLASSES:Labels, I:Int , IS:Codes) =>
       (0 <=Int I andBool I <Int len(CLASSES)) andBool validCodes(CLASSES, IS)

  syntax String ::= labelAt(Labels, Int) [function]
  rule labelAt(L:String , _LS:Labels, 0) => L
  rule labelAt(_L:String , LS:Labels, I:Int) => labelAt(LS, I -Int 1)
    requires I >Int 0

  syntax Labels ::= decode(Labels, Codes) [function]
  rule decode(_CLASSES:Labels, .Codes) => .Labels
  rule decode(CLASSES:Labels, I:Int , IS:Codes) =>
       labelAt(CLASSES, I) , decode(CLASSES, IS)

  syntax YVec ::= getYForScorerValue(Mode, Labels, YVec) [function]
  rule getYForScorerValue(base, _CLASSES:Labels, Y:YVec) => Y
  rule getYForScorerValue(classifier, CLASSES:Labels, codes(YS:Codes)) =>
       labels(decode(CLASSES, YS))
    requires validCodes(CLASSES, YS)

  rule <k> getYForScorer(M:Mode, CLASSES:Labels, Y:YVec)
        => getYForScorerValue(M, CLASSES, Y) ... </k>

  rule <k> checkEarlyStoppingScorer(M:Mode, CLASSES:Labels,
                                    YTRAIN:YVec, YVAL:YVec, true)
        => .K </k>
       <trainArg> _ => getYForScorerValue(M, CLASSES, YTRAIN) </trainArg>
       <validationArg> _ => getYForScorerValue(M, CLASSES, YVAL) </validationArg>
       <validationUsed> _ => true </validationUsed>

  rule <k> checkEarlyStoppingScorer(M:Mode, CLASSES:Labels,
                                    YTRAIN:YVec, _YVAL:YVec, false)
        => .K </k>
       <trainArg> _ => getYForScorerValue(M, CLASSES, YTRAIN) </trainArg>
       <validationArg> V:YVec => V </validationArg>
       <validationUsed> _ => false </validationUsed>
endmodule
