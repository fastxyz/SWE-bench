module MINI-CONVERT-DX-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax FVal ::= finite(Int) | nan
  syntax Dx ::= dx(Int)
  syntax Vals ::= ".Vals" [klabel(valsEmpty)]
                | FVal ";" Vals [klabel(valsCons), right]
  syntax Dxs ::= ".Dxs" [klabel(dxsEmpty)]
               | Dx ";" Dxs [klabel(dxsCons), right]
  syntax Outcome ::= converted(Dxs) | widths(Vals) | stopIteration

  syntax KItem ::= runConvertDx(Dxs, Vals, Vals)
endmodule

module MINI-CONVERT-DX
  imports MINI-CONVERT-DX-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Bool ::= isEmpty(Vals) [function]
  rule isEmpty(.Vals) => true
  rule isEmpty(V:FVal ; VS:Vals) => false

  syntax Bool ::= hasFinite(Vals) [function]
  rule hasFinite(.Vals) => false
  rule hasFinite(finite(I:Int) ; VS:Vals) => true
  rule hasFinite(nan ; VS:Vals) => hasFinite(VS)

  syntax FVal ::= firstVal(Vals) [function]
  rule firstVal(V:FVal ; VS:Vals) => V

  syntax FVal ::= firstFiniteVal(Vals) [function]
  rule firstFiniteVal(finite(I:Int) ; VS:Vals) => finite(I)
  rule firstFiniteVal(nan ; VS:Vals) => firstFiniteVal(VS)
    requires hasFinite(VS)

  // V1 representative selection: use first finite when it exists; otherwise
  // handle the StopIteration case by using the first unfiltered element.
  syntax FVal ::= rep(Vals) [function]
  rule rep(VS:Vals) => firstFiniteVal(VS)
    requires hasFinite(VS)
  rule rep(VS:Vals) => firstVal(VS)
    requires notBool hasFinite(VS) andBool notBool isEmpty(VS)

  syntax FVal ::= delta(FVal, FVal, Dx) [function]
  // Enough arithmetic for the reported defect: nan original and nan converted
  // coordinates produce nonfinite width data, not an exception.
  rule delta(nan, nan, D:Dx) => nan

  syntax Vals ::= mapDelta(FVal, FVal, Dxs) [function]
  rule mapDelta(X0:FVal, X:FVal, .Dxs) => .Vals
  rule mapDelta(X0:FVal, X:FVal, D:Dx ; DS:Dxs) =>
    delta(X0, X, D) ; mapDelta(X0, X, DS)

  syntax Outcome ::= convertDx(Dxs, Vals, Vals) [function]
  rule convertDx(DXS:Dxs, X0S:Vals, .Vals) => converted(DXS)
  rule convertDx(DXS:Dxs, X0S:Vals, XCS:Vals) =>
    widths(mapDelta(rep(X0S), rep(XCS), DXS))
    requires notBool isEmpty(X0S) andBool notBool isEmpty(XCS)

  rule <k> runConvertDx(DXS:Dxs, X0S:Vals, XCS:Vals) =>
           convertDx(DXS, X0S, XCS) ... </k>
endmodule
