requires "mini-java-interval-timeline.k"

module VERSIONED-INTERVAL-TIMELINE-VERIFICATION
  imports MINI-JAVA-INTERVAL-TIMELINE
  imports INT
  imports BOOL
  imports LIST

  syntax Int ::= maxInt(Int, Int) [function]
  rule maxInt(A:Int, B:Int) => A requires B <=Int A
  rule maxInt(A:Int, B:Int) => B requires A <Int B

  syntax Int ::= minInt(Int, Int) [function]
  rule minInt(A:Int, B:Int) => A requires A <=Int B
  rule minInt(A:Int, B:Int) => B requires B <Int A
endmodule

module VERSIONED-INTERVAL-TIMELINE-SPEC
  imports VERSIONED-INTERVAL-TIMELINE-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "Zero-length interval matches too much data" => zero-length query intervals are in-domain.
  // - from_prompt: "end instant of the timeline holder is not adjusted" => selected holders must be endpoint-clipped.
  // - from_code: this models the clipping phase after holders have been selected by timelineInterval.overlaps(interval).
  claim
    <k> lookupClip(QS:Int, QE:Int, .List) => .List </k>
    requires QS <=Int QE
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "should really match nothing" => zero-length query must not produce positive holder intervals.
  // - from_code: selected holder invariant HS < QE and QS < HE follows from the initial overlaps scan.
  claim
    <k> lookupClip(QS:Int, QE:Int, ListItem(interval(HS:Int, HE:Int)))
      => ListItem(interval(maxInt(QS, HS), minInt(QE, HE))) </k>
    requires QS <=Int QE
     andBool HS <Int QE
     andBool QS <Int HE
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "zero-length interval" and "end instant ... is not adjusted" => the reported interior-point case.
  // - from_code: V1 removes the query-side overlaps guard so clipEnd still fires after clipStart makes starts equal.
  claim
    <k> lookupClip(T:Int, T:Int, ListItem(interval(HS:Int, HE:Int)))
      => ListItem(interval(T, T)) </k>
    requires HS <Int T
     andBool T <Int HE
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: lookup clips only first and last holders; middle holders are framed through unchanged.
  // - from_prompt: the issue concerns interval bounds, not holder payload replacement.
  claim
    <k> lookupClip(QS:Int, QE:Int,
                   ListItem(interval(FS:Int, FE:Int)) MIDDLE:List ListItem(interval(LS:Int, LE:Int)))
      => ListItem(interval(maxInt(QS, FS), FE)) MIDDLE ListItem(interval(LS, minInt(QE, LE))) </k>
    requires QS <=Int QE
     andBool FS <Int QE
     andBool QS <Int FE
     andBool LS <Int QE
     andBool QS <Int LE
    [all-path]
endmodule
