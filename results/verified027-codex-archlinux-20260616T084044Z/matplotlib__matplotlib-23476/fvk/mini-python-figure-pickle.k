module MINI-PYTHON-FIGURE-PICKLE-SYNTAX
  imports INT-SYNTAX

  // fig(liveDpi, originalDpi, devicePixelRatio, dpiScaleTransScale)
  syntax Fig ::= fig(Int, Int, Int, Int)

  // pickle(storedDpi, storedOriginalDpi, storedDpiScaleTransScale)
  syntax PickleState ::= pickle(Int, Int, Int)

  syntax KItem ::= getState(Fig)
                 | setState(PickleState)
                 | attachBackend(Fig, Int)
                 | roundTrip(Fig, Int)

  syntax KResult ::= Fig | PickleState
endmodule

module MINI-PYTHON-FIGURE-PICKLE
  imports MINI-PYTHON-FIGURE-PICKLE-SYNTAX
  imports INT

  configuration <k> $PGM:KItem </k>

  // Model of Figure.__getstate__ for a ratio-1 canvas: keep current _dpi.
  rule <k> getState(fig(D:Int, O:Int, 1, T:Int))
        => pickle(D, O, T)
       ... </k>

  // Model of Figure.__getstate__ after V1 for high-DPI canvases:
  // store logical/original DPI instead of runtime scaled DPI.
  rule <k> getState(fig(D:Int, O:Int, R:Int, T:Int))
        => pickle(O, O, T)
       ... </k>
    requires R =/=Int 1

  // Model of Figure.__setstate__ followed by FigureCanvasBase(self).
  // The V1 resync makes the transform scale equal to restored _dpi P.
  // FigureCanvasBase then treats current figure.dpi as the new original DPI.
  rule <k> setState(pickle(P:Int, O:Int, T:Int))
        => fig(P, P, 1, P)
       ... </k>

  // Model of reattaching to a high-DPI backend with ratio R.
  rule <k> attachBackend(fig(D:Int, O:Int, 1, T:Int), R:Int)
        => fig(D *Int R, D, R, D *Int R)
       ... </k>
    requires R =/=Int 1

  // Model of staying on a ratio-1 backend.
  rule <k> attachBackend(fig(D:Int, O:Int, 1, T:Int), 1)
        => fig(D, D, 1, D)
       ... </k>

  // Convenience rules for the roundtrip path.
  rule <k> roundTrip(fig(D:Int, O:Int, 1, T:Int), LR:Int)
        => attachBackend(fig(D, D, 1, D), LR)
       ... </k>

  rule <k> roundTrip(fig(D:Int, O:Int, R:Int, T:Int), LR:Int)
        => attachBackend(fig(O, O, 1, O), LR)
       ... </k>
    requires R =/=Int 1
endmodule
