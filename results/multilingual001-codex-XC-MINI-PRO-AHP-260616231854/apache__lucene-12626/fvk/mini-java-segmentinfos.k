module MINI-JAVA-SEGMENTINFOS-SYNTAX
  imports INT-SYNTAX

  syntax SegmentList ::= segs(Int)
  syntax UserData ::= udata(Int)

  // si(segments, lastGeneration, userData, generation, version, counter)
  syntax SI ::= si(SegmentList, Int, UserData, Int, Int, Int)
  syntax Cmd ::= replace(SI, SI)

  syntax KResult ::= SI
endmodule

module MINI-JAVA-SEGMENTINFOS
  imports MINI-JAVA-SEGMENTINFOS-SYNTAX
  imports INT

  configuration <k> $PGM:Cmd </k>

  rule
    <k>
      replace(
        si(SELF_SEGS, SELF_LAST, SELF_USER, SELF_GEN, SELF_VER, SELF_COUNTER),
        si(OTHER_SEGS, OTHER_LAST, OTHER_USER, OTHER_GEN, OTHER_VER, OTHER_COUNTER))
      =>
        si(OTHER_SEGS, OTHER_LAST, OTHER_USER, SELF_GEN, SELF_VER, SELF_COUNTER)
    </k>
endmodule
