module MINI-DURATION-SYNTAX
  imports INT-SYNTAX

  syntax Sign ::= "pos" | "neg"
  syntax OptInt ::= "none" | "some" "(" Int ")"

  // Parsed input shapes for the sign-placement property.
  syntax DurInput ::= "stdNoDays" "(" Sign "," OptInt "," OptInt "," Int "," Int ")"
                    | "stdDays" "(" Int "," Sign "," OptInt "," OptInt "," Int "," Int ")"
                    | "stdInternalSign"
                    | "isoOrPostgres" "(" Int ")"
                    | "unmatched"

  syntax DurResult ::= "tdUs" "(" Int ")" | "none"
  syntax KResult ::= DurResult
  syntax KItem ::= "parseDuration" "(" DurInput ")"

  syntax Int ::= "hoursOf" "(" OptInt ")" [function]
               | "minutesOf" "(" OptInt ")" [function]
               | "timeUs" "(" OptInt "," OptInt "," Int "," Int ")" [function]
               | "daysUs" "(" Int ")" [function]
endmodule

module MINI-DURATION
  imports MINI-DURATION-SYNTAX
  imports INT

  configuration <k> $PGM:K </k>

  rule hoursOf(none) => 0
  rule hoursOf(some(H:Int)) => H

  rule minutesOf(none) => 0
  rule minutesOf(some(M:Int)) => M

  rule daysUs(D:Int) => D *Int 86400000000

  rule timeUs(H:OptInt, M:OptInt, S:Int, U:Int)
    => (((hoursOf(H) *Int 60) +Int minutesOf(M)) *Int 60 +Int S) *Int 1000000 +Int U

  // Standard format without a day component: one leading sign applies to
  // the entire time value.
  rule <k> parseDuration(stdNoDays(pos, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(timeUs(H, M, S, U)) ... </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000

  rule <k> parseDuration(stdNoDays(neg, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(0 -Int timeUs(H, M, S, U)) ... </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000

  // Standard format with a day component keeps the signed-day semantics used by
  // Python/Django duration strings. A second time sign is invalid.
  rule <k> parseDuration(stdDays(D:Int, pos, H:OptInt, M:OptInt, S:Int, U:Int))
        => tdUs(daysUs(D) +Int timeUs(H, M, S, U)) ... </k>
    requires S >=Int 0 andBool U >=Int 0 andBool U <Int 1000000

  rule <k> parseDuration(stdDays(D:Int, neg, H:OptInt, M:OptInt, S:Int, U:Int))
        => none ... </k>

  // Any sign after a colon is outside the standard grammar.
  rule <k> parseDuration(stdInternalSign) => none ... </k>

  // Other accepted formats are framed as already-normalized durations.
  rule <k> parseDuration(isoOrPostgres(U:Int)) => tdUs(U) ... </k>
  rule <k> parseDuration(unmatched) => none ... </k>
endmodule
