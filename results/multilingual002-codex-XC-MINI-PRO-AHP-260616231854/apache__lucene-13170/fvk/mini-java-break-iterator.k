module MINI-JAVA-BREAK-ITERATOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "precedingV1" "(" Int ")"
                | "precedingOld" "(" Int ")"
                | "move" "(" Int "," Int "," Int "," Int ")"
  syntax Outcome ::= "done" | "arrayIndexOutOfBounds"
  syntax KResult ::= Outcome
endmodule

module MINI-JAVA-BREAK-ITERATOR
  imports MINI-JAVA-BREAK-ITERATOR-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Stmt </k>

  // V1: currentSentence = (sentenceStarts.length - 1) / 2.
  rule <k> precedingV1(N:Int) => move(N, 0, (N -Int 1) /Int 2, N -Int 1) ... </k>
    requires N >Int 0

  // Pre-fix model: currentSentence = sentenceStarts.length / 2.
  rule <k> precedingOld(N:Int) => move(N, 0, N /Int 2, N -Int 1) ... </k>
    requires N >Int 0

  // A non-base helper frame reads sentenceStarts[currentSentence + 1] before it can
  // choose the right branch. If that index is outside the array, this models the issue.
  rule <k> move(N:Int, Min:Int, Cur:Int, Max:Int) => arrayIndexOutOfBounds ... </k>
    requires Min <Int Max andBool Cur +Int 1 >=Int N

  // Base frame: assertions may mention current + 1 only behind Java short-circuiting
  // when Cur is not the last sentence. The issue's failing read is a non-base read.
  rule <k> move(_N:Int, Min:Int, Cur:Int, Max:Int) => done ... </k>
    requires Min ==Int Max andBool Cur ==Int Min

  // Already positioned in the sentence containing pos: no recursive call and no unsafe
  // current + 1 read after the guard above has been ruled out.
  rule <k> move(N:Int, Min:Int, Cur:Int, Max:Int) => done ... </k>
    requires Min <Int Max andBool Cur +Int 1 <Int N

  // Left recursive branch:
  //   newMax = currentSentence - 1
  //   currentSentence = minSentence + (currentSentence - minSentence) / 2
  rule <k> move(N:Int, Min:Int, Cur:Int, Max:Int)
        => move(N, Min, Min +Int (Cur -Int Min) /Int 2, Cur -Int 1) ... </k>
    requires Min <Int Max andBool Min <Int Cur andBool Cur +Int 1 <Int N

  // Right recursive branch:
  //   newMin = currentSentence + 1
  //   currentSentence = maxSentence - (maxSentence - currentSentence) / 2
  rule <k> move(N:Int, Min:Int, Cur:Int, Max:Int)
        => move(N, Cur +Int 1, Max -Int (Max -Int Cur) /Int 2, Max) ... </k>
    requires Min <Int Max andBool Cur <Int Max andBool Cur +Int 1 <Int N
endmodule

