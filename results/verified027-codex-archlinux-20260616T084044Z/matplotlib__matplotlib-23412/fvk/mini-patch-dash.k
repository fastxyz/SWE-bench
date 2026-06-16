module MINI-PATCH-DASH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= setLinestyleTuple(Int, Int, Bool)
                | setLinewidth(Int, Bool)
                | draw
                | bindDrawPath
                | setDashes(Int, Int)

  syntax Int ::= scaleOffset(Bool, Int, Int) [function]
               | scaleCycle(Bool, Int, Int)  [function]
endmodule

module MINI-PATCH-DASH
  imports MINI-PATCH-DASH-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <patch>
      <visible> true </visible>
      <linewidth> 0 </linewidth>
      <unscaledOffset> 0 </unscaledOffset>
      <dashCycle> 0 </dashCycle>
      <dashPatternOffset> 0 </dashPatternOffset>
      <dashPatternCycle> 0 </dashPatternCycle>
    </patch>
    <gc>
      <rendererDashOffset> -1 </rendererDashOffset>
      <rendererDashCycle> -1 </rendererDashCycle>
      <dashSetCount> 0 </dashSetCount>
    </gc>

  rule scaleOffset(true,  O, LW) => O *Int LW
  rule scaleOffset(false, O, LW) => O

  rule scaleCycle(true,  C, LW) => C *Int LW
  rule scaleCycle(false, C, LW) => C

  // Models Patch.set_linestyle for tuple linestyles after
  // matplotlib.lines._get_dash_pattern and _scale_dashes.  C abstracts the
  // positive sum of the on/off dash sequence.
  rule
    <k> setLinestyleTuple(O, C, SCALE) => .K ... </k>
    <linewidth> LW </linewidth>
    <unscaledOffset> _ => O modInt C </unscaledOffset>
    <dashCycle> _ => C </dashCycle>
    <dashPatternOffset> _ => scaleOffset(SCALE, O modInt C, LW) </dashPatternOffset>
    <dashPatternCycle> _ => scaleCycle(SCALE, C, LW) </dashPatternCycle>
  requires C >Int 0 andBool LW >=Int 0

  // Models Patch.set_linewidth rescaling an already-parsed dash tuple.
  rule
    <k> setLinewidth(LW, SCALE) => .K ... </k>
    <linewidth> _ => LW </linewidth>
    <unscaledOffset> U </unscaledOffset>
    <dashCycle> C </dashCycle>
    <dashPatternOffset> _ => scaleOffset(SCALE, U, LW) </dashPatternOffset>
    <dashPatternCycle> _ => scaleCycle(SCALE, C, LW) </dashPatternCycle>
  requires C >Int 0 andBool LW >=Int 0

  // Models Patch.draw's visibility guard.
  rule
    <k> draw => bindDrawPath ... </k>
    <visible> true </visible>

  rule
    <k> draw => .K ... </k>
    <visible> false </visible>

  // Models V1 Patch.draw entering _bind_draw_path_function without rewriting
  // the stored dash pattern.  The pre-fix bug would have used 0 instead of DO.
  rule
    <k> bindDrawPath => setDashes(DO, DC) ... </k>
    <dashPatternOffset> DO </dashPatternOffset>
    <dashPatternCycle> DC </dashPatternCycle>

  // Models gc.set_dashes(offset, dash_list), recording the observable offset.
  rule
    <k> setDashes(DO, DC) => .K ... </k>
    <rendererDashOffset> _ => DO </rendererDashOffset>
    <rendererDashCycle> _ => DC </rendererDashCycle>
    <dashSetCount> N => N +Int 1 </dashSetCount>
endmodule
