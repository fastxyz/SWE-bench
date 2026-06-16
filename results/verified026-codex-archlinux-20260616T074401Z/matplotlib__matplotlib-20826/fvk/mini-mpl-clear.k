module MINI-MPL-CLEAR-SYNTAX
  imports BOOL
  imports MAP

  syntax AxisName ::= "xaxis" | "yaxis"
  syntax TickKind ::= "major" | "minor"
  syntax SideKey ::= "tick1On" | "tick2On" | "label1On" | "label2On"

  syntax KItem ::= clearAxes
                 | axisClear(AxisName)
                 | applyRc
                 | restoreTwin
                 | labelOuterX
                 | labelOuterY
                 | done
endmodule

module MINI-MPL-CLEAR
  imports MINI-MPL-CLEAR-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <rc> .Map </rc>
    <ticks> .Map </ticks>
    <saved> .Map </saved>
    <twin> false </twin>
    <labelOuterXCalled> false </labelOuterXCalled>
    <labelOuterYCalled> false </labelOuterYCalled>
    <firstRow> true </firstRow>
    <lastRow> true </lastRow>
    <firstCol> true </firstCol>
    <lastCol> true </lastCol>
    <style> .Map </style>

  // Abstract `Axis.clear`: visibility keys are gone; unrelated grid/style
  // state is outside this visibility model.
  rule <k> axisClear(AX) => . ... </k>
       <ticks> T => removeAxisVisibility(T, AX) </ticks>

  // Abstract `_set_tick_params_from_rcparams`.
  rule <k> applyRc => . ... </k>
       <rc> R </rc>
       <ticks> _ => R </ticks>

  // Abstract twin restore: only active when the caller is in a twinned group.
  rule <k> restoreTwin => . ... </k>
       <twin> true </twin>
       <saved> S </saved>
       <ticks> T => restoreVisibility(T, S) </ticks>

  rule <k> restoreTwin => . ... </k>
       <twin> false </twin>

  // Abstract SubplotBase._label_outer_xaxis.
  rule <k> labelOuterX => . ... </k>
       <labelOuterXCalled> true </labelOuterXCalled>
       <firstRow> FR </firstRow>
       <lastRow> LR </lastRow>
       <ticks> T => applyOuterX(T, FR, LR) </ticks>

  rule <k> labelOuterX => . ... </k>
       <labelOuterXCalled> false </labelOuterXCalled>

  // Abstract SubplotBase._label_outer_yaxis.
  rule <k> labelOuterY => . ... </k>
       <labelOuterYCalled> true </labelOuterYCalled>
       <firstCol> FC </firstCol>
       <lastCol> LC </lastCol>
       <ticks> T => applyOuterY(T, FC, LC) </ticks>

  rule <k> labelOuterY => . ... </k>
       <labelOuterYCalled> false </labelOuterYCalled>

  rule <k> clearAxes
        => axisClear(xaxis)
        ~> axisClear(yaxis)
        ~> applyRc
        ~> restoreTwin
        ~> labelOuterX
        ~> labelOuterY
        ~> done
        ...
       </k>

  syntax Map ::= removeAxisVisibility(Map, AxisName) [function]
  syntax Map ::= restoreVisibility(Map, Map) [function]
  syntax Map ::= applyOuterX(Map, Bool, Bool) [function]
  syntax Map ::= applyOuterY(Map, Bool, Bool) [function]

  // These functions are intentionally abstract in the mini model. The spec file
  // constrains the observations needed for the claims.
endmodule
