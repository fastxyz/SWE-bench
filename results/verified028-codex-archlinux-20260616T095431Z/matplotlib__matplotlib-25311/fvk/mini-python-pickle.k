// Status: constructed for FVK audit; not machine-checked.
// Minimal K-style model for the pickle-relevant DraggableBase state fragment.

module MINI-PYTHON-PICKLE-SYNTAX
  imports BOOL
  imports MAP

  syntax Key ::= KCanvas          // "_canvas"
               | KLegacyCanvas    // "canvas"
               | KGotArtist       // "got_artist"
               | KBackground      // "background"
               | KCids            // "cids"
               | KUseBlit         // "_use_blit"
               | KRefFigureCanvas // ref_artist.figure.canvas

  syntax Value ::= None
                 | LiveCanvas
                 | Bool(Bool)
                 | Val(String)

  syntax KItem ::= draggableGetState(Map)
                 | draggableSetState(Map)
                 | draggableCanvas(Map)
                 | draggableUseBlitting(Map)
                 | figurePickleWithHelper(Map)

  syntax Map ::= stripTransient(Map) [function]
               | restoreState(Map) [function]
               | removeKey(Map, Key) [function]
               | hasLiveCanvas(Map) [function]
endmodule

module MINI-PYTHON-PICKLE
  imports MINI-PYTHON-PICKLE-SYNTAX
  imports BOOL
  imports MAP

  configuration <k> $PGM:K </k>

  // DraggableBase.__getstate__:
  // state = self.__dict__.copy()
  // state.pop("canvas", None)
  // state["_canvas"] = None
  // state["got_artist"] = False
  // state.pop("background", None)
  rule <k> draggableGetState(H) => stripTransient(H) ... </k>
  rule stripTransient(H)
    => removeKey(
         removeKey(H [KCanvas <- None] [KGotArtist <- Bool(false)],
                   KLegacyCanvas),
         KBackground)

  // DraggableBase.__setstate__:
  // state.pop("canvas", None)
  // state.setdefault("_canvas", None)
  rule <k> draggableSetState(H) => restoreState(H) ... </k>
  rule restoreState(H)
    => removeKey(H [KCanvas <- None], KLegacyCanvas)
    requires notBool (KCanvas in_keys(H))

  rule restoreState(H)
    => removeKey(H, KLegacyCanvas)
    requires KCanvas in_keys(H)

  // DraggableBase.canvas:
  // if _canvas is None and ref_artist.figure is not None, resolve the
  // current figure canvas.  The model represents the still-parented case with
  // KRefFigureCanvas present.
  rule <k> draggableCanvas(H) => H[KRefFigureCanvas] ... </k>
    requires H[KCanvas] ==K None andBool KRefFigureCanvas in_keys(H)

  rule <k> draggableCanvas(H) => H[KCanvas] ... </k>
    requires notBool (H[KCanvas] ==K None)

  rule <k> draggableCanvas(H) => None ... </k>
    requires H[KCanvas] ==K None andBool notBool (KRefFigureCanvas in_keys(H))

  // DraggableBase._use_blitting:
  // returns false when the helper cannot resolve a current canvas.
  rule <k> draggableUseBlitting(H) => Bool(false) ... </k>
    requires H[KCanvas] ==K None andBool notBool (KRefFigureCanvas in_keys(H))

  // Existing Figure.__getstate__ already removes Figure.canvas.  This model
  // focuses on the additional helper path introduced by draggable artists.
  rule <k> figurePickleWithHelper(H) => stripTransient(H) ... </k>
endmodule
