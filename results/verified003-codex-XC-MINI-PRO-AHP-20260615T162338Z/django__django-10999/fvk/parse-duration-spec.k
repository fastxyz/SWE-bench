requires "mini-python-duration.k"

module PARSE-DURATION-SPEC
  imports MINI-DURATION

  // Claim STD-NODAYS-POS
  // SPEC-PROVENANCE:
  // - E6: positive standard formats remain accepted.
  claim <k> parseDuration(stdNoDays(pos, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(timeUs(H, M, S, U)) </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000
    [all-path]

  // Claim STD-NODAYS-NEG
  // SPEC-PROVENANCE:
  // - E3: a leading '-' on a no-day standard duration negates the whole time.
  claim <k> parseDuration(stdNoDays(neg, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(0 -Int timeUs(H, M, S, U)) </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000
    [all-path]

  // Claim STD-DAYS-PRESERVE
  // SPEC-PROVENANCE:
  // - E7: signed day duration strings round-trip with day semantics.
  claim <k> parseDuration(stdDays(D:Int, pos, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(daysUs(D) +Int timeUs(H, M, S, U)) </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000
    [all-path]

  // Claim STD-DAYS-SIGNED-TIME-INVALID
  // SPEC-PROVENANCE:
  // - E4/E5: signs not in leading position are invalid for standard format.
  claim <k> parseDuration(stdDays(D:Int, neg, H:OptInt, M:OptInt, S:Int, U:Int))
        => none </k>
    [all-path]

  // Claim STD-INTERNAL-SIGN-INVALID
  // SPEC-PROVENANCE:
  // - E4: a '-' after a colon is invalid standard syntax.
  claim <k> parseDuration(stdInternalSign) => none </k>
    [all-path]

  // Claim REPORTED-HMS
  // SPEC-PROVENANCE:
  // - E3 concrete reported `-00:01:01` case.
  claim <k> parseDuration(stdNoDays(neg, some(0), some(1), 1, 0))
        => tdUs(0 -Int 61000000) </k>
    [all-path]

  // Claim REPORTED-MS
  // SPEC-PROVENANCE:
  // - E3 concrete `-01:01` case from the issue discussion.
  claim <k> parseDuration(stdNoDays(neg, none, some(1), 1, 0))
        => tdUs(0 -Int 61000000) </k>
    [all-path]
endmodule
