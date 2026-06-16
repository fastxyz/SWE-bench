requires "mini-patch-dash.k"

module PATCH-DASH-SPEC
  imports MINI-PATCH-DASH

  // SPEC-PROVENANCE:
  // - from_prompt: "Rectangle ... ls=(0,(10,10))" and "ls=(10,(10,10))"
  //   => constructor-order patch setup must preserve the tuple offset.
  // - from_docs_or_tests: Patch.set_linestyle documents "(offset, onoffseq)"
  //   => tuple offset is in-domain public API.
  // - from_code: Patch.__init__ calls set_linestyle before set_linewidth;
  //   set_linewidth rescales _unscaled_dash_pattern into _dash_pattern.
  // - conflicts: pre-fix Patch.draw replaced the stored offset with 0.
  claim
    <k> setLinestyleTuple(O:Int, C:Int, SCALE:Bool)
         ~> setLinewidth(LW:Int, SCALE)
         ~> draw
      => .K ... </k>
    <visible> true </visible>
    <linewidth> 0 => LW </linewidth>
    <unscaledOffset> 0 => O modInt C </unscaledOffset>
    <dashCycle> 0 => C </dashCycle>
    <dashPatternOffset> 0 => scaleOffset(SCALE, O modInt C, LW) </dashPatternOffset>
    <dashPatternCycle> 0 => scaleCycle(SCALE, C, LW) </dashPatternCycle>
    <rendererDashOffset> -1 => scaleOffset(SCALE, O modInt C, LW) </rendererDashOffset>
    <rendererDashCycle> -1 => scaleCycle(SCALE, C, LW) </rendererDashCycle>
    <dashSetCount> 0 => 1 </dashSetCount>
  requires C >Int 0 andBool LW >=Int 0
  [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "When setting the linestyle on a patch object using a dash
  //   tuple the offset has no effect" => setting linestyle after construction
  //   must also preserve the tuple offset.
  // - from_code: Patch.set_linestyle immediately scales the parsed offset with
  //   the current linewidth.
  // - conflicts: none after V1.
  claim
    <k> setLinestyleTuple(O:Int, C:Int, SCALE:Bool)
         ~> draw
      => .K ... </k>
    <visible> true </visible>
    <linewidth> LW => LW </linewidth>
    <unscaledOffset> U0:Int => O modInt C </unscaledOffset>
    <dashCycle> C0:Int => C </dashCycle>
    <dashPatternOffset> DO0:Int => scaleOffset(SCALE, O modInt C, LW) </dashPatternOffset>
    <dashPatternCycle> DC0:Int => scaleCycle(SCALE, C, LW) </dashPatternCycle>
    <rendererDashOffset> -1 => scaleOffset(SCALE, O modInt C, LW) </rendererDashOffset>
    <rendererDashCycle> -1 => scaleCycle(SCALE, C, LW) </rendererDashCycle>
    <dashSetCount> 0 => 1 </dashSetCount>
  requires C >Int 0 andBool LW >=Int 0
  [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "the patch edge lines overlap, not adhering to the offset"
  //   => a non-zero normalized offset on a visible positive-linewidth edge must
  //   not be replaced by zero before reaching gc.set_dashes.
  // - from_prompt: Line2D example shows non-overlapping phases for offset 0
  //   versus offset 10.
  // - conflicts: pre-fix Patch.draw violated this exact obligation.
  claim
    <k> setLinestyleTuple(O:Int, C:Int, SCALE:Bool)
         ~> setLinewidth(LW:Int, SCALE)
         ~> draw
      => .K ... </k>
    <visible> true </visible>
    <linewidth> 0 => LW </linewidth>
    <rendererDashOffset> -1 => scaleOffset(SCALE, O modInt C, LW) </rendererDashOffset>
    <dashSetCount> 0 => 1 </dashSetCount>
  requires C >Int 0
       andBool LW >Int 0
       andBool (O modInt C =/=Int 0)
  ensures scaleOffset(SCALE, O modInt C, LW) =/=Int 0
  [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Patch.draw returns immediately when get_visible() is false.
  // - from_intent: the fix must preserve unrelated visibility behavior.
  // - conflicts: none.
  claim
    <k> draw => .K ... </k>
    <visible> false </visible>
    <rendererDashOffset> RDO:Int => RDO </rendererDashOffset>
    <rendererDashCycle> RDC:Int => RDC </rendererDashCycle>
    <dashSetCount> N:Int => N </dashSetCount>
  [all-path]
endmodule
