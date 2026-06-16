// Constructed mini-K model for Matplotlib subfigure layout.
// Status: constructed, not machine-checked.

module MINI-SUBFIGURE-LAYOUT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Exact rational layout coordinates.  This abstracts Python float arithmetic
  // to normalized exact arithmetic over ordinary in-domain layout inputs.
  syntax Rat ::= rat(Int, Int) [function]
               | Rat "+R" Rat [function, left]
               | Rat "-R" Rat [function, left]
               | Rat "*R" Rat [function, left]
               | Rat "/R" Rat [function, left]

  syntax RatList ::= ".RatList" | Rat "," RatList
  syntax Range ::= range(Int, Int)
  syntax BBox ::= bbox(Rat, Rat, Rat, Rat)
  syntax MaybeRat ::= none | some(Rat)
  syntax Stored ::= stored(MaybeRat, MaybeRat)
  syntax Space ::= space(Rat, Rat)

  syntax Layout ::= layout(
      Int, Int,        // nrows, ncols
      RatList, RatList, // height ratios, width ratios
      MaybeRat, MaybeRat, // subfigure hspace, wspace
      Range, Range       // rowspan, colspan
    )
  syntax Command ::= Layout
                   | storeSubfigureSpacing(MaybeRat, MaybeRat)
                   | manualSubfigureSpacing(MaybeRat, MaybeRat,
                                            MaybeRat, MaybeRat)
                   | overrideBBox(BBox)

  syntax KResult ::= BBox | Stored | Space
endmodule

module MINI-SUBFIGURE-LAYOUT
  imports MINI-SUBFIGURE-LAYOUT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Command </k>

  syntax Rat ::= zeroRat() [function]
  syntax Rat ::= oneRat() [function]
  syntax Rat ::= maybeZero(MaybeRat) [function]

  rule maybeZero(none) => zeroRat()
  rule maybeZero(some(R:Rat)) => R

  rule <k> storeSubfigureSpacing(MH:MaybeRat, MW:MaybeRat)
        => stored(MH, MW) </k>

  // The last two arguments model generic GridSpec hspace/wspace; they are
  // intentionally ignored by manual subfigure layout.
  rule <k> manualSubfigureSpacing(MH:MaybeRat, MW:MaybeRat,
                                  GH:MaybeRat, GW:MaybeRat)
        => space(maybeZero(MH), maybeZero(MW)) </k>

  rule <k> overrideBBox(B:BBox) => B </k>

  // Spec-only helpers.  The claim file gives their intended algebraic meaning.
  syntax Rat ::= sumRat(RatList) [function]
  syntax Rat ::= itemRat(RatList, Int) [function]
  syntax Rat ::= cellSize(RatList, Int, Int, Rat) [function]
  syntax Rat ::= sepSize(Int, Rat) [function]
  syntax Rat ::= leftAt(RatList, Int, Rat) [function]
  syntax Rat ::= rightAt(RatList, Int, Rat) [function]
  syntax Rat ::= topAt(RatList, Int, Rat) [function]
  syntax Rat ::= bottomAt(RatList, Int, Rat) [function]
  syntax Rat ::= minLeft(RatList, Range, Rat) [function]
  syntax Rat ::= maxRight(RatList, Range, Rat) [function]
  syntax Rat ::= minBottom(RatList, Range, Rat) [function]
  syntax Rat ::= maxTop(RatList, Range, Rat) [function]

  rule <k> layout(NR:Int, NC:Int, HR:RatList, WR:RatList,
                  MH:MaybeRat, MW:MaybeRat, RS:Range, CS:Range)
        => bbox(minLeft(WR, CS, maybeZero(MW)),
                minBottom(HR, RS, maybeZero(MH)),
                maxRight(WR, CS, maybeZero(MW)),
                maxTop(HR, RS, maybeZero(MH))) </k>
    requires NR >Int 0 andBool NC >Int 0
endmodule
