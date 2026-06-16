module MINI-PYTHON-REFIT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "fitTail" "(" Bool "," Bool ")"
                | "cloneBest"
                | "startClock"
                | "fitBest" "(" Bool ")"
                | "storeRefitTime"

  syntax MaybeInt ::= "absentInt" | Int
  syntax MaybeBool ::= "absentBool" | Bool
  syntax EstimatorState ::= "absentEstimator"
                          | "clonedEstimator"
                          | "fittedEstimator"

  syntax KResult ::= Int | Bool | MaybeInt | MaybeBool | EstimatorState
endmodule

module MINI-PYTHON-REFIT
  imports MINI-PYTHON-REFIT-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <bestEstimator> absentEstimator </bestEstimator>
    <refitTime> absentInt </refitTime>
    <fitSawY> absentBool </fitSawY>
    <startSample> absentInt </startSample>
    <clockStart> 0 </clockStart>
    <clockEnd> 0 </clockEnd>
    <cvState> 0 </cvState>

  rule <k> fitTail(false, HASY:Bool) => .K ... </k>

  rule <k> fitTail(true, HASY:Bool)
        => cloneBest ~> startClock ~> fitBest(HASY) ~> storeRefitTime
        ... </k>

  rule <k> cloneBest => .K ... </k>
       <bestEstimator> absentEstimator => clonedEstimator </bestEstimator>

  rule <k> startClock => .K ... </k>
       <clockStart> TStart:Int </clockStart>
       <startSample> absentInt => TStart </startSample>

  rule <k> fitBest(HASY:Bool) => .K ... </k>
       <bestEstimator> clonedEstimator => fittedEstimator </bestEstimator>
       <fitSawY> absentBool => HASY </fitSawY>

  rule <k> storeRefitTime => .K ... </k>
       <clockEnd> TEnd:Int </clockEnd>
       <startSample> TStart:Int </startSample>
       <refitTime> absentInt => TEnd -Int TStart </refitTime>
    requires TEnd >=Int TStart
endmodule
