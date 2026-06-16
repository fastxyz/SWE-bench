// Constructed K claims for the subfigure layout patch.
// Status: constructed, not machine-checked.

requires "mini-subfigure-layout.k"

module SUBFIGURE-LAYOUT-SPEC
  imports MINI-SUBFIGURE-LAYOUT
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2/E3: wspace/hspace must affect subfigure gaps using the
  //   average-cell GridSpec-style formula.
  // - E4: absent/None subfigure spacing means zero spacing.
  // - E5: generic GridSpec subplot spacing is not subfigure spacing.
  // - E6: explicit bbox override is modeled separately in PROOF.md.

  syntax Bool ::= inDomain(Int, Int, RatList, RatList, Rat, Rat, Range, Range)
                  [function]
  syntax Bool ::= expectedBBox(BBox, Int, Int, RatList, RatList, Rat, Rat,
                               Range, Range) [function]

  claim <k> storeSubfigureSpacing(H:MaybeRat, W:MaybeRat)
        => stored(H, W) </k>
    [all-path]

  claim <k> manualSubfigureSpacing(none, none, GH:MaybeRat, GW:MaybeRat)
        => space(zeroRat(), zeroRat()) </k>
    [all-path]

  claim <k> manualSubfigureSpacing(some(H:Rat), none,
                                   GH:MaybeRat, GW:MaybeRat)
        => space(H, zeroRat()) </k>
    [all-path]

  claim <k> manualSubfigureSpacing(none, some(W:Rat),
                                   GH:MaybeRat, GW:MaybeRat)
        => space(zeroRat(), W) </k>
    [all-path]

  claim <k> manualSubfigureSpacing(some(H:Rat), some(W:Rat),
                                   GH:MaybeRat, GW:MaybeRat)
        => space(H, W) </k>
    [all-path]

  claim <k> overrideBBox(B:BBox) => B </k>
    [all-path]

  claim <k> layout(NR:Int, NC:Int, HR:RatList, WR:RatList,
                   some(H:Rat), some(W:Rat), RS:Range, CS:Range)
        => B:BBox </k>
    requires inDomain(NR, NC, HR, WR, H, W, RS, CS)
    ensures expectedBBox(B, NR, NC, HR, WR, H, W, RS, CS)
    [all-path]

  claim <k> layout(NR:Int, NC:Int, HR:RatList, WR:RatList,
                   some(H:Rat), none, RS:Range, CS:Range)
        => B:BBox </k>
    requires inDomain(NR, NC, HR, WR, H, zeroRat(), RS, CS)
    ensures expectedBBox(B, NR, NC, HR, WR, H, zeroRat(), RS, CS)
    [all-path]

  claim <k> layout(NR:Int, NC:Int, HR:RatList, WR:RatList,
                   none, some(W:Rat), RS:Range, CS:Range)
        => B:BBox </k>
    requires inDomain(NR, NC, HR, WR, zeroRat(), W, RS, CS)
    ensures expectedBBox(B, NR, NC, HR, WR, zeroRat(), W, RS, CS)
    [all-path]

  claim <k> layout(NR:Int, NC:Int, HR:RatList, WR:RatList,
                   none, none, RS:Range, CS:Range)
        => B:BBox </k>
    requires inDomain(NR, NC, HR, WR, zeroRat(), zeroRat(), RS, CS)
    ensures expectedBBox(B, NR, NC, HR, WR, zeroRat(), zeroRat(), RS, CS)
    [all-path]
endmodule
