module MINI-CONTOUR-LEVELS-SYNTAX
  imports BOOL-SYNTAX

  // Tags for the observable selected level policy.  The exact numeric payloads
  // are documented in SPEC.md:
  // - lineBoolDefault    == [0.5]
  // - filledBoolDefault  == [0, 0.5, 1]
  syntax LevelSet ::= "lineBoolDefault"
                    | "filledBoolDefault"
                    | "callerDirectedLevels"
                    | "legacyAutomaticLevels"

  syntax KItem ::= "processLevels"
                   "(" Bool "," Bool "," Bool "," Bool "," Bool "," Bool ")"
  syntax KResult ::= LevelSet
endmodule

module MINI-CONTOUR-LEVELS
  imports MINI-CONTOUR-LEVELS-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // processLevels(zIsBool, filled, noLevels, noLocator, logscale, hasInside)
  //
  // This abstracts _process_contour_level_args after _contour_args has already
  // recorded the original Z dtype.  hasInside models the later line-contour
  // "no levels in data range" fallback; it is intentionally ignored by the
  // boolean-default rules because V2 skips that fallback for auto bool levels.
  rule <k> processLevels(true, false, true, true, false, HAS:Bool)
        => lineBoolDefault ... </k>

  rule <k> processLevels(true, true, true, true, false, HAS:Bool)
        => filledBoolDefault ... </k>

  rule <k> processLevels(Z:Bool, F:Bool, false, L:Bool, G:Bool, H:Bool)
        => callerDirectedLevels ... </k>

  rule <k> processLevels(Z:Bool, F:Bool, true, L:Bool, G:Bool, H:Bool)
        => legacyAutomaticLevels ... </k>
    requires notBool (Z andBool L andBool notBool G)
endmodule
