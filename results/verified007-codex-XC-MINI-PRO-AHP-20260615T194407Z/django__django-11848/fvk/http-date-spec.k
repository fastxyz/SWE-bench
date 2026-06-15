requires "mini-http-date.k"

module HTTP-DATE-SPEC
  imports MINI-HTTP-DATE
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_problem: "instead of comparing versus the current year"
  // - from_problem: RFC850 two-digit years more than 50 years in the future
  //   represent the most recent past year with the same last two digits.
  // - from_hint: use UTC current year; this claim abstracts the already-UTC CY.
  claim
    <k> normalize2(YY:Int, CY:Int)
      => (CY -Int (CY modInt 100)) +Int YY
      ... </k>
    requires CY >=Int 100
     andBool 0 <=Int YY andBool YY <Int 100
     andBool ((CY -Int (CY modInt 100)) +Int YY) <=Int CY +Int 50
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: "MUST interpret a timestamp that appears to be more than
  //   50 years in the future as representing the most recent year in the past
  //   that had the same last two digits."
  claim
    <k> normalize2(YY:Int, CY:Int)
      => ((CY -Int (CY modInt 100)) +Int YY) -Int 100
      ... </k>
    requires CY >=Int 100
     andBool 0 <=Int YY andBool YY <Int 100
     andBool ((CY -Int (CY modInt 100)) +Int YY) >Int CY +Int 50
    ensures (((CY -Int (CY modInt 100)) +Int YY) -Int 100) <Int CY
     andBool ((((CY -Int (CY modInt 100)) +Int YY) -Int 100) modInt 100) ==Int YY
    [all-path]

  // SPEC-PROVENANCE:
  // - discriminator for the reported hard-coded cutoff bug.
  claim
    <k> normalize2(69, 2018) => 1969 ... </k>
    [all-path]
endmodule
