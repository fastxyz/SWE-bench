requires "domains.k"

module MINI-JAVA-INTERVAL-TIMELINE-SYNTAX
  imports INT-SYNTAX
  imports LIST-SYNTAX

  syntax Interval ::= interval(Int, Int)
  syntax Exp ::= lookupClip(Int, Int, List)
               | clipStart(Int, List)
               | clipEnd(Int, List)
  syntax KResult ::= List
endmodule

module MINI-JAVA-INTERVAL-TIMELINE
  imports MINI-JAVA-INTERVAL-TIMELINE-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:Exp </k>

  rule <k> lookupClip(QS:Int, QE:Int, .List) => .List </k>

  rule <k> lookupClip(QS:Int, QE:Int, HOLDERS:List)
        => clipEnd(QE, clipStart(QS, HOLDERS)) </k>
    requires HOLDERS =/=K .List

  rule <k> clipStart(QS:Int, ListItem(interval(HS:Int, HE:Int)) REST:List)
        => ListItem(interval(QS, HE)) REST </k>
    requires HS <Int QS

  rule <k> clipStart(QS:Int, ListItem(interval(HS:Int, HE:Int)) REST:List)
        => ListItem(interval(HS, HE)) REST </k>
    requires QS <=Int HS

  rule <k> clipEnd(QE:Int, FRONT:List ListItem(interval(LS:Int, LE:Int)))
        => FRONT ListItem(interval(LS, QE)) </k>
    requires QE <Int LE

  rule <k> clipEnd(QE:Int, FRONT:List ListItem(interval(LS:Int, LE:Int)))
        => FRONT ListItem(interval(LS, LE)) </k>
    requires LE <=Int QE
endmodule
