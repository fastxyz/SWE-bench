// Constructed for FVK audit; not machine-checked.
// Minimal K-style semantics for the `_format_float` selection logic.
// This abstracts Python float conversion as a FloatView containing:
//   - the Python str(value) token
//   - the legacy f"{value:.16G}" token

module MINI-FITS-CARD-FORMAT-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax FloatView ::= floatView(String, String)
  syntax FCmd ::= formatFloat(FloatView)
                | formatHierarchRadius

  syntax String ::= formatToken(FloatView) [function]
                  | normalizeLowerE(String) [function]
                  | chooseBase(String, String) [function]
                  | ensureDecimal(String) [function]
                  | normalizeExponent(String) [function]
                  | cap20(String) [function]
                  | pad80(String) [function]

  syntax KResult ::= String
endmodule

module MINI-FITS-CARD-FORMAT
  imports MINI-FITS-CARD-FORMAT-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:FCmd </k>

  rule <k> formatFloat(FV:FloatView) => formatToken(FV) ... </k>

  rule <k> formatHierarchRadius =>
    pad80("HIERARCH ESO IFM CL RADIUS = "
          +String formatToken(floatView("0.009125", "0.009124999999999999"))
          +String " / [m] radius arround actuator to avoid")
    ... </k>

  rule formatToken(floatView(S:String, Legacy:String)) =>
    cap20(normalizeExponent(ensureDecimal(chooseBase(normalizeLowerE(S), Legacy))))

  rule chooseBase(S:String, _Legacy:String) => S
    requires lengthString(S) <=Int 20

  rule chooseBase(S:String, Legacy:String) => Legacy
    requires lengthString(S) >Int 20

  // Concrete simplifications used by the reported issue and proof examples.
  rule normalizeLowerE("0.009125") => "0.009125" [simplification]
  rule normalizeLowerE("5.0022221e-07") => "5.0022221E-07" [simplification]

  rule ensureDecimal("0.009125") => "0.009125" [simplification]
  rule ensureDecimal("5.0022221E-07") => "5.0022221E-07" [simplification]

  rule normalizeExponent("0.009125") => "0.009125" [simplification]
  rule normalizeExponent("5.0022221E-07") => "5.0022221E-07" [simplification]

  rule cap20("0.009125") => "0.009125" [simplification]
  rule cap20("5.0022221E-07") => "5.0022221E-07" [simplification]

  rule pad80("HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid")
    => "HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid    "
    [simplification]
endmodule
