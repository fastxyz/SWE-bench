requires "mini-mpl-clear.k"

module AXES-CLEAR-SPEC
  imports MINI-MPL-CLEAR
  imports BOOL
  imports MAP

  // SPEC-PROVENANCE:
  // - E2/E5: top/right ticks on normal axes must come from current rcParams.
  // - F1: V1 failed this when it restored old visibility for ordinary axes.
  claim [CLAIM-RC-CLEAR]:
    <k> clearAxes => done ... </k>
    <rc> RC:Map </rc>
    <ticks> OLD:Map => RC </ticks>
    <twin> false </twin>
    <labelOuterXCalled> false </labelOuterXCalled>
    <labelOuterYCalled> false </labelOuterYCalled>
    <style> STYLE:Map => STYLE </style>

  // SPEC-PROVENANCE:
  // - E1/E6: a subplot that had x label_outer applied must hide redundant
  //   x tick labels after clear.
  claim [CLAIM-LABEL-OUTER-X]:
    <k> clearAxes => done ... </k>
    <rc> RC:Map </rc>
    <ticks> OLD:Map => applyOuterX(RC, FR:Bool, LR:Bool) </ticks>
    <twin> false </twin>
    <labelOuterXCalled> true </labelOuterXCalled>
    <labelOuterYCalled> false </labelOuterYCalled>
    <firstRow> FR </firstRow>
    <lastRow> LR </lastRow>

  // SPEC-PROVENANCE:
  // - E1/E6: a subplot that had y label_outer applied must hide redundant
  //   y tick labels after clear.
  claim [CLAIM-LABEL-OUTER-Y]:
    <k> clearAxes => done ... </k>
    <rc> RC:Map </rc>
    <ticks> OLD:Map => applyOuterY(RC, FC:Bool, LC:Bool) </ticks>
    <twin> false </twin>
    <labelOuterXCalled> false </labelOuterXCalled>
    <labelOuterYCalled> true </labelOuterYCalled>
    <firstCol> FC </firstCol>
    <lastCol> LC </lastCol>

  // SPEC-PROVENANCE:
  // - E7/F3: twinned axes keep structural opposite-side tick placement.
  claim [CLAIM-TWIN-PRESERVE]:
    <k> clearAxes => done ... </k>
    <rc> RC:Map </rc>
    <saved> SAVED:Map </saved>
    <ticks> OLD:Map => restoreVisibility(RC, SAVED) </ticks>
    <twin> true </twin>
    <labelOuterXCalled> false </labelOuterXCalled>
    <labelOuterYCalled> false </labelOuterYCalled>

  // SPEC-PROVENANCE:
  // - P5: non-visibility styling is not restored by the patch.
  claim [CLAIM-NO-STYLE-FRAME]:
    <k> clearAxes => done ... </k>
    <style> STYLE:Map => STYLE </style>

endmodule
