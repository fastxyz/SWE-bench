requires "domains.md"

module MINI-HIST-KWARGS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Range ::= range(Int, Int) | noRange
  syntax Kwargs ::= kw(Bool, Range, Bool, Bool)

  syntax Exp ::= buildHistKwargs(Bool, Int, Range, Bool, Bool, Bool)
               | Kwargs
  syntax Kwargs ::= initKwargs(Bool, Int, Range) [function]
                  | addDensity(Kwargs, Bool, Bool) [function]
  syntax Bool ::= effectiveDensity(Bool, Bool) [function]
endmodule

module MINI-HIST-KWARGS
  imports MINI-HIST-KWARGS-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:Exp </k>

  // Models the audited source fragment:
  // hist_kwargs = dict()
  // if not input_empty and len(x) > 1:
  //     bins = histogram_bin_edges(..., bin_range, ...)
  // else:
  //     hist_kwargs['range'] = bin_range
  // density = bool(density) or bool(normed)
  // if density and not stacked:
  //     hist_kwargs['density'] = density
  rule <k> buildHistKwargs(INPUTEMPTY:Bool, NX:Int, R:Range,
                           DENSITY:Bool, NORMED:Bool, STACKED:Bool)
        => addDensity(initKwargs(INPUTEMPTY, NX, R),
                      effectiveDensity(DENSITY, NORMED),
                      STACKED)
       </k>

  rule initKwargs(INPUTEMPTY:Bool, NX:Int, R:Range)
        => kw(true, R, false, false)
    requires INPUTEMPTY orBool NX <=Int 1

  rule initKwargs(INPUTEMPTY:Bool, NX:Int, R:Range)
        => kw(false, noRange, false, false)
    requires notBool (INPUTEMPTY orBool NX <=Int 1)

  rule effectiveDensity(DENSITY:Bool, NORMED:Bool)
        => DENSITY orBool NORMED

  rule addDensity(kw(HASRANGE:Bool, R:Range, _:Bool, _:Bool),
                  true, false)
        => kw(HASRANGE, R, true, true)

  rule addDensity(KW:Kwargs, false, _:Bool) => KW
  rule addDensity(KW:Kwargs, true, true) => KW
endmodule
