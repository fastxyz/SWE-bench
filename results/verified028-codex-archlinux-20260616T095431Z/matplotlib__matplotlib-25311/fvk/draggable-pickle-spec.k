// Status: constructed for FVK audit; not machine-checked.
// Exact commands to run later, not executed in this session:
//   kompile fvk/mini-python-pickle.k --backend haskell
//   kast --backend haskell fvk/draggable-pickle-spec.k
//   kprove fvk/draggable-pickle-spec.k

requires "mini-python-pickle.k"

module DRAGGABLE-PICKLE-SPEC
  imports MINI-PYTHON-PICKLE
  imports BOOL
  imports MAP

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: pickling draggable legends/annotations must not
  //   reach FigureCanvasQTAgg.
  // - E-004: Figure.__getstate__ already removes the figure's own canvas.
  // - E-007: DraggableBase helper state is the extra serialization path.
  claim <k> draggableGetState(H:Map) => S:Map </k>
    ensures S ==K stripTransient(H)
     andBool notBool (KLegacyCanvas in_keys(S))
     andBool S[KCanvas] ==K None
     andBool S[KGotArtist] ==K Bool(false)
     andBool notBool (KBackground in_keys(S))
     andBool notBool hasLiveCanvas(S)
    [label(DRAGGABLE-GETSTATE-NO-CANVAS)]

  // SPEC-PROVENANCE:
  // - E-003/E-004: restored helper state must not revive the old canvas.
  // - E-005: callbacks may be restored; canvas must be resolved later.
  claim <k> draggableSetState(H:Map) => S:Map </k>
    ensures S ==K restoreState(H)
     andBool notBool (KLegacyCanvas in_keys(S))
     andBool KCanvas in_keys(S)
    [label(DRAGGABLE-SETSTATE-CANVAS-DEFAULT)]

  // SPEC-PROVENANCE:
  // - E-004: figures can be reattached to another canvas after unpickling.
  // - E-005: preserved callbacks need the helper to use the current canvas.
  claim <k> draggableCanvas(
              H:Map [KCanvas <- None] [KRefFigureCanvas <- LiveCanvas])
          => LiveCanvas </k>
    [label(DRAGGABLE-CANVAS-LAZY-RESTORE)]

  // SPEC-PROVENANCE:
  // - E-003: no live canvas means no backend-specific blit operations.
  claim <k> draggableUseBlitting(H:Map [KCanvas <- None])
          => Bool(false) </k>
    requires notBool (KRefFigureCanvas in_keys(H))
    [label(DRAGGABLE-BLIT-SAFE-WHEN-NO-CANVAS)]

  // SPEC-PROVENANCE:
  // - E-001/E-002: both draggable legends and draggable annotations use a
  //   DraggableBase subclass, so the helper path must be canvas-free.
  claim <k> figurePickleWithHelper(H:Map) => S:Map </k>
    ensures S ==K stripTransient(H)
     andBool notBool hasLiveCanvas(S)
    [label(FIGURE-PICKLE-WITH-DRAGGABLE)]
endmodule
